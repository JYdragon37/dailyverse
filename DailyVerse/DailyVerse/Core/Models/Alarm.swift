import Foundation
import SwiftUI

struct Alarm: Identifiable, Codable, Equatable {
    var id: UUID
    var time: Date
    var repeatDays: [Int]       // 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
    var theme: String
    var isEnabled: Bool
    var snoozeCount: Int        // 현재 세션 스누즈 횟수
    var label: String
    var snoozeInterval: Int     // 스누즈 간격 분 (1/3/5/10 중 선택, 기본값: 5)
    var maxSnoozeCount: Int     // 최대 스누즈 횟수 (0~10, 기본값: 3)
    var wakeMission: String     // "none" | "shake" | "math" | "typing"
    var soundId: String         // "piano" | "nature" | "hymn"
    var volume: Float           // 0.0~1.0 (기본값: 0.8)
    var alertStyle: String      // "sound" | "vibration" | "soundAndVibration"

    init(
        id: UUID = UUID(),
        time: Date,
        repeatDays: [Int] = [0, 1, 2, 3, 4, 5, 6],
        theme: String = "hope",
        isEnabled: Bool = true,
        snoozeCount: Int = 0,
        label: String? = nil,
        snoozeInterval: Int = 5,
        maxSnoozeCount: Int = 3,
        wakeMission: String = "none",
        soundId: String = "song",
        volume: Float = 0.8,
        alertStyle: String = "soundAndVibration"
    ) {
        self.id = id
        self.time = time
        self.repeatDays = repeatDays
        self.theme = theme
        self.isEnabled = isEnabled
        self.snoozeCount = snoozeCount
        self.label = label ?? Alarm.defaultLabel(for: time)
        self.snoozeInterval = snoozeInterval
        self.maxSnoozeCount = maxSnoozeCount
        self.wakeMission = wakeMission
        self.soundId = soundId
        self.volume = volume
        self.alertStyle = alertStyle
    }

    // MARK: - Decodable (하위 호환: 기존 필드 없을 때 기본값 폴백)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id           = try container.decode(UUID.self, forKey: .id)
        time         = try container.decode(Date.self, forKey: .time)
        repeatDays   = try container.decode([Int].self, forKey: .repeatDays)
        theme        = try container.decode(String.self, forKey: .theme)
        isEnabled    = try container.decode(Bool.self, forKey: .isEnabled)
        snoozeCount  = try container.decode(Int.self, forKey: .snoozeCount)
        let decodedLabel = try container.decodeIfPresent(String.self, forKey: .label)
        label        = decodedLabel ?? Alarm.defaultLabel(for: time)
        snoozeInterval   = try container.decodeIfPresent(Int.self,    forKey: .snoozeInterval)   ?? 5
        maxSnoozeCount   = try container.decodeIfPresent(Int.self,    forKey: .maxSnoozeCount)   ?? 3
        wakeMission      = try container.decodeIfPresent(String.self, forKey: .wakeMission)      ?? "none"
        soundId          = try container.decodeIfPresent(String.self, forKey: .soundId)          ?? "song"
        volume           = try container.decodeIfPresent(Float.self,  forKey: .volume)           ?? 0.8
        alertStyle       = try container.decodeIfPresent(String.self, forKey: .alertStyle)       ?? "soundAndVibration"
    }

    // MARK: - Computed Properties

    var repeatSummary: String {
        if repeatDays.count == 7 { return "매일" }
        let weekdays = [1, 2, 3, 4, 5]
        let weekends = [0, 6]
        if Set(repeatDays) == Set(weekdays) { return "주중" }
        if Set(repeatDays) == Set(weekends) { return "주말" }
        let names = ["일", "월", "화", "수", "목", "금", "토"]
        return repeatDays.sorted().map { names[$0] }.joined(separator: " ")
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    var canSnooze: Bool {
        return snoozeCount < maxSnoozeCount
    }

    var wakeMissionDisplayName: String {
        switch wakeMission {
        case "shake":  return "흔들기"
        case "math":   return "수학 문제"
        case "typing": return "타이핑"
        default:       return "없음"
        }
    }

    var soundDisplayName: String {
        switch soundId {
        case "song":   return "알람송"
        case "nature": return "자연 소리"
        case "hymn":   return "찬양 멜로디"
        default:       return "알람송"
        }
    }

    // MARK: - Helpers

    static func defaultLabel(for time: Date) -> String {
        let mode = AppMode.fromTime(time)
        switch mode {
        case .deepDark:   return "Deep Dark의 말씀"
        case .firstLight: return "새벽 말씀"
        case .riseIgnite: return "아침의 말씀"
        case .peakMode:   return "집중의 말씀"
        case .recharge:   return "점심 말씀"
        case .secondWind: return "오후의 말씀"
        case .goldenHour: return "저녁의 말씀"
        case .windDown:   return "밤의 말씀"
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, time, theme, label, volume
        case repeatDays      = "repeat_days"
        case isEnabled       = "is_enabled"
        case snoozeCount     = "snooze_count"
        case snoozeInterval  = "snooze_interval"
        case maxSnoozeCount  = "max_snooze_count"
        case wakeMission     = "wake_mission"
        case soundId         = "sound_id"
        case alertStyle      = "alert_style"
    }
}
