import Foundation

// MARK: - HourlyForecastItem

struct HourlyForecastItem: Codable, Equatable {
    let time: Date
    let temperature: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let conditionKo: String
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
    var aqi: Int?                               // 대기질 지수 (0–250 매핑)
    var aqiDescription: String?                 // "좋음" | "보통" | "나쁨" | "매우나쁨"

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
        aqiDescription: String? = nil
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
