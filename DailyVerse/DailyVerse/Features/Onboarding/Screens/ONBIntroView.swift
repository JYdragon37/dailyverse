import SwiftUI

// Design Ref: §4.1 — 감성 인트로, dvBgDeep + 파티클 + fade-in 시퀀스
// Plan SC: 브랜드 각인 + 감정 훅 → "나를 위한 앱" 느낌

struct ONBIntroView: View {
    @ObservedObject var vm: OnboardingViewModel

    @State private var logoOpacity: Double = 0
    @State private var subCopyOpacity: Double = 0
    @State private var ctaOpacity: Double = 0
    @State private var particleAnimate = false

    var body: some View {
        ZStack {
            // 배경
            Color.dvBgDeep.ignoresSafeArea()

            // 파티클 레이어 (Canvas 기반 별빛)
            ONBParticleView(animate: particleAnimate)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 콘텐츠
            VStack(spacing: 0) {
                Spacer()

                // 로고 + 타이틀 영역
                VStack(spacing: 14) {
                    // 로고 (브랜드 심볼 — 십자가+태양 모티프)
                    ZStack {
                        Circle()
                            .fill(Color.dvAccentGold.opacity(0.15))
                            .frame(width: 96, height: 96)
                        Image(systemName: "sun.and.horizon.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.dvAccentGold, Color.dvAccentGold.opacity(0.7)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    }

                    Text("DailyVerse")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(.white)

                    Text("하루의 끝과 시작을 경건하게")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }
                .opacity(logoOpacity)

                Spacer().frame(height: 48)

                // 서브카피 — 핵심 가치 한 줄
                VStack(spacing: 6) {
                    Text("알람이 울릴 때,")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.dvAccentGold)
                    Text("말씀이 함께 울립니다")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.dvAccentGold)
                }
                .opacity(subCopyOpacity)

                Spacer()

                // CTA 버튼
                Button {
                    vm.next()
                } label: {
                    Text("시작하기")
                        .font(.system(size: 18, weight: .semibold))
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
                .opacity(ctaOpacity)
                .accessibilityLabel("온보딩 시작하기")
            }
        }
        .onAppear {
            runEntryAnimations()
        }
    }

    // MARK: - 애니메이션 시퀀스

    private func runEntryAnimations() {
        // 파티클 시작
        withAnimation(.easeIn(duration: 1.0)) {
            particleAnimate = true
        }
        // 1. 로고 fade-in
        withAnimation(.easeIn(duration: 0.8)) {
            logoOpacity = 1
        }
        // 2. 서브카피 (0.7s 딜레이)
        withAnimation(.easeIn(duration: 0.6).delay(0.7)) {
            subCopyOpacity = 1
        }
        // 3. CTA (1.3s 딜레이)
        withAnimation(.easeIn(duration: 0.5).delay(1.3)) {
            ctaOpacity = 1
        }
    }
}

// MARK: - 파티클 뷰 (Canvas 기반 별빛)

private struct ONBParticleView: View {
    let animate: Bool

    // 파티클 데이터 (위치, 크기, opacity, 주기 고정)
    private struct Particle {
        let x: CGFloat    // 0~1 비율
        let y: CGFloat
        let size: CGFloat // 2~5pt
        let duration: Double
        let delay: Double
    }

    private let particles: [Particle] = (0..<15).map { _ in
        Particle(
            x: CGFloat.random(in: 0.05...0.95),
            y: CGFloat.random(in: 0.05...0.85),
            size: CGFloat.random(in: 2...4.5),
            duration: Double.random(in: 3...6),
            delay: Double.random(in: 0...3)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles.indices, id: \.self) { i in
                let p = particles[i]
                Circle()
                    .fill(Color.white.opacity(animate ? Double.random(in: 0.2...0.55) : 0))
                    .frame(width: p.size, height: p.size)
                    .position(
                        x: p.x * geo.size.width,
                        y: p.y * geo.size.height
                    )
                    .animation(
                        .easeInOut(duration: p.duration)
                            .repeatForever(autoreverses: true)
                            .delay(p.delay),
                        value: animate
                    )
            }
        }
    }
}

#Preview {
    ONBIntroView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
