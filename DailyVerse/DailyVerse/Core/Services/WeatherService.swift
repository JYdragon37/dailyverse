import Foundation
import WeatherKit
import CoreLocation

protocol WeatherServiceProtocol {
    func fetchWeather(for location: CLLocation) async throws -> WeatherData
}

class WeatherService: WeatherServiceProtocol {
    private let weatherKitService = WeatherKit.WeatherService.shared
    private let cacheManager = WeatherCacheManager()

    func fetchWeather(for location: CLLocation) async throws -> WeatherData {
        // 1. 유효 캐시 확인 (30분)
        if let cached = cacheManager.load(), cached.isValid {
            return cached
        }

        // 2. WeatherKit 시도
        do {
            let data = try await fetchFromWeatherKit(location: location)
            cacheManager.save(data)
            return data
        } catch {
            // 3. OpenWeatherMap 폴백
            do {
                let data = try await fetchFromOpenWeatherMap(location: location)
                cacheManager.save(data)
                return data
            } catch {
                // 4. 캐시 만료됐더라도 반환
                if let stale = cacheManager.load() { return stale }
                throw WeatherError.unavailable
            }
        }
    }

    // MARK: - WeatherKit

    private func fetchFromWeatherKit(location: CLLocation) async throws -> WeatherData {
        let weather = try await weatherKitService.weather(for: location)
        let current = weather.currentWeather
        let hourly = weather.hourlyForecast

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let tomorrowForecast = tomorrow.flatMap { tomorrowDate in
            hourly.first { forecast in
                let components = Calendar.current.dateComponents([.hour], from: forecast.date)
                return Calendar.current.isDate(forecast.date, inSameDayAs: tomorrowDate)
                    && (components.hour ?? 0) == 6
            }
        }

        let cityName = await reverseGeocode(location) ?? "현재 위치"

        return WeatherData(
            temperature: Int(current.temperature.converted(to: .celsius).value.rounded()),
            condition: mapWeatherKitCondition(current.condition),
            conditionKo: mapWeatherKitConditionKo(current.condition),
            humidity: Int((current.humidity * 100).rounded()),
            dustGrade: "보통",
            cityName: cityName,
            cachedAt: Date(),
            tomorrowMorningTemp: tomorrowForecast.map { Int($0.temperature.converted(to: .celsius).value.rounded()) },
            tomorrowMorningCondition: tomorrowForecast.map { mapWeatherKitCondition($0.condition) },
            tomorrowMorningConditionKo: tomorrowForecast.map { mapWeatherKitConditionKo($0.condition) }
        )
    }

    private func mapWeatherKitCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy: return "sunny"
        case .cloudy, .mostlyCloudy: return "cloudy"
        case .rain, .heavyRain, .drizzle, .freezingRain, .freezingDrizzle: return "rainy"
        case .snow, .heavySnow, .blowingSnow, .sleet, .wintryMix: return "snowy"
        default: return "any"
        }
    }

    private func mapWeatherKitConditionKo(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy: return "맑음"
        case .cloudy, .mostlyCloudy: return "흐림"
        case .rain, .heavyRain, .drizzle: return "비"
        case .snow, .heavySnow, .blowingSnow: return "눈"
        default: return "보통"
        }
    }

    // MARK: - OpenWeatherMap Fallback

    private func fetchFromOpenWeatherMap(location: CLLocation) async throws -> WeatherData {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        // API Key는 Info.plist OPENWEATHER_API_KEY 또는 하드코딩 (개발 중)
        let apiKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty else { throw WeatherError.noApiKey }

        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=kr"
        guard let url = URL(string: urlString) else { throw WeatherError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OWMCurrentResponse.self, from: data)

        return WeatherData(
            temperature: Int(response.main.temp.rounded()),
            condition: mapOWMId(response.weather.first?.id ?? 800),
            conditionKo: response.weather.first?.description ?? "보통",
            humidity: response.main.humidity,
            dustGrade: "보통",
            cityName: response.name,
            cachedAt: Date()
        )
    }

    private func mapOWMId(_ id: Int) -> String {
        switch id {
        case 200...299: return "rainy"
        case 300...399: return "rainy"
        case 500...599: return "rainy"
        case 600...699: return "snowy"
        case 700...799: return "cloudy"
        case 800: return "sunny"
        case 801...804: return "cloudy"
        default: return "any"
        }
    }

    // MARK: - Geocoding

    private func reverseGeocode(_ location: CLLocation) async -> String? {
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let name = placemarks?.first.flatMap {
                    [$0.locality, $0.subLocality].compactMap { $0 }.joined(separator: " ")
                }
                continuation.resume(returning: name?.isEmpty == false ? name : nil)
            }
        }
    }
}

// MARK: - OWM Response Models

private struct OWMCurrentResponse: Codable {
    let main: OWMMain
    let weather: [OWMWeather]
    let name: String

    struct OWMMain: Codable {
        let temp: Double
        let humidity: Int
    }
    struct OWMWeather: Codable {
        let id: Int
        let description: String
    }
}

enum WeatherError: Error, LocalizedError {
    case unavailable
    case invalidURL
    case noApiKey

    var errorDescription: String? {
        switch self {
        case .unavailable: return "날씨 정보를 불러올 수 없습니다."
        case .invalidURL: return "잘못된 URL입니다."
        case .noApiKey: return "API 키가 없습니다."
        }
    }
}
