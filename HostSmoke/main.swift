// Host-level smoke test for the pure-CPU core of Flow Prototype 01.
// Runs on macOS with the CLI Swift toolchain — REAL runtime evidence for the
// deterministic CPU layer. Does NOT replace iOS/GPU gates (see PROGRESS.md).
// Depends only on FlowApp modules that do not require UIKit/Metal.
import Foundation

var passed = 0
var failed = 0
@MainActor
func check(_ cond: Bool, _ name: String) {
    if cond { passed += 1; print("PASS  \(name)") }
    else { failed += 1; print("FAIL  \(name)") }
}

// --- SimulationClock ---
do {
    let dt60 = 1.0 / 60.0, dt120 = 1.0 / 120.0
    let c60 = SimulationClock(stepDuration: dt60, maxStepsPerFrame: 3)
    var t = 0.0
    while t < 2.0 { c60.advance(now: t); t += dt60 }
    c60.advance(now: 2.0)   // flush the tail
    let c120 = SimulationClock(stepDuration: dt120, maxStepsPerFrame: 3)
    t = 0.0
    while t < 2.0 { c120.advance(now: t); t += dt120 }
    c120.advance(now: 2.0)
    check(abs(c60.simTime - c120.simTime) < 1e-3, "60Hz & 120Hz yield same physics time")

    let c = SimulationClock(stepDuration: 1.0 / 120.0, maxStepsPerFrame: 3)
    c.advance(now: 0.5); let t1 = c.simTime
    c.pause(); c.advance(now: 2.0)
    check(t1 == c.simTime, "pause does not accumulate wall time")
    c.resume(); c.advance(now: 2.5)
    check(c.simTime <= 2.0 / 120.0 + t1 + 1e-6, "resume does not jump")

    c.resetToZero(resetPause: false)
    check(c.simTime == 0, "resetToZero resets simTime")
}

// --- InputNormalizer ---
do {
    let n = InputNormalizer()
    n.setCanvasSize(points: CGSize(width: 390, height: 844))
    check(n.normalizedPoint(CGPoint(x: 195, y: 844)) == SIMD2<Float>(0.5, 1.0),
          "normalized coordinates respect canvas size")
    n.ingest(touchID: 1, phase: .began, timestamp: 0, normalized: SIMD2(0.2, 0.2))
    n.ingest(touchID: 2, phase: .began, timestamp: 0, normalized: SIMD2(0.8, 0.8))
    n.ingest(touchID: 1, phase: .moved, timestamp: 0.01, normalized: SIMD2(0.3, 0.2))
    n.ingest(touchID: 2, phase: .moved, timestamp: 0.01, normalized: SIMD2(0.7, 0.8))
    check(n.activeTouchCount == 2, "two touches independent")
    _ = n.segmentsForStep(spacingFraction: 0.025)              // advance finger 1's cursor
    n.ingest(touchID: 2, phase: .moved, timestamp: 0.01, normalized: SIMD2(0.7, 0.8)) // dup
    let segs2 = n.segmentsForStep(spacingFraction: 0.025)
    check(segs2.isEmpty, "duplicate-timestamp samples are deduped (no re-injection)")
    // distance from last injected to current must be below spacing after dedupe
    check(segs2.allSatisfy { $0.velocity.x.isFinite && $0.velocity.y.isFinite },
          "no NaN from dup input")

    // zero-length
    let n2 = InputNormalizer()
    n2.ingest(touchID: 9, phase: .began, timestamp: 0.5, normalized: SIMD2(0.5, 0.5))
    n2.ingest(touchID: 9, phase: .ended, timestamp: 0.51, normalized: SIMD2(0.5, 0.5))
    for s in n2.segmentsForStep(spacingFraction: 0.025) { check(s.isTap, "tap flagged") }

    // velocity clamp
    let n3 = InputNormalizer()
    n3.ingest(touchID: 1, phase: .began, timestamp: 0, normalized: SIMD2(0.1, 0.5))
    n3.ingest(touchID: 1, phase: .moved, timestamp: 0.001, normalized: SIMD2(0.99, 0.5))
    for s in n3.segmentsForStep(spacingFraction: 0.025) {
        let speed = sqrt(s.velocity.x * s.velocity.x + s.velocity.y * s.velocity.y)
        check(speed <= n3.options.maxInputSpeed + 0.01, "input velocity clamped")
    }
}

