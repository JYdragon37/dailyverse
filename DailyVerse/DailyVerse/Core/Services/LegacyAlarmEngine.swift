import Foundation
import AVFoundation
import AudioToolbox
import UserNotifications
import UIKit
import OSLog

private let bgLog = Logger(subsystem: "com.dailyverse", category: "AlarmBackground")

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

    // 진동 전용 타이머
    private static var vibrationTimer: Timer?

    // 번들 파일 없을 때 AVAudioEngine으로 생성한 알람음
    private static var audioEngine: AVAudioEngine?
    private static var enginePlayerNode: AVAudioPlayerNode?

    /// 포그라운드 진입 시 alertStyle에 따라 소리/진동 시작
    /// AVAudioSession.playback 카테고리 → 무음 스위치 우회 (무음/진동 모드에서도 소리 재생)
    static func startAudio(soundId: String, volume: Float = 0.8) {
        // 진동 전용 모드
        if soundId == "vibration" {
            startVibrationLoop()
            return
        }

        // AVAudioSession.playback — 무음 스위치 우회, 스피커 강제 출력
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []   // duckOthers 제거 — 알람은 단독으로 재생
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            // 내장 스피커 강제 출력 — 이어폰/블루투스 연결 여부 무관하게 스피커로
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            #if DEBUG
            print("⚠️ [LegacyAlarmEngine] AVAudioSession 설정 실패: \(error)")
            #endif
        }

        // 번들 오디오 파일 시도
        let filename: String
        switch soundId {
        case "nature": filename = "alarm_nature"
        case "hymn":   filename = "alarm_hymn"
        case "song":   filename = "alarm_song"
        default:       filename = "alarm_song"   // alarm_song이 기본 알람음
        }

        // 미디어 볼륨 체크 — 0이면 소리 안 남
        let outputVol = AVAudioSession.sharedInstance().outputVolume
        #if DEBUG
        print("🔊 [LegacyAlarmEngine] 미디어 볼륨: \(outputVol)")
        print("🔊 [LegacyAlarmEngine] filename: \(filename)")
        #endif

        if let url = Bundle.main.url(forResource: filename, withExtension: "caf")
            ?? Bundle.main.url(forResource: filename, withExtension: "mp3")
            ?? Bundle.main.url(forResource: filename, withExtension: "wav") {
            #if DEBUG
            print("🔊 [LegacyAlarmEngine] 파일 URL 발견: \(url.lastPathComponent)")
            #endif
            // 번들 파일 있음 → AVAudioPlayer 루프
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0.15              // 시작 볼륨 15%
                let started = player.play()
                player.setVolume(volume, fadeDuration: 30.0)  // 30초에 걸쳐 목표 볼륨으로 점진적 증가
                audioPlayer = player
                #if DEBUG
                print("🔊 [LegacyAlarmEngine] play() 결과: \(started)  playerVolume: \(player.volume)")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ [LegacyAlarmEngine] AVAudioPlayer 생성 실패: \(error)")
                #endif
                startGeneratedToneLoop(volume: volume)
            }
        } else {
            #if DEBUG
            print("⚠️ [LegacyAlarmEngine] 번들에서 \(filename) 파일 없음 — 생성 톤으로 대체")
            #endif
            startGeneratedToneLoop(volume: volume)
        }

        // 미디어 볼륨이 0이면 알림 → Stage1이 경고 표시
        if outputVol < 0.05 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .dvAlarmVolumeTooLow, object: nil)
            }
        }
    }

    /// AVAudioEngine으로 알람 비프음을 생성하여 재생
    /// AVAudioSession.playback 위에서 실행되므로 무음 모드에서도 소리가 남
    private static func startGeneratedToneLoop(volume: Float) {
        stopAudio()

        guard let beepData = makeBeepWavData(volume: volume),
              let tempURL = writeTempWav(data: beepData) else {
            // 최후 폴백 (이 경로는 거의 도달하지 않음)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: tempURL)
            player.numberOfLoops = -1
            player.volume = volume
            player.play()
            audioPlayer = player
        } catch {
            #if DEBUG
            print("⚠️ [LegacyAlarmEngine] 생성 톤 재생 실패: \(error)")
            #endif
        }
    }

    /// 진동 전용 모드 — 기존 오디오 정지 후 진동 루프 시작
    static func startVibrationLoop() {
        stopAudio()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        RunLoop.main.add(vibrationTimer!, forMode: .common)
    }

    /// 소리+진동 모드 — 오디오를 유지하면서 진동 루프만 추가
    static func addVibrationLoop() {
        vibrationTimer?.invalidate()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        RunLoop.main.add(vibrationTimer!, forMode: .common)
    }

    static func stopAudio() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        enginePlayerNode?.stop()
        audioEngine?.stop()
        enginePlayerNode = nil
        audioEngine = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - WAV 생성 헬퍼

    /// 알람 비프음 PCM 데이터를 메모리에서 직접 생성
    /// 패턴: 0.3s on (880Hz) → 0.15s off → 0.3s on → 0.25s off (1초 루프)
    private static func makeBeepWavData(volume: Float) -> Data? {
        let sampleRate: Int32 = 22050
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let totalSeconds: Float = 1.0
        let numSamples = Int(Float(sampleRate) * totalSeconds)

        var wav = Data()

        func appendI32(_ v: Int32) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }
        func appendI16(_ v: Int16) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }

        let dataBytes = Int32(numSamples * 2)
        wav.append(contentsOf: "RIFF".utf8)
        appendI32(dataBytes + 36)
        wav.append(contentsOf: "WAVE".utf8)
        wav.append(contentsOf: "fmt ".utf8)
        appendI32(16)
        appendI16(1)             // PCM
        appendI16(numChannels)
        appendI32(sampleRate)
        appendI32(sampleRate * Int32(numChannels * bitsPerSample / 8))
        appendI16(numChannels * bitsPerSample / 8)
        appendI16(bitsPerSample)
        wav.append(contentsOf: "data".utf8)
        appendI32(dataBytes)

        let freq: Float = 880.0
        let amp: Float = min(max(volume, 0), 1) * 26000

        for i in 0..<numSamples {
            let t = Float(i) / Float(sampleRate)
            let pos = t.truncatingRemainder(dividingBy: 1.0)
            var sample: Int16 = 0
            // on 구간: 0~0.3s, 0.45~0.75s
            if pos < 0.30 || (pos >= 0.45 && pos < 0.75) {
                sample = Int16(sin(2 * .pi * freq * t) * amp)
            }
            withUnsafeBytes(of: sample.littleEndian) { wav.append(contentsOf: $0) }
        }
        return wav
    }

    private static func writeTempWav(data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dv_alarm_beep.wav")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    func cancelAll() async throws {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        Self.stopAudio()
    }

    // MARK: - AlarmEngine + Helpers

    private func makeContent(alarm: Alarm, verse: Verse) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title    = "DailyVerse 🔔"
        content.subtitle = verse.verseShortKo          // 말씀 텍스트 (잠금화면 배너 2행)
        content.body     = verse.reference             // 성경 참조 (잠금화면 배너 3행)
        content.interruptionLevel = .timeSensitive
        // 앱 종료 상태에서 알람 소리 재생: 번들 mp3 우선, 없으면 시스템 기본음
        if Bundle.main.url(forResource: "alarm_song", withExtension: "mp3") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_song.mp3"))
        } else {
            content.sound = .default
        }

        content.userInfo = [
            "alarm_id":       alarm.id.uuidString,
            "verse_id":       verse.id,
            "mode":           AppMode.fromTime(alarm.time).rawValue,
            "sound_id":       alarm.soundId,
            "volume":         alarm.volume,
            "alert_style":    alarm.alertStyle,
            "verse_short_ko": verse.verseShortKo,  // 백업 알림 배너용
            "verse_reference": verse.reference      // 백업 알림 배너용
        ]
        return content
    }

    /// 단발성 알람 예약 + 연속 알람 백업 5개 (+1~+5분)
    /// 앱 종료 상태에서도 최대 5분간 배너가 반복 표시됨
    private func scheduleOnce(alarmId: UUID, content: UNMutableNotificationContent, interval: TimeInterval) {
        let center = UNUserNotificationCenter.current()

        // 메인 알람
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: "\(alarmId.uuidString)_once",
                                          content: content, trigger: trigger))

        // 백업 알람: +1분, +2분, +3분, +4분, +5분
        for i in 1...5 {
            let backupInterval = interval + TimeInterval(i * 60)
            guard backupInterval > 1 else { continue }
            let backupTrigger = UNTimeIntervalNotificationTrigger(timeInterval: backupInterval, repeats: false)
            center.add(UNNotificationRequest(identifier: "\(alarmId.uuidString)_once_backup\(i)",
                                              content: content, trigger: backupTrigger))
        }
    }

    /// 반복 알람 예약 (요일별) + 연속 알람 백업 2개 (+1분, +2분)
    /// iOS 64개 한도: 3알람 × 7요일 × 3트리거(main+2backup) = 63개 ✅
    func schedule(alarm: DailyVerseAlarm) async throws {
        let a = alarm.alarm
        let verse = alarm.verse
        guard a.isEnabled else { return }

        let content = makeContent(alarm: a, verse: verse)

        if a.repeatDays.isEmpty {
            let components = Calendar.current.dateComponents([.hour, .minute], from: a.time)
            guard let fireDate = nextFireDate(from: components) else { return }
            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { return }
            scheduleOnce(alarmId: a.id, content: content, interval: interval)
        } else {
            let hourMinute = Calendar.current.dateComponents([.hour, .minute], from: a.time)
            let center = UNUserNotificationCenter.current()

            for day in a.repeatDays {
                var components = DateComponents()
                components.hour = hourMinute.hour
                components.minute = hourMinute.minute
                components.weekday = day + 1

                // 메인 알람
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                try await center.add(UNNotificationRequest(identifier: "\(a.id.uuidString)_day\(day)",
                                                            content: content, trigger: trigger))

                // 백업 +1분, +2분
                for backupMin in 1...2 {
                    let backupComponents = addMinutes(backupMin, to: components)
                    let backupTrigger = UNCalendarNotificationTrigger(dateMatching: backupComponents, repeats: true)
                    try await center.add(UNNotificationRequest(identifier: "\(a.id.uuidString)_day\(day)_backup\(backupMin)",
                                                               content: content, trigger: backupTrigger))
                }
            }
        }
    }

    func cancel(alarmId: UUID) async throws {
        var ids = ["\(alarmId.uuidString)_once", "\(alarmId.uuidString)_snooze"]
        for day in 0...6 {
            ids.append("\(alarmId.uuidString)_day\(day)")
            ids.append("\(alarmId.uuidString)_day\(day)_backup1")
            ids.append("\(alarmId.uuidString)_day\(day)_backup2")
        }
        for i in 1...5 { ids.append("\(alarmId.uuidString)_once_backup\(i)") }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Helpers

    /// DateComponents에 분 추가 (시/분 overflow 처리)
    private func addMinutes(_ minutes: Int, to components: DateComponents) -> DateComponents {
        var result = DateComponents()
        result.weekday = components.weekday
        let total = (components.hour ?? 0) * 60 + (components.minute ?? 0) + minutes
        result.hour   = (total / 60) % 24
        result.minute = total % 60
        return result
    }

    private func nextFireDate(from components: DateComponents) -> Date? {
        var dc = DateComponents()
        dc.hour = components.hour
        dc.minute = components.minute
        dc.second = 0
        return Calendar.current.nextDate(after: Date(), matching: dc, matchingPolicy: .nextTime)
    }
}

