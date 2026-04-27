import WidgetKit
import SwiftUI

@main
struct DailyVerseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DVPostAlarmLiveActivity()       // "밀어서 중단" 후 잠금화면 "말씀 보기" 버튼 (iOS 16.1+)
        if #available(iOS 26.0, *) {
            DailyVerseAlarmLiveActivity()   // AlarmKit 시스템 알람 잠금화면 (iOS 26+)
        }
    }
}
