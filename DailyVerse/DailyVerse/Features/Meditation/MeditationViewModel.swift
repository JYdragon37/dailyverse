import SwiftUI

@MainActor
final class MeditationViewModel: ObservableObject {

    @Published var todayEntry: MeditationEntry?
    @Published var history: [MeditationEntry] = []
    @Published var isLoading = false
    @Published var toastMessage: String?
    @Published var showWriteSheet = false
    @Published var todayVerse: Verse? = nil

    private let repository: MeditationRepository
    let streakManager: StreakManager

    init(repository: MeditationRepository = MeditationRepository()) {
        self.repository = repository
        self.streakManager = StreakManager.shared
    }

    // MARK: - Load

    func load(userId: String) async {
        isLoading = true
        await loadTodayVerse()
        // 오프라인 대기 항목 온라인 복구 시 자동 동기화
        await repository.flushPendingIfNeeded()
        async let today    = repository.fetchToday(userId: userId)
        async let hist     = repository.fetchHistory(userId: userId, limit: 30)
        async let dateKeys = repository.fetchThisMonthDateKeys(userId: userId)
        let loadedToday = await today
        let loadedHist  = await hist
        _ = await dateKeys  // 미사용이지만 async let 완료 대기
        todayEntry = loadedToday
        history    = loadedHist
        // history에서 직접 계산 → 월 경계 문제 없이 28일 커버
        let meditatedDates = Set(loadedHist.map { $0.dateKey })
        streakManager.updateMeditatedDates(meditatedDates)
        streakManager.checkAndResetIfBroken()
        isLoading = false
    }

    // MARK: - Today Verse

    func loadTodayVerse() async {
        let mode = AppMode.current()
        // 1. 캐시 우선 (홈 탭과 동일한 말씀 보장)
        if let cachedId = DailyCacheManager.shared.getVerseId(for: mode),
           let cached = DailyCacheManager.shared.loadCachedVerse(id: cachedId) {
            todayVerse = cached
            return
        }
        // 2. 캐시 없을 때 — 홈과 동일한 조건으로 선택해야 같은 말씀이 나옴
        //    weather: nil 대신 WeatherCache를 전달해 홈 VerseSelector 점수와 일치시킴
        let cachedWeather = WeatherCacheManager().load()
        let verse = await VerseRepository.shared.currentVerse(for: mode, weather: cachedWeather)
        todayVerse = verse
    }

    // MARK: - Quick Save (Toss-style 원스텝)

    func saveQuick(text: String, userId: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let uid = userId.isEmpty ? "local" : userId
        let newItem = PrayerItem.make(text: trimmed)

        // 오늘 묵상이 이미 있으면 prayerItems에 추가(업데이트)
        if var existing = todayEntry {
            existing.prayerItems.append(newItem)
            existing.updatedAt = Date()
            do {
                try await repository.save(existing)
                applyEntry(existing, userId: uid)
            } catch {
                applyEntry(existing, userId: uid)
                showToast("📶 오프라인 상태예요. 연결되면 자동으로 저장돼요")
                return
            }
            showToast("오늘도 말씀 앞에 섰어요 🙏")
        } else {
            // 없으면 새 MeditationEntry 생성
            let mode = AppMode.current()
            let verseId = DailyCacheManager.shared.getVerseId(for: mode) ?? ""
            let verseRef = todayVerse?.reference ?? ""
            let imgUrl = await randomImageUrl(for: mode)
            let entry = MeditationEntry.make(
                userId: uid,
                verseId: verseId,
                verseReference: verseRef,
                mode: mode.rawValue,
                prayerItems: [newItem],
                gratitudeNote: nil,
                imageUrl: imgUrl,
                locationName: cachedCityName(),
                source: "quick"
            )
            do {
                try await repository.save(entry)
                applyEntry(entry, userId: uid)
            } catch {
                applyEntry(entry, userId: uid)
                showToast("📶 오프라인 상태예요. 연결되면 자동으로 저장돼요")
                return
            }
            showToast("오늘도 말씀 앞에 섰어요 🙏")
        }
    }

    // MARK: - Read Only Save ("읽었어요" — 입력 없이 저장)

    func saveRead(userId: String) async {
        guard todayEntry == nil else { return }  // 이미 오늘 기록 있으면 무시
        let uid = userId.isEmpty ? "local" : userId
        let mode = AppMode.current()
        let verseId = DailyCacheManager.shared.getVerseId(for: mode) ?? ""
        let imgUrl = await randomImageUrl(for: mode)
        let entry = MeditationEntry.make(
            userId: uid,
            verseId: verseId,
            verseReference: todayVerse?.reference ?? "",
            mode: mode.rawValue,
            prayerItems: [],          // 텍스트 없음 — 읽음만
            gratitudeNote: nil,
            imageUrl: imgUrl,
            locationName: cachedCityName(),
            source: "read_only"
        )
        do {
            try await repository.save(entry)
            applyEntry(entry, userId: uid)
        } catch {
            applyEntry(entry, userId: uid)
        }
        showToast("말씀을 읽었어요 ✓")
    }

    // MARK: - Full Save (WriteSheet)

