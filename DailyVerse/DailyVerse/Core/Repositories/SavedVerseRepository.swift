import Foundation
import Combine

class SavedVerseRepository {
    private let firestoreService = FirestoreService()

    func fetchAll(userId: String) async throws -> [SavedVerse] {
        return try await firestoreService.fetchSavedVerses(userId: userId)
    }

    func save(_ savedVerse: SavedVerse, userId: String) async throws {
        try await firestoreService.saveVerse(savedVerse, userId: userId)
    }

    func delete(id: String, userId: String) async throws {
        try await firestoreService.deleteSavedVerse(id: id, userId: userId)
    }

    // v5.1: 단일 플랜 — 접근 제한 없음, 항상 열람 가능
    // (구버전 SavedAccessLevel 참조 코드와의 호환을 위해 메서드 유지)
    func accessLevel(for savedVerse: SavedVerse, isPremium: Bool) -> SavedAccessLevel {
        return .premium  // 단일 플랜: 모든 유저 무제한
    }
}
