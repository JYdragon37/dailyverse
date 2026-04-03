import Foundation
import SwiftUI

enum AppMode: String, CaseIterable {
    case morning   = "morning"
    case afternoon = "afternoon"
    case evening   = "evening"
    case dawn      = "dawn"

    static func current() -> AppMode {
        return fromHour(Calendar.current.component(.hour, from: Date()))
    }

    static func fromHour(_ hour: Int) -> AppMode {
        switch hour {
        case 6..<12:  return .morning
        case 12..<18: return .afternoon
        case 18..<24: return .evening
        default:      return .dawn      // 00:00~05:59
        }
    }

    static func fromTime(_ date: Date) -> AppMode {
        return fromHour(Calendar.current.component(.hour, from: date))
    }

    var greeting: String {
        switch self {
        case .morning:   return "Good Morning"
        case .afternoon: return "Good Afternoon"
        case .evening:   return "Good Evening"
        case .dawn:      return "Still awake,"
        }
    }

    var greetingIcon: String {
        switch self {
        case .morning:   return "sun.max.fill"
        case .afternoon: return "cloud.sun.fill"
        case .evening:   return "moon.stars.fill"
        case .dawn:      return "sparkles"
        }
    }

    var themes: [String] {
        switch self {
        case .morning:   return ["hope", "courage", "strength", "renewal"]
        case .afternoon: return ["wisdom", "focus", "patience", "gratitude"]
        case .evening:   return ["peace", "comfort", "reflection", "rest"]
        case .dawn:      return ["stillness", "surrender", "faith", "grace"]
        }
    }

    var moods: [String] {
        switch self {
        case .morning:   return ["bright", "dramatic"]
        case .afternoon: return ["calm", "warm"]
        case .evening:   return ["serene", "cozy"]
        case .dawn:      return ["serene", "calm"]
        }
    }

    var accentColor: Color {
        switch self {
        case .morning:   return .dvMorningGold
        case .afternoon: return .dvNoonSky
        case .evening:   return .dvEveningPurple
        case .dawn:      return .dvDawnIndigo
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .morning:   return .dvMorningAmber
        case .afternoon: return .dvNoonTeal
        case .evening:   return .dvEveningIndigo
        case .dawn:      return .dvDawnNavy
        }
    }

    /// 저녁/새벽 모드는 내일 아침 예보를 표시
    var showsTomorrowForecast: Bool {
        return self == .evening || self == .dawn
    }
}
