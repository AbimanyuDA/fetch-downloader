import Foundation
import AppKit

@MainActor
public final class DownloadQueueManager: ObservableObject {
    public static let shared = DownloadQueueManager()

    @Published public private(set) var tasks: [DownloadTask] = []
    @Published public private(set) var activeRunningCount: Int = 0

    private var activeTaskHandles: [UUID: Task<Void, Never>] = [:]
    private var downloadEngine: MediaDownloadEngine = YTDLPDownloadEngine()
    private var processingEngine: MediaProcessingEngine = FFmpegProcessingEngine()

    public init() {}

    /// Enqueues a new download task — preserves the full OutputSettings snapshot
    public func enqueue(
        url: String,
        mediaInfo: MediaInfo,
        settings: OutputSettings,
        trimRange: TrimRange? = nil
    ) {
        let qualityStr: String = {
            if settings.mode == .video {
                return settings.selectedVideoQuality.displayTitle
            } else {
                return settings.selectedAudioQuality.displayTitle
            }
        }()

        let formatStr: String = {
            if settings.mode == .video {
                return settings.videoFormat.rawValue
            } else {
                return settings.audioFormat.rawValue
            }
        }()

        let ext = settings.mode == .video ? settings.videoFormat.fileExtension : settings.audioFormat.fileExtension

        let task = DownloadTask(
            url: url,
            title: mediaInfo.title,
            channel: mediaInfo.channel,
            thumbnailUrl: mediaInfo.thumbnailUrl,
            mode: settings.mode,
            qualityLabel: qualityStr,
            formatLabel: formatStr,
            targetExtension: ext,
            outputFolder: settings.destinationFolder,
            trimRange: trimRange,
            outputSettings: settings
        )

        tasks.append(task)
        processQueue()
    }

    /// Enqueues multiple URLs (Batch)
    public func enqueueBatch(urls: [String], defaultSettings: OutputSettings) {
        for u in urls {
            let trimmed = u.trimmingCharacters(in: .whitespacesAndNewlines)
            guard URLValidator.isValidMediaURL(trimmed) else { continue }
            let task = DownloadTask(
                url: trimmed,
                title: "Media URL",
                channel: "Unknown",
                mode: defaultSettings.mode,
                qualityLabel: "Default",
                formatLabel: defaultSettings.mode == .video ? defaultSettings.videoFormat.rawValue : defaultSettings.audioFormat.rawValue,
                targetExtension: defaultSettings.mode == .video ? defaultSettings.videoFormat.fileExtension : defaultSettings.audioFormat.fileExtension,
                outputFolder: defaultSettings.destinationFolder,
                outputSettings: defaultSettings
            )
            tasks.append(task)
        }
        processQueue()
    }

    /// Triggers pending items in the queue up to max concurrent limit
    public func processQueue() {
        let maxConcurrent = SettingsManager.shared.maxConcurrentDownloads
        let runningCount = tasks.filter { $0.status.isActive && $0.status != .waiting }.count
        activeRunningCount = runningCount

        guard runningCount < maxConcurrent else { return }

        let slotsAvailable = maxConcurrent - runningCount
        let waitingTasks = tasks.filter { $0.status == .waiting }

        for task in waitingTasks.prefix(slotsAvailable) {
            startTask(id: task.id)
        }
    }

    public func startTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        guard tasks[index].status == .waiting || tasks[index].status == .paused else { return }

        tasks[index].status = .downloading
        tasks[index].statusMessage = "Starting download..."
        let currentTask = tasks[index]

        PowerManagementService.shared.retainSleepPrevention()

