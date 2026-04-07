import SwiftUI
import Combine
import UserNotifications
import CoreLocation

@MainActor
class PermissionManager: NSObject, ObservableObject {
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?

    let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationStatus = locationManager.authorizationStatus
        // 이미 권한이 있으면 앱 시작 즉시 위치 요청
        if locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }

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
                .requestAuthorization(options: [.alert, .badge, .sound]) // timeSensitive는 entitlement로 처리
            notificationStatus = granted ? .authorized : .denied
        } catch {
            notificationStatus = .denied
        }
    }

    func checkLocation() {
        locationStatus = locationManager.authorizationStatus
        if locationAuthorized && currentLocation == nil {
            locationManager.requestLocation()
        }
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 온보딩용 async 위치 권한 요청 (결과를 기다리지 않고 요청만 발송)
    func requestLocationPermission() async {
        locationManager.requestWhenInUseAuthorization()
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

// MARK: - CLLocationManagerDelegate

extension PermissionManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.locationStatus = manager.authorizationStatus
            if self.locationAuthorized {
                manager.requestLocation()
            } else {
                self.currentLocation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 위치 실패 시 조용히 처리 — 기존 캐시 사용
    }
}
