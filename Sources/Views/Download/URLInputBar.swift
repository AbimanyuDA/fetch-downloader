import SwiftUI

public struct URLInputBar: View {
    @ObservedObject var viewModel: DownloadViewModel
    @ObservedObject var clipboardMonitor = ClipboardMonitor.shared

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Clipboard Banner if detected
            if let detected = clipboardMonitor.detectedURL, detected != viewModel.inputURL {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                    Text("Media URL detected in clipboard")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                    Spacer()
                    Button("Paste URL") {
                        viewModel.inputURL = detected
                        clipboardMonitor.dismiss()
                        viewModel.fetchMedia()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        clipboardMonitor.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }

            // URL input box
            HStack(spacing: 8) {
                Image(systemName: viewModel.isURLValid ? viewModel.detectedPlatform.iconName : "link")
                    .foregroundColor(viewModel.isURLValid ? .accentColor : .secondary)
                    .font(.system(size: 14))
                    .frame(width: 20)

                TextField("Paste YouTube video, shorts, or playlist URL here...", text: $viewModel.inputURL)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit {
                        viewModel.fetchMedia()
                    }

                if !viewModel.inputURL.isEmpty {
                    Button {
                        viewModel.clearURL()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help("Clear URL (Cmd+K)")
                }

                Button {
                    viewModel.pasteFromClipboard()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Paste from Clipboard (Cmd+V)")

                Button {
                    viewModel.fetchMedia()
                } label: {
                    if viewModel.isFetching {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 48)
                    } else {
                        Text("Fetch")
                            .fontWeight(.medium)
                            .frame(width: 48)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(viewModel.inputURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isFetching)
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Fetch Media Information (Cmd+Return)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            // Platform and batch indicator
            HStack {
                if viewModel.isURLValid {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text(viewModel.detectedPlatform.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    viewModel.showBatchSheet = true
                } label: {
                    Label("Add Multiple URLs...", systemImage: "text.badge.plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
    }
}
