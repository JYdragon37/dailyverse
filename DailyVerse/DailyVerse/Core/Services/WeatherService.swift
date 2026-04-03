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
        // hourlyForecast가 비어있는 구 캐시는 무시하고 새로 fetch
        if let cached = cacheManager.load(), cached.isValid, !cached.hourlyForecast.isEmpty {
            return cached
        }
        do {
            let data = try await fetchFromWeatherKit(location: location)
            cacheManager.save(data)
            return data
        } catch {
            do {
                let data = try await fetchFromOpenWeatherMap(location: location)
                cacheManager.save(data)
                return data
            } catch {
                if let stale = cacheManager.load() { return stale }
                throw WeatherError.unavailable
            }
        }
    }

    // MARK: - WeatherKit

    private func fetchFromWeatherKit(location: CLLocation) async throws -> WeatherData {
        let weather = try await weatherKitService.weather(for: location)
        let current = weather.currentWeather
        let hourly  = weather.hourlyForecast
        let daily   = weather.dailyForecast

        // 내일 아침 6시 예보
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let tomorrowForecast = tomorrow.flatMap { tomorrowDate in
            hourly.first {
                Calendar.current.isDate($0.date, inSameDayAs: tomorrowDate)
                && (Calendar.current.component(.hour, from: $0.date) == 6)
            }
        }

        // 오늘 최고/최저 기온
        let todayDaily = daily.forecast.first
        let highTemp = todayDaily.map { Int($0.highTemperature.converted(to: .celsius).value.rounded()) }
        let lowTemp  = todayDaily.map { Int($0.lowTemperature.converted(to: .celsius).value.rounded()) }

        // 시간별 예보 12개 (현재 시각 이후)
        let now = Date()
        let next12 = Array(hourly.forecast.filter { $0.date >= now }.prefix(12))
        let hourlyItems = next12.map { f in
            HourlyForecastItem(
                time: f.date,
                temperature: Int(f.temperature.converted(to: .celsius).value.rounded()),
                condition: mapWeatherKitCondition(f.condition),
                conditionKo: mapWeatherKitConditionKo(f.condition)
            )
        }

        // AQI — OWM Air Pollution API
        let apiKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
        let (aqiVal, aqiDesc) = await fetchAQI(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            apiKey: apiKey
        )

        // dustGrade 결정
        let dustGrade = aqiDesc ?? "보통"

        let cityName = await reverseGeocode(location) ?? "현재 위치"

        return WeatherData(
            temperature: Int(current.temperature.converted(to: .celsius).value.rounded()),
            condition: mapWeatherKitCondition(current.condition),
            conditionKo: mapWeatherKitConditionKo(current.condition),
            humidity: Int((current.humidity * 100).rounded()),
            dustGrade: dustGrade,
            cityName: cityName,
            cachedAt: Date(),
            tomorrowMorningTemp: tomorrowForecast.map { Int($0.temperature.converted(to: .celsius).value.rounded()) },
            tomorrowMorningCondition: tomorrowForecast.map { mapWeatherKitCondition($0.condition) },
            tomorrowMorningConditionKo: tomorrowForecast.map { mapWeatherKitConditionKo($0.condition) },
            highTemp: highTemp,
            lowTemp: lowTemp,
            hourlyForecast: hourlyItems,
            aqi: aqiVal,
            aqiDescription: aqiDesc
        )
    }

    // MARK: - AQI (OpenWeatherMap Air Pollution API)

    private func fetchAQI(lat: Double, lon: Double, apiKey: String) async -> (Int?, String?) {
        guard !apiKey.isEmpty,
              let url = URL(string: "https://api.openweathermap.org/data/2.5/air_pollution?lat=\(lat)&lon=\(lon)&appid=\(apiKey)") else {
            return (nil, nil)
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(OWMAirPollutionResponse.self, from: data),
              let item = response.list.first else {
            return (nil, nil)
        }
        let owmAqi = item.main.aqi  // 1(좋음)~5(매우나쁨)
        let aqiNum = owmAqi * 50    // 50~250
        let desc: String
        switch owmAqi {
        case 1:    desc = "좋음"
        case 2:    desc = "보통"
        case 3:    desc = "나쁨"
        default:   desc = "매우나쁨"
        }
        return (aqiNum, desc)
    }

    // MARK: - WeatherKit Condition Mapping

    private func mapWeatherKitCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy: return "sunny"
        case .cloudy, .mostlyCloudy:              return "cloudy"
        case .rain, .heavyRain, .drizzle, .freezingRain, .freezingDrizzle: return "rainy"
        case .snow, .heavySnow, .blowingSnow, .sleet, .wintryMix:          return "snowy"
        default: return "any"
        }
    }

    private func mapWeatherKitConditionKo(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy: return "맑음"
        case .cloudy, .mostlyCloudy:              return "흐림"
        case .rain, .heavyRain, .drizzle:         return "비"
        case .snow, .heavySnow, .blowingSnow:     return "눈"
        default: return "흐림"
        }
    }

    // MARK: - OpenWeatherMap Fallback

    private func fetchFromOpenWeatherMap(location: CLLocation) async throws -> WeatherData {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let apiKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty else { throw WeatherError.noApiKey }

        // 현재 날씨
        let currentUrl = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: currentUrl) else { throw WeatherError.invalidURL }
        let (currentData, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OWMCurrentResponse.self, from: currentData)
        let weatherId = response.weather.first?.id ?? 800

        // Fix 2/3: Forecast API — 최고/최저 + 시간별 예보 (5일/3시간)
        let forecastUrl = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&cnt=16"
        var highTemp: Int? = nil
        var lowTemp: Int? = nil
        var hourlyItems: [HourlyForecastItem] = []

        if let fUrl = URL(string: forecastUrl),
           let (fData, _) = try? await URLSession.shared.data(from: fUrl),
           let fResponse = try? JSONDecoder().decode(OWMForecastResponse.self, from: fData) {

            // 오늘 최고/최저 (다음 24시간 기준)
            let todayItems = fResponse.list.prefix(8)  // 8 × 3h = 24h
            highTemp = todayItems.map { Int($0.main.tempMax.rounded()) }.max()
            lowTemp  = todayItems.map { Int($0.main.tempMin.rounded()) }.min()

            // 시간별 예보 12개
            let now = Date()
            hourlyItems = fResponse.list
                .filter { Date(timeIntervalSince1970: TimeInterval($0.dt)) >= now }
                .prefix(12)
                .map { item in
                    HourlyForecastItem(
                        time: Date(timeIntervalSince1970: TimeInterval(item.dt)),
                        temperature: Int(item.main.temp.rounded()),
                        condition: mapOWMId(item.weather.first?.id ?? 800),
                        conditionKo: mapOWMIdKo(item.weather.first?.id ?? 800)
                    )
                }
        }

        let (aqiVal, aqiDesc) = await fetchAQI(lat: lat, lon: lon, apiKey: apiKey)

        return WeatherData(
            temperature: Int(response.main.temp.rounded()),
            condition: mapOWMId(weatherId),
            conditionKo: mapOWMIdKo(weatherId),    // Fix 1: OWM 자체 한국어 사용 안 함
            humidity: response.main.humidity,
            dustGrade: aqiDesc ?? "보통",
            cityName: response.name,
            cachedAt: Date(),
            highTemp: highTemp,
            lowTemp: lowTemp,
            hourlyForecast: hourlyItems,
            aqi: aqiVal,
            aqiDescription: aqiDesc
        )
    }

    private func mapOWMId(_ id: Int) -> String {
        switch id {
        case 200...599: return "rainy"
        case 600...699: return "snowy"
        case 700...799: return "cloudy"
        case 800:       return "sunny"
        default:        return "cloudy"
        }
    }

    /// Fix 1: OWM weather ID → 한국어 날씨 설명 (자체 매핑, API 한국어 응답 무시)
    private func mapOWMIdKo(_ id: Int) -> String {
        switch id {
        case 200...232: return "뇌우"
        case 300...321: return "이슬비"
        case 500...531: return "비"
        case 600...622: return "눈"
        case 701:       return "안개"
        case 711:       return "연기"
        case 721:       return "박무"
        case 731, 761:  return "먼지"
        case 741:       return "안개"
        case 751:       return "모래"
        case 762:       return "화산재"
        case 771:       return "돌풍"
        case 781:       return "토네이도"
        case 700...799: return "안개"
        case 800:       return "맑음"
        case 801:       return "구름 조금"
        case 802:       return "구름 많음"
        case 803, 804:  return "흐림"
        default:        return "흐림"
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

// MARK: - Response Models

private struct OWMCurrentResponse: Codable {
    let main: OWMMain
    let weather: [OWMWeather]
    let name: String
    struct OWMMain: Codable { let temp: Double; let humidity: Int }
    struct OWMWeather: Codable { let id: Int; let description: String }
}

private struct OWMForecastResponse: Codable {
    let list: [ForecastItem]
    struct ForecastItem: Codable {
        let dt: Int
        let main: ForecastMain
        let weather: [OWMCurrentResponse.OWMWeather]
    }
    struct ForecastMain: Codable {
        let temp: Double
        let tempMax: Double
        let tempMin: Double
        enum CodingKeys: String, CodingKey {
            case temp
            case tempMax = "temp_max"
            case tempMin = "temp_min"
        }
    }
}

private struct OWMAirPollutionResponse: Codable {
    let list: [AirItem]
    struct AirItem: Codable { let main: AirMain }
    struct AirMain: Codable { let aqi: Int }
}

enum WeatherError: Error, LocalizedError {
    case unavailable, invalidURL, noApiKey
    var errorDescription: String? {
        switch self {
        case .unavailable: return "날씨 정보를 불러올 수 없습니다."
        case .invalidURL:  return "잘못된 URL입니다."
        case .noApiKey:    return "API 키가 없습니다."
        }
    }
}
