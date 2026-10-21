import Foundation
import simd

/// Pure reference math so CPU tests can validate the *semantics* the shaders
/// implement (contract §5.5, "受限覆盖混合"). Not a runtime dependency of the
/// GPU path — it exists so determinism/bounds are testable on host.
public enum FluidMath {

    /// Bounded injection:  added = (1-a)*s ; premulRGB += added*C (contract).
    /// Guarantees alpha ≤ maxDye and premul invariant rgb ≤ alpha.
    public static func boundedInjection(currentAlpha: Float,
                                        currentPremulRGB: SIMD3<Float>,
                                        targetColor: SIMD3<Float>,
                                        s: Float,
                                        maxDye: Float = 1.0) -> (alpha: Float, premulRGB: SIMD3<Float>) {
        let a0 = min(max(currentAlpha, 0), 1)
        let sC = min(max(s, 0), 1)
        let inject = (1 - a0) * sC
        let newA = min(a0 + inject, maxDye)
        var rgb = currentPremulRGB
        rgb = min(rgb, SIMD3(repeating: a0))          // premul invariant
        rgb += inject * targetColor
        rgb = min(max(rgb, SIMD3(repeating: 0)), SIMD3(repeating: min(newA, 1)))
        return (newA, rgb)
    }

    /// Damping factor: `pow(0.5, dt / halfLife)` (contract §5.5).
    public static func dampFactor(dt: Double, halfLife: Double) -> Double {
        guard halfLife > 0 else { return dt > 0 ? 0 : 1 }
        let exp = dt / halfLife
        return Foundation.pow(0.5, exp)
    }

    /// Semi-Lagrangian back-step in normalized coordinates.
    /// `velShortSide` is velocity in short-side-per-second; `invIso` maps to
    /// normalized/sec; returns back-traced normalized coordinate [0,1]².
    public static func advectBack(uv: SIMD2<Float>, velShortSide: SIMD2<Float>,
                                  invIso: SIMD2<Float>, dt: Float) -> SIMD2<Float> {
        var back = uv - SIMD2(velShortSide.x * invIso.x, velShortSide.y * invIso.y) * dt
        back.x = min(max(back.x, 0), 1)
        back.y = min(max(back.y, 0), 1)
        return back
    }
}