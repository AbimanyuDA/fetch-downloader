import SwiftUI

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var dependencyManager = DependencyManager.shared

    public init() {}

    public var body: some View {
        TabView {
            // General Tab
            Form {
                Section("Output Destination") {
                    HStack {
                        Text(settingsManager.outputFolderPath)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button("Choose Folder...") {
                            viewModel.chooseOutputFolder()
                        }
                    }
                }

                Section("App Behavior") {
                    Toggle("Enable clipboard URL detection", isOn: $settingsManager.enableClipboardDetection)
                    Toggle("Show notification when download finishes", isOn: $settingsManager.enableNotifications)
                    Toggle("Keep download history locally", isOn: $settingsManager.keepHistory)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            // Downloads Tab
            Form {
                Section("Concurrency") {
                    Picker("Maximum concurrent downloads", selection: $settingsManager.maxConcurrentDownloads) {
                        Text("1").tag(1)
                        Text("2 (Default)").tag(2)
                        Text("3").tag(3)
                        Text("4").tag(4)
                    }
                    .frame(width: 260)
                }

                Section("Defaults") {
                    Picker("Default video format", selection: $settingsManager.defaultVideoFormat) {
                        Text("MP4").tag("MP4")
                        Text("MOV").tag("MOV")
                        Text("MKV").tag("MKV")
                        Text("WebM").tag("WebM")
                    }
                    .frame(width: 260)

                    Picker("Default audio format", selection: $settingsManager.defaultAudioFormat) {
                        Text("MP3").tag("MP3")
                        Text("M4A").tag("M4A")
                        Text("AAC").tag("AAC")
                        Text("WAV").tag("WAV")
                        Text("FLAC").tag("FLAC")
                    }
                    .frame(width: 260)

                    Toggle("Automatically retry interrupted downloads (up to 3 times)", isOn: $settingsManager.autoRetryFailed)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Downloads", systemImage: "arrow.down.circle")
            }

            // Conversion Tab
            Form {
                Section("Engine Strategy") {
                    Toggle("Prefer fast stream-copy remux over transcode", isOn: $settingsManager.preferRemux)
                    Text("Remuxing changes container format instantly without re-encoding video frames.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Toggle("Enable VideoToolbox hardware acceleration", isOn: $settingsManager.hardwareAcceleration)
                    Text("Accelerates H.264 and HEVC encoding using Apple Silicon media engine.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Conversion", systemImage: "slider.horizontal.3")
            }

            // Advanced Tab
            Form {
                Section("Components") {
                    VStack(spacing: 8) {
                        DependencyStatusCard(
                            status: dependencyManager.ytdlpStatus,
                            onUpdate: { viewModel.updateYTDLP() },
                            isUpdating: dependencyManager.isUpdatingYTDLP
                        )

                        DependencyStatusCard(status: dependencyManager.ffmpegStatus)
                        DependencyStatusCard(status: dependencyManager.ffprobeStatus)
                    }

                    HStack {
                        Button("Re-check Components") {
                            viewModel.checkDependencies()
                        }

                        Spacer()

                        Button("Reset All Settings to Defaults") {
                            viewModel.showResetConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Advanced", systemImage: "wrench.and.screwdriver")
            }

            // About & Privacy Tab
            Form {
                Section("About MediaFetch") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MediaFetch for macOS")
                            .font(.system(size: 14, weight: .bold))
                        Text("Version 1.0.0 (Native Apple Silicon & Intel)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Section("Privacy First") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MediaFetch is completely local and privacy respecting.")
                            .font(.system(size: 12, weight: .medium))
                        Text("• No analytics or user tracking\n• No telemetry\n• No external server uploads\n• All media downloads and transcodes occur entirely on your Mac")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Section("Notice") {
                    Text("Only download media you own or have permission to save. Availability and permitted use may depend on the source platform and content rights.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(minWidth: 540, minHeight: 400)
        .confirmationDialog(
            "Reset Settings?",
            isPresented: $viewModel.showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to Defaults", role: .destructive) {
                viewModel.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore default preferences for download formats, folders, and concurrency.")
        }
    }
}
