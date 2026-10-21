import Foundation
import Metal
import MetalKit
import QuartzCore
import simd

/// Owns all GPU state, pass scheduling and deterministic stepping.
///
/// Concurrency: all methods are called from a single serial context (MTKView
/// display-link thread ≈ main run loop). Live touches are drained from
/// `inputBuffer` on the same thread. No Sendable crossing; documented
/// single-caller rule in docs/DECISIONS.md.
///
/// Resource ownership (§3.2/§3.3):
///  - device / queue / pipelines / full-size textures are created once.
///  - small per-frame *uniform/event buffers* are allocated per fixed step
///    (a few KB) to avoid in-flight write hazards; documented in DECISIONS.md.
///
/// Isolation: `@MainActor` because it owns the `MTKView` (main-actor isolated in
/// Xcode 16.4+) and is created from `UIViewRepresentable.makeUIView`. MTKView
/// drives `draw(in:)` on the main run loop, so the delegate entry points are
/// `nonisolated` shims that use `MainActor.assumeIsolated`.
@MainActor
final class FlowRenderer: NSObject, MTKViewDelegate {

    // MARK: Dependencies
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    unowned let view: FlowMetalView
    let metrics = FrameMetrics()
    let metricsStore: MetricsStore
    let inputBuffer: TouchInputBuffer

    // MARK: Config / state
    var config: SimulationConfig
    let normalizer = InputNormalizer()
    let clock = SimulationClock()
    var replayEngine: ReplayEngine?
    /// Extra absolute sim-time capture points requested via launch args.
    public private(set) var extraCaptureTimes: [Double] = []
    private var replayReportedDone = false
    private var replayStartWall: CFAbsoluteTime = 0

    // MARK: GPU resources
    private var textures: TextureSet!
    private var computePipelines: [String: MTLComputePipelineState] = [:]
    private var finalPipeline: MTLRenderPipelineState!
    private var readbackBuffer: MTLBuffer?
    private var readbackLength = 0

    // clear / stats / capture flags (drained inside draw)
    private var renderRequestedClear = false
    private var statsEnabled = false
    private var statsCounter = 0
    private var pendingFrameCaptureURL: URL?

    private var capturedKeys = Set<String>()
    private var captureTargets: [(time: Double, url: URL)] = []
    /// Deterministic frame-sequence dumping (Debug evidence: crisp video source).
    private var dumpInterval: Double = 0
    private var nextDumpTime: Double = 0
    private var dumpDirectory: URL?
    /// Small pool of shared readback buffers so several captures can be in flight.
    private var readbackPool: [MTLBuffer] = []
    private var readbackCursor = 0
    nonisolated private let pngQueue = DispatchQueue(label: "flow.capture.png", qos: .utility)
    /// True when composite+bloom were already encoded for the current frame
    /// (replay capture path encodes them mid-step; display reuses the result).
    private var compositeEncodedThisFrame = false
    private var lastMetricsPublish: CFAbsoluteTime = 0
    private var frameCounter: UInt64 = 0
    private var fpsWindowCount: UInt64 = 0
    private var fpsWindowStart: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    private let maxEvents = 128

