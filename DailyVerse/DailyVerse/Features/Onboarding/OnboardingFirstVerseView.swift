import SwiftUI
import Combine

struct OnboardingFirstVerseView: View {
    var viewModel: OnboardingViewModel
    @State private var cardOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                // v5.1: 닉네임 개인화 미리보기
                let nickname = NicknameManager.shared.nickname
                Text("Good Morning, \(nickname) ☀️")
                    .font(.dvTitle)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("매일 이런 말씀이 당신을 깨울 거예요")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 12)
                .overlay {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("두려워하지 말라\n내가 너와 함께 함이라")
                            .font(.dvVerseText)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("이사야 41장 10절 말씀: 두려워하지 말라 내가 너와 함께 함이라")

                        Divider()

                        HStack {
                            Text("이사야 41:10")
                                .font(.dvReference)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Hope")
                                .font(.dvCaption)
                                .foregroundColor(.dvAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.dvAccent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .padding(.horizontal, 32)
                .opacity(cardOpacity)
                .scaleEffect(cardScale)

            Spacer()

            Button("다음") {
                viewModel.next()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("다음 온보딩 화면으로 이동")
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardOpacity = 1
                cardScale = 1
            }
        }
    }
}

#Preview {
    OnboardingFirstVerseView(viewModel: OnboardingViewModel())
}
