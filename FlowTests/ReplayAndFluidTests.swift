import Foundation
import Testing
import simd

@testable import Flow

struct ReplayAndFluidTests {

    private func loadFixture(_ name: String) throws -> ReplayEngine {
        // fixtures are embedded in the host app bundle (Tests/Fixtures resources)
        let bundles = [Bundle.main] + Bundle.allBundles
        for bundle in bundles {
            if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: nil) {
                return try ReplayEngine(url: url)
            }
        }
        throw FixtureLoader.FixtureError.notFound(name)
    }

    @Test func testReplayFixtureUsesStableSeedAndOrdering() throws {
        let engine = try loadFixture("spiral")
        #expect(engine.fixture.schemaVersion == 1)
        #expect(engine.fixture.seed > 0)
        engine.start()
        let a = engine.samplesUpTo(simTime: 3.0)
        engine.reset()
        engine.start()
        let b = engine.samplesUpTo(simTime: 3.0)
        #expect(a == b)
        // stable time ordering
        for i in 1..<a.count {
            let x = a[i - 1], y = a[i]
            if x.time == y.time { #expect(x.touchID <= y.touchID) }
            else { #expect(x.time <= y.time) }
        }
    }

    @Test func testReplaySamplesUpToReturnsExactlyUpToBoundary() throws {
        let engine = try loadFixture("tap")
        engine.start()
        let all = engine.samplesUpTo(simTime: 0.3)
        #expect(all.count == 2)
        let after = engine.samplesUpTo(simTime: 0.5)
        #expect(after.isEmpty)
        #expect(engine.currentTime == 0)
    }

    @Test func testCancelledTouchMappedToCancelledPhase() throws {
        let engine = try loadFixture("crossing")
        engine.start()
        let all = engine.samplesUpTo(simTime: 2.0)
        #expect(all.contains { ReplayEngine.phaseKind($0.phase) == .cancelled })
        #expect(all.filter { $0.touchID == 1 && $0.phase == "moved" }.count > 0)
    }

    @Test func testBoundedInjectionNeverExceedsAlpha() {
        var a: Float = 0
        var rgb: SIMD3<Float> = .zero
        // 1000 rapid injections would saturate, not overflow
        for _ in 0..<1000 {
            if a >= 1 - 1e-5 { break }
            (a, rgb) = FluidMath.boundedInjection(currentAlpha: a,
                                                  currentPremulRGB: rgb,
                                                  targetColor: SIMD3(0.4, 0.1, 0.8),
                                                  s: 0.05)
        }
        #expect(a <= 1.0)
        #expect(rgb.x <= a + 1e-4 && rgb.y <= a + 1e-4 && rgb.z <= a + 1e-4)
    }

    @Test func testDampFactorMatchesContract() {
        let f = FluidMath.dampFactor(dt: 0.8, halfLife: 0.8)
        #expect(abs(f - 0.5) < 1e-6)
    }

    @Test func testAdvectBackRespectsClamp() {
        let back = FluidMath.advectBack(uv: SIMD2(0.1, 0.1),
                                        velShortSide: SIMD2(-5, -5),
                                        invIso: SIMD2(0.5, 1), dt: 1.0 / 120.0)
        #expect(back.x >= 0 && back.x <= 1)
        #expect(back.y >= 0 && back.y <= 1)
    }

    @Test func testResizePreservesAspectAndDoesNotStretchCircles() throws {
        // iPad landscape drawable (1728×1328 → short side = height)
        let config = SimulationConfig()
        let w = FlowRenderer.simWidthForStatic(pixelW: 1728, pixelH: 1328, config: config)
        let h = FlowRenderer.simHeightForStatic(pixelW: 1728, pixelH: 1328, config: config)
        #expect(w >= h)
        let aspectGrid = Double(w) / Double(h)
        let aspectDraw = 1728.0 / 1328.0
        #expect(abs(aspectGrid - aspectDraw) < 0.02)
        // portrait iPhone 1170×2532: short side = width
        let pw = FlowRenderer.simWidthForStatic(pixelW: 1170, pixelH: 2532, config: config)
        let ph = FlowRenderer.simHeightForStatic(pixelW: 1170, pixelH: 2532, config: config)
        #expect(pw < ph)
        #expect(abs(Double(pw) / Double(ph) - 1170.0 / 2532.0) < 0.02)
    }
}