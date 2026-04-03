import Foundation
import Combine

class VerseRepository {
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
    /// v5.1 선택 우선순위:
    /// 1. daily_cards/{오늘} 큐레이션 데이터
    /// 2. DailyVerseCache (오늘 이미 결정된 말씀)
    /// 3. Cooldown 통과 알고리즘 선택
    /// 4. 번들 폴백
    func currentVerse(for mode: AppMode, weather: WeatherData?) async -> Verse {
        // 1. daily_cards 큐레이션 우선
        if let card = try? await firestoreService.fetchDailyCard(for: Date()),
           let verseId = card.verseId {
            if let cached = cacheManager.loadCachedVerse(id: verseId) {
                cacheManager.setVerseId(verseId, for: mode)
                return cached
            }
            if let verses = try? await fetchVerses(),
               let found = verses.first(where: { $0.id == verseId }) {
                cacheManager.setVerseId(found.id, for: mode)
                return found
            }
        }

        // 2. 오늘의 캐시 확인
        if let cachedId = cacheManager.getVerseId(for: mode),
           let verse = cacheManager.loadCachedVerse(id: cachedId) {
            return verse
        }

        // 3. Cooldown 알고리즘 선택
        if let verses = try? await fetchVerses(),
           let selected = selector.select(from: verses, mode: mode, weather: weather) {
            cacheManager.setVerseId(selected.id, for: mode)
            // v5.1: 노출 후 last_shown + show_count 업데이트 (비동기)
            Task { await self.firestoreService.markVerseAsShown(verseId: selected.id) }
            return selected
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
        case .morning:   return Verse.fallbackMorning
        case .afternoon: return Verse.fallbackAfternoon
        case .evening:   return Verse.fallbackEvening
        case .dawn:      return Verse.fallbackDawn
        }
    }
}
