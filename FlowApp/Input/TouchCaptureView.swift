import Foundation
import MetalKit
import UIKit

/// Main-thread shared queue of live samples produced by FlowMetalView and
/// consumed each frame by FlowRenderer. Single caller per side.
public final class TouchInputBuffer: @unchecked Sendable {
    private var pending: [TouchSample] = []
    public init() {}
    public func append(_ s: TouchSample) { pending.append(s) }
    public func drain() -> [TouchSample] {
        let out = pending
        pending.removeAll(keepingCapacity: true)
        return out
    }
    public var count: Int { pending.count }
}

/// MTKView that captures real touch input (multi-touch + coalesced + Pencil)
/// and converts it to normalized `TouchSample` values (contract §5.2 / §3.2).
/// Drawing is driven by `FlowRenderer` (delegate). GPU solve never runs here.
public final class FlowMetalView: MTKView {

    private let input: TouchInputBuffer

    public init(frame: CGRect, input: TouchInputBuffer) {
        self.input = input
        super.init(frame: frame, device: nil)
        isMultipleTouchEnabled = true
        isUserInteractionEnabled = true
        isAccessibilityElement = true
        accessibilityLabel = "Luminous Ink canvas"
        accessibilityIdentifier = "Luminous Ink canvas"
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("not used") }

    // MARK: Touch handling
    private func normalized(_ p: CGPoint) -> SIMD2<Float> {
        let w = max(bounds.width, 1e-4)
        let h = max(bounds.height, 1e-4)
        return SIMD2(Float(p.x / w), Float(p.y / h))
    }

    private func emit(touch: UITouch, phase: TouchSample.Phase, from event: UIEvent) {
        // Predicted touches (event.predictedTouches) are deliberately ignored:
        // contract §5.2 — predicted samples never enter the permanent simulation.
        let kind: TouchSample.InputKind = touch.type == .stylus ? .pencil : .finger
        let base = normalized(touch.location(in: self))
        let coalesced = event.coalescedTouches(for: touch)
        var samples: [TouchSample] = []
        if let coalesced, !coalesced.isEmpty {
            for (i, t) in coalesced.enumerated() {
                let isLast = i == coalesced.count - 1
                let p = normalized(t.location(in: self))
                let phase: TouchSample.Phase = isLast ? (touch.phase == .ended ? .ended :
                    touch.phase == .cancelled ? .cancelled : phaseFor(touch)) : .moved
                samples.append(makeSample(touch: t, pos: p, kind: kind,
                                          phase: phase, expectingUpdates: t.estimatedPropertiesExpectingUpdates))
            }
        } else {
            samples.append(makeSample(touch: touch, pos: base, kind: kind,
                                      phase: phase, expectingUpdates: touch.estimatedPropertiesExpectingUpdates))
        }
        // Phase differences retained: cancelled touches must not re-inject.
        if touch.phase == .cancelled {
            samples = [samples.last ?? TouchSample(touchID: touch.hashValue, phase: .cancelled,
                                                   timestamp: touch.timestamp, position: base)]
        }
        for s in samples { input.append(s) }
    }

    private func phaseFor(_ touch: UITouch) -> TouchSample.Phase {
        switch touch.phase {
        case .began: return .began
        case .moved: return .moved
        case .ended: return .ended
        case .cancelled: return .cancelled
        default: return .moved
        }
    }

    private func makeSample(touch: UITouch, pos: SIMD2<Float>, kind: TouchSample.InputKind,
                            phase: TouchSample.Phase,
                            expectingUpdates: UITouch.Properties) -> TouchSample {
        // Stable ID from hashValue of the touch — documented as session-local
        // only (not persisted); UIKit reuses UITouch instances per interaction.
        let force: Float?
        if touch.force >= 0, expectingUpdates.contains(.force) == false,
           touch.maximumPossibleForce > 0 {
            force = Float(touch.force / touch.maximumPossibleForce)
        } else {
            force = nil
        }
        let alt: Float? = expectingUpdates.contains(.altitude) ? nil : touch.altitudeAngle.isFinite ? Float(touch.altitudeAngle) : nil
        let azm: Float? = expectingUpdates.contains(.azimuth) ? nil : Float(touch.azimuthAngle(in: self))
        return TouchSample(touchID: touch.hashValue,
                           phase: phase,
                           timestamp: touch.timestamp,
                           position: pos,
                           inputKind: kind,
                           normalizedForce: force,
                           altitudeRadians: alt,
                           azimuthRadians: azm)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let event else { return }
        for t in touches { emit(touch: t, phase: .began, from: event) }
    }
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let event else { return }
        for t in touches { emit(touch: t, phase: .moved, from: event) }
    }
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let event else { return }
        for t in touches { emit(touch: t, phase: .ended, from: event) }
    }
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let event else { return }
        for t in touches { emit(touch: t, phase: .cancelled, from: event) }
    }
}