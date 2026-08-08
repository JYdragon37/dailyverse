import SwiftUI

// v5.1 — Saved 탭 리뉴얼
// - 접근 제한 완전 제거 (단일 플랜 전체 무제한)
// - 이미지 썸네일 카드 (3:4 비율, 하단 그라데이션 오버레이)
// - 날짜·날씨·말씀 오버레이

struct SavedView: View {
    @StateObject private var viewModel = SavedViewModel()
    @StateObject private var nativeAdPool = NativeAdPool()
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @ObservedObject private var adManager = AdManager.shared

    @State private var selectedVerse: SavedVerse?
    @State private var showLoginPrompt = false
    @State private var showPremiumUpgrade = false
    @State private var pendingAdVerse: SavedVerse? = nil
    @State private var adTimeoutTask: Task<Void, Never>? = nil

    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                contentBody
                    .navigationTitle(appLanguageString("tab.verses"))
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbarBackground(Color.dvBgDeep.opacity(0.85), for: .navigationBar)

                if let message = viewModel.toastMessage {
                    ToastView(message: message)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.toastMessage)
                }
            }
            .background(Color.dvBgDeep.ignoresSafeArea())
        }
        // 광고 로딩 대기 오버레이
        .overlay {
            if pendingAdVerse != nil {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.dvAccentGold)
                            .scaleEffect(1.3)
                        Text(appLanguageString("saved.adLoading"))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: pendingAdVerse != nil)
            }
        }
        .task {
            if authManager.isLoggedIn, let userId = authManager.userId {
                await viewModel.loadSavedVerses(userId: userId)
            }
            if !subscriptionManager.isPremium {
                AdManager.shared.loadInterstitialAd()
                // 말씀 로드 완료 후 슬롯 수 계산 → native 광고 로드
                let slotCount = max(1, min(5, (viewModel.savedVerses.count / 6) + 1))
                nativeAdPool.load(count: slotCount)
            }
        }
        // 광고 로드 완료 시 대기 중인 카드 자동 처리
        .onChange(of: adManager.isInterstitialReady) { isReady in
            guard isReady, let verse = pendingAdVerse else { return }
            adTimeoutTask?.cancel()
            pendingAdVerse = nil
            showAdThenOpen(verse: verse)
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
        .sheet(isPresented: $showPremiumUpgrade) {
            NavigationStack {
                PremiumUpgradeView()
                    .environmentObject(subscriptionManager)
            }
            .preferredColorScheme(.dark)
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

    // MARK: - 카드 탭 처리 (Free 유저: 전면 광고 → 상세 / Premium: 바로 상세)

    private func handleCardTap(_ verse: SavedVerse) {
        if subscriptionManager.isPremium {
            selectedVerse = verse
            return
        }

        if AdManager.shared.isInterstitialReady {
            // 광고 준비됨 → 즉시 표시
            showAdThenOpen(verse: verse)
        } else if AdManager.shared.isInterstitialLoading {
            // 광고 로딩 중 → 오버레이 표시 후 대기 (최대 5초)
            pendingAdVerse = verse
            adTimeoutTask?.cancel()
            adTimeoutTask = Task {
                try? await Task.sleep(for: .seconds(5))
                await MainActor.run {
                    guard pendingAdVerse != nil else { return }
                    pendingAdVerse = nil
                    selectedVerse = verse
                }
            }
        } else {
            // 광고 없음 → 바로 진입
            selectedVerse = verse
        }
    }

    private func showAdThenOpen(verse: SavedVerse) {
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController.flatMap { vc -> UIViewController? in
                var top = vc
                while let presented = top.presentedViewController { top = presented }
                return top
            }
        guard let vc = rootVC else { selectedVerse = verse; return }
        AdManager.shared.showInterstitialAd(from: vc) {
            Task { @MainActor in selectedVerse = verse }
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

    // MARK: - Premium Banner

    private var premiumBanner: some View {
        Button {
            showPremiumUpgrade = true
        } label: {
            HStack(spacing: 16) {
                Text("👑")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text("더 많은 말씀을 되돌아보고 싶으신가요?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Premium으로 전체 아카이브를 열어보세요")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.50))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.dvAccentGold)
            }
            .padding(16)
            .background(Color.dvBgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.dvAccentGold.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    // MARK: - Grid

    private var savedGrid: some View {
        ScrollView {
            let verses = viewModel.savedVerses
            // 6개씩 청크 분할 — 청크 뒤마다 네이티브 광고 삽입
            let chunks = stride(from: 0, to: verses.count, by: 6).map {
                Array(verses[$0..<min($0 + 6, verses.count)])
            }

            LazyVStack(spacing: 0) {
                ForEach(Array(chunks.enumerated()), id: \.offset) { chunkIdx, chunk in
                    // 말씀 카드 2열 그리드
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(chunk) { savedVerse in
                            SavedCardView(
                                savedVerse: savedVerse,
                                isPremium: subscriptionManager.isPremium,
                                onTap: { handleCardTap(savedVerse) },
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
                    .padding(.bottom, 12)

                    // 청크 뒤 네이티브 광고 (Free 유저만, 청크가 꽉 찬 경우에만 표시)
                    if !subscriptionManager.isPremium && chunk.count == 6 {
                        if chunkIdx < nativeAdPool.ads.count {
                            NativeAdCardView(nativeAd: nativeAdPool.ads[chunkIdx])
                                .frame(height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.bottom, 16)
                        } else {
                            // 아직 로드 중 — 플레이스홀더
                            NativeAdPlaceholder()
                                .padding(.bottom, 16)
                        }
                    }
                }

                // Premium 업그레이드 배너 (Free 유저만)
                if !subscriptionManager.isPremium {
                    premiumBanner
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // 브랜드 footer
            Image("LogoMMColor")
                .resizable()
                .scaledToFit()
                .frame(width: 72)
                .opacity(0.30)
                .padding(.top, 16)
                .padding(.bottom, 100)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2)
            Text(appLanguageString("saved.loading"))
                .font(.dvBody).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty States (v5.1: 2가지만)

    private var emptyStateNotLoggedIn: some View {
        VStack(spacing: 0) {
            Spacer()

            // mm 브랜드 로고
            Image("LogoMMWhite")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .opacity(0.75)
                .padding(.bottom, 28)

            Text(appLanguageString("saved.empty.notLoggedIn.title"))
                .font(.dvTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text(appLanguageString("saved.empty.notLoggedIn.subtitle"))
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer().frame(height: 36)

            Button {
                showLoginPrompt = true
            } label: {
                Text(appLanguageString("saved.login"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dvAccentGold)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateNoSaves: some View {
        VStack(spacing: 0) {
            Spacer()

            // mm 브랜드 로고
            Image("LogoMMWhite")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .opacity(0.75)
                .padding(.bottom, 28)

            Text(appLanguageString("saved.empty.noSaves.title"))
                .font(.dvTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 8)

            Text(appLanguageString("saved.empty.noSaves.subtitle"))
                .font(.dvBody).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
                .padding(.bottom, 32)

            Button(appLanguageString("saved.empty.goHome")) {
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
    let isPremium: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.M.d"
        return f.string(from: savedVerse.savedAt)
    }

    /// 카드 위에 표시할 말씀 텍스트
    /// 1. savedVerse.verseFullKo (저장 당시 기록된 원문)
    /// 2. Core Data 캐시에서 폴백 (기존 저장 말씀에 필드 없을 때)
    private var overlayVerseText: String? {
        if let full = savedVerse.verseFullKo, !full.isEmpty { return full }
        return DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId)?.verseFullKo
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
                    if overlayVerseText != nil {
                        Color.black.opacity(0.38)
                            .allowsHitTesting(false)
                    }

                    // 글귀 오버레이
                    // verseFullKo 없는 기존 저장 말씀 → Core Data 캐시에서 폴백
                    if let text = overlayVerseText {
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

                    // 브랜드 워터마크 (Free 유저만 표시)
                    if !isPremium {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image("LogoMMColor")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28)
                                    .opacity(0.55)
                                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                                    .padding(.trailing, 8)
                                    .padding(.bottom, 8)
                            }
                        }
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
                Label(appLanguageString("alarm.delete"), systemImage: "trash")
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
