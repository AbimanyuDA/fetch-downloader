import SwiftUI

public struct OutputSettingsView: View {
    @ObservedObject var viewModel: DownloadViewModel
    @State private var isAdvancedExpanded: Bool = false

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Destination Folder
            HStack {
                Text("Save to")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                Text(viewModel.settings.destinationFolder.path)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)

                Button("Choose Folder...") {
                    viewModel.chooseDestinationFolder()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }

            // Filename Template
            HStack {
                Text("Filename")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $viewModel.settings.filenameTemplate) {
                    Text("Title").tag("%(title)s")
                    Text("Title - Channel").tag("%(title)s - %(channel)s")
                    Text("Title - Resolution").tag("%(title)s - %(resolution)s")
                    Text("Channel - Title").tag("%(channel)s - %(title)s")
                }
                .labelsHidden()
                .frame(width: 200)

                Spacer()
            }

            // Subtitles, Thumbnail, Metadata Toggles
            HStack(spacing: 20) {
                Toggle("Embed Metadata", isOn: $viewModel.settings.embedMetadata)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))

                Toggle("Embed Thumbnail", isOn: $viewModel.settings.embedThumbnail)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))

                if viewModel.settings.mode == .video {
                    Toggle("Subtitles", isOn: $viewModel.settings.downloadSubtitles)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 12))
                }
            }

            // Advanced Settings Accordion
            DisclosureGroup(isExpanded: $isAdvancedExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.settings.mode == .video {
                        HStack {
                            Text("Video Codec")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 90, alignment: .leading)
                            Picker("", selection: $viewModel.settings.videoCodec) {
                                ForEach(VideoCodecOption.allCases) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 140)

                            Text("Frame Rate")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                            Picker("", selection: $viewModel.settings.frameRate) {
                                ForEach(FrameRateOption.allCases) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }
                    }

                    HStack {
                        Text("Audio Codec")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 90, alignment: .leading)
                        Picker("", selection: $viewModel.settings.audioCodec) {
                            ForEach(AudioCodecOption.allCases) { a in
                                Text(a.rawValue).tag(a)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)

                        Text("Strategy")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                        Picker("", selection: $viewModel.settings.qualityStrategy) {
                            ForEach(QualityStrategy.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 130)
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("Advanced Settings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
