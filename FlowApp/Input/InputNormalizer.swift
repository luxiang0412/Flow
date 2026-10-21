import Foundation

/// Converts raw input samples into deterministic, velocity-enriched stroke
/// segments for one fixed simulation step (contract §5.3).
///
/// Ownership: main thread only (touch UI). Not shared with other queues.
public final class InputNormalizer {

    /// How a segment should be injected.
    public enum SegmentKind: Int, Equatable, Sendable {
        /// First emission of a stationary touch: one wide, soft bloom.
        case burst = 0
        /// Stationary touch being held after the burst: slow, tiny top-up.
        case hold = 1
        /// Moving touch: oriented stroke.
        case stroke = 2
    }

    /// Segment output for one fixed step.
    public struct SegmentOutput: Equatable, Sendable {
        public let touchID: Int
        public let position: SIMD2<Float>   // normalized [0,1]², top-left origin
        public let velocity: SIMD2<Float>   // short-side units per second
        public let tangent: SIMD2<Float>    // unit, physical frame
        public let kind: SegmentKind
        public let timestamp: Double
        public var isTap: Bool { kind != .stroke }
    }

    private final class TouchRuntime {
        var lastPosNormalized: SIMD2<Float>
        var lastPostTime: Double            // real monotonic seconds
        var velocity: SIMD2<Float> = .zero  // ss/s, low-passed
        var tangent: SIMD2<Float> = .zero
        var lastInjectedPoint: SIMD2<Float>
        var hasMoved: Bool = false
        var didBurst: Bool = false
        var beganAt: Double
        var kind: Int
        init(pos: SIMD2<Float>, time: Double, kind: Int) {
            self.lastPosNormalized = pos
            self.lastPostTime = time
            self.beganAt = time
            self.lastInjectedPoint = pos
            self.kind = kind
        }
    }

    public struct Options {
        /// Velocity low-pass alpha per incoming sample.
        public var velocityAlpha: Float = 0.5
        /// Maximum input speed (short-side units / s).
        public var maxInputSpeed: Float = 12.0
        /// Insert a tap segment on begin even before any move (instant feedback).
        public var injectOnBegin: Bool = true
        public init() {}
    }

    public private(set) var options: Options
    /// Interpolation spacing multiplier over radius (0.35–0.5 per contract).
    public var spacingFactor: Float = 0.4

    // Aspect helpers (points size of the canvas view).
    private var canvasWidthPoints: Float = 1
    private var canvasHeightPoints: Float = 1
    private var runtime = [Int: TouchRuntime]()

    public init(options: Options = Options()) {
        self.options = options
    }

    // MARK: Canvas geometry
    /// Must be updated when the view / drawable content area changes.
    public func setCanvasSize(points: CGSize) {
        canvasWidthPoints = Float(max(points.width, 1e-4))
        canvasHeightPoints = Float(max(points.height, 1e-4))
    }

    public func reset() { runtime.removeAll() }

    // MARK: Ingestion (already normalized to canvas points)
    /// Convert a point (in canvas view points) to normalized coords [0,1]² top-left.
    public func normalizedPoint(_ p: CGPoint) -> SIMD2<Float> {
        SIMD2(Float(p.x) / canvasWidthPoints, Float(p.y) / canvasHeightPoints)
    }

    public func begin(touchID: Int, position: SIMD2<Float>, timestamp: Double, kind: Int = 0) {
        let p = clamped(position)
        if let existing = runtime[touchID] {
            // re-begin on same ID (defensive; UIKit normally ensures clear end)
            existing.lastPosNormalized = p
            existing.lastPostTime = timestamp
            return
        }
        runtime[touchID] = TouchRuntime(pos: p, time: timestamp, kind: kind)
    }

    public func move(touchID: Int, position: SIMD2<Float>, timestamp: Double) {
        guard let rt = runtime[touchID] else { return }
        if timestamp < rt.lastPostTime { return }               // out-of-order guard
        if timestamp == rt.lastPostTime && rt.hasMoved {
            return                                              // duplicate timestamp (dedupe)
        }
        let prevTime = rt.lastPostTime
        rt.lastPostTime = timestamp
        let p = clamped(position)
        let prev = rt.lastPosNormalized
        rt.lastPosNormalized = p

        // Normalized-space delta → physical short-side units.
        let sx: Float = canvasWidthPoints >= canvasHeightPoints
            ? canvasWidthPoints / canvasHeightPoints : 1
        let sy: Float = canvasWidthPoints >= canvasHeightPoints
            ? 1 : canvasHeightPoints / canvasWidthPoints
        let d = p - prev
        let dPhysical = SIMD2(d.x * sx, d.y * sy)
        let dist = simd_length(dPhysical)

        let dt = Float(max(timestamp - prevTime, 1e-6))
        var newVel = SIMD2<Float>.zero
        if dt > 0 && dist > 1e-5 {
            newVel = dPhysical / dt
            let speed = simd_length(newVel)
            if speed > options.maxInputSpeed {
                newVel *= options.maxInputSpeed / speed
            }
        }
        // low-pass blend
        rt.velocity = mix(rt.velocity, newVel, SIMD2(repeating: options.velocityAlpha))
        if dist > 1e-5 {
            rt.tangent = dPhysical / dist
        }
        rt.hasMoved = true
    }

