import Foundation

/// 온보딩 상태를 관리하는 UserDefaults 키 4개.
/// `@AppStorage` 에서 rawValue를 직접 사용한다.
enum OnboardingKey: String {
    case completed            = "onboardingCompleted"
    case locationRequested    = "locationPermissionRequested"
    case notificationRequested = "notificationPermissionRequested"
    case firstAlarmShown      = "firstAlarmPromptShown"
}
