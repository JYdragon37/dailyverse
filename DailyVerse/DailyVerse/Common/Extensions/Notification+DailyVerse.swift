import Foundation

extension Notification.Name {
    static let dvSwitchToAlarmTab = Notification.Name("dvSwitchToAlarmTab")
    /// 저장 탭에서 홈 탭으로 전환 요청
    static let dvSwitchToHomeTab = Notification.Name("dvSwitchToHomeTab")
    /// 알람이 발동되었을 때 (foreground willPresent + background didReceive 공통)
    static let dvAlarmTriggered = Notification.Name("dvAlarmTriggered")
}
