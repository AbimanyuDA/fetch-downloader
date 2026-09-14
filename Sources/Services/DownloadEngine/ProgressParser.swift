import Foundation

public struct ParsedProgressUpdate: Sendable, Equatable {
    public let percentage: Double?
    public let downloadedBytes: Int64?
    public let totalBytes: Int64?
    public let speedBytesPerSecond: Double?
    public let etaSeconds: Int?
    public let phase: DownloadStatus?
    public let rawMessage: String

    public init(
        percentage: Double? = nil,
        downloadedBytes: Int64? = nil,
        totalBytes: Int64? = nil,
        speedBytesPerSecond: Double? = nil,
        etaSeconds: Int? = nil,
        phase: DownloadStatus? = nil,
        rawMessage: String = ""
    ) {
        self.percentage = percentage
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
        self.speedBytesPerSecond = speedBytesPerSecond
        self.etaSeconds = etaSeconds
        self.phase = phase
        self.rawMessage = rawMessage
    }
}

public enum ProgressParser {
    // Matches standard yt-dlp: [download] 45.2% of ~ 125.40MiB at 8.32MiB/s ETA 00:08
    private static let ytdlpProgressRegex = try? NSRegularExpression(
        pattern: #"\[download\]\s+([0-9\.]+)%\s+of\s+(?:~?\s*)?([0-9\.]+)\s*([A-Za-z]+)(?:\s+at\s+([0-9\.]+)\s*([A-Za-z/]+))?(?:\s+ETA\s+([0-9:]+))?"#,
        options: []
    )

    // Completed download line: [download] 100% of 12.34MiB in 00:01
    private static let ytdlpFinishedRegex = try? NSRegularExpression(
        pattern: #"\[download\]\s+100(?:\.0+)?%\s+of\s+([0-9\.]+)\s*([A-Za-z]+)"#,
        options: []
    )

    // Matches FFmpeg time (used when yt-dlp runs --download-sections): time=00:01:23.45
    private static let ffmpegTimeRegex = try? NSRegularExpression(
        pattern: #"time=([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+)"#,
        options: []
    )

    // Matches FFmpeg size: size= 2560KiB
    private static let ffmpegSizeRegex = try? NSRegularExpression(
        pattern: #"size=\s*([0-9\.]+)\s*([A-Za-z]+)"#,
        options: []
    )

    public static func parseYTDLPLine(_ line: String, trimDuration: Double? = nil) -> ParsedProgressUpdate? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.contains("[Merger]") || trimmed.contains("Merging formats") {
            return ParsedProgressUpdate(
                percentage: 98.0,
                phase: .merging,
                rawMessage: "Merging video and audio streams"
            )
        }

        if trimmed.contains("[ExtractAudio]") || (trimmed.contains("Destination:") && trimmed.hasSuffix(".mp3")) {
            return ParsedProgressUpdate(
                percentage: 95.0,
                phase: .converting,
                rawMessage: "Extracting audio track to MP3"
            )
        }

        if trimmed.contains("Downloading 1 time ranges") || trimmed.contains("Downloading visionos") || trimmed.contains("Downloading android") {
            return ParsedProgressUpdate(
                percentage: 5.0,
                phase: .fetching,
                rawMessage: "Connecting and slicing stream..."
            )
        }

        let nsString = trimmed as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        // 1. Standard yt-dlp progress line
        if let match = ytdlpProgressRegex?.firstMatch(in: trimmed, options: [], range: fullRange) {
            let percentStr = nsString.substring(with: match.range(at: 1))
            let totalSizeStr = nsString.substring(with: match.range(at: 2))
            let totalUnitStr = nsString.substring(with: match.range(at: 3))

            let percent = Double(percentStr)
            let totalBytes = parseBytes(val: totalSizeStr, unit: totalUnitStr)
            let downloadedBytes: Int64? = {
                if let p = percent, let tot = totalBytes {
                    return Int64(Double(tot) * (p / 100.0))
                }
                return nil
            }()

            var speedBytes: Double? = nil
            if match.numberOfRanges > 5 && match.range(at: 4).location != NSNotFound && match.range(at: 5).location != NSNotFound {
                let speedValStr = nsString.substring(with: match.range(at: 4))
                let speedUnitStr = nsString.substring(with: match.range(at: 5))
                speedBytes = parseSpeed(val: speedValStr, unit: speedUnitStr)
            }

            var etaSecs: Int? = nil
            if match.numberOfRanges > 6 && match.range(at: 6).location != NSNotFound {
                let etaStr = nsString.substring(with: match.range(at: 6))
                etaSecs = parseETAToSeconds(etaStr)
            }

            return ParsedProgressUpdate(
                percentage: percent,
                downloadedBytes: downloadedBytes,
                totalBytes: totalBytes,
                speedBytesPerSecond: speedBytes,
                etaSeconds: etaSecs,
                phase: .downloading,
                rawMessage: trimmed
            )
        }

