import SwiftUI

// v5.1 — Saved 탭 리뉴얼
// - 접근 제한 완전 제거 (단일 플랜 전체 무제한)
// - 이미지 썸네일 카드 (3:4 비율, 하단 그라데이션 오버레이)
// - 날짜·날씨·말씀 오버레이

struct SavedView: View {
    @StateObject private var viewModel = SavedViewModel()
    @EnvironmentObject private var authManager: AuthManager

    @State private var selectedVerse: SavedVerse?
    @State private var showLoginPrompt = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                contentBody
                    .navigationTitle("Saved")
                    .navigationBarTitleDisplayMode(.large)

                if let message = viewModel.toastMessage {
                    ToastView(message: message)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.toastMessage)
                }
            }
        }
        .task {
            if authManager.isLoggedIn, let userId = authManager.userId {
                await viewModel.loadSavedVerses(userId: userId)
            }
        }
        .sheet(item: $selectedVerse) { savedVerse in
            SavedDetailView(savedVerse: savedVerse) {
                Task {
                    if let userId = authManager.userId {
                        await viewModel.deleteSavedVerse(savedVerse, userId: userId)
                    }
                }
            }
            .environmentObject(authManager)
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet {
                showLoginPrompt = false
                Task { await authManager.signIn() }
            } onDismiss: {
                showLoginPrompt = false
            }
        }
        .onChange(of: authManager.isLoggedIn) { isLoggedIn in
            if isLoggedIn, let userId = authManager.userId {
                Task { await viewModel.loadSavedVerses(userId: userId) }
            } else if !isLoggedIn {
                viewModel.savedVerses = []
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentBody: some View {
        if viewModel.isLoading {
            loadingView
        } else if !authManager.isLoggedIn {
            emptyStateNotLoggedIn
        } else if viewModel.savedVerses.isEmpty {
            emptyStateNoSaves
        } else {
            savedGrid
        }
    }

    // MARK: - Grid

    private var savedGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(viewModel.savedVerses) { savedVerse in
                    SavedCardView(savedVerse: savedVerse) {
                        selectedVerse = savedVerse
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2)
            Text("말씀을 불러오는 중이에요")
                .font(.dvBody).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty States (v5.1: 2가지만)

    private var emptyStateNotLoggedIn: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bookmark.fill")
                .font(.system(size: 56))
                .foregroundColor(.dvAccentGold)
            Text("말씀을 저장하려면 로그인이 필요해요")
                .font(.dvTitle).multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Apple로 시작하기") { showLoginPrompt = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateNoSaves: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 56))
                .foregroundColor(.dvAccentGold)
            Text("아직 저장된 말씀이 없어요")
                .font(.dvTitle).multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("말씀 카드의 하트를 눌러 저장해보세요")
                .font(.dvBody).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button("홈으로 가기") {
                NotificationCenter.default.post(name: .dvSwitchToHomeTab, object: nil)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SavedCardView (v5.1: 이미지 썸네일 카드, 3:4 비율)

private struct SavedCardView: View {
    let savedVerse: SavedVerse
    let onTap: () -> Void

    private var verseText: String {
        Verse.fallbackVerses.first { $0.id == savedVerse.verseId }?.textKo ?? "저장된 말씀"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.M.d"
        return f.string(from: savedVerse.savedAt)
    }

    private var modeEmoji: String {
        switch savedVerse.mode {
        case "morning":   return "☀️"
        case "afternoon": return "🌤"
        case "evening":   return "🌙"
        case "dawn":      return "✨"
        default:          return ""
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // 배경 이미지
                if let imageId = savedVerse.imageId {
                    AsyncImage(url: nil) { _ in
                        // imageId로 Firestore에서 URL 가져오는 로직은 SavedDetailView에서 처리
                        // 여기서는 색상 기반 폴백 사용
                        modeGradient
                    }
                } else {
                    modeGradient
                }

                // 하단 그라데이션 오버레이 (투명→블랙 40%)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center, endPoint: .bottom
                )

                // 텍스트 오버레이
                VStack(alignment: .leading, spacing: 4) {
                    // 상단: 날짜 + 날씨
                    HStack(spacing: 4) {
                        Text(formattedDate)
                            .font(.system(size: 10, weight: .medium))
                        Text(modeEmoji).font(.system(size: 10))
                        if savedVerse.weatherTemp != 0 {
                            Text("\(savedVerse.weatherTemp)°")
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))

                    // 말씀 텍스트
                    Text(verseText)
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: geo.size.width, height: geo.size.width * 4 / 3)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        .onTapGesture { onTap() }
        .accessibilityLabel("\(formattedDate) 저장된 말씀: \(verseText)")
        .accessibilityAddTraits(.isButton)
    }

    private var modeGradient: some View {
        let colors: [Color]
        switch savedVerse.mode {
        case "morning":   colors = [Color(red:0.98,green:0.86,blue:0.60), Color(red:0.60,green:0.78,blue:0.95)]
        case "afternoon": colors = [Color(red:0.53,green:0.81,blue:0.98), Color(red:0.35,green:0.55,blue:0.85)]
        case "dawn":      colors = [Color(red:0.06,green:0.06,blue:0.20), Color(red:0.10,green:0.12,blue:0.25)]
        default:          colors = [Color(red:0.10,green:0.10,blue:0.28), Color(red:0.05,green:0.05,blue:0.15)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}

#Preview {
    SavedView()
        .environmentObject(AuthManager())
}
