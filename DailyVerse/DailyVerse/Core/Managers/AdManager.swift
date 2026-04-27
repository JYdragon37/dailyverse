import SwiftUI
import Combine
import GoogleMobileAds
import FirebaseAnalytics

// Ad Unit ID — Secrets.xcconfig → Info.plist → Bundle 순으로 읽음
// xcconfig에 값이 없으면 Google 공식 테스트 ID로 폴백
private let kRewardedAdUnitID     = Bundle.main.infoDictionary?["ADMOB_REWARDED_ID"] as? String
    ?? "ca-app-pub-3940256099942544/1712485313"
private let kInterstitialAdUnitID = Bundle.main.infoDictionary?["ADMOB_INTERSTITIAL_ID"] as? String
    ?? "ca-app-pub-3940256099942544/4411468910"

@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    // MARK: - Rewarded
    @Published var isAdLoading: Bool = false
    @Published var isAdReady: Bool = false

    private var rewardedAd: GADRewardedAd?

    // MARK: - Interstitial
    @Published var isInterstitialReady: Bool = false

    private var interstitialAd: GADInterstitialAd?
    private var interstitialCoordinator: InterstitialCoordinator?

    private init() {}

    // MARK: - Rewarded 광고 로드

    func loadAd() {
        guard !isAdLoading else { return }
        isAdLoading = true
        isAdReady = false

        GADRewardedAd.load(
            withAdUnitID: kRewardedAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isAdLoading = false
                if let ad {
                    self.rewardedAd = ad
                    self.isAdReady = true
                } else {
                    // Q4: 실패 시 3초 후 1회 재시도
                    try? await Task.sleep(for: .seconds(3))
                    self.loadAd()
                }
            }
        }
    }

    // MARK: - Rewarded 광고 표시

    func showRewardedAd(
        from viewController: UIViewController,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        guard let ad = rewardedAd else {
            completion(false)
            return
        }

        isAdReady = false

        ad.present(fromRootViewController: viewController) { [weak self] in
            Analytics.logEvent("ad_watched", parameters: ["ad_type": "rewarded"])
            completion(true)
            Task { @MainActor [weak self] in
                self?.rewardedAd = nil
                self?.loadAd()
            }
        }
    }

    // MARK: - Interstitial 광고 로드

    func loadInterstitialAd() {
        guard interstitialAd == nil else { return }

        GADInterstitialAd.load(
            withAdUnitID: kInterstitialAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let ad {
                    self.interstitialAd = ad
                    self.isInterstitialReady = true
                } else {
                    // Q4: 실패 시 3초 후 1회 재시도
                    try? await Task.sleep(for: .seconds(3))
                    self.interstitialAd = nil  // guard 조건 통과를 위해 nil 보장
                    self.loadInterstitialAd()
                }
            }
        }
    }

    // MARK: - Interstitial 광고 표시
    // 광고 종료(또는 로드 안 됨) 후 onDismissed 콜백 실행

    func showInterstitialAd(
        from viewController: UIViewController,
        onDismissed: @escaping @Sendable () -> Void
    ) {
        guard let ad = interstitialAd else {
            onDismissed()
            return
        }

        isInterstitialReady = false

        let coordinator = InterstitialCoordinator { [weak self] in
            onDismissed()
            Task { @MainActor [weak self] in
                self?.interstitialAd = nil
                self?.interstitialCoordinator = nil
                self?.loadInterstitialAd()
            }
        }
        interstitialCoordinator = coordinator
        ad.fullScreenContentDelegate = coordinator
        ad.present(fromRootViewController: viewController)
    }
}

// MARK: - Interstitial Delegate

private final class InterstitialCoordinator: NSObject, GADFullScreenContentDelegate {
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        onDismiss()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onDismiss()
    }
}
