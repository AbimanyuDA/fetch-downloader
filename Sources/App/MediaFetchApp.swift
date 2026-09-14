import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct MediaFetchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var clipboardMonitor = ClipboardMonitor.shared

    var body: some Scene {
        WindowGroup("MediaFetch") {
            MainView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            SidebarCommands()

            CommandGroup(replacing: .newItem) {}

            CommandMenu("Media") {
                Button("Download") {
                    // Keyboard shortcut trigger
                }
                .keyboardShortcut("d", modifiers: [.command])

                Button("Fetch Media") {
                    // Keyboard shortcut trigger
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .padding(20)
        }
        #endif
    }
}
