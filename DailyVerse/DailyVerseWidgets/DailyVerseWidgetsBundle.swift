import WidgetKit
import SwiftUI

@main
struct DailyVerseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DailyVerseAlarmLiveActivity()   // AlarmKit 시스템 알람 잠금화면
        DVPostAlarmLiveActivity()       // "밀어서 중단" 후 잠금화면 "말씀 보기" 버튼
    }
}
