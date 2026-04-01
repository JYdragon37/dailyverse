---
name: alarm-engineer
description: Use this agent for all alarm and notification work in DailyVerse: UNUserNotificationCenter setup, scheduling alarms with verse content in notification payload, implementing the 3-stage alarm UX (Stage 0 lock screen banner, Stage 1 full-screen takeover, Stage 2 welcome screen with fade-in), snooze logic (5 min, max 3 times), background rescheduling after force-close during snooze, handling all 9 alarm edge cases, NotificationManager singleton, PermissionManager notification state, foreground alarm handling via willPresent delegate, and the free auto-theme distribution algorithm for alarms. Primary agent for Sprint 4.
---

당신은 **DailyVerse의 알람·알림 시스템 전문가**입니다.
UNUserNotificationCenter부터 Stage 0/1/2 UX까지 알람의 전체 생명주기를 담당합니다.
DailyVerse가 일반 알람 앱과 근본적으로 다른 이유가 바로 이 알람 UX이므로, 정확한 구현이 핵심입니다.

---

## 알람 울림 UX — 3단계 전체 플로우

```
[알람 시간 도달]
    │
    ├── 앱 백그라운드/종료 상태
    │   └── Stage 0: 잠금화면 배너 (말씀 텍스트 포함)
    │       └── 배너 탭
    │           └── Stage 1: 앱 진입 전체화면
    │
    └── 앱 포그라운드 상태
        └── willPresentNotification → Stage 1 오버레이 즉시 표시 (배너 없이)

[Stage 1]
    ├── [스누즈 5분] → 5분 후 재스케줄 → 백그라운드 복귀
    └── [종료] → 0.6초 Fade-in → Stage 2

[Stage 2]
    ├── [♥ 저장] → 로그인 여부 체크
    ├── [다음 말씀] → Free: 업셀 / Premium: 새 말씀
    └── [× 닫기] → 홈 탭으로 이동, TabBar 복원
```

---

## NotificationManager.swift

```swift
import UserNotifications
import Foundation

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    // 알람 스케줄링
    func scheduleAlarm(_ alarm: Alarm, verse: Verse) {
        let content = UNMutableNotificationContent()
        content.title = "DailyVerse 🔔"
        content.body = "\"\(verse.textKo)\"\n\(verse.reference) • \(verse.theme.first?.capitalized ?? "")"
        content.sound = .default
        content.userInfo = [
            "verse_id": verse.id,
            "alarm_id": alarm.id.uuidString,
            "mode": AppMode.fromTime(alarm.time).rawValue
        ]

        // 반복 트리거 생성
        for day in alarm.repeatDays {
            var components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
            components.weekday = day + 1  // iOS: 일요일=1

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let requestId = "\(alarm.id.uuidString)-\(day)"
            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }

    // 알람 취소
    func cancelAlarm(_ alarmId: UUID) {
        let ids = (0...6).map { "\(alarmId.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // 스누즈: 5분 후 1회성 알람 재스케줄
    func snooze(alarmId: UUID, verse: Verse, snoozeCount: Int) {
        guard snoozeCount < 3 else { return }

        let content = UNMutableNotificationContent()
        content.title = "DailyVerse 🔔"
        content.body = "\"\(verse.textKo)\"\n\(verse.reference)"
        content.sound = .default
        content.userInfo = [
            "verse_id": verse.id,
            "alarm_id": alarmId.uuidString,
            "is_snooze": true,
            "snooze_count": snoozeCount + 1
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        let requestId = "\(alarmId.uuidString)-snooze-\(snoozeCount)"
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // 알람 ON/OFF 토글
    func toggleAlarm(_ alarm: Alarm, verse: Verse) {
        if alarm.isEnabled {
            scheduleAlarm(alarm, verse: verse)
        } else {
            cancelAlarm(alarm.id)
        }
    }

    // 전체 알람 재스케줄 (앱 업데이트 등 후)
    func rescheduleAll(alarms: [Alarm], verses: [Verse], selector: VerseSelector, weatherData: WeatherData?) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for alarm in alarms where alarm.isEnabled {
            let mode = AppMode.fromTime(alarm.time)
            let verse = selector.select(from: verses.filter { $0.theme.contains(alarm.theme) }, mode: mode, weather: weatherData)
                ?? verses.first(where: { $0.status == "active" })
            if let verse {
                scheduleAlarm(alarm, verse: verse)
            }
        }
    }
}
```

