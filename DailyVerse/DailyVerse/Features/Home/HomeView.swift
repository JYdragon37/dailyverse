import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator
    @EnvironmentObject private var greetingService: GreetingService
    @ObservedObject private var nicknameManager = NicknameManager.shared
    // Design Ref: §7-1 — 언어 설정 읽기
    @AppStorage("greetingLanguage") private var greetingLanguagePref: String = "random"

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
                    .padding(.horizontal, 24)
            }
            // #2 말씀 카드: 중앙보다 살짝 위, 가로 반응형
            .overlay {
                if let verse = viewModel.currentVerse {
                    GeometryReader { geo in
                        let w = geo.size.width
                        // 가로 여백: 화면 너비의 13% (최소 40pt) → 텍스트 블록 더 좁게
                        let hPad = max(w * 0.13, 40.0)
                        verseCenter(verse: verse)
                            .padding(.horizontal, hPad)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // 화면 상단 42% 위치 (이전 52%보다 위)
                            .position(x: geo.size.width / 2,
                                      y: geo.size.height * 0.48)
                    }
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
            // #4 날씨 상세 시트 — viewModel을 직접 전달하여 새로고침 후 실시간 반영
            .sheet(isPresented: $showWeatherDetail) {
                WeatherDetailSheet(viewModel: viewModel)
            }
            .task { await viewModel.loadData() }
            .task {
                // Design Ref: §7-1 — Zone 진입 시 greeting 로드
                let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
                await greetingService.load(for: viewModel.currentMode, language: lang)
            }
            .onChange(of: viewModel.currentMode) { newMode in
                // Plan SC: Zone 전환 시 새 greeting 선택
                Task {
                    let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
                    await greetingService.load(for: newMode, language: lang)
                }
            }
    }

    // MARK: - Background
    // AsyncImage로만 로드 (URLSession 방식 제거 — Genspark URL 호환성 개선)

    @ViewBuilder
    private var backgroundView: some View {
        Color.clear
            .ignoresSafeArea()
            .background {
                Group {
                    // 우선순위 1: AppRootView가 미리 로드한 이미지 (스플래시 중 로드, 즉시 표시)
                    if let preloaded = loadingCoordinator.zoneBgImage {
                        Image(uiImage: preloaded)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                    // 우선순위 2: zone 변경 시 ViewModel이 로드한 이미지
                    else if let bgUrlStr = viewModel.currentBackground?.storageUrl,
                            let bgUrl = URL(string: bgUrlStr) {
                        RemoteImageView(url: bgUrl) { fallbackGradient }
                    } else {
                        fallbackGradient
                    }
                }
                .ignoresSafeArea()
            }
    }

    private var fallbackGradient: some View {
        // 이미지 로드 전 플레이스홀더 — 각 Zone 다크 테마 그라데이션
        let colors = viewModel.currentMode.gradientColors
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

    /// greeting + 닉네임 조합 — greeting이 구두점으로 끝나면 쉼표 없이 공백만 추가
    /// Design Ref: §7-1 — greetingService 우선, 비어있으면 AppMode 폴백
    private var greetingText: String {
        let g = greetingService.currentGreeting.isEmpty
            ? viewModel.currentMode.greeting
            : greetingService.currentGreeting
        let name = nicknameManager.nickname
        let lastChar = g.last
        if lastChar == "." || lastChar == "!" || lastChar == "?" || lastChar == "," {
            return "\(g) \(name)"
        }
        return "\(g), \(name)"
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Good Afternoon, 친구 🌤
            HStack(spacing: 8) {
                Image(systemName: viewModel.currentMode.greetingIcon)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                // Plan SC: 최장 EN 31자도 레이아웃 깨짐 없음
                Text(greetingText)
                    .font(.dvLargeTitle).foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
            }

            // Fix 1: 시간/날씨 — 아이콘 너비(26)+간격(8)=34pt leading으로 G,D와 수직 정렬
            HStack(spacing: 8) {
                Color.clear.frame(width: 34, height: 1)  // 아이콘+spacing 만큼 들여쓰기

                Text(currentTimeString)
                    .font(.system(size: 17, weight: .semibold))  // 크기 업
                    .foregroundColor(.white.opacity(0.95))

                if let weather = viewModel.weather {
                    Text("·").foregroundColor(.white.opacity(0.4))
                    Button {
                        showWeatherDetail = true
                    } label: {
                        // 날씨 아이콘 제거 (Zone 인사말 아이콘과 중복)
                        // lineLimit(1) + minimumScaleFactor로 한 줄 유지
                        HStack(spacing: 3) {
                            Text("\(weather.cityName) \(weather.temperature)°C ·")
                            Image(systemName: "drop.fill")
                                .font(.system(size: 11))
                            Text("\(weather.humidity)%")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundColor(.white.opacity(0.95))
                    }
                } else {
                    Text("·").foregroundColor(.white.opacity(0.4))
                    Text("Seoul --°C")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    // MARK: - #2 Verse Center (중앙 배치 + 크기 확대)
    // WeatherWidget 제거 — 날씨 정보는 헤더로 통합

    private func verseCenter(verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 말씀 텍스트 — 21pt regular (verseFullKo: 긴 텍스트라 lineSpacing 중요)
            Text(verse.verseFullKo)
                .font(.custom("Georgia-BoldItalic", size: 22))
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

            // 성경 참조 + 테마 + DB 인덱스 (2줄 띄움)
            HStack(spacing: 8) {
                Text(verse.reference)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                if let firstTheme = verse.theme.first, firstTheme != "all" {
                    Text(firstTheme.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.dvAccentGold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.dvAccentGold.opacity(0.2))
                        .clipShape(Capsule())
                }

                Spacer()

                // DB 글귀 번호 표시 (폴백이면 표시 안 함)
                if !verse.id.hasPrefix("fallback_") {
                    Text(verseIndexLabel(verse.id))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 18)  // 출처: 말씀과 2줄 간격

            // 말씀 깊게 보기 힌트
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 20, height: 1)
                Text("말씀 깊게 보기")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.top, 12)
        }
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
        .onTapGesture { showVerseDetail = true }
        .accessibilityLabel("\(verse.verseFullKo). \(verse.reference)")
        .accessibilityAddTraits(.isButton)
        .transition(.dvScaleAndFade)
        .animation(.dvCardExpand, value: viewModel.currentVerse?.id)
    }

    /// "v_007" → "#7" 형태로 변환
    private func verseIndexLabel(_ id: String) -> String {
        let digits = id.filter { $0.isNumber }
        if let n = Int(digits) { return "#\(n)" }
        return ""
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
        let isKorean = greetingLanguagePref == "ko"
        let df = DateFormatter()
        if isKorean {
            df.locale = Locale(identifier: "ko_KR")
            df.dateFormat = "M월 d일 EEE"
        } else {
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "MMM d, EEE"
        }
        let dateStr = df.string(from: Date())
        let tf = DateFormatter()
        tf.locale = Locale(identifier: "en_US_POSIX")
        tf.dateFormat = "h:mm a"
        return "\(dateStr)  \(tf.string(from: Date()))"
    }

    // MARK: - Verse Detail Sheet

    private var verseDetailSheet: some View {
        Group {
            if let verse = viewModel.currentVerse {
                VerseDetailBottomSheet(
                    verse: verse,
                    onSave: handleSave,
                    onMeditation: {
                        showVerseDetail = false
                        NotificationCenter.default.post(name: .dvSwitchToMeditationTab, object: nil)
                    },
                    onClose: { showVerseDetail = false }
                )
            }
        }
    }

    private func handleSave() {
        guard let verse = viewModel.currentVerse else { return }
        if authManager.isLoggedIn {
            viewModel.saveVerse()
            showVerseDetail = false   // 저장 후 팝업 닫기
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

// MARK: - #4 WeatherDetailSheet (iOS Weather 앱 스타일)

struct WeatherDetailSheet: View {
    /// viewModel 직접 관찰 → 새로고침 후 AQI/미세먼지 즉시 반영
    @ObservedObject var viewModel: HomeViewModel
    @State private var isRefreshing = false
    @State private var animating = false

    private var weather: WeatherData? { viewModel.weather }
    private var mode: AppMode { viewModel.currentMode }

    var body: some View {
        ZStack {
            // 동적 날씨 배경 (조건 변경 시 0.5s 전환)
            weatherDetailBackground(condition: weather?.condition ?? "sunny", mode: mode)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: weather?.condition)
            // 가독성 보장용 darkScrim
            Color.black.opacity(weatherScrimOpacity(condition: weather?.condition ?? "sunny", mode: mode))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: weather?.condition)
            // 날씨 파티클 애니메이션 오버레이
            weatherAnimationOverlay(condition: weather?.condition ?? "sunny", mode: mode)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if let weather {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 드래그 인디케이터 + 새로고침 버튼
                        ZStack {
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 36, height: 4)
                            HStack {
                                Spacer()
                                Button {
                                    guard !isRefreshing else { return }
                                    isRefreshing = true
                                    // 캐시 강제 초기화 후 AQI 포함 재요청
                                    Task {
                                        await viewModel.forceRefreshWeather()
                                        isRefreshing = false
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white.opacity(0.7))
                                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                        .animation(
                                            isRefreshing
                                                ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                                : .default,
                                            value: isRefreshing
                                        )
                                }
                                .padding(.trailing, 20)
                            }
                        }
                        .padding(.top, 12)

                        // 위치 + 온도 헤더
                        VStack(spacing: 4) {
                            Text("나의 위치")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))
                            Text(weather.cityName)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(weather.temperature)°")
                                .font(.system(size: 96, weight: .thin))
                                .foregroundColor(.white)
                                .padding(.vertical, -8)
                            Text(weather.conditionKo)
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                            HStack(spacing: 4) {
                                Text("최고:\(weather.highTemp.map { "\($0)°" } ?? "--")")
                                Text("최저:\(weather.lowTemp.map { "\($0)°" } ?? "--")")
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 8)

                        GPTWeatherAdviceCard(weather: weather, zone: mode.rawValue)

                        AQICard(weather: weather)
                        HourlyForecastCard(weather: weather)

                        if !weather.dailyForecast.isEmpty {
                            DailyForecastCard(forecast: weather.dailyForecast)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            WeatherDetailTile(icon: "drop.fill", color: .cyan,
                                              label: "습도", value: "\(weather.humidity)%")
                            WeatherDetailTile(
                                icon: "cloud.rain.fill",
                                color: precipTileColor(weather.precipitationProbability ?? 0),
                                label: "강수",
                                value: weather.precipitationDisplay,
                                subtitle: weather.precipitationAdvice
                            )
                            WeatherDetailTile(
                                icon: "sun.max.fill",
                                color: uvTileColor(weather.uvIndex),
                                label: "자외선",
                                value: weather.uvDisplayValue,
                                subtitle: weather.uvAdvice
                            )
                            WeatherDetailTile(
                                icon: "aqi.low",
                                color: dustTileColor(weather.dustGrade),
                                label: "미세먼지",
                                value: weather.dustDisplayValue,
                                subtitle: weather.dustAdvice
                            )
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                ProgressView().tint(.white)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animating = true
            }
            // 시트 열릴 때 최신 날씨 재조회 → 습도/강수/자외선/미세먼지 즉시 갱신
            Task { await viewModel.forceRefreshWeather() }
        }
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

    // MARK: - 날씨 파티클 애니메이션 오버레이

    @ViewBuilder
    private func weatherAnimationOverlay(condition: String, mode: AppMode) -> some View {
        let isNight = mode == .deepDark || mode == .windDown || mode == .firstLight
        switch condition {
        case "rainy":
            RainParticlesView(animating: animating)
        case "snowy":
            SnowParticlesView(animating: animating)
        case "cloudy":
            CloudDriftView(animating: animating)
        case "sunny" where isNight:
            StarTwinkleView(animating: animating)
        case "sunny":
            SunGlintView(animating: animating)
        default:
            Color.clear
        }
    }

    // MARK: - 날씨 상세 배경 그라데이션

    /// 날씨 조건 + 시간대 기반 배경 그라데이션 (iOS Weather 앱 참고)
    private func weatherDetailBackground(condition: String, mode: AppMode) -> LinearGradient {
        let isNight   = mode == .deepDark || mode == .windDown || mode == .firstLight
        let isEvening = mode == .goldenHour   // 18:00–21:00
        switch condition {
        case "sunny":
            if isNight {
                // 맑은 밤 — 더 어두운 미드나잇 네이비 → 딥 미드나잇 퍼플
                return LinearGradient(
                    colors: [Color(red:0.04,green:0.06,blue:0.22), Color(red:0.14,green:0.08,blue:0.32)],
                    startPoint: .top, endPoint: .bottom
                )
            } else if isEvening {
                // 맑은 저녁 — 앰버 오렌지 → 딥 로즈 (기존 유지)
                return LinearGradient(
                    colors: [Color(red:0.92,green:0.52,blue:0.22), Color(red:0.62,green:0.22,blue:0.32)],
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                // 맑은 낮 — 더 생생한 하늘색 → 밝은 코발트
                return LinearGradient(
                    colors: [Color(red:0.28,green:0.62,blue:0.98), Color(red:0.10,green:0.36,blue:0.88)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        case "cloudy":
            // 흐림 — 쿨 그레이 (더 차갑고 단조롭게)
            return LinearGradient(
                colors: [Color(red:0.32,green:0.35,blue:0.42), Color(red:0.18,green:0.20,blue:0.26)],
                startPoint: .top, endPoint: .bottom
            )
        case "rainy":
            // 비 — 더 어둡고 무거운 스틸 그레이 블루
            return LinearGradient(
                colors: [Color(red:0.12,green:0.16,blue:0.30), Color(red:0.07,green:0.09,blue:0.20)],
                startPoint: .top, endPoint: .bottom
            )
        case "snowy":
            // 눈 — 아이시 화이트 블루
            return LinearGradient(
                colors: [Color(red:0.82,green:0.90,blue:0.98), Color(red:0.58,green:0.70,blue:0.86)],
                startPoint: .top, endPoint: .bottom
            )
        default:
            // 기본 — 딥 네이비
            return LinearGradient(
                colors: [Color(red:0.10,green:0.12,blue:0.22), Color(red:0.08,green:0.08,blue:0.16)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    /// 배경 밝기에 따른 darkScrim opacity — 밝은 배경(sunny낮, snowy)은 강하게
    private func weatherScrimOpacity(condition: String, mode: AppMode) -> Double {
        let isNight   = mode == .deepDark || mode == .windDown || mode == .firstLight
        let isEvening = mode == .goldenHour
        switch condition {
        case "sunny" where !isNight && !isEvening: return 0.35  // 밝은 하늘 — 가독성 위해 강하게
        case "sunny" where isEvening:              return 0.25  // 저녁 앰버
        case "snowy":                              return 0.38  // 밝은 눈 배경
        case "rainy", "cloudy":                    return 0.20  // 어두운 배경
        default:                                   return 0.22
        }
    }

    private func precipTileColor(_ prob: Int) -> Color {
        switch prob {
        case 0:      return .secondary
        case 1...30: return Color(red: 0.55, green: 0.72, blue: 0.90)   // 연파랑
        case 31...60: return Color(red: 0.30, green: 0.55, blue: 0.90)  // 파랑
        default:     return Color(red: 0.18, green: 0.38, blue: 0.82)   // 딥 블루
        }
    }

    private func uvTileColor(_ uvIndex: Int?) -> Color {
        guard let uv = uvIndex else { return .secondary }
        switch uv {
        case 0...2:  return Color(red: 0.30, green: 0.85, blue: 0.75)  // 청록
        case 3...5:  return Color(red: 0.66, green: 0.78, blue: 0.47)  // 연두
        case 6...7:  return Color(red: 0.94, green: 0.63, blue: 0.25)  // 앰버
        case 8...10: return Color(red: 0.88, green: 0.36, blue: 0.25)  // 레드오렌지
        default:     return Color(red: 0.75, green: 0.25, blue: 0.78)  // 퍼플
        }
    }

    private func dustTileColor(_ grade: String) -> Color {
        switch grade {
        case "좋음":    return Color(red: 0.30, green: 0.85, blue: 0.75)  // 청록
        case "보통":    return Color(red: 0.66, green: 0.78, blue: 0.47)  // 연두
        case "나쁨":    return Color(red: 0.94, green: 0.63, blue: 0.25)  // 앰버
        case "매우나쁨": return Color(red: 0.88, green: 0.36, blue: 0.25)  // 레드오렌지
        default:      return .secondary
        }
    }
}

// MARK: - 날씨 파티클 애니메이션 뷰들

/// 빗방울: 대각선으로 떨어지는 얇은 선 (15개)
private struct RainParticlesView: View {
    let animating: Bool

    // 각 빗방울의 초기 오프셋 및 타이밍 오프셋 (15개)
    private let drops: [(xFrac: CGFloat, delay: Double)] = (0..<15).map { i in
        let x = CGFloat(i) / 14.0
        let delay = Double(i) * 0.055
        return (x, delay)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // 빗방울 1개: 세로로 긴 선, 대각선으로 이동
            ForEach(0..<drops.count, id: \.self) { i in
                let drop = drops[i]
                RainDrop(
                    startX: w * drop.xFrac - 40,
                    screenHeight: h,
                    animating: animating,
                    delay: drop.delay
                )
            }
        }
    }
}

private struct RainDrop: View {
    let startX: CGFloat
    let screenHeight: CGFloat
    let animating: Bool
    let delay: Double

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.22))
            .frame(width: 1.2, height: 28)
            .rotationEffect(.degrees(-15))
            .offset(x: startX + (animating ? 30 : 0), y: animating ? offsetY : -screenHeight * 0.2)
            .opacity(opacity)
            .onAppear {
                // 초기 위치를 화면 위 랜덤 지점으로
                offsetY = CGFloat.random(in: -screenHeight * 0.3 ... 0)
                withAnimation(
                    .linear(duration: 0.75)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    offsetY = screenHeight * 1.1
                    opacity = 0.20
                }
            }
    }
}

/// 눈송이: 천천히 흔들리며 떨어지는 작은 원 (12개)
private struct SnowParticlesView: View {
    let animating: Bool

    private let flakes: [(xFrac: CGFloat, size: CGFloat, delay: Double)] = (0..<12).map { i in
        let x = CGFloat(i) / 11.0
        let size = CGFloat.random(in: 4...8)
        let delay = Double(i) * 0.28
        return (x, size, delay)
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<flakes.count, id: \.self) { i in
                let flake = flakes[i]
                SnowFlake(
                    startX: geo.size.width * flake.xFrac,
                    screenHeight: geo.size.height,
                    size: flake.size,
                    animating: animating,
                    delay: flake.delay
                )
            }
        }
    }
}

private struct SnowFlake: View {
    let startX: CGFloat
    let screenHeight: CGFloat
    let size: CGFloat
    let animating: Bool
    let delay: Double

    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.25))
            .frame(width: size, height: size)
            .offset(x: startX + offsetX, y: animating ? offsetY : -80)
            .onAppear {
                offsetY = CGFloat.random(in: -screenHeight * 0.1 ... 0)
                withAnimation(
                    .easeInOut(duration: Double.random(in: 3.5...5.0))
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    offsetY = screenHeight * 1.1
                }
                withAnimation(
                    .easeInOut(duration: 2.2)
                    .repeatForever(autoreverses: true)
                    .delay(delay * 0.5)
                ) {
                    offsetX = CGFloat.random(in: -18...18)
                }
            }
    }
}

/// 흐림: 반투명 타원이 가로로 천천히 흘러가는 구름 느낌 (4개)
private struct CloudDriftView: View {
    let animating: Bool

    private let clouds: [(yFrac: CGFloat, widthFrac: CGFloat, delay: Double)] = [
        (0.12, 0.55, 0.0),
        (0.30, 0.45, 2.5),
        (0.55, 0.60, 5.0),
        (0.75, 0.40, 7.0)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<clouds.count, id: \.self) { i in
                let c = clouds[i]
                CloudBlob(
                    startY: geo.size.height * c.yFrac,
                    blobWidth: geo.size.width * c.widthFrac,
                    screenWidth: geo.size.width,
                    animating: animating,
                    delay: c.delay
                )
            }
        }
    }
}

private struct CloudBlob: View {
    let startY: CGFloat
    let blobWidth: CGFloat
    let screenWidth: CGFloat
    let animating: Bool
    let delay: Double

    @State private var offsetX: CGFloat = 0

    var body: some View {
        Ellipse()
            .fill(Color.white.opacity(0.10))
            .frame(width: blobWidth, height: blobWidth * 0.28)
            .offset(x: animating ? offsetX : -blobWidth, y: startY)
            .onAppear {
                offsetX = -blobWidth * 0.3
                withAnimation(
                    .linear(duration: 9.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    offsetX = screenWidth + blobWidth * 0.2
                }
            }
    }
}

/// 맑은 낮: 은은한 빛 반짝임 (3개)
private struct SunGlintView: View {
    let animating: Bool

    private let glints: [(xFrac: CGFloat, yFrac: CGFloat, delay: Double)] = [
        (0.15, 0.08, 0.0),
        (0.72, 0.18, 0.9),
        (0.45, 0.05, 1.8)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<glints.count, id: \.self) { i in
                let g = glints[i]
                SunGlint(
                    x: geo.size.width * g.xFrac,
                    y: geo.size.height * g.yFrac,
                    animating: animating,
                    delay: g.delay
                )
            }
        }
    }
}

private struct SunGlint: View {
    let x: CGFloat
    let y: CGFloat
    let animating: Bool
    let delay: Double

    @State private var glintOpacity: Double = 0.05

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 80, height: 80)
            .blur(radius: 28)
            .opacity(animating ? glintOpacity : 0.05)
            .position(x: x, y: y)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.2)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    glintOpacity = 0.22
                }
            }
    }
}

