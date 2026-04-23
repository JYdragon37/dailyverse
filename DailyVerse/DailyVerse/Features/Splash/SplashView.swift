import SwiftUI

// MARK: - SplashView
// 디자인 원칙: 미니멀 iOS 감성 / 파스텔 그라데이션 / 로고 중앙 약간 위 / 프리미엄 첫인상
// 색상 토큰: Color+DailyVerse.swift의 mmSplash* 사용 (하드코딩 최소화)

struct SplashView: View {

    // MARK: - 레이아웃 상수 (다양한 iPhone 세로 해상도 대응)

    /// 로고 너비: 화면 너비의 50% (최대 240pt)
    private let logoWidthRatio: CGFloat = 0.50
    private let logoMaxWidth:   CGFloat = 240

    /// 로고 수직 위치: 화면 높이의 42% (중앙 50%보다 약간 위)
    private let logoVerticalRatio: CGFloat = 0.42

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── 배경 그라데이션 ────────────────────────────
                // 토큰: mmSplashTop → mmSplashMid → mmSplashBottom
                LinearGradient(
                    stops: [
                        .init(color: .mmSplashTop,    location: 0.00),
                        .init(color: .mmSplashMid,    location: 0.48),
                        .init(color: .mmSplashBottom, location: 1.00),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // ── 로고 ──────────────────────────────────────
                // 투명 배경 PNG → 그라데이션 위에 자연스럽게 합성
                // 위치: 화면 중앙보다 약간 위 (logoVerticalRatio)
                let logoWidth = min(geo.size.width * logoWidthRatio, logoMaxWidth)
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoWidth)
                    .position(
                        x: geo.size.width  / 2,
                        y: geo.size.height * logoVerticalRatio
                    )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("iPhone 16 Pro") {
    SplashView()
        .frame(width: 393, height: 852)
}

#Preview("iPhone SE") {
    SplashView()
        .frame(width: 375, height: 667)
}
