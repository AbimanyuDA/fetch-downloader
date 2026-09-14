import Foundation

public struct PlaylistItemInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let duration: Double
    public let url: String
    public var isSelected: Bool

    public init(id: String, title: String, duration: Double, url: String, isSelected: Bool = true) {
        self.id = id
        self.title = title
        self.duration = duration
        self.url = url
        self.isSelected = isSelected
    }
}

public struct MediaInfo: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let channel: String
    public let channelUrl: String?
    public let descriptionText: String?
    public let duration: Double
    public let thumbnailUrl: String?
    public let uploadDate: String?
    public let webpageUrl: String
    public let formats: [MediaFormat]
    public let isPlaylist: Bool
    public var playlistItems: [PlaylistItemInfo]

    public init(
        id: String,
        title: String,
        channel: String,
        channelUrl: String? = nil,
        descriptionText: String? = nil,
        duration: Double = 0,
        thumbnailUrl: String? = nil,
        uploadDate: String? = nil,
        webpageUrl: String,
        formats: [MediaFormat] = [],
        isPlaylist: Bool = false,
        playlistItems: [PlaylistItemInfo] = []
    ) {
        self.id = id
        self.title = title
        self.channel = channel
        self.channelUrl = channelUrl
        self.descriptionText = descriptionText
        self.duration = duration
        self.thumbnailUrl = thumbnailUrl
        self.uploadDate = uploadDate
        self.webpageUrl = webpageUrl
        self.formats = formats
        self.isPlaylist = isPlaylist
        self.playlistItems = playlistItems
    }

    /// Highest resolution height available among video streams
    public var maxResolutionHeight: Int {
        formats.compactMap { $0.height }.max() ?? 0
    }

    /// Highest frame rate available
    public var maxFPS: Double {
        formats.compactMap { $0.fps }.max() ?? 30
    }

    /// Primary video codec detected
    public var primaryVideoCodec: String {
        let bestVideo = formats.filter { $0.hasVideo && ($0.height ?? 0) == maxResolutionHeight }.first
        return bestVideo?.videoCodec?.components(separatedBy: ".").first ?? "H.264"
    }

    /// Primary audio codec detected
    public var primaryAudioCodec: String {
        let bestAudio = formats.filter { $0.hasAudio }.first
        return bestAudio?.audioCodec?.components(separatedBy: ".").first ?? "AAC"
    }

    /// Returns sorted list of unique heights available for video selection
    public var availableHeights: [Int] {
        let heights = Set(formats.compactMap { $0.height })
        return heights.sorted(by: >)
    }

    /// Estimates file size for a given resolution height
    public func estimateSize(forHeight targetHeight: Int?) -> Int64? {
        guard let targetHeight = targetHeight else {
            // Return size for max video + best audio
            let maxVid = formats.filter { ($0.height ?? 0) == maxResolutionHeight }.first
            let bestAud = formats.filter { $0.hasAudio && !$0.hasVideo }.first
            let vBytes = maxVid?.effectiveBytes ?? 0
            let aBytes = bestAud?.effectiveBytes ?? 0
            let total = vBytes + aBytes
            return total > 0 ? total : nil
        }

        let matchedVid = formats.filter { ($0.height ?? 0) == targetHeight }.first
        let matchedAud = formats.filter { $0.hasAudio && !$0.hasVideo }.first
        let vBytes = matchedVid?.effectiveBytes ?? 0
        let aBytes = matchedAud?.effectiveBytes ?? 0
        let total = vBytes + aBytes
        return total > 0 ? total : nil
    }

    /// Estimates audio only file size
    public func estimateAudioSize(bitrateKbps: Int = 320) -> Int64? {
        if let bestAud = formats.filter({ $0.hasAudio && !$0.hasVideo }).first, let bytes = bestAud.effectiveBytes {
            return bytes
        }
        guard duration > 0 else { return nil }
        // (bitrate * 1000 / 8) * duration
        let bytes = Int64(Double(bitrateKbps * 1000 / 8) * duration)
        return bytes
    }
}
