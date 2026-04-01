import SwiftUI
import Combine

struct LoginPromptSheet: View {
    let onLogin: () -> Void
    let onDismiss: () -> Void

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

                Text("Apple 계정으로 간편하게 시작하세요")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button(action: onLogin) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Apple로 시작하기")
                            .font(.dvSubtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.primary)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                }
                .accessibilityLabel("Apple 계정으로 로그인")

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
