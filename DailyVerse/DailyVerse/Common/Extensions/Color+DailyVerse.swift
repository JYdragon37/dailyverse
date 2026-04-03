import SwiftUI

// v5.1 — Calm 벤치마크 컬러 시스템
// 레퍼런스: PRD v5.1 섹션 18 디자인 원칙

extension Color {

    // MARK: - Primary (딥 다크 배경)

    /// 딥 네이비 #1A2340 — 카드 배경, 바텀시트
    static let dvPrimaryDeep = Color(hex: "#1A2340")
    /// 미드나이트 블루 #2C3E6B — 탭바, 네비게이션
    static let dvPrimaryMid  = Color(hex: "#2C3E6B")

    // MARK: - Accent

    /// 앰버 골드 #C8972A — CTA 버튼, 성경 참조, 하이라이트
    static let dvAccentGold  = Color(hex: "#C8972A")
    /// 소프트 크림 #F5EDD8 — 보조 텍스트, 테마 칩 테두리
    static let dvAccentSoft  = Color(hex: "#F5EDD8")

    // MARK: - Text

    /// 퓨어 화이트 — 말씀, 주요 텍스트
    static let dvTextPrimary   = Color.white
    /// 화이트 55% — 날짜, 보조 정보
    static let dvTextSecondary = Color.white.opacity(0.55)
    /// 화이트 35% — muted 텍스트
    static let dvTextMuted     = Color.white.opacity(0.35)

    // MARK: - Surface (글래스모피즘)

    /// 카드/날씨 위젯 배경 — White 15% + blur
    static let dvSurfaceGlass  = Color.white.opacity(0.15)
    static let dvSurfaceBorder = Color.white.opacity(0.20)

    // MARK: - Semantic

    static let dvSaved   = Color(hex: "#E86B7A")   // 저장 하트
    static let dvOverlay = Color.black.opacity(0.40)

    // MARK: - 모드별 액센트 (아침)

    static let dvMorningGold  = Color(red: 0.961, green: 0.784, blue: 0.259)  // 황금빛 sunrise
    static let dvMorningAmber = Color(red: 0.910, green: 0.576, blue: 0.290)

    // MARK: - 모드별 액센트 (낮)

    static let dvNoonSky  = Color(red: 0.290, green: 0.565, blue: 0.851)      // 맑고 푸른 하늘
    static let dvNoonTeal = Color(red: 0.231, green: 0.722, blue: 0.627)

    // MARK: - 모드별 액센트 (저녁)

    static let dvEveningPurple = Color(red: 0.482, green: 0.408, blue: 0.784) // 붉은 노을·보랏빛 황혼
    static let dvEveningIndigo = Color(red: 0.290, green: 0.271, blue: 0.502)

    // MARK: - 모드별 액센트 (새벽) v5.1 신규

    static let dvDawnIndigo = Color(red: 0.153, green: 0.165, blue: 0.380)    // 깊은 남색·별빛
    static let dvDawnNavy   = Color(red: 0.102, green: 0.122, blue: 0.250)

    // MARK: - 기존 레거시 호환 (참조 코드가 있을 경우 오류 방지)

    static let dvPrimary    = Color.primary
    static let dvAccent     = dvAccentGold
    static let dvBackground = Color(UIColor.systemBackground)
    static let dvSurface    = dvSurfaceGlass
    static let dvTemperature = dvNoonSky
    static let dvVerseGold  = dvAccentGold
    static let dvCardFill   = dvSurfaceGlass
    static let dvCardBorder = dvSurfaceBorder
    static let dvNight      = dvPrimaryDeep
    static let dvDeepNavy   = dvPrimaryMid
    static let dvDarkSlate  = Color(red: 0.145, green: 0.169, blue: 0.251)
}

// MARK: - Hex 초기화 헬퍼

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
