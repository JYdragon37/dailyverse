import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.88

    var body: some View {
        ZStack {
            // 배경: splash1.jpeg 원본 이미지 직접 사용 (그라데이션 근사치 대신)
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 앱 로고 — 아치형 네온 크로스 (투명 배경 PNG)
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .shadow(color: Color(hex: "#B7E3F6").opacity(0.6), radius: 32, x: 0, y: 0)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                Spacer().frame(height: 40)

                // 앱 이름
                Text("Morning Manna")
                    .font(.dvLargeTitle)
                    .foregroundColor(Color(hex: "#2E3656"))
                    .opacity(textOpacity)

                Spacer().frame(height: 14)

                // 슬로건
                Text("크리스천을 위한 최고의 알람 앱")
                    .font(.dvSubtitle)
                    .foregroundColor(Color(hex: "#2E3656").opacity(0.65))
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
