import SwiftUI

// MARK: - DevotionCompleteView
// 묵상 탭 Screen 3.5 — 완료 화면
// 진입 경로: 가이드 묵상 4단계 플로우(기도 입력) 완료 후 표시

struct DevotionCompleteView: View {

    // MARK: - Props

    let verse: Verse?
    let prayer: String
    @ObservedObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    // MARK: - Animation State

    @State private var emojiScale: CGFloat = 0.3
    @State private var emojiOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    // #13: StreakManager 직접 observe → recordMeditation() 후 currentStreak 즉시 반영
    @ObservedObject private var streakManager = StreakManager.shared
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    // C: 스트릭 7일 업셀 — 최초 1회만 표시
    @AppStorage("hasShownStreak7Upsell") private var hasShownStreak7Upsell = false
    @State private var showStreak7Upsell = false

    // MARK: - Share State

    @State private var showShareSheet: Bool = false
    @State private var shareImage: UIImage? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            // 배경
            Color.dvBgDeep
                .ignoresSafeArea()

            // 방사형 glow (✨ 이모지 주변)
            RadialGradient(
                colors: [
                    Color.dvAccentGold.opacity(glowOpacity),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.0).delay(0.1), value: glowOpacity)

            // 콘텐츠
            ScrollView {
                VStack(spacing: 32) {

                    Spacer(minLength: 40)

                    // 1. 완료 이모지 애니메이션
                    sparkleEmoji

                    // 2. 완료 메시지
                    completionMessage

                    // 3. 스트릭 카운터
                    streakCounter

                    // 4. 말씀 미니카드
                    verseCard
                        .opacity(cardOpacity)
                        .animation(.easeIn(duration: 0.4).delay(0.5), value: cardOpacity)

                    // 5. 액션 버튼
                    actionButtons

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            runEntryAnimations()
            // C: 스트릭 7일 달성 업셀 — 비프리미엄, 최초 1회만
            if !subscriptionManager.isPremium && !hasShownStreak7Upsell && streakManager.currentStreak == 7 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showStreak7Upsell = true
                    hasShownStreak7Upsell = true
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        // C: 스트릭 7일 업셀 시트
        .sheet(isPresented: $showStreak7Upsell) {
            Streak7UpsellSheet(isPresented: $showStreak7Upsell)
        }
    }

    // MARK: - 1. Sparkle Emoji

    private var sparkleEmoji: some View {
        Text("✨")
            .font(.system(size: 80))
            .scaleEffect(emojiScale)
            .opacity(emojiOpacity)
    }

    // MARK: - 2. Completion Message

    private var completionMessage: some View {
        Text(appLanguageString("meditation.completedMessage"))
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
    }

    // MARK: - 3. Streak Counter

    private var streakCounter: some View {
        Text(appLanguageString("meditation.streakCounter", args: streakManager.currentStreak))
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.dvAccentGold)
            .multilineTextAlignment(.center)
    }

    // MARK: - 4. Verse Mini Card

    private var verseCard: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if let verse = verse {
                Text(verse.verseShortKo)
                    .font(.custom("PretendardVariable", size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                Text("— \(verse.reference)")
                    .font(.dvReference)
                    .foregroundColor(.dvAccentGold)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dvBgSurface)
        )
    }

    // MARK: - 5. Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary: 공유 버튼
            Button {
                handleShare()
            } label: {
                HStack {
                    Spacer()
                    Text("📤 카드로 공유하기")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.dvAccentGold)
                )
            }
            .buttonStyle(.plain)

            // #14: 수정하기 — fullScreenCover 닫고 이전 화면으로 복귀
            Button {
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("✏️ 묵상 수정하기")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                }
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                )
            }
            .buttonStyle(.plain)

            // Secondary: 홈으로 돌아가기
            Button {
                // 묵상 NavStack 리셋 + 탭 전환 → dismiss 순서 보장
                NotificationCenter.default.post(name: .dvResetMeditationNav, object: nil)
                NotificationCenter.default.post(name: .dvSwitchToHomeTab, object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            } label: {
                HStack {
                    Spacer()
                    Text("🏠 홈으로 돌아가기")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Entry Animations

    private func runEntryAnimations() {
        // 1. ✨ 이모지 — spring 등장
        withAnimation(.spring(dampingFraction: 0.6).delay(0.1)) {
            emojiScale = 1.0
            emojiOpacity = 1.0
            glowOpacity = 0.15
        }
        // 2. 말씀 카드 fade-in
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            cardOpacity = 1
        }
        // 스트릭: @ObservedObject streakManager가 currentStreak 변화를 직접 반영
    }

    // MARK: - Share Handler

    private func handleShare() {
        let bgImage = loadingCoordinator.zoneBgImage
        let image = DevotionShareCardRenderer.render(verse: verse, backgroundImage: bgImage)
        shareImage = image
        showShareSheet = true
    }
}

// MARK: - C: 스트릭 7일 업셀 시트

private struct Streak7UpsellSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 28) {
            RoundedRectangle(cornerRadius: 2.5).fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5).padding(.top, 8)

            Text("🔥").font(.system(size: 56))

            VStack(spacing: 10) {
                Text("7일 연속 묵상 달성!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text(appLanguageString("meditation.premiumUpsell"))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 12) {
                Button {
                    // TODO: Premium 구매 플로우 연결
                    isPresented = false
                } label: {
                    Text("✨ Premium 시작하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Color.dvAccentGold).cornerRadius(14)
                }
                Button { isPresented = false } label: {
                    Text(appLanguageString("meditation.later"))
                        .font(.dvBody).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Preview

#Preview {
    DevotionCompleteView(
        verse: .fallbackRiseIgnite,
        prayer: "오늘 하루도 주님과 함께 걷게 하소서.",
        viewModel: MeditationViewModel()
    )
    .environmentObject(AuthManager())
    .environmentObject(SubscriptionManager())
    .environmentObject(UpsellManager())
    .environmentObject(AppLoadingCoordinator())
    .preferredColorScheme(.dark)
}
