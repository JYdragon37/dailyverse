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

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        // 배경 이미지를 루트로 두고, 모든 콘텐츠를 overlay로 쌓음
        backgroundView
            // 그라데이션 오버레이
            .overlay { gradientOverlay }
            // 인사말: 상단 고정
            .overlay(alignment: .topLeading) {
                greetingHeader
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
            }
            // 카드: 하단 고정
            .overlay(alignment: .bottom) {
                bottomCards
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
            }
            // 토스트 + 코치마크
            .overlay { toastLayer }
            .overlay { CoachMarkOverlay() }
            // 시트
            .sheet(isPresented: $showVerseDetail) { verseDetailSheet }
            .sheet(isPresented: $showLoginPrompt) {
                LoginPromptSheet(
                    onLogin: { Task { await authManager.signIn() } },
                    onDismiss: { showLoginPrompt = false }
                )
            }
            .sheet(isPresented: $showUpsell) {
                UpsellBottomSheet()
                    .environmentObject(subscriptionManager)
                    .environmentObject(upsellManager)
            }
            .task { await viewModel.loadData() }
            .onChange(of: upsellManager.shouldShow) { if $0 { showUpsell = true } }
            .onChange(of: showUpsell) { if !$0 { upsellManager.shouldShow = false } }
    }

    // MARK: - Background

    // Color.clear.ignoresSafeArea()를 wrapper로 써야 overlay 좌표계가 full-screen으로 설정됨
    @ViewBuilder
    private var backgroundView: some View {
        Color.clear
            .ignoresSafeArea()
            .background {
                Group {
                    if let bg = viewModel.currentBackgroundImage {
                        Image(uiImage: bg)
                            .resizable()
                            .scaledToFill()
                    } else if let urlStr = viewModel.currentImage?.storageUrl,
                              let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                fallbackGradient
                            }
                        }
                    } else {
                        fallbackGradient
                    }
                }
                .ignoresSafeArea()
            }
    }

    private var fallbackGradient: some View {
        let colors: [Color]
        switch viewModel.currentMode {
        case .morning:   colors = [Color(red:0.98,green:0.86,blue:0.60), Color(red:0.60,green:0.78,blue:0.95)]
        case .afternoon: colors = [Color(red:0.53,green:0.81,blue:0.98), Color(red:0.35,green:0.55,blue:0.85)]
        case .evening:   colors = [Color(red:0.10,green:0.10,blue:0.28), Color(red:0.05,green:0.05,blue:0.15)]
        case .dawn:      colors = [Color(red:0.06,green:0.06,blue:0.20), Color(red:0.10,green:0.12,blue:0.25)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    // MARK: - Gradient Overlay

    private var gradientOverlay: some View {
        VStack(spacing: 0) {
            // 상단 — 인사말 가독성
            LinearGradient(
                colors: [Color.black.opacity(0.70), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)
            Spacer()
            // 하단 — 카드 가독성
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 380)
        }
        .ignoresSafeArea()
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Good Evening — 큰 텍스트
            HStack(spacing: 10) {
                Image(systemName: viewModel.currentMode.greetingIcon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                Text(viewModel.currentMode.greeting)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }
            // 시간 + 날씨 한 줄
            HStack(spacing: 12) {
                Text(currentTimeString)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                if let weather = viewModel.weather {
                    Text("·")
                        .foregroundColor(.white.opacity(0.5))
                    Image(systemName: weatherIcon(weather.condition))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                    Text("\(weather.cityName)  \(weather.temperature)°C")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    private func weatherIcon(_ condition: String) -> String {
        switch condition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "sun.max.fill"
        }
    }

    private var currentTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }

    // MARK: - Bottom Cards

    private var bottomCards: some View {
        VStack(spacing: 10) {
            if let verse = viewModel.currentVerse {
                VerseCardView(verse: verse, image: viewModel.currentImage) {
                    showVerseDetail = true
                }
                .transition(.dvScaleAndFade)
                .animation(.dvCardExpand, value: viewModel.currentVerse?.id)
            }

            WeatherWidgetView(
                weather: viewModel.weather,
                mode: viewModel.currentMode,
                isLoading: viewModel.isLoading
            )

        }
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

    private func handleSave() {
        guard let verse = viewModel.currentVerse else { return }
        if authManager.isLoggedIn {
            viewModel.saveVerse()
        } else {
            let pending = SavedVerse(
                id: UUID().uuidString, verseId: verse.id, savedAt: Date(),
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

    private func handleNext() { Task { await viewModel.nextVerse() } }

    // MARK: - Toast

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

#Preview("홈") {
    HomeView(viewModel: HomeViewModel.preview())
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
        .environmentObject(PermissionManager())
}
