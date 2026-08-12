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
    // schema_v1.3: contemplationKo, contemplationReference 제거 (수식 복사본)
    // schema_v1.4: contemplationInterpretation, contemplationAppliance 제거
    //              → 모든 화면이 interpretation / application 하나로 통일
    let question: String?                     // 묵상 질문

    // English fields (KJV + generated)
    let verseShortEn: String?
    let verseFullEn: String?
    let interpretationEn: String?
    let applicationEn: String?
    let questionEn: String? = nil
    let alarmTopEn: String? = nil

    // v5.1 — cooldown 로직용
    let lastShown: String?      // "YYYY-MM-DD"
    let showCount: Int?
    let cooldownDays: Int?      // 기본값 7

    enum CodingKeys: String, CodingKey {
        case id = "verse_id"
        case verseShortKo = "verse_short_ko"
        case verseFullKo = "verse_full_ko"
        case reference, book, chapter, verse
        case mode, theme, mood, season, weather
        case interpretation, application, curated, status, notes
        case alarmTopKo = "alarm_top_ko"
        case question
        case usageCount = "usage_count"
        case lastShown = "last_shown"
        case showCount = "show_count"
        case cooldownDays = "cooldown_days"
        case verseShortEn = "verse_short_en"
        case verseFullEn = "verse_full_en"
        case interpretationEn = "interpretation_en"
        case applicationEn = "application_en"
        case questionEn = "question_en"
        case alarmTopEn = "alarm_top_en"
    }

    // MARK: - Cooldown 헬퍼

    /// 이 구절이 오늘 표시 가능한지 (cooldown_days 경과 여부)
    /// last_shown 포맷:
    ///   - iOS markVerseAsShown → "yyyy-MM-dd"           예: "2026-04-29"
    ///   - Cloud Function       → ISO 8601 with time    예: "2026-04-29T19:00:03.301Z"
    /// 두 포맷 모두 처리해야 쿨다운이 정상 동작함
    var isEligible: Bool {
        guard let lastShown, let cooldownDays else { return true }
        let lastDate: Date?
        if lastShown.count == 10 {
            // "yyyy-MM-dd" 포맷 (iOS markVerseAsShown)
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            lastDate = f.date(from: lastShown)
        } else {
            // ISO 8601 포맷 (Cloud Function) — "2026-04-29T19:00:03.301Z"
            lastDate = ISO8601DateFormatter().date(from: lastShown)
        }
        guard let lastDate else { return true }
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
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "If I take the wings of the morning, and dwell in the uttermost parts of the sea",
        verseFullEn: "If I take the wings of the morning, and dwell in the uttermost parts of the sea; even there shall thy hand lead me, and thy right hand shall hold me.",
        interpretationEn: "Wherever you are, whatever the hour, God's hand is already there with you.",
        applicationEn: "In this quiet, wakeful hour, remember that His hand is holding you.",
        lastShown: nil, showCount: 0, cooldownDays: 7
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
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "My voice shalt thou hear in the morning, O LORD",
        verseFullEn: "My voice shalt thou hear in the morning, O LORD; in the morning will I direct my prayer unto thee, and will look up.",
        interpretationEn: "David's confidence that God hears the prayers we raise in the early morning.",
        applicationEn: "Before the world wakes up, seek God first in this hour.",
        lastShown: nil, showCount: 0, cooldownDays: 7
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
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "Fear thou not; for I am with thee",
        verseFullEn: "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.",
        interpretationEn: "God's own promise to be with you, personally and directly.",
        applicationEn: "Start today remembering that you are not alone.",
        lastShown: nil, showCount: 0, cooldownDays: 7
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
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "I can do all things through Christ which strengtheneth me",
        verseFullEn: "I know both how to be abased, and I know how to abound: every where and in all things I am instructed both to be full and to be hungry, both to abound and to suffer need. I can do all things through Christ which strengtheneth me.",
        interpretationEn: "A declaration of living not by your own strength, but by the strength Christ supplies.",
        applicationEn: "In this focused hour, connect with the One who gives you strength.",
        lastShown: nil, showCount: 0, cooldownDays: 7
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
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "Wisdom calls to you: walk in my ways",
        verseFullEn: "Wisdom calls to you: walk in my ways, and your steps will multiply, and your path will be made level.",
        interpretationEn: "When you walk in the path of wisdom, the way ahead opens up.",
        applicationEn: "It's okay to rest a moment — this pause is held in God too.",
        lastShown: nil, showCount: 0, cooldownDays: 7
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
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "Be of good cheer; I have overcome the world",
        verseFullEn: "These things I have spoken unto you, that in me ye might have peace. In the world ye shall have tribulation: but be of good cheer; I have overcome the world.",
        interpretationEn: "Because Jesus has already overcome the world, we too can be of good cheer.",
        applicationEn: "Even if you feel the afternoon fatigue, remember you're standing in a battle already won.",
        lastShown: nil, showCount: 0, cooldownDays: 7
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
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "The LORD is my shepherd; I shall not want",
        verseFullEn: "The LORD is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters.",
        interpretationEn: "A confession of trust that God cares for us the way a shepherd cares for his sheep.",
        applicationEn: "You worked hard today. Look back on all He provided.",
        lastShown: nil, showCount: 0, cooldownDays: 7
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
        interpretation: "베드로는 네로 황제의 박해가 시작되던 시절, 고향을 잃고 흩어진 사람들에게 편지를 쓰고 있었어. 그 상황에서 그가 전한 말이 바로 이거야—짐을 혼자 다 안고 있지 말고, 그냥 던져버리라고. 하나님이 이미 너를 신경 쓰고 있으니까.",
        application: "집에 돌아온 지금, 오늘 가장 무거웠던 걱정 하나를 떠올리고 '이건 내려놓을게'라고 조용히 말해봐.",
        curated: true, status: "active", usageCount: 0,
        notes: nil, alarmTopKo: nil,
        question: nil,
        verseShortEn: "Casting all your care upon him; for he careth for you",
        verseFullEn: "Casting all your care upon him; for he careth for you.",
        interpretationEn: "Peter wrote this to people scattered from their homes as Nero's persecution began. His message: don't carry the whole weight alone — just cast it off. God is already caring for you.",
        applicationEn: "Now that you're home, think of the heaviest worry from today and quietly say, 'I'm letting this go.'",
        lastShown: nil, showCount: 0, cooldownDays: 7
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

extension Verse {
    func verseShort(lang: String) -> String {
        lang == "en" ? (verseShortEn ?? verseShortKo) : verseShortKo
    }
    func verseFull(lang: String) -> String {
        lang == "en" ? (verseFullEn ?? verseFullKo) : verseFullKo
    }
    func interpretationText(lang: String) -> String {
        lang == "en" ? (interpretationEn ?? interpretation) : interpretation
    }
    func applicationText(lang: String) -> String {
        lang == "en" ? (applicationEn ?? application) : application
    }
    func questionText(lang: String) -> String? {
        lang == "en" ? (questionEn ?? question) : question
    }
    func alarmTopText(lang: String) -> String? {
        lang == "en" ? (alarmTopEn ?? alarmTopKo) : alarmTopKo
    }

    /// reference(예: "갈라디아서 5:22-23")의 영어 버전이 별도 필드로 없어서,
    /// 책 이름 접두어만 클라이언트에서 매핑해 생성한다 (장:절 부분은 공통 표기라 그대로 사용).
    private static let bookNameEn: [(ko: String, en: String)] = [
        ("창세기", "Genesis"), ("출애굽기", "Exodus"), ("레위기", "Leviticus"), ("신명기", "Deuteronomy"),
        ("여호수아", "Joshua"), ("사사기", "Judges"), ("룻기", "Ruth"),
        ("사무엘상", "1 Samuel"), ("사무엘하", "2 Samuel"),
        ("열왕기상", "1 Kings"), ("열왕기하", "2 Kings"),
        ("역대상", "1 Chronicles"), ("역대하", "2 Chronicles"),
        ("에스라", "Ezra"), ("느헤미야", "Nehemiah"), ("에스더", "Esther"),
        ("욥기", "Job"), ("시편", "Psalm"), ("잠언", "Proverbs"), ("전도서", "Ecclesiastes"),
        ("아가", "Song of Solomon"), ("이사야", "Isaiah"), ("예레미야애가", "Lamentations"), ("예레미야", "Jeremiah"),
        ("에스겔", "Ezekiel"), ("다니엘", "Daniel"),
        ("호세아", "Hosea"), ("요엘", "Joel"), ("아모스", "Amos"), ("오바댜", "Obadiah"),
        ("요나", "Jonah"), ("미가", "Micah"), ("나훔", "Nahum"), ("하박국", "Habakkuk"),
        ("스바냐", "Zephaniah"), ("학개", "Haggai"), ("스가랴", "Zechariah"), ("말라기", "Malachi"),
        ("마태복음", "Matthew"), ("마가복음", "Mark"), ("누가복음", "Luke"), ("요한복음", "John"),
        ("사도행전", "Acts"), ("로마서", "Romans"),
        ("고린도전서", "1 Corinthians"), ("고린도후서", "2 Corinthians"),
        ("갈라디아서", "Galatians"), ("에베소서", "Ephesians"), ("빌립보서", "Philippians"),
        ("골로새서", "Colossians"),
        ("데살로니가전서", "1 Thessalonians"), ("데살로니가후서", "2 Thessalonians"),
        ("디모데전서", "1 Timothy"), ("디모데후서", "2 Timothy"),
        ("디도서", "Titus"), ("빌레몬서", "Philemon"), ("히브리서", "Hebrews"),
        ("야고보서", "James"), ("베드로전서", "1 Peter"), ("베드로후서", "2 Peter"),
        ("요한일서", "1 John"), ("요한이서", "2 John"), ("요한삼서", "3 John"),
        ("유다서", "Jude"), ("요한계시록", "Revelation"),
    ]

    /// 어떤 "책이름 장:절" 형식 한국어 문자열에도 적용 가능한 정적 변환 함수
    /// (MeditationEntry처럼 과거 시점에 저장된 참조 문자열에도 사용)
    static func translateReferenceToEnglish(_ koReference: String) -> String {
        for (ko, en) in bookNameEn where koReference.hasPrefix(ko) {
            return en + koReference.dropFirst(ko.count)
        }
        return koReference
    }

    var referenceEn: String { Verse.translateReferenceToEnglish(reference) }

    /// 현재 appLanguage에 맞는 참조 표기 (홈/알람/저장/묵상 등 전체 화면 공통 사용)
    var referenceDisplay: String {
        UserDefaults.standard.string(forKey: "appLanguage") == "en" ? referenceEn : reference
    }
}
