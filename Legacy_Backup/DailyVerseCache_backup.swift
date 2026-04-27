import Foundation
import SwiftUI

// v6.0 — 8 Zone 캐시 구조

struct DailyVerseCache: Codable {
    let date: Date

    // 하루 1개 verse — 04:00에 확정, 모든 탭에서 공유
    var todayVerseId: String?

    // 기본값 init — date만 필요, 나머지는 nil
    init(date: Date = Date()) {
        self.date = date
    }

    // Zone별 말씀 ID (레거시 — todayVerseId 우선)
    var deepDarkVerseId: String?    // Zone 1: 00–03
    var firstLightVerseId: String?  // Zone 2: 03–06
    var riseIgniteVerseId: String?  // Zone 3: 06–09
    var peakModeVerseId: String?    // Zone 4: 09–12
    var rechargeVerseId: String?    // Zone 5: 12–15
    var secondWindVerseId: String?  // Zone 6: 15–18
    var goldenHourVerseId: String?  // Zone 7: 18–21
    var windDownVerseId: String?    // Zone 8: 21–24

    // Zone별 이미지 ID
    var deepDarkImageId: String?
    var firstLightImageId: String?
    var riseIgniteImageId: String?
    var peakModeImageId: String?
    var rechargeImageId: String?
    var secondWindImageId: String?
    var goldenHourImageId: String?
    var windDownImageId: String?

    // 04:00 기준으로 "오늘"을 판단 (새벽 00–03은 전날 취급)
    static func isValid(_ cache: DailyVerseCache) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let referenceDate: Date
        if hour < 4 {
            referenceDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            referenceDate = now
        }
        return calendar.isDate(cache.date, inSameDayAs: referenceDate)
    }

    // MARK: - Helper

    func verseId(for mode: AppMode) -> String? {
        switch mode {
        case .deepDark:   return deepDarkVerseId
        case .firstLight: return firstLightVerseId
        case .riseIgnite: return riseIgniteVerseId
        case .peakMode:   return peakModeVerseId
        case .recharge:   return rechargeVerseId
        case .secondWind: return secondWindVerseId
        case .goldenHour: return goldenHourVerseId
        case .windDown:   return windDownVerseId
        }
    }

    func imageId(for mode: AppMode) -> String? {
        switch mode {
        case .deepDark:   return deepDarkImageId
        case .firstLight: return firstLightImageId
        case .riseIgnite: return riseIgniteImageId
        case .peakMode:   return peakModeImageId
        case .recharge:   return rechargeImageId
        case .secondWind: return secondWindImageId
        case .goldenHour: return goldenHourImageId
        case .windDown:   return windDownImageId
        }
    }

    mutating func setVerseId(_ id: String, for mode: AppMode) {
        switch mode {
        case .deepDark:   deepDarkVerseId   = id
        case .firstLight: firstLightVerseId = id
        case .riseIgnite: riseIgniteVerseId = id
        case .peakMode:   peakModeVerseId   = id
        case .recharge:   rechargeVerseId   = id
        case .secondWind: secondWindVerseId = id
        case .goldenHour: goldenHourVerseId = id
        case .windDown:   windDownVerseId   = id
        }
    }

    mutating func setImageId(_ id: String, for mode: AppMode) {
        switch mode {
        case .deepDark:   deepDarkImageId   = id
        case .firstLight: firstLightImageId = id
        case .riseIgnite: riseIgniteImageId = id
        case .peakMode:   peakModeImageId   = id
        case .recharge:   rechargeImageId   = id
        case .secondWind: secondWindImageId = id
        case .goldenHour: goldenHourImageId = id
        case .windDown:   windDownImageId   = id
        }
    }

    var hasAnyVerse: Bool {
        return todayVerseId != nil ||
               deepDarkVerseId != nil || firstLightVerseId != nil ||
               riseIgniteVerseId != nil || peakModeVerseId != nil ||
               rechargeVerseId != nil || secondWindVerseId != nil ||
               goldenHourVerseId != nil || windDownVerseId != nil
    }
}
