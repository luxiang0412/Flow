import Foundation

/// App-visible error reporting. Consumed by the Debug overlay and recovery UI.
public final class ErrorStatus: @unchecked Sendable {
    public enum Severity: Sendable { case info, warning, fatal }

    public struct Entry: Sendable, Equatable {
        public let severity: Severity
        public let message: String
        public let timestamp: Date
        public let source: String
    }

    private var _entries: [Entry] = []
    public private(set) var lastFatal: Entry?

    public static let shared = ErrorStatus()
    public init() {}

    public func record(severity: Severity, source: String, _ message: String) {
        let e = Entry(severity: severity, message: message, timestamp: Date(), source: source)
        _entries.append(e)
        if _entries.count > 100 { _entries.removeFirst(_entries.count - 100) }
        if severity == .fatal { lastFatal = e }
        NSLog("[Flow][\(source)] \(severity == .warning ? "WARN" : severity == .fatal ? "FATAL" : "INFO") \(message)")
    }

    public func record(_ error: Error, source: String) {
        record(severity: .warning, source: source, "\(error)")
    }

    public var entries: [Entry] { _entries }
    public func clear() { _entries.removeAll(); lastFatal = nil }
}