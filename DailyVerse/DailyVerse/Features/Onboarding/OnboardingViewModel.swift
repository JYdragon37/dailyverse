import SwiftUI
import Combine

// Design Ref: §3 — ZStack + 단일 ViewModel, Option C Pragmatic Balance
// Plan SC: 온보딩 완료율 85%+ / 알람 설정 70%+ / 60초 이내

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - 네비게이션
    @Published var currentPage: Int = 0
    static let totalPages = 4  // 기존 6 → 4 (슬림 온보딩)

    // MARK: - UserDefaults 키
    // v2 신규 온보딩 키 사용 (AppRootView와 동일한 키)
    @AppStorage(OnboardingKey.newCompleted.rawValue)           var onboardingCompleted = false
    @AppStorage(OnboardingKey.nicknameSet.rawValue)            var nicknameSet = false
    @AppStorage(OnboardingKey.notificationRequested.rawValue)  var notificationPermissionRequested = false
    @AppStorage(OnboardingKey.firstAlarmShown.rawValue)        var firstAlarmPromptShown = false
    // OnboardingKey.locationRequested → HomeViewModel에서 관리 (Design §6)

    // MARK: - 재개용
    @AppStorage("onboardingCurrentPage") private var savedPage: Int = 0

    // MARK: - Screen 3: 개인화
    @Published var nicknameInput: String = ""
    @Published var selectedThemes: [String] = []   // 최대 3개

    // MARK: - Screen 4: 알람
    @Published var morningAlarmEnabled: Bool = true
    @Published var eveningAlarmEnabled: Bool = false
    @Published var morningAlarmTime: Date = {
        Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @Published var eveningAlarmTime: Date = {
        Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
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

    func skip() {
        // v2.0: 단순 skip (스킵 카운트 제거 — 4단계면 충분)
        next()
    }

    // MARK: - 테마 토글 (최대 3개)

    func toggleTheme(_ theme: String) {
        if selectedThemes.contains(theme) {
            selectedThemes.removeAll { $0 == theme }
        } else if selectedThemes.count < 3 {
            selectedThemes.append(theme)
        }
    }

    // MARK: - 알림 권한 요청

    func requestNotification() async {
        notificationPermissionRequested = true
        _ = await NotificationManager.shared.requestPermission()
    }

    // MARK: - 온보딩 완료

    func completeOnboarding() {
        saveNickname()
        saveSelectedThemes()
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

    private func saveSelectedThemes() {
        guard !selectedThemes.isEmpty else { return }
        if let data = try? JSONEncoder().encode(selectedThemes) {
            UserDefaults.standard.set(data, forKey: "preferredThemes")
        }
        // 로그인 유저면 Firestore에도 저장 (향후 구현)
    }

    private func saveFirstAlarms() {
        guard morningAlarmEnabled || eveningAlarmEnabled else { return }

        if morningAlarmEnabled {
            let alarm = Alarm(
                id: UUID(),
                time: morningAlarmTime,
                repeatDays: [0, 1, 2, 3, 4, 5, 6],
                theme: selectedThemes.first ?? "hope",
                isEnabled: true,
                label: "아침의 말씀",
                snoozeInterval: 5
            )
            try? alarmRepository.save(alarm)
            notificationManager.schedule(alarm, verse: Verse.fallbackRiseIgnite)
        }

        if eveningAlarmEnabled {
            let alarm = Alarm(
                id: UUID(),
                time: eveningAlarmTime,
                repeatDays: [0, 1, 2, 3, 4, 5, 6],
                theme: selectedThemes.last ?? "peace",
                isEnabled: true,
                label: "저녁의 말씀",
                snoozeInterval: 5
            )
            try? alarmRepository.save(alarm)
            notificationManager.schedule(alarm, verse: Verse.fallbackWindDown)
        }
    }
}

// MARK: - 테마 정의

extension OnboardingViewModel {
    struct Theme: Identifiable {
        let id: String   // Verse theme key
        let emoji: String
        let label: String
    }

    static let themes: [Theme] = [
        Theme(id: "courage",   emoji: "🌟", label: "용기"),
        Theme(id: "peace",     emoji: "🕊️", label: "평안"),
        Theme(id: "wisdom",    emoji: "💡", label: "지혜"),
        Theme(id: "gratitude", emoji: "🙏", label: "감사"),
        Theme(id: "strength",  emoji: "💪", label: "힘"),
        Theme(id: "renewal",   emoji: "✨", label: "회복"),
        Theme(id: "comfort",   emoji: "🤍", label: "위로"),
        Theme(id: "hope",      emoji: "🌱", label: "소망"),
    ]
}
