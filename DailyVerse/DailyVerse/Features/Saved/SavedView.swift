import SwiftUI
import Combine

struct SavedView: View {
    @StateObject private var viewModel = SavedViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager

    @State private var selectedVerse: SavedVerse?
    @State private var showLoginPrompt = false
    @State private var showUpsell = false

    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                contentBody
                    .navigationTitle("Saved")
                    .navigationBarTitleDisplayMode(.large)

                // 토스트
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
        .sheet(isPresented: $showUpsell) {
            UpsellBottomSheet()
                .environmentObject(subscriptionManager)
                .environmentObject(upsellManager)
        }
        .onChange(of: authManager.isLoggedIn) { isLoggedIn in
            if isLoggedIn, let userId = authManager.userId {
                Task { await viewModel.loadSavedVerses(userId: userId) }
            } else if !isLoggedIn {
                viewModel.savedVerses = []
            }
        }
    }

    // MARK: - Empty State Logic

    private enum EmptyStateType {
        case notLoggedIn
        case noSaves
        case allLocked
    }

    private var emptyStateType: EmptyStateType? {
        if !authManager.isLoggedIn { return .notLoggedIn }
        if viewModel.savedVerses.isEmpty { return .noSaves }
        let allLocked = viewModel.savedVerses.allSatisfy {
            viewModel.accessState(for: $0, isPremium: subscriptionManager.isPremium) == .locked
        }
        return allLocked ? .allLocked : nil
    }

    // MARK: - Content Body

    @ViewBuilder
    private var contentBody: some View {
        if viewModel.isLoading {
            loadingView
        } else if let emptyType = emptyStateType {
            emptyStateView(for: emptyType)
        } else {
            savedGrid
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("말씀을 불러오는 중이에요")
                .font(.dvBody)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Saved Grid

    private var savedGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(viewModel.savedVerses) { savedVerse in
                    let state = viewModel.accessState(
                        for: savedVerse,
                        isPremium: subscriptionManager.isPremium
                    )
                    SavedCardView(savedVerse: savedVerse, accessState: state) {
                        handleCardTap(savedVerse: savedVerse, state: state)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Empty State View

    @ViewBuilder
    private func emptyStateView(for type: EmptyStateType) -> some View {
        VStack(spacing: 24) {
            Spacer()
            switch type {
            case .notLoggedIn:
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.dvAccent)
                    .accessibilityHidden(true)
                Text("말씀을 저장하려면 로그인이 필요해요")
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Apple로 시작하기") {
                    showLoginPrompt = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Apple 계정으로 로그인하기")

            case .noSaves:
                Image(systemName: "heart.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.dvAccent)
                    .accessibilityHidden(true)
                Text("아직 저장된 말씀이 없어요")
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("말씀 카드의 하트를 눌러 저장해보세요")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("홈으로 가기") {
                    NotificationCenter.default.post(name: .dvSwitchToHomeTab, object: nil)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("홈 탭으로 이동하기")

            case .allLocked:
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.dvAccent)
                    .accessibilityHidden(true)
                Text("지난 말씀을 모두 보고 싶으신가요?")
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("Premium에서 전체 아카이브를 만나보세요")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Premium 시작하기") {
                    upsellManager.show(trigger: .savedLocked)
                    showUpsell = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Premium 구독 시작하기")
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tap Handler

    private func handleCardTap(savedVerse: SavedVerse, state: SavedViewModel.AccessState) {
        switch state {
        case .free:
            selectedVerse = savedVerse

        case .adRequired:
            upsellManager.show(trigger: .savedAd)
            guard let rootVC = UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .first(where: \.isKeyWindow)?
                .rootViewController
            else {
                showUpsell = true
                return
            }
            AdManager.shared.showRewardedAd(from: rootVC) { success in
                Task { @MainActor in
                    if success {
                        selectedVerse = savedVerse
                    } else {
                        showUpsell = true
                    }
                }
            }

        case .locked:
            upsellManager.show(trigger: .savedLocked)
            showUpsell = true
        }
    }
}

// MARK: - SavedCardView

private struct SavedCardView: View {
    let savedVerse: SavedVerse
    let accessState: SavedViewModel.AccessState
    let onTap: () -> Void

    private var fallbackVerse: Verse? {
        Verse.fallbackVerses.first { $0.id == savedVerse.verseId }
    }

    private var verseText: String {
        fallbackVerse?.textKo ?? "저장된 말씀"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: savedVerse.savedAt)
    }

    private var modeBadgeText: String {
        switch savedVerse.mode {
        case "morning": return "아침"
        case "afternoon": return "낮"
        case "evening": return "저녁"
        default: return savedVerse.mode
        }
    }

    var body: some View {
        ZStack {
            cardBackground
                .blur(radius: accessState == .free ? 0 : 4)

            if accessState != .free {
                lockedOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .onTapGesture { onTap() }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 모드 뱃지
            Text(modeBadgeText)
                .font(.dvCaption)
                .foregroundColor(.dvAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.dvAccent.opacity(0.12))
                .clipShape(Capsule())

            // 말씀 텍스트
            Text(verseText)
                .font(.dvBody)
                .foregroundColor(.dvPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            // 날짜
            Text(formattedDate)
                .font(.dvCaption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Locked Overlay

    @ViewBuilder
    private var lockedOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.55))

        VStack(spacing: 6) {
            if accessState == .adRequired {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)
                Text("광고 시청 후 열람하기")
                    .font(.dvCaption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)
                Text("Premium에서\n전체 아카이브를")
                    .font(.dvCaption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(8)
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        switch accessState {
        case .free:
            return "\(formattedDate) \(modeBadgeText) \(verseText)"
        case .adRequired:
            return "광고 시청 후 열람 가능한 말씀 \(formattedDate)"
        case .locked:
            return "Premium 전용 잠긴 말씀 \(formattedDate)"
        }
    }
}

// MARK: - Preview

#Preview("로그인 + 말씀 있음") {
    let authManager = AuthManager()
    let subscriptionManager = SubscriptionManager()
    let upsellManager = UpsellManager()
    let viewModel = SavedViewModel()
    viewModel.savedVerses = [
        SavedVerse(
            id: "saved_001",
            verseId: "fallback_morning",
            savedAt: Date(),
            mode: "morning",
            weatherTemp: 18,
            weatherCondition: "sunny",
            weatherHumidity: 65,
            locationName: "서울 강남구"
        ),
        SavedVerse(
            id: "saved_002",
            verseId: "fallback_afternoon",
            savedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            mode: "afternoon",
            weatherTemp: 22,
            weatherCondition: "cloudy",
            weatherHumidity: 70,
            locationName: "서울 마포구"
        ),
        SavedVerse(
            id: "saved_003",
            verseId: "fallback_evening",
            savedAt: Calendar.current.date(byAdding: .day, value: -35, to: Date()) ?? Date(),
            mode: "evening",
            weatherTemp: 8,
            weatherCondition: "rainy",
            weatherHumidity: 90,
            locationName: "부산 해운대구"
        )
    ]
    return SavedView()
        .environmentObject(authManager)
        .environmentObject(subscriptionManager)
        .environmentObject(upsellManager)
}

#Preview("비로그인 빈 상태") {
    SavedView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
}
