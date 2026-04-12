import SwiftUI
import UserNotifications

struct AppRootView: View {
    // v2 신규 온보딩 키 — 기존 onboardingCompleted(v1) 유저도 새 온보딩 경험
    @AppStorage("onboardingV2Completed") private var onboardingCompleted = false
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var alarmCoordinator: AlarmCoordinator
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    /// 현재 세션에서 AuthWelcomeView를 보여줄지 여부
    /// - 로그인된 상태라면 false (스킵)
    @State private var showAuthWelcome: Bool = false
    /// 세션 내에서만 유지되는 게스트 모드 플래그
    /// - 앱 재실행 시 초기화됨 (영구 저장 안 함)
    @State private var guestModeActive: Bool = false
    /// 닉네임 미설정 유저에게 닉네임 입력 화면 표시
    @State private var showNicknameSetup: Bool = false

    var body: some View {
        ZStack {
            // MARK: - [베이스 레이어] Zone 배경 이미지
            // 스플래시 중에 미리 로드됨 → state=.ready 전환 순간 이미지가 이미 보임
            // SplashView / MainTabView / AlarmView 모두 이 위에 올라탐
            // Zone 배경: 온보딩 완료 후(메인 앱)에서만 표시
            // 온보딩 중 표시 시 scaledToFill이 우측으로 overflow되어 온보딩 화면에 비침
            if onboardingCompleted {
                if let bgImage = loadingCoordinator.zoneBgImage {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            Image(uiImage: bgImage)
                                .resizable()
                                .scaledToFill()
                        )
                        .clipped()
                        .ignoresSafeArea()
                        .zIndex(0)
                } else {
                    LinearGradient(
                        colors: AppMode.current().gradientColors,
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .zIndex(0)
                }
            } else {
                // 온보딩 중: 각 온보딩 화면이 자체 배경 관리 → 순수 다크 베이스
                Color.dvBgDeep.ignoresSafeArea().zIndex(0)
            }

            // MARK: - 로딩 상태에 따른 화면 분기
            // splash / loading 을 단일 SplashView로 유지 →
            // 상태 전환 시 SwiftUI가 같은 뷰로 인식, 로고 재애니메이션(깜빡임) 없음
            if loadingCoordinator.state != .ready {
                SplashView()
                    .transition(.opacity)
                    .zIndex(20)
            } else if !onboardingCompleted {
                // 온보딩 미완료 → 항상 온보딩 먼저 (로그인 여부 무관)
                OnboardingContainerView()
                    .transition(.opacity)
            } else if showAuthWelcome && !authManager.isLoggedIn && !guestModeActive {
                // 온보딩 완료 + 미로그인 → 로그인 유도
                AuthWelcomeView(onSkip: {
                    guestModeActive = true
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showAuthWelcome = false
                    }
                })
                .transition(.opacity)
                .zIndex(5)
            } else {
                // 온보딩 완료 + 로그인 or 게스트 → 메인
                MainTabView()
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
        // MARK: - 탈퇴 완료 알림 (SettingsView 소멸 후에도 표시)
        .alert("탈퇴 완료", isPresented: .init(
            get: { authManager.deletionCompleteMessage != nil },
            set: { if !$0 { authManager.deletionCompleteMessage = nil } }
        )) {
            Button("확인") { authManager.deletionCompleteMessage = nil }
        } message: {
            Text(authManager.deletionCompleteMessage ?? "")
        }
        // MARK: - 앱 시작 시 로딩 플로우 시작
        .task {
            await loadingCoordinator.start()
            // AuthWelcomeView 표시 여부 결정:
            // - 이미 로그인된 경우 → 스킵
            // - 그 외 미로그인 → 매 세션 표시 (게스트 모드 선택 시 세션 내 스킵)
            if !authManager.isLoggedIn {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showAuthWelcome = true
                }
            } else if !NicknameManager.shared.isSet {
                // 이미 로그인 상태인데 닉네임 미설정 → 입력 화면 표시
                showNicknameSetup = true
            }
            // 알림 권한: 온보딩 완료 유저만 여기서 확인
            // (미완료 유저는 온보딩 Screen 4에서 처리)
            if onboardingCompleted {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                if settings.authorizationStatus == .notDetermined {
                    _ = await NotificationManager.shared.requestPermission()
                }
            }
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
        // MARK: - 온보딩 완료 → 인증 화면 트리거
        // 온보딩이 방금 완료됐고 아직 미로그인이면 AuthWelcomeView 표시
        .onChange(of: onboardingCompleted) { completed in
            if completed && !authManager.isLoggedIn {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showAuthWelcome = true
                }
            }
        }
        // MARK: - 로그인/로그아웃 감지
        .onChange(of: authManager.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                // 로그인 성공 → 게스트 모드 해제
                guestModeActive = false
                // syncWithFirestore(AuthManager.signIn 내부)가 완료된 후 isSet 체크해야
                // 기존 닉네임 유저에게 NicknameSetupView가 불필요하게 뜨지 않음 (타이밍 버그 방지)
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    if !NicknameManager.shared.isSet {
                        showNicknameSetup = true
                    }
                }
            } else {
                // 로그아웃 or 탈퇴
                guestModeActive = false
                showNicknameSetup = false
                if !authManager.isDeletingAccount {
                    // 로그아웃: 온보딩 초기화 → 기존 유저도 온보딩 → 로그인 순서
                    // onboardingCompleted=false → OnboardingContainerView
                    // 온보딩 완료 후 onChange(of: onboardingCompleted)에서 showAuthWelcome=true 자동 세팅
                    onboardingCompleted = false
                }
            }
        }
        // MARK: - 닉네임 입력 화면
        .fullScreenCover(isPresented: $showNicknameSetup) {
            NicknameSetupView {
                showNicknameSetup = false
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
