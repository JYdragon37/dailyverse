import Foundation
import SwiftUI

// v6.0 — 8 Zone 시스템
// 하루를 3시간 단위 8개 구간으로 세분화

enum AppMode: String, CaseIterable {
    case deepDark   = "deep_dark"   // Zone 1: 00:00–03:00 🌑
    case firstLight = "first_light" // Zone 2: 03:00–06:00 🌒
    case riseIgnite = "rise_ignite" // Zone 3: 06:00–09:00 🌅
    case peakMode   = "peak_mode"   // Zone 4: 09:00–12:00 ⚡
    case recharge   = "recharge"    // Zone 5: 12:00–15:00 ☀️
    case secondWind = "second_wind" // Zone 6: 15:00–18:00 🌤️
    case goldenHour = "golden_hour" // Zone 7: 18:00–21:00 🌇
    case windDown   = "wind_down"   // Zone 8: 21:00–24:00 🌙

    // MARK: - 시간 → Zone 변환

    static func current() -> AppMode {
        return fromHour(Calendar.current.component(.hour, from: Date()))
    }

    static func fromHour(_ hour: Int) -> AppMode {
        switch hour {
        case 0..<3:   return .deepDark    // 00:00–03:00
        case 3..<6:   return .firstLight  // 03:00–06:00
        case 6..<9:   return .riseIgnite  // 06:00–09:00
        case 9..<12:  return .peakMode    // 09:00–12:00
        case 12..<15: return .recharge    // 12:00–15:00
        case 15..<18: return .secondWind  // 15:00–18:00
        case 18..<21: return .goldenHour  // 18:00–21:00
        default:      return .windDown    // 21:00–24:00
        }
    }

    static func fromTime(_ date: Date) -> AppMode {
        return fromHour(Calendar.current.component(.hour, from: date))
    }

    // MARK: - 인사말

    /// 영문 인사말
    var greeting: String {
        switch self {
        case .deepDark:   return "Still up, Night Owl?"
        case .firstLight: return "Rise before the world."
        case .riseIgnite: return "Good Morning"
        case .peakMode:   return "In the Zone"
        case .recharge:   return "Breathe. Reset."
        case .secondWind: return "Second Wind's here."
        case .goldenHour: return "Good Evening"
        case .windDown:   return "Rest well."
        }
    }

    /// 한국어 인사말
    var greetingKr: String {
        switch self {
        case .deepDark:   return "아직 안 잤어요?"
        case .firstLight: return "세상보다 먼저 일어난 당신."
        case .riseIgnite: return "좋은 아침이에요, 오늘도 파이팅!"
        case .peakMode:   return "지금 당신, 최고의 상태예요."
        case .recharge:   return "잠깐 숨 고르고, 다시 달려요."
        case .secondWind: return "두 번째 바람이 왔어요, 마무리해봐요."
        case .goldenHour: return "수고했어요, 오늘 하루도."
        case .windDown:   return "오늘도 잘 했어요, 푹 쉬어요."
        }
    }

    // MARK: - 아이콘

    var greetingIcon: String {
        switch self {
        case .deepDark:   return "moon.fill"
        case .firstLight: return "moon.stars.fill"
        case .riseIgnite: return "sunrise.fill"
        case .peakMode:   return "bolt.fill"
        case .recharge:   return "sun.max.fill"
        case .secondWind: return "cloud.sun.fill"
        case .goldenHour: return "sunset.fill"
        case .windDown:   return "moon.stars.fill"
        }
    }

    // MARK: - Zone 컨셉 이름

    var conceptName: String {
        switch self {
        case .deepDark:   return "Deep Dark"
        case .firstLight: return "First Light"
        case .riseIgnite: return "Rise & Ignite"
        case .peakMode:   return "Peak Mode"
        case .recharge:   return "Recharge"
        case .secondWind: return "Second Wind"
        case .goldenHour: return "Golden Hour"
        case .windDown:   return "Wind Down"
        }
    }

    // MARK: - 테마 태그

    var themes: [String] {
        switch self {
        case .deepDark:   return ["stillness", "surrender", "grace", "faith"]
        case .firstLight: return ["faith", "renewal", "stillness", "hope"]
        case .riseIgnite: return ["hope", "courage", "strength", "renewal"]
        case .peakMode:   return ["wisdom", "focus", "courage", "strength"]
        case .recharge:   return ["rest", "patience", "gratitude", "comfort"]
        case .secondWind: return ["strength", "focus", "patience", "wisdom"]
        case .goldenHour: return ["gratitude", "reflection", "comfort", "peace"]
        case .windDown:   return ["peace", "rest", "comfort", "stillness"]
        }
    }

    // MARK: - 무드 태그

    var moods: [String] {
        switch self {
        case .deepDark:   return ["serene", "calm"]
        case .firstLight: return ["serene", "calm"]
        case .riseIgnite: return ["bright", "dramatic"]
        case .peakMode:   return ["bright", "dramatic"]
        case .recharge:   return ["calm", "warm"]
        case .secondWind: return ["warm", "calm"]
        case .goldenHour: return ["warm", "serene"]
        case .windDown:   return ["cozy", "calm"]
        }
    }

    // MARK: - 색상

    var accentColor: Color {
        switch self {
        case .deepDark:   return .dvDeepDarkAccent
        case .firstLight: return .dvFirstLightAccent
        case .riseIgnite: return .dvMorningGold
        case .peakMode:   return .dvNoonSky
        case .recharge:   return .dvRechargeAccent
        case .secondWind: return .dvSecondWindAccent
        case .goldenHour: return .dvGoldenHourAccent
        case .windDown:   return .dvEveningPurple
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .deepDark:   return .dvDawnNavy
        case .firstLight: return .dvDawnIndigo
        case .riseIgnite: return .dvMorningAmber
        case .peakMode:   return .dvNoonTeal
        case .recharge:   return .dvRechargeSoft
        case .secondWind: return .dvSecondWindSoft
        case .goldenHour: return .dvMorningAmber
        case .windDown:   return .dvEveningIndigo
        }
    }

    // MARK: - 그라데이션 시작/끝 색상 (fallback 배경용)

    var gradientColors: [Color] {
        switch self {
        case .deepDark:
            return [Color(hex: "#030308"), Color(hex: "#0A0820")]
        case .firstLight:
            return [Color(hex: "#0A1025"), Color(hex: "#1E3A6E")]
        case .riseIgnite:
            return [Color.dvMorningGradStart, Color.dvMorningGradMid]
        case .peakMode:
            return [Color.dvAfternoonGradStart, Color.dvAfternoonGradMid]
        case .recharge:
            return [Color(hex: "#0D2020"), Color(hex: "#1A4A40")]
        case .secondWind:
            return [Color(hex: "#1A1508"), Color(hex: "#3A3010")]
        case .goldenHour:
            return [Color(hex: "#1A0A02"), Color(hex: "#3A1808")]
        case .windDown:
            return [Color.dvEveningGradStart, Color.dvEveningGradMid]
        }
    }

    // MARK: - 기능 플래그

    /// 내일 아침 날씨 예보를 함께 표시할 구간 (야간~새벽)
    var showsTomorrowForecast: Bool {
        return self == .windDown || self == .deepDark || self == .firstLight
    }

    /// 이미지 tone 우선순위 ("bright" | "mid" | "dark")
    var preferredImageTone: String {
        switch self {
        case .riseIgnite, .peakMode:            return "bright"
        case .recharge, .secondWind, .goldenHour: return "mid"
        case .deepDark, .firstLight, .windDown: return "dark"
        }
    }
}
