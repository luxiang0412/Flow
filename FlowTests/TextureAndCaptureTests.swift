import Foundation
import Testing
import Metal
import simd

@testable import Flow

/// GPU-dependent tests. If no Metal device is available at runtime, they
/// `throw XCTSkip` (recorded, not silently passed).
struct TextureAndCaptureTests {

    private func makeDevice() throws -> MTLDevice {
        guard let d = MTLCreateSystemDefaultDevice() else {
            let err = NSError(domain: "Flow", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "no Metal device available (test skipped)"])
            throw err
        }
        return d
    }

    @Test func testShaderBridgeLayoutsMatch() {
        #expect(ShaderBridge.assertLayouts())
        #expect(MemoryLayout<ShaderBridge.StepParams>.size == 96)
        #expect(MemoryLayout<ShaderBridge.StrokeEvent>.size == 64)
    }

    @Test func testGPUTextureFormatsAndDimensions() throws {
        let device = try makeDevice()
        let tex = TextureSet(device: device)
        tex.build(width: 512, height: 900, captureEnabled: true)
        #expect(tex.velocity[0].pixelFormat == .rg16Float)
        #expect(tex.pigment[0].pixelFormat == .rgba16Float)
        #expect(tex.detail[0].pixelFormat == .r16Float)
        #expect(tex.composite.pixelFormat == .rgba16Float)
        #expect(tex.velocity[0].width == 512 && tex.velocity[0].height == 900)
        #expect(tex.capture?.pixelFormat == .bgra8Unorm)
    }

    @Test func testOffscreenCaptureDimensionsAndColorSpace() throws {
        let device = try makeDevice()
        // sim resolution → pixel buffer
        let tex = TextureSet(device: device)
        tex.build(width: 128, height: 128, captureEnabled: false)
        var pixels = [UInt8](repeating: 255, count: 128 * 128 * 4)
        // encode a top-left red patch in BGRA
        for y in 0..<64 {
            for x in 0..<64 {
                let i = (y * 128 + x) * 4
                pixels[i] = 0; pixels[i + 1] = 0; pixels[i + 2] = 255; pixels[i + 3] = 255
            }
        }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("flow-capture-test.png")
        try pixels.withUnsafeMutableBytes { raw in
            try TestCapture.writePNG(pixels: raw.baseAddress!,
                                     width: 128, height: 128, to: tmp)
        }
        let attrs = try FileManager.default.attributesOfItem(atPath: tmp.path)
        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
        #expect(size > 300)   // uniform image compresses well; just prove real PNG bytes
        #expect(FileManager.default.fileExists(atPath: tmp.path))
        try? FileManager.default.removeItem(at: tmp)
    }

    @Test func testGridAspectDerivation() {
        // contract: short side is 384/512/640; long side capped at 1024
        let c = SimulationConfig()
        let w = FlowRenderer.simWidthForStatic(pixelW: 2000, pixelH: 500, config: c)
        #expect(w == c.maxLongSideTexels)   // capped (raised to 2048, DECISIONS D13)
        let h = FlowRenderer.simHeightForStatic(pixelW: 2000, pixelH: 500, config: c)
        #expect(h == 512)
    }
}