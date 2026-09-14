import SwiftUI

public struct FormatSelectorView: View {
    @ObservedObject var viewModel: DownloadViewModel

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(alignment: .top) {
            Text("Format")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                if viewModel.settings.mode == .video {
                    Picker("", selection: $viewModel.settings.videoFormat) {
                        ForEach(VideoOutputFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                } else {
                    Picker("", selection: $viewModel.settings.audioFormat) {
                        ForEach(AudioOutputFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                // Conversion Speed Tag
                HStack(spacing: 4) {
                    Image(systemName: viewModel.settings.isFastRemuxOnly ? "bolt.fill" : "gearshape")
                        .font(.system(size: 10))
                    Text(viewModel.settings.speedIndicatorLabel)
                        .font(.system(size: 11))
                }
                .foregroundColor(viewModel.settings.isFastRemuxOnly ? .green : .secondary)
            }

            Spacer()
        }
    }
}
