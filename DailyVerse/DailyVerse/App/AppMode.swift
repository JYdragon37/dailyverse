import Foundation

enum AppMode: String, CaseIterable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"

    static func current() -> AppMode {
        return fromHour(Calendar.current.component(.hour, from: Date()))
    }

    static func fromHour(_ hour: Int) -> AppMode {
        switch hour {
        case 5..<12: return .morning
        case 12..<20: return .afternoon
        default: return .evening
        }
    }

    static func fromTime(_ date: Date) -> AppMode {
        return fromHour(Calendar.current.component(.hour, from: date))
    }

    var greeting: String {
        switch self {
        case .morning: return "Good Morning"
        case .afternoon: return "Good Afternoon"
        case .evening: return "Good Evening"
        }
    }

    var greetingIcon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .afternoon: return "cloud.sun.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    var themes: [String] {
        switch self {
        case .morning: return ["hope", "courage", "strength", "renewal"]
        case .afternoon: return ["wisdom", "focus", "patience", "gratitude"]
        case .evening: return ["peace", "comfort", "reflection", "rest"]
        }
    }

    var moods: [String] {
        switch self {
        case .morning: return ["bright", "dramatic"]
        case .afternoon: return ["calm", "warm"]
        case .evening: return ["serene", "cozy"]
        }
    }
}
