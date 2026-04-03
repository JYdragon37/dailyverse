import SwiftUI

// v5.1 — 온보딩 Screen 2: 닉네임 입력
// "우리 어떻게 불러드릴까요?" + 텍스트 필드 (최대 10자)
// 미입력 시 "친구"로 기본 저장

struct OnboardingNicknameView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [Color.dvPrimaryDeep, Color.dvPrimaryMid],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 타이틀
                VStack(spacing: 16) {
                    Text("👋")
                        .font(.system(size: 60))

                    Text("우리 어떻게 불러드릴까요?")
                        .font(.dvLargeTitle)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("이름을 알면 더 따뜻하게 인사할 수 있어요")
                        .font(.dvBody)
                        .foregroundColor(.dvTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // 닉네임 입력 필드
                VStack(spacing: 8) {
                    TextField("친구", text: $viewModel.nicknameInput)
                        .font(.system(size: 22, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isFocused ? Color.dvAccentGold : Color.white.opacity(0.2), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 40)
                        .focused($isFocused)
                        .onChange(of: viewModel.nicknameInput) { newVal in
                            if newVal.count > 10 {
                                viewModel.nicknameInput = String(newVal.prefix(10))
                            }
                        }
                        .submitLabel(.done)
                        .onSubmit { handleNext() }

                    // 미리보기
                    if !viewModel.nicknameInput.isEmpty {
                        Text("\"Good Morning, \(viewModel.nicknameInput) ☀️\"")
                            .font(.dvCaption)
                            .foregroundColor(.dvAccentSoft)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        Text("미입력 시 \"친구\"로 저장됩니다")
                            .font(.dvCaption)
                            .foregroundColor(.dvTextMuted)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: viewModel.nicknameInput.isEmpty)

                Spacer()

                // 다음 버튼
                VStack(spacing: 12) {
                    Button(action: handleNext) {
                        Text("다음 →")
                            .font(.dvUISubtitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.dvAccentGold)
                            .foregroundColor(.dvPrimaryDeep)
                            .cornerRadius(16)
                    }
                    .dvButtonEffect()
                    .padding(.horizontal, 32)

                    Button("나중에") {
                        viewModel.nicknameInput = ""
                        viewModel.next()
                    }
                    .font(.dvCaption)
                    .foregroundColor(.dvTextMuted)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { isFocused = true }
    }

    private func handleNext() {
        viewModel.saveNickname()
        viewModel.next()
    }
}

#Preview {
    OnboardingNicknameView(viewModel: OnboardingViewModel())
}
