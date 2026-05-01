import SwiftUI
import GoogleMobileAds

// MARK: - Ad Unit ID

private func nativeAdUnitID() -> String {
    #if DEBUG
    return "ca-app-pub-3940256099942544/3986624511"  // Google 공식 테스트 Native ID
    #else
    return Bundle.main.infoDictionary?["ADMOB_NATIVE_ID"] as? String
        ?? "ca-app-pub-3940256099942544/3986624511"
    #endif
}

// MARK: - NativeAdPool
// 여러 광고 슬롯을 위한 독립 GADAdLoader 풀
// 4개 말씀카드마다 1개 슬롯 → 저장 목록 최대 20개 기준 최대 5개 사전 로드

@MainActor
final class NativeAdPool: NSObject, ObservableObject {

    @Published var ads: [GADNativeAd] = []

    private var loaders: [GADAdLoader] = []
    private var delegates: [NativeAdDelegate] = []

    func load(count: Int, rootViewController: UIViewController? = nil) {
        let id = nativeAdUnitID()
        let vc = rootViewController ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        for _ in 0..<count {
            let delegate = NativeAdDelegate { [weak self] ad in
                self?.ads.append(ad)
            }
            let loader = GADAdLoader(
                adUnitID: id,
                rootViewController: vc,
                adTypes: [.native],
                options: nil
            )
            loader.delegate = delegate
            loader.load(GADRequest())
            loaders.append(loader)
            delegates.append(delegate)
        }
    }
}

// MARK: - NativeAdDelegate (per-loader delegate)

private final class NativeAdDelegate: NSObject, GADNativeAdLoaderDelegate {
    private let onReceive: @MainActor (GADNativeAd) -> Void

    init(onReceive: @MainActor @escaping (GADNativeAd) -> Void) {
        self.onReceive = onReceive
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        Task { @MainActor in self.onReceive(nativeAd) }
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        // 로드 실패 시 슬롯 미표시 (광고 없이 빈 공간 생략)
    }
}

// MARK: - NativeAdCardView
// 저장탭 그리드에 삽입되는 전폭 네이티브 광고 카드

struct NativeAdCardView: UIViewRepresentable {

    let nativeAd: GADNativeAd

    func makeUIView(context: Context) -> GADNativeAdView {
        let adView = GADNativeAdView()
        setupSubviews(adView)
        return adView
    }

    func updateUIView(_ adView: GADNativeAdView, context: Context) {
        populate(adView: adView, ad: nativeAd)
        adView.nativeAd = nativeAd
    }

    // MARK: - Layout 구성

    private func setupSubviews(_ adView: GADNativeAdView) {
        adView.backgroundColor = UIColor(red: 0.11, green: 0.09, blue: 0.08, alpha: 1) // dvBgSurface

        // ── 광고 배지 ─────────────────────────────────────────────
        let badge = UILabel()
        badge.text = "광고"
        badge.font = .systemFont(ofSize: 10, weight: .semibold)
        badge.textColor = UIColor(white: 1, alpha: 0.45)
        badge.backgroundColor = UIColor(white: 1, alpha: 0.12)
        badge.layer.cornerRadius = 3
        badge.layer.masksToBounds = true
        badge.textAlignment = .center
        badge.tag = 1001

        // ── 미디어 뷰 ────────────────────────────────────────────
        let mediaView = GADMediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 8
        mediaView.tag = 1002

        // ── 아이콘 ───────────────────────────────────────────────
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 6
        iconView.tag = 1003

        // ── 헤드라인 ─────────────────────────────────────────────
        let headline = UILabel()
        headline.font = .systemFont(ofSize: 14, weight: .semibold)
        headline.textColor = UIColor(white: 1, alpha: 0.9)
        headline.numberOfLines = 1
        headline.tag = 1004

        // ── 바디 ─────────────────────────────────────────────────
        let body = UILabel()
        body.font = .systemFont(ofSize: 12, weight: .regular)
        body.textColor = UIColor(white: 1, alpha: 0.5)
        body.numberOfLines = 2
        body.tag = 1005

        // ── CTA 버튼 ──────────────────────────────────────────────
        let cta = UIButton(type: .system)
        cta.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        cta.setTitleColor(.black, for: .normal)
        cta.backgroundColor = UIColor(red: 0.72, green: 0.52, blue: 0.18, alpha: 1) // dvAccentGold
        cta.layer.cornerRadius = 8
        cta.tag = 1006

        // adView 서브뷰 등록
        [mediaView, badge, iconView, headline, body, cta].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            adView.addSubview($0)
        }

        // ── AutoLayout ───────────────────────────────────────────
        NSLayoutConstraint.activate([
            // 미디어 (전폭, 16:9 비율)
            mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.heightAnchor.constraint(equalTo: adView.widthAnchor, multiplier: 9/16),

            // 광고 배지 (우상단)
            badge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            badge.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            badge.widthAnchor.constraint(equalToConstant: 30),
            badge.heightAnchor.constraint(equalToConstant: 16),

            // 아이콘 (미디어 아래 왼쪽)
            iconView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            // 헤드라인 (아이콘 오른쪽)
            headline.topAnchor.constraint(equalTo: iconView.topAnchor),
            headline.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -14),

            // 바디
            body.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 3),
            body.leadingAnchor.constraint(equalTo: headline.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: headline.trailingAnchor),

            // CTA 버튼
            cta.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 14),
            cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -14),
            cta.heightAnchor.constraint(equalToConstant: 36),
            cta.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -14),
        ])

        // adView 아웃렛 연결
        adView.mediaView      = mediaView
        adView.iconView       = iconView
        adView.headlineView   = headline
        adView.bodyView       = body
        adView.callToActionView = cta
    }

    private func populate(adView: GADNativeAdView, ad: GADNativeAd) {
        (adView.headlineView as? UILabel)?.text     = ad.headline
        (adView.bodyView    as? UILabel)?.text      = ad.body
        (adView.callToActionView as? UIButton)?.setTitle(ad.callToAction, for: .normal)
        (adView.iconView as? UIImageView)?.image    = ad.icon?.image
        adView.mediaView?.mediaContent              = ad.mediaContent
        adView.iconView?.isHidden                   = (ad.icon == nil)
    }
}

// MARK: - NativeAdPlaceholder
// 광고 아직 로드 중일 때 표시하는 스켈레톤

struct NativeAdPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.05))
            .overlay(
                Text("광고 로드 중...")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
            )
            .frame(height: 180)
    }
}
