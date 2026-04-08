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

                        TomorrowActionCard(weather: weather)

                        AQICard(weather: weather)
                        HourlyForecastCard(weather: weather)

                        if !weather.dailyForecast.isEmpty {
                            DailyForecastCard(forecast: weather.dailyForecast)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            WeatherDetailTile(icon: "drop.fill", color: .cyan,
                                              label: "습도", value: "\(weather.humidity)%")
                            WeatherDetailTile(icon: "cloud.rain.fill", color: .blue,
                                              label: "강수 확률",
                                              value: weather.precipitationProbability.map { "\($0)%" } ?? "--")
                            WeatherDetailTile(icon: "sun.max.fill", color: .yellow,
                                              label: "자외선",
                                              value: weather.uvIndex.map { "\($0) \(weather.uvIndexDescription)" } ?? "--")
                            WeatherDetailTile(
                                icon: "aqi.low",
                                color: aqiColor(weather.dustGrade),
                                label: weather.pm25 != nil ? "PM2.5" : "미세먼지",
                                value: weather.pm25.map { "\(Int($0))μg/m³" } ?? weather.dustGrade
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

// MARK: - 내일 날씨 액션 카드

private struct TomorrowActionCard: View {
    let weather: WeatherData

    /// 내일 시간별 예보에서 비/눈 예보 여부 확인 (tomorrowPrecipitationProbability가 nil인 경우 보완)
    private var tomorrowHasRain: Bool {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return weather.hourlyForecast.contains {
            cal.isDate($0.time, inSameDayAs: tomorrow) && $0.condition == "rainy"
        }
    }
    private var tomorrowHasSnow: Bool {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return weather.hourlyForecast.contains {
            cal.isDate($0.time, inSameDayAs: tomorrow) && $0.condition == "snowy"
        }
    }

    private var actionMessage: (icon: String, color: Color, title: String, message: String) {
        let rainProb = weather.tomorrowPrecipitationProbability ?? 0
        let temp = weather.tomorrowMorningTemp ?? weather.temperature
        let cond = weather.tomorrowMorningCondition ?? weather.condition
        let uv = weather.uvIndex ?? 0
        // 시간별 예보로 보완 (tomorrowPrecipitationProbability nil 대비)
        let hasRain = tomorrowHasRain || cond == "rainy"
        let hasSnow = tomorrowHasSnow || cond == "snowy"

        if hasRain && rainProb >= 60 {
            return ("umbrella.fill", .blue, "내일 비 소식", "강수 확률 \(rainProb)%, 우산 꼭 챙기세요 ☂️")
        } else if hasRain {
            let probText = rainProb > 0 ? "강수 확률 \(rainProb)%, " : "내일 비 예보가 있어요. "
            return ("umbrella.fill", .blue, "내일 비 소식", "\(probText)우산 챙기세요 ☂️")
        } else if rainProb >= 30 {
            return ("cloud.drizzle.fill", .cyan, "비 올 수도 있어요", "강수 확률 \(rainProb)%, 접이식 우산이 있으면 좋겠어요")
        } else if hasSnow {
            return ("snowflake", .white, "내일 눈이 와요", "미끄러운 길 조심하고, 따뜻하게 입으세요 🧥")
        } else if temp <= -5 {
            return ("thermometer.snowflake", Color(red: 0.5, green: 0.8, blue: 1), "매우 추운 날씨", "내일 아침 \(temp)°C, 최대한 따뜻하게 입으세요 🧤")
        } else if temp <= 5 {
            return ("thermometer.low", .cyan, "꽤 추운 날씨", "내일 아침 \(temp)°C, 외투 꼭 챙기세요 🧥")
        } else if uv >= 8 {
            return ("sun.max.trianglebadge.exclamationmark.fill", .orange, "자외선 매우 강함", "외출 시 자외선 차단제 필수예요 🧴")
        } else if uv >= 6 {
            return ("sun.max.fill", .yellow, "자외선 강한 날", "선글라스와 선크림 챙기면 좋아요 😎")
        } else if temp >= 33 {
            return ("thermometer.high", .red, "매우 더운 날씨", "충분히 물 마시고, 그늘에 있어요 💧")
        } else {
            return ("sun.and.horizon.fill", .dvMorningGold, "내일 날씨 양호", "쾌적한 하루가 될 것 같아요 😊")
        }
    }

    var body: some View {
        let action = actionMessage
        HStack(spacing: 14) {
            Image(systemName: action.icon)
                .font(.system(size: 28))
                .foregroundColor(action.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(action.message)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(action.color.opacity(0.3), lineWidth: 1))
        )
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
