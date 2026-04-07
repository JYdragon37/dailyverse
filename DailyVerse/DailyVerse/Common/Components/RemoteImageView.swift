import SwiftUI

/// 원격 이미지 뷰 — 생성 즉시 disk cache 확인 → 첫 렌더에 이미지 표시 (플래시 0)
///
/// 핵심 원리: ImageLoader를 url과 함께 초기화 → init()에서 disk cache 확인
/// → image가 이미 set된 상태로 첫 render → placeholder 표시 없음
struct RemoteImageView<Placeholder: View>: View {
    let url: URL
    let placeholder: () -> Placeholder

    // ImageLoader를 url과 함께 초기화 — init()에서 disk cache 확인
    @StateObject private var loader: ImageLoader

    init(url: URL, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
        // StateObject wrappedValue는 첫 렌더 전에 실행됨
        // → ImageLoader(url:) init에서 disk cache hit 시 image 즉시 세팅
        _loader = StateObject(wrappedValue: ImageLoader(initialURL: url))
    }

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

    /// URL과 함께 초기화 — disk cache hit 시 image를 즉시 세팅
    /// → 첫 render 시 image가 이미 있어서 placeholder 표시 없음
    init(initialURL: URL) {
        if let cached = ImageDiskCache.shared.load(for: initialURL) {
            self.image = cached
            self.loadingURL = initialURL
        }
    }

    func load(url: URL) {
        guard url != loadingURL else { return }
        loadingURL = url

        // disk cache hit → 즉시 세팅 (image = nil 거치지 않음)
        if let cached = ImageDiskCache.shared.load(for: url) {
            image = cached
            return
        }

        // disk cache miss → 다운로드
        image = nil
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

    private let memoryCache = NSCache<NSString, UIImage>()

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

    func save(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.setObject(image, forKey: key as NSString)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filePath = cacheDir.appendingPathComponent(key)
        try? data.write(to: filePath, options: .atomic)
    }

    func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

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
