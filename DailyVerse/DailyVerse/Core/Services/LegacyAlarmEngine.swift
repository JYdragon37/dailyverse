import Foundation
import AVFoundation
import AudioToolbox
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

    // Bug 4 수정: 진동 전용 타이머
    private static var vibrationTimer: Timer?

    /// 포그라운드 진입 시 alertStyle에 따라 소리/진동 시작
    /// Bug 5 수정: 번들 .caf 없으면 시스템 사운드 + AudioServices로 폴백
    static func startAudio(soundId: String, volume: Float = 0.8) {
        // 진동 전용 모드
        if soundId == "vibration" {
            startVibrationLoop()
            return
        }

        // 번들 오디오 파일 시도
        let filename: String
        switch soundId {
        case "nature": filename = "alarm_nature"
        case "hymn":   filename = "alarm_hymn"
        default:       filename = "alarm_piano"
        }

        if let url = Bundle.main.url(forResource: filename, withExtension: "caf") {
            // 번들 파일 있음 → AVAudioPlayer 루프
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = volume
                player.play()
                audioPlayer = player
            } catch {
                #if DEBUG
                print("⚠️ [LegacyAlarmEngine] AVAudioPlayer 실패, 시스템 사운드로 폴백: \(error)")
                #endif
                startSystemSoundLoop()
            }
        } else {
            // Bug 5 수정: 번들 파일 없음 → 시스템 알람 사운드 + 진동 루프로 폴백
            startSystemSoundLoop()
        }
    }

    /// Bug 5 폴백: 시스템 알람 사운드(1005) + 진동을 2초 간격으로 반복
    private static func startSystemSoundLoop() {
        stopAudio() // 기존 타이머 정리
        // 즉시 1회 실행
        playSystemAlarmSound()
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            playSystemAlarmSound()
        }
        RunLoop.main.add(vibrationTimer!, forMode: .common)
    }

    /// Bug 4 수정: 진동 전용 — 1.5초 간격 햅틱 루프
    private static func startVibrationLoop() {
        stopAudio()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        RunLoop.main.add(vibrationTimer!, forMode: .common)
    }

    private static func playSystemAlarmSound() {
        // 시스템 사운드 1005 = 받은 메일 소리 (짧고 명확)
        // 1007 = 클릭, 1016 = 트윗 수신음, 1057 = SMS 수신음
        AudioServicesPlayAlertSoundWithCompletion(1005) { }
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    static func stopAudio() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
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

        // Bug 4 수정: alertStyle에 따른 올바른 sound 설정
        // iOS에서 content.sound = nil이면 소리도 진동도 없음
        // 진동 전용: 시스템 기본음 사용 (알람 앱 공통 방식 — 실제 진동은 포그라운드에서 AudioServices 처리)
        switch alarm.alertStyle {
        case "vibration":
            // 백그라운드: 최소한의 알림음(시스템이 진동 트리거) + 포그라운드에서 AudioServices 진동 루프
            content.sound = .default
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
