import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.88

    var body: some View {
        ZStack {
            // 배경: Morning Manna — 스카이 블루 → 라벤더 → 블러시 핑크
            LinearGradient(
                colors: [
                    Color(hex: "#87C5E2"),  // 스카이 블루
                    Color(hex: "#C0BDDF"),  // 소프트 라벤더
                    Color(hex: "#E8B5C2"),  // 블러시 핑크
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
