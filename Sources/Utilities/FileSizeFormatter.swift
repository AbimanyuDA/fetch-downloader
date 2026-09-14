import Foundation

public enum FileSizeFormatter {
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter
    }()

    public static func format(bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        return byteCountFormatter.string(fromByteCount: bytes)
    }

    public static func formatSpeed(bytesPerSecond: Double) -> String {
        guard bytesPerSecond > 0 && !bytesPerSecond.isNaN && !bytesPerSecond.isInfinite else {
            return "0 KB/s"
        }
        let formatted = byteCountFormatter.string(fromByteCount: Int64(bytesPerSecond))
        return "\(formatted)/s"
    }

    public static func formatEstimated(bytes: Int64?) -> String {
        guard let bytes = bytes, bytes > 0 else {
            return "Approx. Unknown"
        }
        return "Approx. \(format(bytes: bytes))"
    }
}