// --- FluidMath reference ---
do {
    var a: Float = 0; var rgb = SIMD3<Float>.zero
    for _ in 0..<2000 {
        if a >= 1 - 1e-5 { break }
        (a, rgb) = FluidMath.boundedInjection(currentAlpha: a, currentPremulRGB: rgb,
                                             targetColor: SIMD3(0.4, 0.1, 0.8), s: 0.05)
    }
    check(a <= 1.0, "bounded injection never overflows alpha")
    check(rgb.x <= a + 1e-4 && rgb.y <= a + 1e-4 && rgb.z <= a + 1e-4, "premultiplied invariant holds")
    let f = FluidMath.dampFactor(dt: 0.8, halfLife: 0.8)
    check(abs(f - 0.5) < 1e-6, "damping factor math")

    let back = FluidMath.advectBack(uv: SIMD2(0.1, 0.1), velShortSide: SIMD2(-5, -5),
                                    invIso: SIMD2(0.5, 1), dt: 1.0 / 120.0)
    check(back.x >= 0 && back.x <= 1 && back.y >= 0 && back.y <= 1, "advect back-clamp")
}

// --- ShaderBridge layouts ---
check(ShaderBridge.assertLayouts(), "Swift struct layouts match contract (88/64)")

// --- ReplayEngine determinism ---
let fixturesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Tests/Fixtures", isDirectory: true)
for name in ["tap", "slow-stroke", "fast-swipe", "spiral", "two-fingers", "crossing", "four-fingers"] {
    do {
        let url = fixturesDir.appendingPathComponent("\(name).json")
        let e1 = try ReplayEngine(url: url)
        e1.start()
        let a = e1.samplesUpTo(simTime: 100)
        e1.reset(); e1.start()
        let b = e1.samplesUpTo(simTime: 100)
        check(a == b, "fixture \(name): deterministic ordering")
        check(e1.fixture.schemaVersion == 1, "fixture \(name): schemaVersion")
        var prevTime = -1.0
        var ordered = true
        for s in a {
            if s.time < prevTime { ordered = false; break }
            prevTime = s.time
        }
        check(ordered, "fixture \(name): strictly time-ordered")
    } catch {
        check(false, "fixture \(name): load error \(error)")
    }
}

// --- Grid sizing (mirrors FlowRenderer.sim*ForStatic; formula kept here so the
//     host test stays free of Metal/UIKit imports) ---
func simWidthForStatic(pixelW: Int, pixelH: Int, _ c: SimulationConfig) -> Int {
    let short = c.gridPreset.shortSideTexels
    let aspect = Double(max(pixelW, 1)) / Double(max(pixelH, 1))
    let longSide = Int(Float(short) * Float(max(aspect, 1.0 / max(aspect, 1e-4))))
    return pixelW >= pixelH ? min(longSide, c.maxLongSideTexels) : short
}
func simHeightForStatic(pixelW: Int, pixelH: Int, _ c: SimulationConfig) -> Int {
    let short = c.gridPreset.shortSideTexels
    let aspect = Double(max(pixelW, 1)) / Double(max(pixelH, 1))
    let longSide = Int(Float(short) * Float(max(aspect, 1.0 / max(aspect, 1e-4))))
    return pixelW >= pixelH ? short : min(longSide, c.maxLongSideTexels)
}
do {
    let c = SimulationConfig()
    let iP = (w: 1728, h: 1328)
    let gw = simWidthForStatic(pixelW: iP.w, pixelH: iP.h, c)
    let gh = simHeightForStatic(pixelW: iP.w, pixelH: iP.h, c)
    check(gw >= gh, "landscape grid wide")
    check(abs(Double(gw) / Double(gh) - Double(iP.w) / Double(iP.h)) < 0.02, "grid aspect ≈ drawable aspect")
    let pw = simWidthForStatic(pixelW: 1170, pixelH: 2532, c)
    let ph = simHeightForStatic(pixelW: 1170, pixelH: 2532, c)
    check(pw < ph, "portrait grid tall")
    let cap = simWidthForStatic(pixelW: 4000, pixelH: 1000, c)
    check(cap == c.maxLongSideTexels, "grid long side capped at 1024")
}

print("---")
print("host-smoke: \(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)