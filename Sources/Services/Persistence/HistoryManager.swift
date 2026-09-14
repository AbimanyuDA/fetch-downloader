import Foundation

@MainActor
public final class HistoryManager: ObservableObject {
    public static let shared = HistoryManager()

    @Published public private(set) var entries: [HistoryEntry] = []

    private let fileManager = FileManager.default
    private var historyFileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("MediaFetch", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("history.json")
    }

    public init() {
        loadHistory()
    }

    public func addEntry(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        entries.insert(entry, at: 0)
        saveHistory()
    }

    public func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        saveHistory()
    }

    public func clearHistory() {
        entries.removeAll()
        saveHistory()
    }

    public func filteredEntries(
        searchQuery: String,
        modeFilter: String, // "All", "Video", "Audio"
        statusFilter: String // "All", "Completed", "Failed"
    ) -> [HistoryEntry] {
        entries.filter { entry in
            let matchesQuery = searchQuery.isEmpty ||
                entry.title.localizedCaseInsensitiveContains(searchQuery) ||
                entry.filename.localizedCaseInsensitiveContains(searchQuery) ||
                entry.channel.localizedCaseInsensitiveContains(searchQuery)

            let matchesMode = modeFilter == "All" || entry.mode.lowercased() == modeFilter.lowercased()
            let matchesStatus = statusFilter == "All" || entry.status.lowercased() == statusFilter.lowercased()

            return matchesQuery && matchesMode && matchesStatus
        }
    }

    private func loadHistory() {
        guard fileManager.fileExists(atPath: historyFileURL.path),
              let data = try? Data(contentsOf: historyFileURL),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            return
        }
        self.entries = decoded
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: historyFileURL, options: .atomic)
        } catch {
            print("Failed to save history: \(error.localizedDescription)")
        }
    }
}
