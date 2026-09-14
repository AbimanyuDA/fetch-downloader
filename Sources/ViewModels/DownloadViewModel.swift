import Foundation
import SwiftUI
import AppKit

@MainActor
public final class DownloadViewModel: ObservableObject {
    @Published public var inputURL: String = ""
    @Published public var isFetching: Bool = false
    @Published public var errorMessage: String?
    @Published public var technicalError: String?
    @Published public var mediaInfo: MediaInfo?
    @Published public var settings: OutputSettings
    @Published public var trimRange: TrimRange = TrimRange()
    @Published public var showBatchSheet: Bool = false
    @Published public var batchInputText: String = ""
    @Published public var showPlaylistSheet: Bool = false

    private let metadataFetcher = MetadataFetcher()

    public init() {
        let initialFolder = SettingsManager.shared.outputFolderURL
        self.settings = OutputSettings(destinationFolder: initialFolder)
    }

    public var isURLValid: Bool {
        URLValidator.isValidMediaURL(inputURL)
    }

    public var detectedPlatform: MediaPlatform {
        URLValidator.detectPlatform(from: inputURL)
    }

    public var availableQualityOptions: [VideoQualityOption] {
        guard let info = mediaInfo else {
            return [.best]
        }
        var options: [VideoQualityOption] = [.best]
        for height in info.availableHeights {
            options.append(.custom(height: height))
        }
        return options
    }

    public var estimatedFileSizeString: String {
        guard let info = mediaInfo else { return "Approx. Unknown" }
        if settings.mode == .video {
            let bytes = info.estimateSize(forHeight: settings.selectedVideoQuality.heightValue)
            return FileSizeFormatter.formatEstimated(bytes: bytes)
        } else {
            let bytes = info.estimateAudioSize(bitrateKbps: settings.selectedAudioQuality.rawValue)
            return FileSizeFormatter.formatEstimated(bytes: bytes)
        }
    }

    public func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !string.isEmpty {
            inputURL = string
            fetchMedia()
        }
    }

    public func clearURL() {
        inputURL = ""
        mediaInfo = nil
        errorMessage = nil
        technicalError = nil
        trimRange = TrimRange()
    }

    public func fetchMedia() {
        let clean = URLValidator.cleanURL(inputURL)
        guard URLValidator.isValidMediaURL(clean) else {
            errorMessage = "Please enter a valid HTTP or HTTPS media URL."
            return
        }

        isFetching = true
        errorMessage = nil
        technicalError = nil

        Task {
            do {
                var info = try await metadataFetcher.fetchMetadata(for: clean)

                if info.isPlaylist {
                    let items = try? await metadataFetcher.fetchPlaylistItems(for: clean)
                    info.playlistItems = items ?? []
                    self.showPlaylistSheet = true
                }

                self.mediaInfo = info
                self.trimRange = TrimRange(
                    isEnabled: false,
                    startTime: 0,
                    endTime: info.duration,
                    totalDuration: info.duration
                )
                self.isFetching = false
            } catch let err as ProcessError {
                self.errorMessage = err.localizedDescription
                if case .executionFailed(let code, let errStr) = err {
                    self.technicalError = "Exit code: \(code)\n\(errStr)"
                }
                self.isFetching = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isFetching = false
            }
        }
    }

    public func chooseDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select Output Folder"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            settings.destinationFolder = selectedURL
            SettingsManager.shared.outputFolderPath = selectedURL.path
        }
    }

    public func startDownload() {
        guard let info = mediaInfo else { return }
        DownloadQueueManager.shared.enqueue(
            url: inputURL,
            mediaInfo: info,
            settings: settings,
            trimRange: trimRange.isEnabled ? trimRange : nil
        )
    }

    public func enqueueSelectedPlaylistItems() {
        guard let info = mediaInfo, !info.playlistItems.isEmpty else { return }
        let selected = info.playlistItems.filter { $0.isSelected }
        let urls = selected.map { $0.url }
        DownloadQueueManager.shared.enqueueBatch(urls: urls, defaultSettings: settings)
        showPlaylistSheet = false
    }

    public func submitBatchURLs() {
        let lines = batchInputText.components(separatedBy: .newlines)
        DownloadQueueManager.shared.enqueueBatch(urls: lines, defaultSettings: settings)
        batchInputText = ""
        showBatchSheet = false
    }
}
