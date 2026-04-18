import SwiftUI
import Combine
import UIKit
import OSLog
import ActivityKit

private let alarmLog = Logger(subsystem: "com.dailyverse", category: "AlarmCoordinator")

@MainActor
final class AlarmCoordinator: ObservableObject {

    enum AlarmStage: Equatable {
        case none
        case stage1
        case stage1_5   // v5.1: 웨이크업 미션 수행
        case stage2
    }

    @Published var stage: AlarmStage = .none {
        didSet {
            if stage != .none { stageSetAt = Date() }
            alarmLog.info("🔄 [Stage] \(String(describing: oldValue)) → \(String(describing: self.stage))")
        }
    }
    /// SwiftUI safeAreaInset 버그 방지 — stage 세팅 직후 자동 dismiss 차단용 타임스탬프
    private var stageSetAt: Date = .distantPast
    @Published var activeAlarmId: UUID?
    @Published var activeVerse: Verse?
    @Published var activeImage: VerseImage?
    @Published var activeWeather: WeatherData?
    @Published var activeMode: AppMode = AppMode.current()   // 알람 발동 시간 기준 zone
    @Published var activeSnoozeInterval: Int = 5
    @Published var activeMission: String = "none"
    @Published var activeAlertStyle: String = "soundAndVibration"  // Bug 3 수정
    @Published var activeSoundId: String = "song"
    @Published var activeVolume: Float = 0.8

    private var snoozeCount: Int = 0
    private let notificationManager: NotificationManager
    private let verseRepository: VerseRepository
    private let alarmRepository: AlarmRepository

    var canSnooze: Bool {
        guard let alarmId = activeAlarmId,
              let alarm = alarmRepository.fetchAll().first(where: { $0.id == alarmId }) else {
            return snoozeCount < 3
        }
        return snoozeCount < alarm.maxSnoozeCount
    }

    init(
        notificationManager: NotificationManager = .shared,
        verseRepository: VerseRepository = VerseRepository.shared,
        alarmRepository: AlarmRepository = AlarmRepository()
    ) {
        self.notificationManager = notificationManager
        self.verseRepository = verseRepository
        self.alarmRepository = alarmRepository

        // ★ 핵심 수정: AppRootView.onReceive는 SwiftUI View에 의존하여 백그라운드 미보장.
        //   AlarmCoordinator 자체에 직접 observer 등록 → 백그라운드·포그라운드 모두 안정적 수신.
        NotificationCenter.default.addObserver(
            forName: .dvAlarmTriggered,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, let userInfo = notification.userInfo else { return }
            alarmLog.info("📥 [Coordinator] dvAlarmTriggered 수신 — alarm_id: \(userInfo["alarm_id"] as? String ?? "nil")")
            Task { @MainActor [weak self] in
                await self?.handleNotification(from: userInfo)
            }
        }
        alarmLog.info("✅ [Coordinator] init 완료 — dvAlarmTriggered observer 등록됨")
        // pendingAlarmKitStop 처리는 AppRootView.task에서 로딩 완료 후 실행
        // (init 시점에는 onboardingCompleted가 확정되지 않아 타이밍 문제 발생)
    }

    // MARK: - Notification Handling

    /// NotificationCenter 딕셔너리를 파싱해 알람을 처리합니다.
    func handleNotification(from userInfo: [AnyHashable: Any]) async {
        guard
            let alarmIdString = userInfo["alarm_id"] as? String,
            let alarmId = UUID(uuidString: alarmIdString)
        else { return }

        let modeString      = userInfo["mode"] as? String
        let verseId         = userInfo["verse_id"] as? String ?? ""
        let alertStyle      = userInfo["alert_style"] as? String ?? "soundAndVibration"
        let soundId         = userInfo["sound_id"] as? String ?? "piano"
        let volume          = (userInfo["volume"] as? NSNumber)?.floatValue ?? 0.8
        // AlarmKit StopIntent에서 온 경우: 시스템 잠금화면 알람 종료 후 Stage2 직행
        let alarmKitStop    = userInfo["alarmkit_stop"] as? Bool ?? false

        if alarmKitStop {
            alarmLog.info("📲 [Coordinator] AlarmKit StopIntent 수신 → Stage2 직행")
            await handleAlarmKitStop(alarmId: alarmId, modeString: modeString, fallbackVerseId: verseId)
        } else {
            await handleNotification(
                alarmId: alarmId,
                modeString: modeString,
                fallbackVerseId: verseId,
                alertStyle: alertStyle,
                soundId: soundId,
                volume: volume
            )
        }
    }