    // Only used in tests to keep unit structure simple; production path uses ingest().
    public func end(touchID: Int) {
        runtime[touchID] = nil
    }

    public func cancel(touchID: Int) {
        runtime[touchID] = nil
    }

    /// Ingestion entry from TouchCaptureView (array, stable timestamp order).
    /// Auto-normalizes positions and performs duplicate-timestamp dedupe.
    public func ingest(touchID: Int,
                       phase: TouchSample.Phase,
                       timestamp: Double,
                       normalized: SIMD2<Float>,
                       kind: Int = 0) {
        switch phase {
        case .began: begin(touchID: touchID, position: normalized, timestamp: timestamp, kind: kind)
        case .moved: move(touchID: touchID, position: normalized, timestamp: timestamp)
        case .ended, .cancelled: end(touchID: touchID)
        }
    }

    // MARK: Per-step segment emission
    /// Returns segments to inject for this fixed simulation step. Deterministic
    /// for a fixed input stream (state machine + fixed spacing).
    public func segmentsForStep(spacingFraction radiusFraction: Float) -> [SegmentOutput] {
        // Physical spacing cap: 0.4 × radius in short-side units (contract §5.3.4).
        let spacing = max(radiusFraction * spacingFactor, 1e-6)
        let sx: Float = canvasWidthPoints >= canvasHeightPoints
            ? canvasWidthPoints / canvasHeightPoints : 1
        let sy: Float = canvasWidthPoints >= canvasHeightPoints
            ? 1 : canvasHeightPoints / canvasWidthPoints

        var out: [SegmentOutput] = []
        let ids = runtime.keys.sorted()          // deterministic order
        for id in ids {
            guard let rt = runtime[id] else { continue }
            if rt.hasMoved {
                // walk from last injected to current position
                var cursor = rt.lastInjectedPoint
                let target = rt.lastPosNormalized
                var guardCount = 0
                while true {
                    let dNorm = target - cursor
                    let dPhys = SIMD2(dNorm.x * sx, dNorm.y * sy)
                    let dist = simd_length(dPhys)
                    if dist < spacing || guardCount >= 64 { break }
                    let stepPhys = dPhys * (spacing / dist)
                    let stepNorm = SIMD2(stepPhys.x / sx, stepPhys.y / sy)
                    cursor = cursor + stepNorm
                    out.append(SegmentOutput(touchID: id,
                                             position: cursor,
                                             velocity: rt.velocity,
                                             tangent: rt.tangent == .zero ? (dPhys / max(dist, 1e-6)) : rt.tangent,
                                             kind: .stroke,
                                             timestamp: rt.lastPostTime))
                    guardCount += 1
                }
                rt.lastInjectedPoint = cursor
            } else if options.injectOnBegin {
                // A stationary touch emits ONCE as a wide burst, then only tiny
                // top-ups. Repeating the full tap every step saturated the whole
                // footprint and produced a flat “stamp” disc (measured).
                out.append(SegmentOutput(touchID: id,
                                         position: rt.lastPosNormalized,
                                         velocity: .zero,
                                         tangent: .zero,
                                         kind: rt.didBurst ? .hold : .burst,
                                         timestamp: rt.beganAt))
                rt.didBurst = true
                rt.lastInjectedPoint = rt.lastPosNormalized
            }
        }
        return out
    }

    public var activeTouchCount: Int { runtime.count }

    private func clamped(_ p: SIMD2<Float>) -> SIMD2<Float> {
        simd_clamp(p, SIMD2(repeating: 0), SIMD2(repeating: 1))
    }
}

// helper to mix SIMD2
private func mix(_ a: SIMD2<Float>, _ b: SIMD2<Float>, _ t: SIMD2<Float>) -> SIMD2<Float> {
    a * (SIMD2(repeating: 1) - t) + b * t
}
private func simd_clamp(_ v: SIMD2<Float>, _ lo: SIMD2<Float>, _ hi: SIMD2<Float>) -> SIMD2<Float> {
    SIMD2(min(max(v.x, lo.x), hi.x), min(max(v.y, lo.y), hi.y))
}
private func simd_length(_ v: SIMD2<Float>) -> Float {
    sqrtf(v.x * v.x + v.y * v.y)
}