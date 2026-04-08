import Foundation

// MARK: - HourlyForecastItem

struct HourlyForecastItem: Codable, Equatable {
    let time: Date
    let temperature: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let conditionKo: String
}

// MARK: - DailyForecastItem

struct DailyForecastItem: Codable, Equatable {
    let date: Date
    let highTemp: Int
    let lowTemp: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let conditionKo: String     // "맑음" | "흐림" | "비" | "눈"
    let precipitationProbability: Int  // 강수 확률 0-100%
}

// MARK: - WeatherData

struct WeatherData: Codable, Equatable {
    let temperature: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy" | "any"
    let conditionKo: String     // "맑음" | "흐림" | "비" | "눈"
    let humidity: Int
    let dustGrade: String       // "좋음" | "보통" | "나쁨" | "매우나쁨"
    let cityName: String
    let cachedAt: Date

    // 내일 아침 예보
    var tomorrowMorningTemp: Int?
    var tomorrowMorningCondition: String?
    var tomorrowMorningConditionKo: String?

    // v5.2 — 날씨 상세 시트용
    var highTemp: Int?                          // 오늘 최고 기온
    var lowTemp: Int?                           // 오늘 최저 기온
    var hourlyForecast: [HourlyForecastItem]    // 다음 12시간 예보
    var aqi: Int?                               // 대기질 지수 (0–250 매핑 또는 에어코리아 CAI)
    var aqiDescription: String?                 // "좋음" | "보통" | "나쁨" | "매우나쁨"
    // 에어코리아 실측값
    var pm25: Double?                           // PM2.5 실측 (μg/m³)
    var pm10: Double?                           // PM10 실측 (μg/m³)
    var airStation: String?                     // 측정소명
    var uvIndex: Int?                              // 자외선 지수 0-11+
    var precipitationProbability: Int?             // 오늘 강수 확률 %
    var tomorrowPrecipitationProbability: Int?     // 내일 강수 확률 %
    var dailyForecast: [DailyForecastItem]         // 7일 예보

    init(
        temperature: Int,
        condition: String,
        conditionKo: String,
        humidity: Int,
        dustGrade: String,
        cityName: String,
        cachedAt: Date,
        tomorrowMorningTemp: Int? = nil,
        tomorrowMorningCondition: String? = nil,
        tomorrowMorningConditionKo: String? = nil,
        highTemp: Int? = nil,
        lowTemp: Int? = nil,
        hourlyForecast: [HourlyForecastItem] = [],
        aqi: Int? = nil,
        aqiDescription: String? = nil,
        pm25: Double? = nil,
        pm10: Double? = nil,
        airStation: String? = nil,
        uvIndex: Int? = nil,
        precipitationProbability: Int? = nil,
        tomorrowPrecipitationProbability: Int? = nil,
        dailyForecast: [DailyForecastItem] = []
    ) {
        self.temperature = temperature
        self.condition = condition
        self.conditionKo = conditionKo
        self.humidity = humidity
        self.dustGrade = dustGrade
        self.cityName = cityName
        self.cachedAt = cachedAt
        self.tomorrowMorningTemp = tomorrowMorningTemp
        self.tomorrowMorningCondition = tomorrowMorningCondition
        self.tomorrowMorningConditionKo = tomorrowMorningConditionKo
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.hourlyForecast = hourlyForecast
        self.aqi = aqi
        self.aqiDescription = aqiDescription
        self.pm25 = pm25
        self.pm10 = pm10
        self.airStation = airStation
        self.uvIndex = uvIndex
        self.precipitationProbability = precipitationProbability
        self.tomorrowPrecipitationProbability = tomorrowPrecipitationProbability
        self.dailyForecast = dailyForecast
    }

    var uvIndexDescription: String {
        guard let uv = uvIndex else { return "정보 없음" }
        switch uv {
        case 0...2:  return "낮음"
        case 3...5:  return "보통"
        case 6...7:  return "높음"
        case 8...10: return "매우 높음"
        default:     return "위험"
        }
    }

    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < 1800  // 30분
    }

    var dustEmoji: String {
        switch dustGrade {
        case "좋음":   return "😊"
        case "보통":   return "🙂"
        case "나쁨":   return "😷"
        case "매우나쁨": return "🤢"
        default:     return "😊"
        }
    }

    /// AQI 게이지용 0.0–1.0 비율
    var aqiFraction: Double {
        let val = aqi ?? dustGradeToAqi
        return min(Double(val) / 250.0, 1.0)
    }

    /// dustGrade → AQI 수치 매핑
    var dustGradeToAqi: Int {
        switch dustGrade {
        case "좋음":   return 50
        case "보통":   return 100
        case "나쁨":   return 150
        case "매우나쁨": return 200
        default:     return 50
        }
    }

    static let placeholder = WeatherData(
        temperature: 20,
        condition: "sunny",
        conditionKo: "맑음",
        humidity: 60,
        dustGrade: "좋음",
        cityName: "서울",
        cachedAt: Date(),
        highTemp: 24,
        lowTemp: 14,
        hourlyForecast: [],
        aqi: 50,
        aqiDescription: "좋음"
    )
}
