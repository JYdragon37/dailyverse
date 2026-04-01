import SwiftUI
import Combine
import UserNotifications
import CoreLocation

@MainActor
class PermissionManager: ObservableObject {
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    func checkAll() async {
        await checkNotification()
        checkLocation()
    }

    func checkNotification() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    func requestNotification() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            notificationStatus = granted ? .authorized : .denied
        } catch {
            notificationStatus = .denied
        }
    }

    func checkLocation() {
        locationStatus = locationManager.authorizationStatus
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 온보딩용 async 위치 권한 요청 (결과를 기다리지 않고 요청만 발송)
    func requestLocationPermission() async {
        locationManager.requestWhenInUseAuthorization()
        // CLLocationManager 콜백은 delegate 기반이므로 요청 발송 후 즉시 반환
        // 실제 상태 업데이트는 checkLocation()으로 폴링하거나 delegate로 처리
    }

    /// 온보딩용 async 알림 권한 요청
    func requestNotificationPermission() async {
        await requestNotification()
    }

    var notificationAuthorized: Bool { notificationStatus == .authorized }
    var locationAuthorized: Bool {
        locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
    }

    var notificationStatusText: String {
        switch notificationStatus {
        case .authorized: return "허용됨"
        case .denied: return "거부됨"
        case .provisional: return "임시 허용"
        default: return "미설정"
        }
    }

    var locationStatusText: String {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return "허용됨"
        case .denied, .restricted: return "거부됨"
        default: return "미설정"
        }
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
