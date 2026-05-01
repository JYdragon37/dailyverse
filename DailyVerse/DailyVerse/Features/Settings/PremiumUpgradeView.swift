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

    // MARK: - Sections (stub)

    private var headerSection: some View {
        Text("Header")
            .foregroundColor(.white)
            .padding(.top, 40)
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
