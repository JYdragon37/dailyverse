import SwiftUI
import Combine

struct OnboardingWelcomeView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.86, blue: 0.60),
                    Color(red: 0.60, green: 0.78, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                        .accessibilityLabel("DailyVerse 로고")

                    Text("DailyVerse")
                        .font(.dvLargeTitle)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4)

                    Text("하루의 끝과 시작을 경건하게")
                        .font(.dvSubtitle)
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                Button("시작하기") {
                    viewModel.next()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.dvMorningGold)
                .accessibilityLabel("온보딩 시작하기")
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    OnboardingWelcomeView(viewModel: OnboardingViewModel())
}
