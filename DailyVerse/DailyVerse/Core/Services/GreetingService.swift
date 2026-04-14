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

@MainActor
class GreetingService: ObservableObject {

    // MARK: - Published

    @Published var currentGreeting: String = ""

    // MARK: - Private

    /// 캐시 key: "{zone_id}_{resolved_lang}" 예: "deep_dark_ko"
    private var cache: [String: String] = [:]
    private let db = Firestore.firestore()

    // MARK: - Public

    /// Zone 진입 시 호출. 캐시 히트 → 즉시 반환, miss → Firestore fetch.
    func load(for mode: AppMode, language: GreetingLanguage) async {
        let resolvedLang = language.resolved()
        let cacheKey = "\(mode.rawValue)_\(resolvedLang)"

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

    private func useFallback(mode: AppMode, lang: String) {
        // Plan SC: Firestore 실패 시 하드코딩 폴백으로 정상 표시
        currentGreeting = lang == "ko" ? mode.greetingKr : mode.greeting
    }
}
