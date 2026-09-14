import Foundation

public final class YTDLPDownloadEngine: MediaDownloadEngine {
    public init() {}

    public func download(
        url: String,
        settings: OutputSettings,
        trimRange: TrimRange?,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL {
        guard let ytdlpURL = await DependencyManager.shared.resolvePath(for: "yt-dlp") else {
            throw ProcessError.binaryNotFound("yt-dlp")
        }

        var arguments: [String] = [
            "--no-warnings",
            "--newline",
            "--progress",
            "--print", "after_move:filepath",
            // Faster downloads: parallel fragment downloading and larger buffers
            "--concurrent-fragments", "8",
            "--buffer-size", "16M",
            "--http-chunk-size", "10M",
            // Retry on transient failures
            "--retries", "5",
            "--fragment-retries", "5",
            // Prefer fast-CDN with format sorting
            "--extractor-args", "youtube:player_client=android,web"
        ]

        // Supply ffmpeg location to yt-dlp if available
        if let ffmpegURL = await DependencyManager.shared.resolvePath(for: "ffmpeg") {
            arguments.append(contentsOf: ["--ffmpeg-location", ffmpegURL.deletingLastPathComponent().path])
        }

        // Format specification
        if settings.mode == .video {
            let targetExt = settings.videoFormat.fileExtension
            if let height = settings.selectedVideoQuality.heightValue {
                // Best video up to height + best audio, with fallbacks
                arguments.append(contentsOf: [
                    "-f", "bv*[height<=\(height)]+ba/b[height<=\(height)] / best[height<=\(height)] / best"
                ])
            } else {
                arguments.append(contentsOf: [
                    "-f", "bv*+ba/b"
                ])
            }
            arguments.append(contentsOf: ["--merge-output-format", targetExt])

            // Remap video codecs if user specified one
            switch settings.videoCodec {
            case .h264:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:v libx264"])
            case .hevc:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:v libx265"])
            case .av1:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:v libaom-av1"])
            case .vp9:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:v libvpx-vp9"])
            case .copy:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:v copy"])
            case .auto:
                break
            }

            // Audio codec for video mode
            switch settings.audioCodec {
            case .aac:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:a aac"])
            case .mp3:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:a libmp3lame"])
            case .opus:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:a libopus"])
            case .flac:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:a flac"])
            case .copy:
                arguments.append(contentsOf: ["--postprocessor-args", "ffmpeg:-c:a copy"])
            case .auto:
                break
            }

            // Frame rate
            switch settings.frameRate {
            case .fps60:
                arguments.append(contentsOf: ["-S", "+fps:60"])
            case .fps30:
                arguments.append(contentsOf: ["-S", "+fps:30"])
            case .fps24:
                arguments.append(contentsOf: ["-S", "+fps:24"])
            case .original:
                break
            }

        } else {
            // Audio mode
            let targetExt = settings.audioFormat.fileExtension
            arguments.append(contentsOf: [
                "-x",
                "--audio-format", targetExt
            ])
            if settings.selectedAudioQuality.rawValue > 0 {
                arguments.append(contentsOf: [
                    "--audio-quality", "\(settings.selectedAudioQuality.rawValue)k"
                ])
            } else {
                arguments.append(contentsOf: [
                    "--audio-quality", "0"
                ])
            }
        }

        // Subtitles
        if settings.downloadSubtitles {
            arguments.append(contentsOf: ["--write-subs", "--sub-lang", settings.subtitleLanguage])
            if settings.embedSubtitles && settings.mode == .video {
                arguments.append("--embed-subs")
            }
        }

        // Thumbnail — only write or embed when user explicitly wants it
        if settings.downloadThumbnail {
            arguments.append("--write-thumbnail")
        }
        if settings.embedThumbnail {
            arguments.append("--embed-thumbnail")
        }

        // Metadata
        if settings.embedMetadata {
            arguments.append("--add-metadata")
        }

        // Trimming with download-sections if enabled
        if let trim = trimRange, trim.isEnabled, trim.isValid {
            let start = trim.startTimeString
            let end = trim.endTimeString
            arguments.append(contentsOf: ["--download-sections", "*\(start)-\(end)"])
            // Force keyframes for more accurate trims
            arguments.append(contentsOf: ["--force-keyframes-at-cuts"])
        }

        // Destination and filename template
        let template = settings.filenameTemplate.isEmpty ? "%(title)s.%(ext)s" : "\(settings.filenameTemplate).%(ext)s"
        let outputTemplate = settings.destinationFolder.appendingPathComponent(template).path
        arguments.append(contentsOf: ["-o", outputTemplate])

        // Add URL
        arguments.append(url)

        await ActivityLogger.shared.log(
            process: "yt-dlp",
            message: "Starting download: \(url) with mode \(settings.mode.rawValue), format \(settings.mode == .video ? settings.videoFormat.rawValue : settings.audioFormat.rawValue)"
        )

        // Use a class wrapper for thread-safe mutation
        final class PathBox: @unchecked Sendable {
            var value: String?
        }
        let pathBox = PathBox()
        let runner = ProcessRunner()

        let exitCode = try await runner.stream(
            executableURL: ytdlpURL,
            arguments: arguments,
            currentDirectory: settings.destinationFolder
        ) { line in
            // Log to activity logger
            Task { @MainActor in
                ActivityLogger.shared.log(process: "yt-dlp", message: line)
            }

            // Check if line contains printed final file path
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if FileManager.default.fileExists(atPath: trimmed) {
                pathBox.value = trimmed
            }

            // Parse progress
            if let update = ProgressParser.parseYTDLPLine(line) {
                onProgress(update)
            }
        }

        guard exitCode == 0 else {
            await ActivityLogger.shared.log(
                process: "yt-dlp",
                message: "Download failed with exit code \(exitCode)",
                isError: true
            )
            throw ProcessError.executionFailed(exitCode: exitCode, stderr: "Download failed. Check URL or network connection.")
        }

        if let path = pathBox.value, FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        // Fallback: search destination directory for newest file matching target extension
        let ext = (settings.mode == .video ? settings.videoFormat.fileExtension : settings.audioFormat.fileExtension).lowercased()
        if let contents = try? FileManager.default.contentsOfDirectory(at: settings.destinationFolder, includingPropertiesForKeys: [.contentModificationDateKey]) {
            let matches = contents.filter { $0.pathExtension.lowercased() == ext }
                .sorted { (u1, u2) -> Bool in
                    let d1 = (try? u1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    let d2 = (try? u2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    return d1 > d2
                }
            if let newest = matches.first {
                return newest
            }
        }

        return settings.destinationFolder
    }
}
