import Foundation

/// v5.1 — 홈 화면 시간대별 배경 이미지
/// Firestore collection: background_images
/// Zone별 여러 이미지 존재 → 날씨 조건 필터 후 랜덤 1개 선택
struct BackgroundImage: Identifiable, Codable, Equatable {
    let id: String          // bg_morning / bg_afternoon / bg_evening / bg_dawn
    let mode: String        // "morning" | "afternoon" | "evening" | "dawn"
    let storageUrl: String  // Firebase Storage URL
    let filename: String
    let source: String
    let license: String
    let status: String      // "active" | "draft"
    let needsOverlay: Bool          // 상단 다크 그라데이션 오버레이 필요 여부
    let overlayIntensity: String?   // "light" | "medium" | "heavy" | nil
    let concept: String             // "seoul" | "nature" | "greece_rome" | "prague" | "florence_paris"
    let weather: String             // "all" | "sunny" | "rainy" | "snowy" | "misty" | "cloudy" | "clear"
    let zoneNumber: Int             // 1–8

    enum CodingKeys: String, CodingKey {
        case id = "bg_id"
        case mode, filename, source, license, status, concept, weather
        case storageUrl = "storage_url"
        case needsOverlay = "needs_overlay"
        case overlayIntensity = "overlay_intensity"
        case zoneNumber = "zone_number"
    }

    init(id: String, mode: String, storageUrl: String, filename: String,
         source: String, license: String, status: String,
         needsOverlay: Bool = false, overlayIntensity: String? = nil,
         concept: String = "unknown", weather: String = "all", zoneNumber: Int = 0) {
        self.id = id
        self.mode = mode
        self.storageUrl = storageUrl
        self.filename = filename
        self.source = source
        self.license = license
        self.status = status
        self.needsOverlay = needsOverlay
        self.overlayIntensity = overlayIntensity
        self.concept = concept
        self.weather = weather
        self.zoneNumber = zoneNumber
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(String.self, forKey: .id)
        mode             = try c.decode(String.self, forKey: .mode)
        storageUrl       = try c.decode(String.self, forKey: .storageUrl)
        filename         = try c.decode(String.self, forKey: .filename)
        source           = try c.decode(String.self, forKey: .source)
        license          = try c.decode(String.self, forKey: .license)
        status           = try c.decode(String.self, forKey: .status)
        needsOverlay     = (try? c.decode(Bool.self,   forKey: .needsOverlay))  ?? false
        overlayIntensity = try? c.decode(String.self,  forKey: .overlayIntensity)
        concept          = (try? c.decode(String.self, forKey: .concept))       ?? "unknown"
        weather          = (try? c.decode(String.self, forKey: .weather))       ?? "all"
        zoneNumber       = (try? c.decode(Int.self,    forKey: .zoneNumber))    ?? 0
    }

    /// 모드 한글 표시명
    var modeDisplayName: String {
        switch mode {
        case "deep_dark":   return "🌑 Deep Dark (00–03)"
        case "first_light": return "🌒 First Light (03–06)"
        case "rise_ignite": return "🌅 Rise & Ignite (06–09)"
        case "peak_mode":   return "⚡ Peak Mode (09–12)"
        case "recharge":    return "☀️ Recharge (12–15)"
        case "second_wind": return "🌤 Second Wind (15–18)"
        case "golden_hour": return "🌇 Golden Hour (18–21)"
        case "wind_down":   return "🌙 Wind Down (21–24)"
        case "all":         return "🌐 전체"
        // 레거시 호환
        case "morning":     return "🌅 아침"
        case "afternoon":   return "☀️ 낮"
        case "evening":     return "🌇 저녁"
        case "dawn":        return "🌒 새벽"
        default:            return mode
        }
    }
}
