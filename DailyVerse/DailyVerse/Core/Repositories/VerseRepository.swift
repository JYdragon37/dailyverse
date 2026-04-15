import Foundation
import Combine

class VerseRepository {
    /// 싱글톤 — fetchVerses() 30분 TTL 캐시를 전역 공유하여 불필요한 API 호출 방지
    static let shared = VerseRepository()

    private let firestoreService = FirestoreService()
    private let cacheManager = DailyCacheManager.shared
    private let selector = VerseSelector()

    private var cachedVerses: [Verse] = []
    private var cachedImages: [VerseImage] = []
    private var lastFetched: Date?

    // MARK: - Verses

    /// 전체 말씀 로드 (캐시 우선, 30분 TTL)
    func fetchVerses() async throws -> [Verse] {
        if !cachedVerses.isEmpty, let last = lastFetched, Date().timeIntervalSince(last) < 1800 {
            return cachedVerses
        }
        let verses = try await firestoreService.fetchVerses()
        cachedVerses = verses
        lastFetched = Date()
        verses.forEach { cacheManager.cacheVerse($0) }
        return verses
    }

    /// 현재 모드 말씀 반환 (일별 고정)
    ///
    /// 선택 우선순위:
    /// 1. daily_cards/{오늘} 큐레이션 데이터
    /// 2. DailyVerseCache (오늘 이미 결정된 말씀)
    /// 3. Cooldown 통과 알고리즘 선택
    /// 4. 번들 폴백
    ///
    /// ⚠️ 일관성 보장 원칙:
    /// - 각 await 이후 반드시 캐시를 재확인 (double-check)
    ///   → 동시에 실행 중인 다른 Task가 먼저 캐시를 설정했으면 그 값을 사용
    ///   → 홈/묵상/알람 어느 경로로 호출해도 같은 날 같은 Zone은 같은 말씀 반환
    func currentVerse(for mode: AppMode, weather: WeatherData?) async -> Verse {

        // ── 캐시 재확인 헬퍼 (double-check locking) ──────────────────────────
        // await 이후 다른 Task가 먼저 캐시를 설정했을 수 있으므로 항상 재확인
        func cachedVerseIfExists() -> Verse? {
            guard let id = cacheManager.getVerseId(for: mode),
                  let v  = cacheManager.loadCachedVerse(id: id) else { return nil }
            return v
        }

        // 1-a. 빠른 경로: 이미 캐시에 있으면 즉시 반환
        if let v = cachedVerseIfExists() { return v }

        // 1-b. daily_cards 큐레이션 우선 (네트워크 await)
        if let card = try? await firestoreService.fetchDailyCard(for: Date(), mode: mode),
           let verseId = card.verseId {
            // await 완료 후 재확인 — 동시 Task가 이미 캐시를 설정했을 수 있음
            if let v = cachedVerseIfExists() { return v }

            if let cached = cacheManager.loadCachedVerse(id: verseId) {
                cacheManager.setVerseId(verseId, for: mode)
                return cached
            }
            if let verses = try? await fetchVerses() {
                // await 후 재확인
                if let v = cachedVerseIfExists() { return v }
                if let found = verses.first(where: { $0.id == verseId }) {
                    cacheManager.setVerseId(found.id, for: mode)
                    return found
                }
            }
        }

        // 2. 오늘의 캐시 확인 (verseId가 있으면 반드시 같은 verse 유지)
        if let cachedId = cacheManager.getVerseId(for: mode) {
            if let verse = cacheManager.loadCachedVerse(id: cachedId) {
                return verse
            }
            // Core Data TTL 만료 → Firestore에서 동일 verseId 재로드
            if let verses = try? await fetchVerses() {
                if let v = cachedVerseIfExists() { return v }  // 재확인
                if let found = verses.first(where: { $0.id == cachedId }) {
                    return found
                }
            }
        }

        // 3. Cooldown 알고리즘 선택 (캐시 없을 때만)
        if let verses = try? await fetchVerses() {
            // await 후 재확인 — 경쟁 Task가 먼저 선택했으면 그 결과 사용 (동일 말씀 보장)
            if let v = cachedVerseIfExists() { return v }

            if let selected = selector.select(from: verses, mode: mode, weather: weather) {
                cacheManager.setVerseId(selected.id, for: mode)
                Task { await self.firestoreService.markVerseAsShown(verseId: selected.id) }
                return selected
            }
        }

        // 4. 번들 폴백
        return fallbackVerse(for: mode)
    }

    /// [다음 말씀] — cooldown 통과한 구절 중 현재 제외 후 선택
    func nextVerse(excluding currentId: String, for mode: AppMode, weather: WeatherData?) async -> Verse? {
        guard let verses = try? await fetchVerses() else { return nil }
        let result = selector.selectNext(from: verses, excluding: currentId, mode: mode, weather: weather)
        if let result {
            Task { await self.firestoreService.markVerseAsShown(verseId: result.id) }
        }
        return result
    }

    // MARK: - Images

    func fetchImages() async throws -> [VerseImage] {
        if !cachedImages.isEmpty { return cachedImages }
        let images = try await firestoreService.fetchImages()
        cachedImages = images
        return images
    }

    // MARK: - Fallback

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
