import SwiftUI

// MARK: - SplashView v3.2
// Changes vs v3.1:
//   1. Gradient: 4-stop, inline-matched to reference (cleaner blue, more purple lavender, warmer coral)
//   2. NeonBar: tighter bloom — narrower outer frame, lower blur radius, brighter core contrast
//   3. ArchGlassFrame: thinner fill + thinner stroke, shadow radius reduced
//   4. Wordmark: 12pt closer to arch, opacity 0.72 → 0.84
//   5. Bar colors: more vivid cyan/pink to match reference precisely

struct SplashView: View {

    @State private var phase1 = false
    @State private var phase2 = false
    @State private var phase3 = false
    @State private var glowing = false
    @State private var glowTask: Task<Void, Never>? = nil

    private let archWidthRatio: CGFloat = 0.62
    private let archMaxWidth:   CGFloat = 268
    private let archAspect:     CGFloat = 1.42
    private let compositionY:   CGFloat = 0.43

    var body: some View {
        GeometryReader { geo in
            let archW = min(geo.size.width * archWidthRatio, archMaxWidth)
            let archH = archW * archAspect
            let logoY = geo.size.height * compositionY

            ZStack {
                // ── 배경 그라데이션 (4-stop, 참조 이미지 색상 직접 매칭) ──
                LinearGradient(
                    stops: [
                        // 상단: 맑은 스카이 블루
                        .init(color: Color(red: 0.553, green: 0.780, blue: 0.918), location: 0.00),
                        // 중상단: 깨끗한 라벤더 (더 보라색)
                        .init(color: Color(red: 0.749, green: 0.686, blue: 0.863), location: 0.42),
                        // 중하단: 모브 핑크 전환
                        .init(color: Color(red: 0.831, green: 0.694, blue: 0.761), location: 0.72),
                        // 하단: 따뜻한 산호/살몬
                        .init(color: Color(red: 0.937, green: 0.722, blue: 0.682), location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // ── 로고 컴포지션 ──────────────────────────────────
                ZStack {
                    // Phase 2: 아치 프레임
                    ArchGlassFrame()
                        .frame(width: archW, height: archH)
                        .opacity(phase2 ? 1 : 0)
                        .scaleEffect(phase2 ? 1.0 : 0.97)
                        .animation(.easeOut(duration: 0.50), value: phase2)

                    // Phase 1: 십자가
                    CrossLogo(
                        size: CGSize(width: archW * 0.80, height: archH * 0.73),
                        glowing: glowing
                    )
                    .opacity(phase1 ? 1 : 0)
                    .offset(y: phase1 ? 0 : 10)
                    .animation(.easeOut(duration: 0.55), value: phase1)
                }
                .frame(width: archW, height: archH)
                .position(x: geo.size.width / 2, y: logoY)

                // ── Phase 3: 워드마크 (아치에 12pt 더 가깝게, opacity 올림) ──
                Text("morning manna")
                    .tracking(5)
                    .font(.custom("PretendardVariable", size: 14).weight(.light))
                    .foregroundStyle(Color.white.opacity(0.84))
                    .opacity(phase3 ? 1 : 0)
                    .animation(.easeOut(duration: 0.40), value: phase3)
                    .position(
                        x: geo.size.width / 2,
                        y: logoY + archH * 0.5 + 16   // 28 → 16
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.async { runAnimation() }
        }
        .onDisappear { glowTask?.cancel() }
    }

    private func runAnimation() {
        phase1 = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { phase2 = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) { phase3 = true }
        glowTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowing = true
            }
        }
    }
}

// MARK: - Arch Shape

private struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.width / 2
        let cr: CGFloat = 10
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + cr, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - cr),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY + r),
            radius: r, startAngle: .degrees(180), endAngle: .degrees(0),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cr))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - cr, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        p.addLine(to: CGPoint(x: rect.minX + cr, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Arch Glass Frame
// 참조 이미지: 배경이 완전히 비치는 투명 유리 + 얇고 오팔빛 테두리

private struct ArchGlassFrame: View {
    var body: some View {
        ZStack {
            // 극도로 얇은 흰 틴트 (배경 그라데이션이 그대로 투과)
            ArchShape()
                .fill(Color.white.opacity(0.07))

            // 오팔빛 테두리: 상단 밝고 하단으로 자연스럽게 소멸
            ArchShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.78),
                            Color.white.opacity(0.42),
                            Color.white.opacity(0.14),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        }
        .shadow(color: Color.white.opacity(0.12), radius: 10, x: 0, y: 0)
    }
}

// MARK: - Cross Logo

private struct CrossLogo: View {
    let size: CGSize
    let glowing: Bool

    // 참조 이미지 매칭: 더 채도 높은 teal-cyan, 더 선명한 rose-pink
    private let cyan = Color(red: 0.435, green: 0.800, blue: 0.910)  // #6FCDE8 vivid teal
    private let pink = Color(red: 0.925, green: 0.565, blue: 0.682)  // #EC90AE vivid rose

    var body: some View {
        let W = size.width
        let H = size.height
        let t: CGFloat = 5.5

        ZStack {
            // Bar 1: 메인 세로 (white core, cyan glow)
            NeonBar(core: .white, glow: cyan, w: t, h: H * 0.70, lit: glowing)
                .offset(x: -W * 0.05, y: -H * 0.02)

            // Bar 2: 보조 세로 (pink)
            NeonBar(core: pink, glow: pink, w: t, h: H * 0.41, lit: glowing)
                .offset(x: W * 0.07, y: H * 0.14)

            // Bar 3: 메인 가로 우측 (cyan)
            NeonBar(core: cyan, glow: cyan, w: W * 0.48, h: t, lit: glowing)
                .offset(x: W * 0.23, y: -H * 0.07)

            // Bar 4: 보조 가로 좌측 (pink)
            NeonBar(core: pink, glow: pink, w: W * 0.43, h: t, lit: glowing)
                .offset(x: -W * 0.24, y: H * 0.12)

            // 교차점 블룸 (screen — 강한 흰 빛)
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .blur(radius: glowing ? 11 : 9)
                .opacity(glowing ? 1.0 : 0.88)
                .blendMode(.screen)
                .offset(x: -W * 0.05, y: -H * 0.07)
        }
        .frame(width: W, height: H)
    }
}

// MARK: - Neon Bar
// 핵심 원칙:
//   - 글로우 레이어만 .screen (additive bloom)
//   - 코어는 .normal → 색상 채도 유지 (screen이 코어 색상을 세탁하는 문제 방지)

private struct NeonBar: View {
    let core: Color
    let glow: Color
    let w: CGFloat
    let h: CGFloat
    let lit: Bool

    var body: some View {
        ZStack {
            // 글로우 레이어 (screen blend — 가산 발광)
            ZStack {
                // 외부 와이드 블룸
                RoundedRectangle(cornerRadius: 3)
                    .fill(glow.opacity(lit ? 0.44 : 0.32))
                    .frame(width: w + 18, height: h + 18)
                    .blur(radius: 8)

                // 내부 타이트 블룸
                RoundedRectangle(cornerRadius: 3)
                    .fill(glow.opacity(lit ? 0.72 : 0.56))
                    .frame(width: w + 5, height: h + 5)
                    .blur(radius: 2.5)
            }
            .blendMode(.screen)

            // 코어 바 (normal blend — 선명한 색상 유지)
            RoundedRectangle(cornerRadius: 3)
                .fill(core)
                .frame(width: w, height: h)
        }
    }
}

// MARK: - Preview

#Preview("iPhone 17 Pro") {
    SplashView()
        .frame(width: 393, height: 852)
}

#Preview("iPhone SE") {
    SplashView()
        .frame(width: 375, height: 667)
}
