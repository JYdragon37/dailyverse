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
    @State private var heartScale: CGFloat = 1.0
    @State private var isVisible: Bool = true   // AlarmKit 콜드런치 대응: 처음부터 visible
    @State private var showVerseDetail: Bool = false
    @State private var todayVerse: Verse? = nil
    @State private var toastMessage: String? = nil

    // 알람 발동 시간 기준 zone (현재 시간 아님)
    private var alarmMode: AppMode { coordinator.activeMode }

    private var todayString: String {
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

    /// greeting + 닉네임 조합 — greeting이 구두점으로 끝나면 쉼표 없이 공백만 추가
    /// Design Ref: §7-2 — greetingService 우선, 비어있으면 AppMode 폴백
    private var greetingText: String {
        let g = greetingService.currentGreeting.isEmpty
            ? alarmMode.greeting
            : greetingService.currentGreeting
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
            // 말씀 카드: 화면 중앙(48% 지점)에 배치
            .overlay {
                if let verse = todayVerse {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let hPad = max(w * 0.13, 40.0)
                        verseCenter(verse: verse)
                            .padding(.horizontal, hPad)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .position(x: geo.size.width / 2,
                                      y: geo.size.height * 0.53)
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
                // Design Ref: §7-2 — Zone 진입 시 greeting 로드
                let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
                await greetingService.load(for: alarmMode, language: lang)
            }
            .onAppear {
                // coordinator.activeVerse 우선 사용 — 홈화면과 동일 verse 보장
                // (handleAlarmKitStop → loadVerse로 로드된 것, 홈화면과 같은 DailyCacheManager 경로)
                if let verse = coordinator.activeVerse {
                    todayVerse = verse
                } else {
                    // 폴백: DailyCacheManager에서 직접 로드
                    let mode = coordinator.activeMode
                    if let id = DailyCacheManager.shared.getVerseId(for: mode),
                       let verse = DailyCacheManager.shared.loadCachedVerse(id: id) {
                        todayVerse = verse
                    } else {
                        todayVerse = Verse.fallbackVerses.first { $0.mode.contains(mode.rawValue) }
                                     ?? Verse.fallbackRiseIgnite
                    }
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
                        onClose: { showVerseDetail = false }
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
        VStack(alignment: .leading, spacing: 6) {
            // 1행: 아이콘 + Zone 인사말
            HStack(spacing: 8) {
                Image(systemName: alarmMode.greetingIcon)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                // Design Ref: §7-2 — greetingText: greetingService 우선 + 닉네임 조합
                Text(greetingText)
                    .font(.dvLargeTitle)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
            }

            // 2행: 날짜 · 날씨 인라인 (아이콘 너비 들여쓰기 맞춤)
            HStack(spacing: 8) {
                Color.clear.frame(width: 34, height: 1) // 아이콘+spacing 들여쓰기

                Text(todayString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                if let w = coordinator.activeWeather {
                    Text("·").foregroundColor(.white.opacity(0.4))
                    HStack(spacing: 5) {
                        Image(systemName: weatherIcon(w.condition))
                            .font(.system(size: 15))
                        HStack(spacing: 3) {
                            Text("\(w.cityName) \(w.temperature)°C ·")
                            Image(systemName: "drop.fill")
                                .font(.system(size: 12))
                            Text("\(w.humidity)%")
                        }
                        .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.95))
                }
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    // MARK: - Verse Center (HomeView verseCenter와 동일 스타일)

    private func verseCenter(verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 말씀 텍스트 (verseFullKo)
            Text(verse.verseFullKo)
                .font(.custom("Georgia-BoldItalic", size: 22))
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

            // 성경 참조 + 테마 태그
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
            }
            .padding(.top, 18)
        }
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
    }

    // MARK: - Action Bar (safeAreaInset)

    private var actionBar: some View {
        HStack(spacing: 12) {
            // 저장 버튼 (꽉 채움, dvGold 배경)
            Button { handleSave() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .scaleEffect(heartScale)
                        .accessibilityHidden(true)
                    Text("저장")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.dvGold, Color.dvGold.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .accessibilityLabel("말씀 저장하기")

            // 말씀 더보기 버튼 — 해석 + 일상 적용 바텀시트
            Button { showVerseDetail = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 14))
                        .accessibilityHidden(true)
                    Text("말씀 더보기")
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            .accessibilityLabel("말씀 해석과 일상 적용 보기")

            // 알람 종료 — 사운드 중지 + Stage2 닫기
            Button { coordinator.dismissAll() } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white.opacity(0.7))
            }
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .padding(.bottom, 8)
        .background(
            Color.dvBgDeep.opacity(0.85)
                .overlay(Rectangle().fill(.ultraThinMaterial))
        )
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
