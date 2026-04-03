import Foundation

// MARK: - AlarmEngine Protocol

/// v5.1 — 듀얼 엔진 알람 시스템
/// iOS 15-25: LegacyAlarmEngine (AVAudioSession 루프)
/// iOS 26+:   AlarmKitEngine (시스템 레벨 알람)
protocol AlarmEngine: AnyObject {
    /// 알람 스케줄 등록
    func schedule(alarm: DailyVerseAlarm) async throws
    /// 알람 취소
    func cancel(alarmId: UUID) async throws
    /// 전체 알람 취소
    func cancelAll() async throws
}

/// 알람 등록에 필요한 데이터 집합체
struct DailyVerseAlarm {
    let alarm: Alarm
    let verse: Verse
}

// MARK: - AlarmEngineFactory

final class AlarmEngineFactory {
    static func make() -> AlarmEngine {
        if #available(iOS 26.0, *) {
            return AlarmKitEngine()
        } else {
            return LegacyAlarmEngine()
        }
    }
}
