import Foundation
import AppKit

public enum HistorySortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case name = "Name"
    case size = "File Size"

    public var id: String { rawValue }
}

@MainActor
public final class HistoryViewModel: ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public var selectedModeFilter: String = "All"
    @Published public var selectedStatusFilter: String = "All"
    @Published public var selectedSort: HistorySortOption = .newest

    private let historyManager = HistoryManager.shared

    public var filteredAndSortedEntries: [HistoryEntry] {
        let list = historyManager.filteredEntries(
            searchQuery: searchQuery,
            modeFilter: selectedModeFilter,
            statusFilter: selectedStatusFilter
        )

        switch selectedSort {
        case .newest:
            return list.sorted { $0.downloadDate > $1.downloadDate }
        case .oldest:
            return list.sorted { $0.downloadDate < $1.downloadDate }
        case .name:
            return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .size:
            return list.sorted { $0.fileSizeBytes > $1.fileSizeBytes }
        }
    }

    public func removeEntry(id: UUID) {
        historyManager.removeEntry(id: id)
    }

    public func clearAllHistory() {
        historyManager.clearHistory()
    }

    public func showInFinder(entry: HistoryEntry) {
        NSWorkspace.shared.activateFileViewerSelecting([entry.fileURL])
    }

    public func openFile(entry: HistoryEntry) {
        NSWorkspace.shared.open(entry.fileURL)
    }

    public func copyLink(entry: HistoryEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.sourceURL, forType: .string)
    }
}
