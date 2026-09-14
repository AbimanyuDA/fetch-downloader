import Foundation

public final class MetadataFetcher: Sendable {
    public init() {}

    public func fetchMetadata(for urlString: String) async throws -> MediaInfo {
        let cleanURL = URLValidator.cleanURL(urlString)
        guard URLValidator.isValidMediaURL(cleanURL) else {
            throw ProcessError.executionFailed(exitCode: 1, stderr: "Invalid URL. Please provide a valid media link.")
        }

        guard let ytdlpURL = await DependencyManager.shared.resolvePath(for: "yt-dlp") else {
            throw ProcessError.binaryNotFound("yt-dlp")
        }

        let arguments = [
            "--dump-single-json",
            "--no-warnings",
            "--no-playlist",
            cleanURL
        ]

        await ActivityLogger.shared.log(process: "yt-dlp", message: "Fetching metadata for: \(cleanURL)")

        let runner = ProcessRunner()
        let result = try await runner.run(executableURL: ytdlpURL, arguments: arguments)

        guard result.isSuccess else {
            let errorMsg = parseErrorMessage(result.stderr)
            await ActivityLogger.shared.log(process: "yt-dlp", message: "Metadata fetch failed: \(errorMsg)", isError: true)
            throw ProcessError.executionFailed(exitCode: result.exitCode, stderr: errorMsg)
        }

        guard let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProcessError.executionFailed(exitCode: 1, stderr: "Failed to parse metadata from yt-dlp.")
        }

        return parseJSONToMediaInfo(json: json, originalURL: cleanURL)
    }

    /// Fetches full playlist items if a playlist link is provided
    public func fetchPlaylistItems(for playlistURL: String) async throws -> [PlaylistItemInfo] {
        guard let ytdlpURL = await DependencyManager.shared.resolvePath(for: "yt-dlp") else {
            throw ProcessError.binaryNotFound("yt-dlp")
        }

        let arguments = [
            "--flat-playlist",
            "--dump-single-json",
            "--no-warnings",
            playlistURL
        ]

        let runner = ProcessRunner()
        let result = try await runner.run(executableURL: ytdlpURL, arguments: arguments)

        guard result.isSuccess,
              let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["entries"] as? [[String: Any]] else {
            return []
        }

        var items: [PlaylistItemInfo] = []
        for entry in entries {
            let id = (entry["id"] as? String) ?? UUID().uuidString
            let title = (entry["title"] as? String) ?? "Untitled Video"
            let duration = parseDouble(entry["duration"]) ?? 0.0
            let url = (entry["url"] as? String) ?? "https://www.youtube.com/watch?v=\(id)"
            items.append(PlaylistItemInfo(id: id, title: title, duration: duration, url: url, isSelected: true))
        }
        return items
    }

    private func parseJSONToMediaInfo(json: [String: Any], originalURL: String) -> MediaInfo {
        let id = (json["id"] as? String) ?? UUID().uuidString
        let title = (json["title"] as? String) ?? "Media File"
        let channel = (json["uploader"] as? String) ?? (json["channel"] as? String) ?? "Unknown Artist"
        let channelUrl = json["channel_url"] as? String
        let description = json["description"] as? String
        let duration = parseDouble(json["duration"]) ?? 0.0
        let thumbnail = json["thumbnail"] as? String
        let uploadDate = json["upload_date"] as? String
        let webpageUrl = (json["webpage_url"] as? String) ?? originalURL

        var formats: [MediaFormat] = []
        if let rawFormats = json["formats"] as? [[String: Any]] {
            for f in rawFormats {
                guard let fId = f["format_id"] as? String,
                      let ext = f["ext"] as? String else { continue }

                let resolution = f["resolution"] as? String
                let width = parseInt(f["width"])
                let height = parseInt(f["height"])
                let fps = parseDouble(f["fps"])
                let vcodec = f["vcodec"] as? String
                let acodec = f["acodec"] as? String
                let filesize = parseInt64(f["filesize"])
                let filesizeApprox = parseInt64(f["filesize_approx"])
                let tbr = parseDouble(f["tbr"])
                let vbr = parseDouble(f["vbr"])
                let abr = parseDouble(f["abr"])

                formats.append(MediaFormat(
                    id: fId,
                    ext: ext,
                    resolution: resolution,
                    width: width,
                    height: height,
                    fps: fps,
                    videoCodec: vcodec,
                    audioCodec: acodec,
                    filesize: filesize,
                    filesizeApprox: filesizeApprox,
                    tbr: tbr,
                    vbr: vbr,
                    abr: abr
                ))
            }
        }

        let isPlaylist = (json["_type"] as? String) == "playlist"

        return MediaInfo(
            id: id,
            title: title,
            channel: channel,
            channelUrl: channelUrl,
            descriptionText: description,
            duration: duration,
            thumbnailUrl: thumbnail,
            uploadDate: uploadDate,
            webpageUrl: webpageUrl,
            formats: formats,
            isPlaylist: isPlaylist,
            playlistItems: []
        )
    }

    private func parseDouble(_ val: Any?) -> Double? {
        if let num = val as? NSNumber {
            return num.doubleValue
        }
        if let str = val as? String {
            return Double(str)
        }
        return nil
    }

    private func parseInt(_ val: Any?) -> Int? {
        if let num = val as? NSNumber {
            return num.intValue
        }
        if let str = val as? String {
            return Int(str)
        }
        return nil
    }

    private func parseInt64(_ val: Any?) -> Int64? {
        if let num = val as? NSNumber {
            return num.int64Value
        }
        if let str = val as? String {
            return Int64(str)
        }
        return nil
    }

    private func parseErrorMessage(_ stderr: String) -> String {
        let clean = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased().contains("private video") {
            return "This video is private and cannot be downloaded without authentication."
        }
        if clean.lowercased().contains("video unavailable") {
            return "Video unavailable. It may have been removed, region restricted, or require authentication."
        }
        if clean.lowercased().contains("sign in to confirm your age") {
            return "Age restricted video. Downloading requires authentication."
        }
        if clean.lowercased().contains("network is unreachable") || clean.lowercased().contains("connection refused") {
            return "Network connection issue. Please check your internet connection and try again."
        }
        if clean.isEmpty {
            return "An unexpected error occurred while fetching media metadata."
        }
        for line in clean.components(separatedBy: .newlines) {
            if line.hasPrefix("ERROR:") {
                return line.replacingOccurrences(of: "ERROR:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        return clean
    }
}
