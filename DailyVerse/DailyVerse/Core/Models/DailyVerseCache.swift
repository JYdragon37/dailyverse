import Foundation
import SwiftUI

struct DailyVerseCache: Codable {
    let date: Date

    // 모드별 말씀 ID
    var morningVerseId: String?
    var afternoonVerseId: String?
    var eveningVerseId: String?
    var dawnVerseId: String?        // v5.1

    // v5.1 — 모드별 이미지 ID (daily_cards 큐레이션 또는 알고리즘 결과 캐시)
    var morningImageId: String?
    var afternoonImageId: String?
    var eveningImageId: String?
    var dawnImageId: String?

    // 06:00 기준으로 "오늘"을 판단 (v5.1: 05:00 → 06:00 변경)
    static func isValid(_ cache: DailyVerseCache) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        // 00:00~05:59는 전날로 취급
        let referenceDate: Date
        if hour < 6 {
            referenceDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            referenceDate = now
        }
        return calendar.isDate(cache.date, inSameDayAs: referenceDate)
    }

    // MARK: - Helper

    func verseId(for mode: AppMode) -> String? {
        switch mode {
        case .morning:   return morningVerseId
        case .afternoon: return afternoonVerseId
        case .evening:   return eveningVerseId
        case .dawn:      return dawnVerseId
        }
    }

    func imageId(for mode: AppMode) -> String? {
        switch mode {
        case .morning:   return morningImageId
        case .afternoon: return afternoonImageId
        case .evening:   return eveningImageId
        case .dawn:      return dawnImageId
        }
    }

    mutating func setVerseId(_ id: String, for mode: AppMode) {
        switch mode {
        case .morning:   morningVerseId   = id
        case .afternoon: afternoonVerseId = id
        case .evening:   eveningVerseId   = id
        case .dawn:      dawnVerseId      = id
        }
    }

    mutating func setImageId(_ id: String, for mode: AppMode) {
        switch mode {
        case .morning:   morningImageId   = id
        case .afternoon: afternoonImageId = id
        case .evening:   eveningImageId   = id
        case .dawn:      dawnImageId      = id
        }
    }

    var hasAnyVerse: Bool {
        return morningVerseId != nil || afternoonVerseId != nil
            || eveningVerseId != nil || dawnVerseId != nil
    }
}
