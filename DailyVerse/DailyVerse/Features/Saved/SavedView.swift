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
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                contentBody
                    .navigationTitle("말씀들")
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
                showLoginPrompt = false   // 로그인 성공 시 시트 자동 닫기
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
                    SavedCardView(
                        savedVerse: savedVerse,
                        onTap: { selectedVerse = savedVerse },
                        onDelete: {
                            Task {
                                if let userId = authManager.userId {
                                    await viewModel.deleteSavedVerse(savedVerse, userId: userId)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
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
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 52))
                .foregroundColor(.dvAccentGold.opacity(0.85))
                .padding(.bottom, 20)

            Text("저장한 말씀이 여기에 모여요")
                .font(.dvTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text("로그인하면 말씀을 저장하고\n언제든 다시 꺼내볼 수 있어요")
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer().frame(height: 36)

            Button {
                showLoginPrompt = true
            } label: {
                Text("로그인 하기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dvAccentGold)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)

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

// MARK: - SavedCardView (v5.2: 이미지 썸네일 카드, 3:4 비율 + 하단 시간/날씨 바)

private struct SavedCardView: View {
    let savedVerse: SavedVerse
    let onTap: () -> Void
    let onDelete: () -> Void

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.M.d"
        return f.string(from: savedVerse.savedAt)
    }

    private var weatherConditionEmoji: String {
        switch savedVerse.weatherCondition {
        case "sunny":  return "☀️"
        case "cloudy": return "☁️"
        case "rainy":  return "🌧️"
        case "snowy":  return "❄️"
        default:       return "🌤️"
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // 카드 이미지 영역
            GeometryReader { geo in
                ZStack {
                    // 배경 이미지
                    if let urlStr = savedVerse.imageUrl, let url = URL(string: urlStr) {
                        RemoteImageView(url: url) { modeGradient }
                            .scaledToFill()
                            .clipped()
                    } else {
                        modeGradient
                    }

                    // 글귀 가독성을 위한 다크 스크림
                    if savedVerse.verseFullKo != nil {
                        Color.black.opacity(0.38)
                            .allowsHitTesting(false)
                    }

                    // 글귀 오버레이
                    if let text = savedVerse.verseFullKo {
                        Text(text)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 14)
                            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width * 4 / 3)
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // 이미지 아래 날짜 + 날씨 정보 바
            HStack(spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                if savedVerse.weatherTemp != 0 {
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(weatherConditionEmoji) \(savedVerse.weatherTemp)°")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        .onTapGesture { onTap() }
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(formattedDate) 저장된 말씀")
        .accessibilityAddTraits(.isButton)
    }

    private var modeGradient: some View {
        let mode = AppMode(rawValue: savedVerse.mode) ?? AppMode.current()
        return LinearGradient(colors: mode.gradientColors, startPoint: .top, endPoint: .bottom)
    }
}

#Preview {
    SavedView()
        .environmentObject(AuthManager())
}
