import SwiftUI
import Firebase
import RevenueCat
import GoogleMobileAds
import GoogleSignIn
import AppTrackingTransparency
import OSLog

private let appLog = Logger(subsystem: "com.morningmanna.app", category: "DailyVerseApp")

@main
struct DailyVerseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var upsellManager = UpsellManager()
    @StateObject private var alarmCoordinator = AlarmCoordinator()
    @StateObject private var loadingCoordinator = AppLoadingCoordinator()
    @StateObject private var greetingService = GreetingService()

    init() {
        // Firebase 초기화
        FirebaseApp.configure()

        // RevenueCat 초기화
        // 현재 키: test_ prefix → Sandbox 환경. 출시 전 Production 키로 교체 권장.
        Purchases.configure(withAPIKey: "test_qLgnYIQVMaVTzEsejPWGaCUQrsu")
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        // Fix 4: 이중 탭바 방지 — UIKit 네이티브 탭바를 완전히 숨김
        // 커스텀 DVTabBar가 모든 탭 네비게이션을 담당함
        UITabBar.appearance().isHidden = true

        // Toss-style: large title 좌측 여백 통일 + 투명 내비게이션바 기본값
        // 각 탭에서 .toolbarBackground/.toolbarColorScheme을 설정한 경우 해당 modifier가 우선 적용됨
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)

        // 다크 테마 Form/List 배경 전역 설정 (SettingsView 등 UITableView 기반 뷰)
        UITableView.appearance().backgroundColor = UIColor(red: 9/255, green: 13/255, blue: 24/255, alpha: 1)
        UITableView.appearance().separatorColor = UIColor.white.withAlphaComponent(0.08)

        // AdMob 초기화는 AppDelegate.application(_:didFinishLaunchingWithOptions:)에서 메인스레드 처리
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                    .preferredColorScheme(.dark) // 앱 전체 다크 모드 고정
                    // Google Sign-In URL 핸들러 (로그인 후 앱으로 리다이렉트)
                    .onOpenURL { url in
                        // dailyverse://alarm-stop?id=UUID — Live Activity 버튼 탭
                        if url.scheme == "dailyverse", url.host == "alarm-stop" {
                            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                            let idStr = components?.queryItems?.first(where: { $0.name == "id" })?.value ?? ""
                            Task { @MainActor in
                                await alarmCoordinator.handleAlarmKitStop(
                                    alarmId: UUID(uuidString: idStr) ?? UUID(),
                                    modeString: AppMode.current().rawValue,
                                    fallbackVerseId: ""
                                )
                            }
                        } else {
                            GIDSignIn.sharedInstance.handle(url)
                        }
                    }
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .environmentObject(permissionManager)
                    .environmentObject(upsellManager)
                    .environmentObject(alarmCoordinator)
                    .environmentObject(loadingCoordinator)
                    .environmentObject(greetingService)
                    .task {
                        // v5.1: 단일 플랜 — 구독 상태 확인 생략
                        // 닉네임 동기화 (로그인 유저만)
                        if let userId = authManager.userId {
                            await NicknameManager.shared.syncWithFirestore(userId: userId)
                        }
                        // 마스터 계정 확인 — Firestore app_config/master_accounts
                        if let email = authManager.user?.email {
                            await subscriptionManager.checkMasterAccount(email: email)
                        }
                        // ATT 팝업은 첫 알람 저장 시점으로 이동 (AlarmViewModel.saveAlarm)
                    }
                    // 로그인 상태 변경 감지
                    .onChange(of: authManager.isLoggedIn) { isLoggedIn in
                        if isLoggedIn, let email = authManager.user?.email {
                            Task {
                                await subscriptionManager.checkMasterAccount(email: email)
                                // 로그인 후 today verse 강제 재조회 — 캐시된 잘못된 말씀 교정
                                let mode = AppMode.current()
                                let weather = WeatherCacheManager().load()
                                _ = await VerseRepository.shared.currentVerse(for: mode, weather: weather)
                            }
                        } else if !isLoggedIn {
                            subscriptionManager.logOut()
                        }
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: UIApplication.willEnterForegroundNotification
                        )
                    ) { _ in
                        Task {
                            if let userId = authManager.userId {
                                await NicknameManager.shared.syncWithFirestore(userId: userId)
                            }
                            // 포그라운드 복귀 시에도 premium 상태 재확인
                            if let email = authManager.user?.email {
                                await subscriptionManager.checkMasterAccount(email: email)
                            }
                        }
                    }
                    // 알람 서비스 scenePhase 관리
                    // iOS 26+: 음향/잠금화면은 AlarmKit 담당, 타이머는 포그라운드 Stage2 트리거용 유지
                    // iOS 15-25: BackgroundService 전체 동작 (무음루프 + 타이머)
                    .onChange(of: scenePhase) { phase in
                        if #available(iOS 26.0, *) {
                            // iOS 26: 앱 활성화 시 타이머만 재갱신 (무음루프 없음)
                            if phase == .active {
                                AlarmBackgroundService.shared.rescheduleTimers()
                                AlarmBackgroundService.shared.reregisterIfVersionChanged()
                            }
                            return
                        }
                        switch phase {
                        case .background:
                            AlarmBackgroundService.shared.start()
                        case .active:
                            AlarmBackgroundService.shared.stop()
                            AlarmBackgroundService.shared.reregisterIfVersionChanged()
                        default:
                            break
                        }
                    }
                    // Q2: 저전력 모드 감지 → 알람 미작동 경고 토스트
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: Notification.Name("NSProcessInfoPowerStateDidChangeNotification")
                        )
                    ) { _ in
                        if ProcessInfo.processInfo.isLowPowerModeEnabled {
                            appLog.warning("⚠️ 저전력 모드 활성화 — 알람 백그라운드 미작동 가능성")
                            NotificationCenter.default.post(name: .dvLowPowerModeWarning, object: nil)
                        }
                    }
        }
    }
}