// MARK: - AlarmBackgroundService
// 알라미와 동일한 "백그라운드 무음 루프" 방식 구현
// AVAudioSession.playback + 무음 WAV 루프 → iOS가 앱을 백그라운드에서 종료하지 않음
// 알람 시각에 Timer 발동 → 즉시 알람 사운드 + dvAlarmTriggered 포스팅 → Stage 1 전환

final class AlarmBackgroundService {
    static let shared = AlarmBackgroundService()

    private var silentPlayer: AVAudioPlayer?
    private var alarmTimers: [UUID: [Timer]] = [:]
    private var isRunning = false

    private init() {}

    // MARK: - Public

    /// 앱이 백그라운드 진입 시 호출
    func start() {
        guard !isRunning else { return }
        isRunning = true
        bgLog.info("🚀 [BgService] start() 호출 — 무음루프 + 타이머 시작")
        startSilentLoop()
        rescheduleTimers()
    }

    /// 앱이 포그라운드 복귀 시 호출 (무음 루프만 중지, 타이머는 유지)
    func stop() {
        isRunning = false
        silentPlayer?.stop()
        silentPlayer = nil
        // 알람이 울리는 중이면 AudioSession 유지 — setActive(false) 하면 알람 사운드까지 중단됨
        let alarmPlaying = LegacyAlarmEngine.audioPlayer?.isPlaying ?? false
        if !alarmPlaying {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        #if DEBUG
        print("🔇 [BgService] 포그라운드 복귀 — silentPlayer 중지, alarmPlaying=\(alarmPlaying)")
        #endif
    }

    /// 알람 추가·수정·삭제 후 타이머 재갱신
    /// iOS 26+: AlarmKit이 모든 알람 처리 → 타이머 불필요 (완전 차단)
    func rescheduleTimers() {
        if #available(iOS 26.0, *) { return }
        cancelAllTimers()
        let alarms = AlarmRepository().fetchAll().filter { $0.isEnabled }
        for alarm in alarms {
            scheduleTimers(for: alarm)
        }
    }

    // MARK: - Silent Audio Loop

    private func startSilentLoop() {
        do {
            // .mixWithOthers: 음악 등 다른 앱 오디오를 방해하지 않으면서 백그라운드 유지
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("⚠️ [BgService] AVAudioSession 설정 실패: \(error)")
            #endif
        }

        guard let data = makeSilentWav(),
              let url = writeTempFile(data: data, name: "dv_silent.wav") else { return }

        silentPlayer = try? AVAudioPlayer(contentsOf: url)
        silentPlayer?.numberOfLoops = -1
        silentPlayer?.volume = 0.0   // 완전 무음
        silentPlayer?.play()
        #if DEBUG
        print("🔇 [BgService] 무음 루프 시작")
        #endif
    }

    // stopSilentLoop() 제거됨 — stop()이 직접 처리 (알람 재생 여부 체크 포함)

    // MARK: - Timer Scheduling

    private func scheduleTimers(for alarm: Alarm) {
        let now = Date()
        let dates = nextFireDates(alarm: alarm, from: now)
        if dates.isEmpty {
            bgLog.warning("⚠️ [BgService] 타이머 날짜 없음 — alarmId: \(alarm.id)")
        }
        for date in dates {
            let interval = date.timeIntervalSince(now)
            guard interval > 1 else { continue }
            let t = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
                self?.fireAlarm(alarm)
            }
            RunLoop.main.add(t, forMode: .common)
            alarmTimers[alarm.id, default: []].append(t)
            bgLog.info("⏰ [BgService] 타이머 등록 — alarmId: \(alarm.id), 발동까지: \(Int(interval))초 (\(date))")
        }
    }

