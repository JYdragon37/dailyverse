import SwiftUI

// Design Ref: §3 — 2장 Zone 체험, Zone4(peakMode) + Zone1(deepDark)
// Plan SC: SC-03~SC-06 말씀·인사말·배너 반영

struct ONBExperienceView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    @State private var selectedCard: Int = 0

    // 카드별 등장 애니메이션
    @State private var card1Appeared = false
    @State private var card2Appeared = false

    @State private var currentTimeString: String = ""
    @State private var currentDateString: String = ""

    var body: some View {
        ZStack {
            TabView(selection: $selectedCard) {
                zone4Card.tag(0)
                zone1Card.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        // ── 하단 고정: 내부 도트 + CTA ──
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 14) {
                // 카드 도트 (• •)
                HStack(spacing: 6) {
                    ForEach(0..<2) { i in
                        Capsule()
                            .fill(selectedCard == i ? Color.white : Color.white.opacity(0.40))
                            .frame(width: selectedCard == i ? 16 : 6, height: 4)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedCard)
                    }
                }

                // CTA (카드별 다른 텍스트)
                Button {
                    if selectedCard == 0 {
                        withAnimation(.easeInOut(duration: 0.4)) { selectedCard = 1 }
                    } else {
                        vm.next()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(selectedCard == 0 ? "멋진 배경과 함께 말씀 선물 받기" : "꾸준한 묵상 습관 만들기")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: selectedCard == 0 ? "gift.fill" : "figure.mind.and.body")
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .accessibilityLabel(selectedCard == 0 ? "다음 카드 보기" : "다음 단계로 이동")
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .onChange(of: selectedCard) { card in
            if card == 1 && !card2Appeared {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
                    card2Appeared = true
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                card1Appeared = true
            }
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            currentTimeString = f.string(from: Date())
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentTimeString = f.string(from: Date())
            }
            let df = DateFormatter()
            df.locale = Locale(identifier: "ko_KR")
            df.dateFormat = "M월 d일"
            currentDateString = df.string(from: Date())
        }
    }

    // MARK: - Card 1: Zone4 (peakMode) — v_086

    private var zone4Card: some View {
        ZStack {
            // 배경: 현재 Zone 이미지 (peakMode 시간대에 프리로드된 이미지)
            zone4Background.ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.20), Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // 인사말 (Zone4: peakMode)
                greetingRow(mode: .riseIgnite)

                Spacer().frame(height: 6)

                // 시간 + 장소 + 날씨
                HStack(spacing: 4) {
                    Color.clear.frame(width: 26, height: 1)
                    Text("\(currentDateString)  ·  08:00  ·  Seoul  18°C")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)

                Spacer().frame(height: 28)

                // v_086 말씀 카드
                verseCard(
                    text: "내가 산 자들의 땅에서 여호와의 선하심을\n보게 될 것을 믿었도다.\n너는 여호와를 바라라, 강하고 담대하라,\n여호와를 바라라.",
                    reference: "시편 27:13-14",
                    appeared: card1Appeared
                )

                Spacer().frame(height: 48)

                // 배너
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                    Text("매일 아침, 하나님 말씀으로 하루를 시작하세요")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                )
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }

    // MARK: - Card 2: Zone7 (goldenHour) — v_009

    private var zone1Card: some View {
        ZStack {
            // 배경: windDown(Zone8) 전용 배경 이미지
            if let bgImage = loadingCoordinator.windDownBgImage {
                GeometryReader { geo in
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#C9622F"), Color(hex: "#7A4A8A"), Color(hex: "#2D2060")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            // 오버레이
            Color.black.opacity(0.40).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // 인사말 (Zone7: goldenHour — 닉네임 포함)
                greetingRow(mode: .goldenHour)

                Spacer().frame(height: 6)

                // 시간 + 장소 + 날씨
                HStack(spacing: 4) {
                    Color.clear.frame(width: 26, height: 1)
                    Text("\(currentDateString)  ·  22:00  ·  Seoul  18°C")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                    Image(systemName: "moon.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)

                Spacer().frame(height: 64)

                // v_009 말씀 카드
                verseCard(
                    text: "내가 새벽 날개를 치며 바다 끝에 거할지라도\n거기서도 주의 손이 나를 인도하시며\n주의 오른손이 나를 붙드시리이다.",
                    reference: "시편 139:9-10",
                    appeared: card2Appeared
                )

                Spacer().frame(height: 64)

                // 배너 (첫번째 장과 동일한 Capsule 스타일)
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                    Text("매일 빠짐없는 묵상에 도움줄게요!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                )
                .padding(.horizontal, 20)
                .opacity(card2Appeared ? 1 : 0)

                Spacer()
            }
        }
    }

    // MARK: - 공통 컴포넌트

    @ViewBuilder
    private func greetingRow(mode: AppMode) -> some View {
        HStack(spacing: 8) {
            Image(systemName: mode.greetingIcon)
                .font(.system(size: 18))
                .foregroundColor(.white)
            Text(greetingText(for: mode))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func verseCard(text: String, reference: String, appeared: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text)
                .font(.custom("Georgia-BoldItalic", size: 20))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 2)

            Text(reference)
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
        .padding(.horizontal, 20)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - 헬퍼

    /// zone 인사말 + 닉네임 조합 (트레일링 구두점 처리)
    private func greetingText(for mode: AppMode) -> String {
        let g = mode.greeting
        let name = vm.nicknameDisplay
        let last = g.last
        if last == "." || last == "!" || last == "?" || last == "," {
            return "\(g) \(name)"
        }
        return "\(g), \(name)"
    }

    // MARK: - Zone4 배경 레이어

    @ViewBuilder
    private var zone4Background: some View {
        if let bgImage = loadingCoordinator.zone4BgImage {
            GeometryReader { geo in
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        } else {
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
