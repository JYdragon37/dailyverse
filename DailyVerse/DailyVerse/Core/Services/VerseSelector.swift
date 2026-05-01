import Foundation

class VerseSelector {

    /// 오늘의 말씀 선택 — 서버(Cloud Function) 미응답 시 폴백용
    /// 날씨/테마/무드 스코어링 없음 → 모든 조건 동일 → 날짜 시드만으로 결정
    /// 같은 날 같은 기기에서 항상 동일한 구절 반환 (서버 응답 없을 때만 사용)
    func selectDailyVerse(from verses: [Verse], weather: WeatherData?,
                          excludingUserHistory recentIds: Set<String> = []) -> Verse? {
        let base = verses.filter { $0.status == "active" && $0.curated == true }

        var pool = base.filter { !recentIds.contains($0.id) && $0.isEligible }
        if pool.isEmpty { pool = base.filter { !recentIds.contains($0.id) } }
        if pool.isEmpty { pool = base }

        guard !pool.isEmpty else { return nil }

        // 스코어링 없음 — ID 정렬 후 날짜 시드로 결정론적 선택
        let sorted = pool.sorted { $0.id < $1.id }
        return sorted[Self.dailySeedIndex(count: sorted.count)]
    }

    /// 현재 Zone + 날씨 기반으로 최적 말씀 선택 (알람 전용)
    /// v6.0: 8-zone 기준, theme/mood "all" 지원
    /// v6.1: 유저별 최근 이력(recentIds) 기반 중복 노출 최소화
    /// 스코어링: 테마 +3, 분위기 +2, 날씨 +2, 계절 +1, 선호 테마 +5, 전역 인기 -1/10회
    func select(from verses: [Verse], mode: AppMode, weather: WeatherData?,
                excludingUserHistory recentIds: Set<String> = []) -> Verse? {
        let base = verses.filter {
            $0.status == "active" && $0.curated == true &&
            ($0.mode.contains(mode.rawValue) || $0.mode.contains("all"))
        }

        // 1차: 유저 이력 제외 + cooldown 통과
        var pool = base.filter { !recentIds.contains($0.id) && $0.isEligible }
        // 2차: 유저 이력 제외만 (cooldown 완화)
        if pool.isEmpty { pool = base.filter { !recentIds.contains($0.id) } }
        // 3차: 전체 풀 (모든 구절을 이미 봤을 때 — 386개 이상 사용 시 사실상 미도달)
        if pool.isEmpty { pool = base }

        guard !pool.isEmpty else { return nil }
        return score(pool, mode: mode, weather: weather)
    }

    /// selectNext: 알람·테스트 전용 — 현재 말씀 제외 후 선택 (홈/묵상에서는 미사용)
    func selectNext(from verses: [Verse], excluding currentId: String, mode: AppMode, weather: WeatherData?,
                    excludingUserHistory recentIds: Set<String> = []) -> Verse? {
        let remaining = verses.filter { $0.id != currentId }
        return select(from: remaining, mode: mode, weather: weather, excludingUserHistory: recentIds)
    }

    /// 알람 테마에 맞는 말씀 선택
    func selectForAlarm(from verses: [Verse], theme: String, mode: AppMode, weather: WeatherData?) -> Verse? {
        let themeFiltered = verses.filter { $0.theme.contains(theme) }
        return select(from: themeFiltered.isEmpty ? verses : themeFiltered, mode: mode, weather: weather)
    }

    // MARK: - Private

