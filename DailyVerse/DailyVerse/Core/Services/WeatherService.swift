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
        // precipitationProbability가 nil인 구 캐시도 무시 (OWM 강수확률 수정 반영)
        if let cached = cacheManager.load(),
           cached.isValid,
           !cached.hourlyForecast.isEmpty,
           cached.precipitationProbability != nil {
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

        // 7일 예보 (WeatherKit DayWeather)
        let sevenDayForecast = Array(daily.forecast.prefix(7)).map { d -> DailyForecastItem in
            DailyForecastItem(
                date: d.date,
                highTemp: Int(d.highTemperature.converted(to: .celsius).value.rounded()),
                lowTemp: Int(d.lowTemperature.converted(to: .celsius).value.rounded()),
                condition: mapWeatherKitCondition(d.condition),
                conditionKo: mapWeatherKitConditionKo(d.condition),
                precipitationProbability: Int((d.precipitationChance * 100).rounded())
            )
        }

        // UV Index (현재 자외선 지수)
        let uvIndexVal = Int(current.uvIndex.value)

        // 오늘/내일 강수 확률
        let todayRainProb = daily.forecast.first.map { Int(($0.precipitationChance * 100).rounded()) }
        let tomorrowRainProb = daily.forecast.dropFirst().first.map { Int(($0.precipitationChance * 100).rounded()) }

        // 대기질 — 에어코리아 우선, 실패 시 OWM 폴백
        let airKorea = await fetchAirKorea(location: location)
        let aqiVal: Int?
        let aqiDesc: String?
        let pm25Val: Double?
        let pm10Val: Double?
        let stationName: String?

        if airKorea.aqi != nil {
            // 에어코리아 CAI 기반
            aqiVal = airKorea.aqi
            aqiDesc = airKorea.desc
            pm25Val = airKorea.pm25
            pm10Val = airKorea.pm10
            stationName = airKorea.station
        } else {
            // OWM 폴백
            let owmKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
            let owm = await fetchAQI(lat: location.coordinate.latitude, lon: location.coordinate.longitude, apiKey: owmKey)
            aqiVal = owm.aqi
            aqiDesc = owm.desc
            pm25Val = owm.pm25; pm10Val = owm.pm10; stationName = nil
        }

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
            aqiDescription: aqiDesc,
            pm25: pm25Val,
            pm10: pm10Val,
            airStation: stationName,
            uvIndex: uvIndexVal,
            precipitationProbability: todayRainProb,
            tomorrowPrecipitationProbability: tomorrowRainProb,
            dailyForecast: sevenDayForecast
        )
    }

    // MARK: - 에어코리아 대기오염 API (한국 공식 측정소 실시간 데이터)

    /// 좌표 → 시도명 변환 (CLGeocoder administrativeArea 기반)
    private func sidoName(from location: CLLocation) async -> String {
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let admin = placemarks?.first?.administrativeArea ?? ""
                // CLGeocoder는 영문/한글 혼용 반환 — 한국 시도명으로 매핑
                let map: [String: String] = [
                    "Seoul": "서울", "서울특별시": "서울", "서울": "서울",
                    "Busan": "부산", "부산광역시": "부산",
                    "Daegu": "대구", "대구광역시": "대구",
                    "Incheon": "인천", "인천광역시": "인천",
                    "Gwangju": "광주", "광주광역시": "광주",
                    "Daejeon": "대전", "대전광역시": "대전",
                    "Ulsan": "울산", "울산광역시": "울산",
                    "Gyeonggi-do": "경기", "경기도": "경기",
                    "Gangwon-do": "강원", "강원도": "강원",
                    "Chungcheongbuk-do": "충북", "충청북도": "충북",
                    "Chungcheongnam-do": "충남", "충청남도": "충남",
                    "Jeollabuk-do": "전북", "전라북도": "전북",
                    "Jeollanam-do": "전남", "전라남도": "전남",
                    "Gyeongsangbuk-do": "경북", "경상북도": "경북",
                    "Gyeongsangnam-do": "경남", "경상남도": "경남",
                    "Jeju-do": "제주", "제주특별자치도": "제주",
                    "Sejong": "세종", "세종특별자치시": "세종",
                ]
                continuation.resume(returning: map[admin] ?? "서울")
            }
        }
    }

    /// 에어코리아 API — 시도 단위 실시간 대기오염 정보
    /// CAI(통합대기환경지수), PM2.5, PM10 반환
    private func fetchAirKorea(location: CLLocation) async -> (aqi: Int?, desc: String?, pm25: Double?, pm10: Double?, station: String?) {
        let apiKey = Bundle.main.infoDictionary?["AIRKOREA_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty else { return (nil, nil, nil, nil, nil) }

        let sido = await sidoName(from: location)
        let encodedSido = sido.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sido
        let urlStr = "https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty"
            + "?sidoName=\(encodedSido)&pageNo=1&numOfRows=10&returnType=json"
            + "&serviceKey=\(apiKey)&ver=1.0"

        guard let url = URL(string: urlStr),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(AirKoreaResponse.self, from: data) else {
            return (nil, nil, nil, nil, nil)
        }

        // 유효한 측정값이 있는 첫 번째 측정소
        guard let item = response.response.body.items.first(where: {
            $0.khaiValue != "-" && $0.khaiValue != nil
        }) else { return (nil, nil, nil, nil, nil) }

        let cai = item.khaiValue.flatMap { Int($0) }
        let pm25 = item.pm25Value.flatMap { Double($0) }
        let pm10 = item.pm10Value.flatMap { Double($0) }

        let desc: String
        switch item.khaiGrade {
        case "1": desc = "좋음"
        case "2": desc = "보통"
        case "3": desc = "나쁨"
        case "4": desc = "매우나쁨"
        default:
            if let c = cai {
                desc = c <= 50 ? "좋음" : c <= 100 ? "보통" : c <= 250 ? "나쁨" : "매우나쁨"
            } else { desc = "보통" }
        }

        return (cai, desc, pm25, pm10, item.stationName)
    }

    // MARK: - AQI (OpenWeatherMap — 해외 또는 에어코리아 실패 시 폴백)

    /// OWM Air Pollution — pm2.5 실측값 기반 AQI 계산 (1-5 스케일×50 대신 실측값 사용)
    private func fetchAQI(lat: Double, lon: Double, apiKey: String) async -> (aqi: Int?, desc: String?, pm25: Double?, pm10: Double?) {
        guard !apiKey.isEmpty,
              let url = URL(string: "https://api.openweathermap.org/data/2.5/air_pollution?lat=\(lat)&lon=\(lon)&appid=\(apiKey)") else {
            return (nil, nil, nil, nil)
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(OWMAirPollutionResponse.self, from: data),
              let item = response.list.first else {
            return (nil, nil, nil, nil)
        }
        // pm2.5 실측값으로 AQI 계산 (OWM 1-5 스케일 대신 실측 농도 기반)
        let pm25 = item.components?.pm2_5
        let pm10 = item.components?.pm10
        let aqi: Int
        let desc: String
        if let pm = pm25 {
            // WHO / 한국 PM2.5 기준 환산
            switch pm {
            case ..<15:   aqi = Int(pm * 50 / 15);  desc = "좋음"
            case ..<35:   aqi = Int(50 + (pm-15) * 50 / 20);  desc = "보통"
            case ..<75:   aqi = Int(100 + (pm-35) * 100 / 40); desc = "나쁨"
            default:      aqi = min(250, Int(200 + (pm-75)));   desc = "매우나쁨"
            }
        } else {
            // components 없으면 1-5 스케일 폴백
            switch item.main.aqi {
            case 1: aqi = 30;  desc = "좋음"
            case 2: aqi = 75;  desc = "보통"
            case 3: aqi = 130; desc = "나쁨"
            default: aqi = 200; desc = "매우나쁨"
            }
        }
        return (aqi, desc, pm25, pm10)
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

        // 에어코리아 우선, 실패 시 OWM AQI 폴백
        let airKorea2 = await fetchAirKorea(location: location)
        let aqiVal2: Int?; let aqiDesc2: String?
        let pm25_2: Double?; let pm10_2: Double?; let station2: String?
        if airKorea2.aqi != nil {
            aqiVal2 = airKorea2.aqi; aqiDesc2 = airKorea2.desc
            pm25_2 = airKorea2.pm25; pm10_2 = airKorea2.pm10; station2 = airKorea2.station
        } else {
            let owm = await fetchAQI(lat: lat, lon: lon, apiKey: apiKey)
            aqiVal2 = owm.aqi; aqiDesc2 = owm.desc
            pm25_2 = owm.pm25; pm10_2 = owm.pm10; station2 = nil
        }

        // OWM에서 강수 확률 / 내일 강수 확률 추출
        var todayPop: Int? = nil
        var tomorrowPop: Int? = nil
        var sevenDayForecast2: [DailyForecastItem] = []
        if let fUrl = URL(string: "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&cnt=40"),
           let (fData, _) = try? await URLSession.shared.data(from: fUrl),
           let fResp = try? JSONDecoder().decode(OWMForecastResponse.self, from: fData) {
            let cal = Calendar.current
            let today = Date()
            let todayItems = fResp.list.filter { cal.isDate(Date(timeIntervalSince1970: TimeInterval($0.dt)), inSameDayAs: today) }
            todayPop = todayItems.compactMap { $0.pop }.max().map { Int($0 * 100) }
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? today
            let tomorrowItems = fResp.list.filter { cal.isDate(Date(timeIntervalSince1970: TimeInterval($0.dt)), inSameDayAs: tomorrow) }
            tomorrowPop = tomorrowItems.compactMap { $0.pop }.max().map { Int($0 * 100) }
            // 5일 예보 (일별 그룹화)
            let grouped = Dictionary(grouping: fResp.list) {
                cal.startOfDay(for: Date(timeIntervalSince1970: TimeInterval($0.dt)))
            }
            sevenDayForecast2 = grouped.keys.sorted().prefix(5).compactMap { day in
                let items = grouped[day] ?? []
                guard let high = items.map({ $0.main.tempMax }).max(),
                      let low  = items.map({ $0.main.tempMin }).min(),
                      let cond = items.first?.weather.first?.id else { return nil }
                let pop = items.compactMap { $0.pop }.max().map { Int($0 * 100) } ?? 0
                return DailyForecastItem(date: day, highTemp: Int(high.rounded()), lowTemp: Int(low.rounded()),
                                         condition: mapOWMId(cond), conditionKo: mapOWMIdKo(cond),
                                         precipitationProbability: pop)
            }
        }

        return WeatherData(
            temperature: Int(response.main.temp.rounded()),
            condition: mapOWMId(weatherId),
            conditionKo: mapOWMIdKo(weatherId),
            humidity: response.main.humidity,
            dustGrade: aqiDesc2 ?? "보통",
            cityName: response.name,
            cachedAt: Date(),
            highTemp: highTemp,
            lowTemp: lowTemp,
            hourlyForecast: hourlyItems,
            aqi: aqiVal2,
            aqiDescription: aqiDesc2,
            pm25: pm25_2,
            pm10: pm10_2,
            airStation: station2,
            precipitationProbability: todayPop,
            tomorrowPrecipitationProbability: tomorrowPop,
            dailyForecast: sevenDayForecast2
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
        let pop: Double?   // 강수 확률 0.0–1.0
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
    struct AirItem: Codable {
        let main: AirMain
        let components: AirComponents?
    }
    struct AirMain: Codable { let aqi: Int }
    struct AirComponents: Codable {
        let pm2_5: Double?
        let pm10: Double?
    }
}

// MARK: - 에어코리아 Response Model

private struct AirKoreaResponse: Codable {
    let response: AKBody
    struct AKBody: Codable { let body: AKItems }
    struct AKItems: Codable { let items: [AKItem] }
    struct AKItem: Codable {
        let stationName: String?
        let khaiValue: String?    // 통합대기환경지수 CAI
        let khaiGrade: String?    // 1:좋음 2:보통 3:나쁨 4:매우나쁨
        let pm25Value: String?    // PM2.5 μg/m³
        let pm10Value: String?    // PM10 μg/m³
        enum CodingKeys: String, CodingKey {
            case stationName, khaiValue, khaiGrade
            case pm25Value = "pm25Value"
            case pm10Value = "pm10Value"
        }
    }
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
