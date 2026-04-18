import AlarmKit
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - AlarmKit Metadata (메인 앱과 동일 구조)

struct DailyVerseAlarmMetadata: AlarmMetadata {
    var alarmIdString: String
    var verseShortKo: String
}

// DVPostAlarmAttributes는 Shared/DVPostAlarmAttributes.swift에 정의됨
// (양쪽 타겟 공유 — unsupportedTarget 에러 방지)

// MARK: - AlarmKit Live Activity (시스템 알람 잠금화면)

struct DailyVerseAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<DailyVerseAlarmMetadata>.self) { context in
            lockScreenView(
                alarmId: context.attributes.metadata?.alarmIdString ?? "",
                verse: context.attributes.metadata?.verseShortKo ?? ""
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text("DailyVerse 알람")
                        .font(.system(size: 14, weight: .semibold))
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))
            } compactTrailing: {
                Text("DV").font(.caption2.bold())
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))
            }
        }
    }
}

// MARK: - Post-Alarm Live Activity (잠금화면 "알람 종료" 버튼)
// AlarmKit 종료 후 잠금화면에 표시 → Face ID 후 탭 → 앱 오픈

struct DVPostAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DVPostAlarmAttributes.self) { context in
            postAlarmLockScreen(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DailyVerse")
                            .font(.system(size: 14, weight: .semibold))
                        Text(context.attributes.verseShortKo)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Link(destination: URL(string: "dailyverse://alarm-stop?id=\(context.attributes.alarmIdString)")!) {
                        Text("열기")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.87, green: 0.67, blue: 0.20))
                            .clipShape(Capsule())
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))
            } compactTrailing: {
                Link(destination: URL(string: "dailyverse://alarm-stop?id=\(context.attributes.alarmIdString)")!) {
                    Text("열기")
                        .font(.caption2.bold())
                        .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))
                }
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))
            }
            .widgetURL(URL(string: "dailyverse://alarm-stop?id=\(context.attributes.alarmIdString)"))
        }
    }

    @ViewBuilder
    private func postAlarmLockScreen(context: ActivityViewContext<DVPostAlarmAttributes>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 22))
                .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))

            VStack(alignment: .leading, spacing: 2) {
                Text("DailyVerse")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(context.attributes.verseShortKo)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()

            // 잠금화면 "알람 종료" 버튼 → 탭 → URL → 앱 오픈 → Stage2
            Link(destination: URL(string: "dailyverse://alarm-stop?id=\(context.attributes.alarmIdString)")!) {
                Text("말씀 보기")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.09, green: 0.09, blue: 0.15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color(red: 0.87, green: 0.67, blue: 0.20))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.13))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Shared Lock Screen View

private func lockScreenView(alarmId: String, verse: String) -> some View {
    HStack(spacing: 14) {
        Image(systemName: "alarm.fill")
            .font(.system(size: 22))
            .foregroundColor(Color(red: 0.87, green: 0.67, blue: 0.20))

        VStack(alignment: .leading, spacing: 2) {
            Text("DailyVerse 알람")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            if !verse.isEmpty {
                Text(verse)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
        }

        Spacer()

        Link(destination: URL(string: "dailyverse://alarm-stop?id=\(alarmId)")!) {
            Text("말씀 보기")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.09, green: 0.09, blue: 0.15))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color(red: 0.87, green: 0.67, blue: 0.20))
                )
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.13))
    .activitySystemActionForegroundColor(.white)
}
