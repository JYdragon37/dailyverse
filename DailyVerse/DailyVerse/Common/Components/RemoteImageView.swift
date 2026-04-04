import SwiftUI

/// 원격 이미지 뷰 — 디스크 캐시 우선 로딩
///
/// 동작 순서:
/// 1. 디스크 캐시 확인 → 있으면 즉시 표시 (0ms, 플래시 없음)
/// 2. 없으면 다운로드 → 디스크에 저장 → 표시
/// 3. 이후 앱 재실행 시 디스크에서 즉시 로딩
struct RemoteImageView<Placeholder: View>: View {
    let url: URL
    let placeholder: () -> Placeholder

    @StateObject private var loader = ImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                placeholder()
            }
        }
        .onAppear { loader.load(url: url) }
        .onChange(of: url) { loader.load(url: $0) }
    }
}

// MARK: - ImageLoader

@MainActor
private final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var loadingURL: URL?

    func load(url: URL) {
        guard url != loadingURL else { return }
        loadingURL = url
        image = nil

        // 1. 디스크 캐시 확인 → 있으면 즉시 표시 (플래시 없음)
        if let cached = ImageDiskCache.shared.load(for: url) {
            image = cached
            return
        }

        // 2. 디스크에 없으면 다운로드
        Task { [weak self] in
            let downloaded = await Self.download(url: url)
            if let img = downloaded {
                ImageDiskCache.shared.save(img, for: url)
            }
            self?.image = downloaded
        }
    }

    private static func download(url: URL) async -> UIImage? {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("image/webp,image/png,image/jpeg,*/*", forHTTPHeaderField: "Accept")

        #if DEBUG
        let session = URLSession(
            configuration: .default,
            delegate: _SSLBypassDelegate(),
            delegateQueue: nil
        )
        #else
        let session = URLSession.shared
        #endif

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else { return nil }
            return image
        } catch {
            return nil
        }
    }
}

// MARK: - 디스크 이미지 캐시

final class ImageDiskCache {
    static let shared = ImageDiskCache()

    // 메모리 캐시 (앱 실행 중 반복 접근 시 디스크 I/O 생략)
    private let memoryCache = NSCache<NSString, UIImage>()

    // 디스크 캐시 디렉터리: Caches/DailyVerseImages/ (iOS가 스토리지 부족 시 자동 정리)
    private let cacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("DailyVerseImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {
        memoryCache.countLimit = 30
        memoryCache.totalCostLimit = 100 * 1024 * 1024  // 100MB
    }

    // MARK: - Load

    func load(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)

        // 1. 메모리 캐시
        if let img = memoryCache.object(forKey: key as NSString) {
            return img
        }

        // 2. 디스크 캐시
        let filePath = cacheDir.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let img = UIImage(data: data) else { return nil }

        memoryCache.setObject(img, forKey: key as NSString, cost: data.count)
        return img
    }

    // MARK: - Save

    func save(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.setObject(image, forKey: key as NSString)

        // JPEG 80% 품질로 디스크 저장 (용량 절약)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filePath = cacheDir.appendingPathComponent(key)
        try? data.write(to: filePath, options: .atomic)
    }

    // MARK: - 캐시 초기화

    func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Helper

    private func cacheKey(for url: URL) -> String {
        var hasher = Hasher()
        hasher.combine(url.absoluteString)
        let hash = abs(hasher.finalize())
        return "\(hash).jpg"
    }
}

// MARK: - SSL Bypass (DEBUG only)

#if DEBUG
private final class _SSLBypassDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
#endif
