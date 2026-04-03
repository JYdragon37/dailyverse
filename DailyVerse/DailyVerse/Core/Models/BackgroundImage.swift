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
        case "morning":   return "☀️ 아침 (06-12)"
        case "afternoon": return "🌤 낮 (12-18)"
        case "evening":   return "🌙 저녁 (18-00)"
        case "dawn":      return "✨ 새벽 (00-06)"
        default: return mode
        }
    }
}
