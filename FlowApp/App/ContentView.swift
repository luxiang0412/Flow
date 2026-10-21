import SwiftUI

struct ContentView: View {
    @ObservedObject var model: ControlModel

    var body: some View {
        ZStack {
            Color(red: 7.0 / 255, green: 10.0 / 255, blue: 19.0 / 255).ignoresSafeArea()
            MetalCanvas(model: model)
                .ignoresSafeArea()
            if let err = model.error {
                VStack {
                    Text("Renderer unavailable: \(err)")
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black.opacity(0.7))
                        .accessibilityLabel("Renderer error")
                    Spacer()
                }
                .padding(.top, 8)
            }
            #if DEBUG
            if !model.overlayCollapsed {
                DebugOverlay(model: model)
            } else {
                // keep a small unobtrusive reopen affordance
                VStack { Spacer(); HStack { Spacer(); ReopenButton(model: model) } }
                    .padding(8)
            }
            #endif
        }
        .task {
            // ~2 Hz metrics poll; no per-frame SwiftUI recompute.
            while !Task.isCancelled {
                model.refreshMetrics()
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
}

#if DEBUG
private struct ReopenButton: View {
    @ObservedObject var model: ControlModel
    var body: some View {
        Button {
            model.overlayCollapsed = false
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Open debug panel")
        .accessibilityIdentifier("Open debug panel")
        .buttonStyle(.plain)
    }
}
#endif

#Preview {
    ContentView(model: ControlModel())
}