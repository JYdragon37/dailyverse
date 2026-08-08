import SwiftUI
import Combine
import FirebaseAnalytics

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var savedVerses: [SavedVerse] = []
    @Published var isLoading = false
    @Published var toastMessage: String?

    // v5.1: 단일 플랜 — 접근 제한 제거. 전체 무제한 열람.
    // AccessState는 UI 코드 호환을 위해 유지하되 항상 .free 반환

    enum AccessState {
        case free        // 전체 열람 가능
        case adRequired  // v5.1: 미사용 (단일 플랜)
        case locked      // v5.1: 미사용 (단일 플랜)
    }

    private let savedVerseRepository: SavedVerseRepository

    init(savedVerseRepository: SavedVerseRepository = SavedVerseRepository()) {
        self.savedVerseRepository = savedVerseRepository
    }

    // v5.1: 항상 .free 반환
    func accessState(for savedVerse: SavedVerse, isPremium: Bool) -> AccessState {
        return .free
    }

    // MARK: - Data Loading

    func loadSavedVerses(userId: String) async {
        Analytics.logEvent("saved_tab_viewed", parameters: nil)
        isLoading = true
        do {
            let verses = try await savedVerseRepository.fetchAll(userId: userId)
            savedVerses = verses.sorted { $0.savedAt > $1.savedAt }
        } catch {
            showToast(appLanguageString("saved.error.loadFailed"))
        }
        isLoading = false
    }

    // MARK: - Deletion

    func deleteSavedVerse(_ savedVerse: SavedVerse, userId: String) async {
        do {
            try await savedVerseRepository.delete(id: savedVerse.id, userId: userId)
            savedVerses.removeAll { $0.id == savedVerse.id }
        } catch {
            showToast(appLanguageString("saved.error.deleteFailed"))
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastMessage = message
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.toastMessage = nil
        }
    }
}
