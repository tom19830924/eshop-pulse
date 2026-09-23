import Foundation
import UserNotifications

enum FavoriteSaleNotificationService {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func scheduleNewSaleNotification(for gameTitles: [String]) async {
        guard !gameTitles.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if gameTitles.count == 1, let title = gameTitles.first {
            content.title = "最愛遊戲有新特價"
            content.body = "《\(title)》現在有特價了。"
        } else {
            let titles = gameTitles.prefix(3).map { "《\($0)》" }
            let remainingCount = gameTitles.count - titles.count
            let additionalText = remainingCount > 0 ? "等 \(remainingCount) 款遊戲" : ""
            content.title = "\(gameTitles.count) 款最愛遊戲有新特價"
            content.body = ([titles.joined(separator: "、"), additionalText]
                .filter { !$0.isEmpty })
                .joined(separator: "、")
        }

        let request = UNNotificationRequest(
            identifier: "favorite-sale-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            // Notification scheduling failures do not fail the catalog refresh itself.
        }
    }
}
