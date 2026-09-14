import Foundation

public struct MediaFormat: Identifiable, Hashable, Sendable {
    public let id: String
    public let ext: String
    public let resolution: String?
    public let width: Int?
    public let height: Int?
    public let fps: Double?
    public let videoCodec: String?
    public let audioCodec: String?
    public let filesize: Int64?
    public let filesizeApprox: Int64?
    public let tbr: Double?
    public let vbr: Double?
    public let abr: Double?

    public init(
        id: String,
        ext: String,
        resolution: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        fps: Double? = nil,
        videoCodec: String? = nil,
        audioCodec: String? = nil,
        filesize: Int64? = nil,
        filesizeApprox: Int64? = nil,
        tbr: Double? = nil,
        vbr: Double? = nil,
        abr: Double? = nil
    ) {
        self.id = id
        self.ext = ext
        self.resolution = resolution
        self.width = width
        self.height = height
        self.fps = fps
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.filesize = filesize
        self.filesizeApprox = filesizeApprox
        self.tbr = tbr
        self.vbr = vbr
        self.abr = abr
    }

    public var hasVideo: Bool {
        guard let vcodec = videoCodec, vcodec != "none" else { return false }
        return true
    }

    public var hasAudio: Bool {
        guard let acodec = audioCodec, acodec != "none" else { return false }
        return true
    }

    public var effectiveBytes: Int64? {
        filesize ?? filesizeApprox
    }

    public var formattedResolution: String {
        if let h = height {
            return "\(h)p"
        }
        return resolution ?? "Unknown"
    }

    public var displayCodecInfo: String {
        var parts: [String] = []
        if let v = videoCodec, v != "none" {
            parts.append(cleanCodecName(v))
        }
        if let a = audioCodec, a != "none" {
            parts.append(cleanCodecName(a))
        }
        return parts.joined(separator: " + ")
    }

    private func cleanCodecName(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("avc") || lower.contains("h264") { return "H.264" }
        if lower.contains("hev") || lower.contains("h265") { return "HEVC" }
        if lower.contains("av01") || lower.contains("av1") { return "AV1" }
        if lower.contains("vp9") { return "VP9" }
        if lower.contains("mp4a") || lower.contains("aac") { return "AAC" }
        if lower.contains("opus") { return "Opus" }
        if lower.contains("mp3") { return "MP3" }
        return raw.components(separatedBy: ".").first ?? raw
    }
}
