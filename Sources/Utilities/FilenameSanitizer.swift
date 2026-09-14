import Foundation

public enum FilenameSanitizer {
    /// Characters forbidden in macOS/POSIX and common filenames: : / \ ? * < > | " and control characters
    private static let illegalCharacters = CharacterSet(charactersIn: ":/\\?*<>|\"\0")
        .union(.newlines)
        .union(.controlCharacters)

    /// Sanitizes an input string to be a safe filesystem filename component
    public static func sanitize(_ filename: String) -> String {
        var clean = filename.components(separatedBy: illegalCharacters).joined(separator: "_")
        // Trim dots and spaces from start/end
        clean = clean.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        // Collapse multiple underscores or spaces
        clean = clean.replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
        if clean.isEmpty {
            return "download"
        }
        // Limit length to 200 characters to prevent filesystem error
        if clean.count > 200 {
            clean = String(clean.prefix(200))
        }
        return clean
    }

    /// Evaluates a template string with provided tokens
    public static func applyTemplate(
        template: String,
        title: String,
        channel: String,
        resolution: String,
        ext: String
    ) -> String {
        var result = template
        let safeTitle = sanitize(title)
        let safeChannel = sanitize(channel)
        let safeResolution = sanitize(resolution)

        result = result.replacingOccurrences(of: "%(title)s", with: safeTitle)
        result = result.replacingOccurrences(of: "%(channel)s", with: safeChannel)
        result = result.replacingOccurrences(of: "%(uploader)s", with: safeChannel)
        result = result.replacingOccurrences(of: "%(resolution)s", with: safeResolution)
        result = result.replacingOccurrences(of: "%(ext)s", with: ext)

        var finalName = sanitize(result)
        if !finalName.hasSuffix(".\(ext)") {
            finalName = "\(finalName).\(ext)"
        }
        return finalName
    }

    /// Generates a unique filename in the target directory if collision occurs
    public static func resolveCollision(in folder: URL, desiredFilename: String) -> URL {
        let destination = folder.appendingPathComponent(desiredFilename)
        if !FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }

        let ext = destination.pathExtension
        let baseName = destination.deletingPathExtension().lastPathComponent

        var counter = 2
        while true {
            let candidateName = ext.isEmpty ? "\(baseName) \(counter)" : "\(baseName) \(counter).\(ext)"
            let candidateURL = folder.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
