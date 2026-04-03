import SwiftUI
import Combine

struct AlarmStage1View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator

    var body: some View {
        ZStack {
            if let urlStr = coordinator.activeImage?.storageUrl,
               let url = URL(string: urlStr) {
                RemoteImageView(url: url) { darkFallbackGradient }
                    .ignoresSafeArea()
            } else {
                darkFallbackGradient
            }

            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if let verse = coordinator.activeVerse {
                    VStack(spacing: 16) {
                        Text(verse.textFullKo)
                            .font(.dvStage1Verse)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(verse.reference)
                            .font(.dvReference)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    if coordinator.canSnooze {
                        Button { coordinator.snooze() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "alarm").accessibilityHidden(true)
                                Text("스누즈 \(coordinator.activeSnoozeInterval)분")
                                    .font(.dvSubtitle)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                    } else {
                        Text("더 이상 스누즈할 수 없어요")
                            .font(.dvBody)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                    }

                    // #2 기본 종료 버튼 복원 (아멘 입력은 미션으로 분리)
                    Button { coordinator.dismissToStage2() } label: {
                        Text("종료")
                            .font(.dvSubtitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dvAccentGold)
                            .foregroundColor(.dvPrimaryDeep)
                            .cornerRadius(14)
                    }
                    .accessibilityLabel("알람 종료 후 말씀 화면으로 이동")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .statusBarHidden(false)
    }

    private var darkFallbackGradient: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.18)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    let coordinator = AlarmCoordinator()
    coordinator.activeVerse = .fallbackMorning
    return AlarmStage1View().environmentObject(coordinator)
}
