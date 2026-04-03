import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - UserDefaults (v5.1: 5키)

    @AppStorage(OnboardingKey.completed.rawValue) var onboardingCompleted = false
    @AppStorage(OnboardingKey.nicknameSet.rawValue) var nicknameSet = false   // v5.1 신규
    @AppStorage(OnboardingKey.locationRequested.rawValue) var locationPermissionRequested = false
    @AppStorage(OnboardingKey.notificationRequested.rawValue) var notificationPermissionRequested = false
    @AppStorage(OnboardingKey.firstAlarmShown.rawValue) var firstAlarmPromptShown = false

    /// 스킵 지점 재개용
    @AppStorage("onboardingCurrentPage") private var savedPage: Int = 0

    // MARK: - Published

    @Published var currentPage: Int = 0
    @Published var skipCount: Int = 0
    @Published var nicknameInput: String = ""  // v5.1: 닉네임 입력값

    // MARK: - Pages (v5.1: 0=웰컴 1=닉네임 2=첫말씀 3=위치 4=알림 5=첫알람)
    static let totalPages = 6

    // MARK: - Dependencies

    private let permissionManager: PermissionManager

    // MARK: - Init

    init() {
        self.permissionManager = PermissionManager()
        if !onboardingCompleted {
            currentPage = savedPage
        }
        // 기존 닉네임 불러오기
        nicknameInput = NicknameManager.shared.nickname == "친구" ? "" : NicknameManager.shared.nickname
    }

    // MARK: - Navigation

    func next() {
        if currentPage < OnboardingViewModel.totalPages - 1 {
            currentPage += 1
            savedPage = currentPage
        } else {
            complete()
        }
    }

    func skip() {
        skipCount += 1
        if skipCount >= 3 {
            complete()
        } else {
            next()
        }
    }

    func complete() {
        // 닉네임 미입력 시 "친구" 기본값으로 저장
        let finalNickname = nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await NicknameManager.shared.setNickname(finalNickname.isEmpty ? "친구" : finalNickname)
        }
        onboardingCompleted = true
        savedPage = 0
    }

    // MARK: - Nickname

    /// Screen 2: 닉네임 저장
    func saveNickname() {
        let trimmed = nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        nicknameSet = true
        Task {
            await NicknameManager.shared.setNickname(trimmed.isEmpty ? "친구" : trimmed)
        }
    }

    // MARK: - Permission Requests

    func requestLocation() async {
        locationPermissionRequested = true
        await permissionManager.requestLocationPermission()
    }

    func requestNotification() async {
        notificationPermissionRequested = true
        await permissionManager.requestNotificationPermission()
    }

    func markFirstAlarmShown() {
        firstAlarmPromptShown = true
    }
}

#Preview {
    let vm = OnboardingViewModel()
    return VStack(spacing: 16) {
        Text("OnboardingViewModel Preview").font(.headline)
        Text("currentPage: \(vm.currentPage)")
        Text("skipCount: \(vm.skipCount)")
        Text("completed: \(vm.onboardingCompleted.description)")
        HStack(spacing: 12) {
            Button("Next") { vm.next() }.buttonStyle(.bordered)
            Button("Skip") { vm.skip() }.buttonStyle(.bordered)
            Button("Reset") {
                vm.onboardingCompleted = false; vm.skipCount = 0; vm.currentPage = 0
            }.buttonStyle(.bordered).tint(.red)
        }
    }.padding()
}
