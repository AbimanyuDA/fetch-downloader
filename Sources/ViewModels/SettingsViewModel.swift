import Foundation
import AppKit

@MainActor
public final class SettingsViewModel: ObservableObject {
    public let settingsManager = SettingsManager.shared
    public let dependencyManager = DependencyManager.shared

    @Published public var showResetConfirmation: Bool = false

    public func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Default Folder"

        if panel.runModal() == .OK, let url = panel.url {
            settingsManager.outputFolderPath = url.path
        }
    }

    public func checkDependencies() {
        Task {
            await dependencyManager.checkDependencies()
        }
    }

    public func updateYTDLP() {
        Task {
            try? await dependencyManager.installOrUpdateYTDLP()
        }
    }

    public func resetToDefaults() {
        settingsManager.resetToDefaults()
    }
}
