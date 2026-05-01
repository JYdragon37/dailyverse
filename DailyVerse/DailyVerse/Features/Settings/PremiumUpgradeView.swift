import SwiftUI

struct PremiumUpgradeView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                comparisonTable
                ctaSection
            }
            .padding(.bottom, 40)
        }
        .background(Color.dvBgDeep.ignoresSafeArea())
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.dvBgDeep.opacity(0.95), for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // 왕관 아이콘
            ZStack {
                Circle()
                    .fill(Color.dvAccentGold.opacity(0.12))
                    .frame(width: 72, height: 72)
                Text("👑")
                    .font(.system(size: 36))
            }
            .padding(.top, 40)

            // 타이틀
            Text("PREMIUM")
                .font(.system(size: 26, weight: .black))
                .foregroundColor(Color.dvAccentGold)
                .tracking(3)

            // 부제
            Text("하루의 말씀이 더 깊어집니다")
                .font(.dvSubtitle)
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var comparisonTable: some View {
        Text("Table")
            .foregroundColor(.white)
    }

    private var ctaSection: some View {
        Text("CTA")
            .foregroundColor(.white)
    }
}

#Preview {
    NavigationStack {
        PremiumUpgradeView()
            .environmentObject(SubscriptionManager())
    }
    .preferredColorScheme(.dark)
}