/// 맑은 밤: 별빛 반짝임 (7개)
private struct StarTwinkleView: View {
    let animating: Bool

    private let stars: [(xFrac: CGFloat, yFrac: CGFloat, size: CGFloat, delay: Double)] = [
        (0.12, 0.06, 3.0, 0.0),
        (0.35, 0.12, 2.5, 0.6),
        (0.62, 0.04, 4.0, 1.2),
        (0.80, 0.15, 2.0, 0.3),
        (0.25, 0.20, 3.5, 1.8),
        (0.55, 0.08, 2.5, 0.9),
        (0.90, 0.10, 3.0, 1.5)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<stars.count, id: \.self) { i in
                let s = stars[i]
                StarDot(
                    x: geo.size.width * s.xFrac,
                    y: geo.size.height * s.yFrac,
                    size: s.size,
                    animating: animating,
                    delay: s.delay
                )
            }
        }
    }
}

private struct StarDot: View {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let animating: Bool
    let delay: Double

    @State private var starOpacity: Double = 0.10

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .opacity(animating ? starOpacity : 0.10)
            .position(x: x, y: y)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    starOpacity = 0.80
                }
            }
    }
}

// MARK: - GPT 날씨 조언 카드
private struct GPTWeatherAdviceCard: View {
    let weather: WeatherData
    let zone: String              // Zone rawValue — 변경 시에만 GPT 재호출
    @State private var advice: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            if isLoading {
                ProgressView().tint(.white).frame(width: 40)
            } else {
                Image(systemName: adviceIcon)
                    .font(.system(size: 26))
                    .foregroundColor(adviceColor)
                    .frame(width: 40)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(adviceTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text(isLoading ? "날씨 정보 분석 중..." : advice)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
        .task {
            // Zone 기반 캐시 확인 → Zone 변경 시에만 GPT 재호출
            advice = await WeatherAdviceService.shared.fetchAdvice(for: weather, zone: zone)
            // 오래된 Zone 캐시 정리
            await WeatherAdviceService.shared.clearOldCache(currentZone: zone)
            isLoading = false
        }
    }

    private var adviceTitle: String {
        switch zone {
        case "golden_hour", "wind_down": return "내일 날씨 미리보기"
        case "deep_dark", "first_light": return "오늘 하루 날씨"
        default: return "오늘의 날씨 팁"
        }
    }

    private var adviceIcon: String {
        switch zone {
        case "deep_dark":   return "moon.fill"
        case "first_light": return "moon.stars.fill"
        case "rise_ignite": return "sunrise.fill"
        case "peak_mode":   return "sun.max.fill"
        case "recharge":    return "sun.and.horizon.fill"
        case "second_wind": return "cloud.sun.fill"
        case "golden_hour": return "sunset.fill"
        default:            return "moon.stars.fill"
        }
    }

    private var adviceColor: Color {
        switch zone {
        case "golden_hour", "wind_down": return .blue
        case "rise_ignite", "peak_mode": return .yellow
        default: return .white
        }
    }
}

// MARK: - 7일 예보 (iOS 날씨 앱 스타일)

private struct DailyForecastCard: View {
    let forecast: [DailyForecastItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                Text("7일간의 날씨")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            let allHighs = forecast.map { $0.highTemp }
            let allLows = forecast.map { $0.lowTemp }
            let rangeMin = allLows.min() ?? 0
            let rangeMax = allHighs.max() ?? 30
            let totalRange = Double(max(rangeMax - rangeMin, 1))

            ForEach(Array(forecast.enumerated()), id: \.offset) { idx, day in
                VStack(spacing: 0) {
                    if idx > 0 {
                        Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                    }
                    DailyForecastRow(
                        day: day,
                        rangeMin: rangeMin,
                        rangeMax: rangeMax,
                        totalRange: totalRange,
                        isToday: idx == 0
                    )
                }
            }
            .padding(.bottom, 8)
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
    }
}

private struct DailyForecastRow: View {
    let day: DailyForecastItem
    let rangeMin: Int
    let rangeMax: Int
    let totalRange: Double
    let isToday: Bool

