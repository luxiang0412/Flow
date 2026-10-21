import SwiftUI
import UIKit

/// Minimal Debug control surface (contract §4.2) — Debug builds only.
/// Collapsed by default; no per-frame SwiftUI recompute (metrics poll ~2 Hz).
struct DebugOverlay: View {
    @ObservedObject var model: ControlModel
    @Environment(\.horizontalSizeClass) private var hClass

    @State private var flowValue: Double = 0.5
    @State private var glowValue: Double = 0.35
    @State private var inkValue: Double = 0.5
    @State private var showMetrics = false

    var body: some View {
        Group {
            if hClass == .regular {
                // iPad: fixed floating panel on the leading edge, off the canvas
                sidePanel
                    .frame(width: 260)
                    .padding(.leading, 12)
            } else {
                // iPhone: small bottom sheet, collapsed by default
                bottomSheet
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
            }
        }
        .onChange(of: flowValue) { _, _ in debounceConfig() }
        .onChange(of: glowValue) { _, v in debounceConfig() }
        .onChange(of: inkValue) { _, v in debounceConfig() }
    }

    private func debounceConfig() {
        let f = SimulationConfig.flow(Float(flowValue))
        var c = model.config
        c.touchMomentumGain = f.gain
        c.velocityHalfLife = f.halfLife
        c.glowStrength = SimulationConfig.glow(Float(glowValue))
        c.pigmentHalfLife = SimulationConfig.inkLifetime(Float(inkValue))
        model.enqueue(.setConfig(c))
    }

    private var bottomSheet: some View {
        VStack(spacing: 6) {
            if !model.overlayCollapsed {
                controlsGrid
            }
            HStack {
                Button(action: { model.overlayCollapsed.toggle() }) {
                    Image(systemName: model.overlayCollapsed ? "slider.horizontal.3" : "chevron.down")
                        .frame(width: 36, height: 36)
                        .accessibilityLabel("Toggle Debug Panel")
                }
                .buttonStyle(.bordered)
                Spacer()
                if showMetrics { metricsBar }
                Spacer()
                Text("Flow")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flow · Debug").font(.subheadline.bold())
            controlsGrid
            if showMetrics {
                Divider()
                metricsList
            }
            if let err = model.error {
                Text(err).font(.caption).foregroundStyle(.red).lineLimit(3)
            }
            Text(infoLine).font(.caption2).foregroundStyle(.secondary)
            Button(model.overlayCollapsed ? "Show" : "Hide") {
                withAnimation(.easeInOut(duration: 0.2)) { model.overlayCollapsed.toggle() }
            }
            .accessibilityLabel("Hide debug panel")
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var controlsGrid: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: { model.enqueue(.pauseRequested(!model.isPaused)) }) {
                    Label(model.isPaused ? "Resume" : "Pause", systemImage: model.isPaused ? "play.fill" : "pause.fill")
                }
                .accessibilityLabel(model.isPaused ? "Resume simulation" : "Pause simulation")
                Button(action: { model.enqueue(.clearRequested) }) {
                    Label("Clear", systemImage: "trash")
                }
                .accessibilityLabel("Clear canvas")
                Button(action: { model.enqueue(.capture("ui-manual")) }) {
                    Label("Capture", systemImage: "camera")
                }
                .accessibilityLabel("Capture current frame")
            }
            HStack {
                Menu {
                    ForEach(model.fixtureNames, id: \.self) { name in
                        Button(name) { model.enqueue(.startReplay(name, extraCaptures: [])) }
                    }
                    Button("Stop") { model.enqueue(.stopReplay) }
                } label: {
                    Label("Replay: \(model.activeReplay ?? "off")", systemImage: "arrow.triangle.2.circlepath")
                }
                .accessibilityIdentifier("replay-menu")
                Button(showMetrics ? "Metrics on" : "Metrics off") { showMetrics.toggle() }
                    .accessibilityLabel("Show live metrics")
            }
            slider("Flow", value: $flowValue, hint: "momentum & damping")
            slider("Glow", value: $glowValue, hint: "visual only")
            slider("Ink Life", value: $inkValue, hint: "debug only")
        }
    }

    private func slider(_ title: String, value: Binding<Double>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue)).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...1)
                .accessibilityLabel("\(title) \(hint)")
        }
    }

    private var metricsBar: some View {
        Text(String(format: "%.0f fps · %dx%d · t%d", model.metrics.fps,
                    model.metrics.simWidth, model.metrics.simHeight, model.metrics.activeTouches))
            .font(.caption.monospacedDigit())
    }

    private var metricsList: some View {
        VStack(alignment: .leading, spacing: 2) {
            row("FPS", String(format: "%.1f", model.metrics.fps))
            row("P50", String(format: "%.1f ms", model.metrics.frameIntervalMsP50))
            row("P95", String(format: "%.1f ms", model.metrics.frameIntervalMsP95))
            row("sim", "\(model.metrics.simWidth)×\(model.metrics.simHeight)")
            row("drawable", "\(model.metrics.drawableWidth)×\(model.metrics.drawableHeight)")
            row("touches", "\(model.metrics.activeTouches)")
            row("replay", model.metrics.replayName)
            row("t(ms)", String(format: "%.0f", model.metrics.simTime * 1000))
            row("NaN", "\(model.metrics.nanCount)")
            row("Inf", "\(model.metrics.infCount)")
            row("device", "\(ConfigResolver.simulator ? "SIMULATOR" : UIDevice.current.model)")
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(v).font(.caption2.monospacedDigit())
        }
    }

    private var infoLine: String {
        "measured FPS · grid \(model.metrics.simWidth)x\(model.metrics.simHeight) · "
        + "touches \(model.metrics.activeTouches) · \(model.metrics.replayName != "-" ? "replay:\(model.metrics.replayName)" : "live")"
        + " · \(ConfigResolver.simulator ? "SIMULATOR" : UIDevice.current.model)"
    }
}