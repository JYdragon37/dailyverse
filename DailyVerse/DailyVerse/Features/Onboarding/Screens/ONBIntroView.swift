import SwiftUI

// Design Ref: 레퍼런스 스크린 — 청록→라벤더 그라데이션, AppLogo 아이콘, 커시브 타이틀, 흰색 pill CTA

struct ONBIntroView: View {
    @ObservedObject var vm: OnboardingViewModel

    @State private var contentOpacity: Double = 0
    @State private var ctaOpacity: Double = 0

    // 온보딩 전용 배경 그라데이션
    private let bgGradient = LinearGradient(
        colors: [
            Color(hex: "#4EC4B0"),  // 청록
            Color(hex: "#7A9AD0"),  // 페리윙클
            Color(hex: "#9080CC")   // 라벤더
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // ── 브랜드 블록 ──────────────────────────────
                VStack(spacing: 20) {
                    // 앱 아이콘 (그라데이션 컨테이너 + AppLogo)
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#5AC8C0"), Color(hex: "#9878D0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 108, height: 108)
                            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)

                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                    }

                    // 앱 이름 (커시브 스크립트)
                    Text("DailyVerse")
                        .font(.custom("DancingScript-Regular", size: 50))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

                    // 태그라인
                    VStack(spacing: 6) {
                        Text("하루의 끝과 시작을")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("경건하게")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.dvAccentGold)
                    }

                    // 서브카피
                    Text("알람이 울릴 때 말씀이 함께 옵니다")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.65))
                }
                .opacity(contentOpacity)

                Spacer(minLength: 0)
            }
        }
        // CTA: safeAreaInset으로 home indicator 위에 자동 배치
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                vm.next()
            } label: {
                Text("시작하기")
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
            .padding(.top, 12)
            .opacity(ctaOpacity)
            .accessibilityLabel("온보딩 시작하기")
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                contentOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.6).delay(1.0)) {
                ctaOpacity = 1
            }
        }
    }
}

#Preview {
    ONBIntroView(vm: OnboardingViewModel())
}
