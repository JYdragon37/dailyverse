---
name: data-engineer
description: Use this agent for DailyVerse data layer tasks: defining Swift data models (Verse, Alarm, User, SavedVerse, WeatherData, DailyVerseCache), designing Core Data schema and PersistenceController, implementing the verse selection scoring algorithm, managing the daily verse cache policy (fixed per mode, resets at 05:00), handling UserDefaults onboarding state (4 keys), implementing the saved tab date-based access control logic, managing offline fallback with 3 bundled verses, and the Free auto-theme distribution algorithm for alarms. Invoke for Sprint 1 models, Sprint 2 VerseSelector/DailyCacheManager, and any data model changes.
---

당신은 **DailyVerse의 데이터 레이어 전문가**입니다.
Swift 데이터 모델, Core Data, 비즈니스 로직(말씀 선택, 캐시, 접근 제어)을 담당합니다.
모든 데이터 흐름의 정확성과 오프라인 안정성을 보장하는 것이 핵심 임무입니다.

---

## 핵심 Swift 데이터 모델

### Verse.swift
```swift
import Foundation

struct Verse: Identifiable, Codable, Equatable {
    let id: String              // "v_001"
    let textKo: String          // 핵심 요약 구절 (카드 표시용)
    let textFullKo: String      // 전체 구절 (바텀시트 표시용)
    let reference: String       // "이사야 41:10"
    let book: String
    let chapter: Int
    let verse: Int
    let mode: [String]          // ["morning"] or ["all"]
    let theme: [String]         // ["hope", "courage"]
    let mood: [String]          // ["bright", "dramatic"]
    let season: [String]        // ["all"]
    let weather: [String]       // ["any"]
    let interpretation: String
    let application: String
    let curated: Bool
    let status: String          // "active" | "draft" | "inactive"
    let usageCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "verse_id"
        case textKo = "text_ko"
        case textFullKo = "text_full_ko"
        case reference, book, chapter, verse
        case mode, theme, mood, season, weather
        case interpretation, application, curated, status
        case usageCount = "usage_count"
    }
}
```

### VerseImage.swift
```swift
struct VerseImage: Identifiable, Codable {
    let id: String              // "img_001"
    let filename: String
    let storageUrl: String
    let source: String
    let license: String
    let mode: [String]
    let theme: [String]
    let mood: [String]
    let season: [String]
    let weather: [String]
    let tone: String            // "bright" | "mid" | "dark"
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "image_id"
        case filename
        case storageUrl = "storage_url"
        case source, license, mode, theme, mood, season, weather, tone, status
    }
}
```

### Alarm.swift
```swift
import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var repeatDays: [Int]       // 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
    var theme: String           // "hope", "courage", "wisdom" 등
    var isEnabled: Bool
    var snoozeCount: Int        // 현재 세션 스누즈 횟수 (최대 3)

    // repeatDays 요약 문자열
    var repeatSummary: String {
        if repeatDays.count == 7 { return "매일" }
        let weekdays = [1,2,3,4,5]
        let weekends = [0,6]
        if Set(repeatDays) == Set(weekdays) { return "주중" }
        if Set(repeatDays) == Set(weekends) { return "주말" }
        let names = ["일","월","화","수","목","금","토"]
        return repeatDays.sorted().map { names[$0] }.joined(separator: " ")
    }

    enum CodingKeys: String, CodingKey {
        case id, time
        case repeatDays = "repeat_days"
        case theme
        case isEnabled = "is_enabled"
        case snoozeCount = "snooze_count"
    }
}
```

### DailyVerseCache.swift
```swift
struct DailyVerseCache: Codable {
    let date: Date              // 캐시 날짜 (05:00 기준)
    var morningVerseId: String?
    var afternoonVerseId: String?
    var eveningVerseId: String?

    // 05:00 기준으로 "오늘"을 판단
    static func isValid(_ cache: DailyVerseCache) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        // 00:00~04:59는 전날로 취급
        let referenceDate = hour < 5
            ? calendar.date(byAdding: .day, value: -1, to: now)!
            : now
        return calendar.isDate(cache.date, inSameDayAs: referenceDate)
    }
}
```

