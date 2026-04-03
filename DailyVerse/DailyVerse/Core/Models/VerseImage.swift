import Foundation
import SwiftUI

struct VerseImage: Identifiable, Codable, Equatable {
    let id: String
    let filename: String
    let storageUrl: String
    let source: String
    let sourceUrl: String
    let license: String
    let mode: [String]
    let theme: [String]
    let mood: [String]
    let season: [String]
    let weather: [String]
    let tone: String        // "bright" | "mid" | "dark"
    let status: String

    // v5.1 — 텍스트 레이아웃 & 콘텐츠 안전
    let textPosition: String?   // "top" | "center" | "bottom"
    let textColor: String?      // "light" | "dark"
    let isSacredSafe: Bool?     // true: 홈/알람 배경 사용 가능
    let avoidThemes: [String]?  // 부적합 콘텐츠 태그
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id = "image_id"
        case filename
        case storageUrl = "storage_url"
        case sourceUrl = "source_url"
        case source, license, mode, theme, mood, season, weather, tone, status, notes
        case textPosition = "text_position"
        case textColor = "text_color"
        case isSacredSafe = "is_sacred_safe"
        case avoidThemes = "avoid_themes"
    }

    // MARK: - 헬퍼

    /// 홈/알람 배경으로 사용 가능한지 (is_sacred_safe == true 또는 미설정)
    var isHomeSafe: Bool {
        return isSacredSafe ?? true
    }

    /// 말씀 텍스트를 배치할 수직 위치 (0.0 = 상단, 0.5 = 중앙, 1.0 = 하단)
    var textVerticalAlignment: Alignment {
        switch textPosition {
        case "top":    return .topLeading
        case "center": return .center
        default:       return .bottomLeading  // "bottom" or nil
        }
    }

    /// text_color 기반 추천 텍스트 색상
    var prefersDarkText: Bool {
        return textColor == "dark"
    }
}
