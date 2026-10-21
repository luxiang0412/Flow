import Foundation
import CoreGraphics

/// Immutable value object for a single input sample (contract §5.2).
/// Stored as an independent value; never a long-lived `UITouch` reference.
public struct TouchSample: Equatable, Sendable {
    public enum Phase: Int, Sendable { case began = 0, moved = 1, ended = 2, cancelled = 3 }
    public enum InputKind: Int, Sendable { case finger = 0, pencil = 1 }

    /// Stable integer ID allocated per begin, released on end/cancel (never memory address).
    public let touchID: Int
    public let phase: Phase
    /// Monotonic seconds. Non-decreasing per touch; duplicates are dropped upstream.
    public let timestamp: Double
    /// Normalized canvas coords [0,1]², top-left origin, aspect-corrected.
    public let position: SIMD2<Float>
    public let inputKind: InputKind
    /// Optional force in [0,1]; nil → internal default neutral.
    public let normalizedForce: Float?
    public let altitudeRadians: Float?
    public let azimuthRadians: Float?
    public let isPredicted: Bool

    public init(touchID: Int,
                phase: Phase,
                timestamp: Double,
                position: SIMD2<Float>,
                inputKind: InputKind = .finger,
                normalizedForce: Float? = nil,
                altitudeRadians: Float? = nil,
                azimuthRadians: Float? = nil,
                isPredicted: Bool = false) {
        self.touchID = touchID
        self.phase = phase
        self.timestamp = timestamp
        self.position = position
        self.inputKind = inputKind
        self.normalizedForce = normalizedForce
        self.altitudeRadians = altitudeRadians
        self.azimuthRadians = azimuthRadians
        self.isPredicted = isPredicted
    }

    /// Neutral force used when hardware pressure is unavailable (contract §5.2 / test #12).
    public static let neutralForce: Float = 0.5

    public var force: Float {
        normalizedForce.map { min(max($0, 0), 1) } ?? TouchSample.neutralForce
    }
}

/// A normalized, velocity-enriched segment used by the Simulation to inject
/// a single fixed step (by-product of InputNormalizer).
public struct StrokeSegment: Equatable, Sendable {
    /// Normalized top-left-origin coordinate.
    public let position: SIMD2<Float>
    /// Velocity in short-side units per second.
    public let velocity: SIMD2<Float>
    /// Radius as short-side fraction.
    public let radiusFraction: Float
    /// Momentum gain (config-scaled).
    public let strength: Float
    /// Linear RGB target color (premultiplied convention handled at shader level).
    public let color: SIMD3<Float>
    /// Relative dye amount 0...1 (force + kind aware).
    public let dyeAmount: Float
    /// Unit tangent along stroke (detail alignment). Zero for taps.
    public let tangent: SIMD2<Float>
    /// 0 = tap (radial), 1 = stroke (oriented).
    public let isTap: Bool
    /// Stable determinism keys (timestamp, touchID) for CPU-side ordering.
    public let timestamp: Double
    public let touchID: Int
}