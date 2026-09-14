import SwiftUI

public struct QualitySelectorView: View {
    @ObservedObject var viewModel: DownloadViewModel

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mode Segmented Control
            HStack {
                Text("Mode")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $viewModel.settings.mode) {
                    ForEach(DownloadMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Spacer()
            }

            // Quality Selection
            HStack(alignment: .top) {
                Text(viewModel.settings.mode == .video ? "Resolution" : "Bitrate")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                    .padding(.top, 4)

                if viewModel.settings.mode == .video {
                    Picker("", selection: $viewModel.settings.selectedVideoQuality) {
                        ForEach(viewModel.availableQualityOptions, id: \.self) { option in
                            Text(option.displayTitle).tag(option)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                } else {
                    Picker("", selection: $viewModel.settings.selectedAudioQuality) {
                        ForEach(AudioQualityOption.allCases) { option in
                            Text(option.displayTitle).tag(option)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }

                Text(viewModel.estimatedFileSizeString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .padding(.leading, 8)

                Spacer()
            }
        }
    }
}
