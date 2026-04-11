import SwiftUI
import Combine

struct AlarmStage2View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator
    @EnvironmentObject private var authManager: AuthManager
    @State private var showLoginPrompt: Bool = false
    @State private var heartScale: CGFloat = 1.0
    @State private var isVisible: Bool = false
    @State private var showWordSheet: Bool = false
    @State private var todayVerse: Verse? = nil

    // 알람 발동 시간 기준 zone (현재 시간 아님)
    private var alarmMode: AppMode { coordinator.activeMode }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: Date())
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
            // 말씀 카드: 중앙보다 살짝 위, 가로 반응형 (HomeView와 동일)
            .overlay {
                if let verse = todayVerse {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let hPad = max(w * 0.13, 40.0)
                        verseCenter(verse: verse)
                            .padding(.horizontal, hPad)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .position(x: geo.size.width / 2,
                                      y: geo.size.height * 0.45)
                    }
                }
            }
            // 하단 버튼: safeAreaInset (HomeView 탭바 대체)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionBar
            }
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6)) { isVisible = true }
                // DailyCacheManager에서 오늘의 말씀 로드
                let mode = coordinator.activeMode
                if let id = DailyCacheManager.shared.getVerseId(for: mode),
                   let verse = DailyCacheManager.shared.loadCachedVerse(id: id) {
                    todayVerse = verse
                } else {
                    todayVerse = Verse.fallbackVerses.first { $0.mode.contains(mode.rawValue) }
                                 ?? Verse.fallbackRiseIgnite
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
            // 오늘의 한마디 시트
            .sheet(isPresented: $showWordSheet) {
                if let verse = todayVerse {
                    WordOfDaySheet(verse: verse, mode: alarmMode, userId: authManager.userId ?? "local") {
                        showWordSheet = false
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarHidden(true)
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
                Text(alarmMode.greeting)
                    .font(.dvLargeTitle)
                    .foregroundColor(.white)
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
                        Text("\(w.cityName) \(w.temperature)°C · 💧\(w.humidity)%")
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
                .font(.system(size: 21, weight: .semibold))
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

            // 오늘의 한마디 버튼 (반투명)
            Button { showWordSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 14))
                        .accessibilityHidden(true)
                    Text("오늘의 한마디")
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
            .accessibilityLabel("오늘의 한마디 보기")

            // 닫기 (x)
            Button { coordinator.dismissAll() } label: {
                Image(systemName: "xmark")
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
            locationName: coordinator.activeWeather?.cityName ?? ""
        )
        authManager.setPendingSave(savedVerse)
    }
}

// MARK: - 오늘의 한마디 시트 (text_ko 표시)

private struct WordOfDaySheet: View {
    let verse: Verse
    let mode: AppMode
    let userId: String
    let onDismiss: () -> Void

    @State private var inputText: String = ""

    var body: some View {
        ZStack {
            Color.dvPrimaryDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // 드래그 핸들
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 28)

                // 타이틀
                HStack(spacing: 8) {
                    Image(systemName: mode.greetingIcon)
                        .foregroundColor(mode.accentColor)
                    Text("오늘의 한마디")
                        .font(.dvUITitle)
                        .foregroundColor(mode.accentColor)
                }
                .padding(.bottom, 28)

                // 말씀 카드 (verse_short_ko)
                VStack(alignment: .center, spacing: 16) {
                    Text(verse.verseShortKo)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)

                    Text(verse.reference)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.60))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 24)
                .background(Color.white.opacity(0.07))
                .cornerRadius(18)
                .padding(.horizontal, 28)

                // 입력 필드
                TextField("오늘 한 마디를 남겨보세요...", text: $inputText, axis: .vertical)
                    .font(.dvBody)
                    .foregroundColor(.white)
                    .lineLimit(1...3)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .tint(.dvAccentGold)
                    .padding(.horizontal, 28)
                    .padding(.top, 20)

                Spacer()

                Button(action: handleDismiss) {
                    Text("닫기")
                        .font(.dvBody)
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func handleDismiss() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            Task {
                let repo = MeditationRepository()
                let item = PrayerItem.make(text: trimmed)
                let entry = MeditationEntry.make(
                    userId: userId,
                    verseId: verse.id,
                    verseReference: verse.reference,
                    mode: mode.rawValue,
                    prayerItems: [item],
                    gratitudeNote: nil,
                    source: "stage2"
                )
                try? await repo.save(entry)
                await MainActor.run { StreakManager.shared.recordMeditation() }
            }
        }
        onDismiss()
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
