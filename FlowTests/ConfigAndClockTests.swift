import Foundation
import Testing
import simd

@testable import Flow

// Reference: FLOW-PROTOTYPE-01.md §9.1 / §5
struct ConfigAndClockTests {

    /// Contract §5.6 gives *tuning ranges*, not fixed finals: the table values
    /// are explicitly “起点，非已经过验证的终值”. We therefore assert the ranges.
    @Test func testDefaultConfigSatisfiesContractRanges() {
        let c = SimulationConfig()
        #expect(c.simulationStep == 1.0 / 120.0)
        #expect(c.velocityHalfLife >= 0.4 && c.velocityHalfLife <= 1.6)
        #expect(c.pigmentHalfLife >= 4.0 && c.pigmentHalfLife <= 16.0)
        #expect(c.detailHalfLife >= 1.5 && c.detailHalfLife <= 6.0)
        #expect(c.radiusFraction >= 0.01 && c.radiusFraction <= 0.05)
        #expect(c.maxVelocity > 0 && c.maxVelocity <= 2.5)
        #expect(c.gridPreset.shortSideTexels == 512)
    }

    /// The one-shot tap burst must stay apart from the stroke parameters,
    /// otherwise a light touch saturates its footprint into a flat stamp.
    @Test func testTapBurstIsSeparateFromStrokeInjection() {
        let c = SimulationConfig()
        #expect(c.tapRadiusScale > 1.0)
        #expect(c.tapDyeRadiusScale > 0 && c.tapDyeRadiusScale <= 1.0)
        #expect(c.tapHoldDye < c.tapDye)
        #expect(c.tapRadialPush < c.touchMomentumGain)
    }

    @Test func testFlowSliderMapsToRestrictedValues() {
        let low = SimulationConfig.flow(0)
        #expect(low.gain >= 1.0 && low.gain <= 4.0)
        #expect(low.halfLife >= 1.2)
        let high = SimulationConfig.flow(1)
        #expect(high.gain > low.gain)
        #expect(high.halfLife < low.halfLife)
    }

    @Test func testFixedStepAt60And120HzHasSamePhysicsTime() {
        let dt60 = 1.0 / 60.0
        let dt120 = 1.0 / 120.0
        let c60 = SimulationClock(stepDuration: dt60, maxStepsPerFrame: 3)
        let wall = 2.0
        var t = 0.0
        while t < wall {
            c60.advance(now: t)
            t += dt60
        }
        c60.advance(now: wall)   // flush remaining accumulator
        let c120 = SimulationClock(stepDuration: dt120, maxStepsPerFrame: 3)
        t = 0.0
        while t < wall {
            c120.advance(now: t)
            t += dt120
        }
        c120.advance(now: wall)
        // same physics time regardless of frame cadence
        #expect(abs(c60.simTime - c120.simTime) < 1e-3)
    }

    @Test func testPauseResumeDoesNotAccumulateElapsedWallTime() {
        let c = SimulationClock(stepDuration: 1.0 / 120.0, maxStepsPerFrame: 3)
        c.advance(now: 0.5)          // some steps
        let t1 = c.simTime
        c.pause()
        _ = c.advance(now: 2.0)      // long pause ignored
        let t2 = c.simTime
        #expect(t1 == t2)
        c.resume()
        c.advance(now: 2.5)
        // resume does not jump by the paused seconds
        #expect(c.simTime <= 2.0 / 120.0 + t1 + 1e-6)
    }

    @Test func testOverloadDropsStaleTimeNotSteps() {
        let c = SimulationClock(stepDuration: 1.0 / 120.0, maxStepsPerFrame: 3)
        c.advance(now: 0.0)
        var steps = c.advance(now: 0.5)   // 500 ms burst → capped at 3
        #expect(steps <= 3)
        #expect(c.droppedSteps > 0)
        let t = c.simTime
        c.advance(now: 0.5001)
        #expect(c.simTime >= t)
    }
}