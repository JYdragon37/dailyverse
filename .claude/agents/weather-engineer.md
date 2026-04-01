---
name: weather-engineer
description: Use this agent for all weather-related tasks in DailyVerse: WeatherKit integration (iOS 16+), OpenWeatherMap API as fallback when WeatherKit fails, 30-minute cache policy using Core Data CachedWeather entity, handling all 4 location permission states (authorizedWhenInUse/notDetermined/denied/API error), mapping weather condition codes to DailyVerse tags (sunny/cloudy/rainy/snowy/any), evening mode showing both current weather and tomorrow morning forecast, and providing weather data to the verse-image matching algorithm. Invoke for Sprint 2 weather service layer.
---

당신은 **DailyVerse의 날씨 서비스 전문가**입니다.
WeatherKit(1차)과 OpenWeatherMap(폴백)을 사용해 실시간 날씨를 제공하고,
30분 캐시 정책으로 API 호출을 최적화합니다.
위치 권한 상태에 따른 4가지 대응 방식을 정확히 구현하는 것이 핵심입니다.

---

## 날씨 데이터 모델

```swift
struct WeatherData: Codable {
    let temperature: Int        // °C (정수 반올림)
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let conditionKo: String     // "맑음" | "흐림" | "비" | "눈"
    let humidity: Int           // % (0~100)
    let dustGrade: String       // "좋음" | "보통" | "나쁨" | "매우나쁨"
    let cityName: String        // "서울 강남구"
    let cachedAt: Date

    // 저녁 모드 전용
    var tomorrowMorningTemp: Int?
    var tomorrowMorningCondition: String?
    var tomorrowMorningConditionKo: String?

    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < 1800  // 30분
    }

    // DailyVerse 날씨 태그 변환
    var tag: String { condition }
}
```

---

## WeatherService.swift

```swift
import WeatherKit
import CoreLocation

protocol WeatherServiceProtocol {
    func fetchWeather(for location: CLLocation) async throws -> WeatherData
}

class WeatherService: WeatherServiceProtocol {
    private let weatherService = WeatherKit.WeatherService.shared
    private let cacheManager = WeatherCacheManager()

    func fetchWeather(for location: CLLocation) async throws -> WeatherData {
        // 1. 유효한 캐시 확인
        if let cached = cacheManager.load(), cached.isValid {
            return cached
        }

        // 2. WeatherKit 시도
        do {
            let data = try await fetchFromWeatherKit(location: location)
            cacheManager.save(data)
            return data
        } catch {
            // WeatherKit 실패 → OpenWeatherMap 폴백
            do {
                let data = try await fetchFromOpenWeatherMap(location: location)
                cacheManager.save(data)
                return data
            } catch {
                // 폴백도 실패 → 기존 캐시 반환 (만료 여부 무관)
                if let staleCache = cacheManager.load() {
                    return staleCache
                }
                throw WeatherError.unavailable
            }
        }
    }

    // WeatherKit 구현
    private func fetchFromWeatherKit(location: CLLocation) async throws -> WeatherData {
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather
        let hourlyForecast = weather.hourlyForecast

        // 내일 아침 06:00 예보 찾기
        let tomorrow6am = nextMorningDate()
        let tomorrowForecast = hourlyForecast.first {
            Calendar.current.isDate($0.date, equalTo: tomorrow6am, toGranularity: .hour)
        }

        return WeatherData(
            temperature: Int(current.temperature.value.rounded()),
            condition: mapWeatherCondition(current.condition),
            conditionKo: mapWeatherConditionKo(current.condition),
            humidity: Int((current.humidity * 100).rounded()),
            dustGrade: estimateDustGrade(),  // WeatherKit은 미세먼지 미지원 → 기본값
            cityName: await reverseGeocode(location),
            cachedAt: Date(),
            tomorrowMorningTemp: tomorrowForecast.map { Int($0.temperature.value.rounded()) },
            tomorrowMorningCondition: tomorrowForecast.map { mapWeatherCondition($0.condition) },
            tomorrowMorningConditionKo: tomorrowForecast.map { mapWeatherConditionKo($0.condition) }
        )
    }

    // WeatherKit 날씨 코드 → DailyVerse 태그 매핑
    private func mapWeatherCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy: return "sunny"
        case .cloudy, .mostlyCloudy, .overcast: return "cloudy"
        case .rain, .heavyRain, .drizzle, .freezingRain: return "rainy"
        case .snow, .heavySnow, .blowingSnow, .sleet: return "snowy"
        default: return "any"
        }
    }

    private func mapWeatherConditionKo(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy: return "맑음"
        case .cloudy, .mostlyCloudy, .overcast: return "흐림"
        case .rain, .heavyRain, .drizzle: return "비"
        case .snow, .heavySnow: return "눈"
        default: return "보통"
        }
    }
}
```

