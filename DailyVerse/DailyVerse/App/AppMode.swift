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
        case .deepDark:   return "Still up,\nNight Owl?"
        case .firstLight: return "Rise before the world."
        case .riseIgnite: return "Good Morning"
        case .peakMode:   return "In the Zone,"
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

    // MARK: - 알람 전용 인사말 (일어날 시간 뉘앙스)

    /// 알람 화면 전용 한국어 인사말 — Firestore alarm_greetings 폴백
    var alarmGreetingKr: String {
        switch self {
        case .deepDark:   return "이 시간에 일어나셨군요."
        case .firstLight: return "일어날 시간이에요."
        case .riseIgnite: return "좋은 아침이에요, 일어날 시간이에요!"
        case .peakMode:   return "오전 알람이에요, 일어나세요!"
        case .recharge:   return "점심 알람이에요."
        case .secondWind: return "오후 알람이에요."
        case .goldenHour: return "저녁 알람이에요."
        case .windDown:   return "밤 알람이에요."
        }
    }

    /// 알람 화면 전용 영어 인사말
    var alarmGreetingEn: String {
        switch self {
        case .deepDark:   return "Time to wake up."
        case .firstLight: return "Rise and shine!"
        case .riseIgnite: return "Good morning! Time to rise!"
        case .peakMode:   return "Wake up, it's morning!"
        case .recharge:   return "Midday alarm!"
        case .secondWind: return "Afternoon alarm!"
        case .goldenHour: return "Evening alarm!"
        case .windDown:   return "Night alarm!"
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
            return [Color(hex: "#11131A"), Color(hex: "#1A1F31")]
        case .firstLight:
            return [Color(hex: "#171E33"), Color(hex: "#365B8A")]
        case .riseIgnite:
            return [Color(hex: "#2E3656"), Color(hex: "#8DB8DA"), Color(hex: "#E8C8D2")]
        case .peakMode:
            return [Color(hex: "#243246"), Color(hex: "#4D6A8F")]
        case .recharge:
            return [Color(hex: "#274040"), Color(hex: "#56727D")]
        case .secondWind:
            return [Color(hex: "#3A4251"), Color(hex: "#7A7F9A")]
        case .goldenHour:
            return [Color(hex: "#47364B"), Color(hex: "#A9828F")]
        case .windDown:
            return [Color(hex: "#161923"), Color(hex: "#2A3150")]
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

    // MARK: - 구 mode 값 호환 (마이그레이션 방어 레이어)
    // Firestore images/ 컬렉션이 구 mode 값(morning/afternoon/evening/dawn)을 가질 경우를 대비

    /// 이미지 mode 배열이 현재 Zone에 해당하는지 확인 (구 mode 값 포함)
    func matchesImageMode(_ modes: [String]) -> Bool {
        if modes.contains("all") || modes.contains(self.rawValue) { return true }
        // 구 mode 값 → 새 Zone 호환 매핑
        for m in modes {
            switch m {
            case "morning":   if self == .riseIgnite || self == .peakMode   { return true }
            case "afternoon": if self == .recharge   || self == .secondWind { return true }
            case "evening":   if self == .goldenHour || self == .windDown   { return true }
            case "dawn":      if self == .firstLight || self == .deepDark   { return true }
            default: break
            }
        }
        return false
    }
}
