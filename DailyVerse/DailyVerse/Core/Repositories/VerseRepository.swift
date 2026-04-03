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
        // Core Data에 각 말씀 캐시
        verses.forEach { cacheManager.cacheVerse($0) }
        return verses
    }

    /// 현재 모드 말씀 반환 (일별 고정)
    func currentVerse(for mode: AppMode, weather: WeatherData?) async -> Verse {
        // 1. 오늘의 캐시 확인
        if let cachedId = cacheManager.getVerseId(for: mode),
           let verse = cacheManager.loadCachedVerse(id: cachedId) {
            return verse
        }
        // 2. Firestore에서 로드 후 선택
        if let verses = try? await fetchVerses(),
           let selected = selector.select(from: verses, mode: mode, weather: weather) {
            cacheManager.setVerseId(selected.id, for: mode)
            return selected
        }
        // 3. 오프라인 폴백
        return fallbackVerse(for: mode)
    }

    /// Premium 다음 말씀
    func nextVerse(excluding currentId: String, for mode: AppMode, weather: WeatherData?) async -> Verse? {
        guard let verses = try? await fetchVerses() else { return nil }
        return selector.selectNext(from: verses, excluding: currentId, mode: mode, weather: weather)
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
