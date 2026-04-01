import Foundation

class VerseSelector {

    /// 현재 모드 + 날씨 기반으로 최적 말씀 선택
    /// 스코어링: 테마 겹침 +3, 분위기 겹침 +2, 날씨 일치 +2, 계절 일치 +1
    func select(from verses: [Verse], mode: AppMode, weather: WeatherData?) -> Verse? {
        let filtered = verses.filter {
            $0.status == "active" &&
            $0.curated == true &&
            ($0.mode.contains(mode.rawValue) || $0.mode.contains("all"))
        }
        guard !filtered.isEmpty else { return nil }

        let currentThemes = mode.themes
        let currentMoods = mode.moods
        let currentSeason = currentSeasonTag()
        let currentWeather = weather?.condition ?? "any"

        let scored: [(Verse, Int)] = filtered.map { verse in
            var score = 0
            score += verse.theme.filter { currentThemes.contains($0) }.count * 3
            score += verse.mood.filter { currentMoods.contains($0) }.count * 2
            if verse.weather.contains(currentWeather) || verse.weather.contains("any") { score += 2 }
            if verse.season.contains(currentSeason) || verse.season.contains("all") { score += 1 }
            return (verse, score)
        }

        let maxScore = scored.map { $0.1 }.max() ?? 0
        let topVerses = scored.filter { $0.1 == maxScore }.map { $0.0 }
        return topVerses.randomElement()
    }

    /// Premium [다음 말씀]: 현재 표시 중인 말씀 제외 후 선택
    func selectNext(from verses: [Verse], excluding currentId: String, mode: AppMode, weather: WeatherData?) -> Verse? {
        let remaining = verses.filter { $0.id != currentId }
        return select(from: remaining, mode: mode, weather: weather)
    }

    /// 알람 테마에 맞는 말씀 선택
    func selectForAlarm(from verses: [Verse], theme: String, mode: AppMode, weather: WeatherData?) -> Verse? {
        let themeFiltered = verses.filter { $0.theme.contains(theme) }
        return select(from: themeFiltered.isEmpty ? verses : themeFiltered, mode: mode, weather: weather)
    }

    // MARK: - Helpers

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
