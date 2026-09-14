import SwiftUI

public struct HistoryRowView: View {
    let entry: HistoryEntry
    let onOpen: () -> Void
    let onShowInFinder: () -> Void
    let onCopyLink: () -> Void
    let onDelete: () -> Void

    public init(
        entry: HistoryEntry,
        onOpen: @escaping () -> Void,
        onShowInFinder: @escaping () -> Void,
        onCopyLink: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.entry = entry
        self.onOpen = onOpen
        self.onShowInFinder = onShowInFinder
        self.onCopyLink = onCopyLink
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Thumbnail / Icon
            ZStack {
                if let thumb = entry.thumbnailURL, let url = URL(string: thumb) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().aspectRatio(16/9, contentMode: .fill)
                        } else {
                            Rectangle().fill(Color(nsColor: .controlBackgroundColor))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(Image(systemName: entry.mode == "Video" ? "video.fill" : "headphones").foregroundColor(.secondary))
                }
            }
            .frame(width: 72, height: 44)
            .cornerRadius(6)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(entry.filename)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(entry.formattedSize)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(formatDate(entry.downloadDate))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 6) {
                Button {
                    onShowInFinder()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Show in Finder")

                Button {
                    onOpen()
                } label: {
                    Image(systemName: "play.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open File")

                Button {
                    onCopyLink()
                } label: {
                    Image(systemName: "link")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Copy Source Link")

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Delete from History")
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
