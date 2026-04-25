import SwiftUI
import FirebaseFirestore

// Design Ref: §3 — GreetingService @EnvironmentObject
// Plan SC: Zone 진입 시 항상 표시, 언어 설정 반영, 폴백 보장

// MARK: - GreetingLanguage

enum GreetingLanguage: String, CaseIterable {
    case ko     = "ko"
    case en     = "en"
    case random = "random"

    var displayName: String {
        switch self {
        case .ko:     return "한국어"
        case .en:     return "English"
        case .random: return "랜덤"
        }
    }

    /// random일 경우 실제 언어 결정
    func resolved() -> String {
        self == .random ? (Bool.random() ? "ko" : "en") : self.rawValue
    }
}

// MARK: - GreetingService
//
// Firestore 컬렉션 구조:
//   greetings       — 홈화면 Zone별 인사말 (load() 사용)
//   alarm_greetings — 알람 Stage2 팝업 전용 인사말 (loadAlarmGreeting() 사용)
//
// 두 컬렉션은 동일한 스키마(gr_id, zone_id, language, text, char_count)를
// 공유하지만 맥락(홈 vs 알람)에 따라 어조와 내용이 다르게 관리됩니다.
//   홈:  "Good morning, beloved. 오늘도..." (일상적, 부드러운 시작)
//   알람: "밤 알람이에요, beloved..." (알람 종료 직후 웰컴 맥락)

@MainActor
class GreetingService: ObservableObject {

    // MARK: - Published

    @Published var currentGreeting: String = ""
    @Published var currentAlarmGreeting: String = ""

    // MARK: - Private

    /// 캐시 key: "{zone_id}_{resolved_lang}" 예: "deep_dark_ko"
    private var cache: [String: String] = [:]
    /// 알람 전용 캐시 (홈 캐시와 독립 관리 — 같은 Zone이어도 다른 문구)
    private var alarmCache: [String: String] = [:]
    private let db = Firestore.firestore()

    // MARK: - Public

    /// Zone 진입 시 호출. 캐시 히트 → 즉시 반환, miss → Firestore fetch.
    /// daily_cards에 절기 greeting이 있으면 우선 사용
    func load(for mode: AppMode, language: GreetingLanguage) async {
        let resolvedLang = language.resolved()
        let cacheKey = "\(mode.rawValue)_\(resolvedLang)"

        // 0. 절기 카드 greeting 우선 확인
        if let eventGreeting = await fetchEventGreeting(language: resolvedLang) {
            currentGreeting = eventGreeting
            return
        }

        // 1. 캐시 히트: 같은 Zone 재진입 시 동일 greeting 유지
        if let cached = cache[cacheKey] {
            currentGreeting = cached
            return
        }

        // 2. Firestore fetch
        do {
            let snapshot = try await db.collection("greetings")
                .whereField("zone_id", isEqualTo: mode.rawValue)
                .whereField("language", isEqualTo: resolvedLang)
                .getDocuments()

            let greetings = snapshot.documents.compactMap { doc -> Greeting? in
                let data = doc.data()
                guard
                    let id        = data["gr_id"]      as? String,
                    let zoneId    = data["zone_id"]    as? String,
                    let lang      = data["language"]   as? String,
                    let text      = data["text"]       as? String,
                    let charCount = data["char_count"] as? Int
                else { return nil }
                return Greeting(id: id, zoneId: zoneId, language: lang,
                                text: text, charCount: charCount)
            }

            if let picked = greetings.randomElement() {
                cache[cacheKey] = picked.text
                currentGreeting = picked.text
            } else {
                useFallback(mode: mode, lang: resolvedLang)
            }
        } catch {
            useFallback(mode: mode, lang: resolvedLang)
        }
    }

    /// 알람 화면 전용 인사말 로드 — alarm_greetings 컬렉션 (폴백: AppMode.alarmGreetingKr/En)
    /// 절기 당일은 daily_cards.greeting_ko/en 우선 사용
    func loadAlarmGreeting(for mode: AppMode, language: GreetingLanguage) async {
        let resolvedLang = language.resolved()
        let cacheKey = "alarm_\(mode.rawValue)_\(resolvedLang)"

        // 절기 카드 greeting 우선 확인
        if let eventGreeting = await fetchEventGreeting(language: resolvedLang) {
            currentAlarmGreeting = eventGreeting
            return
        }

        if let cached = alarmCache[cacheKey] {
            currentAlarmGreeting = cached
            return
        }

        do {
            let snapshot = try await db.collection("alarm_greetings")
                .whereField("zone_id", isEqualTo: mode.rawValue)
                .whereField("language", isEqualTo: resolvedLang)
                .getDocuments()

            let greetings = snapshot.documents.compactMap { doc -> Greeting? in
                let data = doc.data()
                guard
                    let id        = data["gr_id"]      as? String,
                    let zoneId    = data["zone_id"]    as? String,
                    let lang      = data["language"]   as? String,
                    let text      = data["text"]       as? String,
                    let charCount = data["char_count"] as? Int
                else { return nil }
                return Greeting(id: id, zoneId: zoneId, language: lang,
                                text: text, charCount: charCount)
            }

            if let picked = greetings.randomElement() {
                alarmCache[cacheKey] = picked.text
                currentAlarmGreeting = picked.text
            } else {
                useAlarmFallback(mode: mode, lang: resolvedLang)
            }
        } catch {
            useAlarmFallback(mode: mode, lang: resolvedLang)
        }
    }

    /// Zone 전환 시 해당 Zone 캐시 무효화 (다음 진입 시 새 greeting 선택)
    func invalidate(for mode: AppMode) {
        cache.removeValue(forKey: "\(mode.rawValue)_ko")
        cache.removeValue(forKey: "\(mode.rawValue)_en")
    }

    /// 언어 설정 변경 시 전체 캐시 클리어
    func clearCache() {
        cache.removeAll()
        currentGreeting = ""
    }

    // MARK: - Private

    /// 오늘 날짜의 daily_cards 문서에서 절기 greeting 반환 (없으면 nil)
    private func fetchEventGreeting(language: String) async -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        guard let doc = try? await db.collection("daily_cards").document(today).getDocument(),
              doc.exists,
              let data = doc.data(),
              (data["active"] as? Bool) != false else { return nil }

        let key = language == "ko" ? "greeting_ko" : "greeting_en"
        guard let text = data[key] as? String, !text.isEmpty else { return nil }
        return text
    }

    private func useFallback(mode: AppMode, lang: String) {
        // Plan SC: Firestore 실패 시 하드코딩 폴백으로 정상 표시
        currentGreeting = lang == "ko" ? mode.greetingKr : mode.greeting
    }

    private func useAlarmFallback(mode: AppMode, lang: String) {
        currentAlarmGreeting = lang == "ko" ? mode.alarmGreetingKr : mode.alarmGreetingEn
    }
}
