import SwiftUI

struct SplashView: View {

    var body: some View {
        ZStack {
            // 배경: 이미지 외 여백을 채울 다크 컬러 (이미지 배경색과 일치)
            Color(red: 0.12, green: 0.12, blue: 0.14)
                .ignoresSafeArea()

            // 스플래시 이미지 — scaledToFit으로 크롭 없이 로고 정중앙 유지
            Image("SplashBackground")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SplashView()
}
