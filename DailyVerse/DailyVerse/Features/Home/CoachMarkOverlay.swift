import SwiftUI

// MARK: - Feature Tour (신규 유저 첫 진입 시 주요 기능 안내)
// Step 1: 인사말 — 언어 변경 (프로필)
// Step 2: 날씨 탭 — 날씨 상세보기
// Step 3: 말씀 카드 — 말씀 깊게 보기

enum CoachMarkStep: Int {
    case greeting = 0
    case weather  = 1
    case verse    = 2
}

struct CoachMarkOverlay: View {

    @AppStorage("featureTourV2Shown") private var tourShown = false
    @State private var currentStep: CoachMarkStep = .greeting
    @State private var isVisible = true
    @State private var overlayOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if !tourShown && isVisible {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // 스텝별 하이라이트 프레임 (safe area 59pt + greetingHeader padding 60pt 반영)
                let greetingRect = CGRect(x: 16, y: 118, width: w - 32, height: 82)
                let weatherRect  = CGRect(x: 50, y: 225, width: w * 0.72, height: 28)
                let verseRect    = CGRect(x: max(w * 0.13, 36), y: h * 0.34,
                                         width: w - 2 * max(w * 0.13, 36), height: h * 0.22)

                let target: CGRect = {
                    switch currentStep {
                    case .greeting: return greetingRect
                    case .weather:  return weatherRect
                    case .verse:    return verseRect
                    }
                }()

                ZStack {
                    // ── 스포트라이트 오버레이 ──
                    spotlightCanvas(target: target, size: geo.size)

                    // ── 하이라이트 테두리 + 펄스 ──
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: target.width + 10, height: target.height + 10)
                        .position(x: target.midX, y: target.midY)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: pulseScale
                        )

                    // ── 툴팁 ──
                    tooltip(for: currentStep, target: target, screenWidth: w, screenHeight: h)
                }
                .opacity(overlayOpacity)
                .animation(.easeIn(duration: 0.35), value: overlayOpacity)
            }
            .ignoresSafeArea()
            .onAppear {
                overlayOpacity = 1
                pulseScale = 1.06
            }
        }
    }

    // MARK: - Canvas 스포트라이트

    private func spotlightCanvas(target: CGRect, size: CGSize) -> some View {
        Canvas { ctx, _ in
            // 어두운 오버레이
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.72)))
            // 스포트라이트 컷아웃 (ctx 직접 수정)
            ctx.blendMode = .destinationOut
            ctx.fill(
                Path(roundedRect: target.insetBy(dx: -5, dy: -5), cornerRadius: 10),
                with: .color(.black)
            )
        }
        .compositingGroup()
        .ignoresSafeArea()
    }

    // MARK: - 툴팁 버블

    private func tooltip(for step: CoachMarkStep,
                         target: CGRect,
                         screenWidth: CGFloat,
                         screenHeight: CGFloat) -> some View {

        let isAbove = target.midY > screenHeight * 0.45
        let tooltipY = isAbove
            ? target.minY - 130
            : target.maxY + 90

        let (icon, title, desc): (String, String, String) = {
            switch step {
            case .greeting:
                return ("🌐", "언어를 바꿀 수 있어요",
                        "프로필 탭에서 인사말 언어를\nKorean / English로 변경할 수 있어요")
            case .weather:
                return ("🌤️", "날씨를 탭해보세요",
                        "날씨를 누르면 상세 정보와\n시간대별 예보를 확인할 수 있어요")
            case .verse:
                return ("📖", "말씀을 탭해보세요",
                        "'말씀 깊게 보기'를 누르면\n해석과 일상 적용까지 볼 수 있어요")
            }
        }()

        return VStack(spacing: 0) {
            // 화살표
            if !isAbove {
                arrowUp
                    .padding(.leading, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 버블
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(icon).font(.system(size: 20))
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.15))
                }

                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.32))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    // 스텝 도트
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i == step.rawValue
                                      ? Color(red: 0.97, green: 0.65, blue: 0.15)
                                      : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    Spacer()
                    // 다음 / 완료
                    Button(action: advance) {
                        Text(step == .verse ? "완료" : "다음 →")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color(red: 0.97, green: 0.65, blue: 0.15))
                            )
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.97))
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
            )

            if isAbove {
                arrowDown
                    .padding(.leading, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: screenWidth - 48)
        .position(x: screenWidth / 2, y: tooltipY)
    }

    private var arrowUp: some View {
        Triangle(pointingUp: true)
            .fill(Color(red: 0.10, green: 0.12, blue: 0.20).opacity(0.95))
            .frame(width: 16, height: 9)
    }

    private var arrowDown: some View {
        Triangle(pointingUp: false)
            .fill(Color(red: 0.10, green: 0.12, blue: 0.20).opacity(0.95))
            .frame(width: 16, height: 9)
    }

    // MARK: - 액션

    private func advance() {
        withAnimation(.easeOut(duration: 0.25)) { overlayOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 280_000_000)
            let next = currentStep.rawValue + 1
            if let nextStep = CoachMarkStep(rawValue: next) {
                currentStep = nextStep
                withAnimation(.easeIn(duration: 0.3)) { overlayOpacity = 1 }
            } else {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) { isVisible = false }
        tourShown = true
    }
}

// MARK: - 삼각형

private struct Triangle: Shape {
    let pointingUp: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if pointingUp {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.6), .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        CoachMarkOverlay()
    }
}