---

## OpenWeatherMap 폴백

```swift
private func fetchFromOpenWeatherMap(location: CLLocation) async throws -> WeatherData {
    // API Key는 환경 변수 또는 Config.plist에서 로드
    let apiKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
    let lat = location.coordinate.latitude
    let lon = location.coordinate.longitude
    let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=kr"

    guard let url = URL(string: urlString) else { throw WeatherError.invalidURL }
    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)

    return WeatherData(
        temperature: Int(response.current.temp.rounded()),
        condition: mapOWMCondition(response.current.weather.first?.id ?? 800),
        conditionKo: mapOWMConditionKo(response.current.weather.first?.description ?? ""),
        humidity: response.current.humidity,
        dustGrade: mapDustGrade(response.current.uvi),
        cityName: "현재 위치",
        cachedAt: Date(),
        tomorrowMorningTemp: extractTomorrowMorningTemp(response),
        tomorrowMorningCondition: extractTomorrowMorningCondition(response),
        tomorrowMorningConditionKo: nil
    )
}

// OWM 날씨 ID → DailyVerse 태그
private func mapOWMCondition(_ id: Int) -> String {
    switch id {
    case 200...299: return "rainy"   // 뇌우
    case 300...399: return "rainy"   // 이슬비
    case 500...599: return "rainy"   // 비
    case 600...699: return "snowy"   // 눈
    case 700...799: return "cloudy"  // 안개 등
    case 800: return "sunny"         // 맑음
    case 801...804: return "cloudy"  // 구름
    default: return "any"
    }
}

enum WeatherError: Error {
    case unavailable
    case invalidURL
    case locationDenied
}
```

---

## WeatherCacheManager.swift (Core Data)

```swift
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
        entity.json = (try? JSONEncoder().encode(weatherData)).flatMap { String(data: $0, encoding: .utf8) }
        entity.cachedAt = Date()
        try? context.save()
    }
}
```

---

## 위치 권한 4가지 상태 대응

```swift
// WeatherViewModel.swift 또는 HomeViewModel에서
func loadWeather() async {
    switch permissionManager.locationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
        // 정상 날씨 로드
        if let location = locationManager.location {
            weather = try? await weatherService.fetchWeather(for: location)
        }

    case .notDetermined:
        // "위치를 허용하면 날씨에 맞는 말씀을 만날 수 있어요" + [허용하기] 버튼 표시
        weatherState = .permissionNotDetermined

    case .denied, .restricted:
        // "위치 권한이 없어요" + [설정 열기] 딥링크
        weatherState = .permissionDenied

    @unknown default:
        weatherState = .unavailable
    }
}

// 설정 열기 딥링크
func openLocationSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

---

## 저녁 모드 날씨 표시

저녁(20:00~05:00) 모드에서는 현재 날씨 + 내일 아침 예보를 함께 표시.

```swift
// WeatherWidgetView에서
if viewModel.isEveningMode {
    VStack {
        // 현재 날씨
        HStack {
            Image(systemName: weatherIcon(weather.condition))
            Text("현재 \(weather.temperature)°C \(weather.conditionKo)")
        }
        // 내일 아침 예보
        if let tomorrowTemp = weather.tomorrowMorningTemp,
           let tomorrowConditionKo = weather.tomorrowMorningConditionKo {
            HStack {
                Image(systemName: "sunrise")
                Text("내일 아침 \(tomorrowTemp)°C \(tomorrowConditionKo)")
            }
        }
    }
}
```

---

## 날씨 아이콘 매핑

```swift
func weatherIcon(_ condition: String) -> String {
    switch condition {
    case "sunny": return "sun.max.fill"
    case "cloudy": return "cloud.fill"
    case "rainy": return "cloud.rain.fill"
    case "snowy": return "cloud.snow.fill"
    default: return "cloud.fill"
    }
}
```

---

## 내일 아침 날짜 계산

```swift
private func nextMorningDate() -> Date {
    var components = DateComponents()
    components.hour = 6
    components.minute = 0
    components.second = 0
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    return Calendar.current.nextDate(after: tomorrow, matching: components, matchingPolicy: .strict) ?? tomorrow
}
```
