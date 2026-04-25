import SwiftUI

struct AuthWelcomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    let onSkip: () -> Void

    @State private var isLoadingGoogle = false
    @State private var isLoadingApple = false
    @State private var errorMessage: String?
    @State private var logoAppeared = false
    @State private var buttonsAppeared = false

    private var isLoading: Bool { isLoadingGoogle || isLoadingApple }

    var body: some View {
        ZStack {
            // 배경: 새벽 숲 사진
            GeometryReader { geo in
                Image("AuthWelcomeBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // 상단→하단 다크 오버레이 (텍스트 가독성)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.30),
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.55),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - 로고 + 태그라인 (중앙 그룹)
                logoSection
                    .opacity(logoAppeared ? 1 : 0)
                    .offset(y: logoAppeared ? 0 : 20)

                Spacer()

                // MARK: - 버튼 영역
                buttonSection
                    .opacity(buttonsAppeared ? 1 : 0)
                    .offset(y: buttonsAppeared ? 0 : 24)

                // MARK: - 이용약관
                termsSection
                    .opacity(buttonsAppeared ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { logoAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { buttonsAppeared = true }
        }
    }

    // MARK: - 로고 섹션

    private var logoSection: some View {
        VStack(spacing: 0) {
            // 로고 + "Wake with the Word" 타이트하게 묶음
            // LogoMM 이미지는 1024×1024이지만 실제 콘텐츠는 중앙 16% → 음수 패딩으로 여백 제거
            VStack(spacing: 8) {
                Image("LogoMMColor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .opacity(0.92)
                    .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 10)
                    // LogoMMColor는 1024×1024이나 실제 mm 콘텐츠는 중앙 16% → 하단 투명 여백 ~67pt 제거
                    .padding(.bottom, -62)

                Text("Wake with the Word")
                    .font(.dvSubtitle)
                    .foregroundColor(.white.opacity(0.80))
                    .shadow(color: .black.opacity(0.30), radius: 3, x: 0, y: 1)
            }

            Spacer().frame(height: 44)

            VStack(spacing: 4) {
                Text("하나님 말씀으로")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("하루를 맞이할 준비 되셨나요?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.40), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - 버튼 섹션

    private var buttonSection: some View {
        VStack(spacing: 12) {
            // 에러 메시지
            if let error = errorMessage {
                Text(error)
                    .font(.dvCaption)
                    .foregroundColor(Color(hex: "#FF6B6B"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }

            // Apple로 시작하기 (신규→가입, 기존→로그인 자동)
            appleButton

            // Google로 시작하기 (신규→가입, 기존→로그인 자동)
            googleButton

            // 로그인 없이 둘러보기 — 텍스트 링크
            Button(action: { onSkip() }) {
                Text("로그인 없이 둘러보기")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.vertical, 12)
            }
        }
    }

    private var googleButton: some View {
        Button {
            guard !isLoading else { return }
            Task {
                isLoadingGoogle = true
                errorMessage = nil
                await authManager.signInWithGoogle()
                if let err = authManager.authError {
                    withAnimation { errorMessage = err }
                }
                isLoadingGoogle = false
            }
        } label: {
            HStack(spacing: 10) {
                if isLoadingGoogle {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .frame(width: 20, height: 20)
                } else {
                    Text("G")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#4285F4"))
                        .frame(width: 20)
                }
                Text("Google로 시작하기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(14)
        }
        .disabled(isLoading)
        .opacity(isLoading && !isLoadingGoogle ? 0.6 : 1)
    }

    private var appleButton: some View {
        Button {
            guard !isLoading else { return }
            Task {
                isLoadingApple = true
                errorMessage = nil
                await authManager.signIn()
                if let err = authManager.errorMessage {
                    withAnimation { errorMessage = err }
                }
                isLoadingApple = false
            }
        } label: {
            HStack(spacing: 10) {
                if isLoadingApple {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20)
                }
                Text("Apple로 시작하기")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(Color.dvBgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .disabled(isLoading)
        .opacity(isLoading && !isLoadingApple ? 0.6 : 1)
    }

    // MARK: - 이용약관 섹션

    private var termsSection: some View {
        Text("시작하면 이용약관 및 개인정보처리방침에 동의하게 됩니다")
            .font(.dvCaption)
            .foregroundColor(.white.opacity(0.25))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .padding(.bottom, 8)
    }
}

#Preview {
    AuthWelcomeView(onSkip: {})
        .environmentObject(AuthManager())
}
