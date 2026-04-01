import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    var id: UUID
    var time: Date
    var repeatDays: [Int]    // 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
    var theme: String
    var isEnabled: Bool
    var snoozeCount: Int     // 현재 세션 스누즈 횟수 (최대 3)
    var label: String        // 알람 이름 (기본값: 시간대별 자동 이름)
    var snoozeInterval: Int  // 스누즈 간격 분 (기본값: 5)

    init(
        id: UUID = UUID(),
        time: Date,
        repeatDays: [Int] = [0, 1, 2, 3, 4, 5, 6],
        theme: String = "hope",
        isEnabled: Bool = true,
        snoozeCount: Int = 0,
        label: String? = nil,
        snoozeInterval: Int = 5
    ) {
        self.id = id
        self.time = time
        self.repeatDays = repeatDays
        self.theme = theme
        self.isEnabled = isEnabled
        self.snoozeCount = snoozeCount
        self.label = label ?? Alarm.defaultLabel(for: time)
        self.snoozeInterval = snoozeInterval
    }

    // MARK: - Decodable (하위 호환: label/snoozeInterval 없는 기존 데이터 폴백 처리)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        time = try container.decode(Date.self, forKey: .time)
        repeatDays = try container.decode([Int].self, forKey: .repeatDays)
        theme = try container.decode(String.self, forKey: .theme)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        snoozeCount = try container.decode(Int.self, forKey: .snoozeCount)
        // 기존 데이터에 없을 경우 기본값으로 폴백
        let decodedLabel = try container.decodeIfPresent(String.self, forKey: .label)
        label = decodedLabel ?? Alarm.defaultLabel(for: time)
        snoozeInterval = try container.decodeIfPresent(Int.self, forKey: .snoozeInterval) ?? 5
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

    // MARK: - Helpers

    /// 시간대별 기본 알람 이름
    static func defaultLabel(for time: Date) -> String {
        let mode = AppMode.fromTime(time)
        switch mode {
        case .morning:   return "아침의 말씀"
        case .afternoon: return "낮의 말씀"
        case .evening:   return "저녁의 말씀"
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, time, theme
        case repeatDays = "repeat_days"
        case isEnabled = "is_enabled"
        case snoozeCount = "snooze_count"
        case label
        case snoozeInterval = "snooze_interval"
    }
}