    private func conditionIcon(_ c: String) -> String {
        switch c {
        case "sunny": return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy": return "cloud.rain.fill"
        case "snowy": return "snowflake"
        default: return "cloud.fill"
        }
    }

    private func conditionColor(_ c: String) -> Color {
        switch c {
        case "sunny": return .yellow
        case "rainy": return .blue
        case "snowy": return .white
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(isToday ? "오늘" : dayString(day.date))
                .font(.system(size: 17, weight: isToday ? .semibold : .regular))
                .foregroundColor(.white)
                .frame(width: 44, alignment: .leading)

            VStack(spacing: 2) {
                Image(systemName: conditionIcon(day.condition))
                    .font(.system(size: 18))
                    .foregroundColor(conditionColor(day.condition))
                if day.precipitationProbability >= 20 {
                    Text("\(day.precipitationProbability)%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.cyan)
                }
            }
            .frame(width: 38)

            Text("\(day.lowTemp)°")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 32, alignment: .trailing)

            GeometryReader { geo in
                let lowFrac = Double(day.lowTemp - rangeMin) / totalRange
                let highFrac = Double(day.highTemp - rangeMin) / totalRange
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15)).frame(height: 4)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.cyan, .yellow],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(
                            width: max(8, width * (highFrac - lowFrac)),
                            height: 4
                        )
                        .offset(x: width * lowFrac)
                }
            }
            .frame(height: 4)

            Text("\(day.highTemp)°")
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 32, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "E"
        return f.string(from: date)
    }
}

