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
        // [AnyHashable: Any]를 직접 전달 — as? [String: Any] 캐스트는 NSString 키 때문에 nil 반환하여 Stage 1이 뜨지 않는 버그 수정
        NotificationCenter.default.post(
            name: .dvAlarmTriggered,
            object: nil,
            userInfo: userInfo as [AnyHashable: Any]
        )
        // alertStyle에 따라 소리/진동 처리
        let alertStyle = notification.request.content.userInfo["alert_style"] as? String ?? "soundAndVibration"
        switch alertStyle {
        case "vibration":
            // 진동만: 시스템 배너 없이 햅틱만
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            completionHandler([])
        case "sound":
            completionHandler([.sound])
        default: // soundAndVibration
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            completionHandler([.sound])
        }
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
            userInfo: userInfo as [AnyHashable: Any]
        )
        completionHandler()
    }
}
