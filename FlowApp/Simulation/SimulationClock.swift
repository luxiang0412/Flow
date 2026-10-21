import Foundation

/// Deterministic fixed-step accumulator (contract §3.2 / §5.1).
///
/// Ownership: used exclusively from the render queue thread (MTKView display
/// link / main thread). Not actor-isolated to keep MTKView delegate callbacks
/// compile-clean; documented single-caller rule in docs/DECISIONS.md.
public final class SimulationClock {

    public struct Snapshot: Equatable, Sendable {
        public var stepIndex: Int
        public var simTime: Double
        public var isPaused: Bool
        public var droppedSteps: Int
    }

    public private(set) var stepDuration: Double
    public private(set) var maxStepsPerFrame: Int

    private var accumulator: Double = 0
    private var lastNow: Double?
    private var stepIndex: Int = 0
    private(set) public var simTime: Double = 0
    private(set) public var isPaused: Bool = false
    private(set) public var droppedSteps: Int = 0

    public init(stepDuration: Double = 1.0 / 120.0, maxStepsPerFrame: Int = 3) {
        precondition(stepDuration > 0)
        self.stepDuration = stepDuration
        self.maxStepsPerFrame = maxStepsPerFrame
    }

    /// Reset timeline. Optionally keep pause flag.
    public func resetToZero(resetPause: Bool = true) {
        accumulator = 0
        lastNow = nil
        stepIndex = 0
        simTime = 0
        droppedSteps = 0
        if resetPause { isPaused = false }
    }

    /// Config-driven policy update (steps/frame bound).
    public func setPolicy(stepDuration: Double, maxStepsPerFrame: Int) {
        if stepDuration > 0 { self.stepDuration = stepDuration }
        self.maxStepsPerFrame = max(1, maxStepsPerFrame)
    }

    public func pause() {
        isPaused = true
        lastNow = nil      // ensure resume does not add paused wall time
        accumulator = 0
    }

    public func resume() {
        isPaused = false
        lastNow = nil
        accumulator = 0
    }

    /// Advance using externally supplied monotonic seconds (live touch path).
    /// Returns number of fixed steps to execute this frame.
    @discardableResult
    public func advance(now: Double) -> Int {
        guard !isPaused else { return 0 }
        let t = now
        if let last = lastNow {
            var delta = t - last
            if delta < 0 { delta = 0 }                       // clock stepped backwards: ignore
            if delta > 0.5 {                                  // background hop protection
                delta = 0.5
                droppedSteps += 1
            }
            accumulator += delta
        } else {
            accumulator = 0
        }
        lastNow = t

        var steps = 0
        while accumulator >= stepDuration {
            accumulator -= stepDuration
            stepIndex += 1
            simTime += stepDuration
            steps += 1
            if steps >= maxStepsPerFrame {
                if accumulator >= stepDuration {
                    droppedSteps += 1
                    accumulator = 0                         // truncate stale sim time (contract)
                }
                break
            }
        }
        return steps
    }

    /// Deterministic replay path: steps the clock by exactly one fixed step.
    /// Returns time of the step that was executed.
    @discardableResult
    public func advanceSingle(dropping: Bool = false) -> Double? {
        guard !isPaused else { return nil }
        if dropping {
            droppedSteps += 1
        }
        stepIndex += 1
        simTime += stepDuration
        return simTime
    }

    public func snapshot() -> Snapshot {
        Snapshot(stepIndex: stepIndex, simTime: simTime, isPaused: isPaused, droppedSteps: droppedSteps)
    }
}