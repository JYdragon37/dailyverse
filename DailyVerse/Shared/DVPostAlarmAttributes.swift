import ActivityKit
import Foundation

/// AlarmKit 종료 후 잠금화면 Live Activity 표시용 Attributes
/// ⚠️ 이 파일은 DailyVerse 메인 앱 + DailyVerseWidgetsExtension 양쪽 타겟에 포함되어야 합니다.
/// Xcode: File Inspector → Target Membership → 두 타겟 모두 체크
struct DVPostAlarmAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isStopped: Bool
    }
    var alarmIdString: String
    var verseShortKo: String
}
