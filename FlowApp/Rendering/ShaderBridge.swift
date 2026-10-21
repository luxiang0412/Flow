import Foundation
import simd

/// Layout mirrors FlowShaders.metal. Asserted via `ShaderBridge.assertLayouts()`.
enum ShaderBridge {

    // MARK: StepParams (88 bytes = 11 × SIMD2<Float>)
    struct StepParams: Equatable {
        var dtRadius        = SIMD2<Float>(0, 0)      // dt, radiusFraction
        var iso             = SIMD2<Float>(1, 1)      // (sx, sy)
        var invIso          = SIMD2<Float>(1, 1)
        var gains           = SIMD2<Float>(6, 2)      // momentumGain, maxVelocity
        var noiseSeed       = SIMD2<Float>(1.5, 0)    // noiseScale, seed float
        var maxDyeStrength  = SIMD2<Float>(1.0, 0.9)  // maxDye, detailStrength
        var wavelengthHL    = SIMD2<Float>(0.05, 0.8) // detailWavelength, velocityHalfLife
        var pigDetHL        = SIMD2<Float>(8.0, 4.0)  // pigmentHalfLife, detailHalfLife
        var bloom           = SIMD2<Float>(0.35, 0.7) // bloomStrength, bloomThreshold
        var bg0             = SIMD2<Float>(0.002, 0.003) // background linear r,g
        var bg1             = SIMD2<Float>(0.0057, 0)    // background linear b, pad
        var edgeCurve       = SIMD2<Float>(0.03, 0.45)   // dye remap (lo, hi)

        static var stride: Int { 12 * MemoryLayout<SIMD2<Float>>.stride }  // 96
    }

    // MARK: StrokeEvent (56 bytes)
    struct StrokeEvent {
        var pos:      SIMD2<Float>
        var vel:      SIMD2<Float>      // short-side / s
        var radius:   Float             // short-side fraction
        var strength: Float
        var dye:      Float             // 0...1
        var force:    Float             // 0...1
        var color:    SIMD3<Float>      // linear RGB
        var tangent:  SIMD2<Float>      // unit
        var kind:     UInt32            // 0 tap, 1 stroke
        /// Pigment/detail footprint. Narrower than `radius` for taps so the
        /// outward velocity spreads dye into a soft halo instead of a flat disc.
        var radiusPigment: Float = 0
    }

    /// Validate layout compatibility with the MSL mirrors. Expected sizes:
    ///   StepParams  96  (12 × SIMD2<Float>, alignment 8)
    ///   StrokeEvent 64  (float3/SIMD3 alignment 16 keeps tangent at 48)
    static func assertLayouts() -> Bool {
        let paramsSize = MemoryLayout<StepParams>.size
        let paramsAlign = MemoryLayout<StepParams>.alignment
        let eventSize = MemoryLayout<StrokeEvent>.size
        let eventAlign = MemoryLayout<StrokeEvent>.alignment
        let paramsOK = paramsSize == 96 && paramsAlign == 8
        let eventOK = eventSize == 64 && eventAlign == 16
        assert(paramsOK, "StepParams layout mismatch: size=\(paramsSize) align=\(paramsAlign)")
        assert(eventOK, "StrokeEvent layout mismatch: size=\(eventSize) align=\(eventAlign)")
        return paramsOK && eventOK
    }

    // MARK: Color helpers
    static func srgbToLinear(_ c: Float) -> Float {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    /// Aurora default palette (contract §4.1).
    static let paletteSRGB: [SIMD3<Float>] = [
        SIMD3(0x65 / 255.0, 0x48 / 255.0, 0xDF / 255.0),
        SIMD3(0xC7 / 255.0, 0x54 / 255.0, 0xCE / 255.0),
        SIMD3(0xFB / 255.0, 0x71 / 255.0, 0x9E / 255.0),
        SIMD3(0xFF / 255.0, 0xC6 / 255.0, 0x8B / 255.0),
    ]

    static func linearColor(index: Int) -> SIMD3<Float> {
        let s = paletteSRGB[abs(index) % paletteSRGB.count]
        return SIMD3(srgbToLinear(s.x), srgbToLinear(s.y), srgbToLinear(s.z))
    }

    /// Smooth cyclic Aurora gradient in linear space.
    /// `t` wraps over [0,1) across the 4 palette stops, so a stroke crossing the
    /// canvas walks purple → magenta → pink → warm (contract §4.1 “精致渐变”).
    static func auroraLinear(at t: Float) -> SIMD3<Float> {
        let n = paletteSRGB.count
        let wrapped = t - floor(t)
        let scaled = wrapped * Float(n)
        let i0 = Int(scaled) % n
        let i1 = (i0 + 1) % n
        let f = scaled - floor(scaled)
        let a = linearColor(index: i0)
        let b = linearColor(index: i1)
        // smoothstep keeps the transitions soft (no visible banding seams)
        let s = f * f * (3 - 2 * f)
        return a + (b - a) * s
    }

    /// Background `#070A13` in linear space (computed, not estimated).
    static let backgroundLinear = SIMD3<Float>(
        srgbToLinear(7.0 / 255.0),
        srgbToLinear(10.0 / 255.0),
        srgbToLinear(19.0 / 255.0)
    )
}