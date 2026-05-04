import SwiftUI
import Combine
import RevenueCat
import FirebaseAnalytics

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: String = "free"
    @Published var expirationDate: Date? = nil
    @Published var isLoading: Bool = false

    private let entitlementID = "premium"

    init() {}

    func checkStatus() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            applyCustomerInfo(customerInfo)
        } catch {
            // 조회 실패 시 free 유지
        }
    }

    /// 마스터 계정 확인 — Firestore app_config/master_accounts에 등록된 이메일이면 isPremium = true
    /// 앱 업데이트 없이 Firebase 콘솔에서 직접 추가/삭제 가능
    func checkMasterAccount(email: String) async {
        let masterEmails = await FirestoreService().fetchMasterAccounts()
        // 명시적으로 결과를 반영 — 비마스터 계정은 false 보장
        isPremium = masterEmails.contains(email.lowercased())
    }

    func purchase() async {
        // v5.1: 단일 플랜 — 구매 플로우 미사용
        // 향후 구독 도입 시 활성화:
        Analytics.logEvent("subscription_started", parameters: nil)
    }

    func restore() async {
        // v5.1: 단일 플랜 — 복원 플로우 미사용
    }

    func logOut() {
        if subscriptionStatus == "premium" {
            Analytics.logEvent("subscription_cancelled", parameters: nil)
        }
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
        let active = entitlement?.isActive == true
        isPremium = active
        subscriptionStatus = active ? "premium" : "free"
        expirationDate = entitlement?.expirationDate
    }
}
