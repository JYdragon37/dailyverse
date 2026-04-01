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

    // MARK: - Images

    func fetchImages() async throws -> [VerseImage] {
        let snapshot = try await db.collection("images")
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: VerseImage.self) }
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

    func createUser(uid: String, email: String, displayName: String) async throws {
        let userData: [String: Any] = [
            "email": email,
            "display_name": displayName,
            "created_at": Timestamp(date: Date()),
            "subscription_status": "free",
            "settings": [
                "timezone": TimeZone.current.identifier,
                "location_enabled": false,
                "notification_enabled": false,
                "preferred_theme": "hope"
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

    func deleteUserData(uid: String) async throws {
        let savedVerses = try await db.collection("saved_verses")
            .document(uid).collection("verses").getDocuments()
        for doc in savedVerses.documents {
            try await doc.reference.delete()
        }
        try await db.collection("users").document(uid).delete()
    }
}
