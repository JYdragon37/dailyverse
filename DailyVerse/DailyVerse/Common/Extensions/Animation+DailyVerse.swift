import SwiftUI

extension Animation {
    // Stage 1 → Stage 2 전환
    static let dvStageTransition = Animation.easeInOut(duration: 0.6)
    // 모드 전환 (아침→낮→저녁) — 1.2s로 업그레이드
    static let dvModeTransition = Animation.easeInOut(duration: 1.2)
    // 말씀 카드 → 상세
    static let dvCardExpand = Animation.easeOut(duration: 0.4)
    // 바텀시트
    static let dvSheetAppear = Animation.easeOut(duration: 0.3)
    // Heart pulse — spring으로 업그레이드
    static let dvHeartPulse = Animation.spring(response: 0.4, dampingFraction: 0.3)
    // 온보딩 화면 전환
    static let dvOnboardingTransition = Animation.easeInOut(duration: 0.4)
    // 스플래시 로고 페이드인 — easeOut으로 업그레이드
    static let dvSplashFadeIn = Animation.easeOut(duration: 0.6)
    // 명상 앱 수준 breathing pulse
    static let dvBreathingPulse = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
    // 텍스트 등장
    static let dvTextAppear = Animation.easeOut(duration: 0.8)
}

extension AnyTransition {
    static let dvFade = AnyTransition.opacity
    static let dvScaleAndFade = AnyTransition.scale.combined(with: .opacity)
    // 바텀시트 슬라이드업
    static let dvSlideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
}
