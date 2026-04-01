import SwiftUI

extension Animation {
    // Stage 1 → Stage 2 전환
    static let dvStageTransition = Animation.easeInOut(duration: 0.6)
    // 모드 전환 (아침→낮→저녁)
    static let dvModeTransition = Animation.easeInOut(duration: 1.0)
    // 말씀 카드 → 상세
    static let dvCardExpand = Animation.easeOut(duration: 0.4)
    // 바텀시트
    static let dvSheetAppear = Animation.easeOut(duration: 0.3)
    // Heart pulse
    static let dvHeartPulse = Animation.spring(response: 0.3, dampingFraction: 0.5)
    // 온보딩 화면 전환
    static let dvOnboardingTransition = Animation.easeInOut(duration: 0.4)
    // 스플래시 로고 페이드인
    static let dvSplashFadeIn = Animation.easeIn(duration: 0.3)
}

extension AnyTransition {
    static let dvFade = AnyTransition.opacity
    static let dvScaleAndFade = AnyTransition.scale.combined(with: .opacity)
    // 바텀시트 슬라이드업
    static let dvSlideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
}
