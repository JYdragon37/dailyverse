import SwiftUI
import Combine

struct AlarmStage1View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator

    @State private var showAmenAlert = false     // #3 아멘 확인 팝업
    @State private var amenInput = ""

    var body: some View {
        ZStack {
            // 배경 이미지
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

                // 말씀 (text_full_ko)
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
                    } else {
                        Text("더 이상 스누즈할 수 없어요")
                            .font(.dvBody)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                    }

                    // #3 종료 → 아멘 입력 팝업
                    Button {
                        amenInput = ""
                        showAmenAlert = true
                    } label: {
                        Text("종료")
                            .font(.dvSubtitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dvAccentGold)
                            .foregroundColor(.dvPrimaryDeep)
                            .cornerRadius(14)
                    }
                    .accessibilityLabel("알람 종료")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .statusBarHidden(false)
        // #3 아멘 입력 Alert
        .alert("아멘으로 알람을 종료하세요", isPresented: $showAmenAlert) {
            TextField("아멘", text: $amenInput)
                .autocorrectionDisabled()
            Button("확인") {
                if amenInput.trimmingCharacters(in: .whitespacesAndNewlines) == "아멘" {
                    coordinator.dismissToStage2()
                } else {
                    // 틀렸으면 다시 표시
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        amenInput = ""
                        showAmenAlert = true
                    }
                }
            }
            Button("취소", role: .cancel) { amenInput = "" }
        } message: {
            Text("\"아멘\"을 입력하면 말씀 화면으로 넘어갑니다")
        }
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
