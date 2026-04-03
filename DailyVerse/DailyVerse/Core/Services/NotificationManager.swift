import Foundation
import UserNotifications
import Combine

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            // .timeSensitive: 집중 모드(Focus)에서도 알람이 표시되도록 요청
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    /// 알람을 스케줄링합니다. isEnabled == false 알람은 등록하지 않습니다.
    func schedule(_ alarm: Alarm, verse: Verse) {
        guard alarm.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "DailyVerse 🔔"
        content.body = "\"\(verse.textKo)\"\n\(verse.reference) \u{2022} \(verse.theme.first?.capitalized ?? "")"
        content.sound = .default
        // timeSensitive: 집중 모드(Focus)를 뚫고 알람이 표시됨 (iOS 15+)
        // 엔타이틀먼트 com.apple.developer.usernotifications.time-sensitive 필요
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "alarm_id": alarm.id.uuidString,
            "verse_id": verse.id,
            "mode": AppMode.fromTime(alarm.time).rawValue
        ]

        if alarm.repeatDays.isEmpty {
            // 단발성 — 가장 가까운 미래 시점으로 계산
            let components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
            guard let fireDate = nextFireDate(from: components) else { return }
            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { return }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(alarm.id.uuidString)_once",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        } else {
            // 반복 — 각 요일마다 개별 UNCalendarNotificationTrigger 등록
            let hourMinute = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
            for day in alarm.repeatDays {
                var components = DateComponents()
                components.hour = hourMinute.hour
                components.minute = hourMinute.minute
                components.weekday = day + 1   // iOS: 일요일=1, 0=일 → 1, 1=월 → 2

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)_day\(day)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    // MARK: - Cancellation

    func cancel(alarmId: UUID) {
        // repeatDays 7가지 + 단발성 + 스누즈 전부 제거
        var identifiers: [String] = ["\(alarmId.uuidString)_once", "\(alarmId.uuidString)_snooze"]
        for day in 0...6 {
            identifiers.append("\(alarmId.uuidString)_day\(day)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Snooze (Edge Case 3: 앱 강제 종료 후에도 UNNotificationRequest가 시스템에 등록되어 있으므로 자동 발동 보장)

    func rescheduleSnooze(alarmId: UUID, verse: Verse, minutes: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = "DailyVerse 🔔"
        content.body = "\"\(verse.textKo)\"\n\(verse.reference)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "alarm_id": alarmId.uuidString,
            "verse_id": verse.id,
            "is_snooze": true
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "\(alarmId.uuidString)_snooze",
            content: content,
            trigger: trigger
        )
        // 기존 스누즈 요청 제거 후 재등록
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(alarmId.uuidString)_snooze"]
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Private Helpers

    private func nextFireDate(from components: DateComponents) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        dateComponents.second = 0
        return Calendar.current.nextDate(
            after: Date(),
            matching: dateComponents,
            matchingPolicy: .nextTime
        )
    }
}
