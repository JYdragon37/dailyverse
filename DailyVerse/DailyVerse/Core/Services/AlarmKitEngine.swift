import Foundation
import UserNotifications
import AlarmKit
import AppIntents
import ActivityKit
import SwiftUI
import OSLog

private let kitLog = Logger(subsystem: "com.dailyverse", category: "AlarmKitEngine")

// DVPostAlarmAttributes는 Shared/DVPostAlarmAttributes.swift에 정의됨
// (양쪽 타겟 공유 — unsupportedTarget 에러 방지)

// MARK: - AlarmMetadata
// AlarmMetadata = Codable + Hashable + Sendable

@available(iOS 26.0, *)
struct DailyVerseAlarmMetadata: AlarmMetadata {
    var alarmIdString: String
    var verseShortKo: String   // 잠금화면 Live Activity 말씀 미리보기용
}

// MARK: - Stop Intent
// LiveActivityIntent 채택 필수 (AlarmConfiguration.stopIntent 요건)

@available(iOS 26.0, *)
struct DVStopAlarmIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "알람 종료"

    // ★ 핵심: .foreground(.immediate) = 앱을 반드시 포그라운드로 열고 나서 perform() 실행
    // ForegroundContinuableIntent의 requestToContinueInForeground()는 "요청"이라 거부 가능
    // supportedModes: .foreground(.immediate)는 "강제"라 잠금화면에서도 Face ID → 앱 열림
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Alarm ID")
    var alarmIdString: String

    init() { self.alarmIdString = "" }
    init(alarmIdString: String) { self.alarmIdString = alarmIdString }

    func perform() async throws -> some IntentResult {
        // perform() 실행 시점에 앱은 이미 포그라운드 상태 (supportedModes 보장)
        kitLog.info("✅ [AlarmKit] StopIntent 포그라운드 실행 — \(self.alarmIdString)")

        // 1. pending 저장 (콜드런치 대응)
        UserDefaults.standard.set(alarmIdString, forKey: "pendingAlarmKitStop")
        UserDefaults.standard.set(AppMode.current().rawValue, forKey: "pendingAlarmKitStopMode")
        UserDefaults.standard.synchronize()

        // 2. Stage2 세팅
        NotificationCenter.default.post(
            name: .dvAlarmTriggered,
            object: nil,
            userInfo: ["alarm_id": alarmIdString, "alarmkit_stop": true]
        )

        // 3. Live Activity 상태 업데이트
        for activity in Activity<DVPostAlarmAttributes>.activities {
            let updatedState = DVPostAlarmAttributes.ContentState(isStopped: true)
            let content = ActivityContent(state: updatedState, staleDate: Date().addingTimeInterval(300))
            await activity.update(content)
        }

        return .result()
    }
}

// MARK: - AlarmKitEngine (iOS 26+)
// Alarm.ID = Foundation.UUID  (SDK 헤더 확인: public typealias ID = Foundation.UUID)
// AlarmPresentation.Alert.stopButton = iOS 26.1 deprecated → title: 만 필수

@available(iOS 26.0, *)
final class AlarmKitEngine: AlarmEngine {

