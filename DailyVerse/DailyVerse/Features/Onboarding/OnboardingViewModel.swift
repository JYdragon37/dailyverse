import SwiftUI
import Combine

// Design Ref: §3 — ZStack + 단일 ViewModel, Option C Pragmatic Balance
// Plan SC: 온보딩 완료율 85%+ / 알람 설정 70%+ / 60초 이내

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - 네비게이션
    @Published var currentPage: Int = 0
    static let totalPages = 4  // 공감 / 닉네임 / 체험 / 알람설정

    // MARK: - UserDefaults 키
    // v2 신규 온보딩 키 사용 (AppRootView와 동일한 키)
    @AppStorage(OnboardingKey.newCompleted.rawValue)           var onboardingCompleted = false
    @AppStorage(OnboardingKey.nicknameSet.rawValue)            var nicknameSet = false
    @AppStorage(OnboardingKey.notificationRequested.rawValue)  var notificationPermissionRequested = false
    @AppStorage(OnboardingKey.firstAlarmShown.rawValue)        var firstAlarmPromptShown = false
    // OnboardingKey.locationRequested → HomeViewModel에서 관리 (Design §6)

    // MARK: - 재개용
    @AppStorage("onboardingCurrentPage") private var savedPage: Int = 0

    // MARK: - 닉네임
    @Published var nicknameInput: String = ""

    /// 뷰에서 인사말 조합용 — 빈 값이면 기본값 "Stranger" 표시
    var nicknameDisplay: String {
        let t = nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Stranger" : t
    }

    // MARK: - Screen 3: 알람 설정 (단일 알람 — 기본 07:00)
    @Published var morningAlarmEnabled: Bool = true
    @Published var morningAlarmTime: Date = {
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    // MARK: - Dependencies
    private let permissionManager: PermissionManager
    private let alarmRepository: AlarmRepository
    private let notificationManager: NotificationManager

    // MARK: - Init

    init() {
        // @MainActor class이므로 default 파라미터 대신 init body에서 생성
        // (default 파라미터 값은 nonisolated context에서 평가 → @MainActor 충돌)
        self.permissionManager = PermissionManager()
        self.alarmRepository = AlarmRepository()
        self.notificationManager = .shared

        if !onboardingCompleted {
            currentPage = savedPage
        }
        // 기존 닉네임 복원
        let existing = NicknameManager.shared.nickname
        nicknameInput = existing == "친구" ? "" : existing
    }

    // MARK: - 네비게이션

    /// 슬라이드 방향 — OnboardingContainerView의 transition 방향 결정
    @Published var isGoingForward: Bool = true

    func next() {
        guard currentPage < Self.totalPages - 1 else {
            completeOnboarding()
            return
        }
        isGoingForward = true   // transition 방향 먼저 설정
        currentPage += 1
        savedPage = currentPage
    }

    func previous() {
        guard currentPage > 0 else { return }
        isGoingForward = false  // transition 방향 먼저 설정
        currentPage -= 1
        savedPage = currentPage
    }

    func skip() {
        next()
    }

    // MARK: - 알림 권한 요청

    func requestNotification() async {
        notificationPermissionRequested = true
        // 1. 알림 권한 (.alert .badge .sound .timeSensitive)
        _ = await NotificationManager.shared.requestPermission()
        // 2. AlarmKit 권한 (iOS 26+) — 잠금화면 알람 + Live Activity
        if #available(iOS 26.0, *) {
            _ = await AlarmKitEngine().requestAuthorization()
        }
    }

    // MARK: - 온보딩 완료

    func completeOnboarding() {
        saveNickname()
        saveFirstAlarms()
        onboardingCompleted = true
        savedPage = 0
        firstAlarmPromptShown = true
    }

    // MARK: - Private 저장 헬퍼

    private func saveNickname() {
        let trimmed = nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        nicknameSet = true
        Task {
            await NicknameManager.shared.setNickname(trimmed.isEmpty ? "친구" : trimmed)
        }
    }

    private func saveFirstAlarms() {
        guard morningAlarmEnabled else { return }

        let existing = alarmRepository.fetchAll()

        if existing.isEmpty {
            // 알람이 없으면 신규 생성
            let alarm = Alarm(
                time: morningAlarmTime,
                repeatDays: [0, 1, 2, 3, 4, 5, 6],
                theme: "hope",
                isEnabled: true,
                label: Alarm.defaultLabel(for: morningAlarmTime)
            )
            try? alarmRepository.save(alarm)
            notificationManager.schedule(alarm, verse: Verse.fallbackRiseIgnite)
        } else {
            // 기존 첫 번째 알람의 시간을 온보딩에서 선택한 시간으로 업데이트
            // (비로그인 유저는 매 실행마다 온보딩이 재시작되므로 upsert 필요)
            var alarm = existing[0]
            alarm.time = morningAlarmTime
            alarm.isEnabled = true
            try? alarmRepository.update(alarm)
            notificationManager.cancel(alarmId: alarm.id)
            notificationManager.schedule(alarm, verse: Verse.fallbackRiseIgnite)
        }

        // 백그라운드 타이머 갱신 + 알람 탭이 이미 열려있는 경우 즉시 반영
        AlarmBackgroundService.shared.rescheduleTimers()
        NotificationCenter.default.post(name: .dvAlarmSaved, object: nil)
    }
}

