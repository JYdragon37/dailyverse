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
                benefitRow(icon: "infinity", text: "말씀 무제한 + 전 테마")
                benefitRow(icon: "archivebox.fill", text: "전체 아카이브 열람")
                benefitRow(icon: "xmark.circle.fill", text: "광고 없음")
            }
            .padding(.horizontal, 32)

            // 구매 버튼
            VStack(spacing: 12) {
                Button {
                    Task { await subscriptionManager.purchase() }
                    dismiss()
                } label: {
                    VStack(spacing: 2) {
                        Text("Premium 시작하기")
                            .font(.dvSubtitle)
                        Text("₩24,500/월")
                            .font(.dvCaption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dvAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Premium 구독 시작하기 월 24500원")

                Button {
                    upsellManager.shouldShow = false
                    dismiss()
                } label: {
                    Text("나중에")
                        .font(.dvBody)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("업셀 닫기")
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
