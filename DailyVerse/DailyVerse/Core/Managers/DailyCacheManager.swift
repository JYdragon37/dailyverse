import Foundation
import CoreData
import Combine

class DailyCacheManager {
    static let shared = DailyCacheManager()
    private let cacheKey = "dailyVerseCache_v2"  // v5.1: 4모드 캐시 키 변경

    // MARK: - Verse ID

    func getVerseId(for mode: AppMode) -> String? {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return nil }
        return cache.verseId(for: mode)
    }

    func setVerseId(_ verseId: String, for mode: AppMode) {
        var cache = loadCache() ?? DailyVerseCache(
            date: Date(),
            morningVerseId: nil, afternoonVerseId: nil,
            eveningVerseId: nil, dawnVerseId: nil,
            morningImageId: nil, afternoonImageId: nil,
            eveningImageId: nil, dawnImageId: nil
        )
        cache.setVerseId(verseId, for: mode)
        saveCache(cache)
    }

    // MARK: - Image ID (v5.1)

    func getImageId(for mode: AppMode) -> String? {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return nil }
        return cache.imageId(for: mode)
    }

    func setImageId(_ imageId: String, for mode: AppMode) {
        var cache = loadCache() ?? DailyVerseCache(
            date: Date(),
            morningVerseId: nil, afternoonVerseId: nil,
            eveningVerseId: nil, dawnVerseId: nil,
            morningImageId: nil, afternoonImageId: nil,
            eveningImageId: nil, dawnImageId: nil
        )
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
