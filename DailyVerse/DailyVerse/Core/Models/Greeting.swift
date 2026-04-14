import Foundation

// Design Ref: §2 — Greeting 데이터 모델
// Firestore greetings/{gr_id} 문서에 대응

struct Greeting: Identifiable, Codable {
    let id: String          // gr_id (예: "gr_deep_dark_ko_01")
    let zoneId: String      // "deep_dark"
    let language: String    // "ko" | "en"
    let text: String        // "이 밤도 당신 편이에요."
    let charCount: Int

    enum CodingKeys: String, CodingKey {
        case id       = "gr_id"
        case zoneId   = "zone_id"
        case language
        case text
        case charCount = "char_count"
    }
}
