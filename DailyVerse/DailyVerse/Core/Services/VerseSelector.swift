import Foundation

class VerseSelector {

    /// 현재 Zone + 날씨 기반으로 최적 말씀 선택
    /// v6.0: 8-zone 기준, theme/mood "all" 지원
    /// 스코어링: 테마 겹침 +3, 분위기 겹침 +2, 날씨 일치 +2, 계절 일치 +1
    func select(from verses: [Verse], mode: AppMode, weather: WeatherData?) -> Verse? {
        let filtered = verses.filter {
            $0.status == "active" &&
            $0.curated == true &&
            ($0.mode.contains(mode.rawValue) || $0.mode.contains("all")) &&
            $0.isEligible
        }

        // cooldown 통과 구절이 없으면 제한 없이 전체에서 선택
        let pool = filtered.isEmpty ? verses.filter {
            $0.status == "active" &&
            $0.curated == true &&
            ($0.mode.contains(mode.rawValue) || $0.mode.contains("all"))
        } : filtered

        guard !pool.isEmpty else { return nil }
        return score(pool, mode: mode, weather: weather)
    }

    /// [다음 말씀]: 현재 표시 중인 말씀 제외 후 선택
    func selectNext(from verses: [Verse], excluding currentId: String, mode: AppMode, weather: WeatherData?) -> Verse? {
        let remaining = verses.filter { $0.id != currentId }
        return select(from: remaining, mode: mode, weather: weather)
    }

    /// 알람 테마에 맞는 말씀 선택
    func selectForAlarm(from verses: [Verse], theme: String, mode: AppMode, weather: WeatherData?) -> Verse? {
        let themeFiltered = verses.filter { $0.theme.contains(theme) }
        return select(from: themeFiltered.isEmpty ? verses : themeFiltered, mode: mode, weather: weather)
    }

    // MARK: - Private

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
        let calendar = Calendar.current
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
