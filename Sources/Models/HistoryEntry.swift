import Foundation

public struct HistoryEntry: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let channel: String
    public let sourceURL: String
    public let localFilePath: String
    public let filename: String
    public let thumbnailURL: String?
    public let format: String
    public let quality: String
    public let fileSizeBytes: Int64
    public let downloadDate: Date
    public let mode: String
    public let status: String

    public init(
        id: UUID = UUID(),
        title: String,
        channel: String,
        sourceURL: String,
        localFilePath: String,
        filename: String,
        thumbnailURL: String? = nil,
        format: String,
        quality: String,
        fileSizeBytes: Int64 = 0,
        downloadDate: Date = Date(),
        mode: String = "Video",
        status: String = "Completed"
    ) {
        self.id = id
        self.title = title
        self.channel = channel
        self.sourceURL = sourceURL
        self.localFilePath = localFilePath
        self.filename = filename
        self.thumbnailURL = thumbnailURL
        self.format = format
        self.quality = quality
        self.fileSizeBytes = fileSizeBytes
        self.downloadDate = downloadDate
        self.mode = mode
        self.status = status
    }

    public var fileURL: URL {
        URL(fileURLWithPath: localFilePath)
    }

    public var fileExists: Bool {
        FileManager.default.fileExists(atPath: localFilePath)
    }

    public var formattedSize: String {
        FileSizeFormatter.format(bytes: fileSizeBytes)
    }
}
