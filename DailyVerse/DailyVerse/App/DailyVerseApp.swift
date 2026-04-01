import SwiftUI
import Firebase
import RevenueCat
import GoogleMobileAds

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

        // RevenueCat 초기화
        // 출시 전 실제 API 키 입력 필요
        Purchases.configure(withAPIKey: "")
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        // AdMob 초기화는 AppDelegate.application(_:didFinishLaunchingWithOptions:)에서 메인스레드 처리
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
                .environmentObject(permissionManager)
                .environmentObject(upsellManager)
                .environmentObject(alarmCoordinator)
                .environmentObject(loadingCoordinator)
                .task {
                    // 앱 시작 시 구독 상태 확인 + 광고 미리 로드
                    await subscriptionManager.checkStatus()
                    AdManager.shared.loadAd()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in
                    Task {
                        await subscriptionManager.checkStatus()
                    }
                }
        }
    }
}
