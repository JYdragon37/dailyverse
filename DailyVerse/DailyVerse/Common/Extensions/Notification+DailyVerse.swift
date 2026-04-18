import Foundation

extension Notification.Name {
    static let dvSwitchToAlarmTab = Notification.Name("dvSwitchToAlarmTab")
    /// 저장 탭에서 홈 탭으로 전환 요청
    static let dvSwitchToHomeTab = Notification.Name("dvSwitchToHomeTab")
    /// 알람이 발동되었을 때 (foreground willPresent + background didReceive 공통)
    static let dvAlarmTriggered = Notification.Name("dvAlarmTriggered")
    /// 미디어 볼륨이 0에 가까울 때 — Stage 1에서 볼륨 경고 표시용
    static let dvAlarmVolumeTooLow = Notification.Name("dvAlarmVolumeTooLow")
    /// 묵상 탭으로 전환 요청
    static let dvSwitchToMeditationTab = Notification.Name("dvSwitchToMeditationTab")
    /// 묵상 탭 NavigationStack 루트로 리셋 (묵상 완료 후 홈으로 돌아갈 때)
    static let dvResetMeditationNav = Notification.Name("dvResetMeditationNav")
    /// AlarmKit(iOS 26+) 종료 버튼 탭 — StopAlarmIntent에서 발송
    static let dvAlarmKitStopped = Notification.Name("dvAlarmKitStopped")
}
