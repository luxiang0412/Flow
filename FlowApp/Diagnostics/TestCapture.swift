import Foundation
import Metal
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import UIKit

/// Offscreen Metal capture → PNG (Debug/verification only; contract §6.4).
/// Never reads the live drawable; uses a dedicated texture + shared buffer.
public enum TestCapture {

    /// Writes a PNG from raw BGRA8 (non-sRGB, sRGB-encoded values) pixel bytes.
    /// `width`/`height` are pixel counts. Returns the saved file URL.
    @discardableResult
    public static func writePNG(pixels: UnsafeMutableRawPointer,
                                width: Int,
                                height: Int,
                                to url: URL) throws -> URL {
        let bytesPerRow = width * 4
        guard let provider = CGDataProvider(dataInfo: nil,
                                            data: pixels,
                                            size: bytesPerRow * height,
                                            releaseData: { _, _, _ in }) else {
            throw CaptureError.dataProvider
        }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        guard let cs = colorSpace,
              let image = CGImage(width: width,
                                   height: height,
                                   bitsPerComponent: 8,
                                   bitsPerPixel: 32,
                                   bytesPerRow: bytesPerRow,
                                   space: cs,
                                   bitmapInfo: CGBitmapInfo(rawValue:
                                       CGImageAlphaInfo.premultipliedFirst.rawValue |
                                       CGBitmapInfo.byteOrder32Little.rawValue),
                                   provider: provider,
                                   decode: nil,
                                   shouldInterpolate: true,
                                   intent: .defaultIntent) else {
            throw CaptureError.image
        }
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        guard let dst else { throw CaptureError.destination }
        CGImageDestinationAddImage(dst, image, nil)
        guard CGImageDestinationFinalize(dst) else { throw CaptureError.write }
        try FileManager.default.createDirectory(at: ImagesDocsURL, withIntermediateDirectories: true)
        return url
    }

    public enum CaptureError: Error {
        case dataProvider, image, destination, write, readback, size
    }

    /// Documents directory for captures (harness copies via simctl get_app_container).
    public static var ImagesDocsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("captures", isDirectory: true)
    }

    /// Builds a shared buffer of `pixelCount * 4` bytes for GPU readback.
    public static func makeReadbackBuffer(device: MTLDevice, pixelCount: Int) throws -> MTLBuffer {
        guard let b = device.makeBuffer(length: pixelCount * 4,
                                        options: .storageModeShared) else {
            throw CaptureError.dataProvider
        }
        return b
    }

    /// Synchronously reads `shared` buffer back into an owned Data.
    ///
    /// Debug-only path; on simulator/iOS shared memory is directly visible after
    /// `waitUntilCompleted`. Called only on explicit capture requests.
    public static func readBack(device: MTLDevice,
                                buffer: MTLBuffer,
                                length: Int) throws -> Data {
        let ptr = buffer.contents().bindMemory(to: UInt8.self, capacity: length)
        // Ensure any pending writes are visible to CPU
        #if os(macOS)
        buffer.didModifyRange(0..<length)
        #endif
        return Data(bytes: ptr, count: length)
    }
}