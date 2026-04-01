import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - UserDefaults (4키 + 보조 키)

    @AppStorage(OnboardingKey.completed.rawValue) var onboardingCompleted = false
    @AppStorage(OnboardingKey.locationRequested.rawValue) var locationPermissionRequested = false
    @AppStorage(OnboardingKey.notificationRequested.rawValue) var notificationPermissionRequested = false
    @AppStorage(OnboardingKey.firstAlarmShown.rawValue) var firstAlarmPromptShown = false

    /// 스킵 지점 재개용: 마지막으로 진입했던 페이지 인덱스 (0~4)
    @AppStorage("onboardingCurrentPage") private var savedPage: Int = 0

    // MARK: - Published

    @Published var currentPage: Int = 0
    @Published var skipCount: Int = 0

    // MARK: - Pages (0=웰컴 1=첫말씀 2=위치 3=알림 4=첫알람)
    static let totalPages = 5

    // MARK: - Dependencies

    private let permissionManager: PermissionManager

    // MARK: - Init

    init() {
        self.permissionManager = PermissionManager()
        // 온보딩 미완료 상태에서 앱 재진입 시 스킵했던 페이지부터 재개
        if !onboardingCompleted {
            currentPage = savedPage
        }
    }

    // MARK: - Navigation

    /// 다음 페이지로 이동. 마지막 페이지(4)에서 호출하면 온보딩을 완료한다.
    func next() {
        if currentPage < OnboardingViewModel.totalPages - 1 {
            currentPage += 1
            savedPage = currentPage
        } else {
            complete()
        }
    }

    /// 현재 화면을 건너뛴다. 3회 누적 시 온보딩 강제 완료.
    func skip() {
        skipCount += 1
        if skipCount >= 3 {
            complete()
        } else {
            next()
        }
    }

    /// 온보딩을 완료 처리하고 저장된 페이지 인덱스를 초기화한다.
    func complete() {
        onboardingCompleted = true
        savedPage = 0
    }

    // MARK: - Permission Requests

    /// Screen 3: 위치 권한 요청 (온보딩 전용 래퍼)
    func requestLocation() async {
        locationPermissionRequested = true
        await permissionManager.requestLocationPermission()
    }

    /// Screen 4: 알림 권한 요청 (온보딩 전용 래퍼)
    func requestNotification() async {
        notificationPermissionRequested = true
        await permissionManager.requestNotificationPermission()
    }

    // MARK: - First Alarm

    /// Screen 5: 첫 알람 프롬프트 노출 기록
    func markFirstAlarmShown() {
        firstAlarmPromptShown = true
    }
}

// MARK: - Preview

#Preview {
    // OnboardingViewModel 단독 미리보기: 상태 확인용 간단 뷰
    let vm = OnboardingViewModel()
    return VStack(spacing: 16) {
        Text("OnboardingViewModel Preview")
            .font(.headline)
        Text("currentPage: \(vm.currentPage)")
        Text("skipCount: \(vm.skipCount)")
        Text("completed: \(vm.onboardingCompleted.description)")
        HStack(spacing: 12) {
            Button("Next") { vm.next() }
                .buttonStyle(.bordered)
            Button("Skip") { vm.skip() }
                .buttonStyle(.bordered)
            Button("Reset") {
                vm.onboardingCompleted = false
                vm.skipCount = 0
                vm.currentPage = 0
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }
    .padding()
}
