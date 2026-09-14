import SwiftUI

public struct QueueRowView: View {
    let task: DownloadTask
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void
    let onRetry: () -> Void
    let onRemove: () -> Void
    let onShowInFinder: () -> Void
    let onOpenFile: () -> Void

    public init(
        task: DownloadTask,
        onPause: @escaping () -> Void,
        onResume: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onRetry: @escaping () -> Void,
        onRemove: @escaping () -> Void,
        onShowInFinder: @escaping () -> Void,
        onOpenFile: @escaping () -> Void
    ) {
        self.task = task
        self.onPause = onPause
        self.onResume = onResume
        self.onCancel = onCancel
        self.onRetry = onRetry
        self.onRemove = onRemove
        self.onShowInFinder = onShowInFinder
        self.onOpenFile = onOpenFile
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Thumbnail / Icon
            ZStack {
                if let thumbStr = task.thumbnailUrl, let url = URL(string: thumbStr) {
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
                        .overlay(Image(systemName: task.mode == .video ? "video.fill" : "headphones").foregroundColor(.secondary))
                }
            }
            .frame(width: 80, height: 48)
            .cornerRadius(6)
            .clipped()

            // Details and Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(status: task.status)
                }

                // Progress Bar
                if task.status == .downloading || task.status == .merging || task.status == .converting || task.status == .trimming {
                    ProgressView(value: max(0.01, task.progressPercentage / 100.0))
                        .progressViewStyle(.linear)
                } else if task.status == .waiting || task.status == .fetching {
                    ProgressView()
                        .progressViewStyle(.linear)
                }

                // Metrics Row
                HStack(spacing: 8) {
                    Text("\(task.qualityLabel) • \(task.formatLabel)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    if task.status == .downloading {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(task.formattedProgress)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(task.formattedSpeed)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("ETA \(task.formattedETA)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else if let err = task.errorMessage {
                        Text(err)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .lineLimit(1)
                    } else {
                        Text(task.statusMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            // Controls
            HStack(spacing: 6) {
                if task.status == .downloading {
                    Button {
                        onPause()
                    } label: {
                        Image(systemName: "pause.fill")
                    }
                    .buttonStyle(.plain)
                    .help("Pause")

                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel")
                } else if task.status == .paused {
                    Button {
                        onResume()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.plain)
                    .help("Resume")

                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel")
                } else if task.status == .completed {
                    Button {
                        onShowInFinder()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Show in Finder")

                    Button {
                        onOpenFile()
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Open File")

                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove from Queue")
                } else if task.status == .failed || task.status == .cancelled {
                    Button {
                        onRetry()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Retry")

                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove from Queue")
                }
            }
            .frame(width: 90, alignment: .trailing)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

private struct StatusBadge: View {
    let status: DownloadStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeBackground)
            .foregroundColor(badgeForeground)
            .cornerRadius(4)
    }

    private var badgeBackground: Color {
        switch status {
        case .completed:
            return Color.green.opacity(0.15)
        case .failed:
            return Color.red.opacity(0.15)
        case .cancelled, .paused:
            return Color.gray.opacity(0.15)
        case .downloading, .merging, .converting, .trimming:
            return Color.accentColor.opacity(0.15)
        case .waiting, .fetching:
            return Color.orange.opacity(0.15)
        }
    }

    private var badgeForeground: Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        case .cancelled, .paused: return .secondary
        case .downloading, .merging, .converting, .trimming: return .accentColor
        case .waiting, .fetching: return .orange
        }
    }
}