    private func cancelAllTimers() {
        alarmTimers.values.flatMap { $0 }.forEach { $0.invalidate() }
        alarmTimers.removeAll()
    }

    // MARK: - Alarm Fire (백그라운드에서 알람 발동)

    private func fireAlarm(_ alarm: Alarm) {
        bgLog.info("🔔 [BgService] fireAlarm() 호출 — alarmId: \(alarm.id), appState: \(UIApplication.shared.applicationState.rawValue)")

        // 1. 알람 사운드 즉시 재생
        LegacyAlarmEngine.startAudio(soundId: alarm.soundId, volume: alarm.volume)
        if alarm.alertStyle == "soundAndVibration" || alarm.alertStyle == "vibration" {
            LegacyAlarmEngine.addVibrationLoop()
        }
        bgLog.info("🔊 [BgService] startAudio 완료 — soundId: \(alarm.soundId)")

        // 2. dvAlarmTriggered 포스팅 → AlarmCoordinator.init() observer가 수신 (백그라운드 안정)
        let verse = resolveVerse(for: alarm)
        bgLog.info("📤 [BgService] dvAlarmTriggered 포스팅 예정 — verseId: \(verse.id)")
        NotificationCenter.default.post(
            name: .dvAlarmTriggered,
            object: nil,
            userInfo: [
                "alarm_id":    alarm.id.uuidString,
                "verse_id":    verse.id,
                "mode":        AppMode.fromTime(alarm.time).rawValue,
                "alert_style": alarm.alertStyle,
                "sound_id":    alarm.soundId,
                "volume":      alarm.volume as NSNumber
            ]
        )
        bgLog.info("📤 [BgService] dvAlarmTriggered 포스팅 완료")
        // scene activation은 AlarmCoordinator.handleNotification() 내 requestForegroundActivation()에서 처리

        // 4. 반복 알람 재스케줄
        alarmTimers[alarm.id]?.forEach { $0.invalidate() }
        alarmTimers[alarm.id] = nil
        if !alarm.repeatDays.isEmpty {
            scheduleTimers(for: alarm)
        }
    }

