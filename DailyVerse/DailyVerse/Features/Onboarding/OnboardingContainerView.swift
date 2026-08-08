import SwiftUI

// MARK: - OnboardingContainerView v2.3
//
// 전환 방식: offset 기반 (ZStack 내 3개 뷰 항상 존재)
// → transition 방식 대비 배경 노출 완전 방지
//
// v2.3 변경 (2026-07-13):
//   - 4단계 → 3단계: ONBExperienceView(알람체험 시뮬레이션) 제거
//   - 새 순서: 공감(0) / 닉네임(1) / 알람설정(2)
//   - totalPages = 3 (OnboardingViewModel)

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator
    private let screenWidth = UIScreen.main.bounds.width

    var body: some View {
        ZStack {
            // 베이스 배경 (offset 방식에서는 두 인접 페이지가 항상 화면을 완전히 커버)
            LinearGradient(
                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ONBIntroView(vm: vm)
                .offset(x: pageOffset(for: 0))
                .opacity(nearPage(0) ? 1 : 0)

            ONBNicknameView(vm: vm)
                .offset(x: pageOffset(for: 1))
                .opacity(nearPage(1) ? 1 : 0)

            ONBAlarmPermissionView(vm: vm)
                .offset(x: pageOffset(for: 2))
                .opacity(nearPage(2) ? 1 : 0)
        }
        // easeInOut: 오버슈팅 없음 → 두 인접 페이지가 전환 중 항상 화면 전체를 커버
        .animation(.easeInOut(duration: 0.28), value: vm.currentPage)
        .gesture(DragGesture()) // 스와이프 차단
        .overlay(alignment: .top) { progressBar }
    }

    // MARK: - 레이아웃 헬퍼

    private func pageOffset(for page: Int) -> CGFloat {
        CGFloat(page - vm.currentPage) * screenWidth
    }

    private func nearPage(_ page: Int) -> Bool {
        abs(vm.currentPage - page) <= 1
    }

    // MARK: - 진행 도트

    private var progressBar: some View {
        HStack {
            if vm.currentPage > 0 {
                Button { vm.previous() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                }
                .accessibilityLabel(appLanguageString("onboarding.a11y.previousStep"))
            } else {
                Color.clear.frame(width: 32, height: 32)
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<OnboardingViewModel.totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == vm.currentPage
                              ? Color.white
                              : Color.white.opacity(0.45))
                        .frame(width: index == vm.currentPage ? 20 : 8, height: 4)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.currentPage)
                }
            }

            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppLoadingCoordinator())
        .preferredColorScheme(.dark)
}
