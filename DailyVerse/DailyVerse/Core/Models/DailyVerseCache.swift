import Foundation

struct DailyVerseCache: Codable {
    let date: Date
    var morningVerseId: String?
    var afternoonVerseId: String?
    var eveningVerseId: String?

    // 05:00 기준으로 "오늘"을 판단
    static func isValid(_ cache: DailyVerseCache) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        // 00:00~04:59는 전날로 취급
        let referenceDate: Date
        if hour < 5 {
            referenceDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            referenceDate = now
        }
        return calendar.isDate(cache.date, inSameDayAs: referenceDate)
    }
}
