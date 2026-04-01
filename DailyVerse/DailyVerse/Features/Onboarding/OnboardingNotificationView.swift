import SwiftUI
import Combine

struct OnboardingNotificationView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.dvAccent)
                    .accessibilityLabel("알림 아이콘")

                Text("알람이 울릴 때\n말씀이 함께 옵니다")
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)

                Text("매일 알람을 통해 자연스럽게\n하나님의 말씀을 만나보세요")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("알림 허용하기") {
                    Task {
                        await viewModel.requestNotification()
                        viewModel.next()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("알림 권한 허용하기")

                Button("나중에") {
                    viewModel.skip()
                }
                .font(.dvBody)
                .foregroundColor(.secondary)
                .accessibilityLabel("알림 권한 나중에 설정하기")
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingNotificationView(viewModel: OnboardingViewModel())
}
