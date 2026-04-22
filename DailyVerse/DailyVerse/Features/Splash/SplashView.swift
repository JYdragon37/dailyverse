import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.88

    var body: some View {
        ZStack {
            // 배경: Morning Manna — 새벽 여명 그라데이션
            LinearGradient(
                colors: [
                    Color(hex: "#2E3656"),  // 새벽 딥 네이비
                    Color(hex: "#8DB8DA"),  // 여명 스카이 블루
                    Color(hex: "#E8C8D2"),  // 블러시 핑크
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 앱 로고 — 배경 그라데이션 포함된 PNG를 그대로 표시
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148, height: 148)
                    .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 10)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                Spacer().frame(height: 36)

                // 앱 이름 — Dancing Script 커시브체
                Text("Morning Manna")
                    .font(.dvLargeTitle)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    .opacity(textOpacity)

                Spacer().frame(height: 16)

                // 슬로건
                Text("크리스천을 위한 최고의 알람 앱")
                    .font(.dvSubtitle)
                    .foregroundColor(.white.opacity(0.82))
                    .opacity(textOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                logoOpacity = 1.0
                logoScale   = 1.0
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
