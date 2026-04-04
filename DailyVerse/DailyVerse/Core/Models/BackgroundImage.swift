import Foundation

/// v5.1 — 홈 화면 시간대별 배경 이미지
/// Firestore collection: background_images
/// 아침/낮/저녁/새벽 각 1장씩 (유저가 직접 지정)
struct BackgroundImage: Identifiable, Codable, Equatable {
    let id: String          // bg_morning / bg_afternoon / bg_evening / bg_dawn
    let mode: String        // "morning" | "afternoon" | "evening" | "dawn"
    let storageUrl: String  // Firebase Storage URL
    let filename: String
    let source: String
    let license: String
    let status: String      // "active" | "draft"

    enum CodingKeys: String, CodingKey {
        case id = "bg_id"
        case mode, filename, source, license, status
        case storageUrl = "storage_url"
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
