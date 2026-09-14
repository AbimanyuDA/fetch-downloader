import Foundation
import AppKit

@MainActor
public final class ClipboardMonitor: ObservableObject {
    public static let shared = ClipboardMonitor()

    @Published public private(set) var detectedURL: String?
    @Published public var isEnabled: Bool = true

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastProcessedString: String?

    public init() {
        startMonitoring()
    }

    public func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    public func dismiss() {
        detectedURL = nil
    }

    private func checkPasteboard() {
        guard isEnabled else { return }
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let string = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty else { return }

        if string != lastProcessedString && URLValidator.isValidMediaURL(string) {
            lastProcessedString = string
            self.detectedURL = string
        }
    }
}
