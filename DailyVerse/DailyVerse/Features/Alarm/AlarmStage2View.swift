import SwiftUI
import Combine

struct AlarmStage2View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator
    @EnvironmentObject private var authManager: AuthManager
    @State private var showLoginPrompt: Bool = false
    @State private var heartScale: CGFloat = 1.0
    @State private var isVisible: Bool = false
    @State private var showWordSheet: Bool = false

    // 알람 발동 시간 기준 zone (현재 시간 아님)
    private var alarmMode: AppMode { coordinator.activeMode }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            backgroundView
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - 헤더: Zone 인사말 + 날짜
                headerSection
                    .padding(.top, 56)
                    .padding(.horizontal, 24)

                Spacer(minLength: 36)

                // MARK: - 메인 말씀 (text_full_ko)
                if let verse = coordinator.activeVerse {
                    verseSection(verse: verse)
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 36)

                // MARK: - 하단 액션 버튼
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.dvStageTransition) { isVisible = true }
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
        // 오늘의 한마디 시트 (text_ko 표시)
        .sheet(isPresented: $showWordSheet) {
            if let verse = coordinator.activeVerse {
                WordOfDaySheet(verse: verse, mode: alarmMode) {
                    showWordSheet = false
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
    }

    // MARK: - 배경

    @ViewBuilder
    private var backgroundView: some View {
        if let urlStr = coordinator.activeImage?.storageUrl,
           let url = URL(string: urlStr) {
            RemoteImageView(url: url) { fallbackGradient }
                .ignoresSafeArea()
        } else {
            fallbackGradient
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

    // MARK: - 헤더 섹션

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1행: 아이콘 + Zone 인사말
            HStack(spacing: 10) {
                Image(systemName: alarmMode.greetingIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(alarmMode.accentColor)
                Text(alarmMode.greeting)
                    .font(.dvTitle)
                    .foregroundColor(.white)
            }
            // 2행: 날짜 + 날씨 인라인 (홈화면 스타일)
            HStack(spacing: 8) {
                Text(todayString)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.72))

                if let w = coordinator.activeWeather {
                    Text("·")
                        .foregroundColor(.white.opacity(0.35))
                    HStack(spacing: 5) {
                        Image(systemName: weatherIcon(w.condition))
                            .font(.system(size: 14))
                        Text("\(w.cityName) \(w.temperature)°C")
                            .font(.system(size: 16, weight: .medium))
                        Text("·")
                            .foregroundColor(.white.opacity(0.35))
                        Text("\(w.humidity)%")
                            .font(.system(size: 15))
                    }
                    .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 2)
    }

    private func weatherIcon(_ condition: String) -> String {
        switch condition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "cloud.fill"
        }
    }

    // MARK: - 말씀 섹션 (text_full_ko)

    @ViewBuilder
    private func verseSection(verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // 전체 구절 텍스트 (text_full_ko)
            Text(verse.textFullKo)
                .font(.system(size: 21, weight: .regular))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.55), radius: 4, x: 0, y: 2)

            // 출처 + 테마 태그
            HStack(spacing: 10) {
                Text(verse.reference)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.80))

                if let firstTheme = verse.theme.first, firstTheme != "all" {
                    Text(firstTheme.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.dvVerseGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dvVerseGold.opacity(0.20))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - 액션 버튼

    private var actionButtons: some View {
        HStack(spacing: 10) {
            // 저장
            Button { handleSave() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .scaleEffect(heartScale)
                        .accessibilityHidden(true)
                    Text("저장")
                        .font(.dvBody)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.white.opacity(0.18))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .accessibilityLabel("말씀 저장하기")

            // 오늘의 한마디
            Button { showWordSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 14))
                        .accessibilityHidden(true)
                    Text("오늘의 한마디")
                        .font(.dvBody)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(alarmMode.accentColor.opacity(0.30))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .accessibilityLabel("오늘의 한마디 보기")

            // 닫기
            Button { coordinator.dismissAll() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.18))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .accessibilityLabel("닫기")
        }
    }

    // MARK: - 저장 액션

    private func handleSave() {
        guard let verse = coordinator.activeVerse else { return }
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
    let onDismiss: () -> Void

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

                // 말씀 카드 (text_ko, 잘림 없음)
                VStack(alignment: .center, spacing: 16) {
                    Text(verse.textKo)
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

                Spacer()

                Button(action: onDismiss) {
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
}

// MARK: - Preview

#Preview {
    let coordinator = AlarmCoordinator()
    coordinator.activeVerse = .fallbackMorning
    coordinator.activeWeather = .placeholder
    coordinator.activeMode = .riseIgnite

    return AlarmStage2View()
        .environmentObject(coordinator)
        .environmentObject(AuthManager())
}
