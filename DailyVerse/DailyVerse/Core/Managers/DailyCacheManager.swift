import Foundation
import CoreData
import Combine

class DailyCacheManager {
    static let shared = DailyCacheManager()
    private let cacheKey = "dailyVerseCache"

    // MARK: - Public Interface

    func getVerseId(for mode: AppMode) -> String? {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return nil }
        switch mode {
        case .morning: return cache.morningVerseId
        case .afternoon: return cache.afternoonVerseId
        case .evening: return cache.eveningVerseId
        }
    }

    func setVerseId(_ verseId: String, for mode: AppMode) {
        let existing = loadCache()
        let base = DailyVerseCache(
            date: existing?.date ?? Date(),
            morningVerseId: existing?.morningVerseId,
            afternoonVerseId: existing?.afternoonVerseId,
            eveningVerseId: existing?.eveningVerseId
        )
        let updated: DailyVerseCache
        switch mode {
        case .morning:
            updated = DailyVerseCache(date: base.date, morningVerseId: verseId,
                                       afternoonVerseId: base.afternoonVerseId, eveningVerseId: base.eveningVerseId)
        case .afternoon:
            updated = DailyVerseCache(date: base.date, morningVerseId: base.morningVerseId,
                                       afternoonVerseId: verseId, eveningVerseId: base.eveningVerseId)
        case .evening:
            updated = DailyVerseCache(date: base.date, morningVerseId: base.morningVerseId,
                                       afternoonVerseId: base.afternoonVerseId, eveningVerseId: verseId)
        }
        saveCache(updated)
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    /// 오늘 날짜 기준으로 유효한 캐시가 하나라도 존재하는지 확인 (05:00 기준)
    func hasValidCache() -> Bool {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return false }
        return cache.morningVerseId != nil
            || cache.afternoonVerseId != nil
            || cache.eveningVerseId != nil
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
        return try? JSONDecoder().decode(Verse.self, from: data)
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
