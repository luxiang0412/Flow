import Foundation

/// Performance + state snapshot published to the Debug overlay & logs.
public struct MetricsSnapshot: Sendable, Equatable {
    public var fps: Double = 0
    public var frameIntervalMsP50: Double = 0
    public var frameIntervalMsP95: Double = 0
    public var lastFrameEncodeMs: Double = 0
    public var stepsLastFrame: Int = 0
    public var activeTouches: Int = 0
    public var simWidth: Int = 0
    public var simHeight: Int = 0
    public var drawableWidth: Int = 0
    public var drawableHeight: Int = 0
    public var replayName: String = "-"
    public var isPaused: Bool = false
    public var simTime: Double = 0
    public var nanCount: UInt = 0
    public var infCount: UInt = 0
    public var isSimulator: Bool = true
}

/// Ring buffer of frame intervals for P50/P95 statistics.
public struct IntervalStats {
    private var samples: [Double] = []
    private let capacity: Int

    public init(capacity: Int = 240) {
        self.capacity = capacity
    }

    public mutating func record(_ intervalSeconds: Double) {
        samples.append(intervalSeconds)
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
    }

    public var count: Int { samples.count }

    public func percentile(_ p: Double) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sorted = samples.sorted()
        let idx = min(Int(Double(sorted.count) * p), sorted.count - 1)
        return max(sorted[idx], 0)
    }

    public mutating func reset() { samples.removeAll() }
}

/// Records frame timing. Main-thread only by ownership convention.
public final class FrameMetrics: @unchecked Sendable {
    public private(set) var intervals = IntervalStats()
    private var lastIntervalStart: CFAbsoluteTime?
    private var lastFrameStart: CFAbsoluteTime = 0
    public var lastEncodeSeconds: Double = 0
    public var stepsLastFrame: Int = 0
    public var nanCount: UInt = 0
    public var infCount: UInt = 0

    public init() {}

    public func beginFrame() {
        let now = CFAbsoluteTimeGetCurrent()
        if let last = lastIntervalStart {
            intervals.record(now - last)
        }
        lastIntervalStart = now
        lastFrameStart = now
    }

    public func endFrame(encodeSeconds: Double) {
        lastEncodeSeconds = encodeSeconds
    }

    /// Seconds since last frame start (for encode duration accounting).
    public func elapsedSinceFrameStart() -> CFAbsoluteTime { CFAbsoluteTimeGetCurrent() - lastFrameStart }

    public func snapshot(fps: Double,
                         simSize: SIMD2<Int>,
                         drawableSize: SIMD2<Int>,
                         touches: Int,
                         replayName: String,
                         isPaused: Bool,
                         simTime: Double,
                         isSimulator: Bool) -> MetricsSnapshot {
        MetricsSnapshot(fps: fps.isFinite ? fps : 0,
                        frameIntervalMsP50: intervals.percentile(0.5) * 1000,
                        frameIntervalMsP95: intervals.percentile(0.95) * 1000,
                        lastFrameEncodeMs: lastEncodeSeconds * 1000,
                        stepsLastFrame: stepsLastFrame,
                        activeTouches: touches,
                        simWidth: simSize.x, simHeight: simSize.y,
                        drawableWidth: drawableSize.x, drawableHeight: drawableSize.y,
                        replayName: replayName,
                        isPaused: isPaused,
                        simTime: simTime,
                        nanCount: nanCount, infCount: infCount,
                        isSimulator: isSimulator)
    }
}

/// Small thread-visible store bridging renderer (main) → SwiftUI overlay (main).
public final class MetricsStore: @unchecked Sendable {
    public var latest: MetricsSnapshot = MetricsSnapshot()
    public init() {}
    public func publish(_ s: MetricsSnapshot) { latest = s }
}