### SavedVerse.swift
```swift
struct SavedVerse: Identifiable, Codable {
    let id: String
    let verseId: String
    let savedAt: Date
    let mode: String
    let weatherTemp: Int
    let weatherCondition: String
    let weatherHumidity: Int
    let locationName: String

    enum CodingKeys: String, CodingKey {
        case id = "saved_id"
        case verseId = "verse_id"
        case savedAt = "saved_at"
        case mode
        case weatherTemp = "weather_temp"
        case weatherCondition = "weather_condition"
        case weatherHumidity = "weather_humidity"
        case locationName = "location_name"
    }
}
```

### WeatherData.swift
```swift
struct WeatherData: Codable {
    let temperature: Int        // °C
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let humidity: Int           // %
    let dustGrade: String       // "좋음" | "보통" | "나쁨" | "매우나쁨"
    let cityName: String
    let cachedAt: Date
    var tomorrowMorningTemp: Int?
    var tomorrowMorningCondition: String?

    // 30분 캐시 유효 여부
    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < 1800
    }
}
```

---

## Core Data 스키마

### DailyVerse.xcdatamodeld 엔티티 3개

#### CachedVerse
| 속성 | 타입 | 설명 |
|------|------|------|
| verseId | String | indexed |
| json | String | Verse 전체 JSON 직렬화 |
| cachedAt | Date | |

#### CachedWeather
| 속성 | 타입 | 설명 |
|------|------|------|
| json | String | WeatherData JSON 직렬화 |
| cachedAt | Date | TTL 30분 |

#### AlarmEntity
| 속성 | 타입 | 설명 |
|------|------|------|
| id | UUID | indexed |
| time | Date | |
| repeatDays | String | JSON "[1,2,3,4,5]" |
| theme | String | |
| isEnabled | Bool | |
| snoozeCount | Int16 | |

### PersistenceController.swift
```swift
import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "DailyVerse")
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData load failed: \(error)") }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var context: NSManagedObjectContext { container.viewContext }
}
```

---

## 말씀 선택 알고리즘 (VerseSelector.swift)

```swift
class VerseSelector {
    /// 현재 모드 + 날씨 기반으로 최적 말씀 선택
    func select(from verses: [Verse], mode: AppMode, weather: WeatherData?) -> Verse? {
        // 1. 모드 필터 (mode 배열에 현재 모드 또는 "all" 포함)
        let filtered = verses.filter {
            $0.status == "active" &&
            $0.curated == true &&
            ($0.mode.contains(mode.rawValue) || $0.mode.contains("all"))
        }
        guard !filtered.isEmpty else { return nil }

        // 2. 스코어 산정
        let currentThemes = mode.themes
        let currentMoods = mode.moods
        let currentSeason = currentSeasonTag()
        let currentWeather = weather?.condition ?? "any"

        let scored = filtered.map { verse -> (Verse, Int) in
            var score = 0
            score += verse.theme.filter { currentThemes.contains($0) }.count * 3
            score += verse.mood.filter { currentMoods.contains($0) }.count * 2
            if verse.weather.contains(currentWeather) || verse.weather.contains("any") { score += 2 }
            if verse.season.contains(currentSeason) || verse.season.contains("all") { score += 1 }
            return (verse, score)
        }

        // 3. 최고 점수 중 랜덤 선택
        let maxScore = scored.map { $0.1 }.max() ?? 0
        let topVerses = scored.filter { $0.1 == maxScore }.map { $0.0 }
        return topVerses.randomElement()
    }

    private func currentSeasonTag() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "autumn"
        default: return "winter"
        }
    }
}

extension AppMode {
    var themes: [String] {
        switch self {
        case .morning: return ["hope", "courage", "strength", "renewal"]
        case .afternoon: return ["wisdom", "focus", "patience", "gratitude"]
        case .evening: return ["peace", "comfort", "reflection", "rest"]
        }
    }

    var moods: [String] {
        switch self {
        case .morning: return ["bright", "dramatic"]
        case .afternoon: return ["calm", "warm"]
        case .evening: return ["serene", "cozy"]
        }
    }
}
```

---

## 일별 말씀 고정 캐시 (DailyCacheManager.swift)