        // 2. yt-dlp section-downloading via ffmpeg output (frame=... time=00:01:23)
        if let match = ffmpegTimeRegex?.firstMatch(in: trimmed, options: [], range: fullRange) {
            let timeStr = nsString.substring(with: match.range(at: 1))
            if let currentSeconds = TimeFormatter.parse(string: timeStr) {
                var percent: Double? = nil
                if let targetDuration = trimDuration, targetDuration > 0 {
                    percent = min(99.0, (currentSeconds / targetDuration) * 100.0)
                }

                var sizeBytes: Int64? = nil
                if let sizeMatch = ffmpegSizeRegex?.firstMatch(in: trimmed, options: [], range: fullRange) {
                    let sVal = nsString.substring(with: sizeMatch.range(at: 1))
                    let sUnit = nsString.substring(with: sizeMatch.range(at: 2))
                    sizeBytes = parseBytes(val: sVal, unit: sUnit)
                }

                return ParsedProgressUpdate(
                    percentage: percent ?? 50.0,
                    downloadedBytes: sizeBytes,
                    totalBytes: nil,
                    speedBytesPerSecond: nil,
                    etaSeconds: nil,
                    phase: .downloading,
                    rawMessage: "Slicing media: \(TimeFormatter.format(seconds: currentSeconds))"
                )
            }
        }

        // 3. Finished download line
        if let match = ytdlpFinishedRegex?.firstMatch(in: trimmed, options: [], range: fullRange) {
            let totalSizeStr = nsString.substring(with: match.range(at: 1))
            let totalUnitStr = nsString.substring(with: match.range(at: 2))
            let totalBytes = parseBytes(val: totalSizeStr, unit: totalUnitStr)

            return ParsedProgressUpdate(
                percentage: 100.0,
                downloadedBytes: totalBytes,
                totalBytes: totalBytes,
                speedBytesPerSecond: 0,
                etaSeconds: 0,
                phase: .downloading,
                rawMessage: trimmed
            )
        }

        return nil
    }

    public static func parseFFmpegProgress(line: String, totalDuration: Double?) -> ParsedProgressUpdate? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let nsString = trimmed as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        if let match = ffmpegTimeRegex?.firstMatch(in: trimmed, options: [], range: fullRange) {
            let timeStr = nsString.substring(with: match.range(at: 1))
            if let currentSeconds = TimeFormatter.parse(string: timeStr) {
                var percent: Double? = nil
                if let total = totalDuration, total > 0 {
                    percent = min(99.0, (currentSeconds / total) * 100.0)
                }
                return ParsedProgressUpdate(
                    percentage: percent,
                    phase: .converting,
                    rawMessage: "Processing: \(TimeFormatter.format(seconds: currentSeconds))"
                )
            }
        }
        return nil
    }

    private static func parseBytes(val: String, unit: String) -> Int64? {
        guard let num = Double(val) else { return nil }
        let u = unit.lowercased()
        if u.contains("gib") || u.contains("gb") {
            return Int64(num * 1024 * 1024 * 1024)
        } else if u.contains("mib") || u.contains("mb") {
            return Int64(num * 1024 * 1024)
        } else if u.contains("kib") || u.contains("kb") {
            return Int64(num * 1024)
        } else {
            return Int64(num)
        }
    }

    private static func parseSpeed(val: String, unit: String) -> Double? {
        guard let num = Double(val) else { return nil }
        let u = unit.lowercased()
        if u.contains("gib") || u.contains("gb") {
            return num * 1024 * 1024 * 1024
        } else if u.contains("mib") || u.contains("mb") {
            return num * 1024 * 1024
        } else if u.contains("kib") || u.contains("kb") {
            return num * 1024
        } else {
            return num
        }
    }

    private static func parseETAToSeconds(_ etaStr: String) -> Int? {
        let parts = etaStr.split(separator: ":").map { String($0) }
        if parts.count == 3, let h = Int(parts[0]), let m = Int(parts[1]), let s = Int(parts[2]) {
            return (h * 3600) + (m * 60) + s
        } else if parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]) {
            return (m * 60) + s
        } else if parts.count == 1, let s = Int(parts[0]) {
            return s
        }
        return nil
    }
}
