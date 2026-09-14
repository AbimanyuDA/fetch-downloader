import Foundation
import UserNotifications

public final class NotificationService: Sendable {
    public static let shared = NotificationService()

    private init() {
        requestAuthorization()
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func sendDownloadCompletedNotification(filename: String) {
        let content = UNMutableNotificationContent()
        content.title = "Download Completed"
        content.body = filename
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    public func sendDownloadFailedNotification(title: String, error: String) {
        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = "\(title): \(error)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
