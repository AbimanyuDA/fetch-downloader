import Foundation

public struct DependencyStatus: Sendable {
    public let name: String
    public let isAvailable: Bool
    public let path: String?
    public let version: String?
}

@MainActor
public final class DependencyManager: ObservableObject {
    public static let shared = DependencyManager()

    @Published public private(set) var ytdlpStatus: DependencyStatus
    @Published public private(set) var ffmpegStatus: DependencyStatus
    @Published public private(set) var ffprobeStatus: DependencyStatus
    @Published public private(set) var isChecking: Bool = false
    @Published public private(set) var isUpdatingYTDLP: Bool = false
    @Published public private(set) var updateMessage: String?

    public var isFullyReady: Bool {
        ytdlpStatus.isAvailable && ffmpegStatus.isAvailable
    }

    private let fileManager = FileManager.default

    public init() {
        self.ytdlpStatus = DependencyStatus(name: "yt-dlp", isAvailable: false, path: nil, version: nil)
        self.ffmpegStatus = DependencyStatus(name: "ffmpeg", isAvailable: false, path: nil, version: nil)
        self.ffprobeStatus = DependencyStatus(name: "ffprobe", isAvailable: false, path: nil, version: nil)
        Task {
            await checkDependencies()
        }
    }

    /// Application Support bin directory where user or in-app updater can install binaries
    public var appSupportBinDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("MediaFetch/bin", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Finds the executable path for a given binary name
    public func resolvePath(for binary: String, customOverride: String? = nil) -> URL? {
        // 1. User custom override if set
        if let custom = customOverride, !custom.isEmpty {
            let url = URL(fileURLWithPath: custom)
            if fileManager.isExecutableFile(atPath: url.path) {
                return url
            }
        }

        // 2. Application Support managed directory
        let managed = appSupportBinDirectory.appendingPathComponent(binary)
        if fileManager.isExecutableFile(atPath: managed.path) {
            return managed
        }

        // 3. Application bundle Resources/bin/ if bundled
        if let bundlePath = Bundle.main.path(forResource: binary, ofType: nil, inDirectory: "bin") {
            if fileManager.isExecutableFile(atPath: bundlePath) {
                return URL(fileURLWithPath: bundlePath)
            }
        }

        // 4. Standard system and Homebrew locations
        let standardPaths = [
            "/opt/homebrew/bin/\(binary)",
            "/usr/local/bin/\(binary)",
            "/usr/bin/\(binary)",
            "/bin/\(binary)"
        ]

        for p in standardPaths {
            if fileManager.isExecutableFile(atPath: p) {
                return URL(fileURLWithPath: p)
            }
        }

        // 5. Look in PATH via 'which'
        if let whichPath = findInPath(binary: binary) {
            return URL(fileURLWithPath: whichPath)
        }

        return nil
    }

    private func findInPath(binary: String) -> String? {
        let env = ProcessInfo.processInfo.environment["PATH"] ?? "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        for dir in env.components(separatedBy: ":") {
            let candidate = (dir as NSString).appendingPathComponent(binary)
            if fileManager.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    /// Checks the presence and versions of all required binaries
    public func checkDependencies() async {
        isChecking = true
        defer { isChecking = false }

        let ytdlpURL = resolvePath(for: "yt-dlp")
        let ffmpegURL = resolvePath(for: "ffmpeg")
        let ffprobeURL = resolvePath(for: "ffprobe")

        let ytdlpVer = await fetchVersion(for: ytdlpURL, argument: "--version")
        let ffmpegVer = await fetchVersion(for: ffmpegURL, argument: "-version")
        let ffprobeVer = await fetchVersion(for: ffprobeURL, argument: "-version")

        self.ytdlpStatus = DependencyStatus(
            name: "yt-dlp",
            isAvailable: ytdlpURL != nil,
            path: ytdlpURL?.path,
            version: ytdlpVer
        )
        self.ffmpegStatus = DependencyStatus(
            name: "ffmpeg",
            isAvailable: ffmpegURL != nil,
            path: ffmpegURL?.path,
            version: cleanFFmpegVersion(ffmpegVer)
        )
        self.ffprobeStatus = DependencyStatus(
            name: "ffprobe",
            isAvailable: ffprobeURL != nil,
            path: ffprobeURL?.path,
            version: cleanFFmpegVersion(ffprobeVer)
        )
    }

    private func fetchVersion(for binaryURL: URL?, argument: String) async -> String? {
        guard let binaryURL = binaryURL else { return nil }
        let runner = ProcessRunner()
        do {
            let result = try await runner.run(executableURL: binaryURL, arguments: [argument])
            let firstLine = result.stdout.components(separatedBy: .newlines).first ?? ""
            return firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private func cleanFFmpegVersion(_ raw: String?) -> String? {
        guard let raw = raw else { return nil }
        // Extracts e.g. "ffmpeg version 7.0" -> "7.0"
        let parts = raw.components(separatedBy: " ")
        if parts.count >= 3 && parts[0].lowercased().contains("ffmpeg") || parts[0].lowercased().contains("ffprobe") {
            return parts[2]
        }
        return raw
    }

    /// Downloads the official standalone yt-dlp universal macOS binary directly into Application Support
    public func installOrUpdateYTDLP() async throws {
        isUpdatingYTDLP = true
        updateMessage = "Checking latest release..."
        defer {
            isUpdatingYTDLP = false
        }

        let downloadURL = URL(string: "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos")!
        updateMessage = "Downloading official yt-dlp binary..."

        let (data, response) = try await URLSession.shared.data(from: downloadURL)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ProcessError.executionFailed(exitCode: 1, stderr: "Failed to download yt-dlp binary.")
        }

        let targetFile = appSupportBinDirectory.appendingPathComponent("yt-dlp")
        try data.write(to: targetFile, options: .atomic)

        // Set executable permission (chmod +x)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: targetFile.path)

        updateMessage = "yt-dlp updated successfully."
        await checkDependencies()
    }
}
