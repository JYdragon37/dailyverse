import SwiftUI
import Combine

struct AlarmStage2View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var greetingService: GreetingService
    @ObservedObject private var nicknameManager = NicknameManager.shared
    // Design Ref: §7-2 — 언어 설정 읽기
    @AppStorage("greetingLanguage") private var greetingLanguagePref: String = "random"
    @State private var showLoginPrompt: Bool = false
    @State private var isSavedCurrentVerse: Bool = false
    @State private var heartScale: CGFloat = 1.0
    @State private var isVisible: Bool = true   // AlarmKit 콜드런치 대응: 처음부터 visible
    @State private var showVerseDetail: Bool = false
    @State private var cachedFallbackVerse: Verse? = nil  // coordinator.activeVerse nil일 때만 사용
    @State private var toastMessage: String? = nil

    /// 항상 coordinator.activeVerse 우선 — reactive하게 홈화면과 동일 말씀 보장
    private var todayVerse: Verse? { coordinator.activeVerse ?? cachedFallbackVerse }

    // 알람 발동 시간 기준 zone (현재 시간 아님)
    private var alarmMode: AppMode { coordinator.activeMode }

    /// 날짜만 (M월 d일 EEE) — HomeView와 동일 분리 구조
    private var alarmDateString: String {
        let isKorean = greetingLanguagePref == "ko"
        let df = DateFormatter()
        df.locale = Locale(identifier: isKorean ? "ko_KR" : "en_US")
        df.dateFormat = isKorean ? "M월 d일 EEE" : "MMM d, EEE"
        return df.string(from: Date())
    }

    /// 시간만 (h:mm a)
    private var alarmTimeString: String {
        let tf = DateFormatter()
        tf.locale = Locale(identifier: "en_US_POSIX")
        tf.dateFormat = "h:mm a"
        return tf.string(from: Date())
    }

    /// 알람 전용 인사말 + 닉네임 — alarm_greetings 컬렉션 우선, 없으면 AppMode.alarmGreeting 폴백
    private var greetingText: String {
        let g = greetingService.currentAlarmGreeting.isEmpty
            ? (greetingLanguagePref == "ko" ? alarmMode.alarmGreetingKr : alarmMode.alarmGreetingEn)
            : greetingService.currentAlarmGreeting
        let name = nicknameManager.nickname
        let lastChar = g.last
        if lastChar == "." || lastChar == "!" || lastChar == "?" || lastChar == "," {
            return "\(g) \(name)"
        }
        return "\(g), \(name)"
    }

    var body: some View {
        backgroundView
            .overlay { gradientOverlay }
            // 인사말: 상단 고정 (HomeView와 동일)
            .overlay(alignment: .topLeading) {
                greetingHeader
                    .padding(.top, 60)
                    .padding(.horizontal, 28)
            }
            // 말씀 카드: 화면 50% 상단 고정 (헤더에 로고+시간 포함으로 HomeView보다 낮게)
            .overlay {
                if let verse = todayVerse {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let hPad = max(w * 0.13, 40.0)
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height: geo.size.height * 0.50)
                            // ScrollView: 긴 말씀이 액션 버튼 영역을 침범할 때 스크롤로 보완
                            // 하단 Spacer(110pt)로 [스누즈/일어나기] 버튼 항상 노출 보장
                            ScrollView(.vertical, showsIndicators: false) {
                                verseCenter(verse: verse)
                                    .padding(.horizontal, hPad)
                                    .padding(.bottom, 16)
                            }
                            Spacer().frame(height: 110) // 액션바(~90pt) + 여백 확보
                        }
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                    }
                }
            }
            // 하단 버튼: safeAreaInset (HomeView 탭바 대체)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionBar
            }
            .opacity(isVisible ? 1 : 0)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // 백그라운드에서 세팅된 경우: 포그라운드 복귀 시 즉시 표시 (애니메이션 없이)
                if !isVisible { isVisible = true }
            }
            .task {
                let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
                // 알람 전용 인사말 로드 (alarm_greetings 컬렉션)
                await greetingService.loadAlarmGreeting(for: alarmMode, language: lang)
            }
            .onAppear {
                // coordinator.activeVerse는 computed property로 reactive하게 반영됨
                // DailyCacheManager에 캐시된 말씀이 있으면 activeVerse 로드 완료 전까지 임시 표시
                // Core Data miss 시: cachedFallbackVerse = nil → 말씀 영역 빈 화면 유지
                //                  → coordinator.activeVerse 세팅 후 reactive 업데이트
                // 하드코딩 폴백(fallbackRecharge 등) 절대 사용 안 함 — 홈화면과 다른 말씀 노출 방지
                if coordinator.activeVerse == nil {
                    let mode = coordinator.activeMode
                    if let id = DailyCacheManager.shared.getVerseId(for: mode),
                       let verse = DailyCacheManager.shared.loadCachedVerse(id: id) {
                        cachedFallbackVerse = verse
                    }
                    // Core Data miss → cachedFallbackVerse 그대로 nil 유지
                }
            }
            // 로그인 유도 시트
            .sheet(isPresented: $showLoginPrompt) {
                LoginPromptSheet {
                    showLoginPrompt = false
                    Task { await authManager.signIn() }
                } onDismiss: {
                    showLoginPrompt = false
                }
            }
            // 말씀 더보기 시트 (해석 + 일상 적용)
            .sheet(isPresented: $showVerseDetail) {
                if let verse = todayVerse {
                    VerseDetailBottomSheet(
                        verse: verse,
                        onSave: { handleSave() },
                        onMeditation: { showVerseDetail = false },
                        onClose: { showVerseDetail = false },
                        showMeditationButton: false,
                        isSaved: $isSavedCurrentVerse
                    )
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarHidden(true)
            // 저장 성공/실패 토스트
            .overlay(alignment: .bottom) {
                if let message = toastMessage {
                    ToastView(message: message)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: toastMessage)
                }
            }
    }

    // MARK: - Background (HomeView와 동일한 구조)

    @ViewBuilder
    private var backgroundView: some View {
        Color.clear
            .ignoresSafeArea()
            .background {
                Group {
                    if let urlStr = coordinator.activeImage?.storageUrl,
                       let url = URL(string: urlStr) {
                        RemoteImageView(url: url) { fallbackGradient }
                    } else {
                        fallbackGradient
                    }
                }
                .ignoresSafeArea()
            }
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: alarmMode.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Gradient Overlay (HomeView와 동일)

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

    // MARK: - Greeting Header (HomeView greetingHeader와 동일 스타일)

    private var greetingHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            // 좌측: mm 브랜드 로고 이미지
            Image("LogoMMColor")
                .resizable()
                .scaledToFit()
                .frame(width: 64)
                .opacity(0.90)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                .padding(.leading, 4)
                .padding(.top, 4)

            // 우측: 인사말 / 날짜+날씨 / 시간 — 모두 같은 수직선
            VStack(alignment: .leading, spacing: 6) {
                // 1행: 인사말
                Text(greetingText)
                    .font(.dvLargeTitle)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)

                // 2행: 날짜·요일 + 위치·온도
                HStack(spacing: 8) {
                    Text(alarmDateString)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))

                    if let w = coordinator.activeWeather {
                        Text("·").foregroundColor(.white.opacity(0.35))
                        HStack(spacing: 4) {
                            Image(systemName: weatherIcon(w.condition))
                                .font(.system(size: 13))
                            Text("\((w.cityName.components(separatedBy: " ").first ?? w.cityName)) \(w.temperature)°C")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.75))
                    }
                }

                // 3행: 시간 — 크고 굵게
                Text(alarmTimeString)
                    .font(.system(size: 52, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .padding(.top, 2)
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    // MARK: - Verse Center (HomeView verseCenter와 동일 스타일)

    private func verseCenter(verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 말씀 텍스트 (verseFullKo)
            Text(verse.verseFullKo)
                .font(.custom("PretendardVariable", size: 22).weight(.semibold))
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

            // 성경 참조
            Text(verse.reference)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)

            // 말씀 깊게 보기 힌트 (HomeView와 동일 스타일)
            Button { showVerseDetail = true } label: {
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
            }
            .padding(.top, 12)
            .accessibilityLabel("말씀 해석과 일상 적용 보기")
        }
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
    }

    // MARK: - Action Bar (safeAreaInset)

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // 스누즈
                Button {
                    coordinator.snooze()
                } label: {
                    VStack(spacing: 2) {
                        Text("🌙  스누즈")
                            .font(.system(size: 15, weight: .medium))
                        Text("\(coordinator.activeSnoozeInterval)분 후")
                            .font(.system(size: 11, weight: .regular))
                            .opacity(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(coordinator.canSnooze ? 0.10 : 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(coordinator.canSnooze ? 0.18 : 0.08), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white.opacity(coordinator.canSnooze ? 1.0 : 0.35))
                }
                .disabled(!coordinator.canSnooze)
                .accessibilityLabel(coordinator.canSnooze ? "\(coordinator.activeSnoozeInterval)분 스누즈" : "스누즈 횟수 초과")

                // 일어나기
                Button { coordinator.dismissAll() } label: {
                    Text("☀️  일어나기")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.dvAccentGold.opacity(0.20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.dvAccentGold.opacity(0.45), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.dvAccentGold)
                }
                .accessibilityLabel("알람 종료")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func weatherIcon(_ condition: String) -> String {
        switch condition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "cloud.fill"
        }
    }

    // MARK: - Save Action

    private func handleSave() {
        guard let verse = todayVerse else { return }
        guard authManager.isLoggedIn else {
            showLoginPrompt = true
            return
        }
        withAnimation(.dvHeartPulse) { heartScale = 1.4 }
        withAnimation(.dvHeartPulse.delay(0.15)) { heartScale = 1.0 }

        let savedVerse = SavedVerse(
            id: UUID().uuidString,
            verseId: verse.id,
            imageId: coordinator.activeImage?.id,
            imageUrl: coordinator.activeImage?.storageUrl,
            savedAt: Date(),
            mode: alarmMode.rawValue,
            weatherTemp: coordinator.activeWeather?.temperature ?? 0,
            weatherCondition: coordinator.activeWeather?.condition ?? "any",
            weatherHumidity: coordinator.activeWeather?.humidity ?? 0,
            weatherDust: coordinator.activeWeather?.dustGrade,
            locationName: coordinator.activeWeather?.cityName ?? "",
            verseFullKo: verse.verseFullKo,
            source: .alarm                          // v5.2: 알람 탭(Stage 2)에서 저장
        )
        // 로그인 상태 → Firestore 직접 저장 (성공/실패 토스트 피드백)
        Task {
            guard let uid = authManager.userId else { return }
            do {
                try await FirestoreService().saveVerse(savedVerse, userId: uid)
                showToast("말씀이 저장되었습니다")
            } catch {
                showToast("저장에 실패했습니다. 다시 시도해주세요")
            }
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            toastMessage = nil
        }
    }
}

// MARK: - Preview

#Preview {
    let coordinator = AlarmCoordinator()
    coordinator.activeWeather = .placeholder
    coordinator.activeMode = .riseIgnite

    return AlarmStage2View()
        .environmentObject(coordinator)
        .environmentObject(AuthManager())
}