    // MARK: - Verse Resolution

    private func resolveVerse(for alarm: Alarm) -> Verse {
        let mode = AppMode.fromTime(alarm.time)
        if let id = DailyCacheManager.shared.getVerseId(for: mode),
           let v  = DailyCacheManager.shared.loadCachedVerse(id: id) { return v }
        switch mode {
        case .deepDark:   return Verse.fallbackDeepDark
        case .firstLight: return Verse.fallbackFirstLight
        case .riseIgnite: return Verse.fallbackRiseIgnite
        case .peakMode:   return Verse.fallbackPeakMode
        case .recharge:   return Verse.fallbackRecharge
        case .secondWind: return Verse.fallbackSecondWind
        case .goldenHour: return Verse.fallbackGoldenHour
        case .windDown:   return Verse.fallbackWindDown
        }
    }

    // MARK: - Next Fire Dates

    private func nextFireDates(alarm: Alarm, from now: Date) -> [Date] {
        let cal = Calendar.current
        let hm  = cal.dateComponents([.hour, .minute], from: alarm.time)
        guard let h = hm.hour, let m = hm.minute else { return [] }

        if alarm.repeatDays.isEmpty {
            // 일회성: 오늘 해당 시각 (이미 지났으면 내일)
            var dc = DateComponents(); dc.hour = h; dc.minute = m; dc.second = 0
            if let d = cal.nextDate(after: now - 60, matching: dc, matchingPolicy: .nextTime) {
                return [d]
            }
            return []
        } else {
            // 요일 반복: 각 요일의 다음 발동 시각
            return alarm.repeatDays.compactMap { day in
                var dc = DateComponents()
                dc.weekday = day + 1   // Alarm.repeatDays: 0=일 → Calendar.weekday 1
                dc.hour = h; dc.minute = m; dc.second = 0
                return cal.nextDate(after: now - 60, matching: dc, matchingPolicy: .nextTime)
            }
        }
    }

    // MARK: - Silent WAV (1초, 무음)

    private func makeSilentWav() -> Data? {
        let sr: Int32 = 8000; let ch: Int16 = 1; let bps: Int16 = 16
        let samples = Int(sr)   // 1초
        var wav = Data()
        func i32(_ v: Int32) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }
        func i16(_ v: Int16) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }
        let dataBytes = Int32(samples * 2)
        wav.append(contentsOf: "RIFF".utf8); i32(dataBytes + 36)
        wav.append(contentsOf: "WAVE".utf8); wav.append(contentsOf: "fmt ".utf8)
        i32(16); i16(1); i16(ch); i32(sr)
        i32(sr * Int32(ch * bps / 8)); i16(ch * bps / 8); i16(bps)
        wav.append(contentsOf: "data".utf8); i32(dataBytes)
        wav.append(Data(repeating: 0, count: samples * 2))
        return wav
    }

    private func writeTempFile(data: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        return (try? data.write(to: url, options: .atomic)) != nil ? url : nil
    }
}
