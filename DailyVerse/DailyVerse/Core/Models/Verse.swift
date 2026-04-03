import Foundation

struct Verse: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let textKo: String
    let textFullKo: String
    let reference: String
    let book: String
    let chapter: Int
    let verse: Int
    let mode: [String]
    let theme: [String]
    let mood: [String]
    let season: [String]
    let weather: [String]
    let interpretation: String
    let application: String
    let curated: Bool
    let status: String
    let usageCount: Int
    let notes: String?

    // v5.1 — cooldown 로직용
    let lastShown: String?      // "YYYY-MM-DD"
    let showCount: Int?
    let cooldownDays: Int?      // 기본값 7

    // v5.1 — 번역본 (MVP: ko_nkrv만 사용)
    let translations: VerseTranslations?

    struct VerseTranslations: Codable, Equatable, Hashable {
        let koNkrv: String?
        let koEasy: String?

        enum CodingKeys: String, CodingKey {
            case koNkrv = "ko_nkrv"
            case koEasy = "ko_easy"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "verse_id"
        case textKo = "text_ko"
        case textFullKo = "text_full_ko"
        case reference, book, chapter, verse
        case mode, theme, mood, season, weather
        case interpretation, application, curated, status, notes
        case usageCount = "usage_count"
        case lastShown = "last_shown"
        case showCount = "show_count"
        case cooldownDays = "cooldown_days"
        case translations
    }

    // MARK: - Cooldown 헬퍼

    /// 이 구절이 오늘 표시 가능한지 (cooldown_days 경과 여부)
    var isEligible: Bool {
        guard let lastShown, let cooldownDays else { return true }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let lastDate = formatter.date(from: lastShown) else { return true }
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince >= cooldownDays
    }

    // MARK: - 번들 폴백용 샘플 말씀

    static let fallbackMorning = Verse(
        id: "fallback_morning",
        textKo: "두려워하지 말라 내가 너와 함께 함이라",
        textFullKo: "두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라 내가 너를 굳세게 하리라 참으로 너를 도와주리라",
        reference: "이사야 41:10",
        book: "이사야", chapter: 41, verse: 10,
        mode: ["morning"], theme: ["hope", "courage"], mood: ["bright", "dramatic"],
        season: ["all"], weather: ["any"],
        interpretation: "하나님이 직접 함께하겠다는 약속",
        application: "오늘 두렵다면 혼자가 아님을 기억해",
        curated: true, status: "active", usageCount: 0,
        notes: nil, lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    static let fallbackAfternoon = Verse(
        id: "fallback_afternoon",
        textKo: "지혜가 네게 이르기를 내 길로 행하라",
        textFullKo: "지혜가 네게 이르기를 내 길로 행하라 그리하면 네 걸음이 많아지고 네 앞길이 평탄하게 되리라",
        reference: "잠언 9:6",
        book: "잠언", chapter: 9, verse: 6,
        mode: ["afternoon"], theme: ["wisdom", "focus"], mood: ["calm", "warm"],
        season: ["all"], weather: ["any"],
        interpretation: "지혜의 길로 나아갈 때 앞길이 열린다",
        application: "오늘 결정해야 할 일이 있다면 지혜를 구해보자",
        curated: true, status: "active", usageCount: 0,
        notes: nil, lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    static let fallbackEvening = Verse(
        id: "fallback_evening",
        textKo: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
        textFullKo: "여호와는 나의 목자시니 내게 부족함이 없으리로다 그가 나를 푸른 풀밭에 누이시며 쉴 만한 물가로 인도하시는도다",
        reference: "시편 23:1",
        book: "시편", chapter: 23, verse: 1,
        mode: ["evening"], theme: ["peace", "comfort"], mood: ["serene", "cozy"],
        season: ["all"], weather: ["any"],
        interpretation: "하나님이 목자처럼 돌봐주신다는 안식의 약속",
        application: "오늘 하루를 마무리하며 부족함 없이 채워주심을 감사해",
        curated: true, status: "active", usageCount: 0,
        notes: nil, lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    static let fallbackDawn = Verse(
        id: "fallback_dawn",
        textKo: "내가 새벽 날개를 치며 바다 끝에 거할지라도",
        textFullKo: "내가 새벽 날개를 치며 바다 끝에 거할지라도 거기서도 주의 손이 나를 인도하시며 주의 오른손이 나를 붙드시리이다",
        reference: "시편 139:9-10",
        book: "시편", chapter: 139, verse: 9,
        mode: ["dawn"], theme: ["stillness", "faith"], mood: ["serene", "calm"],
        season: ["all"], weather: ["any"],
        interpretation: "어디에 있든 하나님의 손이 함께한다",
        application: "잠 못 드는 이 시간에도 하나님이 붙드심을 기억해",
        curated: true, status: "active", usageCount: 0,
        notes: nil, lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    static let fallbackVerses: [Verse] = [.fallbackMorning, .fallbackAfternoon, .fallbackEvening, .fallbackDawn]
}
