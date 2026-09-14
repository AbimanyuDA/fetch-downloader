import Foundation

public enum DownloadMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case video = "Video"
    case audio = "Audio"

    public var id: String { rawValue }
    public var iconName: String {
        self == .video ? "video.fill" : "headphones"
    }
}

public enum VideoOutputFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case mp4 = "MP4"
    case mov = "MOV"
    case mkv = "MKV"
    case webm = "WebM"
    case m4v = "M4V"

    public var id: String { rawValue }
    public var fileExtension: String {
        switch self {
        case .mp4: return "mp4"
        case .mov: return "mov"
        case .mkv: return "mkv"
        case .webm: return "webm"
        case .m4v: return "m4v"
        }
    }
}

public enum AudioOutputFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case mp3 = "MP3"
    case m4a = "M4A"
    case aac = "AAC"
    case wav = "WAV"
    case flac = "FLAC"
    case ogg = "OGG"

    public var id: String { rawValue }
    public var fileExtension: String {
        switch self {
        case .mp3: return "mp3"
        case .m4a: return "m4a"
        case .aac: return "aac"
        case .wav: return "wav"
        case .flac: return "flac"
        case .ogg: return "ogg"
        }
    }
}

public enum VideoQualityOption: Hashable, Identifiable, Sendable {
    case best
    case custom(height: Int)

    public var id: String {
        switch self {
        case .best: return "best"
        case .custom(let height): return "\(height)p"
        }
    }

    public var displayTitle: String {
        switch self {
        case .best:
            return "Best Available"
        case .custom(let height):
            switch height {
            case 2160: return "2160p (4K)"
            case 1440: return "1440p (2K)"
            case 1080: return "1080p (Full HD)"
            case 720: return "720p (HD)"
            case 480: return "480p"
            case 360: return "360p"
            default: return "\(height)p"
            }
        }
    }

    public var heightValue: Int? {
        switch self {
        case .best: return nil
        case .custom(let h): return h
        }
    }
}

public enum AudioQualityOption: Int, CaseIterable, Identifiable, Sendable {
    case best = 0
    case kbps320 = 320
    case kbps256 = 256
    case kbps192 = 192
    case kbps128 = 128

    public var id: Int { rawValue }

    public var displayTitle: String {
        switch self {
        case .best: return "Best Quality"
        case .kbps320: return "320 kbps (High)"
        case .kbps256: return "256 kbps"
        case .kbps192: return "192 kbps (Standard)"
        case .kbps128: return "128 kbps (Light)"
        }
    }
}

public enum VideoCodecOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case auto = "Auto"
    case copy = "Copy"
    case h264 = "H.264"
    case hevc = "HEVC / H.265"
    case av1 = "AV1"
    case vp9 = "VP9"

    public var id: String { rawValue }
}

public enum AudioCodecOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case auto = "Auto"
    case copy = "Copy"
    case aac = "AAC"
    case mp3 = "MP3"
    case opus = "Opus"
    case flac = "FLAC"

    public var id: String { rawValue }
}

public enum FrameRateOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case original = "Original"
    case fps60 = "60"
    case fps30 = "30"
    case fps24 = "24"

    public var id: String { rawValue }
}

public enum QualityStrategy: String, CaseIterable, Identifiable, Codable, Sendable {
    case bestQuality = "Best Quality"
    case balanced = "Balanced"
    case smallFile = "Small File"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .bestQuality:
            return "Prioritizes maximum fidelity and resolution"
        case .balanced:
            return "Good balance between visual quality and file size"
        case .smallFile:
            return "Highly compressed codecs for smaller file size"
        }
    }
}

public struct OutputSettings: Sendable {
    public var mode: DownloadMode = .video
    public var selectedVideoQuality: VideoQualityOption = .best
    public var selectedAudioQuality: AudioQualityOption = .best
    public var videoFormat: VideoOutputFormat = .mp4
    public var audioFormat: AudioOutputFormat = .mp3
    public var destinationFolder: URL
    public var filenameTemplate: String = "%(title)s"

    // Subtitles
    public var downloadSubtitles: Bool = false
    public var subtitleLanguage: String = "en"
    public var embedSubtitles: Bool = false

    // Thumbnail & Metadata
    public var downloadThumbnail: Bool = false
    public var embedThumbnail: Bool = true
    public var embedMetadata: Bool = true

    // Advanced options
    public var videoCodec: VideoCodecOption = .auto
    public var audioCodec: AudioCodecOption = .auto
    public var frameRate: FrameRateOption = .original
    public var qualityStrategy: QualityStrategy = .bestQuality

    public init(destinationFolder: URL? = nil) {
        if let folder = destinationFolder {
            self.destinationFolder = folder
        } else {
            let defaultDownloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
            self.destinationFolder = defaultDownloads
        }
    }

    /// Evaluates if the current conversion requires full transcoding or fast remux
    public var isFastRemuxOnly: Bool {
        if mode == .audio {
            // Audio to MP3 or AAC typically involves quick audio transcode
            return false
        }
        // In video mode, MKV or MP4 without forced codec change can be fast remux
        if videoFormat == .mkv {
            return true
        }
        if videoCodec == .copy {
            return true
        }
        return false
    }

    public var speedIndicatorLabel: String {
        if isFastRemuxOnly {
            return "Fast: Remux only (no quality loss)"
        } else {
            return "Transcode: Encodes video stream for maximum compatibility"
        }
    }
}