    /// Daily verse 전용 스코어링 — Zone 무관, weather/season + 선호 테마만 반영
    private func scoreDailyVerse(_ verses: [Verse], weather: WeatherData?) -> Verse? {
        let currentSeason   = currentSeasonTag()
        let currentWeather  = weather?.condition ?? "any"
        let preferredThemes: [String] = {
            guard let data = UserDefaults.standard.data(forKey: "preferredThemes"),
                  let themes = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return themes
        }()

        let scored: [(Verse, Int)] = verses.map { verse in
            var score = 0
            if verse.weather.contains(currentWeather) || verse.weather.contains("any") { score += 2 }
            if verse.season.contains(currentSeason)   || verse.season.contains("all")  { score += 1 }
            if !preferredThemes.isEmpty && !Set(verse.theme).isDisjoint(with: Set(preferredThemes)) {
                score += 5
            }
            return (verse, score)
        }

        let maxScore  = scored.map { $0.1 }.max() ?? 0
        let topVerses = scored.filter { $0.1 == maxScore }.map { $0.0 }.sorted { $0.id < $1.id }
        guard !topVerses.isEmpty else { return nil }
        return topVerses[Self.dailySeedIndex(count: topVerses.count)]
    }

    private func score(_ verses: [Verse], mode: AppMode, weather: WeatherData?) -> Verse? {
        let currentThemes = mode.themes
        let currentMoods  = mode.moods
        let currentSeason = currentSeasonTag()
        let currentWeather = weather?.condition ?? "any"

        // Design Ref: §7 — 온보딩 선호 테마 +5점 보너스
        let preferredThemes: [String] = {
            guard let data = UserDefaults.standard.data(forKey: "preferredThemes"),
                  let themes = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return themes
        }()

        let scored: [(Verse, Int)] = verses.map { verse in
            var score = 0
            // theme: "all" → +3, 특정 테마 매칭 → 매칭 수 × 3
            score += verse.theme.contains("all")
                ? 3
                : verse.theme.filter { currentThemes.contains($0) }.count * 3
            // mood: "all" → +2, 특정 분위기 매칭 → 매칭 수 × 2
            score += verse.mood.contains("all")
                ? 2
                : verse.mood.filter { currentMoods.contains($0) }.count * 2
            if verse.weather.contains(currentWeather) || verse.weather.contains("any") { score += 2 }
            if verse.season.contains(currentSeason)  || verse.season.contains("all")  { score += 1 }
            // 온보딩 선호 테마 보너스 (겹치는 테마 하나라도 있으면 +5)
            if !preferredThemes.isEmpty && !Set(verse.theme).isDisjoint(with: Set(preferredThemes)) {
                score += 5
            }
            return (verse, score)
        }

        let maxScore  = scored.map { $0.1 }.max() ?? 0
        // id 기준 정렬로 순서를 결정론적으로 고정한 뒤 날짜 시드로 선택
        // → 동일 날짜에 캐시 미스가 발생해도 항상 같은 구절이 선택됨
        let topVerses = scored.filter { $0.1 == maxScore }.map { $0.0 }
            .sorted { $0.id < $1.id }
        guard !topVerses.isEmpty else { return nil }
        let index = Self.dailySeedIndex(count: topVerses.count)
        return topVerses[index]
    }

    /// 오늘 날짜(04:00 기준)를 시드로 사용한 결정론적 인덱스 반환
    /// - 같은 날이면 count가 같을 때 항상 동일한 인덱스를 반환
    /// - 새벽 00–03은 전날로 취급 (DailyVerseCache.isValid와 동일 기준)
    private static func dailySeedIndex(count: Int) -> Int {
        guard count > 1 else { return 0 }
        // KST 명시 — Cloud Function의 04:00 KST 기준과 dayInt 통일
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let referenceDate: Date
        if hour < 4 {
            referenceDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            referenceDate = now
        }
        // "yyyyMMdd" 형식 숫자를 시드로 사용
        let dayInt = calendar.component(.year, from: referenceDate) * 10000
            + calendar.component(.month, from: referenceDate) * 100
            + calendar.component(.day, from: referenceDate)
        return dayInt % count
    }

    private func currentSeasonTag() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return "spring"
        case 6...8:  return "summer"
        case 9...11: return "autumn"
        default:     return "winter"
        }
    }
}
