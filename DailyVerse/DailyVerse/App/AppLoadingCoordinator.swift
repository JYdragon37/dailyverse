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
    @Published var zone4BgImage: UIImage? = nil
    @Published var windDownBgImage: UIImage? = nil

    // MARK: - Dependencies

    private let verseRepository: VerseRepository
    private let cacheManager: DailyCacheManager

    init(
        verseRepository: VerseRepository = VerseRepository.shared,
        cacheManager: DailyCacheManager = .shared
    ) {
        self.verseRepository = verseRepository
        self.cacheManager = cacheManager
    }

    // MARK: - Start

    func start() async {
        // Stage 1: 스플래시 (0.8초 — 애니메이션 완료 최소 시간)
        try? await Task.sleep(nanoseconds: 800_000_000)
        state = .loading

        // Stage 2: 캐시 확인 (동기, @MainActor 안에서 직접 호출)
        // + 배경 이미지 비동기 로드
        let hasCached = cacheManager.hasValidCache()
        async let zoneLoad: Void = loadZoneBackground()
        async let zone4Load: Void = loadFixedBackground(mode: .peakMode, assign: { self.zone4BgImage = $0 })
        async let goldenLoad: Void = loadFixedBackground(mode: .windDown, assign: { self.windDownBgImage = $0 })
        _ = await (zoneLoad, zone4Load, goldenLoad)

        // Stage 3: 유효 캐시 있으면 메모리 캐시만 복원 후 ready
        // (앱 재시작 시 VerseRepository.cachedVerses가 비워짐 → Home/Meditation 경쟁 조건 방지)
        if hasCached {
            _ = try? await verseRepository.fetchVerses()
            state = .ready
            return
        }

        // Stage 4: 오프라인 확인
        let offline = await checkConnectivity()
        if offline {
            isOffline = true
            state = .ready
            return
        }

        // Stage 5: Firestore 말씀 프리로드 + 오늘 말씀 캐싱
        // ⚠️ 이 단계가 완료된 후 state = .ready가 되므로
        //    홈/묵상/알람 탭이 모두 동일한 캐시를 읽어 같은 말씀을 표시한다.
        _ = try? await verseRepository.fetchVerses()
        let mode = AppMode.current()
        let cachedWeather = WeatherCacheManager().load()
        _ = await verseRepository.currentVerse(for: mode, weather: cachedWeather)

        state = .ready
    }

    // MARK: - Zone Background 로드

    /// 현재 Zone 배경 이미지를 메모리(zoneBgImage)에 로드
    /// 1. disk cache hit → 즉시 메모리에 세팅
    /// 2. miss → 다운로드 → disk 저장 → 메모리에 세팅
    // UserDefaults 키 — Zone별 마지막 배경 URL 캐싱 (Firestore 반복 호출 제거)
    private static let bgUrlCacheKeyPrefix = "zoneBgUrl_"

    private func loadZoneBackground() async {
        let mode = AppMode.current()
        let cacheKey = Self.bgUrlCacheKeyPrefix + mode.rawValue

        // 1. UserDefaults에서 이전 URL 먼저 확인 (Firestore 호출 없이 즉시)
        var url: URL?
        if let cachedUrlStr = UserDefaults.standard.string(forKey: cacheKey),
           let cachedUrl = URL(string: cachedUrlStr) {
            url = cachedUrl
        }

        // 2. 디스크 캐시 히트 → 즉시 메모리에 세팅 (가장 빠른 경로)
        if let u = url, let cached = ImageDiskCache.shared.load(for: u) {
            zoneBgUrl = u
            zoneBgImage = cached
            // 백그라운드에서 URL 갱신 (화면은 이미 표시됨)
            Task { await refreshBgUrl(for: mode, cacheKey: cacheKey) }
            return
        }

        // 3. Firestore에서 URL 가져오기 (날씨 캐시 참조, 없으면 "all" fallback)
        let cachedCondition = WeatherCacheManager().load()?.condition ?? "all"
        var bgCandidates = (try? await FirestoreService().fetchBackgroundImages(for: mode, weatherCondition: cachedCondition)) ?? []
        if bgCandidates.isEmpty {
            bgCandidates = (try? await FirestoreService().fetchBackgroundImages(for: mode, weatherCondition: "all")) ?? []
        }
        guard let bg = bgCandidates.randomElement(),
              let freshUrl = URL(string: bg.storageUrl) else { return }

        url = freshUrl
        zoneBgUrl = freshUrl
        UserDefaults.standard.set(freshUrl.absoluteString, forKey: cacheKey)

        // 4. 이미지 다운로드
        if let cached = ImageDiskCache.shared.load(for: freshUrl) {
            zoneBgImage = cached
            return
        }
        var request = URLRequest(url: freshUrl, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let image = UIImage(data: data) else { return }
        ImageDiskCache.shared.save(image, for: freshUrl)
        zoneBgImage = image
    }

    /// 특정 Zone 배경 이미지 로드 — ONBExperienceView 고정 카드용
    private func loadFixedBackground(mode: AppMode, assign: @MainActor @escaping (UIImage) -> Void) async {
        if AppMode.current() == mode, let img = zoneBgImage {
            assign(img); return
        }
        let cacheKey = Self.bgUrlCacheKeyPrefix + mode.rawValue
        if let str = UserDefaults.standard.string(forKey: cacheKey),
           let u = URL(string: str),
           let cached = ImageDiskCache.shared.load(for: u) {
            assign(cached); return
        }
        let candidates = (try? await FirestoreService().fetchBackgroundImages(for: mode, weatherCondition: "all")) ?? []
        guard let bg = candidates.randomElement(),
              let freshUrl = URL(string: bg.storageUrl) else { return }
        UserDefaults.standard.set(freshUrl.absoluteString, forKey: cacheKey)
        if let cached = ImageDiskCache.shared.load(for: freshUrl) {
            assign(cached); return
        }
        var request = URLRequest(url: freshUrl, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let image = UIImage(data: data) else { return }
        ImageDiskCache.shared.save(image, for: freshUrl)
        assign(image)
    }

    /// 백그라운드에서 URL만 최신화 (이미지는 이미 표시 중)
    private func refreshBgUrl(for mode: AppMode, cacheKey: String) async {
        let cachedCondition = WeatherCacheManager().load()?.condition ?? "all"
        let candidates = (try? await FirestoreService().fetchBackgroundImages(for: mode, weatherCondition: cachedCondition)) ?? []
        guard let bg = candidates.randomElement(),
              let url = URL(string: bg.storageUrl) else { return }
        UserDefaults.standard.set(url.absoluteString, forKey: cacheKey)
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
