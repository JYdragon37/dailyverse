import SwiftUI
import Combine

struct AlarmStage2View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager

    @State private var showLoginPrompt: Bool = false
    @State private var showUpsell: Bool = false
    @State private var heartScale: CGFloat = 1.0
    @State private var isVisible: Bool = false

    private var currentMode: AppMode { AppMode.current() }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            // 감성 이미지 배경 (폴백: 다크 그라데이션)
            backgroundView

            // 반투명 오버레이
            Color.black.opacity(0.35).ignoresSafeArea()

            // 콘텐츠
            VStack(spacing: 0) {
                // 상단: 인사말 + 날짜
                headerSection
                    .padding(.top, 60)
                    .padding(.horizontal, 24)

                Spacer()

                // 말씀 카드
                if let verse = coordinator.activeVerse {
                    VerseCardView(verse: verse, onTap: {})
                        .padding(.horizontal, 20)
                }

                // 날씨 위젯
                WeatherWidgetView(weather: coordinator.activeWeather, mode: currentMode)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                // 하단 액션 버튼
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            // 0.6s Fade-in
            withAnimation(.dvStageTransition) {
                isVisible = true
            }
        }
        // Edge Case 5: Stage 2 저장 — 미로그인 시 LoginPromptSheet 표시
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet {
                showLoginPrompt = false
                Task { await authManager.signIn() }
            } onDismiss: {
                showLoginPrompt = false
            }
        }
        // Edge Case 4: Stage 2 다음 말씀 — Free 시 업셀 표시
        .sheet(isPresented: $showUpsell) {
            UpsellBottomSheet()
                .environmentObject(subscriptionManager)
                .environmentObject(upsellManager)
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backgroundView: some View {
        if let imageURL = coordinator.activeImage.flatMap({ URL(string: $0.storageUrl) }) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    fallbackGradient
                }
            }
            .ignoresSafeArea()
        } else {
            fallbackGradient
        }
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: gradientColors(for: currentMode),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(currentMode.greeting)
                .font(.dvTitle)
                .foregroundColor(.white)

            Text(todayString)
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // 저장 버튼
            Button {
                handleSave()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .scaleEffect(heartScale)
                        .accessibilityHidden(true)
                    Text("저장")
                        .font(.dvBody)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .accessibilityLabel("말씀 저장하기")

            // 다음 말씀 버튼
            Button {
                handleNextVerse()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle")
                        .accessibilityHidden(true)
                    Text("다음 말씀")
                        .font(.dvBody)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .accessibilityLabel("다음 말씀 보기")

            // 닫기 버튼 → 홈 탭으로 이동, TabBar 복원
            Button {
                coordinator.dismissAll()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .accessibilityLabel("닫기")
        }
    }

    // MARK: - Actions

    private func handleSave() {
        guard let verse = coordinator.activeVerse else { return }

        // Edge Case 5: 미로그인 → LoginPromptSheet 표시
        guard authManager.isLoggedIn else {
            showLoginPrompt = true
            return
        }

        // Heart pulse 애니메이션
        withAnimation(.dvHeartPulse) {
            heartScale = 1.4
        }
        withAnimation(.dvHeartPulse.delay(0.15)) {
            heartScale = 1.0
        }

        // pendingSave 설정 (로그인 후 자동 저장)
        let savedVerse = SavedVerse(
            id: UUID().uuidString,
            verseId: verse.id,
            savedAt: Date(),
            mode: currentMode.rawValue,
            weatherTemp: coordinator.activeWeather?.temperature ?? 0,
            weatherCondition: coordinator.activeWeather?.condition ?? "any",
            weatherHumidity: coordinator.activeWeather?.humidity ?? 0,
            locationName: coordinator.activeWeather?.cityName ?? ""
        )
        authManager.setPendingSave(savedVerse)
    }

    private func handleNextVerse() {
        // Edge Case 4: Free 유저 → 업셀 표시
        guard subscriptionManager.isPremium else {
            upsellManager.show(trigger: .nextVerse)
            showUpsell = upsellManager.shouldShow
            return
        }
        // Premium: 다음 말씀 로드 (VerseRepository.nextVerse는 HomeViewModel에서 관리)
        // Stage 2는 알람 컨텍스트이므로 현재 말씀을 갱신하지 않음 (PRD 범위 외)
    }

    // MARK: - Helpers

    private func gradientColors(for mode: AppMode) -> [Color] {
        switch mode {
        case .morning:
            return [Color(red: 0.95, green: 0.6, blue: 0.3), Color(red: 0.5, green: 0.25, blue: 0.7)]
        case .afternoon:
            return [Color(red: 0.2, green: 0.5, blue: 0.85), Color(red: 0.1, green: 0.3, blue: 0.6)]
        case .evening:
            return [Color(red: 0.05, green: 0.05, blue: 0.2), Color(red: 0.15, green: 0.05, blue: 0.3)]
        }
    }
}

#Preview {
    let coordinator = AlarmCoordinator()
    coordinator.activeVerse = .fallbackMorning
    coordinator.activeWeather = .placeholder

    return AlarmStage2View()
        .environmentObject(coordinator)
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
}
