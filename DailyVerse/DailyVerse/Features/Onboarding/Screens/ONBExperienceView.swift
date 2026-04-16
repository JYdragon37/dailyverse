import SwiftUI

// Screen 2 — 알람 체험 시뮬레이션
// Stage 1 → Stage 2 (AlarmStage2 재현) → Stage 3 (해석 + 일상 적용)
// 배경: AppLoadingCoordinator.zoneBgImage
// 말씀: 시편 27:13-14

struct ONBExperienceView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    @State private var simPhase: SimPhase = .stage1
    @State private var isVisible: Bool = false
    @State private var badgeShake: CGFloat = 0
    @State private var stage2Visible: Bool = false
    @State private var stage3Visible: Bool = false
    @State private var messageVisible: Bool = false
    @State private var ctaVisible: Bool = false

    enum SimPhase {
        case stage1
        case stage2
        case stage3
    }

    // MARK: - 시뮬레이션 콘텐츠

    private let verseShort     = "내가 산 자들의 땅에서\n여호와의 선하심을 보게 될 것을 믿었도다"
    private let verseFull      = "내가 산 자들의 땅에서 여호와의 선하심을\n보게 될 것을 믿었도다.\n너는 여호와를 바라라, 강하고 담대하라,\n여호와를 바라라."
    private let reference      = "시편 27:13-14"
    private let interpretation = "다윗은 극심한 위협 속에서도 하나님의 선하심을 '믿었다'고 고백합니다. 두려움이 엄습할 때도 포기하지 않고 하나님을 바라보는 것, 그것이 담대함의 시작입니다."
    private let application    = "오늘 무겁게 느껴지는 순간이 찾아올 때, 잠시 멈추고 '여호와를 바라라'를 마음속으로 되뇌어보세요. 강함은 억지로 만드는 게 아니라 바라봄에서 자연스럽게 흘러옵니다."

    // MARK: - Body

    var body: some View {
        ZStack {
            stage1View
                .opacity(simPhase == .stage1 ? 1 : 0)
                .animation(.easeInOut(duration: 0.6), value: simPhase)

            stage2View
                .opacity(simPhase == .stage2 ? 1 : 0)
                .animation(.easeInOut(duration: 0.6).delay(0.1), value: simPhase)

            stage3View
                .opacity(simPhase == .stage3 ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: simPhase)
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomArea }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) { isVisible = true }
            // 배지 진동: 0.5s 후 시작, stage1에서만 반복
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.linear(duration: 0.055).repeatForever(autoreverses: true)) {
                    badgeShake = 4
                }
            }
        }
    }

    // MARK: - Stage 1 (AlarmStage1View 재현)

    private var stage1View: some View {
        ZStack {
            backgroundLayer
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── 상단: 알람 UI ──
                alarmTopBar
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.1), value: isVisible)

                // '오늘도 힘차게 일어나요!' 박스 아래 줄바꿈 2번 간격
                Spacer().frame(height: 44)

                // ── 말씀 — 알람 UI 바로 아래 ──
                VStack(spacing: 14) {
                    Text(verseShort)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                        .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

                    Text(reference)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }
                .opacity(isVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: isVisible)

                Spacer()
                Spacer().frame(height: 100)
            }
        }
    }

    // MARK: - 상단 알람 UI

    private var alarmTopBar: some View {
        VStack(spacing: 10) {
            // DailyVerse 앱 배지
            HStack(spacing: 6) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 11))
                Text("DailyVerse")
                    .font(.custom("DancingScript-Regular", size: 17))
            }
            .foregroundColor(.white.opacity(0.80))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 1))
            )
            // 진동 효과: 빠른 좌우 흔들림 + 미세 회전
            .offset(x: badgeShake)
            .rotationEffect(.degrees(Double(badgeShake) * 0.45))

            // 알람 시간
            Text("07:00")
                .font(.system(size: 68, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)

            // 날짜
            Text(alarmDateString)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.72))

            // 기상 독려 메시지
            HStack(spacing: 6) {
                Text("✝")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.88))
                Text("오늘도 힘차게 일어나요!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.88))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            )
        }
        .padding(.top, 100)
    }

    private var alarmDateString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일 EEEE"
        return df.string(from: Date())
    }

    // MARK: - Stage 2 (AlarmStage2View 재현 — 버튼 없이 ✕만)

    private var stage2View: some View {
        ZStack {
            backgroundLayer

            // 그라데이션 오버레이
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 200)
                Spacer()
                LinearGradient(colors: [.clear, Color.black.opacity(0.70)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 300)
            }
            .ignoresSafeArea()

            // 인사말 헤더
            VStack {
                greetingHeader
                    .padding(.top, 120)
                    .padding(.horizontal, 28)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 말씀 카드: 화면 중앙(50% 지점)에 배치
            GeometryReader { geo in
                let w = geo.size.width
                let hPad = max(w * 0.13, 40.0)
                verseCenter
                    .padding(.horizontal, hPad)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.50)
            }
        }
        .opacity(stage2Visible ? 1 : 0)
    }

    // MARK: - Stage 3 (해석 + 일상 적용)

    private var stage3View: some View {
        ZStack {
            // 배경: Stage 2와 동일 (backgroundLayer + 다크 오버레이)
            backgroundLayer
            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 175)

                    // 말씀 원문 (출처 위로 배치)
                    Text(verseFull)
                        .font(.custom("Georgia-BoldItalic", size: 18))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(6)
                        .padding(.horizontal, 28)

                    Spacer().frame(height: 12)

                    // 출처 — 원문 바로 아래
                    Text(reference)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dvAccentGold)
                        .padding(.horizontal, 28)

                    Spacer().frame(height: 32)

                    // 해석 섹션
                    contentSection(icon: "💡", title: "해석", body: interpretation)

                    Spacer().frame(height: 20)

                    // 일상 적용 섹션 — {name}, 으로 시작
                    contentSection(icon: "🌱", title: "일상 적용",
                                   body: "\(vm.nicknameDisplay), " + application)

                    Spacer().frame(height: 100)
                }
            }
        }
        .opacity(stage3Visible ? 1 : 0)
    }

    private func contentSection(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 28)

            Text(body)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.82))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
        }
    }

    // MARK: - 인사말 헤더

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(.top, 3)
                VStack(alignment: .leading, spacing: 3) {
                    Text("잘 잤어요?")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundColor(.white.opacity(0.88))
                    Text("힘차게 기지개 펴요, \(vm.nicknameDisplay)")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                }
            }
            HStack(spacing: 8) {
                Color.clear.frame(width: 34, height: 1)
                Text(todayString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Text("·").foregroundColor(.white.opacity(0.4))
                HStack(spacing: 5) {
                    Image(systemName: "sun.max.fill").font(.system(size: 15))
                    Text("서울 18°C · 맑음").font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.95))
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    // MARK: - 말씀 카드

    private var verseCenter: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verseFull)
                .font(.custom("Georgia-BoldItalic", size: 22))
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

            HStack(spacing: 8) {
                Text(reference)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Text("Hope")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.dvAccentGold)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.dvAccentGold.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.top, 18)

            // 말씀 깊게 보기 힌트
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 0.6)
                Text("말씀 깊게 보기")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.60))
                    .fixedSize()
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.60))
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 0.6)
            }
            .padding(.top, 14)
        }
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
    }

    // MARK: - 하단 버튼

    private var bottomArea: some View {
        Group {
            switch simPhase {
            case .stage1:
                VStack(spacing: 12) {
                    Button { transitionToStage2() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "alarm").accessibilityHidden(true)
                            Text("스누즈").font(.system(size: 17, weight: .medium))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white).cornerRadius(14)
                    }
                    Button { transitionToStage2() } label: {
                        Text("종료").font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.dvAccentGold)
                            .foregroundColor(.dvPrimaryDeep).cornerRadius(14)
                    }
                    .accessibilityLabel("알람 종료 후 말씀 화면으로")
                }
                .padding(.horizontal, 24).padding(.vertical, 12).padding(.bottom, 8)
                .opacity(isVisible ? 1 : 0)

            case .stage2:
                // 말씀 깊게 보기 → Stage 3으로
                Button { transitionToStage3() } label: {
                    HStack(spacing: 6) {
                        Text("말씀 깊게 보기")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.dvPrimaryDeep)
                        Image(systemName: "chevron.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.dvPrimaryDeep)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.dvAccentGold)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 8)
                .opacity(ctaVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: ctaVisible)

            case .stage3:
                Button { vm.next() } label: {
                    Text("다음 →")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.dvPrimaryDeep)
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.dvAccentGold))
                }
                .padding(.horizontal, 24).padding(.bottom, 20).padding(.top, 12)
                .opacity(stage3Visible ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: stage3Visible)
            }
        }
    }

    // MARK: - 배경

    @ViewBuilder
    private var backgroundLayer: some View {
        let bgImage = UIImage(named: "onb_alarm_bg") ?? loadingCoordinator.zoneBgImage
        if let img = bgImage {
            GeometryReader { geo in
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height).clipped()
            }
            .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - 전환

    private func transitionToStage2() {
        // 진동 멈춤
        withAnimation(.linear(duration: 0.1)) { badgeShake = 0 }
        withAnimation(.easeInOut(duration: 0.6)) { simPhase = .stage2 }
        withAnimation(.easeIn(duration: 0.5).delay(0.4)) { stage2Visible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.4)) { ctaVisible = true }
        }
    }

    private func transitionToStage3() {
        withAnimation(.easeInOut(duration: 0.5)) { simPhase = .stage3 }
        withAnimation(.easeIn(duration: 0.4).delay(0.2)) { stage3Visible = true }
    }

    // MARK: - Helpers

    private var todayString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "MMM d, EEE"
        return df.string(from: Date())
    }
}

#Preview {
    ONBExperienceView(vm: OnboardingViewModel())
        .environmentObject(AppLoadingCoordinator())
        .preferredColorScheme(.dark)
}
