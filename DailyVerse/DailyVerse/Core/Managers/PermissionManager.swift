import SwiftUI
import Combine
import UserNotifications
import CoreLocation
import AlarmKit

@MainActor
class PermissionManager: NSObject, ObservableObject {
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    // AlarmKit 권한 상태 (iOS 26+)
    @Published var alarmKitStatus: String = "미설정"   // "허용됨" | "거부됨" | "미설정"

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
        await checkAlarmKit()
    }

    // MARK: - AlarmKit 권한 (iOS 26+)

    @available(iOS 26.0, *)
    func requestAlarmKitPermission() async {
        let granted = await AlarmKitEngine().requestAuthorization()
        alarmKitStatus = granted ? "허용됨" : "거부됨"
    }

    func checkAlarmKit() async {
        if #available(iOS 26.0, *) {
            let state = AlarmManager.shared.authorizationState
            switch state {
            case .authorized:   alarmKitStatus = "허용됨"
            case .denied:       alarmKitStatus = "거부됨"
            case .notDetermined: alarmKitStatus = "미설정"
            @unknown default:   alarmKitStatus = "미설정"
            }
        } else {
            alarmKitStatus = "미지원"  // iOS 15-25
        }
    }

    var alarmKitAuthorized: Bool { alarmKitStatus == "허용됨" }

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

    private var isEnglish: Bool { UserDefaults.standard.string(forKey: "appLanguage") == "en" }

    var notificationStatusText: String {
        if isEnglish {
            switch notificationStatus {
            case .authorized: return "Allowed"
            case .denied: return "Denied"
            case .provisional: return "Provisionally Allowed"
            default: return "Not Set"
            }
        }
        switch notificationStatus {
        case .authorized: return "허용됨"
        case .denied: return "거부됨"
        case .provisional: return "임시 허용"
        default: return "미설정"
        }
    }

    var locationStatusText: String {
        if isEnglish {
            switch locationStatus {
            case .authorizedWhenInUse, .authorizedAlways: return "Allowed"
            case .denied, .restricted: return "Denied"
            default: return "Not Set"
            }
        }
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return "허용됨"
        case .denied, .restricted: return "거부됨"
        default: return "미설정"
        }
    }

    /// alarmKitStatus(내부 비교용 한국어 토큰)의 표시 전용 영어 변환
    var alarmKitStatusDisplay: String {
        guard isEnglish else { return alarmKitStatus }
        switch alarmKitStatus {
        case "허용됨": return "Allowed"
        case "거부됨": return "Denied"
        case "미지원": return "Unsupported"
        default: return "Not Set"
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
