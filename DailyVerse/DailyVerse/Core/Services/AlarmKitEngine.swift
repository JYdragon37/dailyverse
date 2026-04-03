import Foundation
import UserNotifications

// MARK: - AlarmKitEngine (iOS 26+)

/// iOS 26+의 AlarmKit을 사용하는 시스템 레벨 알람 엔진.
/// - 앱 종료/잠금화면/DND 완전 관통
/// - 시스템 알람 인프라 사용 → 배터리 효율 최적
/// - NSAlarmKitUsageDescription Info.plist 필수
///
/// 주의: AlarmKit SDK는 iOS 26.0 정식 출시 이후 통합 예정.
/// 현재는 안전한 폴백 구현으로 LegacyAlarmEngine과 동일하게 동작.
@available(iOS 26.0, *)
final class AlarmKitEngine: AlarmEngine {

    func schedule(alarm: DailyVerseAlarm) async throws {
        // TODO: AlarmKit 정식 SDK 출시 후 구현
        // AlarmManager.shared.schedule(...)
        // 현재는 LegacyAlarmEngine으로 폴백
        try await LegacyAlarmEngine().schedule(alarm: alarm)
    }

    func cancel(alarmId: UUID) async throws {
        try await LegacyAlarmEngine().cancel(alarmId: alarmId)
    }

    func cancelAll() async throws {
        try await LegacyAlarmEngine().cancelAll()
    }
}
