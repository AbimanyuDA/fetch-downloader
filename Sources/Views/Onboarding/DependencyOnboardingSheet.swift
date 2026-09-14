import SwiftUI
import AppKit

public struct DependencyOnboardingSheet: View {
    @ObservedObject var dependencyManager = DependencyManager.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle.badge.gearshape")
                .font(.system(size: 44))
                .foregroundColor(.accentColor)

            VStack(spacing: 6) {
                Text("Required Components")
                    .font(.system(size: 18, weight: .bold))
                Text("MediaFetch requires yt-dlp and FFmpeg to extract media and process output formats.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                DependencyStatusCard(
                    status: dependencyManager.ytdlpStatus,
                    onUpdate: {
                        Task { try? await dependencyManager.installOrUpdateYTDLP() }
                    },
                    isUpdating: dependencyManager.isUpdatingYTDLP
                )

                DependencyStatusCard(status: dependencyManager.ffmpegStatus)
            }
            .frame(maxWidth: 460)

            if !dependencyManager.ffmpegStatus.isAvailable {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("FFmpeg can be installed via Homebrew (brew install ffmpeg) or placed in ~/Library/Application Support/MediaFetch/bin/.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: 460)
            }

            HStack {
                Button("Check Again") {
                    Task { await dependencyManager.checkDependencies() }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Continue") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: 460)
        }
        .padding(28)
        .frame(width: 520)
    }
}
