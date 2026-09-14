import Foundation

public final class FFmpegProcessingEngine: MediaProcessingEngine {
    public init() {}

    private func resolveFFmpeg() async throws -> URL {
        guard let url = await DependencyManager.shared.resolvePath(for: "ffmpeg") else {
            throw ProcessError.binaryNotFound("ffmpeg")
        }
        return url
    }

    /// Fast stream copy remuxing without re-encoding
    public func remux(
        inputURL: URL,
        outputURL: URL,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL {
        let ffmpeg = try await resolveFFmpeg()
        let arguments = [
            "-y",
            "-i", inputURL.path,
            "-c", "copy",
            outputURL.path
        ]

        await ActivityLogger.shared.log(process: "ffmpeg", message: "Starting remux from \(inputURL.lastPathComponent) to \(outputURL.lastPathComponent)")

        let runner = ProcessRunner()
        let exitCode = try await runner.stream(executableURL: ffmpeg, arguments: arguments) { line in
            Task { @MainActor in ActivityLogger.shared.log(process: "ffmpeg", message: line) }
            if let update = ProgressParser.parseFFmpegProgress(line: line, totalDuration: nil) {
                onProgress(update)
            }
        }

        guard exitCode == 0 else {
            throw ProcessError.executionFailed(exitCode: exitCode, stderr: "Remux operation failed.")
        }
        return outputURL
    }

    /// Trims media using stream copy or fallback transcode
    public func trim(
        inputURL: URL,
        outputURL: URL,
        trimRange: TrimRange,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL {
        let ffmpeg = try await resolveFFmpeg()
        guard trimRange.isValid else {
            throw ProcessError.executionFailed(exitCode: 1, stderr: trimRange.validationErrorMessage ?? "Invalid trim range")
        }

        let start = trimRange.startTimeString
        let duration = String(format: "%.3f", trimRange.duration)

        // Try stream copy first for instant trim
        let streamCopyArgs = [
            "-y",
            "-ss", start,
            "-i", inputURL.path,
            "-t", duration,
            "-c", "copy",
            outputURL.path
        ]

        await ActivityLogger.shared.log(process: "ffmpeg", message: "Trimming media: start \(start), duration \(duration)s")

        let runner = ProcessRunner()
        let exitCode = try await runner.stream(executableURL: ffmpeg, arguments: streamCopyArgs) { line in
            Task { @MainActor in ActivityLogger.shared.log(process: "ffmpeg", message: line) }
            if let update = ProgressParser.parseFFmpegProgress(line: line, totalDuration: trimRange.duration) {
                onProgress(update)
            }
        }

        if exitCode == 0 && FileManager.default.fileExists(atPath: outputURL.path) {
            return outputURL
        }

        // Fallback with re-encoding if stream-copy fails due to keyframe boundary
        let fallbackArgs = [
            "-y",
            "-ss", start,
            "-i", inputURL.path,
            "-t", duration,
            "-c:v", "libx264",
            "-c:a", "aac",
            outputURL.path
        ]

        let fallbackCode = try await runner.stream(executableURL: ffmpeg, arguments: fallbackArgs) { line in
            Task { @MainActor in ActivityLogger.shared.log(process: "ffmpeg", message: line) }
            if let update = ProgressParser.parseFFmpegProgress(line: line, totalDuration: trimRange.duration) {
                onProgress(update)
            }
        }

        guard fallbackCode == 0 else {
            throw ProcessError.executionFailed(exitCode: fallbackCode, stderr: "Trimming media failed.")
        }

        return outputURL
    }

    /// Converts video to selected container/codecs with optional VideoToolbox hardware acceleration
    public func convert(
        inputURL: URL,
        outputURL: URL,
        settings: OutputSettings,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL {
        let ffmpeg = try await resolveFFmpeg()
        var arguments = ["-y", "-i", inputURL.path]

        // Video codec selection
        switch settings.videoCodec {
        case .auto:
            // Use hardware accelerated VideoToolbox on macOS if available
            arguments.append(contentsOf: ["-c:v", "h264_videotoolbox", "-b:v", "4000k"])
        case .copy:
            arguments.append(contentsOf: ["-c:v", "copy"])
        case .h264:
            arguments.append(contentsOf: ["-c:v", "h264_videotoolbox", "-b:v", "4000k"])
        case .hevc:
            arguments.append(contentsOf: ["-c:v", "hevc_videotoolbox", "-b:v", "3000k"])
        case .av1:
            arguments.append(contentsOf: ["-c:v", "libsvtav1"])
        case .vp9:
            arguments.append(contentsOf: ["-c:v", "libvpx-vp9"])
        }

        // Audio codec selection
        switch settings.audioCodec {
        case .auto:
            arguments.append(contentsOf: ["-c:a", "aac", "-b:a", "256k"])
        case .copy:
            arguments.append(contentsOf: ["-c:a", "copy"])
        case .aac:
            arguments.append(contentsOf: ["-c:a", "aac", "-b:a", "256k"])
        case .mp3:
            arguments.append(contentsOf: ["-c:a", "libmp3lame", "-b:a", "320k"])
        case .opus:
            arguments.append(contentsOf: ["-c:a", "libopus"])
        case .flac:
            arguments.append(contentsOf: ["-c:a", "flac"])
        }

        // Frame rate
        if settings.frameRate != .original {
            arguments.append(contentsOf: ["-r", settings.frameRate.rawValue])
        }

        arguments.append(outputURL.path)

        await ActivityLogger.shared.log(process: "ffmpeg", message: "Converting media to \(outputURL.lastPathComponent)")

        let runner = ProcessRunner()
        let exitCode = try await runner.stream(executableURL: ffmpeg, arguments: arguments) { line in
            Task { @MainActor in ActivityLogger.shared.log(process: "ffmpeg", message: line) }
            if let update = ProgressParser.parseFFmpegProgress(line: line, totalDuration: nil) {
                onProgress(update)
            }
        }

        guard exitCode == 0 else {
            throw ProcessError.executionFailed(exitCode: exitCode, stderr: "Media conversion failed.")
        }
        return outputURL
    }

    /// Extracts and transcodes audio to the desired audio container and bitrate
    public func extractAudio(
        inputURL: URL,
        outputURL: URL,
        format: AudioOutputFormat,
        bitrateKbps: Int,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL {
        let ffmpeg = try await resolveFFmpeg()
        var arguments = ["-y", "-i", inputURL.path, "-vn"]

        switch format {
        case .mp3:
            arguments.append(contentsOf: ["-c:a", "libmp3lame", "-b:a", "\(bitrateKbps > 0 ? bitrateKbps : 320)k"])
        case .m4a, .aac:
            arguments.append(contentsOf: ["-c:a", "aac", "-b:a", "\(bitrateKbps > 0 ? bitrateKbps : 256)k"])
        case .wav:
            arguments.append(contentsOf: ["-c:a", "pcm_s16le"])
        case .flac:
            arguments.append(contentsOf: ["-c:a", "flac"])
        case .ogg:
            arguments.append(contentsOf: ["-c:a", "libvorbis", "-b:a", "\(bitrateKbps > 0 ? bitrateKbps : 192)k"])
        }

        arguments.append(outputURL.path)

        await ActivityLogger.shared.log(process: "ffmpeg", message: "Extracting audio to \(outputURL.lastPathComponent)")

        let runner = ProcessRunner()
        let exitCode = try await runner.stream(executableURL: ffmpeg, arguments: arguments) { line in
            Task { @MainActor in ActivityLogger.shared.log(process: "ffmpeg", message: line) }
            if let update = ProgressParser.parseFFmpegProgress(line: line, totalDuration: nil) {
                onProgress(update)
            }
        }

        guard exitCode == 0 else {
            throw ProcessError.executionFailed(exitCode: exitCode, stderr: "Audio extraction failed.")
        }
        return outputURL
    }
}
