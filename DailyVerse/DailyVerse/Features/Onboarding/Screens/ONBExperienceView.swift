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

            // 다크 오버레이
            LinearGradient(
                colors: [Color.black.opacity(0.30), Color.black.opacity(0.60)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 시간대 인사 (데모 — 실제 앱과 동일 스타일)
                HStack(spacing: 8) {
                    Image(systemName: AppMode.current().greetingIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    Text("\(AppMode.current().greeting), 친구")
                        .font(.dvLargeTitle)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)

                Spacer().frame(height: 28)

                // 말씀 카드 (메인 앱과 동일한 스타일)
                VStack(alignment: .leading, spacing: 14) {
                    Text(demoVerse.verseFullKo)
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
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.dvAccentGold.opacity(0.25), lineWidth: 1)
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
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
                .opacity(cardAppeared ? 1 : 0)

                Spacer()

                // CTA
                Button {
                    vm.next()
                } label: {
                    Text("이런 말씀을 받고 싶어요 →")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.dvAccentGold)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
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
            Image(uiImage: bgImage)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            // 폴백: Zone 그라데이션
            LinearGradient(
                colors: AppMode.current().gradientColors,
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