// MARK: - AQI Card

private struct AQICard: View {
    let weather: WeatherData

    private var aqiNum: Int { weather.aqi ?? weather.dustGradeToAqi }
    private var aqiDesc: String { weather.aqiDescription ?? weather.dustGrade }
    /// aqi 필드가 실제 API 데이터인지 여부
    private var isRealAQI: Bool { weather.aqi != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: "aqi.low")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                Text("대기질")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                Spacer()
            }

            // AQI 수치 + 등급 (실측 여부 표시)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(aqiNum) - \(aqiDesc)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                if !isRealAQI {
                    Text("추정값")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
            }

            // 컬러 게이지
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 트랙
                    LinearGradient(
                        colors: [.green, .yellow, .orange, .red],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(height: 6)
                    .clipShape(Capsule())

                    // 인디케이터
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(geo.size.width - 14, geo.size.width * weather.aqiFraction - 7)))
                }
                .frame(height: 14)
            }
            .frame(height: 14)

            // 설명 텍스트
            Text("현재 대기질 지수는 \(aqiNum) 수준으로 \(aqiDesc)입니다.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dvBorderMid, lineWidth: 1))
        )
    }
}

// MARK: - Hourly Forecast Card

private struct HourlyForecastCard: View {
    let weather: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                Text("시간별 일기예보")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                Spacer()
            }

            if weather.hourlyForecast.isEmpty {
                Text("시간별 예보 정보를 불러오는 중...")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        // 첫 항목: 현재 실시간 날씨 (API 예보는 최소 1-2시간 이후부터 시작)
                        let currentItem = HourlyForecastItem(
                            time: Date(),
                            temperature: weather.temperature,
                            condition: weather.condition,
                            conditionKo: weather.conditionKo
                        )
                        HourlyItem(item: currentItem, isNow: true)

                        // 이후 예보 항목들
                        ForEach(Array(weather.hourlyForecast.enumerated()), id: \.offset) { _, item in
                            HourlyItem(item: item, isNow: false)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dvBorderMid, lineWidth: 1))
        )
    }
}

private struct HourlyItem: View {
    let item: HourlyForecastItem
    let isNow: Bool

    private var timeLabel: String {
        if isNow { return "지금" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        // "오전 1시" → 잘림 방지: "오전\n1시" 두 줄로 표시
        f.dateFormat = "a"
        let ampm = f.string(from: item.time)  // "오전" or "오후"
        f.dateFormat = "h시"
        let hour = f.string(from: item.time)  // "1시"
        return "\(ampm)\n\(hour)"
    }

    private var conditionIcon: String {
        switch item.condition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "sun.max.fill"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // 시간 레이블 — 고정 높이
            Text(timeLabel)
                .font(.system(size: 12, weight: isNow ? .semibold : .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30)
            // 아이콘 — 고정 프레임으로 높이 통일 (Fix 1)
            Image(systemName: conditionIcon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)  // 고정 크기로 정렬
            // 온도 — 항상 같은 위치에 표시
            Text("\(item.temperature)°")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(height: 20)
        }
        .frame(width: 46)
    }
}

// MARK: - Detail Tile

private struct WeatherDetailTile: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
            Text(label).font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dvBorderMid, lineWidth: 1))
        )
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
