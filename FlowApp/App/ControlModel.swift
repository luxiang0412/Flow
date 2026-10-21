import Foundation
import Combine
import SwiftUI

/// Debug/control surface shared between the SwiftUI shell and MetalCanvas.
/// Ops are queued from UI/app code and drained inside `updateUIView` so they
/// are applied on the render-thread context exactly once.
@MainActor
public final class ControlModel: ObservableObject {

    public enum Op: Equatable {
        case pauseRequested(Bool)
        case clearRequested
        case startReplay(String, extraCaptures: [Double])
        case stopReplay
        case capture(String)
        case setConfig(SimulationConfig)
        case setStatsEnabled(Bool)
    }

    @Published public var config = SimulationConfig()
    @Published public var metrics = MetricsSnapshot()
    @Published public var isPaused = false
    @Published public var activeReplay: String?
    @Published public var errorMessage: String?
    @Published public var fixtureNames: [String] = []
    @Published public var overlayCollapsed = true

    public let metricsStore = MetricsStore()
    public let input = TouchInputBuffer()

    /// Set from launch options; consumed when a replay starts.
    public var dumpFramesFPS: Double?
    /// Mirror of the launch flag so the renderer can emit periodic stats.
    public var metricsLog = false
    /// Mirror of the launch flag; restarts the replay for long-run testing.
    public var loopReplay = false

    private var pending: [Op] = []
    public var lastClear: Date?

    public init() {
        fixtureNames = FixtureLoader.availableNames()
    }

    // MARK: Metrics refresh (polled ~2 Hz from the shell)
    public func refreshMetrics() {
        metrics = metricsStore.latest
    }

    // MARK: Ops
    public func enqueue(_ op: Op) {
        switch op {
        case .pauseRequested(let p): isPaused = p
        case .startReplay(let name, _): activeReplay = name
        case .stopReplay: activeReplay = nil
        case .clearRequested: lastClear = Date()
        case .setConfig(let c): config = c
        default: break
        }
        pending.append(op)
    }

    public func drainOps() -> [Op] {
        let ops = pending
        pending.removeAll()
        return ops
    }

    public var error: String? {
        get { errorMessage }
        set { errorMessage = newValue }
    }
}

public enum FixtureLoader {
    /// Standard fixture names (contract §6.3).
    public static let standard: [String] = ["tap", "slow-stroke", "fast-swipe", "spiral",
                                            "two-fingers", "crossing"]

    public static func availableNames() -> [String] {
        let fm = FileManager.default
        guard let resources = Bundle.main.resourceURL,
              let files = try? fm.contentsOfDirectory(atPath: resources.path) else {
            return []
        }
        return files.filter { $0.hasSuffix(".json") }
                    .map { ($0 as NSString).deletingPathExtension }
                    .sorted()
    }

    public static func load(name: String) throws -> ReplayEngine {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw FixtureError.notFound(name)
        }
        return try ReplayEngine(url: url)
    }

    public static func engine(from url: URL) throws -> ReplayEngine {
        try ReplayEngine(url: url)
    }

    public enum FixtureError: Error {
        case notFound(String)
    }
}

/// Parsed launch arguments (Debug CLI behavior, contract §6.1).
public struct LaunchOptions: Equatable, Sendable {
    public var replayName: String?
    public var seed: UInt32?
    public var fixedDt: Double?
    public var captureAt: [Double] = []
    public var disableBloom = false
    public var disableDetail = false
    /// Dump a native-resolution PNG every 1/fps of *simulation* time (Debug only).
    public var dumpFramesFPS: Double?
    /// Log measured frame-interval statistics every 2 s (Debug only).
    public var metricsLog = false
    /// Restart the fixture when it finishes (long-run stress testing).
    public var loopReplay = false
    /// Simulation grid short side (384 / 512 / 640) for perf/quality A/B.
    public var gridShortSide: Int?

    public static func parse(_ args: [String]) -> LaunchOptions {
        var o = LaunchOptions()
        var i = 0
        while i < args.count {
            let a = args[i]
            switch a {
            case "--flow-replay":
                if i + 1 < args.count { o.replayName = args[i + 1]; i += 1 }
            case "--flow-seed":
                if i + 1 < args.count { o.seed = UInt32(args[i + 1]); i += 1 }
            case "--flow-fixed-dt":
                if i + 1 < args.count { o.fixedDt = Double(args[i + 1]); i += 1 }
            case "--flow-capture-at":
                if i + 1 < args.count {
                    o.captureAt = args[i + 1].split(separator: ",").compactMap { Double($0) }
                    i += 1
                }
            case "--flow-metrics-log": o.metricsLog = true
            case "--flow-loop-replay": o.loopReplay = true
            case "--flow-grid":
                if i + 1 < args.count, let v = Int(args[i + 1]) { o.gridShortSide = v; i += 1 }
            case "--flow-dump-frames":
                if i + 1 < args.count { o.dumpFramesFPS = Double(args[i + 1]); i += 1 }
            case "--flow-disable-bloom": o.disableBloom = true
            case "--flow-disable-detail": o.disableDetail = true
            default: break
            }
            i += 1
        }
        return o
    }
}