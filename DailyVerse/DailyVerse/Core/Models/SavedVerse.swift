import Foundation

struct SavedVerse: Identifiable, Codable, Equatable {
    let id: String
    let verseId: String
    let imageId: String?        // v5.1 — 저장 당시 배경 이미지 ID
    let savedAt: Date
    let mode: String
    let weatherTemp: Int
    let weatherCondition: String
    let weatherHumidity: Int
    let weatherDust: String?    // v5.1 — 미세먼지 등급
    let locationName: String
    let locationLat: Double?
    let locationLng: Double?

    enum CodingKeys: String, CodingKey {
        case id = "saved_id"
        case verseId = "verse_id"
        case imageId = "image_id"
        case savedAt = "saved_at"
        case mode
        case weatherTemp = "weather_temp"
        case weatherCondition = "weather_condition"
        case weatherHumidity = "weather_humidity"
        case weatherDust = "weather_dust"
        case locationName = "location_name"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id               = try container.decode(String.self, forKey: .id)
        verseId          = try container.decode(String.self, forKey: .verseId)
        imageId          = try container.decodeIfPresent(String.self, forKey: .imageId)
        savedAt          = try container.decode(Date.self, forKey: .savedAt)
        mode             = try container.decode(String.self, forKey: .mode)
        weatherTemp      = try container.decodeIfPresent(Int.self, forKey: .weatherTemp) ?? 0
        weatherCondition = try container.decodeIfPresent(String.self, forKey: .weatherCondition) ?? "any"
        weatherHumidity  = try container.decodeIfPresent(Int.self, forKey: .weatherHumidity) ?? 0
        weatherDust      = try container.decodeIfPresent(String.self, forKey: .weatherDust)
        locationName     = try container.decodeIfPresent(String.self, forKey: .locationName) ?? ""
        locationLat      = try container.decodeIfPresent(Double.self, forKey: .locationLat)
        locationLng      = try container.decodeIfPresent(Double.self, forKey: .locationLng)
    }

    init(
        id: String,
        verseId: String,
        imageId: String? = nil,
        savedAt: Date,
        mode: String,
        weatherTemp: Int = 0,
        weatherCondition: String = "any",
        weatherHumidity: Int = 0,
        weatherDust: String? = nil,
        locationName: String = "",
        locationLat: Double? = nil,
        locationLng: Double? = nil
    ) {
        self.id = id
        self.verseId = verseId
        self.imageId = imageId
        self.savedAt = savedAt
        self.mode = mode
        self.weatherTemp = weatherTemp
        self.weatherCondition = weatherCondition
        self.weatherHumidity = weatherHumidity
        self.weatherDust = weatherDust
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
    }

    var daysSinceSaved: Int {
        Calendar.current.dateComponents([.day], from: savedAt, to: Date()).day ?? 0
    }
}

// v5.1: 단일 플랜으로 접근 제한 제거. enum은 하위 호환을 위해 유지.
enum SavedAccessLevel {
    case free        // 열람 가능
    case adRequired  // v5.1: 미사용
    case locked      // v5.1: 미사용
    case premium     // v5.1: 미사용 (모든 유저가 free와 동일)
}
