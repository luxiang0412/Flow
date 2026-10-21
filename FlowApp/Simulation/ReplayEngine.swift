import Foundation

/// Deterministic, controllable playback of a gesture fixture (contract §6).
/// Drives the exact same `InputNormalizer`/simulation path as real touches.
public final class ReplayEngine: @unchecked Sendable {

    public struct FixtureSample: Decodable, Equatable, Sendable {
        public var touchID: Int
        public var phase: String        // began | moved | ended | cancelled
        public var time: Double         // seconds, monotonic
        public var x: Double
        public var y: Double
        public var inputKind: String    // finger | pencil
        public var force: Double?       // optional
    }

    public struct Fixture: Decodable, Equatable, Sendable {
        public var schemaVersion: Int
        public var name: String
        public var seed: UInt32
        public var canvasAspectRatio: Double
        public var durationSeconds: Double
        public var samples: [FixtureSample]
        public var expectVisibleCurlAtSeconds: Double?
    }

    public enum Phase: Sendable { case waiting, running, finished }

    public private(set) var fixture: Fixture
    /// Sorted by (time, touchID) — stability requirement §6.2.
    public private(set) var orderedSamples: [FixtureSample]
    public private(set) var phase: Phase = .waiting
    public private(set) var processedCursor: Int = 0

    /// Total simulation seconds ingested so far.
    public private(set) var currentTime: Double = 0

    public init(fixture: Fixture) throws {
        self.fixture = fixture
        var s = fixture.samples
        s.sort { a, b in
            if a.time != b.time { return a.time < b.time }
            return a.touchID < b.touchID
        }
        // dedupe identical (time, touchID)
        var unique: [FixtureSample] = []
        for e in s {
            if let last = unique.last, last.time == e.time && last.touchID == e.touchID { continue }
            unique.append(e)
        }
        self.orderedSamples = unique
    }

    public convenience init(url: URL) throws {
        let data = try Data(contentsOf: url)
        let f = try Self.decoder.decode(Fixture.self, from: data)
        try self.init(fixture: f)
    }

    private static let decoder: JSONDecoder = { let d = JSONDecoder(); return d }()

    /// Called by the simulation after each fixed step at `simTime`.
    /// Returns samples whose timestamp is in (previousTime, simTime].
    /// Deterministic: depends only on fixture content and simTime history.
    public func samplesUpTo(simTime: Double) -> [FixtureSample] {
        guard phase == .running || phase == .waiting else { return [] }
        var out: [FixtureSample] = []
        while processedCursor < orderedSamples.count,
              orderedSamples[processedCursor].time <= simTime {
            out.append(orderedSamples[processedCursor])
            processedCursor += 1
        }
        return out
    }

    public func start() {
        phase = .running
        currentTime = 0
        processedCursor = 0
    }

    public func advanceTo(simTime: Double) {
        currentTime = simTime
        if simTime >= fixture.durationSeconds { phase = .finished }
    }

    public func reset() {
        phase = .waiting
        currentTime = 0
        processedCursor = 0
    }

    public static func phaseKind(_ raw: String) -> TouchSample.Phase {
        switch raw {
        case "began": return .began
        case "ended": return .ended
        case "cancelled": return .cancelled
        default: return .moved
        }
    }
}