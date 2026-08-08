import SwiftUI
import Combine

struct UpsellBottomSheet: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // 핸들
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // 헤더
            VStack(spacing: 8) {
                Text("Premium")
                    .font(.dvLargeTitle)
                    .foregroundColor(.dvPrimary)

                Text(upsellManager.currentTrigger.message)
                    .font(.dvSubtitle)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            // 혜택 목록
            VStack(alignment: .leading, spacing: 12) {
                benefitRow(icon: "infinity", text: appLanguageString("upsell.benefit.unlimitedThemes"))
                benefitRow(icon: "archivebox.fill", text: appLanguageString("upsell.benefit.fullArchive"))
                benefitRow(icon: "xmark.circle.fill", text: appLanguageString("upsell.benefit.noAds"))
            }
            .padding(.horizontal, 32)

            // 구매 버튼
            VStack(spacing: 12) {
                Button {
                    Task { await subscriptionManager.purchase() }
                    dismiss()
                } label: {
                    VStack(spacing: 2) {
                        Text(appLanguageString("settings.premiumUpgrade"))
                            .font(.dvSubtitle)
                        Text(appLanguageString("upsell.price"))
                            .font(.dvCaption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dvAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .accessibilityLabel(appLanguageString("upsell.cta.accessibility"))

                Button {
                    upsellManager.shouldShow = false
                    dismiss()
                } label: {
                    Text(appLanguageString("meditation.later"))
                        .font(.dvBody)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(appLanguageString("upsell.dismiss.accessibility"))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .onDisappear {
            upsellManager.shouldShow = false
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.dvAccent)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(text)
                .font(.dvBody)
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UpsellBottomSheet()
                .environmentObject(SubscriptionManager())
                .environmentObject(UpsellManager())
        }
}