    /// AlarmKit "밀어서 중단" 후 Stage2 직행 — Stage1(전체화면 알람) 건너뜀
    /// 알라미의 이중 종료 UX를 제거한 DailyVerse 최적화 흐름
    func handleAlarmKitStop(alarmId: UUID, modeString: String?, fallbackVerseId: String) async {
        // stage2 이미 표시 중이면 무시
        guard stage != .stage2 else { return }

        // ★ BackgroundService가 먼저 .stage1을 세팅한 경우 (iOS 26 AlarmKit + LegacyEngine 동시 동작)
        // stage1 → stage2 즉시 전환 (데이터는 이미 로드됨)
        if stage == .stage1 {
            stopAlarmFeedback()
            stage = .stage2
            alarmLog.info("✅ [Coordinator] AlarmKit stop: .stage1 → .stage2 (데이터 재사용)")
            return
        }

        // stage == .none: 콜드런치 케이스
        guard !isHandling else { return }
        isHandling = true
        defer { isHandling = false }

        let mode = modeString.flatMap { AppMode(rawValue: $0) } ?? AppMode.current()
        let activeAlarm = alarmRepository.fetchAll().first(where: { $0.id == alarmId })

        // ★ Stage2를 즉시 표시 — 데이터 로드 전에 먼저 화면을 열어둠
        // 사용자가 Face ID로 잠금 해제하는 순간 Stage2가 바로 보여야 함
        activeAlarmId        = alarmId
        activeMode           = mode
        activeWeather        = activeWeather ?? WeatherCacheManager().load()
        activeSnoozeInterval = activeAlarm?.snoozeInterval ?? 5
        activeMission        = "none"
        activeAlertStyle     = activeAlarm?.alertStyle ?? "soundAndVibration"
        activeSoundId        = activeAlarm?.soundId    ?? "song"
        activeVolume         = activeAlarm?.volume     ?? 0.8
        snoozeCount          = 0
        stage = .stage2   // ← 즉시 표시

        // Stage2 진입 시 알람 사운드 이어서 재생 (알라미와 동일 UX)
        // AlarmKit 잠금화면 사운드 → Stage2 앱 사운드로 연결
        startAlarmFeedback()
        alarmLog.info("✅ [Coordinator] AlarmKit → stage = .stage2 즉시 표시 + 사운드 재생")

        // Post-alarm Live Activity 종료 (잠금화면 "말씀 보기" 버튼 제거)
        if #available(iOS 26.0, *) {
            endPostAlarmLiveActivities()
        }

