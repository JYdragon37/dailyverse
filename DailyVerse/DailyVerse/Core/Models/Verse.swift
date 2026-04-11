import Foundation

struct Verse: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let verseShortKo: String       // 짧은 요약 글귀 (카드, 알람 Stage 1, 묵상 탭)
    let verseFullKo: String        // 전체 구절 (홈 메인, 알람 Stage 2, 저장 상세)
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
    let alarmTopKo: String?              // 알람 목록 상단 전용 (없으면 verseShortKo 폴백)
    let contemplationKo: String?         // 묵상 읽기 구절 — Screen 2 읽기 섹션 표시용 (50-200자)
    let contemplationReference: String?  // 묵상 구절 출처 (예: "시편 62:5")
    let contemplationInterpretation: String?  // 묵상 전용 해석 — Screen 2 해석 섹션
    let contemplationAppliance: String?       // 묵상 일상 적용 — Screen 3 섹션 1
    let question: String?                     // 묵상 질문 — Screen 3 섹션 2

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
        case verseShortKo = "verse_short_ko"
        case verseFullKo = "verse_full_ko"
        case reference, book, chapter, verse
        case mode, theme, mood, season, weather
        case interpretation, application, curated, status, notes
        case alarmTopKo = "alarm_top_ko"
        case contemplationKo = "contemplation_ko"
        case contemplationReference = "contemplation_reference"
        case contemplationInterpretation = "contemplation_interpretation"
        case contemplationAppliance = "contemplation_appliance"
        case question
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

    // MARK: - v6.0 8 Zone 폴백 말씀

    // Zone 1 — Deep Dark (00–03) 극야 / 고요
    static let fallbackDeepDark = Verse(
        id: "fallback_deep_dark",
        verseShortKo: "내가 새벽 날개를 치며 바다 끝에 거할지라도",
        verseFullKo: "내가 새벽 날개를 치며 바다 끝에 거할지라도 거기서도 주의 손이 나를 인도하시며 주의 오른손이 나를 붙드시리이다",
        reference: "시편 139:9-10",
        book: "시편", chapter: 139, verse: 9,
        mode: ["deep_dark"], theme: ["stillness", "surrender", "grace", "faith"], mood: ["serene", "calm"],
        season: ["all"], weather: ["any"],
        interpretation: "어디에 있든, 어떤 시간이든 하나님의 손이 함께한다",
        application: "아직 깨어있는 이 시간, 하나님이 붙드심을 기억해",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // Zone 2 — First Light (03–06) 여명 / 준비
    static let fallbackFirstLight = Verse(
        id: "fallback_first_light",
        verseShortKo: "여호와여 아침에 주께서 나의 소리를 들으시리니",
        verseFullKo: "여호와여 아침에 주께서 나의 소리를 들으시리니 아침에 내가 주께 기도하고 바라리이다",
        reference: "시편 5:3",
        book: "시편", chapter: 5, verse: 3,
        mode: ["first_light"], theme: ["faith", "renewal", "stillness", "hope"], mood: ["serene", "calm"],
        season: ["all"], weather: ["any"],
        interpretation: "새벽/아침에 올리는 기도를 하나님이 들으신다는 다윗의 확신",
        application: "세상이 깨기 전 이 시간, 가장 먼저 하나님을 찾아봐",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // Zone 3 — Rise & Ignite (06–09) 아침 / 점화
    static let fallbackRiseIgnite = Verse(
        id: "fallback_rise_ignite",
        verseShortKo: "두려워하지 말라 내가 너와 함께 함이라",
        verseFullKo: "두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라 내가 너를 굳세게 하리라 참으로 너를 도와주리라",
        reference: "이사야 41:10",
        book: "이사야", chapter: 41, verse: 10,
        mode: ["rise_ignite"], theme: ["hope", "courage", "strength", "renewal"], mood: ["bright", "dramatic"],
        season: ["all"], weather: ["any"],
        interpretation: "하나님이 직접 함께하겠다는 약속",
        application: "오늘 하루, 혼자가 아님을 기억하며 시작해",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // Zone 4 — Peak Mode (09–12) 집중 / 성과
    static let fallbackPeakMode = Verse(
        id: "fallback_peak_mode",
        verseShortKo: "내가 능력 주시는 자 안에서 모든 것을 할 수 있느니라",
        verseFullKo: "내가 비천에 처할 줄도 알고 풍부에 처할 줄도 알아 모든 일 곧 배부름과 배고픔과 풍부와 궁핍에도 처할 줄 아는 일체의 비결을 배웠노라 내가 능력 주시는 자 안에서 모든 것을 할 수 있느니라",
        reference: "빌립보서 4:13",
        book: "빌립보서", chapter: 4, verse: 13,
        mode: ["peak_mode"], theme: ["wisdom", "focus", "courage", "strength"], mood: ["bright", "dramatic"],
        season: ["all"], weather: ["any"],
        interpretation: "자기 능력이 아닌 그리스도 안에서 주어지는 힘으로 사는 선언",
        application: "지금 이 집중의 시간, 능력 주시는 분께 연결돼봐",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // Zone 5 — Recharge (12–15) 정오 / 회복
    static let fallbackRecharge = Verse(
        id: "fallback_recharge",
        verseShortKo: "지혜가 네게 이르기를 내 길로 행하라",
        verseFullKo: "지혜가 네게 이르기를 내 길로 행하라 그리하면 네 걸음이 많아지고 네 앞길이 평탄하게 되리라",
        reference: "잠언 9:6",
        book: "잠언", chapter: 9, verse: 6,
        mode: ["recharge"], theme: ["rest", "patience", "gratitude", "comfort"], mood: ["calm", "warm"],
        season: ["all"], weather: ["any"],
        interpretation: "지혜의 길로 나아갈 때 앞길이 열린다",
        application: "잠깐 쉬어가도 괜찮아. 이 숨 고르는 시간도 하나님 안에 있어",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // Zone 6 — Second Wind (15–18) 오후 / 재점화
    static let fallbackSecondWind = Verse(
        id: "fallback_second_wind",
        verseShortKo: "담대하라 내가 세상을 이기었노라",
        verseFullKo: "세상에서는 너희가 환난을 당하나 담대하라 내가 세상을 이기었노라 이것을 너희에게 이르는 것은 너희로 내 안에서 평안을 누리게 하려 함이라",
        reference: "요한복음 16:33",
        book: "요한복음", chapter: 16, verse: 33,
        mode: ["second_wind"], theme: ["strength", "focus", "patience", "wisdom"], mood: ["warm", "calm"],
        season: ["all"], weather: ["any"],
        interpretation: "예수님이 이미 세상을 이기셨기에 우리도 담대할 수 있다는 선언",
        application: "오후의 피로가 느껴져도, 이미 이긴 싸움 안에 서 있음을 기억해",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // Zone 7 — Golden Hour (18–21) 저녁 / 수확
    static let fallbackGoldenHour = Verse(
        id: "fallback_golden_hour",
        verseShortKo: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
        verseFullKo: "여호와는 나의 목자시니 내게 부족함이 없으리로다 그가 나를 푸른 풀밭에 누이시며 쉴 만한 물가로 인도하시는도다",
        reference: "시편 23:1",
        book: "시편", chapter: 23, verse: 1,
        mode: ["golden_hour"], theme: ["gratitude", "reflection", "comfort", "peace"], mood: ["warm", "serene"],
        season: ["all"], weather: ["any"],
        interpretation: "하나님이 목자처럼 돌봐주신다는 신뢰의 고백",
        application: "오늘 하루 수고했어. 채워주신 것들을 되돌아봐",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // Zone 8 — Wind Down (21–24) 밤 / 마무리
    static let fallbackWindDown = Verse(
        id: "fallback_wind_down",
        verseShortKo: "너희 염려를 다 주께 맡기라",
        verseFullKo: "너희 염려를 다 주께 맡기라 이는 그가 너희를 돌보심이라",
        reference: "베드로전서 5:7",
        book: "베드로전서", chapter: 5, verse: 7,
        mode: ["wind_down"], theme: ["peace", "rest", "comfort", "stillness"], mood: ["cozy", "calm"],
        season: ["all"], weather: ["any"],
        interpretation: "염려를 하나님께 내던지고 쉬라는 권면",
        application: "오늘의 무게를 내려놓고 쉬어. 그분이 돌보신다",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil, contemplationKo: nil, contemplationReference: nil,
        contemplationInterpretation: nil, contemplationAppliance: nil, question: nil,
        lastShown: nil, showCount: 0, cooldownDays: 7, translations: nil
    )

    // MARK: - 레거시 호환 (구 4-zone 이름 → 새 zone으로 매핑)
    static var fallbackMorning:   Verse { fallbackRiseIgnite }
    static var fallbackAfternoon: Verse { fallbackRecharge }
    static var fallbackEvening:   Verse { fallbackGoldenHour }
    static var fallbackDawn:      Verse { fallbackFirstLight }

    static let fallbackVerses: [Verse] = [
        .fallbackDeepDark, .fallbackFirstLight, .fallbackRiseIgnite, .fallbackPeakMode,
        .fallbackRecharge, .fallbackSecondWind, .fallbackGoldenHour, .fallbackWindDown
    ]
}
