import SwiftUI
import Combine

@MainActor
final class AlarmCoordinator: ObservableObject {

    enum AlarmStage: Equatable {
        case none
        case stage1
        case stage2
    }

    @Published var stage: AlarmStage = .none
    @Published var activeAlarmId: UUID?
    @Published var activeVerse: Verse?
    @Published var activeImage: VerseImage?
    @Published var activeWeather: WeatherData?
    @Published var activeSnoozeInterval: Int = 5

    private var snoozeCount: Int = 0
    private let notificationManager: NotificationManager
    private let verseRepository: VerseRepository
    private let alarmRepository: AlarmRepository

    var canSnooze: Bool { snoozeCount < 3 }

    init(
        notificationManager: NotificationManager = .shared,
        verseRepository: VerseRepository = VerseRepository(),
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

        // mode가 있으면 오늘의 캐시된 말씀 우선 사용, 없으면 verse_id 폴백
        let modeString = userInfo["mode"] as? String
        let verseId = userInfo["verse_id"] as? String ?? ""
        await handleNotification(alarmId: alarmId, modeString: modeString, fallbackVerseId: verseId)
    }

    /// alarmId + mode로 Stage 1을 표시합니다.
    /// 오늘의 캐시된 말씀 우선, 없으면 verseId → 번들 폴백 순으로 로드.
    /// Edge Case 6: 복수 알람 동시 발동 — stage != .none 이면 가장 최근 것만 유지
    func handleNotification(alarmId: UUID, modeString: String?, fallbackVerseId: String) async {
        guard stage == .none else { return }

        let mode = modeString.flatMap { AppMode(rawValue: $0) } ?? AppMode.current()
        let verse = await loadVerse(mode: mode, fallbackVerseId: fallbackVerseId)
        let image = await loadImage(mode: mode, verse: verse)
        activeVerse = verse
        activeImage = image
        activeAlarmId = alarmId
        // 알람의 스누즈 간격 로드 (없으면 기본값 5분)
        activeSnoozeInterval = alarmRepository.fetchAll()
            .first(where: { $0.id == alarmId })?.snoozeInterval ?? 5
        snoozeCount = 0
        stage = .stage1
    }

    // MARK: - Stage Transitions

    /// Stage 1 → Stage 2 (Fade-in 0.6s 애니메이션은 AppRootView에서 처리)
    func dismissToStage2() {
        stage = .stage2
    }

    /// Stage 전체 해제 — 홈 탭 복귀
    func dismissAll() {
        stage = .none
        activeVerse = nil
        activeImage = nil
        activeAlarmId = nil
        activeWeather = nil
        activeSnoozeInterval = 5
        snoozeCount = 0
    }

    /// Edge Case 7: snoozeCount >= 3 이면 canSnooze == false → 버튼 비활성화
    func snooze() {
        guard canSnooze,
              let alarmId = activeAlarmId,
              let verse = activeVerse else { return }

        snoozeCount += 1
        // Edge Case 3: rescheduleSnooze는 UNNotificationRequest를 시스템에 등록하므로
        //              앱 강제 종료 후에도 자동 발동 보장
        notificationManager.rescheduleSnooze(alarmId: alarmId, verse: verse, minutes: activeSnoozeInterval)
        stage = .none
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
            score += image.theme.filter { verse.theme.contains($0) }.count * 3
            score += image.mood.filter { mode.moods.contains($0) }.count * 2
            if image.weather.contains(weatherCondition) || image.weather.contains("any") { score += 2 }
            if image.season.contains(season) || image.season.contains("all") { score += 1 }
            // 톤 우선순위: 아침/낮 → bright/mid, 저녁 → dark
            switch mode {
            case .morning, .afternoon:
                if image.tone == "bright" { score += 2 } else if image.tone == "mid" { score += 1 }
            case .evening:
                if image.tone == "dark" { score += 2 } else if image.tone == "mid" { score += 1 }
            }
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
        case .morning: return Verse.fallbackMorning
        case .afternoon: return Verse.fallbackAfternoon
        case .evening: return Verse.fallbackEvening
        }
    }
}
