import SwiftUI
import GoogleMobileAds

// MARK: - AdMob 배너 광고 (Medium Rectangle 300×250)
// TODO: 프로덕션 배포 전 실제 Ad Unit ID로 교체
// 현재: AdMob 테스트 ID (실제 광고 미게재)
// 실제 ID 예시: "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"

struct BannerAdView: UIViewRepresentable {

    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"  // 테스트 ID

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
// TODO: 프로덕션 배포 전 실제 Ad Unit ID로 교체

struct SmartBannerAdView: UIViewRepresentable {

    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"  // 테스트 ID

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
