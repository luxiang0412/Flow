import Foundation
import Metal

/// Ring of shared buffers so queued commands never overwrite data still in flight.
/// Ownership: created at init with fixed capacity; filled by the render thread.
public final class BufferPool {
    private let device: MTLDevice
    private let buffers: [MTLBuffer]
    private let capacity: Int
    private var cursor: Int = 0

    public init(device: MTLDevice, size: Int, count: Int) {
        self.device = device
        self.capacity = max(count, 4)
        var b: [MTLBuffer] = []
        for _ in 0..<self.capacity {
            if let buf = device.makeBuffer(length: size, options: .storageModeShared) {
                b.append(buf)
            }
        }
        self.buffers = b
    }

    /// Returns the next buffer for writing its `size`-byte region.
    public func next() -> MTLBuffer {
        let b = buffers[cursor % buffers.count]
        cursor += 1
        return b
    }

    public var count: Int { buffers.count }

    public func reset() { cursor = 0 }
}

/// Owns all simulation + post-process textures for one drawable size.
public final class TextureSet {
    let device: MTLDevice

    var velocity: [MTLTexture]!     // RG16Float, A/B
    var pigment: [MTLTexture]!      // RGBA16Float, A/B
    var detail: [MTLTexture]!       // R16Float, A/B
    var composite: MTLTexture!      // RGBA16Float
    var bloomA: MTLTexture!         // RGBA16Float (ping)
    var bloomB: MTLTexture!         // RGBA16Float (pong)
    var capture: MTLTexture?        // bgra8Unorm (offscreen capture target)

    /// A/B roles per field — the index of the *newest* state. Each field has
    /// its own cadence: velocity and pigment flip every step, detail does not.
    public var velRole: Int = 0
    public var pigRole: Int = 0
    public var detRole: Int = 0

    var width: Int = 0
    var height: Int = 0

    var mainDims: SIMD2<Int> { SIMD2(width, height) }
    var bloomDims: SIMD2<Int> { SIMD2(bloomA.width, bloomA.height) }

    public init(device: MTLDevice) { self.device = device }

    func make(state: MTLPixelFormat, width: Int, height: Int) -> MTLTexture {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: state,
            width: width,
            height: height,
            mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        desc.storageMode = .private
        guard let t = device.makeTexture(descriptor: desc) else {
            preconditionFailure("unable to allocate texture \(state.rawValue) \(width)x\(height)")
        }
        t.label = "flow-\(state.rawValue)-\(width)x\(height)"
        return t
    }

    /// (Re)builds all state textures at the given sim resolution.
    /// `captureSize` is the native target size for offscreen PNG capture — the
    /// final composite runs at that resolution (§5.4), not at sim resolution.
    func build(width w: Int, height h: Int,
               captureEnabled: Bool,
               captureSize: SIMD2<Int> = .zero) {
        width = w; height = h
        velocity = [make(state: .rg16Float, width: w, height: h),
                    make(state: .rg16Float, width: w, height: h)]
        pigment  = [make(state: .rgba16Float, width: w, height: h),
                    make(state: .rgba16Float, width: w, height: h)]
        detail   = [make(state: .r16Float, width: w, height: h),
                    make(state: .r16Float, width: w, height: h)]
        composite = make(state: .rgba16Float, width: w, height: h)
        let bw = max(1, w / 4), bh = max(1, h / 4)
        bloomA = make(state: .rgba16Float, width: bw, height: bh)
        bloomB = make(state: .rgba16Float, width: bw, height: bh)
        if captureEnabled {
            let cw = captureSize.x > 0 ? captureSize.x : w
            let ch = captureSize.y > 0 ? captureSize.y : h
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                width: cw, height: ch, mipmapped: false)
            desc.usage = [.renderTarget, .shaderRead]
            desc.storageMode = .private
            if let t = device.makeTexture(descriptor: desc) {
                t.label = "flow-capture"
                capture = t
            }
        } else {
            capture = nil
        }
        velRole = 0; pigRole = 0; detRole = 0
    }
}