import Foundation
import SwiftUI

@MainActor
public final class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // General
    @Published public var outputFolderPath: String {
        didSet { defaults.set(outputFolderPath, forKey: "outputFolderPath") }
    }
    @Published public var enableClipboardDetection: Bool {
        didSet { defaults.set(enableClipboardDetection, forKey: "enableClipboardDetection") }
    }
    @Published public var enableNotifications: Bool {
        didSet { defaults.set(enableNotifications, forKey: "enableNotifications") }
    }
    @Published public var keepHistory: Bool {
        didSet { defaults.set(keepHistory, forKey: "keepHistory") }
    }

    // Downloads
    @Published public var maxConcurrentDownloads: Int {
        didSet { defaults.set(maxConcurrentDownloads, forKey: "maxConcurrentDownloads") }
    }
    @Published public var defaultVideoFormat: String {
        didSet { defaults.set(defaultVideoFormat, forKey: "defaultVideoFormat") }
    }
    @Published public var defaultAudioFormat: String {
        didSet { defaults.set(defaultAudioFormat, forKey: "defaultAudioFormat") }
    }
    @Published public var autoRetryFailed: Bool {
        didSet { defaults.set(autoRetryFailed, forKey: "autoRetryFailed") }
    }

    // Conversion
    @Published public var preferRemux: Bool {
        didSet { defaults.set(preferRemux, forKey: "preferRemux") }
    }
    @Published public var hardwareAcceleration: Bool {
        didSet { defaults.set(hardwareAcceleration, forKey: "hardwareAcceleration") }
    }

    // Appearance
    @Published public var appearanceMode: String {
        didSet { defaults.set(appearanceMode, forKey: "appearanceMode") }
    }

    // Advanced
    @Published public var customYTDLPPath: String {
        didSet { defaults.set(customYTDLPPath, forKey: "customYTDLPPath") }
    }
    @Published public var customFFmpegPath: String {
        didSet { defaults.set(customFFmpegPath, forKey: "customFFmpegPath") }
    }

    public init() {
        let defaultDownloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path
            ?? (NSHomeDirectory() + "/Downloads")

        self.outputFolderPath = defaults.string(forKey: "outputFolderPath") ?? defaultDownloads
        self.enableClipboardDetection = defaults.object(forKey: "enableClipboardDetection") != nil ? defaults.bool(forKey: "enableClipboardDetection") : true
        self.enableNotifications = defaults.object(forKey: "enableNotifications") != nil ? defaults.bool(forKey: "enableNotifications") : true
        self.keepHistory = defaults.object(forKey: "keepHistory") != nil ? defaults.bool(forKey: "keepHistory") : true

        self.maxConcurrentDownloads = defaults.integer(forKey: "maxConcurrentDownloads") > 0 ? defaults.integer(forKey: "maxConcurrentDownloads") : 2
        self.defaultVideoFormat = defaults.string(forKey: "defaultVideoFormat") ?? "MP4"
        self.defaultAudioFormat = defaults.string(forKey: "defaultAudioFormat") ?? "MP3"
        self.autoRetryFailed = defaults.object(forKey: "autoRetryFailed") != nil ? defaults.bool(forKey: "autoRetryFailed") : true

        self.preferRemux = defaults.object(forKey: "preferRemux") != nil ? defaults.bool(forKey: "preferRemux") : true
        self.hardwareAcceleration = defaults.object(forKey: "hardwareAcceleration") != nil ? defaults.bool(forKey: "hardwareAcceleration") : true

        self.appearanceMode = defaults.string(forKey: "appearanceMode") ?? "System"

        self.customYTDLPPath = defaults.string(forKey: "customYTDLPPath") ?? ""
        self.customFFmpegPath = defaults.string(forKey: "customFFmpegPath") ?? ""
    }

    public var outputFolderURL: URL {
        URL(fileURLWithPath: outputFolderPath)
    }

    public func resetToDefaults() {
        let defaultDownloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path
            ?? (NSHomeDirectory() + "/Downloads")
        outputFolderPath = defaultDownloads
        enableClipboardDetection = true
        enableNotifications = true
        keepHistory = true
        maxConcurrentDownloads = 2
        defaultVideoFormat = "MP4"
        defaultAudioFormat = "MP3"
        autoRetryFailed = true
        preferRemux = true
        hardwareAcceleration = true
        appearanceMode = "System"
        customYTDLPPath = ""
        customFFmpegPath = ""
    }
}