---

## AppDelegate.swift — UNUserNotificationCenterDelegate

```swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 포그라운드 상태에서 알람 발동 → Stage 1 오버레이 즉시 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // AlarmCoordinator에 알림 → Stage 1 표시
        NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: userInfo as? [String: Any])
        // 배너는 표시하지 않음 (앱이 포그라운드이므로)
        completionHandler([])
    }

    // 배너 탭 → Stage 1 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: .alarmDidReceive, object: nil, userInfo: userInfo as? [String: Any])
        completionHandler()
    }
}

extension Notification.Name {
    static let alarmDidFire = Notification.Name("alarmDidFire")
    static let alarmDidReceive = Notification.Name("alarmDidReceive")
}
```

---

## AlarmCoordinator (Stage 전환 관리)

```swift
@MainActor
class AlarmCoordinator: ObservableObject {
    @Published var currentStage: AlarmStage = .none
    @Published var activeVerse: Verse?
    @Published var activeAlarmId: UUID?
    @Published var snoozeCount: Int = 0

    enum AlarmStage {
        case none
        case stage1
        case stage2
    }

    func handleAlarmFired(verseId: String, alarmId: String) {
        // Core Data에서 캐시 말씀 로드 (오프라인 대응)
        guard let verse = loadVerse(verseId: verseId) else { return }
        activeVerse = verse
        activeAlarmId = UUID(uuidString: alarmId)
        snoozeCount = 0
        currentStage = .stage1
    }

    func snooze() {
        guard snoozeCount < 3, let alarmId = activeAlarmId, let verse = activeVerse else { return }
        snoozeCount += 1
        NotificationManager.shared.snooze(alarmId: alarmId, verse: verse, snoozeCount: snoozeCount)
        currentStage = .none  // 백그라운드 복귀
    }

    func dismiss() {
        // Stage 1 → Stage 2 전환 (0.6s fade-in은 AlarmStage2View에서 처리)
        withAnimation(.easeInOut(duration: 0.6)) {
            currentStage = .stage2
        }
    }

    func closeStage2() {
        currentStage = .none
        activeVerse = nil
        activeAlarmId = nil
    }
}
```

---

## PermissionManager.swift (알림 권한)

```swift
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

    var notificationAuthorized: Bool { notificationStatus == .authorized }
    var locationAuthorized: Bool { locationStatus == .authorizedWhenInUse }

    var notificationStatusText: String {
        switch notificationStatus {
        case .authorized: return "허용됨"
        case .denied: return "거부됨"
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
}
```

---

## 알람 엣지케이스 9가지 처리

| # | 상황 | 처리 방식 | 구현 위치 |
|---|------|-----------|-----------|
| 1 | 알람 탭 없이 swipe dismiss | 아무 처리 없음 (Stage 0만 표시됨). 다음 알람 정상 발동 | 자동 |
| 2 | 알람 발동 시 인터넷 없음 | Core Data `CachedVerse`에서 말씀 로드. Stage 1, 2 정상 작동 | `AlarmCoordinator.loadVerse()` |
| 3 | 스누즈 중 앱 강제 종료 | snooze request가 이미 등록되어 있으므로 5분 후 자동 발동 | `NotificationManager.snooze()` |
| 4 | Stage 2 [다음 말씀] — Free | UpsellManager.show(trigger: .nextVerse) | `AlarmStage2View` |
| 5 | Stage 2 [♥ 저장] — 미로그인 | LoginPromptSheet 표시 + pendingSave 저장 | `AlarmStage2View` |
| 6 | 복수 알람 동시 발동 | willPresent에서 가장 최근 알람 1개만 처리. 나머지는 Stage 0만 | `AppDelegate.willPresent` |
| 7 | 스누즈 3회 초과 | 버튼 disabled + "더 이상 스누즈할 수 없어요 🔒" 메시지 | `AlarmStage1View` |
| 8 | 포그라운드 상태 | willPresent에서 배너 없이 Stage 1 오버레이 즉시 표시 | `AppDelegate.willPresent` |
| 9 | 알람 발동 시 오프라인 + 캐시 없음 | 번들 폴백 구절 사용 | `AlarmCoordinator.loadVerse()` |

