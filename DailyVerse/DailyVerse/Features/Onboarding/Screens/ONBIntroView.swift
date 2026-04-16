import SwiftUI

// Screen 0 — 공감 화면 v5
// bg_first_light.jpg 배경 + 타이핑 스토리텔링
//
// 레이아웃 원칙:
// - outer ZStack에 ignoresSafeArea 없음 → safeAreaInset CTA 정상 동작
// - temp lines는 opacity만 0으로 (레이아웃 유지) → line3 위치 고정
// - 타이핑 속도 90ms

struct ONBIntroView: View {
    @ObservedObject var vm: OnboardingViewModel

    @State private var tempLine1: String = ""
    @State private var tempLine2: String = ""
    @State private var tempLinesOpacity: Double = 1

    @State private var line3: String = ""
    @State private var line4a: String = ""
    @State private var line4b: String = ""

    @State private var activeText: ActiveText = .none
    @State private var cursorVisible: Bool = true

    @State private var topLabelOpacity: Double = 0
    @State private var badgeVisible: Bool = false
    @State private var badgeOffset: CGFloat = 55
    @State private var ctaVisible: Bool = false
    @State private var animationDone: Bool = false
    @State private var animationTask: Task<Void, Never>? = nil

    enum ActiveText { case temp1, temp2, line3, line4a, line4b, none }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 배경 (ignoresSafeArea 개별 적용)
            backgroundImage
            LinearGradient(
                colors: [Color.black.opacity(0.18), Color.black.opacity(0.60)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // 메인 콘텐츠 VStack (safe area 내에서 동작)
            mainContent

            // 상단 레이블 오버레이 (완료 후 등장)
            topLabelOverlay
        }
        // outer ZStack에 ignoresSafeArea 없음 → badge가 CTA 위에 정확히 배치됨
        .safeAreaInset(edge: .bottom, spacing: 0) { ctaButton }
        .onAppear { startAnimation() }
        .onDisappear { animationTask?.cancel() }
        .onReceive(Timer.publish(every: 0.52, on: .main, in: .common).autoconnect()) { _ in
            if activeText != .none { cursorVisible.toggle() }
        }
        .contentShape(Rectangle())
        .onTapGesture { skipToEnd() }
    }

    // MARK: - 배경

    private var backgroundImage: some View {
        Group {
            if let img = UIImage(named: "onb_bg_first_light") {
                GeometryReader { geo in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
            } else {
                Color(red: 0.04, green: 0.06, blue: 0.16).ignoresSafeArea()
            }
        }
    }

    // MARK: - 메인 콘텐츠

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            textArea
                .padding(.horizontal, 32)

            Spacer()

            // Daily Verse 배지 — CTA 바로 위
            nytBadge
                .padding(.horizontal, 36)
                .offset(y: badgeOffset)
                .opacity(badgeVisible ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.78), value: badgeVisible)
                .animation(.spring(response: 0.65, dampingFraction: 0.78), value: badgeOffset)

