import SwiftUI
import Combine
import Network
import UIKit

@MainActor
final class AppLoadingCoordinator: ObservableObject {

    // MARK: - Loading State

    enum LoadingState {
        case splash
        case loading
        case ready
    }

    // MARK: - Published

    @Published var state: LoadingState = .splash
    @Published var isOffline: Bool = false

    /// 스플래시 중 미리 로드된 Zone 배경 이미지
    /// AppRootView 베이스 레이어에서 사용 → 스플래시 종료 즉시 올바른 이미지 표시
    @Published var zoneBgImage: UIImage? = nil
    @Published var zoneBgUrl: URL? = nil

    // MARK: - Dependencies

    private let verseRepository: VerseRepository
    private let cacheManager: DailyCacheManager

    init(
        verseRepository: VerseRepository = VerseRepository(),
        cacheManager: DailyCacheManager = .shared
    ) {
        self.verseRepository = verseRepository
        self.cacheManager = cacheManager
    }

    // MARK: - Start

    func start() async {
        // Stage 1: 스플래시
        try? await Task.sleep(nanoseconds: 2_800_000_000)
        state = .loading

        // Stage 2-a: Zone 배경 이미지를 메모리에 로드 (항상 실행)
        // → AppRootView 베이스 레이어가 즉시 표시 → HomeView 전환 시 플래시 0
        await loadZoneBackground()

        // Stage 2-b: 유효 캐시 있으면 즉시 ready
        if cacheManager.hasValidCache() {
            state = .ready
            return
        }

        // Stage 2-c: 오프라인 확인
        let offline = await checkConnectivity()
        if offline {
            isOffline = true
            state = .ready
            return
        }

        // Stage 2-d: Firestore 말씀 로드
        _ = try? await verseRepository.fetchVerses()

        state = .ready
    }

    // MARK: - Zone Background 로드

    /// 현재 Zone 배경 이미지를 메모리(zoneBgImage)에 로드
    /// 1. disk cache hit → 즉시 메모리에 세팅
    /// 2. miss → 다운로드 → disk 저장 → 메모리에 세팅
    private func loadZoneBackground() async {
        let mode = AppMode.current()
        guard let bg = try? await FirestoreService().fetchBackgroundImage(for: mode),
              let url = URL(string: bg.storageUrl) else { return }

        zoneBgUrl = url

        // Disk cache hit → 즉시 메모리에 로드
        if let cached = ImageDiskCache.shared.load(for: url) {
            zoneBgImage = cached
            return
        }

        // Disk cache miss → 다운로드
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let image = UIImage(data: data) else { return }

        ImageDiskCache.shared.save(image, for: url)
        zoneBgImage = image
    }

    // MARK: - Connectivity

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
