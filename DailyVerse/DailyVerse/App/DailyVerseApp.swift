import SwiftUI
import Firebase
import RevenueCat
import GoogleMobileAds
import GoogleSignIn

@main
struct DailyVerseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var upsellManager = UpsellManager()
    @StateObject private var alarmCoordinator = AlarmCoordinator()
    @StateObject private var loadingCoordinator = AppLoadingCoordinator()

    init() {
        // Firebase 초기화
        FirebaseApp.configure()

        // RevenueCat 초기화 (v5.1: 단일 플랜 MVP — 향후 구독 도입 시 실제 키 입력)
        Purchases.configure(withAPIKey: "")
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
                // Google Sign-In URL 핸들러 (로그인 후 앱으로 리다이렉트)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
                .environmentObject(permissionManager)
                .environmentObject(upsellManager)
                .environmentObject(alarmCoordinator)
                .environmentObject(loadingCoordinator)
                .task {
                    // v5.1: 단일 플랜 — 구독 상태 확인 생략
                    // 닉네임 동기화 (로그인 유저만)
                    if let userId = authManager.userId {
                        await NicknameManager.shared.syncWithFirestore(userId: userId)
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
                    }
                }
        }
    }
}
