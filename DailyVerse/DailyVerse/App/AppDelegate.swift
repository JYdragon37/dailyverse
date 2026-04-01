import UIKit
import UserNotifications
import FirebaseAnalytics
import FirebaseCrashlytics
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        // AdMob은 메인스레드 didFinishLaunching에서 초기화
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // 포그라운드 진입 시 배지 초기화
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
