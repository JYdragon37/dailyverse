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
    /// 강제 업데이트 팝업 표시 여부
    @Published var showForceUpdate: Bool = false

    /// 스플래시 중 미리 로드된 Zone 배경 이미지
    /// AppRootView 베이스 레이어에서 사용 → 스플래시 종료 즉시 올바른 이미지 표시
    @Published var zoneBgImage: UIImage? = nil
    @Published var zoneBgUrl: URL? = nil
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
        // Stage 0: 고아 알림 정리 — 삭제된 알람의 UNNotification 잔존 방지
        NotificationManager.shared.cleanupOrphanedNotifications()

        // ★ 콜드 스타트 시 DailyVerseCache 초기화
        // 목적: 이전 세션의 잘못된 todayVerseId(알고리즘 결과 등)가 남아있을 경우
        //       source:.server 실패 시 stale 캐시가 반환되는 순환 차단
        // 효과: hasCached=false → non-cached 경로 → checkForceUpdate() → Firestore SDK 연결 확보
        //       → fetchTodayVerseId(source:.server) 성공률 보장
        // 주의: 매 콜드 스타트마다 Firestore에서 오늘의 말씀을 재확인 (필수)
        cacheManager.clearCache()

        // Stage 2 캐시 확인 — clearCache() 후이므로 항상 false (non-cached 경로 강제)
        let hasCached = cacheManager.hasValidCache()

        // Stage 1: 스플래시
        // - 캐시 히트(재방문): 1.0초 (애니메이션 Phase1~3 = 1.12s 이내 완료)
        // - 캐시 미스(첫 방문): 1.5초 (로딩 인디케이터 표시 여유)
        let splashDuration: UInt64 = hasCached ? 1_000_000_000 : 1_500_000_000
        try? await Task.sleep(nanoseconds: splashDuration)
        state = .loading

        // Stage 2: 배경 이미지 비동기 로드
        async let zoneLoad: Void = loadZoneBackground()
        async let goldenLoad: Void = loadFixedBackground(mode: .windDown, assign: { self.windDownBgImage = $0 })
        _ = await (zoneLoad, goldenLoad)

        // Stage 3: clearCache() 후 hasCached는 항상 false — 이 블록은 실행되지 않음
        // (콜드 스타트 캐시 초기화로 항상 non-cached 경로 사용)
        if hasCached {
            _ = try? await verseRepository.fetchVerses()
            let mode = AppMode.current()
            let cachedWeather = WeatherCacheManager().load()
            _ = await verseRepository.currentVerse(for: mode, weather: cachedWeather)
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

        // Stage 4-b: 강제 업데이트 확인 (오프라인이 아닌 경우에만)
        await checkForceUpdate()

        // Stage 5: Firestore 말씀 프리로드 + 오늘 말씀 캐싱
        // ⚠️ 이 단계가 완료된 후 state = .ready가 되므로
        //    홈/묵상/알람 탭이 모두 동일한 캐시를 읽어 같은 말씀을 표시한다.
        _ = try? await verseRepository.fetchVerses()
        let mode = AppMode.current()
        let cachedWeather = WeatherCacheManager().load()
        _ = await verseRepository.currentVerse(for: mode, weather: cachedWeather)

        state = .ready
    }

    // MARK: - 강제 업데이트 확인

    /// Firestore app_config/minimum_version과 현재 앱 버전을 비교해 강제 업데이트 여부 결정
    private func checkForceUpdate() async {
        let (minVersion, forceUpdate) = await FirestoreService().fetchMinimumVersion()
        guard forceUpdate else { return }
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        if isVersionBelow(current, minimum: minVersion) {
            showForceUpdate = true
        }
    }

    /// 버전 비교: current가 minimum 미만이면 true
    private func isVersionBelow(_ current: String, minimum: String) -> Bool {
        let cur = current.split(separator: ".").compactMap { Int($0) }
        let min = minimum.split(separator: ".").compactMap { Int($0) }
        for i in 0..<Swift.max(cur.count, min.count) {
            let c = i < cur.count ? cur[i] : 0
            let m = i < min.count ? min[i] : 0
            if c < m { return true }
            if c > m { return false }
        }
        return false
    }

    // MARK: - Zone Background 로드

    /// 현재 Zone 배경 이미지를 메모리(zoneBgImage)에 로드
    /// 1. disk cache hit → 즉시 메모리에 세팅
    /// 2. miss → 다운로드 → disk 저장 → 메모리에 세팅
    // UserDefaults 키 — Zone별 마지막 배경 URL 캐싱 (Firestore 반복 호출 제거)
    private static let bgUrlCacheKeyPrefix = "zoneBgUrl_v2_"

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
            let queue = DispatchQueue(label: "com.morningmanna.app.connectivity-check")
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status != .satisfied)
            }
            monitor.start(queue: queue)
        }
    }
}
