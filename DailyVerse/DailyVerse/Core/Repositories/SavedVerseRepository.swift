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

    func accessLevel(for savedVerse: SavedVerse, isPremium: Bool) -> SavedAccessLevel {
        if isPremium { return .premium }
        let days = savedVerse.daysSinceSaved
        if days <= 7 { return .free }
        if days <= 30 { return .adRequired }
        return .locked
    }
}
