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
    @Published var activeWeather: WeatherData?

    private var snoozeCount: Int = 0
    private let notificationManager: NotificationManager
    private let verseRepository: VerseRepository

    var canSnooze: Bool { snoozeCount < 3 }

    init(
        notificationManager: NotificationManager = .shared,
        verseRepository: VerseRepository = VerseRepository()
    ) {
        self.notificationManager = notificationManager
        self.verseRepository = verseRepository
    }

    // MARK: - Notification Handling

    /// NotificationCenter 딕셔너리를 파싱해 알람을 처리합니다.
    func handleNotification(from userInfo: [AnyHashable: Any]) async {
        guard
            let alarmIdString = userInfo["alarm_id"] as? String,
            let alarmId = UUID(uuidString: alarmIdString),
            let verseId = userInfo["verse_id"] as? String
        else { return }

        await handleNotification(alarmId: alarmId, verseId: verseId)
    }

    /// alarmId + verseId로 Stage 1을 표시합니다.
    /// Edge Case 6: 복수 알람 동시 발동 — stage != .none 이면 가장 최근 것만 유지
    func handleNotification(alarmId: UUID, verseId: String) async {
        guard stage == .none else { return }

        let verse = await loadVerse(verseId: verseId)
        activeVerse = verse
        activeAlarmId = alarmId
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
        activeAlarmId = nil
        activeWeather = nil
        snoozeCount = 0
    }

    /// Edge Case 7: snoozeCount >= 3 이면 canSnooze == false → 버튼 비활성화
    func snooze() {
        guard canSnooze,
              let alarmId = activeAlarmId,
              let verse = activeVerse else { return }

        snoozeCount += 1
        // Edge Case 3: rescheduleSnooze는 UNNotificationRequest를 시스템에 등록하므로
        //              앱 강제 종료 후에도 5분 후 자동 발동 보장
        notificationManager.rescheduleSnooze(alarmId: alarmId, verse: verse)
        stage = .none
    }

    // MARK: - Private Helpers

    /// Edge Case 2: 오프라인 또는 캐시 없음 → 번들 폴백 구절 사용
    /// Edge Case 9: 캐시도 없는 오프라인 → Verse.fallbackVerses에서 모드 매칭
    private func loadVerse(verseId: String) async -> Verse {
        // 1. DailyCacheManager에서 Core Data 캐시 조회 (오프라인 대응)
        if let cached = DailyCacheManager.shared.loadCachedVerse(id: verseId) {
            return cached
        }
        // 2. VerseRepository에서 Firestore 조회
        if let verses = try? await verseRepository.fetchVerses(),
           let found = verses.first(where: { $0.id == verseId }) {
            return found
        }
        // 3. 번들 폴백 — verseId 접두사로 모드 추정
        let mode = AppMode.current()
        return fallbackVerse(for: mode)
    }

    private func fallbackVerse(for mode: AppMode) -> Verse {
        switch mode {
        case .morning: return Verse.fallbackMorning
        case .afternoon: return Verse.fallbackAfternoon
        case .evening: return Verse.fallbackEvening
        }
    }
}
