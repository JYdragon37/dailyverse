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

        // RevenueCat 초기화 (v5.1: 단일 플랜 MVP — 향후 구독 도입 시 실제 키 입력)
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
