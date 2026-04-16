import SwiftUI

// MARK: - BackgroundImage 오버레이 지원
// needs_overlay: true 이미지 위에 상단 다크 그라데이션을 자동으로 추가
// overlay_intensity 값에 따라 그라데이션 강도를 조절

extension BackgroundImage {

    /// overlay_intensity → opacity 매핑
    var overlayOpacity: Double {
        guard needsOverlay else { return 0.0 }
        switch overlayIntensity {
        case "light":  return 0.35
        case "medium": return 0.50
        case "heavy":  return 0.65
        default:       return 0.50
        }
    }

    /// overlay_intensity → 그라데이션 커버 높이 비율
    var overlayHeightFraction: Double {
        guard needsOverlay else { return 0.0 }
        switch overlayIntensity {
        case "light":  return 0.30   // 상단 30%
        case "medium": return 0.45   // 상단 45%
        case "heavy":  return 0.60   // 상단 60%
        default:       return 0.45
        }
    }
}

// MARK: - View Modifier

struct ZoneBackgroundOverlay: ViewModifier {
    let backgroundImage: BackgroundImage?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let bg = backgroundImage, bg.needsOverlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.black.opacity(bg.overlayOpacity),
                                Color.black.opacity(bg.overlayOpacity * 0.5),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: geo.size.height * bg.overlayHeightFraction)
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

extension View {
    /// BackgroundImage의 needs_overlay 값에 따라 상단 다크 그라데이션 자동 적용
    /// 사용법: .zoneBackgroundOverlay(backgroundImage: viewModel.currentBackground)
    func zoneBackgroundOverlay(backgroundImage: BackgroundImage?) -> some View {
        modifier(ZoneBackgroundOverlay(backgroundImage: backgroundImage))
    }
}
