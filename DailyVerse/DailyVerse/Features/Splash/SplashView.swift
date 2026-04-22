import SwiftUI

struct SplashView: View {

    var body: some View {
        // 스플래시 이미지 — 로고·텍스트·슬로건 모두 포함된 완성 이미지
        Image("SplashBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