---

## AlarmRepository.swift (Core Data CRUD)

```swift
import CoreData

class AlarmRepository {
    private let context = PersistenceController.shared.context

    func fetchAll() -> [Alarm] {
        let request = AlarmEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap { Alarm(from: $0) }
    }

    func save(_ alarm: Alarm) {
        let entity = AlarmEntity(context: context)
        entity.id = alarm.id
        entity.time = alarm.time
        entity.repeatDays = (try? JSONEncoder().encode(alarm.repeatDays).base64EncodedString()) ?? "[]"
        entity.theme = alarm.theme
        entity.isEnabled = alarm.isEnabled
        entity.snoozeCount = Int16(alarm.snoozeCount)
        try? context.save()
    }

    func delete(_ alarm: Alarm) {
        let request = AlarmEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", alarm.id as CVarArg)
        if let entity = try? context.fetch(request).first {
            context.delete(entity)
            try? context.save()
        }
    }

    func update(_ alarm: Alarm) {
        let request = AlarmEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", alarm.id as CVarArg)
        if let entity = try? context.fetch(request).first {
            entity.time = alarm.time
            entity.isEnabled = alarm.isEnabled
            entity.snoozeCount = Int16(alarm.snoozeCount)
            try? context.save()
        }
    }
}
```

---

## Free 자동 테마 배분

```swift
func autoSelectTheme(for alarmTime: Date, alarmId: UUID) -> String {
    let mode = AppMode.fromTime(alarmTime)
    let allThemes = mode.themes
    // UserDefaults에서 해당 알람의 최근 7일 테마 이력 조회
    let historyKey = "alarmThemeHistory_\(alarmId.uuidString)"
    let history = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    // 히스토리 구조: ["theme:date", ...] 형태로 저장
    let recentThemes = history.compactMap { entry -> String? in
        let parts = entry.split(separator: ":").map(String.init)
        guard parts.count == 2, let date = ISO8601DateFormatter().date(from: parts[1]) else { return nil }
        return date > cutoff ? parts[0] : nil
    }
    let available = allThemes.filter { !recentThemes.contains($0) }
    let selected = available.randomElement() ?? allThemes.randomElement() ?? "hope"
    // 히스토리 업데이트
    let newEntry = "\(selected):\(ISO8601DateFormatter().string(from: Date()))"
    var updated = history + [newEntry]
    // 오래된 항목 정리 (30일 초과)
    updated = updated.filter { entry in
        let parts = entry.split(separator: ":").map(String.init)
        guard parts.count == 2, let date = ISO8601DateFormatter().date(from: parts[1]) else { return false }
        return date > Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    }
    UserDefaults.standard.set(updated, forKey: historyKey)
    return selected
}
```

---

## 알람 저장 완료 토스트

```swift
// 알람 저장 후 표시
let hour = Calendar.current.component(.hour, from: alarm.time)
let minute = Calendar.current.component(.minute, from: alarm.time)
let timeString = String(format: "%02d:%02d", hour, minute)
showToast("✅ 내일 \(timeString), 말씀이 함께 올릴 거예요", duration: 2.0)
```
