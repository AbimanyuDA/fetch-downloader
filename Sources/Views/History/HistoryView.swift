import SwiftUI

public struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showClearConfirmation: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Filter and Search Header
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search downloads...", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )

                    Picker("Sort", selection: $viewModel.selectedSort) {
                        ForEach(HistorySortOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 110)

                    Button("Clear History") {
                        showClearConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.filteredAndSortedEntries.isEmpty)
                }

                // Filter tabs
                HStack {
                    Picker("Mode", selection: $viewModel.selectedModeFilter) {
                        Text("All").tag("All")
                        Text("Video").tag("Video")
                        Text("Audio").tag("Audio")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    Spacer()

                    Text("\(viewModel.filteredAndSortedEntries.count) items")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // History List
            if viewModel.filteredAndSortedEntries.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 38))
                        .foregroundColor(.secondary)
                    Text("No history entries")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Downloaded files will be remembered locally here.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredAndSortedEntries) { entry in
                            HistoryRowView(
                                entry: entry,
                                onOpen: { viewModel.openFile(entry: entry) },
                                onShowInFinder: { viewModel.showInFinder(entry: entry) },
                                onCopyLink: { viewModel.copyLink(entry: entry) },
                                onDelete: { viewModel.removeEntry(id: entry.id) }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .confirmationDialog(
            "Clear Download History?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All History", role: .destructive) {
                viewModel.clearAllHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all entries from your history list. Downloaded files on disk will not be deleted.")
        }
    }
}
