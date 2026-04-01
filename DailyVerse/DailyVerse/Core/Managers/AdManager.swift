import SwiftUI
import Combine
import GoogleMobileAds

// Google 공식 테스트 ID: ca-app-pub-3940256099942544/1712485313
// 출시 전 실제 Ad Unit ID로 교체 필요
private let kAdUnitID = "ca-app-pub-3940256099942544/1712485313"

@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    @Published var isAdLoading: Bool = false
    @Published var isAdReady: Bool = false

    private var rewardedAd: GADRewardedAd?

    private init() {}

    // MARK: - 광고 로드

    func loadAd() {
        guard !isAdLoading else { return }
        isAdLoading = true
        isAdReady = false

        GADRewardedAd.load(
            withAdUnitID: kAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isAdLoading = false
                if let ad {
                    self.rewardedAd = ad
                    self.isAdReady = true
                } else {
                    // 로드 실패 — 조용히 처리
                    self.isAdReady = false
                }
            }
        }
    }

    // MARK: - 광고 표시

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
            // 보상 콜백: 광고 끝까지 시청 완료
            completion(true)
            Task { @MainActor [weak self] in
                self?.rewardedAd = nil
                self?.loadAd()
            }
        }
    }
}
