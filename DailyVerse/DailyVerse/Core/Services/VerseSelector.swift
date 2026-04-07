import Foundation

class VerseSelector {

    // MARK: - 구 4-zone → 새 8-zone 하위 호환 매핑
    // DB에 "morning", "afternoon", "evening", "dawn"으로 저장된 구 데이터 지원
    private let legacyModeAliases: [String: [String]] = [
        "morning":   ["rise_ignite", "peak_mode"],
        "afternoon": ["recharge", "second_wind"],
        "evening":   ["golden_hour", "wind_down"],
        "dawn":      ["deep_dark", "first_light"]
    ]

    /// 말씀의 mode 배열이 현재 Zone과 매칭되는지 확인 (8-zone + 구 4-zone 하위 호환)
    private func modeMatches(_ verseModes: [String], mode: AppMode) -> Bool {
        // 1. 직접 매칭 (새 8-zone rawValue 또는 "all")
        if verseModes.contains(mode.rawValue) || verseModes.contains("all") { return true }
        // 2. 구 4-zone 이름으로 저장된 경우 → 새 zone 매핑 확인
        for legacyMode in verseModes {
            if let newZones = legacyModeAliases[legacyMode], newZones.contains(mode.rawValue) {
                return true
            }
        }
        return false
    }

    /// 현재 모드 + 날씨 기반으로 최적 말씀 선택
    /// v6.0: 8-zone + 구 4-zone 하위 호환, theme/mood "all" 지원
    func select(from verses: [Verse], mode: AppMode, weather: WeatherData?) -> Verse? {
        let filtered = verses.filter {
            $0.status == "active" &&
            $0.curated == true &&
            modeMatches($0.mode, mode: mode) &&
            $0.isEligible
        }

        // cooldown 통과 구절이 없으면 제한 없이 전체에서 선택
        let pool = filtered.isEmpty ? verses.filter {
            $0.status == "active" &&
            $0.curated == true &&
            modeMatches($0.mode, mode: mode)
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
        let currentMoods = mode.moods
        let currentSeason = currentSeasonTag()
        let currentWeather = weather?.condition ?? "any"

        let scored: [(Verse, Int)] = verses.map { verse in
            var score = 0
            // theme: "all" → 모든 Zone에서 +3 (1개 매칭과 동일)
            if verse.theme.contains("all") {
                score += 3
            } else {
                score += verse.theme.filter { currentThemes.contains($0) }.count * 3
            }
            // mood: "all" → 모든 분위기에서 +2
            if verse.mood.contains("all") {
                score += 2
            } else {
                score += verse.mood.filter { currentMoods.contains($0) }.count * 2
            }
            if verse.weather.contains(currentWeather) || verse.weather.contains("any") { score += 2 }
            if verse.season.contains(currentSeason) || verse.season.contains("all") { score += 1 }
            return (verse, score)
        }

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
