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
            return (verse, score)
        }

        let maxScore  = scored.map { $0.1 }.max() ?? 0
        let topVerses = scored.filter { $0.1 == maxScore }.map { $0.0 }
        return topVerses.randomElement()
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
