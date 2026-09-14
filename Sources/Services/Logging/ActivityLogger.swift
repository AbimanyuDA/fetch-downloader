import Foundation

public struct LogEntry: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let process: String
    public let message: String
    public let isError: Bool

    public init(id: UUID = UUID(), timestamp: Date = Date(), process: String, message: String, isError: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.process = process
        self.message = message
        self.isError = isError
    }

    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    public var exportLine: String {
        "[\(formattedTimestamp)] [\(process)] \(message)"
    }
}

@MainActor
public final class ActivityLogger: ObservableObject {
    public static let shared = ActivityLogger()

    @Published public private(set) var entries: [LogEntry] = []

    private let maxEntries = 500

    private init() {}

    public func log(process: String, message: String, isError: Bool = false) {
        // Redact any possible sensitive cookie or auth flags
        let sanitized = sanitizeLog(message)
        let entry = LogEntry(process: process, message: sanitized, isError: isError)
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    public func clear() {
        entries.removeAll()
    }

    public func exportText() -> String {
        entries.map { $0.exportLine }.joined(separator: "\n")
    }

    private func sanitizeLog(_ text: String) -> String {
        var clean = text
        // Scrub potential cookie headers or tokens
        clean = clean.replacingOccurrences(
            of: "(?i)cookie:[^\\s]+",
            with: "cookie: [REDACTED]",
            options: .regularExpression
        )
        clean = clean.replacingOccurrences(
            of: "(?i)bearer\\s+[a-z0-9_\\-\\.]+",
            with: "bearer [REDACTED]",
            options: .regularExpression
        )
        return clean
    }
}
