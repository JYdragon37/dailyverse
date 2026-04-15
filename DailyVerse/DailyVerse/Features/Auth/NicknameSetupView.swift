import SwiftUI

struct NicknameSetupView: View {
    let onComplete: () -> Void

    @EnvironmentObject private var authManager: AuthManager
    @FocusState private var isFocused: Bool
    @State private var nickname: String = ""
    @State private var isSaving: Bool = false

    // MARK: - 유효성

    /// 한글 포함 여부 (가~힣 범위)
    private var isKorean: Bool {
        nickname.unicodeScalars.contains { $0.value >= 0xAC00 && $0.value <= 0xD7A3 }
    }

    private var maxLength: Int { isKorean ? 5 : 8 }

    private var isValid: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && nickname.count <= maxLength
    }

    private var hintText: String {
        "한글 5자 / 영어·숫자 8자 이내 · \(nickname.count)/\(maxLength)"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.dvBgDeep
                .ignoresSafeArea()
                .hideKeyboardOnTap()

            VStack(spacing: 0) {
                Spacer()

                // 이모지
                Text("🙏")
                    .font(.system(size: 48))

                Spacer().frame(height: 20)

                // 타이틀
                Text("어떻게 불러드릴까요?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 8)

                // 서브타이틀
                Text("함께 말씀을 묵상할 이름을 알려주세요")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 48)

                // MARK: - 닉네임 입력 필드
                VStack(spacing: 8) {
                    TextField("닉네임", text: $nickname)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .accentColor(.dvAccentGold)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            guard isValid else { return }
                            Task { await save() }
                        }
                        .onChange(of: nickname) { newValue in
                            // 한글/영문 구분 후 최대 길이 초과 시 자동 트림
                            if newValue.count > maxLength {
                                nickname = String(newValue.prefix(maxLength))
                            }
                        }
                        .padding(.vertical, 12)

                    // 아래 경계선
                    Rectangle()
                        .fill(isFocused ? Color.dvAccentGold : Color.white.opacity(0.25))
                        .frame(height: 1.5)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 12)

                // 힌트 텍스트
                Text(hintText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.40))
                    .multilineTextAlignment(.center)

                Spacer()

                // MARK: - 버튼 영역
                VStack(spacing: 4) {
                    // 시작하기 버튼
                    Button {
                        guard isValid && !isSaving else { return }
                        Task { await save() }
                    } label: {
                        ZStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("시작하기")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(isValid ? .white : .white.opacity(0.4))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            isValid
                                ? Color.dvAccentGold
                                : Color.dvAccentGold.opacity(0.25)
                        )
                        .cornerRadius(16)
                    }
                    .disabled(!isValid || isSaving)
                    .animation(.easeInOut(duration: 0.2), value: isValid)

                    // 나중에 버튼
                    Button {
                        onComplete()
                    } label: {
                        Text("나중에")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            // 화면 진입 시 키보드 자동 포커스
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }

    // MARK: - 저장 로직

    private func save() async {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onComplete()
            return
        }
        isSaving = true
        await NicknameManager.shared.setNickname(trimmed, userId: authManager.userId)
        isSaving = false
        onComplete()
    }
}

// MARK: - Preview

#Preview {
    NicknameSetupView(onComplete: {})
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
