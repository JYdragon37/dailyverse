import SwiftUI
import Combine

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.currentPage) {
                OnboardingWelcomeView(viewModel: viewModel)
                    .tag(0)
                OnboardingFirstVerseView(viewModel: viewModel)
                    .tag(1)
                OnboardingLocationView(viewModel: viewModel)
                    .tag(2)
                OnboardingNotificationView(viewModel: viewModel)
                    .tag(3)
                OnboardingFirstAlarmView(viewModel: viewModel)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.dvOnboardingTransition, value: viewModel.currentPage)

            // 페이지 인디케이터 (5개 점)
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(
                            index == viewModel.currentPage
                                ? Color.dvAccent
                                : Color.secondary.opacity(0.4)
                        )
                        .frame(
                            width: index == viewModel.currentPage ? 10 : 6,
                            height: index == viewModel.currentPage ? 10 : 6
                        )
                        .animation(.spring(), value: viewModel.currentPage)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("온보딩 진행 단계 \(viewModel.currentPage + 1) / 5")
            .padding(.bottom, 20)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingContainerView()
}
