import Foundation
import Testing
import simd

@testable import Flow

struct InputNormalizerTests {

    private func makeNormalizer() -> InputNormalizer {
        let n = InputNormalizer()
        n.setCanvasSize(points: CGSize(width: 200, height: 400))   // portrait canvas
        return n
    }

    @Test func testNormalizedCoordinatesRespectAspectRatio() {
        let n = makeNormalizer()
        let p = n.normalizedPoint(CGPoint(x: 50, y: 100))
        #expect(p.x == 0.25)
        #expect(p.y == 0.25)
        // aspect independence: normalized coords [0,1]² regardless of pixel aspect
        n.setCanvasSize(points: CGSize(width: 400, height: 200))
        let q = n.normalizedPoint(CGPoint(x: 100, y: 100))
        #expect(q.x == 0.25 && q.y == 0.5)
    }

    @Test func testTouchIDsStayIndependentDuringInterleaving() {
        let n = makeNormalizer()
        n.ingest(touchID: 1, phase: .began, timestamp: 0.0, normalized: SIMD2(0.2, 0.2))
        n.ingest(touchID: 2, phase: .began, timestamp: 0.0, normalized: SIMD2(0.8, 0.8))
        n.ingest(touchID: 1, phase: .moved, timestamp: 0.01, normalized: SIMD2(0.21, 0.2))
        n.ingest(touchID: 2, phase: .moved, timestamp: 0.01, normalized: SIMD2(0.79, 0.8))
        #expect(n.activeTouchCount == 2)
        n.ingest(touchID: 2, phase: .cancelled, timestamp: 0.02, normalized: SIMD2(0.79, 0.8))
        #expect(n.activeTouchCount == 1)
    }

    @Test func testCoalescedSampleDeduplication() {
        let n = makeNormalizer()
        n.ingest(touchID: 0, phase: .began, timestamp: 1.0, normalized: SIMD2(0.5, 0.5))
        n.ingest(touchID: 0, phase: .moved, timestamp: 1.1, normalized: SIMD2(0.55, 0.5))
        _ = n.segmentsForStep(spacingFraction: 0.025)   // emit the segment span
        // duplicate sample (same timestamp + position) must be absorbed:
        n.ingest(touchID: 0, phase: .moved, timestamp: 1.1, normalized: SIMD2(0.55, 0.5))
        let again = n.segmentsForStep(spacingFraction: 0.025)
        // nothing new is injected (cursor already reached the position)
        #expect(again.isEmpty)
    }

    @Test func testZeroLengthStrokeDoesNotGenerateNaN() {
        let n = makeNormalizer()
        n.ingest(touchID: 3, phase: .began, timestamp: 0.5, normalized: SIMD2(0.5, 0.5))
        n.ingest(touchID: 3, phase: .ended, timestamp: 0.51, normalized: SIMD2(0.5, 0.5))
        for seg in n.segmentsForStep(spacingFraction: 0.025) {
            #expect(seg.velocity.x.isFinite && seg.velocity.y.isFinite)
            #expect(seg.isTap)
        }
    }

    @Test func testVelocityClamp() {
        let n = makeNormalizer()
        n.ingest(touchID: 9, phase: .began, timestamp: 0.0, normalized: SIMD2(0.1, 0.5))
        // unreasonably fast move (huge distance in 1 ms)
        n.ingest(touchID: 9, phase: .moved, timestamp: 0.001, normalized: SIMD2(0.99, 0.5))
        let segs = n.segmentsForStep(spacingFraction: 0.025)
        for seg in segs {
            let speed = simd_length(seg.velocity)
            #expect(speed <= n.options.maxInputSpeed + 0.01)
        }
    }

    @Test func testMissingPencilPressureUsesNeutralValue() {
        let s = TouchSample(touchID: 1, phase: .began, timestamp: 0, position: .zero)
        #expect(s.force == TouchSample.neutralForce)
        let t = TouchSample(touchID: 1, phase: .began, timestamp: 0, position: .zero,
                            normalizedForce: 0.9)
        #expect(t.force == 0.9)
    }

    @Test func testInterpolationSpacingIsDensityBounded() {
        let n = makeNormalizer()
        n.setCanvasSize(points: CGSize(width: 390, height: 844))
        n.ingest(touchID: 0, phase: .began, timestamp: 0, normalized: SIMD2(0.1, 0.5))
        n.ingest(touchID: 0, phase: .moved, timestamp: 1.0, normalized: SIMD2(0.9, 0.5))
        let radiusFrac: Float = 0.025
        let segs = n.segmentsForStep(spacingFraction: radiusFrac)
        #expect(segs.count > 1)
        guard segs.count > 1 else { return }
        for i in 1..<segs.count {
            let prev = segs[i - 1].position
            let cur = segs[i].position
            let dx = Float(844.0 / 390.0) // short side = width in points
            _ = dx
            let d = simd_distance(prev, cur)
            // normalized-space distance is bounded by short-side*spacingFactor*radius
            let shortInNormalized = Float(390.0 / 390.0)
            #expect(d <= radiusFrac * 0.4 * shortInNormalized + 1e-3)
        }
    }
}