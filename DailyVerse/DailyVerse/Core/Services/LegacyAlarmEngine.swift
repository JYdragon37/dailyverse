import Foundation
import AVFoundation
import AudioToolbox
import UserNotifications
import UIKit
import OSLog

private let bgLog = Logger(subsystem: "com.morningmanna.app", category: "AlarmBackground")

// MARK: - LegacyAlarmEngine (iOS 15–25)

/// AVAudioSession .playback 카테고리를 이용해 무음 모드를 관통하는 알람 엔진.
///
/// 동작 방식:
/// 1. UNUserNotificationCenter로 30초 간격 로컬 알림 10개를 연속 예약 → 연속 알람 효과
///    (.timeSensitive + 커스텀 사운드 → 앱이 백그라운드/종료 상태여도 알림 배너로 알람 발동)
/// 2. 앱이 포그라운드로 올 때 AppDelegate/NotificationDelegate에서 AVAudioPlayer로 전환
///
/// 참고: audio 백그라운드 모드는 App Store 심사(2.5.4) 준수를 위해 제거됨.
///       → 백그라운드 무음 루프 keep-alive 대신 UNNotification(.timeSensitive)에 의존.
///       → 앱이 활성 상태일 때만 AVAudioSession .playback로 무음 스위치 관통 재생.
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

        // 번들 오디오 파일 — AlarmSound 모델에서 파일명 조회
        let filename = AlarmSound.sound(for: soundId).filename

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
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "ko"
        content.title    = "mm"
        content.subtitle = verse.verseShort(lang: lang)  // 말씀 텍스트 (잠금화면 배너 2행)
        content.body     = verse.referenceDisplay        // 성경 참조 (잠금화면 배너 3행)
        content.interruptionLevel = .timeSensitive
        // 앱 종료 상태 알람 소리: 유저가 선택한 사운드 → 없으면 alarm_song → 시스템 기본음
        let selectedFilename = AlarmSound.sound(for: alarm.soundId).filename + ".mp3"
        if Bundle.main.url(forResource: AlarmSound.sound(for: alarm.soundId).filename, withExtension: "mp3") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(selectedFilename))
        } else if Bundle.main.url(forResource: "alarm_song", withExtension: "mp3") != nil {
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
            "verse_short_ko": verse.verseShort(lang: lang),  // 백업 알림 배너용
            "verse_reference": verse.referenceDisplay         // 백업 알림 배너용
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
        // Q4: 등록 완료 후 현재 UNNotification 개수 콘솔 출력 (64개 한도 추적)
        LegacyAlarmEngine.logPendingNotificationCount()
    }

    // MARK: - UNNotification 개수 로그 (Q4: 64개 한도 추적)

    /// 현재 등록된 UNNotification 개수를 Xcode 콘솔에 출력
    /// 알람 미작동 신고 시 원인 파악용 — 서버 전송 없음
    static func logPendingNotificationCount() {
        Task {
            let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            bgLog.info("📊 [LegacyAlarmEngine] UNNotification 등록 개수: \(pending.count)/64\(pending.count >= 60 ? " ⚠️ 한도 근접" : "")")
        }
    }

    /// 알람의 메인/백업 알림만 취소한다. 대기 중인 스누즈(`_snooze`)는 건드리지 않음 —
    /// 콘텐츠 버전 재등록·다른 저장/토글 시에도 호출되므로, 여기서 스누즈까지 지우면
    /// 유저가 스누즈 대기 중 앱을 여는 것만으로 재알람이 사라지는 버그가 된다.
    /// 스누즈까지 함께 취소해야 하는 경우(알람 삭제/비활성화)는 `cancelSnooze(alarmId:)`를 별도 호출한다.
    func cancel(alarmId: UUID) async throws {
        var ids = ["\(alarmId.uuidString)_once"]
        for day in 0...6 {
            ids.append("\(alarmId.uuidString)_day\(day)")
            ids.append("\(alarmId.uuidString)_day\(day)_backup1")
            ids.append("\(alarmId.uuidString)_day\(day)_backup2")
            // iOS 26 포그라운드 트리거 (scheduleForegroundTrigger에서 등록)
            ids.append("\(alarmId.uuidString)_fg_\(day)")
        }
        for i in 1...5 { ids.append("\(alarmId.uuidString)_once_backup\(i)") }
        // iOS 26 포그라운드 트리거 일회성
        ids.append("\(alarmId.uuidString)_fg")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// 대기 중인 스누즈 알림만 취소 (알람 삭제/비활성화 시 호출)
    func cancelSnooze(alarmId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(alarmId.uuidString)_snooze"]
        )
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

    /// 콘텐츠 버전 변경 감지 시 모든 알람 알림 재등록 (Q3: 버전 업 후 배너 말씀 최신화)
    /// - cachedVerseContentVersion과 alarmNotificationRegisteredVersion이 다르면 재등록 실행
    /// - 재등록 후 alarmNotificationRegisteredVersion을 최신 버전으로 갱신
    func reregisterIfVersionChanged() {
        let currentVersion    = UserDefaults.standard.string(forKey: "cachedVerseContentVersion") ?? ""
        let registeredVersion = UserDefaults.standard.string(forKey: "alarmNotificationRegisteredVersion") ?? ""
        guard !currentVersion.isEmpty, currentVersion != registeredVersion else { return }

        bgLog.info("🔄 [BgService] 콘텐츠 버전 변경 감지 (\(registeredVersion) → \(currentVersion)) — 알람 알림 재등록 시작")
        let alarms = AlarmRepository().fetchAll().filter { $0.isEnabled }
        for alarm in alarms {
            let mode = AppMode.fromTime(alarm.time)
            let verse: Verse
            if let id = DailyCacheManager.shared.getVerseId(for: mode),
               let v  = DailyCacheManager.shared.loadCachedVerse(id: id) {
                verse = v
            } else {
                verse = OfflineFallbackManager.shared.fallbackVerse(for: mode)
            }
            NotificationManager.shared.cancelThenSchedule(alarmId: alarm.id, alarm: alarm, verse: verse)
        }
        UserDefaults.standard.set(currentVersion, forKey: "alarmNotificationRegisteredVersion")
        bgLog.info("✅ [BgService] 알람 알림 재등록 완료 — \(alarms.count)개 알람, version: \(currentVersion)")
    }

    /// 알람 추가·수정·삭제 후 타이머 재갱신
    /// iOS 26+: 포그라운드 Stage2 트리거용 타이머 유지 (음향은 AlarmKit 담당)
    /// iOS 15-25: 음향 + UI 모두 타이머로 처리
    func rescheduleTimers() {
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

    // MARK: - Alarm Fire

    private func fireAlarm(_ alarm: Alarm) {
        bgLog.info("🔔 [BgService] fireAlarm() 호출 — alarmId: \(alarm.id), appState: \(UIApplication.shared.applicationState.rawValue)")

        if #available(iOS 26.0, *) {
            // iOS 26+: AlarmKit이 음향 담당 → 앱은 포그라운드 UI(Stage2)만 트리거
            // 타이머는 RunLoop.main에서 동작 → 앱이 포그라운드일 때만 발동 (백그라운드 시 AlarmKit 처리)
            let verse = resolveVerse(for: alarm)
            bgLog.info("📤 [BgService] iOS26 포그라운드 Stage2 트리거 — verseId: \(verse.id)")
            NotificationCenter.default.post(
                name: .dvAlarmTriggered,
                object: nil,
                userInfo: [
                    "alarm_id":       alarm.id.uuidString,
                    "verse_id":       verse.id,
                    "mode":           AppMode.fromTime(alarm.time).rawValue,
                    "alarmkit_stop":  true   // Stage2 직행, 앱 음향 없음
                ]
            )
            // 반복 알람 재스케줄
            alarmTimers[alarm.id]?.forEach { $0.invalidate() }
            alarmTimers[alarm.id] = nil
            if !alarm.repeatDays.isEmpty { scheduleTimers(for: alarm) }
            return
        }

        // iOS 15-25: 음향 + UI 모두 앱이 처리
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
