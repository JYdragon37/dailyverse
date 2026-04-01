import UIKit
import UserNotifications

/// UNUserNotificationCenterDelegate 구현체
/// AppDelegate에서 `UNUserNotificationCenter.current().delegate = NotificationDelegate.shared` 으로 등록
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // MARK: - Foreground (Edge Case 8)
    /// 포그라운드 상태에서 알람 발동 — 배너 없이 Stage 1 오버레이 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        NotificationCenter.default.post(
            name: .dvAlarmTriggered,
            object: nil,
            userInfo: userInfo as? [String: Any]
        )
        // Edge Case 8: 포그라운드에서는 배너 표시 안 함 — Stage 1이 직접 오버레이
        completionHandler([])
    }

    // MARK: - Background / Locked Screen Tap
    /// 잠금화면 배너 탭 → 앱 진입 후 Stage 1 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: .dvAlarmTriggered,
            object: nil,
            userInfo: userInfo as? [String: Any]
        )
        completionHandler()
    }
}
