import SwiftUI

public struct DownloadView: View {
    @StateObject private var viewModel = DownloadViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // URL input bar
                URLInputBar(viewModel: viewModel)

                // Error message if any
                if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }

                        if let tech = viewModel.technicalError {
                            DisclosureGroup("Technical Details") {
                                Text(tech)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(6)
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(8)
                }

                // Media card and options or Empty State
                if let info = viewModel.mediaInfo {
                    VStack(alignment: .leading, spacing: 20) {
                        MediaInfoCard(
                            mediaInfo: info,
                            estimatedSizeString: viewModel.estimatedFileSizeString
                        )

                        Divider()

                        QualitySelectorView(viewModel: viewModel)

                        Divider()

                        FormatSelectorView(viewModel: viewModel)

                        Divider()

                        TrimRangeView(
                            trimRange: $viewModel.trimRange,
                            totalDuration: info.duration
                        )

                        Divider()

                        OutputSettingsView(viewModel: viewModel)

                        Divider()

                        // Action Bar
                        HStack {
                            Spacer()

                            Menu {
                                Button("Download (Default)") {
                                    viewModel.startDownload()
                                }
                                Button("Best Video") {
                                    viewModel.settings.mode = .video
                                    viewModel.settings.selectedVideoQuality = .best
                                    viewModel.startDownload()
                                }
                                Button("Audio Only (MP3)") {
                                    viewModel.settings.mode = .audio
                                    viewModel.settings.audioFormat = .mp3
                                    viewModel.startDownload()
                                }
                            } label: {
                                Label("Download", systemImage: "arrow.down.circle.fill")
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 120)
                            } primaryAction: {
                                viewModel.startDownload()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .keyboardShortcut("d", modifiers: [.command])
                        }
                    }
                } else if !viewModel.isFetching {
                    // Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 38))
                            .foregroundColor(.secondary)

                        Text("Drop or paste a media link")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Paste a URL to inspect available formats and download options.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        Button("Paste URL") {
                            viewModel.pasteFromClipboard()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $viewModel.showPlaylistSheet) {
            PlaylistItemsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showBatchSheet) {
            BatchURLsSheet(viewModel: viewModel)
        }
    }
}

private struct BatchURLsSheet: View {
    @ObservedObject var viewModel: DownloadViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Multiple URLs")
                .font(.system(size: 15, weight: .semibold))

            Text("Enter one video or audio link per line:")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            TextEditor(text: $viewModel.batchInputText)
                .font(.system(size: 12, design: .monospaced))
                .frame(height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Add to Queue") {
                    viewModel.submitBatchURLs()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.batchInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480)
    }
}
