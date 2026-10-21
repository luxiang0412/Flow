import SwiftUI

@main
struct FlowApp: App {
    @StateObject private var model = ControlModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onAppear { applyLaunchOptions() }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .background:
                        // Contract §5.9: only a real background transition pauses
                        // drawing. `.inactive` also fires when the Simulator window
                        // loses focus, which froze the canvas (and broke scripted
                        // screenshot/video runs), so it is deliberately ignored.
                        model.enqueue(.pauseRequested(true))
                    case .active:
                        model.enqueue(.pauseRequested(false))
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }

    /// Debug CLI behavior (contract §6.1). Ignored outside Debug builds.
    private func applyLaunchOptions() {
        #if DEBUG
        let options = LaunchOptions.parse(ProcessInfo.processInfo.arguments)
        if options.seed != nil { model.config.seed = options.seed! }
        if options.fixedDt != nil { model.config.simulationStep = options.fixedDt! }
        if let g = options.gridShortSide,
           let preset = SimulationConfig.GridPreset.allCases.first(where: { $0.shortSideTexels == g }) {
            model.config.gridPreset = preset
            NSLog("[Flow][launch] grid preset \(preset.label)")
        }
        if options.disableBloom { model.config.bloomEnabled = false }
        if options.disableDetail { model.config.detailEnabled = false }
        model.enqueue(.setConfig(model.config))
        model.dumpFramesFPS = options.dumpFramesFPS
        model.metricsLog = options.metricsLog
        model.loopReplay = options.loopReplay
        if let name = options.replayName {
            model.enqueue(.startReplay(name, extraCaptures: options.captureAt))
        }
        NSLog("[Flow][launch] options=%@",
              String(describing: options))
        #endif
    }
}