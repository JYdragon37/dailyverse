import SwiftUI
import Combine

@MainActor
final class AlarmCoordinator: ObservableObject {

    enum AlarmStage: Equatable {
        case none
        case stage1
        case stage1_5   // v5.1: 웨이크업 미션 수행
        case stage2
    }

    @Published var stage: AlarmStage = .none
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
    }

    // MARK: - Notification Handling

    /// NotificationCenter 딕셔너리를 파싱해 알람을 처리합니다.
    func handleNotification(from userInfo: [AnyHashable: Any]) async {
        guard
            let alarmIdString = userInfo["alarm_id"] as? String,
            let alarmId = UUID(uuidString: alarmIdString)
        else { return }

        let modeString   = userInfo["mode"] as? String
        let verseId      = userInfo["verse_id"] as? String ?? ""
        // Bug 3 수정: alertStyle, soundId, volume을 userInfo에서 읽기
        let alertStyle   = userInfo["alert_style"] as? String ?? "soundAndVibration"
        let soundId      = userInfo["sound_id"] as? String ?? "piano"
        let volume       = (userInfo["volume"] as? NSNumber)?.floatValue ?? 0.8

        await handleNotification(
            alarmId: alarmId,
            modeString: modeString,
            fallbackVerseId: verseId,
            alertStyle: alertStyle,
            soundId: soundId,
            volume: volume
        )
    }

    /// alarmId + mode로 Stage 1을 표시합니다.
    /// 오늘의 캐시된 말씀 우선, 없으면 verseId → 번들 폴백 순으로 로드.
    /// Edge Case 6: 복수 알람 동시 발동 — stage != .none 이면 가장 최근 것만 유지
    func handleNotification(
        alarmId: UUID,
        modeString: String?,
        fallbackVerseId: String,
        alertStyle: String = "soundAndVibration",
        soundId: String = "piano",
        volume: Float = 0.8
    ) async {
        guard stage == .none else { return }

        let mode = modeString.flatMap { AppMode(rawValue: $0) } ?? AppMode.current()
        let verse = await loadVerse(mode: mode, fallbackVerseId: fallbackVerseId)
        let image = await loadImage(mode: mode, verse: verse)
        activeVerse = verse
        activeImage = image
        activeAlarmId = alarmId
        activeMode = mode
        // 캐시된 날씨 로드 (Stage 2 날씨 위젯용)
        if activeWeather == nil {
            activeWeather = WeatherCacheManager().load()
        }
        let activeAlarm = alarmRepository.fetchAll().first(where: { $0.id == alarmId })
        activeSnoozeInterval = activeAlarm?.snoozeInterval ?? 5
        activeMission        = activeAlarm?.wakeMission    ?? "none"
        // Bug 3 수정: 실제 알람 설정값 우선, 없으면 userInfo 값 사용
        activeAlertStyle     = activeAlarm?.alertStyle     ?? alertStyle
        activeSoundId        = activeAlarm?.soundId        ?? soundId
        activeVolume         = activeAlarm?.volume         ?? volume
        snoozeCount = 0
        stage = .stage1

        // Bug 1 수정: Stage 1 진입 시 소리/진동 시작
        startAlarmFeedback()
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

    func dismissAll() {
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

        let modeFiltered = active.filter {
            $0.mode.contains(mode.rawValue) || $0.mode.contains("all")
        }
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
