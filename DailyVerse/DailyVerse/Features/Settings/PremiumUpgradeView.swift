import SwiftUI

struct PremiumUpgradeView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    private struct FeatureRow {
        let title: String
        let free: String
        let premium: String
    }

    private let features: [FeatureRow] = [
        FeatureRow(title: "말씀 아카이브",  free: "7일",    premium: "무제한"),
        FeatureRow(title: "알람 테마",      free: "자동",   premium: "자유 선택"),
        FeatureRow(title: "광고",          free: "있음",   premium: "없음"),
        FeatureRow(title: "카드 워터마크", free: "있음",   premium: "없음"),
        FeatureRow(title: "묵상 기록",     free: "무제한", premium: "무제한"),
    ]

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
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.dvAccentGold)
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

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // 헤더 행
            HStack(spacing: 0) {
                Text("기능")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)

                Text("Free")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .frame(width: 72, alignment: .center)

                Text("Premium")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.dvAccentGold)
                    .frame(width: 96, alignment: .center)
                    .padding(.trailing, 16)
            }
            .frame(height: 36)
            .background(Color.dvBgSurface)

            // 상단 구분선
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            // 기능 행들
            ForEach(Array(features.enumerated()), id: \.offset) { index, row in
                featureRow(row, isLast: index == features.count - 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func featureRow(_ row: FeatureRow, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(row.title)
                    .font(.dvBody)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)

                Text(row.free)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.40))
                    .frame(width: 72, alignment: .center)

                Text(row.premium)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.dvAccentGold)
                    .frame(width: 96, alignment: .center)
                    .padding(.trailing, 16)
            }
            .frame(height: 48)
            .background(
                HStack(spacing: 0) {
                    Color.clear.frame(maxWidth: .infinity)
                    Color.clear.frame(width: 72)
                    Color.dvAccentGold.opacity(0.06).frame(width: 96)
                }
            )

            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 16)
            }
        }
        .background(Color.dvBgSurface)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isPremium {
                // Premium 유저 상태
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.dvAccentGold)
                    Text("이미 Premium이에요")
                        .font(.dvSubtitle)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.dvAccentGold.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.dvAccentGold.opacity(0.25), lineWidth: 1)
                )
            } else {
                // 구매 버튼
                Button {
                    Task { await subscriptionManager.purchase() }
                } label: {
                    VStack(spacing: 3) {
                        Text("Premium 시작하기")
                            .font(.system(size: 16, weight: .bold))
                        Text("₩8,900/월")
                            .font(.system(size: 13, weight: .medium))
                            .opacity(0.75)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dvAccentGold)
                    .foregroundColor(Color(hex: "#1A2340"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // 복원 버튼
                Button {
                    Task { await subscriptionManager.restore() }
                } label: {
                    Text("구독 복원하기")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }
            }

            // 안내 문구
            Text("구독은 App Store에서 언제든지 해지할 수 있습니다")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
    }
}

#Preview("Free 유저") {
    NavigationStack {
        PremiumUpgradeView()
            .environmentObject(SubscriptionManager())
    }
    .preferredColorScheme(.dark)
}

#Preview("Premium 유저") {
    let sm = SubscriptionManager()
    sm.isPremium = true
    return NavigationStack {
        PremiumUpgradeView()
            .environmentObject(sm)
    }
    .preferredColorScheme(.dark)
}
