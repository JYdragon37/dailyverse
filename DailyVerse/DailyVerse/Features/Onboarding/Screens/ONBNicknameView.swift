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
    @State private var showEditHint = false
    @State private var hintOffset: CGFloat = 8
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

                    // ── 편집 힌트 (주황 깜빡임 구간에만 노출) ──
                    if showEditHint {
                        HStack(spacing: 6) {
                            Text("✏️")
                                .font(.system(size: 13))
                            Text("탭해서 수정할 수 있어요")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.72))
                        }
                        .padding(.horizontal, 28)
                        .offset(y: hintOffset)
                        .transition(.opacity)
                    }
                }
                .opacity(inputOpacity)

                Spacer()
            }
        }
        // ── 하단 고정 CTA — 항상 활성 (미입력 시 "NY" 기본값으로 진행) ──
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Button {
                    if isAnimating {
                        // 애니메이션 중 탭 → NY로 고정
                        cancelAnimation()
                    } else if vm.nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        vm.nicknameInput = "NY"
                    }
                    vm.next()
                } label: {
                    Text("시작하기 →")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2340"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                        )
                }
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
            func sleep(_ ms: UInt64) async -> Bool {
                try? await Task.sleep(nanoseconds: ms * 1_000_000)
                return !Task.isCancelled
            }

            // ── Step 1: "뭐로 입력하지..??" → 전체 삭제 ──
            guard await sleep(900) else { return }
            for ch in "뭐로 입력하지..??" {
                guard !Task.isCancelled else { return }
                vm.nicknameInput.append(ch)
                guard await sleep(120) else { return }
            }
            guard await sleep(850) else { return }
            while !vm.nicknameInput.isEmpty {
                guard !Task.isCancelled else { return }
                vm.nicknameInput.removeLast()
                guard await sleep(72) else { return }
            }
            guard await sleep(320) else { return }

            // ── Step 2: "일단 나윤" → "나윤"(2자) 삭제 → "일단 " 삭제 → "" ──
            for ch in "일단 나윤" {
                guard !Task.isCancelled else { return }
                vm.nicknameInput.append(ch)
                guard await sleep(120) else { return }
            }
            guard await sleep(800) else { return }
            for _ in 0..<2 {   // "나윤" 2자 삭제 → "일단 " 남김
                guard !Task.isCancelled else { return }
                vm.nicknameInput.removeLast()
                guard await sleep(72) else { return }
            }
            guard await sleep(150) else { return }
            for _ in 0..<3 {   // "일단 " 3자 삭제 → "" 남김
                guard !Task.isCancelled else { return }
                vm.nicknameInput.removeLast()
                guard await sleep(72) else { return }
            }
            guard await sleep(220) else { return }

            // ── Step 3: "NY로 적어둘게요" 타이핑 → "로 적어둘게요" 삭제 → "NY" 남김 ──
            for ch in "NY로 적어둘게요" {
                guard !Task.isCancelled else { return }
                vm.nicknameInput.append(ch)
                guard await sleep(110) else { return }
            }
            guard await sleep(750) else { return }
            for _ in 0..<7 {   // "로 적어둘게요" 7자 삭제 → "NY" 남김
                guard !Task.isCancelled else { return }
                vm.nicknameInput.removeLast()
                guard await sleep(72) else { return }
            }
            guard await sleep(400) else { return }

            // ── Step 4: 주황 깜빡임 + 편집 힌트 ──
            isNYHighlighted = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                showEditHint = true
                hintOffset = 0
            }
            guard await sleep(2200) else { return }

            // ── Step 5: TextField 전환 ──
            withAnimation(.easeOut(duration: 0.18)) { showEditHint = false }
            guard await sleep(180) else { return }
            isNYHighlighted = false
            isAnimating = false
        }
    }

    private func cancelAnimation() {
        animationTask?.cancel()
        animationTask = nil
        isNYHighlighted = false
        showEditHint = false
        hintOffset = 8
        isAnimating = false
        // 유저가 직접 입력하지 않은 경우 항상 "NY"로 고정
        vm.nicknameInput = "NY"
    }
}

#Preview {
    ONBNicknameView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
