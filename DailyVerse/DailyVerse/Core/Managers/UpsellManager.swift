import SwiftUI
import Combine

// v5.1 — 단일 플랜으로 전환. UpsellManager는 향후 구독 도입 시 재활성화.
// 현재는 shouldShow가 항상 false를 반환하여 업셀 시트가 표시되지 않음.

enum UpsellTrigger: String {
    case nextVerse   = "next_verse"
    case saveVerse   = "save_verse"
    case savedAd     = "saved_ad"
    case savedLocked = "saved_locked"
    case alarmTheme  = "alarm_theme"

    var message: String {
        switch self {
        case .nextVerse:   return "오늘 말씀이 더 필요하신가요?"
        case .saveVerse:   return "이 말씀을 간직하고 싶으신가요?"
        case .savedAd:     return "광고 없이 모든 기록을 되돌아보세요"
        case .savedLocked: return "모든 말씀 기록을 되돌아보세요"
        case .alarmTheme:  return "지금 필요한 말씀을 직접 고르세요"
        }
    }
}

@MainActor
class UpsellManager: ObservableObject {
    @Published var shouldShow: Bool = false
    @Published var currentTrigger: UpsellTrigger = .nextVerse

    // v5.1: 단일 플랜 — 모든 업셀 비활성화
    func canShow(trigger: UpsellTrigger) -> Bool { return false }
    func show(trigger: UpsellTrigger) { /* 단일 플랜에서는 아무것도 하지 않음 */ }
    func resetSession() {}
}
