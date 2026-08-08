import SwiftUI
import Combine

// v5.1 — 단일 플랜으로 전환. UpsellManager는 향후 구독 도입 시 재활성화.
// 현재는 shouldShow가 항상 false를 반환하여 업셀 시트가 표시되지 않음.

enum UpsellTrigger: String {
    case saveVerse   = "save_verse"
    case savedAd     = "saved_ad"
    case savedLocked = "saved_locked"
    case alarmTheme  = "alarm_theme"

    var message: String {
        switch self {
        case .saveVerse:   return appLanguageString("upsell.trigger.saveVerse")
        case .savedAd:     return appLanguageString("upsell.trigger.savedAd")
        case .savedLocked: return appLanguageString("upsell.trigger.savedLocked")
        case .alarmTheme:  return appLanguageString("upsell.trigger.alarmTheme")
        }
    }
}

@MainActor
class UpsellManager: ObservableObject {
    @Published var shouldShow: Bool = false
    @Published var currentTrigger: UpsellTrigger = .saveVerse

    // v5.1: 단일 플랜 — 모든 업셀 비활성화
    func canShow(trigger: UpsellTrigger) -> Bool { return false }
    func show(trigger: UpsellTrigger) { /* 단일 플랜에서는 아무것도 하지 않음 */ }
    func resetSession() {}
}
