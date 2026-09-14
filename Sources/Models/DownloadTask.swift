import Foundation

public enum DownloadStatus: String, CaseIterable, Identifiable, Codable, Sendable {
    case waiting = "Waiting"
    case fetching = "Fetching"
    case downloading = "Downloading"
    case merging = "Merging Video and Audio"
    case converting = "Converting Format"
    case trimming = "Trimming Media"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    case paused = "Paused"

    public var id: String { rawValue }

    public var isActive: Bool {
        switch self {
        case .waiting, .fetching, .downloading, .merging, .converting, .trimming:
            return true
        default:
            return false
        }
    }

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        default:
            return false
        }
    }
}

public struct DownloadTask: Identifiable, Sendable {
    public let id: UUID
    public let url: String
    public var title: String
    public var channel: String
    public var thumbnailUrl: String?
    public var mode: DownloadMode
    public var qualityLabel: String
    public var formatLabel: String
    public var targetExtension: String
    public var outputFolder: URL
    public var finalDestinationURL: URL?
    public var trimRange: TrimRange?

    /// Full output settings snapshot taken at enqueue time — ensures the download
    /// engine uses exactly the options the user configured (format, codec, quality,
    /// subtitle, thumbnail, metadata flags, etc.).
    public var outputSettings: OutputSettings

    public var status: DownloadStatus = .waiting
    public var progressPercentage: Double = 0.0
    public var downloadedBytes: Int64 = 0
    public var totalBytes: Int64 = 0
    public var downloadSpeed: Double = 0.0
    public var etaSeconds: Int = 0
    public var statusMessage: String = "Queued"
    public var errorMessage: String?
    public var technicalDetails: String?
    public var createdAt: Date = Date()
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        url: String,
        title: String,
        channel: String,
        thumbnailUrl: String? = nil,
        mode: DownloadMode = .video,
        qualityLabel: String = "Best Available",
        formatLabel: String = "MP4",
        targetExtension: String = "mp4",
        outputFolder: URL,
        finalDestinationURL: URL? = nil,
        trimRange: TrimRange? = nil,
        outputSettings: OutputSettings? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.channel = channel
        self.thumbnailUrl = thumbnailUrl
        self.mode = mode
        self.qualityLabel = qualityLabel
        self.formatLabel = formatLabel
        self.targetExtension = targetExtension
        self.outputFolder = outputFolder
        self.finalDestinationURL = finalDestinationURL
        self.trimRange = trimRange
        self.outputSettings = outputSettings ?? OutputSettings(destinationFolder: outputFolder)
    }

    public var formattedSpeed: String {
        FileSizeFormatter.formatSpeed(bytesPerSecond: downloadSpeed)
    }

    public var formattedETA: String {
        TimeFormatter.formatETA(seconds: etaSeconds)
    }

    public var formattedProgress: String {
        let downloaded = FileSizeFormatter.format(bytes: downloadedBytes)
        if totalBytes > 0 {
            let total = FileSizeFormatter.format(bytes: totalBytes)
            return "\(downloaded) / \(total)"
        }
        return downloaded
    }
}
