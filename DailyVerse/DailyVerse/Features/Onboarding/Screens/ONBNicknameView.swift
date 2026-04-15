import SwiftUI

// Design Ref: §2 — 닉네임 단독 페이지, 타이핑 애니메이션으로 입력 유도
// Plan SC: SC-01 타이핑 시퀀스 / SC-02 인터럽트 즉시 중단

struct ONBNicknameView: View {
    @ObservedObject var vm: OnboardingViewModel
    @FocusState private var isFocused: Bool

    @State private var titleOpacity: Double = 0
    @State private var inputOpacity: Double = 0
    @State private var isAnimating = true
    @State private var cursorVisible = true
    @State private var isNYHighlighted = false
    @State private var animationTask: Task<Void, Never>? = nil
    @State private var didStart = false  // 중복 실행 방지

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .hideKeyboardOnTap()

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                // ── 타이틀 ──
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("처음 오셨군요!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.97, green: 0.67, blue: 0.28))
                    }
                    Spacer().frame(height: 4)
                    Text("매일 어떻게")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("불러드릴까요?")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .opacity(titleOpacity)

                Spacer().frame(height: 52)

                // ── 입력 영역 ──
                VStack(alignment: .leading, spacing: 12) {
                    if isAnimating {
                        // 애니메이션 중: Text + 깜빡이는 커서
                        HStack(spacing: 1) {
                            Text(vm.nicknameInput.isEmpty ? " " : vm.nicknameInput)
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(
                                    isNYHighlighted
                                    ? Color(red: 0.97, green: 0.67, blue: 0.28).opacity(cursorVisible ? 1.0 : 0.35)
                                    : .white
                                )
                            if !isNYHighlighted {
                                Text(cursorVisible ? "|" : " ")
                                    .font(.system(size: 38, weight: .light))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            cancelAnimation()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isFocused = true
                            }
                        }
                    } else {
                        // 애니메이션 완료: 실제 TextField
                        TextField("NY", text: $vm.nicknameInput)
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                            .tint(.dvAccentGold)
                            .focused($isFocused)
                            .padding(.horizontal, 28)
                            .onChange(of: vm.nicknameInput) { newValue in
                                let hasKorean = newValue.unicodeScalars.contains {
                                    ($0.value >= 0xAC00 && $0.value <= 0xD7A3) ||
                                    ($0.value >= 0x3131 && $0.value <= 0x318E)
                                }
                                let maxLen = hasKorean ? 4 : 6
                                if newValue.count > maxLen {
                                    vm.nicknameInput = String(newValue.prefix(maxLen))
                                }
                            }
                    }

                    // 하단 구분선
                    Rectangle()
                        .fill(Color.white.opacity(isFocused ? 0.85 : 0.35))
                        .frame(height: 1)
                        .padding(.horizontal, 28)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                .opacity(inputOpacity)

                Spacer()
            }
        }
        // ── 하단 고정 CTA ──
        .safeAreaInset(edge: .bottom, spacing: 0) {
            let isNicknameEmpty = vm.nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            VStack(spacing: 0) {
                if isNicknameEmpty {
                    Text("이름을 입력해야 계속할 수 있어요")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 8)
                }
                Button {
                    guard !isNicknameEmpty else { return }
                    vm.next()
                } label: {
                    Text("시작하기 →")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isNicknameEmpty ? Color(hex: "#1A2340").opacity(0.4) : Color(hex: "#1A2340"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isNicknameEmpty ? Color.white.opacity(0.4) : Color.white)
                        )
                }
                .disabled(isNicknameEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .padding(.top, 12)
            .accessibilityLabel("이름 입력 완료, 다음으로")
        }
        .onAppear {
            // nearPage로 미리 렌더링되므로 onAppear 단독 사용 금지
            // currentPage 감시로 실제 진입 시점에만 시작
        }
        .onChange(of: vm.currentPage) { page in
            if page == 1 && !didStart {
                didStart = true
                withAnimation(.easeIn(duration: 0.6)) { titleOpacity = 1 }
                withAnimation(.easeIn(duration: 0.5).delay(0.4)) { inputOpacity = 1 }
                startAnimation()
            }
        }
        .onTapGesture {
            isFocused = false
        }
        .onDisappear {
            animationTask?.cancel()
        }
        // 커서 깜빡임
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // nearPage로 미리 렌더링되므로 currentPage 조건 필수 — 비활성 페이지에서 타이머 낭비 방지
            if isAnimating && vm.currentPage == 1 { cursorVisible.toggle() }
        }
    }

    // MARK: - 타이핑 애니메이션

    private func startAnimation() {
        vm.nicknameInput = ""

        animationTask = Task { @MainActor in
            // sleep helper: 취소 시 false 반환
            func sleep(_ ms: UInt64) async -> Bool {
                try? await Task.sleep(nanoseconds: ms * 1_000_000)
                return !Task.isCancelled
            }

            guard await sleep(900) else { return }

            let words = ["뭐로 입력하지..??", "내 이름은 ", "나윤", "NY"]
            for (i, word) in words.enumerated() {
                // 타이핑
                for ch in word {
                    guard !Task.isCancelled else { return }
                    vm.nicknameInput.append(ch)
                    guard await sleep(130) else { return }
                }

                // 마지막 단어(NY)는 지우지 않음
                guard i < words.count - 1 else { break }

                // 정지 후 백스페이스
                guard await sleep(800) else { return }
                while !vm.nicknameInput.isEmpty {
                    guard !Task.isCancelled else { return }
                    vm.nicknameInput.removeLast()
                    guard await sleep(75) else { return }
                }
                guard await sleep(300) else { return }
            }

            // NY 입력 완료 → 주황 깜빡임으로 유저에게 안내
            isNYHighlighted = true
            guard await sleep(1800) else { return }

            // 완료 — TextField 전환
            isNYHighlighted = false
            isAnimating = false
        }
    }

    private func cancelAnimation() {
        animationTask?.cancel()
        animationTask = nil
        isNYHighlighted = false
        isAnimating = false
        if vm.nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            vm.nicknameInput = "NY"
        }
    }
}

#Preview {
    ONBNicknameView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
