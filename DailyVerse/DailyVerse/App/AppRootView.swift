import SwiftUI

struct AppRootView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @EnvironmentObject private var alarmCoordinator: AlarmCoordinator
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    var body: some View {
        ZStack {
            // MARK: - 로딩 상태에 따른 화면 분기
            switch loadingCoordinator.state {
            case .splash:
                // Stage 1: 스플래시 화면 (0.8초)
                SplashView()
                    .transition(.opacity)
                    .zIndex(20)

            case .loading:
                // Stage 2: 스플래시를 유지하면서 백그라운드에서 데이터 로드
                // 데이터 로드 완료 후 .ready로 전환되므로 별도 스켈레톤 없이 스플래시 유지
                SplashView()
                    .transition(.opacity)
                    .zIndex(20)

            case .ready:
                // Stage 3: 온보딩 완료 여부에 따라 홈/온보딩 분기
                Group {
                    if onboardingCompleted {
                        MainTabView()
                    } else {
                        OnboardingContainerView()
                    }
                }
                .transition(.opacity)
            }

            // MARK: - Stage 1 — 전체화면 알람 (TabBar 없음)
            if alarmCoordinator.stage == .stage1 {
                AlarmStage1View()
                    .transition(.opacity)
                    .zIndex(10)
            }

            // MARK: - Stage 1.5 — 웨이크업 미션 (v5.1)
            if alarmCoordinator.stage == .stage1_5 {
                WakeMissionView(
                    mission: alarmCoordinator.activeMission,
                    nickname: NicknameManager.shared.nickname,
                    verse: alarmCoordinator.activeVerse,
                    onComplete: { alarmCoordinator.completeMission() },
                    onSkip: { alarmCoordinator.completeMission() }
                )
                .transition(.dvFade)
                .zIndex(10)
            }

            // MARK: - Stage 2 — 웰컴 스크린 (0.6s Fade-in)
            if alarmCoordinator.stage == .stage2 {
                AlarmStage2View()
                    .transition(.dvFade)
                    .zIndex(11)
            }
        }
        .animation(.dvStageTransition, value: alarmCoordinator.stage)
        .animation(.easeInOut(duration: 0.4), value: loadingCoordinator.state == .ready)
        // MARK: - 앱 시작 시 로딩 플로우 시작
        .task {
            await loadingCoordinator.start()
        }
        // MARK: - 오프라인 토스트 (3초 후 자동 해제)
        .overlay(alignment: .bottom) {
            if loadingCoordinator.isOffline {
                ToastView(message: "오프라인 상태입니다. 저장된 말씀을 표시해요")
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            withAnimation {
                                loadingCoordinator.isOffline = false
                            }
                        }
                    }
            }
        }
        // MARK: - dvAlarmTriggered 수신 → AlarmCoordinator 호출
        .onReceive(NotificationCenter.default.publisher(for: .dvAlarmTriggered)) { notification in
            guard let userInfo = notification.userInfo else { return }
            Task {
                await alarmCoordinator.handleNotification(from: userInfo)
            }
        }
    }
}

#Preview {
    AppRootView()
        .environmentObject(AlarmCoordinator())
        .environmentObject(AppLoadingCoordinator())
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
}
