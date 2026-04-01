import Foundation
import CoreData

class WeatherCacheManager {
    private let context = PersistenceController.shared.context

    func load() -> WeatherData? {
        let request = CachedWeather.fetchRequest()
        guard let entity = try? context.fetch(request).first,
              let json = entity.json,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WeatherData.self, from: data)
    }

    func save(_ weatherData: WeatherData) {
        // 기존 캐시 삭제
        let request = CachedWeather.fetchRequest()
        if let existing = try? context.fetch(request) {
            existing.forEach { context.delete($0) }
        }
        // 새 캐시 저장
        let entity = CachedWeather(context: context)
        if let encoded = try? JSONEncoder().encode(weatherData) {
            entity.json = String(data: encoded, encoding: .utf8)
        }
        entity.cachedAt = Date()
        PersistenceController.shared.save()
    }

    func clear() {
        let request = CachedWeather.fetchRequest()
        if let existing = try? context.fetch(request) {
            existing.forEach { context.delete($0) }
            PersistenceController.shared.save()
        }
    }
}
