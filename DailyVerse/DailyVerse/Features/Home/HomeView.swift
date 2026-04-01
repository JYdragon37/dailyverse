import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager

    @State private var showVerseDetail = false
    @State private var showLoginPrompt = false
    @State private var showUpsell = false

    // Preview 및 테스트에서 외부 주입 가능. 프로덕션에서는 항상 vm을 전달한다.
    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
            toastLayer
            CoachMarkOverlay()
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showVerseDetail) {
            verseDetailSheet
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet(
                onLogin: {
                    Task { await authManager.signIn() }
                },
                onDismiss: { showLoginPrompt = false }
            )
        }
        .sheet(isPresented: $showUpsell) {
            UpsellBottomSheet()
                .environmentObject(subscriptionManager)
                .environmentObject(upsellManager)
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: upsellManager.shouldShow) { newValue in
            if newValue { showUpsell = true }
        }
        .onChange(of: showUpsell) { newValue in
            if !newValue { upsellManager.shouldShow = false }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            if let imageURL = viewModel.currentImage.map({ URL(string: $0.storageUrl) }) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        fallbackBackground
                    @unknown default:
                        fallbackBackground
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .animation(.dvModeTransition, value: viewModel.currentMode)
            } else {
                fallbackBackground
                    .transition(.opacity)
                    .animation(.dvModeTransition, value: viewModel.currentMode)
            }

            // 상하 그라데이션 오버레이 (단일 dvOverlay 대체)
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.4)
                )
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.75)],
                    startPoint: UnitPoint(x: 0.5, y: 0.5),
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    private var fallbackBackground: some View {
        LinearGradient(
            colors: gradientColors(for: viewModel.currentMode),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func gradientColors(for mode: AppMode) -> [Color] {
        switch mode {
        case .morning:
            return [Color(red: 0.98, green: 0.86, blue: 0.60), Color(red: 0.60, green: 0.78, blue: 0.95)]
        case .afternoon:
            return [Color(red: 0.53, green: 0.81, blue: 0.98), Color(red: 0.35, green: 0.55, blue: 0.85)]
        case .evening:
            return [Color(red: 0.10, green: 0.10, blue: 0.28), Color(red: 0.05, green: 0.05, blue: 0.15)]
        }
    }

    // MARK: - Content

    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단 인사말 + 시간
            greetingHeader
                .padding(.top, 60)
                .padding(.horizontal, 20)

            Spacer()

            // 하단 카드 영역
            VStack(spacing: 12) {
                WeatherWidgetView(
                    weather: viewModel.weather,
                    mode: viewModel.currentMode
                )

                if let verse = viewModel.currentVerse {
                    VerseCardView(verse: verse) {
                        showVerseDetail = true
                    }
                    .transition(.dvScaleAndFade)
                    .animation(.dvCardExpand, value: viewModel.currentVerse?.id)
                }

                if viewModel.showAlarmCTA {
                    alarmCTABanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.currentMode.greetingIcon)
                    .foregroundColor(.white)
                Text(viewModel.currentMode.greeting)
                    .font(.dvTitle)
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .transition(.opacity)
            .animation(.dvModeTransition, value: viewModel.currentMode)

            Text(currentTimeString)
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.75))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.currentMode.greeting) \(currentTimeString)")
    }

    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    // MARK: - Alarm CTA Banner

    private var alarmCTABanner: some View {
        Button {
            // 알람 탭으로 이동 — 부모 TabView에서 처리 (Notification 또는 바인딩)
            NotificationCenter.default.post(name: .dvSwitchToAlarmTab, object: nil)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.dvAccent)
                Text("+ 알람 설정하기")
                    .font(.dvBody)
                    .foregroundColor(.dvPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .accessibilityLabel("알람 설정하기")
    }

    // MARK: - Verse Detail Sheet

    private var verseDetailSheet: some View {
        Group {
            if let verse = viewModel.currentVerse {
                VerseDetailBottomSheet(
                    verse: verse,
                    onSave: handleSave,
                    onNext: handleNext,
                    onClose: { showVerseDetail = false }
                )
            }
        }
    }

    // MARK: - Actions

    private func handleSave() {
        guard let verse = viewModel.currentVerse else { return }
        if authManager.isLoggedIn {
            viewModel.saveVerse()
        } else {
            // pendingSave 예약
            let pending = SavedVerse(
                id: UUID().uuidString,
                verseId: verse.id,
                savedAt: Date(),
                mode: viewModel.currentMode.rawValue,
                weatherTemp: viewModel.weather?.temperature ?? 0,
                weatherCondition: viewModel.weather?.condition ?? "any",
                weatherHumidity: viewModel.weather?.humidity ?? 0,
                locationName: viewModel.weather?.cityName ?? ""
            )
            authManager.setPendingSave(pending)
            showLoginPrompt = true
        }
    }

    private func handleNext() {
        Task {
            await viewModel.nextVerse()
            // upsellManager.shouldShow 변화는 onChange에서 감지
        }
    }

    // MARK: - Toast Layer

    private var toastLayer: some View {
        VStack {
            Spacer()
            if let message = viewModel.toastMessage {
                ToastView(message: message)
            }
        }
        .animation(.spring(), value: viewModel.toastMessage)
    }
}

// MARK: - Preview

#Preview("아침 모드") {
    let auth = AuthManager()
    let sub = SubscriptionManager()
    let upsell = UpsellManager()
    let vm = HomeViewModel(authManager: auth, subscriptionManager: sub, upsellManager: upsell)
    vm.currentVerse = .fallbackMorning
    vm.weather = .placeholder
    return HomeView(viewModel: vm)
        .environmentObject(auth)
        .environmentObject(sub)
        .environmentObject(upsell)
}

#Preview("저녁 모드 + 날씨") {
    let auth = AuthManager()
    let sub = SubscriptionManager()
    let upsell = UpsellManager()
    let vm = HomeViewModel(authManager: auth, subscriptionManager: sub, upsellManager: upsell)
    vm.currentVerse = .fallbackEvening
    vm.weather = WeatherData(
        temperature: 15,
        condition: "cloudy",
        conditionKo: "흐림",
        humidity: 70,
        dustGrade: "보통",
        cityName: "서울",
        cachedAt: Date(),
        tomorrowMorningTemp: 13,
        tomorrowMorningCondition: "rainy",
        tomorrowMorningConditionKo: "비"
    )
    return HomeView(viewModel: vm)
        .environmentObject(auth)
        .environmentObject(sub)
        .environmentObject(upsell)
}
