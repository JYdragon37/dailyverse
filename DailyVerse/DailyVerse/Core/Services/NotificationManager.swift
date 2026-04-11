import Foundation
import UserNotifications
import UIKit
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
                .requestAuthorization(options: [.alert, .badge, .sound]) // timeSensitive는 entitlement로 처리
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

    // MARK: - Vibration (포그라운드에서 진동 트리거)

    func triggerVibration(for alertStyle: String) {
        switch alertStyle {
        case "vibration":
            // 진동만: 경고 패턴
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            // 추가 진동 (0.5초 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        case "soundAndVibration":
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        default:
            break // sound only — 소리는 UNNotification이 담당
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
        content.body = "\"\(verse.verseShortKo)\"\n\(verse.reference)"
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

    func startVibrationLoop() {
        LegacyAlarmEngine.startVibrationLoop()
    }

    func addVibrationLoop() {
        LegacyAlarmEngine.addVibrationLoop()
    }

    func stopAlarmAudio() {
        LegacyAlarmEngine.stopAudio()
    }

    // MARK: - 묵상 리마인더

    /// 저녁 9시 묵상 리마인더 스케줄 (당일 묵상 미기록 시)
    func scheduleMeditationEveningReminder() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "DailyVerse"
        content.body = "📿 오늘 묵상을 아직 기록하지 않으셨어요"
        content.sound = .default

        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "meditation.evening.reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// 오늘 묵상 완료 시 호출 — 당일 리마인더 취소 후 내일 재스케줄
    func cancelTodayMeditationReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["meditation.evening.reminder"]
            )
        // 내일 것 재스케줄
        scheduleMeditationEveningReminder()
    }
}
