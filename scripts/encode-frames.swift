#!/usr/bin/env swift
// Encode a PNG frame sequence into a high-bitrate H.264 MP4.
//
//   swift scripts/encode-frames.swift <framesDir> <fps> <out.mp4> [Mbps]
//
// Used for review footage where the Simulator's own recordVideo bitrate is far
// too low for smooth gradient art (measured: tap clip 402 kbps @1206x2622).
// Frames come from the deterministic `--flow-dump-frames` path, so the video is
// reproducible and is real Metal output — it is NOT a device recording.
import AVFoundation
import CoreGraphics
import Foundation
import ImageIO

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write("usage: encode-frames.swift <dir> <fps> <out.mp4> [Mbps]\n".data(using: .utf8)!)
    exit(2)
}
let dir = URL(fileURLWithPath: args[1])
let fps = Double(args[2]) ?? 24
let outURL = URL(fileURLWithPath: args[3])
let mbps = args.count > 4 ? (Double(args[4]) ?? 20) : 20

let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path))?
    .filter { $0.hasSuffix(".png") }
    .sorted() ?? []
guard let first = files.first,
      let firstImage = CGImageSourceCreateWithURL(dir.appendingPathComponent(first) as CFURL, nil),
      let firstCG = CGImageSourceCreateImageAtIndex(firstImage, 0, nil) else {
    FileHandle.standardError.write("no frames in \(dir.path)\n".data(using: .utf8)!)
    exit(3)
}
let width = firstCG.width, height = firstCG.height

try? FileManager.default.removeItem(at: outURL)
let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: Int(mbps * 1_000_000),
        AVVideoMaxKeyFrameIntervalKey: 24,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        AVVideoAllowFrameReorderingKey: false,
    ],
]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: input,
    sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
    ])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

let timescale: Int32 = 600
for (i, name) in files.enumerated() {
    while !input.isReadyForMoreMediaData { usleep(2000) }
    guard let src = CGImageSourceCreateWithURL(dir.appendingPathComponent(name) as CFURL, nil),
          let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { continue }
    var pb: CVPixelBuffer?
    guard let pool = adaptor.pixelBufferPool,
          CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pb) == kCVReturnSuccess,
          let buffer = pb else { continue }
    CVPixelBufferLockBaseAddress(buffer, [])
    if let base = CVPixelBufferGetBaseAddress(buffer) {
        let ctx = CGContext(data: base,
                            width: width, height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                      | CGBitmapInfo.byteOrder32Little.rawValue)
        ctx?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    CVPixelBufferUnlockBaseAddress(buffer, [])
    let t = CMTime(value: CMTimeValue(Double(i) / fps * Double(timescale)), timescale: timescale)
    adaptor.append(buffer, withPresentationTime: t)
}

input.markAsFinished()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }
sem.wait()

let size = (try? FileManager.default.attributesOfItem(atPath: outURL.path)[.size] as? NSNumber)?.intValue ?? 0
let bytes = size
let bits = Double(bytes) * 8
let seconds = Double(files.count) / fps
print("wrote \(outURL.path) \(width)x\(height) frames=\(files.count) "
      + String(format: "≈%.1fs %.1f Mbps", seconds, bits / max(seconds, 0.001) / 1e6))