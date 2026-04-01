import SwiftUI
import Combine
import RevenueCat

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: String = "free"
    @Published var expirationDate: Date? = nil
    @Published var isLoading: Bool = false

    private let entitlementID = "premium"

    init() {
        // RevenueCat configure는 DailyVerseApp.init()에서 호출됨
    }

    // MARK: - 구독 상태 확인

    func checkStatus() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            applyCustomerInfo(customerInfo)
        } catch {
            // 오류 시 기존 상태 유지
        }
    }

    // MARK: - 구매

    func purchase() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let package = offerings.current?.monthly else { return }
            let result = try await Purchases.shared.purchase(package: package)
            applyCustomerInfo(result.customerInfo)
        } catch let error as RevenueCat.ErrorCode where error == .purchaseCancelledError {
            // 사용자 취소 — 조용히 처리
        } catch {
            // 기타 오류 — 상태 변경 없이 무시
        }
    }

    // MARK: - 복원

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(customerInfo)
        } catch {
            // 복원 오류 무시
        }
    }

    // MARK: - 로그아웃 (계정 탈퇴 / 로그아웃 시)

    func logOut() {
        Task {
            try? await Purchases.shared.logOut()
        }
        isPremium = false
        subscriptionStatus = "free"
        expirationDate = nil
    }

    // MARK: - Private

    private func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        let entitlement = customerInfo.entitlements[entitlementID]
        isPremium = entitlement?.isActive == true
        subscriptionStatus = isPremium ? "premium" : "free"
        expirationDate = entitlement?.expirationDate
    }
}
