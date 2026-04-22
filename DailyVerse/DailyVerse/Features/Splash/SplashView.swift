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

            // 앱 이름 + 슬로건 — splash1.jpeg에 로고 이미 포함되어 있어 AppLogo 중복 제거
            VStack(spacing: 0) {
                Spacer()
                Spacer()

                Text("Morning Manna")
                    .font(.dvLargeTitle)
                    .foregroundColor(Color(hex: "#2E3656"))
                    .opacity(textOpacity)

                Spacer().frame(height: 14)

                Text("크리스천을 위한 최고의 알람 앱")
                    .font(.dvSubtitle)
                    .foregroundColor(Color(hex: "#2E3656").opacity(0.65))
                    .opacity(textOpacity)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