        // 말씀/이미지는 Stage2가 열린 후 비동기로 로드 → 화면이 먼저 열리고 내용이 채워짐
        let verse = await loadVerse(mode: mode, fallbackVerseId: fallbackVerseId)
        let image = await loadImage(mode: mode, verse: verse)
        activeVerse = verse
        activeImage = image
        alarmLog.info("✅ [Coordinator] 말씀/이미지 로드 완료 — \(verse.reference)")
    }

    /// alarmId + mode로 Stage 1을 표시합니다.
    /// 오늘의 캐시된 말씀 우선, 없으면 verseId → 번들 폴백 순으로 로드.
    /// Edge Case 6: 복수 알람 동시 발동 — stage != .none 이면 가장 최근 것만 유지
    // isHandling: async handleNotification의 race condition 방지 (await 중 두 번째 호출 차단)
    private var isHandling = false

    func handleNotification(
        alarmId: UUID,
        modeString: String?,
        fallbackVerseId: String,
        alertStyle: String = "soundAndVibration",
        soundId: String = "piano",
        volume: Float = 0.8
    ) async {
        alarmLog.info("📲 [Coordinator] handleNotification 진입 — alarmId: \(alarmId), stage: \(String(describing: self.stage)), isHandling: \(self.isHandling)")
        // stage 체크 + isHandling 플래그로 async 중 race condition 방지
        guard stage == .none, !isHandling else {
            alarmLog.warning("⚠️ [Coordinator] 중복 호출 무시 — stage: \(String(describing: self.stage)), isHandling: \(self.isHandling)")
            return
        }
        isHandling = true
        defer { isHandling = false }

        let mode = modeString.flatMap { AppMode(rawValue: $0) } ?? AppMode.current()
        let verse = await loadVerse(mode: mode, fallbackVerseId: fallbackVerseId)
        let image = await loadImage(mode: mode, verse: verse)
        activeVerse = verse
        activeImage = image
        activeAlarmId = alarmId
        activeMode = mode
        if activeWeather == nil {
            activeWeather = WeatherCacheManager().load()
        }
        let activeAlarm = alarmRepository.fetchAll().first(where: { $0.id == alarmId })
        activeSnoozeInterval = activeAlarm?.snoozeInterval ?? 5
        activeMission        = activeAlarm?.wakeMission    ?? "none"
        activeAlertStyle     = activeAlarm?.alertStyle     ?? alertStyle
        activeSoundId        = activeAlarm?.soundId        ?? soundId
        activeVolume         = activeAlarm?.volume         ?? volume
        snoozeCount = 0
        stage = .stage1
        alarmLog.info("✅ [Coordinator] stage = .stage1 완료 — appState: \(UIApplication.shared.applicationState.rawValue)")

        startAlarmFeedback()
        cancelBackupNotifications(for: alarmId)

        // iPhone은 requestSceneSessionActivation 미지원 (iPad 전용 멀티윈도우 API)
        // iOS 26 AlarmKit 이전까지: 백그라운드 오디오 소리 + 알림 배너가 최선
        // 사용자가 배너 탭 or FaceID+Raise to Wake 잠금해제 → 포그라운드 → stage1 렌더링됨
        alarmLog.info("ℹ️ [Coordinator] iPhone 백그라운드 알람 완료 — 소리 재생 중, 배너 탭 시 Stage1 표시")
    }

    /// 연속 알람 백업 알림 전체 취소
    private func cancelBackupNotifications(for alarmId: UUID) {
        var ids: [String] = []
        for day in 0...6 {
            ids.append("\(alarmId.uuidString)_day\(day)_backup1")
            ids.append("\(alarmId.uuidString)_day\(day)_backup2")
        }
        for i in 1...5 { ids.append("\(alarmId.uuidString)_once_backup\(i)") }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Stage Transitions

    /// Stage 1 → Stage 1.5(미션) 또는 Stage 2
    /// v5.1: 미션이 "none"이 아니면 Stage 1.5를 거침
    func dismissToStage2() {
        stopAlarmFeedback()  // Bug 2 수정
        if activeMission != "none" {
            stage = .stage1_5
        } else {
            stage = .stage2
        }
    }

    func completeMission() {
        stage = .stage2
    }

    /// Post-alarm Live Activity 종료
    @available(iOS 26.0, *)
    private func endPostAlarmLiveActivities() {
        Task {
            for activity in Activity<DVPostAlarmAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func dismissAll() {
        // SwiftUI safeAreaInset 버그 방지:
        // 뷰 전환 애니메이션 중 버튼 액션이 자동 실행되는 현상 차단
        // stage 세팅 후 최소 2초 경과해야 dismiss 허용
        let elapsed = Date().timeIntervalSince(stageSetAt)
        guard elapsed > 2.0 else {
            alarmLog.warning("⚠️ [Coordinator] dismissAll 차단 — stage 세팅 후 \(String(format: "%.1f", elapsed))초 (최소 2초 필요)")
            return
        }
        alarmLog.info("🛑 [Coordinator] dismissAll() 실행")
        stopAlarmFeedback()
        stage = .none
        activeVerse = nil
        activeImage = nil
        activeAlarmId = nil
        activeWeather = nil
        activeSnoozeInterval = 5
        activeMission    = "none"
        activeAlertStyle = "soundAndVibration"
        activeSoundId    = "song"
        activeVolume     = 0.8
        activeMode       = AppMode.current()
        snoozeCount = 0
    }

    /// Edge Case 7: snoozeCount >= 3 이면 canSnooze == false → 버튼 비활성화
    func snooze() {
        guard canSnooze,
              let alarmId = activeAlarmId,
              let verse = activeVerse else { return }

        stopAlarmFeedback()  // Bug 2 수정
        snoozeCount += 1
        notificationManager.rescheduleSnooze(alarmId: alarmId, verse: verse, minutes: activeSnoozeInterval)
        stage = .none
    }

    // MARK: - Alarm Feedback (Bug 1/2/4/5 수정)

    /// Stage 1 진입 시 alertStyle에 따라 소리/진동 시작
    private func startAlarmFeedback() {
        switch activeAlertStyle {
        case "vibration":
            notificationManager.startAlarmAudio(soundId: "vibration", volume: 0)
        case "soundAndVibration":
            notificationManager.startAlarmAudio(soundId: activeSoundId, volume: activeVolume)
            notificationManager.addVibrationLoop()  // stopAudio 없이 진동만 추가
        case "sound":
            notificationManager.startAlarmAudio(soundId: activeSoundId, volume: activeVolume)
        default:
            notificationManager.startAlarmAudio(soundId: activeSoundId, volume: activeVolume)
        }
    }

    private func stopAlarmFeedback() {
        notificationManager.stopAlarmAudio()
    }

    // MARK: - Private Helpers

    /// 알람 발동 시 말씀 로드 우선순위:
    /// 1. 오늘의 mode 캐시 (DailyVerseCache + Core Data)
    /// 2. Firestore에서 mode 기반 선택
    /// 3. fallbackVerseId로 Core Data 캐시 조회
    /// 4. 번들 폴백 (Edge Case 2, 9)
    private func loadVerse(mode: AppMode, fallbackVerseId: String) async -> Verse {
        // 1. 오늘의 mode 캐시 확인 — 가장 최신 일별 말씀
        if let cachedId = DailyCacheManager.shared.getVerseId(for: mode),
           let verse = DailyCacheManager.shared.loadCachedVerse(id: cachedId) {
            return verse
        }
        // 2. Firestore에서 mode 기반 선택 (온라인 시)
        if let verses = try? await verseRepository.fetchVerses() {
            let selector = VerseSelector()
            if let selected = selector.select(from: verses, mode: mode, weather: nil) {
                DailyCacheManager.shared.setVerseId(selected.id, for: mode)
                return selected
            }
        }
        // 3. fallbackVerseId로 Core Data 캐시 조회
        if !fallbackVerseId.isEmpty,
           let cached = DailyCacheManager.shared.loadCachedVerse(id: fallbackVerseId) {
            return cached
        }
        // 4. 번들 폴백 (Edge Case 2, 9)
        return fallbackVerse(for: mode)
    }

    /// 이미지 선택 — mode + verse 테마/분위기 기반 스코어링 (HomeViewModel과 동일 알고리즘)
    private func loadImage(mode: AppMode, verse: Verse) async -> VerseImage? {
        guard let images = try? await verseRepository.fetchImages() else { return nil }

        let active = images.filter { $0.status == "active" }
        guard !active.isEmpty else { return nil }

        let season = currentSeasonTag()
        let weatherCondition = activeWeather?.condition ?? "any"

        let modeFiltered = active.filter { mode.matchesImageMode($0.mode) }
        let pool = modeFiltered.isEmpty ? active : modeFiltered

        let scored = pool.map { image -> (VerseImage, Int) in
            var score = 0
            score += image.theme.contains("all") ? 3 : image.theme.filter { verse.theme.contains($0) }.count * 3
            score += image.mood.contains("all") ? 2 : image.mood.filter { mode.moods.contains($0) }.count * 2
            if image.weather.contains(weatherCondition) || image.weather.contains("any") { score += 2 }
            if image.season.contains(season) || image.season.contains("all") { score += 1 }
            // 톤 우선순위: AppMode.preferredImageTone 활용 (8 Zone 대응)
            let preferredTone = mode.preferredImageTone
            if image.tone == preferredTone { score += 2 } else if image.tone == "mid" { score += 1 }
            return (image, score)
        }

        let maxScore = scored.map { $0.1 }.max() ?? 0
        let topImages = scored.filter { $0.1 == maxScore }.map { $0.0 }
        return topImages.randomElement()
    }

    private func currentSeasonTag() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "autumn"
        default: return "winter"
        }
    }

    private func fallbackVerse(for mode: AppMode) -> Verse {
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
}
