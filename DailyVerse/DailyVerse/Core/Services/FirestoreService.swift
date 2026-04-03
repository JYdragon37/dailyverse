import Foundation
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Verses

    func fetchVerses() async throws -> [Verse] {
        let snapshot = try await db.collection("verses")
            .whereField("status", isEqualTo: "active")
            .whereField("curated", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Verse.self) }
    }

    /// v5.1 — 말씀 노출 후 last_shown + show_count 업데이트 (Cooldown 로직)
    func markVerseAsShown(verseId: String) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        try? await db.collection("verses").document(verseId).updateData([
            "last_shown": today,
            "show_count": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Images

    func fetchImages() async throws -> [VerseImage] {
        let snapshot = try await db.collection("images")
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: VerseImage.self) }
    }

    // MARK: - Daily Cards (v5.1 신규 — 큐레이션 카드)

    /// 특정 날짜의 큐레이션 카드 가져오기
    func fetchDailyCard(for date: Date) async throws -> DailyCard? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let doc = try await db.collection("daily_cards").document(dateString).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        return DailyCard(
            date: dateString,
            verseId: data["verse_id"] as? String,
            imageId: data["image_id"] as? String,
            label: data["label"] as? String,
            note: data["note"] as? String
        )
    }

    // MARK: - Saved Verses

    func fetchSavedVerses(userId: String) async throws -> [SavedVerse] {
        let snapshot = try await db.collection("saved_verses")
            .document(userId)
            .collection("verses")
            .order(by: "saved_at", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: SavedVerse.self) }
    }

    func saveVerse(_ savedVerse: SavedVerse, userId: String) async throws {
        try await db.collection("saved_verses")
            .document(userId)
            .collection("verses")
            .document(savedVerse.id)
            .setData(from: savedVerse)
    }

    func deleteSavedVerse(id: String, userId: String) async throws {
        try await db.collection("saved_verses")
            .document(userId)
            .collection("verses")
            .document(id)
            .delete()
    }

    // MARK: - User

    func createUser(uid: String, email: String, displayName: String, nickname: String = "친구") async throws {
        let userData: [String: Any] = [
            "email": email,
            "display_name": displayName,
            "nickname": nickname,
            "created_at": Timestamp(date: Date()),
            "subscription_status": "free",
            "pinned_images": [:],
            "settings": [
                "timezone": TimeZone.current.identifier,
                "location_enabled": false,
                "notification_enabled": false,
                "preferred_theme": "hope",
                "wake_mission": "none"
            ]
        ]
        try await db.collection("users")
            .document(uid)
            .setData(userData, merge: true)
    }

    func fetchUser(uid: String) async throws -> DVUser? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try? doc.data(as: DVUser.self)
    }

    /// v5.1 — 닉네임 업데이트
    func updateNickname(_ nickname: String, userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "nickname": nickname
        ])
    }

    /// v5.1 — 모드별 핀 이미지 설정
    func updatePinnedImage(_ imageId: String?, forMode mode: AppMode, userId: String) async throws {
        let modeKey = mode.rawValue
        if let imageId {
            try await db.collection("users").document(userId).updateData([
                "pinned_images.\(modeKey)": imageId
            ])
        } else {
            try await db.collection("users").document(userId).updateData([
                "pinned_images.\(modeKey)": FieldValue.delete()
            ])
        }
    }

    func deleteUserData(uid: String) async throws {
        let savedVerses = try await db.collection("saved_verses")
            .document(uid).collection("verses").getDocuments()
        for doc in savedVerses.documents {
            try await doc.reference.delete()
        }
        try await db.collection("users").document(uid).delete()
    }
}

// MARK: - DailyCard 모델 (daily_cards 컬렉션)

struct DailyCard {
    let date: String        // "YYYY-MM-DD"
    let verseId: String?
    let imageId: String?
    let label: String?      // "부활절 특별 말씀" 등
    let note: String?       // 큐레이션 의도 메모
}
