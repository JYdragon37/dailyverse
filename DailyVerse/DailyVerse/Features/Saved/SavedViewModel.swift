import SwiftUI
import Combine

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var savedVerses: [SavedVerse] = []
    @Published var isLoading = false
    @Published var toastMessage: String?

    // v5.2: 출처별 필터
    enum SavedFilter: String, CaseIterable {
        case all   = "전체"
        case home  = "홈"
        case alarm = "알람"
    }
    @Published var selectedFilter: SavedFilter = .all

    var filteredVerses: [SavedVerse] {
        switch selectedFilter {
        case .all:   return savedVerses
        case .home:  return savedVerses.filter { $0.source == .home }
        case .alarm: return savedVerses.filter { $0.source == .alarm }
        }
    }

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
        isLoading = true
        do {
            let verses = try await savedVerseRepository.fetchAll(userId: userId)
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
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.toastMessage = nil
        }
    }
}
