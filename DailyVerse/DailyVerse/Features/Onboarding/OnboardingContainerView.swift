import SwiftUI

// Design Ref: §5 — ZStack + offset 기반 커스텀 전환, TabView swipe 완전 제거
// Plan SC: 온보딩 완료율 85%+ / 60초 이내

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    private let screenWidth = UIScreen.main.bounds.width

    var body: some View {
        ZStack {
            // Screen 0: 감성 인트로
            ONBIntroView(vm: vm)
                .offset(x: pageOffset(for: 0))
                .opacity(nearPage(0) ? 1 : 0)

            // Screen 1: Value-First 체험
            ONBExperienceView(vm: vm)
                .offset(x: pageOffset(for: 1))
                .opacity(nearPage(1) ? 1 : 0)

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
        .ignoresSafeArea()
        // 스와이프 제스처 비활성화 (실수 방지, 버튼으로만 진행)
        .gesture(DragGesture())
    }

    // MARK: - 전환 헬퍼

    /// 화면 인덱스에 따른 X offset — 현재 페이지 기준 좌우 배치
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