            Spacer().frame(height: 24)
        }
    }

    // MARK: - 타이핑 텍스트 영역

    private var cursor: String { cursorVisible ? "|" : " " }

    private var textArea: some View {
        VStack(alignment: .leading, spacing: 8) {

            // 1번, 2번 — 레이아웃 유지하면서 opacity만 0으로 (line3 위치 고정)
            VStack(alignment: .leading, spacing: 6) {
                Text(tempLine1.isEmpty ? " " : tempLine1 + (activeText == .temp1 ? cursor : ""))
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(tempLine1.isEmpty ? 0 : 1)

                Text(tempLine2.isEmpty ? " " : tempLine2 + (activeText == .temp2 ? cursor : ""))
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(tempLine2.isEmpty ? 0 : 1)
            }
            .opacity(tempLinesOpacity)
            .animation(.easeOut(duration: 0.38), value: tempLinesOpacity)

            // 3번 (남음)
            if !line3.isEmpty || activeText == .line3 {
                Text(line3 + (activeText == .line3 ? cursor : ""))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white.opacity(0.90))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 4a (남음)
            if !line4a.isEmpty || activeText == .line4a {
                VStack(alignment: .leading, spacing: 4) {
                    Spacer().frame(height: 4)
                    Text(line4a + (activeText == .line4a ? cursor : ""))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // 4b (남음)
            if !line4b.isEmpty || activeText == .line4b {
                Text(line4b + (activeText == .line4b ? cursor : ""))
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: .black.opacity(0.70), radius: 8, x: 0, y: 2)
    }

    // MARK: - 상단 좌측 레이블 오버레이 (완료 후 등장, 화면 중하단)

    private var topLabelOverlay: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 310)  // 화면의 약 45~50% 지점
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("★★★★★")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                        .kerning(2)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(0.50))
                                .frame(height: 1.2)
                                .offset(y: -6)
                        }
                    Text("크리스천을 위한 최고의 알람 앱")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.white.opacity(0.75))
                        .kerning(0.5)
                }
                .padding(.leading, 32)
                Spacer()
            }
            Spacer()
        }
        .opacity(topLabelOpacity)
        .animation(.easeIn(duration: 0.5), value: topLabelOpacity)
    }

    // MARK: - NYT 배지

    private var nytBadge: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.40))
                .frame(height: 0.7)

            VStack(spacing: 5) {
                Text("크리스천을 위한 최고의 알람 앱")
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(.white.opacity(0.70))
                    .kerning(1.2)
                    .multilineTextAlignment(.center)

                // 앱 지정 필기체 폰트
                Text("DailyVerse")
                    .font(.custom("DancingScript-Regular", size: 26))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            Rectangle()
                .fill(Color.white.opacity(0.40))
                .frame(height: 0.7)
        }
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button { vm.next() } label: {
            Text("시작하기 →")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "#1A1030"))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color(hex: "#E8F0FF")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .padding(.top, 12)
        .opacity(ctaVisible ? 1 : 0)
        .animation(.easeIn(duration: 0.4), value: ctaVisible)
        .accessibilityLabel("온보딩 시작하기")
    }

    // MARK: - 애니메이션 (90ms 타이핑)

    private func startAnimation() {
        guard !animationDone else { return }

        animationTask = Task { @MainActor in
            func sleep(_ ms: UInt64) async -> Bool {
                try? await Task.sleep(nanoseconds: ms * 1_000_000)
                return !Task.isCancelled
            }

            guard await sleep(600) else { return }

            // ── 1번: 타이핑 후 유지 ──
            activeText = .temp1
            for ch in "매일 아침 시끄럽게 울리는 알람" {
                guard !Task.isCancelled else { return }
                tempLine1.append(ch)
                guard await sleep(90) else { return }
            }
            guard await sleep(400) else { return }

            // ── 2번: 줄바꿈 타이핑 후 유지 ──
            activeText = .temp2
            for ch in "겨우 겨우 억지로 끄기 바쁘시죠..?" {
                guard !Task.isCancelled else { return }
                tempLine2.append(ch)
                guard await sleep(90) else { return }
            }
            guard await sleep(450) else { return }

            // ── 3번 타이핑 시작 + 동시에 1,2번 fade-out ──
            // (3번은 1,2번 아래 위치 유지 — tempLines opacity만 변경, 레이아웃 유지)
            activeText = .line3
            withAnimation(.easeOut(duration: 0.40)) { tempLinesOpacity = 0 }

            for ch in "이제,\n이런 무의미한 알람 대신" {
                guard !Task.isCancelled else { return }
                line3.append(ch)
                guard await sleep(88) else { return }
            }
            guard await sleep(350) else { return }

            // ── 4a: 빈줄 후 "하나님의 말씀으로" ──
            activeText = .line4a
            for ch in "하나님의 말씀으로" {
                guard !Task.isCancelled else { return }
                line4a.append(ch)
                guard await sleep(88) else { return }
            }
            guard await sleep(280) else { return }

            // ── 4b: "하루를 경건하게 시작하세요!" ──
            activeText = .line4b
            for ch in "하루를 경건하게 시작하세요!" {
                guard !Task.isCancelled else { return }
                line4b.append(ch)
                guard await sleep(82) else { return }
            }
            activeText = .none
            guard await sleep(500) else { return }

            // ── 완료: 상단 레이블 + 배지 + CTA 순차 등장 ──
            withAnimation(.easeIn(duration: 0.5)) { topLabelOpacity = 1 }
            guard await sleep(320) else { return }

            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                badgeOffset = 0
                badgeVisible = true
            }
            guard await sleep(550) else { return }

            ctaVisible = true
            animationDone = true
        }
    }

    private func skipToEnd() {
        guard !animationDone else { return }
        animationTask?.cancel()
        animationTask = nil
        tempLinesOpacity = 0
        line3 = "이제,\n이런 무의미한 알람 대신"
        line4a = "하나님의 말씀으로"
        line4b = "하루를 경건하게 시작하세요!"
        activeText = .none
        withAnimation(.easeIn(duration: 0.3)) { topLabelOpacity = 1 }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
            badgeOffset = 0
            badgeVisible = true
        }
        ctaVisible = true
        animationDone = true
    }
}

#Preview {
    ONBIntroView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
