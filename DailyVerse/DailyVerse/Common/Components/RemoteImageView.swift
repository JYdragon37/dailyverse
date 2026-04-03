import SwiftUI

/// Genspark URL 등 AsyncImage가 실패하는 URL을 처리하는 커스텀 이미지 로더.
/// - DEBUG: SSL 인증서 검증 우회 (Genspark 자체 서명 인증서 대응)
/// - RELEASE: URLSession.shared (정상 인증서 검증)
struct RemoteImageView<Placeholder: View>: View {
    let url: URL
    let placeholder: () -> Placeholder

    @StateObject private var loader: ImageLoader = ImageLoader()

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

@MainActor
private final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var loadingURL: URL?

    func load(url: URL) {
        guard url != loadingURL else { return }
        loadingURL = url
        image = nil

        Task { [weak self] in
            let downloaded = await Self.download(url: url)
            self?.image = downloaded
        }
    }

    private static func download(url: URL) async -> UIImage? {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("image/webp,image/png,image/jpeg,*/*", forHTTPHeaderField: "Accept")

        // DEBUG: Genspark SSL 인증서 검증 우회 (실제 기기 포함)
        // Genspark API는 자체 서명 인증서를 사용하여 iOS가 검증 실패함
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
                  let image = UIImage(data: data) else {
                #if DEBUG
                print("🖼️ [RemoteImage] 응답 오류: \(url.lastPathComponent)")
                #endif
                return nil
            }
            #if DEBUG
            print("🖼️ [RemoteImage] 로드 성공: \(url.lastPathComponent) (\(data.count / 1024)KB)")
            #endif
            return image
        } catch {
            #if DEBUG
            print("🖼️ [RemoteImage] 실패: \(url.lastPathComponent) — \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}

// MARK: - SSL Bypass Delegate (DEBUG only)

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
