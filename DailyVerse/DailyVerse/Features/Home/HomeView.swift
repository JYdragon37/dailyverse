import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @ObservedObject private var nicknameManager = NicknameManager.shared

    @State private var showVerseDetail = false
    @State private var showLoginPrompt = false
    @State private var showWeatherDetail = false   // #4 날씨 상세

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        backgroundView
            .overlay { gradientOverlay }
            // 인사말: 상단 고정
            .overlay(alignment: .topLeading) {
                greetingHeader
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
            }
            // #2 말씀 카드: 중앙 배치
            .overlay(alignment: .center) {
                if let verse = viewModel.currentVerse {
                    verseCenter(verse: verse)
                        .padding(.horizontal, 24)
                        .padding(.top, 100) // 인사말 영역과 겹치지 않게 살짝 아래
                }
            }
            .overlay { toastLayer }
            .overlay { CoachMarkOverlay() }
            .sheet(isPresented: $showVerseDetail) { verseDetailSheet }
            .sheet(isPresented: $showLoginPrompt) {
                LoginPromptSheet(
                    onLogin: { Task { await authManager.signIn() } },
                    onDismiss: { showLoginPrompt = false }
                )
            }
            // #4 날씨 상세 시트
            .sheet(isPresented: $showWeatherDetail) {
                if let weather = viewModel.weather {
                    WeatherDetailSheet(weather: weather, mode: viewModel.currentMode)
                        .presentationDetents([.medium])
                }
            }
            .task { await viewModel.loadData() }
    }

    // MARK: - Background
    // AsyncImage로만 로드 (URLSession 방식 제거 — Genspark URL 호환성 개선)

    @ViewBuilder
    private var backgroundView: some View {
        Color.clear
            .ignoresSafeArea()
            .background {
                Group {
                    if let urlStr = viewModel.currentImage?.storageUrl,
                       let url = URL(string: urlStr) {
                        // AsyncImage 대신 User-Agent 포함 URLSession 사용 (Genspark URL 호환)
                        RemoteImageView(url: url) { fallbackGradient }
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
            LinearGradient(
                colors: [Color.black.opacity(0.65), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 200)
            Spacer()
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.70)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Good Afternoon, 친구 🌤
            HStack(spacing: 8) {
                Image(systemName: viewModel.currentMode.greetingIcon)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                if viewModel.currentMode == .dawn {
                    Text("Still awake, \(nicknameManager.nickname)?")
                        .font(.dvLargeTitle).foregroundColor(.white)
                } else {
                    Text("\(viewModel.currentMode.greeting), \(nicknameManager.nickname)")
                        .font(.dvLargeTitle).foregroundColor(.white)
                }
            }

            // 시간 + 날씨(온도+습도) 한 줄 — #3 중복 제거, #4 탭 시 상세
            HStack(spacing: 8) {
                Text(currentTimeString)
                    .font(.dvSubtitle)
                    .foregroundColor(.white.opacity(0.9))

                if let weather = viewModel.weather {
                    Text("·").foregroundColor(.white.opacity(0.4))

                    // #4 날씨 탭 → 상세 시트
                    Button {
                        showWeatherDetail = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: weatherIcon(weather.condition))
                                .font(.system(size: 13))
                            // #3 습도 추가
                            Text("\(weather.cityName) \(weather.temperature)°C · 💧\(weather.humidity)%")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    // MARK: - #2 Verse Center (중앙 배치 + 크기 확대)
    // WeatherWidget 제거 — 날씨 정보는 헤더로 통합

    private func verseCenter(verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // 말씀 텍스트 — 30pt bold (기존 26pt에서 확대)
            Text(verse.textKo)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 2)

            // 성경 참조 + 테마
            HStack(spacing: 8) {
                Text(verse.reference)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                if let firstTheme = verse.theme.first {
                    Text(firstTheme.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.dvAccentGold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.dvAccentGold.opacity(0.2))
                        .clipShape(Capsule())
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
        .onTapGesture { showVerseDetail = true }
        .accessibilityLabel("\(verse.textKo). \(verse.reference)")
        .accessibilityAddTraits(.isButton)
        .transition(.dvScaleAndFade)
        .animation(.dvCardExpand, value: viewModel.currentVerse?.id)
    }

    // MARK: - Helpers

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

// MARK: - #4 WeatherDetailSheet

struct WeatherDetailSheet: View {
    let weather: WeatherData
    let mode: AppMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvPrimaryDeep.ignoresSafeArea()

                VStack(spacing: 28) {
                    // 현재 날씨
                    VStack(spacing: 8) {
                        Text(weather.cityName)
                            .font(.dvLargeTitle).foregroundColor(.white)
                        HStack(spacing: 6) {
                            Image(systemName: conditionIcon(weather.condition))
                                .font(.system(size: 48)).foregroundColor(.dvAccentGold)
                        }
                        Text("\(weather.temperature)°C")
                            .font(.system(size: 56, weight: .thin)).foregroundColor(.white)
                        Text(weather.conditionKo)
                            .font(.dvSubtitle).foregroundColor(.dvTextSecondary)
                    }
                    .padding(.top, 20)

                    // 상세 정보 그리드
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        detailCard(icon: "drop.fill", label: "습도", value: "\(weather.humidity)%", color: .cyan)
                        detailCard(icon: "aqi.low", label: "미세먼지", value: weather.dustGrade, color: dustColor(weather.dustGrade))
                        if let tomorrowTemp = weather.tomorrowMorningTemp,
                           let tomorrowCond = weather.tomorrowMorningCondition {
                            detailCard(icon: "sunrise.fill", label: "내일 아침", value: "\(tomorrowTemp)°C", color: .dvMorningGold)
                            detailCard(icon: conditionIcon(tomorrowCond), label: "내일 날씨", value: weather.tomorrowMorningConditionKo ?? "", color: .dvNoonSky)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("현재 날씨")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.dvAccentGold)
                }
            }
        }
    }

    private func detailCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24)).foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .semibold)).foregroundColor(.white)
            Text(label)
                .font(.dvCaption).foregroundColor(.dvTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }

    private func conditionIcon(_ c: String) -> String {
        switch c {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "sun.max.fill"
        }
    }

    private func dustColor(_ grade: String) -> Color {
        switch grade {
        case "좋음":   return .green
        case "보통":   return .yellow
        case "나쁨":   return .orange
        default:      return .red
        }
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
