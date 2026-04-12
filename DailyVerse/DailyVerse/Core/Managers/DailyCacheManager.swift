import Foundation
import CoreData
import Combine

class DailyCacheManager {
    static let shared = DailyCacheManager()
    private let cacheKey = "dailyVerseCache_v6"  // v6: todayVerseId 추가 (하루 1개 verse 통일)

    /// Core Data verse JSON 캐시 스키마 버전
    /// 버전이 다르면 CachedVerse 전체 삭제 → Firestore에서 최신 데이터 재취득
    private static let verseSchemVersion = "verse_cache_v2"
    private static let verseSchemaKey    = "cachedVerseSchemaVersion"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.verseSchemaKey)
        if stored != Self.verseSchemVersion {
            clearAllCachedVerses()
            UserDefaults.standard.set(Self.verseSchemVersion, forKey: Self.verseSchemaKey)
        }
    }

    private func clearAllCachedVerses() {
        let context = PersistenceController.shared.context
        let request = CachedVerse.fetchRequest()
        if let all = try? context.fetch(request) {
            all.forEach { context.delete($0) }
            PersistenceController.shared.save()
        }
    }

    // MARK: - Today Verse ID (하루 1개 — 모든 탭 공유)

    /// 오늘의 verse ID 조회 (04:00 기준 일일 고정)
    func getTodayVerseId() -> String? {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return nil }
        return cache.todayVerseId
    }

    /// 오늘의 verse ID 저장 (최초 1회 결정 후 하루 동안 변경 없음)
    func setTodayVerseId(_ verseId: String) {
        var cache = loadCache() ?? DailyVerseCache(date: Date())
        cache.todayVerseId = verseId
        saveCache(cache)
    }

    // MARK: - Verse ID (Zone별 — 레거시 호환)

    func getVerseId(for mode: AppMode) -> String? {
        // 하루 1개 verse 우선, 없으면 Zone별 폴백
        if let todayId = getTodayVerseId() { return todayId }
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return nil }
        return cache.verseId(for: mode)
    }

    func setVerseId(_ verseId: String, for mode: AppMode) {
        var cache = loadCache() ?? DailyVerseCache(date: Date())
        cache.todayVerseId = verseId  // 항상 todayVerseId도 동시 세팅
        cache.setVerseId(verseId, for: mode)
        saveCache(cache)
    }

    // MARK: - Image ID (v5.1)

    func getImageId(for mode: AppMode) -> String? {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return nil }
        return cache.imageId(for: mode)
    }

    func setImageId(_ imageId: String, for mode: AppMode) {
        var cache = loadCache() ?? DailyVerseCache(date: Date())
        cache.setImageId(imageId, for: mode)
        saveCache(cache)
    }

    // MARK: - 유효성 확인

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    func hasValidCache() -> Bool {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return false }
        return cache.hasAnyVerse
    }

    // MARK: - Core Data verse cache

    func cacheVerse(_ verse: Verse) {
        let context = PersistenceController.shared.context
        let request = CachedVerse.fetchRequest()
        request.predicate = NSPredicate(format: "verseId == %@", verse.id)

        if let existing = try? context.fetch(request).first {
            context.delete(existing)
        }
        let entity = CachedVerse(context: context)
        entity.verseId = verse.id
        entity.cachedAt = Date()
        if let encoded = try? JSONEncoder().encode(verse) {
            entity.json = String(data: encoded, encoding: .utf8)
        }
        PersistenceController.shared.save()
    }

    func loadCachedVerse(id: String) -> Verse? {
        let context = PersistenceController.shared.context
        let request = CachedVerse.fetchRequest()
        request.predicate = NSPredicate(format: "verseId == %@", id)
        guard let entity = try? context.fetch(request).first,
              let json = entity.json,
              let data = json.data(using: .utf8) else { return nil }
        // 24시간 TTL: 만료 시 삭제 → fetchVerses()가 Firestore에서 최신 데이터 재취득
        if let cachedAt = entity.cachedAt, Date().timeIntervalSince(cachedAt) > 86400 {
            context.delete(entity)
            PersistenceController.shared.save()
            return nil
        }
        return try? JSONDecoder().decode(Verse.self, from: data)
    }

    /// alarm_top_ko가 있는 구절 전체 로드 (알람 탭 Random Access 풀)
    func loadAlarmTopKoPool(excluding currentId: String?) -> [Verse] {
        let context = PersistenceController.shared.context
        let request = CachedVerse.fetchRequest()
        guard let entities = try? context.fetch(request) else { return [] }

        return entities.compactMap { entity -> Verse? in
            guard let json = entity.json,
                  let data = json.data(using: .utf8),
                  let verse = try? JSONDecoder().decode(Verse.self, from: data) else { return nil }
            // alarm_top_ko가 있고, 현재 표시 중인 구절 제외
            guard let alarmTopKo = verse.alarmTopKo, !alarmTopKo.isEmpty else { return nil }
            if let currentId, verse.id == currentId { return nil }
            return verse
        }
    }

    // MARK: - Private

    private func loadCache() -> DailyVerseCache? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(DailyVerseCache.self, from: data)
    }

    private func saveCache(_ cache: DailyVerseCache) {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
