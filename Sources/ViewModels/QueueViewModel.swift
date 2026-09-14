import Foundation
import SwiftUI

@MainActor
public final class QueueViewModel: ObservableObject {
    private let queueManager = DownloadQueueManager.shared

    public var tasks: [DownloadTask] {
        queueManager.tasks
    }

    public var activeCount: Int {
        queueManager.activeRunningCount
    }

    public var hasCompletedTasks: Bool {
        tasks.contains { $0.status == .completed || $0.status == .cancelled }
    }

    public func pauseTask(id: UUID) {
        queueManager.pauseTask(id: id)
    }

    public func resumeTask(id: UUID) {
        queueManager.startTask(id: id)
    }

    public func cancelTask(id: UUID) {
        queueManager.cancelTask(id: id)
    }

    public func retryTask(id: UUID) {
        queueManager.retryTask(id: id)
    }

    public func removeTask(id: UUID) {
        queueManager.removeTask(id: id)
    }

    public func pauseAll() {
        queueManager.pauseAll()
    }

    public func resumeAll() {
        queueManager.resumeAll()
    }

    public func clearCompleted() {
        queueManager.clearCompleted()
    }

    public func showInFinder(for task: DownloadTask) {
        if let url = task.finalDestinationURL {
            queueManager.showInFinder(url: url)
        } else {
            queueManager.showInFinder(url: task.outputFolder)
        }
    }

    public func openFile(for task: DownloadTask) {
        if let url = task.finalDestinationURL {
            queueManager.openFile(url: url)
        }
    }
}