    // MARK: Init
    init?(view: FlowMetalView, config: SimulationConfig, metricsStore: MetricsStore,
          inputBuffer: TouchInputBuffer) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            ErrorStatus.shared.record(severity: .fatal, source: "renderer", "no Metal device / queue")
            return nil
        }
        self.device = device
        self.commandQueue = queue
        self.view = view
        self.config = config
        self.metricsStore = metricsStore
        self.inputBuffer = inputBuffer
        super.init()

        let library = try? device.makeDefaultLibrary(bundle: Bundle(for: FlowRenderer.self))
        guard let lib = library else {
            ErrorStatus.shared.record(severity: .fatal, source: "renderer", "no default Metal library")
            return nil
        }
        guard ShaderBridge.assertLayouts(),
              setupPipelines(library: lib) else {
            ErrorStatus.shared.record(severity: .fatal, source: "renderer", "pipeline/layout setup failed")
            return nil
        }
        view.device = device
        view.delegate = self
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .invalid
        let bg = ShaderBridge.backgroundLinear
        view.clearColor = MTLClearColor(red: Double(bg.x), green: Double(bg.y),
                                        blue: Double(bg.z), alpha: 1)
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false
    }

    // MARK: Pipelines
    private func setupPipelines(library: MTLLibrary) -> Bool {
        let names = ["advectVelocity", "injectVelocity", "dampVelocity",
                     "advectPigment", "injectPigment", "decayPigment",
                     "advectDetail", "injectDetailDecay",
                     "compositePass", "bloomExtract", "bloomBlurH", "bloomBlurV",
                     "resampleState", "statsScan", "clearTex"]
        for name in names {
            guard let fn = library.makeFunction(name: name),
                  let ps = try? device.makeComputePipelineState(function: fn) else {
                ErrorStatus.shared.record(severity: .fatal, source: "renderer", "pipeline \(name) failed")
                return false
            }
            computePipelines[name] = ps
        }
        guard let v = library.makeFunction(name: "fullscreenVertex"),
              let f = library.makeFunction(name: "finishFragment") else {
            ErrorStatus.shared.record(severity: .fatal, source: "renderer", "final shaders missing")
            return false
        }
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = v
        rpd.fragmentFunction = f
        rpd.colorAttachments[0].pixelFormat = .bgra8Unorm
        rpd.colorAttachments[0].isBlendingEnabled = false
        do {
            finalPipeline = try device.makeRenderPipelineState(descriptor: rpd)
        } catch {
            ErrorStatus.shared.record(severity: .fatal, source: "renderer", "final render: \(error)")
            return false
        }
        return true
    }

    // MARK: MTKViewDelegate
    //
    // MTKView normally drives these on the main thread, but that is a runtime
    // guarantee we should not *trap* on: `MainActor.assumeIsolated` aborts the
    // process if it is ever called elsewhere (observed as an unexplained crash
    // on the CI runner). Hop to the main actor instead when needed.
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { resizeTo(drawable: size) }
        } else {
            NSLog("[Flow][warn] drawableSizeWillChange off-main; hopping to main actor")
            Task { @MainActor [weak self] in self?.resizeTo(drawable: size) }
        }
    }

    nonisolated func draw(in view: MTKView) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { renderFrame(in: view) }
        } else {
            // Cannot send MTKView across actors, so re-enter on the next run loop.
            NSLog("[Flow][warn] draw off-main; hopping to main actor")
            Task { @MainActor [weak self] in
                guard let self, let v = self.viewOrNil else { return }
                self.renderFrame(in: v)
            }
        }
    }

    /// Main-actor view reference used by the off-main fallback path.
    var viewOrNil: FlowMetalView? { view }

    private func renderFrame(in view: MTKView) {
        guard ShaderBridge.assertLayouts() else { return }
        metrics.beginFrame()
        metrics.stepsLastFrame = 0
        compositeEncodedThisFrame = false
        frameCounter += 1
        fpsWindowCount += 1
        let now = CFAbsoluteTimeGetCurrent()
        if now - fpsWindowStart >= 1.0 {
            let fps = Double(fpsWindowCount) / max(now - fpsWindowStart, 1e-6)
            _ = fps
            fpsWindowCount = 0
            fpsWindowStart = now
            fpsStore = fps
        }

        if textures == nil {
            textures = makeTextures(drawable: view.drawableSize)
        }

        if renderRequestedClear {
            clearAllTextures()
            renderRequestedClear = false
        }

        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            metrics.endFrame(encodeSeconds: 0)
            return
        }
        commandBuffer.label = "flow-frame-\(frameCounter)"

        if let replay = replayEngine {
            runReplaySteps(replay: replay, commandBuffer: commandBuffer)
        } else {
            let steps = clock.advance(now: CACurrentMediaTime())
            if steps > 0 {
                let live = inputBuffer.drain()
                for s in live { ingest(sample: s) }
            }
            metrics.stepsLastFrame = 0
            for _ in 0..<steps {
                runFixedStep(commandBuffer: commandBuffer)
                metrics.stepsLastFrame += 1
            }
        }

        compositeAndRenderIfNeeded(commandBuffer: commandBuffer, drawable: drawable)

        // Optional offscreen capture requested from the Debug UI (end of frame)
        if let url = pendingFrameCaptureURL {
            if !compositeEncodedThisFrame { encodeCompositeAndBloom(commandBuffer: commandBuffer) }
            encodeCapture(commandBuffer: commandBuffer, url: url)
            pendingFrameCaptureURL = nil
        }

        if statsEnabled {
            maybeStats(commandBuffer: commandBuffer)
        }

        metrics.endFrame(encodeSeconds: metrics.elapsedSinceFrameStart())
        commandBuffer.commit()
        publishMetricsPeriodically()
    }

    // MARK: Fixed step (contract §5.5 ordering)
    //
    // Roles are tracked per field: velocity and pigment flip A/B each step
    // (their newest state lives in the *other* buffer after the step), detail
    // keeps its role (newest stays in “cur”). PASSES ALWAYS RUN — the inject
    // kernels passthrough with eventCount == 0, which removes skip-branches
    // that previously desynced the “current” pointer for composite reads.
    private func runFixedStep(commandBuffer: MTLCommandBuffer) {
        guard let tex = textures else { return }
        let params = makeParams()
        let segs = normalizer.segmentsForStep(spacingFraction: config.radiusFraction)
        let events = makeEvents(from: segs)
        let eventBuf = makeEventsBuffer(events)          // count 0 events passthrough
        let countBuf = makeCountBuffer(UInt32(events.count))
        let buffers = [eventBuf, countBuf]

        let rV = tex.velRole, oV = 1 - rV
        let rP = tex.pigRole, oP = 1 - rP
        let rD = tex.detRole, oD = 1 - rD

        // 1 advectVelocity  V[rV]→V[oV]
        dispatch("advectVelocity", [tex.velocity[rV], tex.velocity[oV]], params: params, cb: commandBuffer)
        // 2 injectVelocity  V[oV]→V[rV]
        dispatch("injectVelocity", [tex.velocity[oV], tex.velocity[rV]], params: params, cb: commandBuffer, buffers: buffers)
        // 3 dampVelocity    V[rV]→V[oV]   (latest velocity lives in oV)
        dispatch("dampVelocity", [tex.velocity[rV], tex.velocity[oV]], params: params, cb: commandBuffer)

        // 4 advectPigment   P[rP]·V[oV]→P[oP]
        dispatch("advectPigment", [tex.pigment[rP], tex.velocity[oV], tex.pigment[oP]], params: params, cb: commandBuffer)
        // 5 injectPigment   P[oP]→P[rP]
        dispatch("injectPigment", [tex.pigment[oP], tex.pigment[rP]], params: params, cb: commandBuffer, buffers: buffers)
        // 5b decayPigment   P[rP]→P[oP]   (latest pigment lives in oP)
        dispatch("decayPigment", [tex.pigment[rP], tex.pigment[oP]], params: params, cb: commandBuffer)

        if config.detailEnabled {
            // 6 advectDetail   D[rD]·V[oV]→D[oD]
            dispatch("advectDetail", [tex.detail[rD], tex.velocity[oV], tex.detail[oD]], params: params, cb: commandBuffer)
            // 7 injectDetailDecay D[oD]→D[rD]   (latest detail stays in rD)
            dispatch("injectDetailDecay", [tex.detail[oD], tex.detail[rD]], params: params, cb: commandBuffer, buffers: buffers)
        }

        tex.velRole = oV
        tex.pigRole = oP
        // tex.detRole unchanged
    }

    // MARK: Replay (deterministic fixture path)
    //
    // Determinism (§6.2): the number of fixed steps per frame is CONSTANT —
    // wall-clock pacing is intentionally not used, because it made the same
    // fixture produce different frames run-to-run (frame load varies).
    // Captures are encoded *inside* the step loop, immediately after the step
    // whose sim time crosses the requested instant, so the recorded image is
    // the exact state at that sim time regardless of frame rate.
    private func runReplaySteps(replay: ReplayEngine, commandBuffer: MTLCommandBuffer) {
        // Wall-clock paced so a live demo plays at natural speed (≈2 steps per
        // 60 Hz frame = real time), capped by maxStepsPerFrame. Determinism is
        // unaffected because captures are encoded inside the loop, immediately
        // after the fixed step whose sim time crosses the requested instant.
        let steps = clock.advance(now: CACurrentMediaTime())
        guard steps > 0 else { return }
        var t = clock.simTime - Double(steps) * clock.stepDuration
        for _ in 0..<steps {
            t += clock.stepDuration
            replay.advanceTo(simTime: t)
            for s in replay.samplesUpTo(simTime: t) {
                ingest(sample: TouchSample(touchID: s.touchID,
                                           phase: ReplayEngine.phaseKind(s.phase),
                                           timestamp: s.time,
                                           position: SIMD2(Float(s.x), Float(s.y)),
                                           inputKind: s.inputKind == "pencil" ? .pencil : .finger,
                                           normalizedForce: s.force.map { Float($0) }))
            }
            runFixedStep(commandBuffer: commandBuffer)
            metrics.stepsLastFrame += 1

            if let url = takeDueCapture(at: t) {
                encodeCompositeAndBloom(commandBuffer: commandBuffer)
                encodeCapture(commandBuffer: commandBuffer, url: url)
            }
            if dumpInterval > 0, t >= nextDumpTime, let dir = dumpDirectory {
                nextDumpTime += dumpInterval
                encodeCompositeAndBloom(commandBuffer: commandBuffer)
                let name = String(format: "f_%06d.png", Int((t / dumpInterval).rounded()))
                encodeCapture(commandBuffer: commandBuffer,
                              url: dir.appendingPathComponent(name))
            }
        }
        if replay.phase == .finished {
            if loopReplayEnabled {
                restartReplayForLoop(commandBuffer: commandBuffer)
            } else if !replayReportedDone {
                replayReportedDone = true
            }
        }
    }

    /// Long-run stress mode: clear state and replay the same fixture again.
    /// Captures are not re-scheduled (they are already done) to avoid disk churn.
    private func restartReplayForLoop(commandBuffer: MTLCommandBuffer) {
        guard let engine = replayEngine else { return }
        replayLoops += 1
        normalizer.reset()
        clock.resetToZero(resetPause: false)
        engine.reset()
        engine.start()
        captureTargets.removeAll()
        renderRequestedClear = true
        NSLog("[Flow][loop] replay restart #\(replayLoops) at t=\(clock.simTime)")
    }

    // MARK: Input
    private func ingest(sample: TouchSample) {
        normalizer.ingest(touchID: sample.touchID, phase: sample.phase,
                          timestamp: sample.timestamp,
                          normalized: sample.position,
                          kind: sample.inputKind == .pencil ? 1 : 0)
    }

    // MARK: Events / params helpers
    private func makeEvents(from segs: [InputNormalizer.SegmentOutput]) -> [ShaderBridge.StrokeEvent] {
        let sorted = segs.sorted { a, b in
            if a.timestamp != b.timestamp { return a.timestamp < b.timestamp }
            return a.touchID < b.touchID
        }
        var out: [ShaderBridge.StrokeEvent] = []
        out.reserveCapacity(min(sorted.count, maxEvents))
        for seg in sorted {
            // Radial (tap/hold) segments get their own footprint so a light
            // touch blooms softly instead of stamping a dot (contract §1.4),
            // while holds only add a trickle of dye (contract §4.3).
            let dye: Float
            let strength: Float
            switch seg.kind {
            case .burst: dye = config.tapDye;  strength = config.tapRadialPush
            case .hold:  dye = config.tapHoldDye; strength = 0
            case .stroke: dye = 0.85; strength = config.touchMomentumGain
            }
            let radius: Float = seg.isTap
                ? config.radiusFraction * config.tapRadiusScale
                : config.radiusFraction
            let radiusPigment = seg.isTap
                ? radius * config.tapDyeRadiusScale
                : radius
            out.append(ShaderBridge.StrokeEvent(
                pos: seg.position, vel: seg.velocity,
                radius: radius,
                strength: strength,
                dye: dye,
                force: 0.75,
                color: ShaderBridge.auroraLinear(
                    at: seg.position.x * 0.85 + seg.position.y * 0.45
                        + Float(seg.touchID % 4) * 0.17),
                tangent: seg.isTap ? SIMD2<Float>(1, 0) : normalizedOr(seg.tangent),
                kind: seg.isTap ? 0 : 1,
                radiusPigment: radiusPigment))
            if out.count >= maxEvents { break }
        }
        return out
    }

    private func normalizedOr(_ v: SIMD2<Float>) -> SIMD2<Float> {
        let l = simd_length(v)
        return l > 1e-4 ? v / l : SIMD2(1, 0)
    }

    private func makeEventsBuffer(_ events: [ShaderBridge.StrokeEvent]) -> MTLBuffer {
        let size = Swift.max(1, events.count) * MemoryLayout<ShaderBridge.StrokeEvent>.stride
        guard let buf = device.makeBuffer(bytes: events, length: size, options: .storageModeShared) else {
            return device.makeBuffer(length: 4, options: .storageModeShared)!
        }
        return buf
    }

    private func makeCountBuffer(_ count: UInt32) -> MTLBuffer {
        var c = count
        return device.makeBuffer(bytes: &c, length: 4, options: .storageModeShared)!
    }

    private func makeParams() -> ShaderBridge.StepParams {
        var p = ShaderBridge.StepParams()
        if let tex = textures {
            let w = tex.width, h = tex.height
            let aspect = Float(max(w, h)) / Float(max(1, min(w, h)))
            let iso = w >= h ? SIMD2<Float>(aspect, 1) : SIMD2<Float>(1, aspect)
            p.dtRadius = SIMD2(Float(config.simulationStep), config.radiusFraction)
            p.iso = iso
            p.invIso = SIMD2(1.0 / iso.x, 1.0 / iso.y)
            p.gains = SIMD2(config.touchMomentumGain, config.maxVelocity)
            p.noiseSeed = SIMD2(config.filamentFrequency, Float(config.seed))
            p.maxDyeStrength = SIMD2(config.maxDyeConcentration,
                                     config.detailEnabled ? config.detailStrength : 0)
            p.wavelengthHL = SIMD2(config.radiusFraction * 0.9, Float(config.velocityHalfLife))
            p.pigDetHL = SIMD2(Float(config.pigmentHalfLife), Float(config.detailHalfLife))
            p.bloom = SIMD2(config.bloomEnabled ? config.glowStrength : 0,
                            config.bloomThreshold)
            p.bg0 = SIMD2(ShaderBridge.backgroundLinear.x, ShaderBridge.backgroundLinear.y)
            p.bg1 = SIMD2(ShaderBridge.backgroundLinear.z, 0)
            p.edgeCurve = SIMD2(config.edgeCurveLo, config.edgeCurveHi)
        }
        return p
    }

    private func paramsBytes(_ p: ShaderBridge.StepParams) -> MTLBuffer {
        var v = p
        return device.makeBuffer(bytes: &v, length: MemoryLayout<ShaderBridge.StepParams>.stride,
                                 options: .storageModeShared)!
    }

    // MARK: Dispatch helpers
    private func dispatch(_ name: String, _ texs: [MTLTexture], params: ShaderBridge.StepParams,
                          cb: MTLCommandBuffer, buffers: [MTLBuffer] = []) {
        guard let ps = computePipelines[name], let tex = textures else { return }
        let target = tex.mainDims
        guard let enc = cb.makeComputeCommandEncoder() else { return }
        enc.label = name
        enc.setComputePipelineState(ps)
        enc.setBuffer(paramsBytes(params), offset: 0, index: 0)
        for (i, t) in texs.enumerated() { enc.setTexture(t, index: i) }
        // kernels bind parameters at buffer 0; event buffer at 1; count at 2
        for (i, b) in buffers.enumerated() { enc.setBuffer(b, offset: 0, index: 1 + i) }
        enc.dispatchThreadgroups(MTLSize(width: (target.x + 7) / 8,
                                         height: (target.y + 7) / 8, depth: 1),
                                 threadsPerThreadgroup: MTLSize(width: min(ps.threadExecutionWidth, 8), height: 8, depth: 1))
        enc.endEncoding()
    }

    // MARK: Composite + bloom (shared by display and capture)
    private func encodeCompositeAndBloom(commandBuffer: MTLCommandBuffer) {
        guard let tex = textures else { return }
        let params = makeParams()

        func dispatchC(_ name: String, _ texs: [MTLTexture], _ dims: SIMD2<Int>) {
            guard let ps = computePipelines[name],
                  let enc = commandBuffer.makeComputeCommandEncoder() else { return }
            enc.label = name
            enc.setComputePipelineState(ps)
            enc.setBuffer(paramsBytes(params), offset: 0, index: 0)
            for (i, t) in texs.enumerated() { enc.setTexture(t, index: i) }
            enc.dispatchThreadgroups(MTLSize(width: (dims.x + 7) / 8, height: (dims.y + 7) / 8, depth: 1),
                                     threadsPerThreadgroup: MTLSize(width: min(ps.threadExecutionWidth, 8), height: 8, depth: 1))
            enc.endEncoding()
        }

        dispatchC("compositePass", [tex.pigment[tex.pigRole], tex.detail[tex.detRole], tex.composite], tex.mainDims)
        if params.bloom.x > 0 {
            // ping-pong: never read+write the same texture in one kernel
            dispatchC("bloomExtract", [tex.composite, tex.bloomA], tex.bloomDims)
            dispatchC("bloomBlurH", [tex.bloomA, tex.bloomB], tex.bloomDims)
            dispatchC("bloomBlurV", [tex.bloomB, tex.bloomA], tex.bloomDims)
        } else {
            // keep the bloom texture at zero so `final` can sample it unconditionally
            dispatchC("clearTex", [tex.bloomA], tex.bloomDims)
            dispatchC("clearTex", [tex.bloomB], tex.bloomDims)
        }
        compositeEncodedThisFrame = true
    }

    // MARK: Display pass
    private func encodeDisplay(commandBuffer: MTLCommandBuffer, drawable: any CAMetalDrawable) {
        guard let tex = textures else { return }
        if !compositeEncodedThisFrame { encodeCompositeAndBloom(commandBuffer: commandBuffer) }
        let params = makeParams()
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture = drawable.texture
        rpd.colorAttachments[0].loadAction = .clear
        rpd.colorAttachments[0].storeAction = .store
        rpd.colorAttachments[0].clearColor = view.clearColor
        let paramsData = paramsBytes(params)
        if let rend = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
            rend.label = "final-display"
            rend.setRenderPipelineState(finalPipeline)
            bindFinishTextures(rend, tex)
            rend.setFragmentBytes(paramsData.contents(), length: MemoryLayout<ShaderBridge.StepParams>.stride, index: 0)
            rend.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            rend.endEncoding()
        }
        // MTKView with an explicit delegate does NOT present for us; without
        // this the drawable is never shown (the window shows the SwiftUI
        // background instead — the same #070A13, which hid the bug).
        commandBuffer.present(drawable)
    }

    /// Binds the four textures consumed by `finishFragment`.
    private func bindFinishTextures(_ rend: MTLRenderCommandEncoder, _ tex: TextureSet) {
        rend.setFragmentTexture(tex.pigment[tex.pigRole], index: 0)
        rend.setFragmentTexture(tex.detail[tex.detRole], index: 1)
        rend.setFragmentTexture(tex.bloomA, index: 2)
        rend.setFragmentTexture(tex.velocity[tex.velRole], index: 3)
    }

    // MARK: Capture (offscreen → readback → PNG)
    func scheduleCaptureAt(_ absoluteSimTime: Double, tag: String) {
        let key = String(format: "%.3f-%@", absoluteSimTime, tag)
        guard !capturedKeys.contains(key) else { return }
        capturedKeys.insert(key)
        // unique per-sim-time filename so multiple frames don't overwrite
        let url = TestCapture.ImagesDocsURL
            .appendingPathComponent("\(tag)_\(String(format: "%.2f", absoluteSimTime)).png")
        captureTargets.append((absoluteSimTime, url))
    }

    func requestCapture(tag: String) {
        pendingFrameCaptureURL = TestCapture.ImagesDocsURL.appendingPathComponent("\(tag).png")
    }

    private func compositeAndRenderIfNeeded(commandBuffer: MTLCommandBuffer,
                                            drawable: any CAMetalDrawable) {
        encodeDisplay(commandBuffer: commandBuffer, drawable: drawable)
    }

    /// Returns the capture URL whose sim time has just been crossed, if any.
    /// Removes it from the pending list so each instant is captured once.
    private func takeDueCapture(at t: Double) -> URL? {
        guard let idx = captureTargets.firstIndex(where: { $0.time <= t }) else { return nil }
        let url = captureTargets[idx].url
        captureTargets.remove(at: idx)
        return url
    }

    private func checkCaptures(at t: Double) { _ = t }

    private func scheduleFixtureCaptures(_ fixture: ReplayEngine.Fixture) {
        // retained for API symmetry; capture instants are scheduled in startReplay
    }

    private func encodeCapture(commandBuffer: MTLCommandBuffer, url: URL) {
        guard let tex = textures, let capture = tex.capture else { return }
        let params = makeParams()
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture = capture
        rpd.colorAttachments[0].loadAction = .clear
        rpd.colorAttachments[0].storeAction = .store
        rpd.colorAttachments[0].clearColor = view.clearColor
        let paramsData = paramsBytes(params)
        if let rend = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
            rend.label = "final-capture"
            rend.setRenderPipelineState(finalPipeline)
            bindFinishTextures(rend, tex)
            rend.setFragmentBytes(paramsData.contents(), length: MemoryLayout<ShaderBridge.StepParams>.stride, index: 0)
            rend.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            rend.endEncoding()
        }
        guard let readback = makeReadbackIfNeeded(pixelCount: capture.width * capture.height),
              let blit = commandBuffer.makeBlitCommandEncoder() else { return }
        blit.label = "capture-readback"
        blit.copy(from: capture, sourceSlice: 0, sourceLevel: 0,
                  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                  sourceSize: MTLSize(width: capture.width, height: capture.height, depth: 1),
                  to: readback, destinationOffset: 0,
                  destinationBytesPerRow: capture.width * 4,
                  destinationBytesPerImage: capture.width * capture.height * 4)
        blit.endEncoding()
        // Completion handlers run off the main thread. The buffer is only read
        // after the GPU finished with it, so hand it over explicitly.
        nonisolated(unsafe) let readbackRef = readback
        let cw = capture.width, ch = capture.height
        let queue = pngQueue
        let isDump = dumpInterval > 0
        commandBuffer.addCompletedHandler { _ in
            Self.writeCapturePNG(readback: readbackRef, w: cw, h: ch, url: url,
                                 queue: queue, quiet: isDump)
        }
    }

    private func makeReadbackIfNeeded(pixelCount: Int) -> MTLBuffer? {
        let needed = pixelCount * 4
        if readbackPool.count >= 3 {
            let b = readbackPool[readbackCursor % readbackPool.count]
            readbackCursor += 1
            if b.length >= needed { return b }
        }
        guard let b = device.makeBuffer(length: needed, options: .storageModeShared) else {
            ErrorStatus.shared.record(severity: .warning, source: "capture", "readback buffer alloc failed")
            return nil
        }
        if readbackPool.count < 3 {
            readbackPool.append(b)
            readbackCursor += 1
        } else {
            readbackPool[(readbackCursor - 1) % readbackPool.count] = b
        }
        readbackLength = needed
        return b
    }

    /// Nonisolated: runs on the command buffer's completion thread and touches
    /// no main-actor state. Copies the readback bytes and writes a PNG.
    nonisolated private static func writeCapturePNG(readback: MTLBuffer, w: Int, h: Int,
                                                   url: URL, queue: DispatchQueue,
                                                   quiet: Bool) {
        #if os(macOS)
        readback.didModifyRange(0..<readback.length)
        #endif
        let length = w * h * 4
        let bytes = readback.contents().bindMemory(to: UInt8.self, capacity: length)
        let data = Data(bytes: bytes, count: length)   // copy off the GPU buffer
        do {
            let w2 = w, h2 = h
            queue.async {
                do {
                    try data.withUnsafeBytes { raw in
                        let ptr = UnsafeMutableRawPointer(mutating: raw.baseAddress!)
                        try TestCapture.writePNG(pixels: ptr, width: w2, height: h2, to: url)
                    }
                } catch {
                    ErrorStatus.shared.record(severity: .warning, source: "capture", "\(error)")
                }
            }
            if !quiet {
                NSLog("[Flow][capture] saved \(url.path) (\(w)x\(h))")
            }
        }
    }

    // MARK: Stats
    private func maybeStats(commandBuffer: MTLCommandBuffer) {
        statsCounter += 1
        guard statsCounter % 30 == 0, let tex = textures,
              let ps = computePipelines["statsScan"],
              let buffer = device.makeBuffer(length: 16, options: .storageModeShared) else { return }
        buffer.contents().assumingMemoryBound(to: UInt32.self).update(repeating: 0, count: 4)
        guard let enc = commandBuffer.makeComputeCommandEncoder() else { return }
        enc.label = "stats-scan"
        enc.setComputePipelineState(ps)
        enc.setTexture(tex.pigment[tex.pigRole], index: 0)
        enc.setTexture(tex.velocity[tex.velRole], index: 1)
        enc.setBuffer(buffer, offset: 0, index: 0)
        enc.dispatchThreadgroups(MTLSize(width: (tex.mainDims.x + 7) / 8,
                                         height: (tex.mainDims.y + 7) / 8, depth: 1),
                                 threadsPerThreadgroup: MTLSize(width: min(ps.threadExecutionWidth, 8), height: 8, depth: 1))
        enc.endEncoding()
        nonisolated(unsafe) let statsBuffer = buffer
        commandBuffer.addCompletedHandler { [weak self] _ in
            let ptr = statsBuffer.contents().assumingMemoryBound(to: UInt32.self)
            let nan = UInt(ptr[0]), inf = UInt(ptr[1])
            Task { @MainActor [weak self] in
                self?.metrics.nanCount = nan
                self?.metrics.infCount = inf
            }
        }
    }

    // MARK: Clear / Pause / Resume / Config
    func clearRequested() { renderRequestedClear = true }

    private func clearAllTextures() {
        guard let tex = textures, let ps = computePipelines["clearTex"],
              let cb = commandQueue.makeCommandBuffer(),
              let enc = cb.makeComputeCommandEncoder() else { return }
        enc.label = "clear-state"
        enc.setComputePipelineState(ps)
        var targets: [MTLTexture] = []
        for i in 0..<2 { targets.append(tex.velocity[i]); targets.append(tex.pigment[i]); targets.append(tex.detail[i]) }
        targets.append(tex.composite); targets.append(tex.bloomA); targets.append(tex.bloomB)
        for t in targets {
            enc.setTexture(t, index: 0)
            enc.dispatchThreadgroups(MTLSize(width: (t.width + 7) / 8,
                                             height: (t.height + 7) / 8, depth: 1),
                                     threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        }
        enc.endEncoding()
        cb.commit()
    }

    func pause() { clock.pause(); view.isPaused = true }
    func resume() { clock.resume(); view.isPaused = false }
    func applyConfig(_ c: SimulationConfig) {
        config = c
        clock.setPolicy(stepDuration: c.simulationStep, maxStepsPerFrame: c.maxStepsPerFrame)
    }
    func setStatsEnabled(_ on: Bool) { statsEnabled = on }

    // MARK: Replay control
    func startReplay(_ engine: ReplayEngine, extraCaptures: [Double] = []) {
        normalizer.reset()
        clock.resetToZero(resetPause: true)
        engine.start()            // must be running, otherwise samplesUpTo returns []
        replayEngine = engine
        replayReportedDone = false
        extraCaptureTimes = extraCaptures
        captureTargets.removeAll()
        capturedKeys.removeAll()
        if let fps = pendingDumpFPS, fps > 1 {
            dumpInterval = 1.0 / fps
            nextDumpTime = 0
            dumpDirectory = TestCapture.ImagesDocsURL.appendingPathComponent("frames/\(engine.fixture.name)",
                                                                            isDirectory: true)
        } else {
            dumpInterval = 0
            dumpDirectory = nil
        }
        renderRequestedClear = true
        replayStartWall = CACurrentMediaTime()
        // "touch end" = time of the last input sample in the fixture (§6.3).
        let touchEnd = engine.orderedSamples.last?.time ?? engine.fixture.durationSeconds
        for off in [0.0, 0.5, 2.0, 8.0] {
            scheduleCaptureAt(touchEnd + off, tag: engine.fixture.name)
        }
        for t in extraCaptures { scheduleCaptureAt(t, tag: engine.fixture.name) }
        if clock.snapshot().isPaused { view.isPaused = false }
    }

    func stopReplay() {
        replayEngine = nil
    }

    func setExtraCaptureTimes(_ t: [Double]) { extraCaptureTimes = t }

    /// Set before starting a replay; frames are written every 1/fps of sim time.
    var pendingDumpFPS: Double?
    /// When true, emit measured frame-interval statistics to the system log.
    var metricsLoggingEnabled = false
    /// When true, restart the fixture after it completes (long-run stress test).
    var loopReplayEnabled = false
    private var replayLoops: Int = 0
    private var lastMetricsLog: CFAbsoluteTime = 0

    // MARK: Layout / resize / texture creation
    private func makeTextures(drawable: CGSize) -> TextureSet {
        let t = TextureSet(device: device)
        let w = simWidthFor(pixelW: Int(drawable.width), pixelH: Int(drawable.height))
        let h = simHeightFor(pixelW: Int(drawable.width), pixelH: Int(drawable.height))
        t.build(width: w, height: h, captureEnabled: true,
                captureSize: SIMD2(max(1, Int(drawable.width)), max(1, Int(drawable.height))))
        normalizer.setCanvasSize(points: view.bounds.size)
        return t
    }

    private func resizeTo(drawable size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        guard let old = textures else {
            if textures == nil { textures = makeTextures(drawable: size) }
            return
        }
        let t = TextureSet(device: device)
        let w = simWidthFor(pixelW: Int(size.width), pixelH: Int(size.height))
        let h = simHeightFor(pixelW: Int(size.width), pixelH: Int(size.height))
        t.build(width: w, height: h, captureEnabled: true,
                captureSize: SIMD2(max(1, Int(size.width)), max(1, Int(size.height))))
        if let cb = commandQueue.makeCommandBuffer() {
            var pairs: [(MTLTexture, MTLTexture)] = []
            for i in 0..<2 {
                pairs.append((old.velocity[i], t.velocity[i]))
                pairs.append((old.pigment[i], t.pigment[i]))
                pairs.append((old.detail[i], t.detail[i]))
            }
            if let ps = computePipelines["resampleState"] {
                var oldDim = SIMD4<Float>(Float(old.width), Float(old.height), 0, 0)
                for (src, dst) in pairs {
                    guard let enc = cb.makeComputeCommandEncoder() else { break }
                    enc.label = "resample"
                    enc.setComputePipelineState(ps)
                    enc.setTexture(src, index: 0)
                    enc.setTexture(dst, index: 1)
                    enc.setBytes(&oldDim, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
                    enc.dispatchThreadgroups(MTLSize(width: (t.width + 7) / 8, height: (t.height + 7) / 8, depth: 1),
                                             threadsPerThreadgroup: MTLSize(width: min(ps.threadExecutionWidth, 8), height: 8, depth: 1))
                    enc.endEncoding()
                }
            }
            cb.commit()
        }
        textures = t
        normalizer.setCanvasSize(points: view.bounds.size)
        NSLog("[Flow][resize] \(Int(size.width))x\(Int(size.height)) px → sim \(w)x\(h)")
    }

    func simWidthFor(pixelW: Int, pixelH: Int) -> Int {
        Self.simWidthForStatic(pixelW: pixelW, pixelH: pixelH, config: config)
    }

    func simHeightFor(pixelW: Int, pixelH: Int) -> Int {
        Self.simHeightForStatic(pixelW: pixelW, pixelH: pixelH, config: config)
    }

    // Pure sizing math — marked nonisolated so tests and tooling can call it
    // from any context without hopping to the main actor.
    nonisolated static func simWidthForStatic(pixelW: Int, pixelH: Int, config: SimulationConfig) -> Int {
        let short = config.gridPreset.shortSideTexels
        let aspect = Double(max(pixelW, 1)) / Double(max(pixelH, 1))
        let longSide = Int(Float(short) * Float(max(aspect, 1.0 / max(aspect, 1e-4))))
        return pixelW >= pixelH ? min(longSide, config.maxLongSideTexels) : short
    }
    nonisolated static func simHeightForStatic(pixelW: Int, pixelH: Int, config: SimulationConfig) -> Int {
        let short = config.gridPreset.shortSideTexels
        let aspect = Double(max(pixelW, 1)) / Double(max(pixelH, 1))
        let longSide = Int(Float(short) * Float(max(aspect, 1.0 / max(aspect, 1e-4))))
        return pixelW >= pixelH ? short : min(longSide, config.maxLongSideTexels)
    }

    // MARK: Metrics
    private var fpsStore: Double = 0

    private func publishMetricsPeriodically() {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastMetricsPublish > 0.5, let tex = textures else { return }
        lastMetricsPublish = now
        let sim = ConfigResolver.simulator
        let snap = metrics.snapshot(fps: fpsStore,
                                    simSize: SIMD2<Int>(tex.width, tex.height),
                                    drawableSize: SIMD2<Int>(Int(view.drawableSize.width),
                                                             Int(view.drawableSize.height)),
                                    touches: replayEngine == nil ? normalizer.activeTouchCount : 0,
                                    replayName: replayEngine?.fixture.name ?? "-",
                                    isPaused: clock.snapshot().isPaused,
                                    simTime: clock.simTime,
                                    isSimulator: sim)
        metricsStore.publish(snap)

        if metricsLoggingEnabled, now - lastMetricsLog >= 2.0 {
            lastMetricsLog = now
            NSLog(String(format:
                "[Flow][perf] fps=%.1f p50=%.2fms p95=%.2fms p99=%.2fms sim=%dx%d draw=%dx%d steps=%d touches=%d simTime=%.2f",
                snap.fps, snap.frameIntervalMsP50, snap.frameIntervalMsP95,
                metrics.intervals.percentile(0.99) * 1000,
                snap.simWidth, snap.simHeight, snap.drawableWidth, snap.drawableHeight,
                snap.stepsLastFrame, snap.activeTouches, snap.simTime))
        }
    }
}

enum ConfigResolver {
    static var simulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}