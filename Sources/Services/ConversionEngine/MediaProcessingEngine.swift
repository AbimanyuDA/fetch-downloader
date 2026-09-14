import Foundation

public protocol MediaProcessingEngine: Sendable {
    func remux(
        inputURL: URL,
        outputURL: URL,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL

    func trim(
        inputURL: URL,
        outputURL: URL,
        trimRange: TrimRange,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL

    func convert(
        inputURL: URL,
        outputURL: URL,
        settings: OutputSettings,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL

    func extractAudio(
        inputURL: URL,
        outputURL: URL,
        format: AudioOutputFormat,
        bitrateKbps: Int,
        onProgress: @escaping @Sendable (ParsedProgressUpdate) -> Void
    ) async throws -> URL
}