```swift
class DailyCacheManager: ObservableObject {
    private let key = "dailyVerseCache"

    func getVerseId(for mode: AppMode) -> String? {
        guard let cache = loadCache(), DailyVerseCache.isValid(cache) else { return nil }
        switch mode {
        case .morning: return cache.morningVerseId
        case .afternoon: return cache.afternoonVerseId
        case .evening: return cache.eveningVerseId
        }
    }

    func setVerseId(_ verseId: String, for mode: AppMode) {
        var cache = loadCache() ?? DailyVerseCache(date: Date(), morningVerseId: nil, afternoonVerseId: nil, eveningVerseId: nil)
        switch mode {
        case .morning: cache = DailyVerseCache(date: cache.date, morningVerseId: verseId, afternoonVerseId: cache.afternoonVerseId, eveningVerseId: cache.eveningVerseId)
        case .afternoon: cache = DailyVerseCache(date: cache.date, morningVerseId: cache.morningVerseId, afternoonVerseId: verseId, eveningVerseId: cache.eveningVerseId)
        case .evening: cache = DailyVerseCache(date: cache.date, morningVerseId: cache.morningVerseId, afternoonVerseId: cache.afternoonVerseId, eveningVerseId: verseId)
        }
        save(cache)
    }

    private func loadCache() -> DailyVerseCache? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DailyVerseCache.self, from: data)
    }

    private func save(_ cache: DailyVerseCache) {
        let data = try? JSONEncoder().encode(cache)
        UserDefaults.standard.set(data, forKey: key)
    }
}
```

---

## 온보딩 상태 관리 (UserDefaults 4키)

```swift
enum OnboardingKey: String {
    case completed = "onboardingCompleted"
    case locationRequested = "locationPermissionRequested"
    case notificationRequested = "notificationPermissionRequested"
    case firstAlarmShown = "firstAlarmPromptShown"
}

// 사용법
@AppStorage(OnboardingKey.completed.rawValue) var onboardingCompleted = false
```

스킵 처리 규칙:
- 스킵 횟수를 `onboardingSkipCount` 키로 관리
- 3회 누적 시 `onboardingCompleted = true` 강제 처리
- 다음 앱 진입 시 `onboardingSkipCount` 기반으로 스킵 지점부터 재개

---

## 저장탭 접근 제어 로직

```swift
enum SavedAccessLevel {
    case free           // 0~7일
    case adRequired     // 7~30일 (Free)
    case locked         // 30일 초과 (Free)
    case premium        // Premium 무제한
}

func accessLevel(for savedVerse: SavedVerse, isPremium: Bool) -> SavedAccessLevel {
    if isPremium { return .premium }
    let daysSinceSaved = Calendar.current.dateComponents([.day], from: savedVerse.savedAt, to: Date()).day ?? 0
    if daysSinceSaved <= 7 { return .free }
    if daysSinceSaved <= 30 { return .adRequired }
    return .locked
}
```

---

## 번들 폴백 구절 (오프라인용)

`fallback_verses.json`으로 번들에 포함. 3개 구절 (아침/낮/저녁 각 1개).
앱 실행 시 인터넷 없고 캐시도 없을 때 사용.

```json
[
  {
    "verse_id": "fallback_morning",
    "text_ko": "두려워하지 말라 내가 너와 함께 함이라",
    "text_full_ko": "두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라",
    "reference": "이사야 41:10",
    "mode": ["morning"],
    "theme": ["hope", "courage"],
    "status": "active",
    "curated": true
  }
]
```

---

## 알람 Free 자동 테마 배분 로직

```swift
func autoSelectTheme(for alarm: Alarm, existingAlarms: [Alarm]) -> String {
    let mode = AppMode.fromHour(Calendar.current.component(.hour, from: alarm.time))
    let allThemes = mode.themes
    // 최근 7일 내 표시된 테마 (해당 알람의 히스토리에서)
    // 실제 구현 시 AlarmThemeHistory Core Data 엔티티 활용
    let recentThemes = getRecentThemes(for: alarm.id, withinDays: 7)
    let available = allThemes.filter { !recentThemes.contains($0) }
    return available.randomElement() ?? allThemes.randomElement() ?? "hope"
}
```
