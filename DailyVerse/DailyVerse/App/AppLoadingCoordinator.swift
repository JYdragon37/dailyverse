import SwiftUI
import Combine
import Network

@MainActor
final class AppLoadingCoordinator: ObservableObject {

    // MARK: - Loading State

    enum LoadingState {
        /// Stage 1: 스플래시 0.8초
        case splash
        /// Stage 2: 데이터 로드 (스켈레톤 or 스플래시 유지)
        case loading
        /// Stage 3: 준비 완료 → 온보딩/홈 전환
        case ready
    }

    // MARK: - Published

    @Published var state: LoadingState = .splash
    @Published var isOffline: Bool = false

    // MARK: - Dependencies

    private let verseRepository: VerseRepository
    private let cacheManager: DailyCacheManager

    // MARK: - Init

    init(
        verseRepository: VerseRepository = VerseRepository(),
        cacheManager: DailyCacheManager = .shared
    ) {
        self.verseRepository = verseRepository
        self.cacheManager = cacheManager
    }

    // MARK: - Start

    /// 앱 진입 시 호출. 스플래시 → 로딩 → 준비 완료 순으로 상태를 전이한다.
    func start() async {
        // Stage 1: 스플래시 2.8초 대기 (+2초 추가)
        try? await Task.sleep(nanoseconds: 2_800_000_000)
        state = .loading

        // Stage 2-a: 오늘 날짜 기준 유효 캐시가 있으면 네트워크 호출 없이 즉시 ready
        if cacheManager.hasValidCache() {
            state = .ready
            return
        }

        // Stage 2-b: 오프라인 확인
        let offline = await checkConnectivity()
        if offline {
            isOffline = true
            state = .ready
            return
        }

        // Stage 2-c: Firestore에서 최신 말씀 로드 (실패해도 폴백으로 ready)
        _ = try? await verseRepository.fetchVerses()
        state = .ready
    }

    // MARK: - Connectivity

    /// NWPathMonitor를 이용해 현재 네트워크 상태를 단발성으로 확인한다.
    /// 경로 상태가 `.satisfied`가 아니면 오프라인으로 판단한다.
    private func checkConnectivity() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.dailyverse.connectivity-check")
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status != .satisfied)
            }
            monitor.start(queue: queue)
        }
    }
}
