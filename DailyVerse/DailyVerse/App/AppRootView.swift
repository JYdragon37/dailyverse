import SwiftUI
import UserNotifications
import AppTrackingTransparency

struct AppRootView: View {
    // v2 신규 온보딩 키 — 기존 onboardingCompleted(v1) 유저도 새 온보딩 경험
    @AppStorage("onboardingV2Completed") private var onboardingCompleted = false
    @AppStorage("authWelcomeSkipped") private var authWelcomeSkipped = false  // 레거시, 미사용
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var alarmCoordinator: AlarmCoordinator
    @EnvironmentObject private var loadingCoordinator: AppLoadingCoordinator

    @State private var showAuthWelcome: Bool = false  // 레거시, 항상 false
    @State private var guestModeActive: Bool = false  // 레거시, 미사용
    // NOTE: showNicknameSetup 제거 — 닉네임 입력은 온보딩(ONBNicknameView)에서 처리

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
            } else {
                // 온보딩 완료 + 로그인 or 게스트 → 메인
                MainTabView()
                    .transition(.opacity)
            }

            // MARK: - Stage 2 — 말씀+날씨 웰컴 스크린 (iOS 26 AlarmKit / Legacy 모두 직행)
            if alarmCoordinator.stage == .stage2 {
                AlarmStage2View()
                    .transition(.dvFade)
                    .zIndex(31)
            }

            // MARK: - VerseRead — Live Activity "말씀 보기" 탭 시 (스누즈/일어나기 없음)
            if alarmCoordinator.stage == .verseRead {
                VerseReadView()
                    .transition(.dvFade)
                    .zIndex(30)
            }

            #if DEBUG
            if UserDefaults.standard.bool(forKey: "debugShowAuthWelcome") {
                AuthWelcomeView(onSkip: {})
                    .ignoresSafeArea()
                    .zIndex(52)
                    .environmentObject(authManager)
            }
            #endif
        }
        .animation(.dvStageTransition, value: alarmCoordinator.stage)
        .animation(.easeInOut(duration: 0.4), value: loadingCoordinator.state == .ready)
        // MARK: - 탈퇴 완료 알림 (SettingsView 소멸 후에도 표시)
        .alert(appLanguageString("appRoot.deletionComplete.title"), isPresented: .init(
            get: { authManager.deletionCompleteMessage != nil },
            set: { if !$0 { authManager.deletionCompleteMessage = nil } }
        )) {
            Button(appLanguageString("common.ok")) { authManager.deletionCompleteMessage = nil }
        } message: {
            Text(authManager.deletionCompleteMessage ?? "")
        }
        // MARK: - 앱 시작 시 로딩 플로우 시작
        .task {
            await loadingCoordinator.start()
            // 알림 권한: 온보딩 완료 유저만 여기서 확인
            // (미완료 유저는 온보딩 Screen 4에서 처리)
            if onboardingCompleted {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                if settings.authorizationStatus == .notDetermined {
                    _ = await NotificationManager.shared.requestPermission()
                }
                // ATT: 이미 온보딩 완료한 기존 유저도 최초 1회 요청 (아직 미요청 시)
                requestTrackingIfNeeded()
            }

            // AlarmKit 콜드런치 대응 — 로딩 완료 + onboardingCompleted 확정 후 처리
            // (init에서 하면 onboarding 여부가 미확정 상태라 온보딩 위에 Stage2가 덮이는 버그)
            if onboardingCompleted,
               let pendingId = UserDefaults.standard.string(forKey: "pendingAlarmKitStop") {
                let modeStr = UserDefaults.standard.string(forKey: "pendingAlarmKitStopMode")
                UserDefaults.standard.removeObject(forKey: "pendingAlarmKitStop")
                UserDefaults.standard.removeObject(forKey: "pendingAlarmKitStopMode")
                await alarmCoordinator.handleAlarmKitStop(
                    alarmId: UUID(uuidString: pendingId) ?? UUID(),
                    modeString: modeStr,
                    fallbackVerseId: ""
                )
            } else {
                // 온보딩 미완료면 pending 클리어만
                UserDefaults.standard.removeObject(forKey: "pendingAlarmKitStop")
                UserDefaults.standard.removeObject(forKey: "pendingAlarmKitStopMode")
            }
        }
        // MARK: - 오프라인 토스트 (3초 후 자동 해제)
        .overlay(alignment: .bottom) {
            if loadingCoordinator.isOffline {
                ToastView(message: appLanguageString("appRoot.offlineToast"))
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
        // MARK: - 강제 업데이트 알럿
        .alert(appLanguageString("appRoot.forceUpdate.title"), isPresented: $loadingCoordinator.showForceUpdate) {
            Button(appLanguageString("appRoot.forceUpdate.openAppStore")) {
                if let url = URL(string: "https://apps.apple.com/app/id6763995142") {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(appLanguageString("appRoot.forceUpdate.message"))
        }
        .onChange(of: onboardingCompleted) { completed in
            if completed {
                // ATT: 온보딩 완료 직후 요청 — 심사자가 확실히 도달하는 시점
                requestTrackingIfNeeded()
            }
        }
        // MARK: - 로그인/로그아웃 감지
        .onChange(of: authManager.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                // 로그인 성공 → 게스트 모드 해제
                guestModeActive = false
                // syncWithFirestore가 완료된 후에만 isSet 체크해야 기존 닉네임 유저에게
                // NicknameSetupView가 불필요하게 뜨지 않음.
                // 1초 고정 sleep → 실제 sync 완료 대기로 교체하여 race condition 해결.
                Task {
                    if let userId = authManager.userId {
                        await NicknameManager.shared.syncWithFirestore(userId: userId)
                    }
                }
            } else {
                // 로그아웃 or 탈퇴
                guestModeActive = false
                if !authManager.isDeletingAccount {
                    // 로그아웃: 온보딩은 최초 1회만 — 로그인 화면으로 바로 이동
                    // (탈퇴는 deleteAccount()에서 UserDefaults 전체 초기화 → onboardingCompleted=false 자동)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showAuthWelcome = true
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

    // MARK: - App Tracking Transparency
    /// 온보딩 완료 직후 ATT 권한을 최초 1회 요청.
    /// 앱이 active 상태에서 UI가 안정된 뒤 호출해야 시스템 팝업이 확실히 표시됨.
    private func requestTrackingIfNeeded() {
        guard #available(iOS 14, *) else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        Task {
            // UI 전환 안정화 대기 → active 상태 보장 (팝업 유실 방지)
            try? await Task.sleep(nanoseconds: 800_000_000)
            _ = await ATTrackingManager.requestTrackingAuthorization()
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
