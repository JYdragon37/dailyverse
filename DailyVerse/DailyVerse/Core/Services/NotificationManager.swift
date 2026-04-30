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
            // .timeSensitive: Focus 모드(수면 집중 등) 관통에 필수 — entitlement 단독으로는 부족
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
            // iOS 26+: AlarmKit은 잠금화면만 담당 → 포그라운드 감지용 UNCalendarNotificationTrigger 병행 등록
            // willPresent가 포그라운드에서 dvAlarmTriggered를 포스팅해 Stage2를 즉시 표시
            if #available(iOS 26.0, *) {
                scheduleForegroundTrigger(alarm, verse: verse)
            }
        }
    }

    /// iOS 26 포그라운드 전용 UNCalendarNotificationTrigger
    /// - 소리 없음 (AlarmKit이 담당)
    /// - willPresent 호출 → dvAlarmTriggered(alarmkit_stop: true) → Stage2
    @available(iOS 26.0, *)
    private func scheduleForegroundTrigger(_ alarm: Alarm, verse: Verse) {
        let content = UNMutableNotificationContent()
        content.title = "mm"
        content.interruptionLevel = .passive  // 배너 없이 willPresent만 트리거 (AlarmKit이 시스템 알람 담당)
        content.sound = nil
        // alarmkit_stop 없음 → handleNotification → Stage1(전체화면 알람)
        // alert_style: silent → LegacyEngine 음향 없음 (AlarmKit이 담당)
        content.userInfo = [
            "alarm_id":      alarm.id.uuidString,
            "verse_id":      verse.id,
            "mode":          AppMode.fromTime(alarm.time).rawValue,
            "alert_style":   "silent",
            "sound_id":      alarm.soundId,
            "volume":        alarm.volume as NSNumber
        ]

        let cal = Calendar.current
        let hm  = cal.dateComponents([.hour, .minute], from: alarm.time)
        let center = UNUserNotificationCenter.current()

        if alarm.repeatDays.isEmpty {
            // 일회성
            var dc = hm
            dc.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            let req = UNNotificationRequest(
                identifier: "\(alarm.id.uuidString)_fg",
                content: content, trigger: trigger)
            center.add(req)
        } else {
            // 요일 반복
            for day in alarm.repeatDays {
                var dc = hm
                dc.second = 0
                dc.weekday = day + 1  // 0=일 → weekday 1
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)_fg_\(day)",
                    content: content, trigger: trigger)
                center.add(req)
            }
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

    // MARK: - 고아 알림 정리

    /// 앱 시작 시 Core Data에 없는 alarm_id를 가진 UNNotification을 모두 제거
    /// 시나리오: 알람 삭제 시 _fg 식별자 누락 버그, 앱 업데이트 전후 잔존 알림 등
    func cleanupOrphanedNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            guard !pending.isEmpty else { return }

            // Core Data에 실제 존재하는 alarm ID 목록
            let validIds = Set(AlarmRepository().fetchAll().map { $0.id.uuidString })

            // alarm_id userInfo가 있는데 DB에 없으면 고아 알림
            let orphanIds = pending.compactMap { req -> String? in
                guard let alarmIdStr = req.content.userInfo["alarm_id"] as? String else { return nil }
                return validIds.contains(alarmIdStr) ? nil : req.identifier
            }

            if !orphanIds.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: orphanIds)
                #if DEBUG
                print("🧹 [NotificationManager] 고아 알림 \(orphanIds.count)개 제거: \(orphanIds.prefix(5))")
                #endif
            }
        }
    }

    // MARK: - Snooze

    /// 스누즈: UNTimeIntervalNotificationTrigger로 재스케줄 (앱 강제 종료 후에도 유지)
    func rescheduleSnooze(alarmId: UUID, verse: Verse, minutes: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = "mm"
        content.body = "\"\(verse.verseShortKo)\"\n\(verse.reference)"
        if Bundle.main.url(forResource: "alarm_song", withExtension: "mp3") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_song.mp3"))
        } else {
            content.sound = .default
        }
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

    /// 묵상 리마인더 스케줄 — UserDefaults에서 시간 읽음
    func scheduleMeditationEveningReminder() {
        let enabled = UserDefaults.standard.object(forKey: "meditationReminderEnabled") as? Bool ?? true
        guard enabled else { return }

        let hour = UserDefaults.standard.object(forKey: "meditationReminderHour") as? Int ?? 21
        let minute = UserDefaults.standard.object(forKey: "meditationReminderMinute") as? Int ?? 0

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "mm"
        content.body = "📿 오늘 묵상을 아직 기록하지 않으셨어요"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "meditation.evening.reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// 리마인더 완전 취소 (설정에서 OFF 시)
    func disableMeditationReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["meditation.evening.reminder"])
    }

    /// 오늘 묵상 완료 시 호출 — 당일 리마인더 취소 후 내일 재스케줄
    func cancelTodayMeditationReminder() {
        let enabled = UserDefaults.standard.object(forKey: "meditationReminderEnabled") as? Bool ?? true
        guard enabled else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["meditation.evening.reminder"])
        scheduleMeditationEveningReminder()
    }
}
