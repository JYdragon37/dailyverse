import Foundation
import UserNotifications
import Combine

/// v5.1 — 알람 스케줄링 매니저 (듀얼 엔진 사용)
/// - iOS 26+: AlarmKitEngine
/// - iOS 15–25: LegacyAlarmEngine (AVAudioSession + UNUserNotificationCenter)
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let engine: AlarmEngine = AlarmEngineFactory.make()

    private override init() {
        super.init()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    func schedule(_ alarm: Alarm, verse: Verse) {
        guard alarm.isEnabled else { return }
        let av = DailyVerseAlarm(alarm: alarm, verse: verse)
        Task {
            try? await engine.schedule(alarm: av)
        }
    }

    func cancel(alarmId: UUID) {
        Task {
            try? await engine.cancel(alarmId: alarmId)
        }
    }

    func cancelAll() {
        Task {
            try? await engine.cancelAll()
        }
    }

    // MARK: - Snooze

    /// 스누즈: UNTimeIntervalNotificationTrigger로 재스케줄 (앱 강제 종료 후에도 유지)
    func rescheduleSnooze(alarmId: UUID, verse: Verse, minutes: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = "DailyVerse 🔔"
        content.body = "\"\(verse.textKo)\"\n\(verse.reference)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "alarm_id": alarmId.uuidString,
            "verse_id": verse.id,
            "is_snooze": true,
            "mode": AppMode.current().rawValue
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(alarmId.uuidString)_snooze"]
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Audio Control (포그라운드 전환 시)

    func startAlarmAudio(soundId: String, volume: Float) {
        LegacyAlarmEngine.startAudio(soundId: soundId, volume: volume)
    }

    func stopAlarmAudio() {
        LegacyAlarmEngine.stopAudio()
    }
}
