import SwiftUI
import Combine
import RevenueCat

// v5.1 — MVP는 단일 플랜. 모든 기능 전면 제공.
// isPremium은 항상 true. 향후 구독 도입 시 RevenueCat 로직 재활성화.

@MainActor
final class SubscriptionManager: ObservableObject {
    // v5.1: 단일 플랜 — 항상 premium으로 동작
    @Published var isPremium: Bool = true
    @Published var subscriptionStatus: String = "free"
    @Published var expirationDate: Date? = nil
    @Published var isLoading: Bool = false

    private let entitlementID = "premium"

    init() {}

    // MARK: - 향후 구독 도입 시 재활성화될 메서드들

    func checkStatus() async {
        // v5.1: 단일 플랜 — RevenueCat 조회 생략
        // 향후 구독 도입 시 아래 코드 활성화:
        // let customerInfo = try await Purchases.shared.customerInfo()
        // applyCustomerInfo(customerInfo)
    }

    func purchase() async {
        // v5.1: 단일 플랜 — 구매 플로우 미사용
    }

    func restore() async {
        // v5.1: 단일 플랜 — 복원 플로우 미사용
    }

    func logOut() {
        Task {
            try? await Purchases.shared.logOut()
        }
        subscriptionStatus = "free"
        expirationDate = nil
    }

    // MARK: - Private

    private func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        let entitlement = customerInfo.entitlements[entitlementID]
        let active = entitlement?.isActive == true
        subscriptionStatus = active ? "premium" : "free"
        expirationDate = entitlement?.expirationDate
    }
}
