import Foundation

/// All simulation parameters. These are the *starting points* documented in
/// FLOW-PROTOTYPE-01.md §5.6; they are tuned values, not verified finals.
public struct SimulationConfig: Equatable, Sendable {

    // MARK: Clock
    /// Physics fixed step in seconds. 120 Hz recommended by the contract.
    public var simulationStep: Double = 1.0 / 120.0
    /// Hard ceiling on steps run per display frame (0–3 per contract).
    public var maxStepsPerFrame: Int = 3

    // MARK: Decay (half lives, seconds)
    public var velocityHalfLife: Double = 0.65  // 0.4–1.6 (0.8 → 0.65: structure survives instead of fogging)
    public var pigmentHalfLife: Double = 6.5    // 4–16 (8 → 6.5: recovers negative space)
    public var detailHalfLife: Double = 4.0     // 1.5–6

    // MARK: Injection
    /// Touch influence radius, as a fraction of the canvas short side.
    /// Tuned 0.025 → 0.045 → 0.030. 2.5% read as a hairline; 4.5% made tight
    /// spiral arms merge into one disc (losing structure/negative space).
    /// 3.0% keeps strokes wide and soft while leaving spiral arms separable.
    public var radiusFraction: Float = 0.030     // 1–5%
    /// Teleported segment spacing cap as multiple of radius (0.35–0.5).
    public var interpolationSpacingFactor: Float = 0.4
    /// Momentum multiplier applied to input velocity (calibrated).
    /// Was 6.0 → pigment was advected at the velocity clamp (2.0 short-sides/s)
    /// and diluted by semi-Lagrangian resampling, leaving a hairline. 2.2 keeps
    /// visible curl while letting dye accumulate.
    public var touchMomentumGain: Float = 2.2
    /// Input velocity low-space clamp, short-side units per second.
    public var maxInputSpeed: Float = 12.0
    /// Physical velocity clamp, short-side units per second.
    public var maxVelocity: Float = 1.1
    /// Max dye concentration per pixel.
    public var maxDyeConcentration: Float = 1.0

    // MARK: Tap (light touch) — contract §1.4 “轻触 ≠ 圆形印章：可见柔和绽放”
    /// Tap influence radius as a multiple of `radiusFraction`. A tap needs a
    /// wider, softer footprint than a stroke or it reads as a small stamp.
    public var tapRadiusScale: Float = 4.2
    /// Radial push for taps (short-side units/s). Kept below the stroke gain so
    /// the bloom expands and deforms instead of smearing across the canvas.
    public var tapRadialPush: Float = 0.25
    /// Relative dye amount for the one-shot tap burst (strokes use 0.85).
    public var tapDye: Float = 0.85
    /// Per-step top-up while a touch is held stationary (contract §4.3 “Hold:
    /// 缓慢注入、有上限”). Very small on purpose — a large value re-saturates
    /// the footprint and destroys the bloom gradient.
    public var tapHoldDye: Float = 0.022
    /// Pigment core radius as a fraction of the tap radius. A dense core plus a
    /// wide, faint halo is what makes a tap read as a bloom (§1.4 #1) instead
    /// of a uniform round stamp.
    public var tapDyeRadiusScale: Float = 1.0

    // MARK: Visual (post process only — never used during simulation)
    public var detailStrength: Float = 0.9
    public var glowStrength: Float = 0.45       // 0...1
    public var bloomThreshold: Float = 0.18     // was 0.7 → bloom never triggered
    public var bloomEnabled: Bool = true
    public var detailEnabled: Bool = true

    // MARK: Determinism
    public var seed: UInt32 = 2401
    /// Dye remap range for the visible rim (§4.1 “边缘清晰但非硬边”).
    /// Raise `lo`/lower `hi` for a crisper edge; values are dye concentrations.
    public var edgeCurveLo: Float = 0.03
    public var edgeCurveHi: Float = 0.45
    /// Native-resolution filament frequency, cycles per canvas short side.
    /// Evaluated per display pixel (§5.4) so the silk structure is not limited
    /// by the simulation grid resolution.
    public var filamentFrequency: Float = 110

    // MARK: Simulation grid presets (short side texels)
    public enum GridPreset: Int, CaseIterable, Sendable {
        case q384 = 0
        case q512 = 1
        case q640 = 2
        var shortSideTexels: Int {
            switch self {
            case .q384: return 384
            case .q512: return 512
            case .q640: return 640
            }
        }
        var label: String {
            switch self {
            case .q384: return "384"
            case .q512: return "512"
            case .q640: return "640"
            }
        }
    }
    public var gridPreset: GridPreset = .q512
    /// Absolute cap on long side texels. Spec suggested 1024, raised to 2048
    /// because the cap clipped iPhone-portrait grids to an 8% aspect error
    /// (violates §4.1 no-stretch). See docs/DECISIONS.md D13.
    public var maxLongSideTexels: Int = 2048

    // MARK: - Flow / Glow / Ink Lifetime Debug controls
    /// `flow` in [0,1] maps to a restricted (momentumGain, velocityHalfLife) pair.
    public static func flow(_ f: Float) -> (gain: Float, halfLife: Double) {
        let k = min(max(f, 0), 1)
        // Low flow: gentle momentum, long persistence; high flow: punchy, short-lived
        let gain = 1.2 + k * 5.0                       // 1.2 ... 6.2
        let life = Double(1.6) - Double(k) * 1.2       // 1.6 ... 0.4
        return (gain, life)
    }

    /// `glow` in [0,1] maps to glowStrength (visual only).
    public static func glow(_ g: Float) -> Float {
        min(max(g, 0), 1)
    }

    /// `inkLifetime` in [0,1] maps to pigmentHalfLife in [4,16] s (Debug only).
    public static func inkLifetime(_ l: Float) -> Double {
        4.0 + Double(min(max(l, 0), 1)) * 12.0
    }

    public init() {}
}