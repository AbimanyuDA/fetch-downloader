import Foundation

public protocol MediaDownloadEngine: Sendable {
    func download(
        url: String,
        settings: OutputSettings,
        trimRange: TrimRange?,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL
}
