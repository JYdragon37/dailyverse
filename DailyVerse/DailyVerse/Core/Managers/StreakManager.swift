import Foundation

// MARK: - StreakManager
// 스트릭 인정 기준: 기도 제목 1개 이상 저장 = 1일
// 저장소: UserDefaults (경량, v1 범위)

@MainActor
final class StreakManager: ObservableObject {

    static let shared = StreakManager()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var totalDays: Int = 0
    @Published private(set) var didMeditateToday: Bool = false
    @Published private(set) var meditatedDatesThisMonth: Set<String> = []

    private let kCurrent  = "streak_current_v1"
    private let kLongest  = "streak_longest_v1"
    private let kLastDate = "streak_last_date_v1"
    private let kTotal    = "streak_total_days_v1"

    private init() {
        load()
        checkAndResetIfBroken()
    }

    // MARK: - Public

    /// 묵상 저장 완료 시 호출 (MeditationViewModel에서 호출)
    func recordMeditation() {
        let today = MeditationEntry.todayKey()
        let lastDate = UserDefaults.standard.string(forKey: kLastDate) ?? ""

        guard lastDate != today else {
            didMeditateToday = true
            return
        }

        let yesterday = dayBefore(today)
        currentStreak = (lastDate == yesterday) ? currentStreak + 1 : 1
        longestStreak = max(currentStreak, longestStreak)
        totalDays += 1
        didMeditateToday = true

        let d = UserDefaults.standard
        d.set(currentStreak, forKey: kCurrent)
        d.set(longestStreak,  forKey: kLongest)
        d.set(today,          forKey: kLastDate)
        d.set(totalDays,      forKey: kTotal)
    }

    /// 앱 시작 시 호출: 스트릭 유효성 확인
    func checkAndResetIfBroken() {
        let today     = MeditationEntry.todayKey()
        let yesterday = dayBefore(today)
        let lastDate  = UserDefaults.standard.string(forKey: kLastDate) ?? ""

        didMeditateToday = (lastDate == today)

        if !lastDate.isEmpty && lastDate != today && lastDate != yesterday {
            currentStreak = 0
            UserDefaults.standard.set(0, forKey: kCurrent)
        }
    }

    /// 이번 달 묵상 날짜 업데이트 — Firestore 실제 기록으로 스트릭 재계산
    func updateMeditatedDates(_ dateKeys: Set<String>) {
        meditatedDatesThisMonth = dateKeys
        recalculateStreak(from: dateKeys)
    }

    /// dateKeys 기반으로 연속 스트릭을 정확히 재계산 (UserDefaults 보정)
    private func recalculateStreak(from dateKeys: Set<String>) {
        let today = MeditationEntry.todayKey()
        didMeditateToday = dateKeys.contains(today)

        guard !dateKeys.isEmpty else {
            currentStreak = 0
            UserDefaults.standard.set(0, forKey: kCurrent)
            return
        }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"

        // 날짜 내림차순 정렬 후 오늘부터 연속 체크
        let sorted = dateKeys.sorted().reversed()
        var streak = 0
        var checkDate = today

        for dateKey in sorted {
            if dateKey == checkDate {
                streak += 1
                guard let d = f.date(from: checkDate) else { break }
                let prev = Calendar.current.date(byAdding: .day, value: -1, to: d)!
                checkDate = f.string(from: prev)
            } else if dateKey < checkDate {
                // 연속 끊김
                break
            }
            // dateKey > checkDate (미래) 는 무시
        }

        currentStreak = streak
        longestStreak = max(streak, longestStreak)
        let d = UserDefaults.standard
        d.set(streak,        forKey: kCurrent)
        d.set(longestStreak, forKey: kLongest)
        if didMeditateToday { d.set(today, forKey: kLastDate) }
    }

    // MARK: - Private

    private func load() {
        let d = UserDefaults.standard
        currentStreak = d.integer(forKey: kCurrent)
        longestStreak = d.integer(forKey: kLongest)
        totalDays     = d.integer(forKey: kTotal)
    }

    private func dayBefore(_ dateKey: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateKey) else { return "" }
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        return f.string(from: prev)
    }
}
