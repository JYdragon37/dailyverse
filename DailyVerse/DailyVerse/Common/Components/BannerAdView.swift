import SwiftUI
import GoogleMobileAds

// MARK: - AdMob 배너 광고 (Medium Rectangle 300×250)
// Ad Unit ID: Secrets.xcconfig → Info.plist → Bundle 순으로 읽음

struct BannerAdView: UIViewRepresentable {

    private let adUnitID = Bundle.main.infoDictionary?["ADMOB_BANNER_ID"] as? String
        ?? "ca-app-pub-3940256099942544/2934735716"  // xcconfig 누락 시 테스트 ID 폴백

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeMediumRectangle)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    static func dismantleUIView(_ uiView: GADBannerView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}

// MARK: - AdMob 스마트 배너 (320×50) — 리스트/좁은 영역용

struct SmartBannerAdView: UIViewRepresentable {

    private let adUnitID = Bundle.main.infoDictionary?["ADMOB_BANNER_ID"] as? String
        ?? "ca-app-pub-3940256099942544/2934735716"  // xcconfig 누락 시 테스트 ID 폴백

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)  // 320×50
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    static func dismantleUIView(_ uiView: GADBannerView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}
