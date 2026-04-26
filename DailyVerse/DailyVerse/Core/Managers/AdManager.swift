import SwiftUI
import Combine
import GoogleMobileAds

// TODO: 프로덕션 배포 전 실제 Ad Unit ID로 교체
// Google 공식 테스트 ID
private let kRewardedAdUnitID     = "ca-app-pub-3940256099942544/1712485313"
private let kInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"

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
                    self.isAdReady = false
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
