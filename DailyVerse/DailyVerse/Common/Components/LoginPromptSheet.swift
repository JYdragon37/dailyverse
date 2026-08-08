import SwiftUI
import Combine

struct LoginPromptSheet: View {
    let onLogin: () -> Void
    let onDismiss: () -> Void
    var message: String = appLanguageString("loginPrompt.message")
    var icon: String = "bookmark.fill"

    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        VStack(spacing: 24) {
            // 핸들
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // 아이콘
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.dvAccent)

            VStack(spacing: 8) {
                Text(message)
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)

                Text(appLanguageString("loginPrompt.subtitle"))
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                // Apple 로그인 — 흰 배경 + 검정 텍스트 (항상 명확하게 보임)
                Button(action: onLogin) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 16, weight: .semibold))
                        Text(appLanguageString("auth.welcome.startWithApple"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .cornerRadius(12)
                }
                .accessibilityLabel(appLanguageString("loginPrompt.appleAccessibility"))

                // Google 로그인
                Button {
                    Task { await authManager.signInWithGoogle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .medium))
                        Text(appLanguageString("auth.welcome.startWithGoogle"))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .accessibilityLabel(appLanguageString("loginPrompt.googleAccessibility"))

                Button(action: onDismiss) {
                    Text(appLanguageString("meditation.later"))
                        .font(.dvBody)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(appLanguageString("loginPrompt.skipAccessibility"))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            LoginPromptSheet(onLogin: {}, onDismiss: {})
        }
}
