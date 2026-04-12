import SwiftUI

struct AuthWelcomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    let onSkip: () -> Void

    @State private var isLoadingGoogle = false
    @State private var isLoadingApple = false
    @State private var errorMessage: String?
    @State private var logoAppeared = false
    @State private var textAppeared = false
    @State private var buttonsAppeared = false

    private var isLoading: Bool { isLoadingGoogle || isLoadingApple }

    var body: some View {
        ZStack {
            // 배경: SplashView와 동일한 청록→파란보라→보라 그라데이션
            LinearGradient(
                colors: [
                    Color(red: 0.40, green: 0.82, blue: 0.86),
                    Color(red: 0.45, green: 0.62, blue: 0.88),
                    Color(red: 0.62, green: 0.45, blue: 0.85),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 56)

                // MARK: - 로고 영역
                logoSection
                    .opacity(logoAppeared ? 1 : 0)
                    .offset(y: logoAppeared ? 0 : 20)

                Spacer().frame(height: 32)

                // MARK: - 가치 선언
                valueSection
                    .opacity(textAppeared ? 1 : 0)
                    .offset(y: textAppeared ? 0 : 16)

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
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { textAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) { buttonsAppeared = true }
        }
    }

    // MARK: - 로고 섹션

    private var logoSection: some View {
        VStack(spacing: 16) {
            // 로그인 화면 — 아이콘 축소
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 10)

            Text("DailyVerse")
                .font(.custom("DancingScript-Regular", size: 40))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - 가치 선언 섹션

    private var valueSection: some View {
        VStack(spacing: 12) {
            Text("말씀과 함께 시작해요")
                .font(.dvTitle)
                .foregroundColor(.dvAccentGold)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 4)

            Text("알람이 울릴 때 말씀이 함께 옵니다")
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
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

            // Google 버튼 (주요)
            googleButton

            // Apple 버튼 (보조)
            appleButton

            // 로그인 없이 둘러보기
            Button(action: {
                onSkip()
            }) {
                Text("로그인 없이 둘러보기")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.55))
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
