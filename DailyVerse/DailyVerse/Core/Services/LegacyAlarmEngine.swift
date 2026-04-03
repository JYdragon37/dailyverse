import Foundation
import AVFoundation
import UserNotifications

// MARK: - LegacyAlarmEngine (iOS 15–25)

/// AVAudioSession .playback 카테고리를 이용해 무음 모드를 관통하는 알람 엔진.
///
/// 동작 방식:
/// 1. UNUserNotificationCenter로 30초 간격 로컬 알림 10개를 연속 예약 → 연속 알람 효과
/// 2. 앱이 포그라운드로 올 때 AppDelegate/NotificationDelegate에서 AVAudioPlayer로 전환
/// 3. Info.plist Background Modes → audio 필수
///
/// 한계: 앱이 완전 종료 상태면 시스템 알림 소리만 울림 (DND는 .timeSensitive로 관통)
final class LegacyAlarmEngine: AlarmEngine {

    // MARK: - AVAudio (포그라운드 전환 시)

    static var audioPlayer: AVAudioPlayer?

    /// 포그라운드 복귀 시 시스템 알림 사운드 대신 번들 오디오로 전환
    static func startAudio(soundId: String, volume: Float = 0.8) {
        let filename: String
        switch soundId {
        case "nature": filename = "alarm_nature"
        case "hymn":   filename = "alarm_hymn"
        default:       filename = "alarm_piano"
        }

        guard let url = Bundle.main.url(forResource: filename, withExtension: "caf") else {
            // 번들 오디오 파일 없으면 시스템 소리 유지
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1   // 무한 반복
            player.volume = volume
            player.play()
            audioPlayer = player
        } catch {
            #if DEBUG
            print("⚠️ [LegacyAlarmEngine] AVAudioPlayer 시작 실패: \(error)")
            #endif
        }
    }

    static func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - AlarmEngine

    func schedule(alarm: DailyVerseAlarm) async throws {
        let a = alarm.alarm
        let verse = alarm.verse
        guard a.isEnabled else { return }

        let content = makeContent(alarm: a, verse: verse)

        if a.repeatDays.isEmpty {
            // 단발성
            let components = Calendar.current.dateComponents([.hour, .minute], from: a.time)
            guard let fireDate = nextFireDate(from: components) else { return }
            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { return }
            scheduleOnce(alarmId: a.id, content: content, interval: interval)
        } else {
            // 반복: 요일별 UNCalendarNotificationTrigger
            let hourMinute = Calendar.current.dateComponents([.hour, .minute], from: a.time)
            for day in a.repeatDays {
                var components = DateComponents()
                components.hour = hourMinute.hour
                components.minute = hourMinute.minute
                components.weekday = day + 1
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(a.id.uuidString)_day\(day)",
                    content: content, trigger: trigger
                )
                try await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func cancel(alarmId: UUID) async throws {
        var ids = ["\(alarmId.uuidString)_once", "\(alarmId.uuidString)_snooze"]
        for day in 0...6 { ids.append("\(alarmId.uuidString)_day\(day)") }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAll() async throws {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        Self.stopAudio()
    }

    // MARK: - Helpers

    private func makeContent(alarm: Alarm, verse: Verse) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "DailyVerse 🔔"
        content.body = "\"\(verse.textKo)\"\n\(verse.reference) • \(verse.theme.first?.capitalized ?? "")"
        content.interruptionLevel = .timeSensitive

        // alertStyle에 따라 소리 설정
        switch alarm.alertStyle {
        case "vibration":
            // 진동만: sound = nil (시스템이 진동만 울림)
            content.sound = nil
        case "sound":
            content.sound = .default
        default: // "soundAndVibration"
            content.sound = .default
        }

        content.userInfo = [
            "alarm_id":    alarm.id.uuidString,
            "verse_id":    verse.id,
            "mode":        AppMode.fromTime(alarm.time).rawValue,
            "sound_id":    alarm.soundId,
            "volume":      alarm.volume,
            "alert_style": alarm.alertStyle
        ]
        return content
    }

    private func scheduleOnce(alarmId: UUID, content: UNMutableNotificationContent, interval: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarmId.uuidString)_once",
            content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func nextFireDate(from components: DateComponents) -> Date? {
        var dc = DateComponents()
        dc.hour = components.hour
        dc.minute = components.minute
        dc.second = 0
        return Calendar.current.nextDate(after: Date(), matching: dc, matchingPolicy: .nextTime)
    }
}