        let handle = Task {
            await executeDownload(for: currentTask)
        }
        activeTaskHandles[id] = handle
        activeRunningCount += 1
    }

    public func cancelTask(id: UUID) {
        activeTaskHandles[id]?.cancel()
        activeTaskHandles.removeValue(forKey: id)
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = .cancelled
            tasks[index].statusMessage = "Cancelled by user"
        }
        PowerManagementService.shared.releaseSleepPrevention()
        processQueue()
    }

    public func retryTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = .waiting
            tasks[index].progressPercentage = 0
            tasks[index].downloadedBytes = 0
            tasks[index].errorMessage = nil
            tasks[index].statusMessage = "Queued for retry"
        }
        processQueue()
    }

    public func removeTask(id: UUID) {
        cancelTask(id: id)
        tasks.removeAll { $0.id == id }
    }

    public func pauseTask(id: UUID) {
        activeTaskHandles[id]?.cancel()
        activeTaskHandles.removeValue(forKey: id)
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = .paused
            tasks[index].statusMessage = "Paused"
        }
        PowerManagementService.shared.releaseSleepPrevention()
        processQueue()
    }

    public func pauseAll() {
        for task in tasks where task.status.isActive {
            pauseTask(id: task.id)
        }
    }

    public func resumeAll() {
        for i in 0..<tasks.count {
            if tasks[i].status == .paused {
                tasks[i].status = .waiting
            }
        }
        processQueue()
    }

    public func clearCompleted() {
        tasks.removeAll { $0.status == .completed || $0.status == .cancelled }
    }

    private func executeDownload(for task: DownloadTask) async {
        let taskId = task.id
        var retryCount = 0
        let maxRetries = SettingsManager.shared.autoRetryFailed ? 3 : 0

        while retryCount <= maxRetries {
            if Task.isCancelled { break }

            do {
                // Use the full OutputSettings snapshot stored at enqueue time —
                // this preserves format, quality, codec, subtitle, metadata,
                // thumbnail, and every other user-configured option.
                let settings = task.outputSettings

                // Check free disk space if possible
                if let freeSpace = try? task.outputFolder.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                    if freeSpace < 100 * 1024 * 1024 { // < 100 MB free
                        throw ProcessError.executionFailed(exitCode: 1, stderr: "Low disk space. Less than 100 MB available.")
                    }
                }

                let finalFile = try await downloadEngine.download(
                    url: task.url,
                    settings: settings,
                    trimRange: task.trimRange
                ) { [weak self] update in
                    Task { @MainActor in
                        self?.updateTaskProgress(id: taskId, update: update)
                    }
                }

                if Task.isCancelled {
                    PowerManagementService.shared.releaseSleepPrevention()
                    return
                }

                // Mark completion
                if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                    tasks[index].status = .completed
                    tasks[index].progressPercentage = 100.0
                    tasks[index].statusMessage = "Completed"
                    tasks[index].finalDestinationURL = finalFile
                    tasks[index].completedAt = Date()

                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: finalFile.path)[.size] as? Int64) ?? tasks[index].totalBytes

                    // Add to History
                    if SettingsManager.shared.keepHistory {
                        let entry = HistoryEntry(
                            id: UUID(),
                            title: tasks[index].title,
                            channel: tasks[index].channel,
                            sourceURL: tasks[index].url,
                            localFilePath: finalFile.path,
                            filename: finalFile.lastPathComponent,
                            thumbnailURL: tasks[index].thumbnailUrl,
                            format: tasks[index].formatLabel,
                            quality: tasks[index].qualityLabel,
                            fileSizeBytes: fileSize,
                            downloadDate: Date(),
                            mode: tasks[index].mode.rawValue,
                            status: "Completed"
                        )
                        HistoryManager.shared.addEntry(entry)
                    }

                    // System Notification
                    if SettingsManager.shared.enableNotifications {
                        NotificationService.shared.sendDownloadCompletedNotification(filename: finalFile.lastPathComponent)
                    }
                }

                activeTaskHandles.removeValue(forKey: taskId)
                PowerManagementService.shared.releaseSleepPrevention()
                processQueue()
                return

            } catch {
                if Task.isCancelled {
                    PowerManagementService.shared.releaseSleepPrevention()
                    return
                }

                retryCount += 1
                if retryCount <= maxRetries {
                    if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                        tasks[index].statusMessage = "Retrying (attempt \(retryCount) of \(maxRetries))..."
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                } else {
                    // Final failure
                    if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                        tasks[index].status = .failed
                        tasks[index].errorMessage = error.localizedDescription
                        tasks[index].statusMessage = "Failed"

                        if SettingsManager.shared.enableNotifications {
                            NotificationService.shared.sendDownloadFailedNotification(
                                title: tasks[index].title,
                                error: error.localizedDescription
                            )
                        }
                    }
                    activeTaskHandles.removeValue(forKey: taskId)
                    PowerManagementService.shared.releaseSleepPrevention()
                    processQueue()
                    return
                }
            }
        }
    }

    private func updateTaskProgress(id: UUID, update: ParsedProgressUpdate) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        if let p = update.percentage {
            tasks[index].progressPercentage = p
        }
        if let d = update.downloadedBytes {
            tasks[index].downloadedBytes = d
        }
        if let t = update.totalBytes {
            tasks[index].totalBytes = t
        }
        if let s = update.speedBytesPerSecond {
            tasks[index].downloadSpeed = s
        }
        if let eta = update.etaSeconds {
            tasks[index].etaSeconds = eta
        }
        if let phase = update.phase {
            tasks[index].status = phase
            tasks[index].statusMessage = phase.rawValue
        }
    }

    public func showInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public func openFile(url: URL) {
        NSWorkspace.shared.open(url)
    }
}
