import SwiftUI

// MARK: - EditCompleteView
// 묵상 수정 완료 화면 — DevotionCompleteView 레이아웃 기반
// 스트릭·CTA 없이 이모지+메시지만 표시 → 1.5초 후 자동 다이어리 복귀

struct EditCompleteView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var emojiScale: CGFloat = 0.3
    @State private var emojiOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var messageOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.dvBgDeep.ignoresSafeArea()

            // 방사형 glow
            RadialGradient(
                colors: [Color.dvAccentGold.opacity(glowOpacity), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.0).delay(0.1), value: glowOpacity)

            VStack(spacing: 28) {
                Spacer()

                // 수정 완료 아이콘
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.dvAccentGold)
                    .scaleEffect(emojiScale)
                    .opacity(emojiOpacity)

                // 완료 메시지
                VStack(spacing: 8) {
                    Text(appLanguageString("meditation.editedMessage"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text(appLanguageString("meditation.returningToDiary"))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.45))
                }
                .opacity(messageOpacity)

                Spacer()
            }
        }
        .onAppear {
            // 등장 애니메이션
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                emojiScale = 1.0
                emojiOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
                glowOpacity = 0.25
                messageOpacity = 1.0
            }
            // 1.5초 후 자동 dismiss → 뷰 라이프사이클과 함께 취소 가능한 Task 사용
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                await MainActor.run {
                    dismiss()
                }
                try? await Task.sleep(for: .milliseconds(100))
                NotificationCenter.default.post(name: .dvMeditationEditCompleted, object: nil)
            }
        }
    }
}
