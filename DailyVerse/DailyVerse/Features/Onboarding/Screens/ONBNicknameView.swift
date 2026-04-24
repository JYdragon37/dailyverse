import SwiftUI

struct ONBNicknameView: View {
    @ObservedObject var vm: OnboardingViewModel
    @FocusState private var isFocused: Bool

    @State private var contentOpacity: Double = 0

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

                Spacer().frame(height: 52)

                // ── 입력 영역 ──
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Stranger", text: $vm.nicknameInput)
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
                            let maxLen = hasKorean ? 4 : 7
                            if newValue.count > maxLen {
                                vm.nicknameInput = String(newValue.prefix(maxLen))
                            }
                        }

                    Rectangle()
                        .fill(Color.white.opacity(isFocused ? 0.85 : 0.35))
                        .frame(height: 1)
                        .padding(.horizontal, 28)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)

                    // 수정 가능 힌트
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.55))
                        Text("탭해서 수정할 수 있어요")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 28)
                }
                .opacity(contentOpacity)

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Button {
                    if vm.nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        vm.nicknameInput = "Stranger"
                    }
                    vm.next()
                } label: {
                    Text("기상 알람 보기 →")
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
            withAnimation(.easeIn(duration: 0.5)) { contentOpacity = 1 }
            // 기본값 설정
            if vm.nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                vm.nicknameInput = "Stranger"
            }
        }
        .onTapGesture { isFocused = false }
    }
}

#Preview {
    ONBNicknameView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
