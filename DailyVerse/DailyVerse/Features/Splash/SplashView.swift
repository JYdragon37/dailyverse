import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.85

    var body: some View {
        ZStack {
            // 앱 아이콘과 어울리는 청록-보라 그라데이션 (아이콘 배경색)
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.78, blue: 0.82),  // teal
                    Color(red: 0.55, green: 0.42, blue: 0.82)   // purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // #5 앱 로고 이미지
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    // 투명 배경 처리 — 배경 제거된 PNG의 경우에도 깔끔하게 표시
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                Text("DailyVerse")
                    .font(.dvLargeTitle)
                    .foregroundColor(.white)
                    .opacity(logoOpacity)

                Text("하루의 끝과 시작을 경건하게")
                    .font(.dvBody)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                subtitleOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
