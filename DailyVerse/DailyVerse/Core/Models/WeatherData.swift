import Foundation

struct WeatherData: Codable, Equatable {
    let temperature: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy" | "any"
    let conditionKo: String     // "맑음" | "흐림" | "비" | "눈"
    let humidity: Int
    let dustGrade: String       // "좋음" | "보통" | "나쁨" | "매우나쁨"
    let cityName: String
    let cachedAt: Date
    var tomorrowMorningTemp: Int?
    var tomorrowMorningCondition: String?
    var tomorrowMorningConditionKo: String?

    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < 1800  // 30분
    }

    var dustEmoji: String {
        switch dustGrade {
        case "좋음": return "😊"
        case "보통": return "🙂"
        case "나쁨": return "😷"
        case "매우나쁨": return "🤢"
        default: return "😊"
        }
    }

    static let placeholder = WeatherData(
        temperature: 20,
        condition: "sunny",
        conditionKo: "맑음",
        humidity: 60,
        dustGrade: "좋음",
        cityName: "서울",
        cachedAt: Date()
    )
}
