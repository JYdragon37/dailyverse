import SwiftUI
import Combine
import Network
import UIKit

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

        // Stage 2-d: 현재 Zone 배경 이미지 pre-load → HomeView 진입 시 즉시 표시
        await preloadZoneBackground()

        state = .ready
    }

    // MARK: - Connectivity

    /// NWPathMonitor를 이용해 현재 네트워크 상태를 단발성으로 확인한다.
    /// 경로 상태가 `.satisfied`가 아니면 오프라인으로 판단한다.
    /// 현재 Zone 배경 이미지를 disk cache에 미리 저장
    /// HomeView 진입 시 RemoteImageView가 cache hit → 즉시 표시 (flash 없음)
    private func preloadZoneBackground() async {
        let mode = AppMode.current()
        guard let bg = try? await FirestoreService().fetchBackgroundImage(for: mode),
              let url = URL(string: bg.storageUrl) else { return }

        // 이미 disk cache에 있으면 스킵
        guard ImageDiskCache.shared.load(for: url) == nil else { return }

        // disk cache 없으면 다운로드 후 저장
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let image = UIImage(data: data) else { return }

        ImageDiskCache.shared.save(image, for: url)
    }

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
