import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    var id: UUID
    var time: Date
    var repeatDays: [Int]    // 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
    var theme: String
    var isEnabled: Bool
    var snoozeCount: Int     // 현재 세션 스누즈 횟수 (최대 3)

    init(id: UUID = UUID(), time: Date, repeatDays: [Int] = [0,1,2,3,4,5,6], theme: String = "hope", isEnabled: Bool = true, snoozeCount: Int = 0) {
        self.id = id
        self.time = time
        self.repeatDays = repeatDays
        self.theme = theme
        self.isEnabled = isEnabled
        self.snoozeCount = snoozeCount
    }

    var repeatSummary: String {
        if repeatDays.count == 7 { return "매일" }
        let weekdays = [1,2,3,4,5]
        let weekends = [0,6]
        if Set(repeatDays) == Set(weekdays) { return "주중" }
        if Set(repeatDays) == Set(weekends) { return "주말" }
        let names = ["일","월","화","수","목","금","토"]
        return repeatDays.sorted().map { names[$0] }.joined(separator: " ")
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    enum CodingKeys: String, CodingKey {
        case id, time, theme
        case repeatDays = "repeat_days"
        case isEnabled = "is_enabled"
        case snoozeCount = "snooze_count"
    }
}
