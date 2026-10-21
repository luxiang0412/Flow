import SwiftUI
import UIKit
import MetalKit

/// SwiftUI wrapper owning the MTKView + FlowRenderer stack (§3.2/§3.3).
/// The renderer is created once in `makeUIView` and retained by Coordinator;
/// `updateUIView` only applies queued control ops (no per-frame work here).
struct MetalCanvas: UIViewRepresentable {

    @ObservedObject var model: ControlModel

    final class Coordinator {
        var renderer: FlowRenderer?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> FlowMetalView {
        let view = FlowMetalView(frame: .zero, input: model.input)
        guard let renderer = FlowRenderer(view: view,
                                          config: model.config,
                                          metricsStore: model.metricsStore,
                                          inputBuffer: model.input) else {
            model.error = "Metal renderer could not be initialized"
            return view
        }
        context.coordinator.renderer = renderer
        return view
    }

    func updateUIView(_ uiView: FlowMetalView, context: Context) {
        guard let renderer = context.coordinator.renderer else { return }
        for op in model.drainOps() {
            switch op {
            case .pauseRequested(let paused):
                paused ? renderer.pause() : renderer.resume()
            case .clearRequested:
                renderer.clearRequested()
            case .startReplay(let name, let extraCaptures):
                do {
                    let engine = try FixtureLoader.load(name: name)
                    renderer.pendingDumpFPS = model.dumpFramesFPS
                    renderer.metricsLoggingEnabled = model.metricsLog
                    renderer.loopReplayEnabled = model.loopReplay
                    renderer.startReplay(engine, extraCaptures: extraCaptures)
                } catch {
                    ErrorStatus.shared.record(severity: .warning, source: "replay", "\(error)")
                    model.error = "Fixture \"\(name)\" load failed: \(error.localizedDescription)"
                }
            case .stopReplay:
                renderer.stopReplay()
            case .capture(let tag):
                renderer.requestCapture(tag: tag)
            case .setConfig(let c):
                renderer.applyConfig(c)
            case .setStatsEnabled(let on):
                renderer.setStatsEnabled(on)
            }
        }
    }
}