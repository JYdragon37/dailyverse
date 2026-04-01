import SwiftUI
import Combine

enum UpsellTrigger: String {
    case nextVerse = "next_verse"
    case saveVerse = "save_verse"
    case savedAd = "saved_ad"
    case savedLocked = "saved_locked"
    case alarmTheme = "alarm_theme"

    var message: String {
        switch self {
        case .nextVerse: return "오늘 말씀이 더 필요하신가요?"
        case .saveVerse: return "이 말씀을 간직하고 싶으신가요?"
        case .savedAd: return "광고 없이 모든 기록을 되돌아보세요"
        case .savedLocked: return "모든 말씀 기록을 되돌아보세요"
        case .alarmTheme: return "지금 필요한 말씀을 직접 고르세요"
        }
    }
}

@MainActor
class UpsellManager: ObservableObject {
    @Published var shouldShow: Bool = false
    @Published var currentTrigger: UpsellTrigger = .nextVerse

    private var sessionShowCount: Int = 0
    private let maxPerSession = 2

    func canShow(trigger: UpsellTrigger) -> Bool {
        guard sessionShowCount < maxPerSession else { return false }
        let key = "upsellLastShown_\(trigger.rawValue)"
        if let lastShown = UserDefaults.standard.object(forKey: key) as? Date {
            return Date().timeIntervalSince(lastShown) >= 86400
        }
        return true
    }

    func show(trigger: UpsellTrigger) {
        guard canShow(trigger: trigger) else { return }
        currentTrigger = trigger
        shouldShow = true
        sessionShowCount += 1
        UserDefaults.standard.set(Date(), forKey: "upsellLastShown_\(trigger.rawValue)")
    }

    func resetSession() {
        sessionShowCount = 0
    }
}
