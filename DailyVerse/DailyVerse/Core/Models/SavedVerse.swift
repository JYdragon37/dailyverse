import Foundation

struct SavedVerse: Identifiable, Codable, Equatable {
    let id: String
    let verseId: String
    let savedAt: Date
    let mode: String
    let weatherTemp: Int
    let weatherCondition: String
    let weatherHumidity: Int
    let locationName: String

    enum CodingKeys: String, CodingKey {
        case id = "saved_id"
        case verseId = "verse_id"
        case savedAt = "saved_at"
        case mode
        case weatherTemp = "weather_temp"
        case weatherCondition = "weather_condition"
        case weatherHumidity = "weather_humidity"
        case locationName = "location_name"
    }

    // 저장탭 접근 레벨 계산
    var daysSinceSaved: Int {
        Calendar.current.dateComponents([.day], from: savedAt, to: Date()).day ?? 0
    }
}

enum SavedAccessLevel {
    case free        // 0~7일
    case adRequired  // 7~30일 (Free 유저)
    case locked      // 30일 초과 (Free 유저)
    case premium     // Premium 유저 무제한
}
