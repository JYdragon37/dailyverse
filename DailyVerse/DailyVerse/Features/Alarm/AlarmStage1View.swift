import SwiftUI
import Combine

struct AlarmStage1View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator

    var body: some View {
        ZStack {
            // 배경 이미지 — RemoteImageView로 Genspark URL 호환
            if let urlStr = coordinator.activeImage?.storageUrl,
               let url = URL(string: urlStr) {
                RemoteImageView(url: url) { darkFallbackGradient }
                    .ignoresSafeArea()
            } else {
                darkFallbackGradient
            }

            // 가독성 오버레이
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 말씀 영역: text_full_ko 표시 (#3 수정)
                if let verse = coordinator.activeVerse {
                    VStack(spacing: 16) {
                        Text(verse.textFullKo)          // textKo → textFullKo
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

                // 하단 버튼
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
                        .accessibilityLabel("\(coordinator.activeSnoozeInterval)분 후 다시 알림")
                    } else {
                        Text("더 이상 스누즈할 수 없어요")
                            .font(.dvBody)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                    }

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
