import SwiftUI
import Combine

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var isPulsing: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.18),
                    Color(red: 0.10, green: 0.10, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .opacity(logoOpacity)
                    .scaleEffect(isPulsing ? 1.04 : 1.0)
                    .animation(.dvBreathingPulse, value: isPulsing)
                    .accessibilityLabel("DailyVerse 앱 아이콘")

                Text("DailyVerse")
                    .font(.dvLargeTitle)
                    .foregroundColor(.white)
                    .opacity(logoOpacity)

                Text("하루의 끝과 시작을 경건하게")
                    .font(.dvBody)
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            withAnimation(.dvSplashFadeIn) {
                logoOpacity = 1.0
            }
            withAnimation(.dvSplashFadeIn.delay(0.2)) {
                subtitleOpacity = 1.0
            }
            isPulsing = true
        }
    }
}

#Preview {
    SplashView()
}
