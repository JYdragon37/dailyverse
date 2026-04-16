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

    /// 뷰에서 인사말 조합용 — 빈 값이면 기본값 "NY" 표시
    var nicknameDisplay: String {
        let t = nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "NY" : t
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

    func next() {
        guard currentPage < Self.totalPages - 1 else {
            completeOnboarding()
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage += 1
            savedPage = currentPage
        }
    }

    func previous() {
        guard currentPage > 0 else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage -= 1
            savedPage = currentPage
        }
    }

    func skip() {
        // v2.0: 단순 skip (스킵 카운트 제거 — 4단계면 충분)
        next()
    }

    // MARK: - 알림 권한 요청

    func requestNotification() async {
        notificationPermissionRequested = true
        _ = await NotificationManager.shared.requestPermission()
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

        // 이미 알람이 존재하면 중복 생성 방지
        let existing = alarmRepository.fetchAll()
        guard existing.isEmpty else { return }

        let alarm = Alarm(
            id: UUID(),
            time: morningAlarmTime,
            repeatDays: [0, 1, 2, 3, 4, 5, 6],
            theme: "hope",
            isEnabled: true,
            label: "아침의 말씀",
            snoozeInterval: 5
        )
        try? alarmRepository.save(alarm)
        notificationManager.schedule(alarm, verse: Verse.fallbackRiseIgnite)
    }
}

