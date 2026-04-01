import SwiftUI
import Combine

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var savedVerses: [SavedVerse] = []
    @Published var isLoading = false
    @Published var toastMessage: String?

    // MARK: - Access State

    /// 저장탭 3단계 접근 제어 (CLAUDE.md §8 기준)
    /// - .free      : 0~7일 모두 / 7일 이상 Premium
    /// - .adRequired: 7~30일 Free 유저 (광고 시청 필요)
    /// - .locked    : 30일 초과 Free 유저 (Premium 유도)
    enum AccessState {
        case free
        case adRequired
        case locked
    }

    // MARK: - Dependencies

    private let savedVerseRepository: SavedVerseRepository

    init(savedVerseRepository: SavedVerseRepository = SavedVerseRepository()) {
        self.savedVerseRepository = savedVerseRepository
    }

    // MARK: - Access Control

    func accessState(for savedVerse: SavedVerse, isPremium: Bool) -> AccessState {
        // Premium 유저는 기간에 관계없이 자유 열람
        if isPremium { return .free }

        let daysSince = Calendar.current
            .dateComponents([.day], from: savedVerse.savedAt, to: Date()).day ?? 0

        if daysSince <= 7 { return .free }
        if daysSince <= 30 { return .adRequired }
        return .locked
    }

    // MARK: - Data Loading

    func loadSavedVerses(userId: String) async {
        isLoading = true
        do {
            let verses = try await savedVerseRepository.fetchAll(userId: userId)
            // 최신순 정렬 (CLAUDE.md §8: 최신순 정렬)
            savedVerses = verses.sorted { $0.savedAt > $1.savedAt }
        } catch {
            showToast("말씀을 불러오지 못했어요. 잠시 후 다시 시도해주세요.")
        }
        isLoading = false
    }

    // MARK: - Deletion

    func deleteSavedVerse(_ savedVerse: SavedVerse, userId: String) async {
        do {
            try await savedVerseRepository.delete(id: savedVerse.id, userId: userId)
            savedVerses.removeAll { $0.id == savedVerse.id }
        } catch {
            showToast("삭제 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            toastMessage = nil
        }
    }
}

