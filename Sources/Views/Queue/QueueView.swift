import SwiftUI

public struct QueueView: View {
    @ObservedObject var queueManager = DownloadQueueManager.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Download Queue")
                        .font(.system(size: 16, weight: .semibold))
                    Text("\(queueManager.tasks.count) total (\(queueManager.activeRunningCount) downloading)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Pause All") {
                    queueManager.pauseAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(queueManager.activeRunningCount == 0)

                Button("Resume All") {
                    queueManager.resumeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Clear Completed") {
                    queueManager.clearCompleted()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!queueManager.tasks.contains(where: { $0.status.isTerminal }))
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // List of Tasks or Empty State
            if queueManager.tasks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 38))
                        .foregroundColor(.secondary)
                    Text("Queue is empty")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Downloads you start will appear here with realtime speed and progress.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(queueManager.tasks) { task in
                            QueueRowView(
                                task: task,
                                onPause: { queueManager.pauseTask(id: task.id) },
                                onResume: { queueManager.startTask(id: task.id) },
                                onCancel: { queueManager.cancelTask(id: task.id) },
                                onRetry: { queueManager.retryTask(id: task.id) },
                                onRemove: { queueManager.removeTask(id: task.id) },
                                onShowInFinder: {
                                    if let url = task.finalDestinationURL {
                                        queueManager.showInFinder(url: url)
                                    }
                                },
                                onOpenFile: {
                                    if let url = task.finalDestinationURL {
                                        queueManager.openFile(url: url)
                                    }
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}
