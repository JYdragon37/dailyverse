import SwiftUI
import Combine

struct AlarmStage1View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator

    var body: some View {
        ZStack {
            // 다크 그라데이션 배경
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 말씀 영역 (중앙)
                if let verse = coordinator.activeVerse {
                    VStack(spacing: 16) {
                        Text(verse.textKo)
                            .font(.dvStage1Verse)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 32)

                        Text(verse.reference)
                            .font(.dvReference)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                // 하단 버튼 영역
                VStack(spacing: 12) {
                    if coordinator.canSnooze {
                        // 스누즈 버튼
                        Button {
                            coordinator.snooze()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "alarm")
                                    .accessibilityHidden(true)
                                Text("스누즈 5분")
                                    .font(.dvSubtitle)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .accessibilityLabel("5분 후 다시 알림")
                    } else {
                        // Edge Case 7: 스누즈 3회 초과 — 버튼 비활성화 + 메시지
                        Text("더 이상 스누즈할 수 없어요")
                            .font(.dvBody)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                            .accessibilityLabel("스누즈 횟수를 초과했습니다")
                    }

                    // 종료 버튼 → Stage 2 전환
                    Button {
                        coordinator.dismissToStage2()
                    } label: {
                        Text("종료")
                            .font(.dvSubtitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dvAccent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .accessibilityLabel("알람 종료 후 말씀 화면으로 이동")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        // TabBar, NavigationBar 완전 숨김
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .statusBarHidden(false)
    }
}

#Preview {
    let coordinator = AlarmCoordinator()
    coordinator.activeVerse = .fallbackMorning

    return AlarmStage1View()
        .environmentObject(coordinator)
}