    private let manager = AlarmManager.shared

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let state = try await manager.requestAuthorization()
            kitLog.info("✅ [AlarmKit] 권한: \(String(describing: state))")
            return state == .authorized
        } catch {
            kitLog.error("❌ [AlarmKit] 권한 실패: \(error)")
            return false
        }
    }

    // MARK: - AlarmEngine Protocol

    func schedule(alarm: DailyVerseAlarm) async throws {
        let a = alarm.alarm
        let verse = alarm.verse
        guard a.isEnabled else { return }

        let authorized = await requestAuthorization()
        guard authorized else {
            kitLog.warning("⚠️ [AlarmKit] 미권한 → LegacyEngine 폴백")
            try await LegacyAlarmEngine().schedule(alarm: alarm)
            return
        }

        // 기존 취소
        try await cancel(alarmId: a.id)

        // 스누즈 버튼
        let snoozeButton = AlarmButton(
            text: "\(a.snoozeInterval)분 스누즈",
            textColor: .white,
            systemImageName: "repeat.circle.fill"
        )

        // AlarmPresentation.Alert
        // iOS 26.1+: stopButton deprecated, title: 만 사용
        // iOS 26.0:  deprecated init으로 stopButton 필수
        let alertPresentation: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alertPresentation = AlarmPresentation.Alert(
                title: "DailyVerse 🔔",
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
        } else {
            let stopButton = AlarmButton(
                text: "종료",
                textColor: .white,
                systemImageName: "xmark.circle.fill"
            )
            alertPresentation = AlarmPresentation.Alert(
                title: "DailyVerse 🔔",
                stopButton: stopButton,
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
        }
        let presentation = AlarmPresentation(alert: alertPresentation)

        // AlarmAttributes<Metadata>(presentation:metadata:tintColor:)
        let metadata = DailyVerseAlarmMetadata(
            alarmIdString: a.id.uuidString,
            verseShortKo: verse.verseShortKo
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color(red: 0.87, green: 0.67, blue: 0.20)  // dvAccentGold
        )

        // Alarm.Schedule 생성
        // 일회성: .fixed(Date)
        // 요일 반복: .relative(Alarm.Schedule.Relative) → 1개 알람으로 처리
        guard let schedule = buildSchedule(alarm: a) else {
            kitLog.warning("⚠️ [AlarmKit] 스케줄 계산 실패")
            return
        }

        let config = AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: DVStopAlarmIntent(alarmIdString: a.id.uuidString),
            secondaryIntent: nil,
            sound: .named("alarm_song.mp3")   // 커스텀 알람 사운드 (번들 파일명 그대로)
        )

        // Alarm.ID = Foundation.UUID → a.id 직접 사용
        let scheduled = try await manager.schedule(id: a.id, configuration: config)
        kitLog.info("✅ [AlarmKit] 등록 완료 — id: \(scheduled.id), state: \(String(describing: scheduled.state))")

        // ★ 알람 등록 시점(포그라운드)에서 Live Activity 시작
        // "밀어서 중단" 후 잠금화면에 "말씀 보기" 버튼이 남아있게 됨
        // (StopIntent는 백그라운드라 Activity.request 불가 → 여기서 미리 시작)
        do {
            // 기존 Live Activity 정리
            for activity in Activity<DVPostAlarmAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            let postAlarmAttrs = DVPostAlarmAttributes(
                alarmIdString: a.id.uuidString,
                verseShortKo: verse.verseShortKo
            )
            let state = DVPostAlarmAttributes.ContentState(isStopped: false)
            let content = ActivityContent(state: state, staleDate: nil)
            _ = try Activity.request(
                attributes: postAlarmAttrs,
                content: content,
                pushType: nil
            )
            kitLog.info("✅ [AlarmKit] Post-alarm Live Activity 시작됨 (알람 등록 시점)")
        } catch {
            kitLog.error("❌ [AlarmKit] Live Activity 시작 실패: \(error)")
        }
    }

    func cancel(alarmId: UUID) async throws {
        // manager.cancel(id:) → throws (not async)
        try? manager.cancel(id: alarmId)
        // Legacy UNNotification 백업도 취소
        try await LegacyAlarmEngine().cancel(alarmId: alarmId)
    }

    func cancelAll() async throws {
        if let registered = try? manager.alarms {
            for alarm in registered {
                try? manager.cancel(id: alarm.id)
            }
        }
        try await LegacyAlarmEngine().cancelAll()
        kitLog.info("🗑 [AlarmKit] 전체 취소 완료")
    }

    // MARK: - Schedule Builder
    // 일회성: Alarm.Schedule.fixed(Date)
    // 요일 반복: Alarm.Schedule.relative(Relative(time:repeats:.weekly([Locale.Weekday])))
    //   → 하나의 알람으로 전체 요일 처리 (AlarmKit 반복 알람 네이티브 지원)

    private func buildSchedule(alarm: Alarm) -> AlarmKit.Alarm.Schedule? {
        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: alarm.time)
        guard let h = hm.hour, let m = hm.minute else { return nil }

        if alarm.repeatDays.isEmpty {
            // 일회성: 가장 가까운 해당 시각
            var dc = DateComponents(); dc.hour = h; dc.minute = m; dc.second = 0
            guard let date = cal.nextDate(after: Date() - 60, matching: dc, matchingPolicy: .nextTime)
            else { return nil }
            return .fixed(date)
        } else {
            // 요일 반복: Locale.Weekday 배열로 변환 (0=일 → .sunday, 1=월 → .monday ...)
            let weekdays: [Locale.Weekday] = alarm.repeatDays.compactMap { day in
                switch day {
                case 0: return .sunday
                case 1: return .monday
                case 2: return .tuesday
                case 3: return .wednesday
                case 4: return .thursday
                case 5: return .friday
                case 6: return .saturday
                default: return nil
                }
            }
            guard !weekdays.isEmpty else { return nil }
            let time       = AlarmKit.Alarm.Schedule.Relative.Time(hour: h, minute: m)
            let recurrence = AlarmKit.Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
            let relative   = AlarmKit.Alarm.Schedule.Relative(time: time, repeats: recurrence)
            return .relative(relative)
        }
    }
}
