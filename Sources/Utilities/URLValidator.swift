import Foundation

public enum MediaPlatform: String, CaseIterable, Identifiable, Sendable {
    case youtubeVideo = "YouTube Video"
    case youtubeShorts = "YouTube Shorts"
    case youtubePlaylist = "YouTube Playlist"
    case generic = "Web Media"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .youtubeVideo:
            return "play.rectangle.fill"
        case .youtubeShorts:
            return "bolt.fill"
        case .youtubePlaylist:
            return "list.bullet.rectangle.fill"
        case .generic:
            return "link"
        }
    }
}

public enum URLValidator {
    /// Validates if string is a well-formed HTTP/HTTPS URL
    public static func isValidMediaURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
            return false
        }
        guard scheme == "http" || scheme == "https" else {
            return false
        }
        guard let host = url.host?.lowercased(), !host.isEmpty else {
            return false
        }
        return true
    }

    /// Detects platform and media type from URL
    public static func detectPlatform(from urlString: String) -> MediaPlatform {
        let lower = urlString.lowercased()

        if lower.contains("youtube.com/playlist") || lower.contains("list=") {
            return .youtubePlaylist
        } else if lower.contains("youtube.com/shorts/") {
            return .youtubeShorts
        } else if lower.contains("youtube.com/watch") || lower.contains("youtu.be/") {
            return .youtubeVideo
        } else {
            return .generic
        }
    }

    /// Checks if a string looks like a playlist
    public static func isPlaylistURL(_ urlString: String) -> Bool {
        let lower = urlString.lowercased()
        return lower.contains("list=") || lower.contains("/playlist")
    }

    /// Cleans tracking parameters from YouTube URLs while preserving video ID and playlist ID
    public static func cleanURL(_ rawURL: String) -> String {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else { return trimmed }

        // Keep relevant query items for YouTube
        let allowedQueryKeys = Set(["v", "list", "t", "index"])
        if let queryItems = components.queryItems {
            components.queryItems = queryItems.filter { allowedQueryKeys.contains($0.name.lowercased()) }
        }
        return components.url?.absoluteString ?? trimmed
    }
}
