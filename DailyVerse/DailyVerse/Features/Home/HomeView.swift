import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator
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
                    .padding(.horizontal, 28)
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
    private var greetingText: String {
        let g = viewModel.currentMode.greeting
        let name = nicknameManager.nickname
        let lastChar = g.last
        if lastChar == "." || lastChar == "!" || lastChar == "?" {
            // "Breathe. Reset." → "Breathe. Reset. 친구"
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
                Text(greetingText)
                    .font(.dvLargeTitle).foregroundColor(.white)
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
                        Text("\(weather.cityName) \(weather.temperature)°C · 💧\(weather.humidity)%")
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    // MARK: - #2 Verse Center (중앙 배치 + 크기 확대)
    // WeatherWidget 제거 — 날씨 정보는 헤더로 통합

    private func verseCenter(verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 말씀 텍스트 — 21pt regular (textFullKo: 긴 텍스트라 lineSpacing 중요)
            Text(verse.textFullKo)
                .font(.system(size: 22, weight: .semibold))
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
        }
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
        .onTapGesture { showVerseDetail = true }
        .accessibilityLabel("\(verse.textFullKo). \(verse.reference)")
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

// MARK: - #4 WeatherDetailSheet (iOS Weather 앱 스타일)

struct WeatherDetailSheet: View {
    /// viewModel 직접 관찰 → 새로고침 후 AQI/미세먼지 즉시 반영
    @ObservedObject var viewModel: HomeViewModel
    @State private var isRefreshing = false

    private var weather: WeatherData? { viewModel.weather }
    private var mode: AppMode { viewModel.currentMode }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

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

                        AQICard(weather: weather)
                        HourlyForecastCard(weather: weather)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            WeatherDetailTile(icon: "drop.fill", color: .cyan,
                                              label: "습도", value: "\(weather.humidity)%")
                            // 에어코리아 실측값 우선, 없으면 등급 표시
                            WeatherDetailTile(
                                icon: "aqi.low",
                                color: aqiColor(weather.dustGrade),
                                label: weather.pm25 != nil ? "PM2.5 (에어코리아)" : "미세먼지",
                                value: weather.pm25.map { "\(Int($0)) μg/m³" } ?? weather.dustGrade
                            )
                            if let pm10 = weather.pm10 {
                                WeatherDetailTile(
                                    icon: "wind",
                                    color: aqiColor(weather.dustGrade),
                                    label: "PM10",
                                    value: "\(Int(pm10)) μg/m³"
                                )
                            }
                            if let tomorrowTemp = weather.tomorrowMorningTemp {
                                WeatherDetailTile(icon: "sunrise.fill", color: .dvMorningGold,
                                                  label: "내일 아침", value: "\(tomorrowTemp)°")
                            }
                            if let tomorrowCond = weather.tomorrowMorningConditionKo {
                                WeatherDetailTile(icon: conditionIcon(weather.tomorrowMorningCondition ?? ""),
                                                  color: .dvNoonSky, label: "내일 날씨", value: tomorrowCond)
                            }
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

    private func aqiColor(_ grade: String) -> Color {
        switch grade {
        case "좋음": return .green
        case "보통": return .yellow
        case "나쁨": return .orange
        default:    return .red
        }
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

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
            Text(label).font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
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
