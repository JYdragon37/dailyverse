import Foundation
import CoreData

class WeatherCacheManager {
    private let context = PersistenceController.shared.context
    /// 캐시 스키마 버전 — WeatherData 구조 변경 시 올려서 구 캐시 강제 무효화
    // v4: dailyForecast/uvIndex/precipitationProbability 필드 추가로 구 캐시 무효화
    private static let schemaVersion = "v4"
    private static let schemaKey = "weatherCacheSchemaVersion"

    init() {
        // 스키마 버전이 다르면 기존 캐시 전부 삭제
        let stored = UserDefaults.standard.string(forKey: Self.schemaKey)
        if stored != Self.schemaVersion {
            clear()
            UserDefaults.standard.set(Self.schemaVersion, forKey: Self.schemaKey)
        }
    }

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
