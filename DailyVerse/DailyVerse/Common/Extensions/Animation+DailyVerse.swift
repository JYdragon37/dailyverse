import SwiftUI
import UIKit

// v5.1 — 모션 시스템
// - 화면 전환: 0.4~0.6초 Ease-In-Out
// - 배경 이미지 모드 전환: 0.8초 Cross-Fade
// - 버튼 탭: Scale 95%→100%, 0.1초 + haptic Light
// - 스켈레톤: shimmer 좌→우, 1.5초 반복

extension Animation {

    // MARK: - 화면 전환

    /// Stage 1 → Stage 2 전환 (0.6s)
    static let dvStageTransition = Animation.easeInOut(duration: 0.6)
    /// 모드 전환 배경 이미지 Cross-Fade (0.8s) — v5.1: 1.2s → 0.8s
    static let dvModeTransition  = Animation.easeInOut(duration: 0.8)
    /// 말씀 카드 → 상세 바텀시트 (0.4s)
    static let dvCardExpand      = Animation.easeOut(duration: 0.4)
    /// 바텀시트 등장 (0.3s)
    static let dvSheetAppear     = Animation.easeOut(duration: 0.3)
    /// 온보딩 화면 전환 (0.4s)
    static let dvOnboardingTransition = Animation.easeInOut(duration: 0.4)
    /// 스플래시 로고 페이드인 (0.3s)
    static let dvSplashFadeIn    = Animation.easeOut(duration: 0.3)

    // MARK: - 버튼 / 인터랙션

    /// Heart pulse (저장 버튼 탭) — spring
    static let dvHeartPulse      = Animation.spring(response: 0.4, dampingFraction: 0.3)
    /// 버튼 탭 Scale 95%→100% (0.1s)
    static let dvButtonTap       = Animation.easeOut(duration: 0.1)

    // MARK: - 특수 효과

    /// 텍스트 등장 (0.8s)
    static let dvTextAppear      = Animation.easeOut(duration: 0.8)
    /// 명상 앱 수준 breathing pulse
    static let dvBreathingPulse  = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
    /// 스켈레톤 shimmer (1.5s 반복)
    static let dvShimmer         = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
}

extension AnyTransition {
    static let dvFade        = AnyTransition.opacity
    static let dvScaleAndFade = AnyTransition.scale.combined(with: .opacity)
    static let dvSlideUp     = AnyTransition.move(edge: .bottom).combined(with: .opacity)
}

// MARK: - 버튼 탭 효과 ViewModifier

struct DVButtonPressEffect: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.dvButtonTap, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func dvButtonEffect() -> some View {
        modifier(DVButtonPressEffect())
    }
}
