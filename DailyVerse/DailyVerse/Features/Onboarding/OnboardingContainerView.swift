import SwiftUI

// v5.1 — 6단계 온보딩
// 0: Welcome → 1: 닉네임 → 2: First Verse → 3: Location → 4: Notification → 5: First Alarm

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.currentPage) {
                OnboardingWelcomeView(viewModel: viewModel)
                    .tag(0)
                OnboardingNicknameView(viewModel: viewModel)   // v5.1 신규
                    .tag(1)
                OnboardingFirstVerseView(viewModel: viewModel)
                    .tag(2)
                OnboardingLocationView(viewModel: viewModel)
                    .tag(3)
                OnboardingNotificationView(viewModel: viewModel)
                    .tag(4)
                OnboardingFirstAlarmView(viewModel: viewModel)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.dvOnboardingTransition, value: viewModel.currentPage)

            // 페이지 인디케이터 (6개 점)
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(
                            index == viewModel.currentPage
                                ? Color.dvAccentGold
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
            .accessibilityLabel("온보딩 진행 단계 \(viewModel.currentPage + 1) / 6")
            .padding(.bottom, 20)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingContainerView()
}
