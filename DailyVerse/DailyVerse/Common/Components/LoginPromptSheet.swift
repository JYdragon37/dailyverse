import SwiftUI
import Combine

struct LoginPromptSheet: View {
    let onLogin: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var authManager: AuthManager
    @State private var showEmailAuth = false

    var body: some View {
        VStack(spacing: 24) {
            // 핸들
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // 아이콘
            Image(systemName: "bookmark.fill")
                .font(.system(size: 44))
                .foregroundColor(.dvAccent)

            VStack(spacing: 8) {
                Text("말씀을 저장하려면 로그인이 필요해요")
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)

                Text("Apple·Google 계정으로 간편하게 시작하세요")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                // Apple 로그인
                Button(action: onLogin) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Apple로 시작하기")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.primary)
                    .foregroundColor(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .accessibilityLabel("Apple 계정으로 로그인")

                // Google 로그인
                Button {
                    Task { await authManager.signInWithGoogle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .medium))
                        Text("Google로 시작하기")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Google 계정으로 로그인")

                // 이메일 로그인
                Button {
                    showEmailAuth = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                        Text("이메일로 로그인 / 회원가입")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .sheet(isPresented: $showEmailAuth) {
                    EmailAuthView()
                        .environmentObject(authManager)
                }

                Button(action: onDismiss) {
                    Text("나중에")
                        .font(.dvBody)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("로그인 건너뛰기")
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
