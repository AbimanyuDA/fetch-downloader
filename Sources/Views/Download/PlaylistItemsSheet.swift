import SwiftUI

public struct PlaylistItemsSheet: View {
    @ObservedObject var viewModel: DownloadViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    private var selectedCount: Int {
        viewModel.mediaInfo?.playlistItems.filter { $0.isSelected }.count ?? 0
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.mediaInfo?.title ?? "Playlist")
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(selectedCount) of \(viewModel.mediaInfo?.playlistItems.count ?? 0) videos selected")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Select All") {
                    selectAll(true)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Deselect All") {
                    selectAll(false)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // List of items
            if let items = viewModel.mediaInfo?.playlistItems {
                List {
                    ForEach(items.indices, id: \.self) { idx in
                        HStack(spacing: 12) {
                            Toggle("", isOn: Binding(
                                get: { viewModel.mediaInfo?.playlistItems[idx].isSelected ?? false },
                                set: { viewModel.mediaInfo?.playlistItems[idx].isSelected = $0 }
                            ))
                            .labelsHidden()

                            Text("\(idx + 1).")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 28, alignment: .trailing)

                            Text(items[idx].title)
                                .font(.system(size: 12))
                                .lineLimit(1)

                            Spacer()

                            if items[idx].duration > 0 {
                                Text(TimeFormatter.format(seconds: items[idx].duration))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // Footer actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Add to Queue (\(selectedCount))") {
                    viewModel.enqueueSelectedPlaylistItems()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 520, minHeight: 440)
    }

    private func selectAll(_ select: Bool) {
        guard let count = viewModel.mediaInfo?.playlistItems.count else { return }
        for i in 0..<count {
            viewModel.mediaInfo?.playlistItems[i].isSelected = select
        }
    }
}
