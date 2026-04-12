import SwiftUI

// Design Ref: §4.2 — Value-First 체험, 실제 말씀카드 + 배경이미지
// Plan SC: "이게 매일 내가 받을 것" 각인 → D1 리텐션 2~3배 향상 (Calm Value-first 패턴)

struct ONBExperienceView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    // 데모용 고정 말씀 (네트워크 불필요, 항상 즉시 표시)
    private let demoVerse: Verse = Verse.fallbackRiseIgnite

    @State private var cardAppeared = false

    var body: some View {
        ZStack {
            // 배경: 앱 Zone 이미지 또는 그라데이션 폴백
            backgroundLayer.ignoresSafeArea()

            // 오버레이 (배경 이미지 있을 때)
            LinearGradient(
                colors: [Color.black.opacity(0.20), Color.black.opacity(0.50)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 도트 아래 여유
                Spacer().frame(height: 80)

                // 시간대 인사 (데모 — 실제 앱과 동일 스타일, 상단 고정)
                HStack(spacing: 8) {
                    Image(systemName: AppMode.current().greetingIcon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    Text(AppMode.current().greeting)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)

                Spacer().frame(height: 32)

                // 말씀 카드 (메인 앱과 동일한 스타일 — VerseCardView와 동일하게 verseShortKo 사용)
                VStack(alignment: .leading, spacing: 14) {
                    Text(demoVerse.verseShortKo)
                        .font(.custom("Georgia-BoldItalic", size: 20))
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 2)

                    Text(demoVerse.reference)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.dvAccentGold)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.14))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.dvAccentGold.opacity(0.30), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 28)
                .scaleEffect(cardAppeared ? 1 : 0.92)
                .opacity(cardAppeared ? 1 : 0)

                Spacer().frame(height: 32)

                // 설명 문구
                VStack(spacing: 8) {
                    Text("✨ 매일 아침, 이 말씀이 알람과 함께 도착해요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.88))
                        .multilineTextAlignment(.center)

                    Text("알람은 이미 쓰고 있어요\n거기에 말씀만 얹는 거예요")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
                }
                .padding(.horizontal, 28)
                .opacity(cardAppeared ? 1 : 0)

                Spacer(minLength: 40)

                // CTA
                Button {
                    vm.next()
                } label: {
                    Text("이런 말씀을 받고 싶어요 →")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2340"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(cardAppeared ? 1 : 0)
                .accessibilityLabel("다음 단계로 이동")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                cardAppeared = true
            }
        }
    }

    // MARK: - 배경 레이어

    @ViewBuilder
    private var backgroundLayer: some View {
        if let bgImage = loadingCoordinator.zoneBgImage {
            GeometryReader { geo in
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        } else {
            // 폴백: 온보딩 그라데이션 (dark zone 색상 대신 밝은 그라데이션)
            LinearGradient(
                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    ONBExperienceView(vm: OnboardingViewModel())
        .environmentObject(AppLoadingCoordinator())
        .preferredColorScheme(.dark)
}
