import SwiftUI

// Design Ref: §5 — ZStack + offset 기반 커스텀 전환, TabView swipe 완전 제거
// Plan SC: 온보딩 완료율 85%+ / 60초 이내

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator
    private let screenWidth = UIScreen.main.bounds.width

    var body: some View {
        ZStack {
            // 베이스 배경: 온보딩 그라데이션 (페이지 전환 시 노출 방지)
            LinearGradient(
                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Screen 0: 감성 인트로
            ONBIntroView(vm: vm)
                .offset(x: pageOffset(for: 0))
                .opacity(nearPage(0) ? 1 : 0)

            // Screen 1: Value-First 체험 — 현재 페이지일 때만 활성
            ONBExperienceView(vm: vm)
                .offset(x: pageOffset(for: 1))
                .opacity(vm.currentPage == 1 ? 1 : 0)

            // Screen 2: 테마 + 닉네임
            ONBPersonalizeView(vm: vm)
                .offset(x: pageOffset(for: 2))
                .opacity(nearPage(2) ? 1 : 0)

            // Screen 3: 알람 + Permission Priming
            ONBAlarmPermissionView(vm: vm)
                .offset(x: pageOffset(for: 3))
                .opacity(nearPage(3) ? 1 : 0)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: vm.currentPage)
        .gesture(DragGesture())
        .overlay(alignment: .top) {
            HStack {
                // 뒤로가기 버튼 (page 0에서는 숨김)
                if vm.currentPage > 0 {
                    Button {
                        vm.previous()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                    }
                    .accessibilityLabel("이전 단계")
                } else {
                    // 공간 유지용 빈 뷰
                    Color.clear.frame(width: 32, height: 32)
                }

                Spacer()

                // 진행 상태 도트
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

                // 우측 균형용 빈 뷰
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // MARK: - 전환 헬퍼

    private func pageOffset(for page: Int) -> CGFloat {
        CGFloat(page - vm.currentPage) * screenWidth
    }

    /// 인접 화면(현재 ±1)만 렌더링해 메모리 절약
    private func nearPage(_ page: Int) -> Bool {
        abs(vm.currentPage - page) <= 1
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppLoadingCoordinator())
        .preferredColorScheme(.dark)
}
