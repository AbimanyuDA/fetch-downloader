import Foundation

public enum TimeFormatter {
    /// Formats seconds into HH:MM:SS or MM:SS
    public static func format(seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else {
            return "00:00"
        }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// Parses string in HH:MM:SS, MM:SS, or raw seconds to Double
    public static func parse(string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // If it is just a pure number
        if let directSeconds = Double(trimmed) {
            return directSeconds >= 0 ? directSeconds : nil
        }

        let parts = trimmed.split(separator: ":").map { String($0) }
        guard (1...3).contains(parts.count) else { return nil }

        var total: Double = 0
        if parts.count == 3 {
            guard let h = Double(parts[0]), let m = Double(parts[1]), let s = Double(parts[2]) else { return nil }
            if h < 0 || m < 0 || m >= 60 || s < 0 || s >= 60 { return nil }
            total = (h * 3600) + (m * 60) + s
        } else if parts.count == 2 {
            guard let m = Double(parts[0]), let s = Double(parts[1]) else { return nil }
            if m < 0 || s < 0 || s >= 60 { return nil }
            total = (m * 60) + s
        } else if parts.count == 1 {
            guard let s = Double(parts[0]), s >= 0 else { return nil }
            total = s
        }

        return total
    }

    /// Formats an ETA in seconds to a human friendly format like 01:23
    public static func formatETA(seconds: Int) -> String {
        guard seconds >= 0 else { return "--:--" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