    func saveEntry(
        userId: String,
        verseId: String,
        verseReference: String,
        mode: String,
        prayerItems: [PrayerItem],
        gratitudeNote: String?,
        source: String = "manual"
    ) async {
        let uid = userId.isEmpty ? "local" : userId
        let appMode = AppMode(rawValue: mode) ?? AppMode.current()
        let imgUrl = await randomImageUrl(for: appMode)
        let entry = MeditationEntry.make(
            userId: uid,
            verseId: verseId,
            verseReference: verseReference,
            mode: mode,
            prayerItems: prayerItems,
            gratitudeNote: gratitudeNote,
            imageUrl: imgUrl,
            locationName: cachedCityName(),
            source: source
        )
        do {
            try await repository.save(entry)
            applyEntry(entry, userId: userId)
            showToast("오늘도 말씀 앞에 섰어요 🙏")
        } catch {
            applyEntry(entry, userId: userId)
            showToast("📶 오프라인 상태예요. 연결되면 자동으로 저장돼요")
        }
        showWriteSheet = false
    }

    private func applyEntry(_ entry: MeditationEntry, userId: String) {
        todayEntry = entry
        history.removeAll { $0.dateKey == entry.dateKey }
        history.insert(entry, at: 0)
        streakManager.recordMeditation()
        // 오늘 묵상 완료 → 저녁 리마인더 취소 (saveQuick/saveRead/saveEntry 공통)
        NotificationManager.shared.cancelTodayMeditationReminder()
        Task {
            let keys = await repository.fetchThisMonthDateKeys(userId: userId)
            streakManager.updateMeditatedDates(keys)
        }
    }

    // MARK: - Toggle Answered

    func toggleAnswered(item: PrayerItem, in entry: MeditationEntry) async {
        guard var updated = findEntry(id: entry.id) else { return }
        guard let idx = updated.prayerItems.firstIndex(where: { $0.id == item.id }) else { return }

        if updated.prayerItems[idx].isAnswered {
            updated.prayerItems[idx].unmarkAnswered()
        } else {
            updated.prayerItems[idx].markAnswered()
            showToast("🙏 기도에 응답하셨네요")
        }
        updated.updatedAt = Date()
        try? await repository.save(updated)
        updateLocal(updated)
    }

    // MARK: - Guided Save (4화면 플로우 완료)

    func saveGuided(userId: String, prayer: String, readingText: String) async {
        let uid = userId.isEmpty ? "local" : userId
        let mode = AppMode.current()
        // todayVerse?.id 우선 — 실제 화면에 표시된 말씀 ID를 직접 사용
        // DailyCacheManager 타이밍 이슈로 빈 문자열이 저장되는 버그 방지
        let verseId = todayVerse?.id ?? DailyCacheManager.shared.getVerseId(for: mode) ?? ""
        let verseRef = todayVerse?.reference ?? ""

        if var existing = todayEntry {
            existing.prayer = prayer.isEmpty ? nil : prayer
            existing.readingText = readingText.isEmpty ? nil : readingText
            existing.updatedAt = Date()
            do {
                try await repository.save(existing)
                applyEntry(existing, userId: uid)
            } catch {
                applyEntry(existing, userId: uid)
                showToast("📶 오프라인 상태예요. 연결되면 자동으로 저장돼요")
                return
            }
        } else {
            let imgUrl = await randomImageUrl(for: mode)
            let entry = MeditationEntry.make(
                userId: uid,
                verseId: verseId,
                verseReference: verseRef,
                mode: mode.rawValue,
                prayerItems: [],
                gratitudeNote: nil,
                prayer: prayer,
                readingText: readingText,
                imageUrl: imgUrl,
                locationName: cachedCityName(),
                source: "guided"
            )
            do {
                try await repository.save(entry)
                applyEntry(entry, userId: uid)
            } catch {
                applyEntry(entry, userId: uid)
                showToast("📶 오프라인 상태예요. 연결되면 자동으로 저장돼요")
                return
            }
        }
    }

    // MARK: - Random Image URL

    /// 날씨 캐시에서 도시명 반환 (저장 당시 위치 기록용, 영문)
    private func cachedCityName() -> String? {
        WeatherCacheManager().load()?.cityName
    }

    /// 현재 모드에 맞는 이미지 중 랜덤 선택 (저장 당시 배경 이미지 기록용)
    private func randomImageUrl(for mode: AppMode) async -> String? {
        guard let images = try? await VerseRepository.shared.fetchImages() else { return nil }
        let modeMatched = images.filter {
            $0.status == "active" && ($0.mode.contains(mode.rawValue) || $0.mode.contains("all"))
        }
        let pool = modeMatched.isEmpty ? images.filter { $0.status == "active" } : modeMatched
        return pool.randomElement()?.storageUrl
    }

    // MARK: - History Access Control (v5.1: 단일플랜 → 항상 잠금 없음)

    func isLocked(_ entry: MeditationEntry, isPremium: Bool) -> Bool {
        return false
    }

    // MARK: - Toast

    func showToast(_ message: String) {
        toastMessage = message
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            self?.toastMessage = nil
        }
    }

    // MARK: - Private Helpers

    private func findEntry(id: String) -> MeditationEntry? {
        if todayEntry?.id == id { return todayEntry }
        return history.first { $0.id == id }
    }

    private func updateLocal(_ entry: MeditationEntry) {
        if entry.isToday { todayEntry = entry }
        if let i = history.firstIndex(where: { $0.id == entry.id }) { history[i] = entry }
    }
}
