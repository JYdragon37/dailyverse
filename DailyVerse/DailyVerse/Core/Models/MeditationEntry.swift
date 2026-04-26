import Foundation
import CryptoKit

// MARK: - MeditationEntry
// 하루 1개 묵상 기록. dateKey가 Firestore 문서 ID 겸용.

struct MeditationEntry: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let dateKey: String                // "2026-04-09" (날짜 키)
    let verseId: String
    let verseReference: String         // "이사야 41:10" (표시용 캐시)
    let mode: String                   // AppMode.rawValue
    var prayerItems: [PrayerItem]
    var gratitudeNote: String?
    let createdAt: Date
    var updatedAt: Date
    let source: String                 // "manual" | "stage2" | "guided"
    var prayer: String?                // 한 줄 기도 (max 50자) — guided flow용
    var readingText: String?           // 읽기 타이핑 텍스트 — guided flow용
    var imageUrl: String? = nil        // 저장 당시 배경 이미지 URL (랜덤 선택)
    var locationName: String? = nil    // 저장 당시 도시명 (영문, 예: "Seoul")

    var isToday: Bool {
        dateKey == Self.todayKey()
    }

    var answeredCount: Int {
        prayerItems.filter { $0.isAnswered }.count
    }

    static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    static func make(
        userId: String,
        verseId: String,
        verseReference: String,
        mode: String,
        prayerItems: [PrayerItem],
        gratitudeNote: String?,
        prayer: String? = nil,
        readingText: String? = nil,
        imageUrl: String? = nil,
        locationName: String? = nil,
        source: String = "manual"
    ) -> MeditationEntry {
        MeditationEntry(
            id: UUID().uuidString,
            userId: userId,
            dateKey: todayKey(),
            verseId: verseId,
            verseReference: verseReference,
            mode: mode,
            prayerItems: prayerItems,
            gratitudeNote: gratitudeNote?.isEmpty == true ? nil : gratitudeNote,
            createdAt: Date(),
            updatedAt: Date(),
            source: source,
            prayer: prayer?.isEmpty == true ? nil : prayer,
            readingText: readingText?.isEmpty == true ? nil : readingText,
            imageUrl: imageUrl,
            locationName: locationName
        )
    }

    // MARK: - Codable CodingKeys (camelCase → snake_case 수동 매핑)
    enum CodingKeys: String, CodingKey {
        case id
        case userId       = "user_id"
        case dateKey      = "date_key"
        case verseId      = "verse_id"
        case verseReference = "verse_reference"
        case mode
        case prayerItems  = "prayer_items"
        case gratitudeNote = "gratitude_note"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
        case source
        case prayer
        case readingText  = "reading_text"
        case imageUrl     = "image_url"
        case locationName = "location_name"
    }
}

// MARK: - PrayerItem

struct PrayerItem: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var isAnswered: Bool
    var answeredAt: Date?

    init(id: String = UUID().uuidString,
         text: String,
         isAnswered: Bool = false,
         answeredAt: Date? = nil) {
        self.id = id
        self.text = text
        self.isAnswered = isAnswered
        self.answeredAt = answeredAt
    }

    static func make(text: String) -> PrayerItem {
        PrayerItem(text: text)
    }

    mutating func markAnswered() {
        isAnswered = true
        answeredAt = Date()
    }

    mutating func unmarkAnswered() {
        isAnswered = false
        answeredAt = nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isAnswered  = "is_answered"
        case answeredAt  = "answered_at"
    }
}

// MARK: - 기도·감사 필드 암호화 (CryptoKit AES-GCM)

extension MeditationEntry {

    /// 앱 번들 ID + UID 조합으로 결정론적 키 생성
    /// 같은 기기·같은 유저는 항상 같은 키를 가짐
    static func encryptionKey(userId: String) -> SymmetricKey {
        let bundleId = Bundle.main.bundleIdentifier ?? "morning.manna"
        let seed = "\(bundleId).\(userId).meditation.v1"
        let seedData = Data(seed.utf8)
        let hash = SHA256.hash(data: seedData)
        return SymmetricKey(data: hash)
    }

    static func encrypt(_ text: String, key: SymmetricKey) -> String {
        guard !text.isEmpty,
              let data = text.data(using: .utf8),
              let sealed = try? AES.GCM.seal(data, using: key) else {
            return text  // 암호화 실패 시 원문 반환 (하위 호환)
        }
        return sealed.combined?.base64EncodedString() ?? text
    }

    static func decrypt(_ text: String, key: SymmetricKey) -> String {
        // Base64 디코딩 실패 = 이미 평문 (이전 데이터 하위 호환)
        guard !text.isEmpty,
              let data = Data(base64Encoded: text),
              let sealed = try? AES.GCM.SealedBox(combined: data),
              let decrypted = try? AES.GCM.open(sealed, using: key),
              let result = String(data: decrypted, encoding: .utf8) else {
            return text  // 평문 그대로 반환
        }
        return result
    }
}
