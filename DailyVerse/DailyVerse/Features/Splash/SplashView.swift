import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.88

    var body: some View {
        ZStack {
            // 배경: 청록(상단) → 파란보라(중간) → 보라(하단)
            LinearGradient(
                colors: [
                    Color(red: 0.40, green: 0.82, blue: 0.86),  // 청록
                    Color(red: 0.45, green: 0.62, blue: 0.88),  // 파란보라
                    Color(red: 0.62, green: 0.45, blue: 0.85),  // 보라
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
                Text("DailyVerse")
                    .font(.custom("DancingScript-Regular", size: 56))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    .opacity(textOpacity)

                Spacer().frame(height: 16)

                // 슬로건 — Nanum Pen Script 손글씨체
                Text("하루의 끝과 시작을 경건하게")
                    .font(.custom("NanumPenScript-Regular", size: 20))
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
