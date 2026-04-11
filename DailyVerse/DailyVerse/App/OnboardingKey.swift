import Foundation

/// 온보딩 상태를 관리하는 UserDefaults 키 5개 (v5.1: nicknameSet 추가).
/// `@AppStorage` 에서 rawValue를 직접 사용한다.
enum OnboardingKey: String {
    case completed             = "onboardingCompleted"        // v1 레거시 (호환성 유지)
    case newCompleted          = "onboardingV2Completed"      // v2 신규 온보딩 (2026.04)
    case nicknameSet           = "nicknameSet"
    case locationRequested     = "locationPermissionRequested"
    case notificationRequested = "notificationPermissionRequested"
    case firstAlarmShown       = "firstAlarmPromptShown"
}
