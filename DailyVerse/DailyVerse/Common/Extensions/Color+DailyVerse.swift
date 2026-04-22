import SwiftUI

// Morning Manna Design System — v1.1
// 배경/Zone: Morning Manna 새벽 파스텔 / 액센트: 앰버 골드 유지

extension Color {

    // MARK: - 배경 계층 (Dark Charcoal)

    /// 앱 기본 배경 #15171C
    static let dvBgDeep     = Color(hex: "#15171C")
    /// 카드 서피스 #1C1F26
    static let dvBgSurface  = Color(hex: "#1C1F26")
    /// Elevated 서피스 (모달, 바텀시트) #252932
    static let dvBgElevated = Color(hex: "#252932")

    // MARK: - 액센트 (Dawn Pastel)

    /// Sky Blue #B7E3F6 — 주요 하이라이트, 칩 선택 상태
    static let dvAccentSky   = Color(hex: "#B7E3F6")
    /// Blush Pink #F4C7D4 — 따뜻한 포인트
    static let dvAccentBlush = Color(hex: "#F4C7D4")
    /// Ivory Glow #F6F1E8 — 교차 중심 부드러운 빛
    static let dvAccentIvory = Color(hex: "#F6F1E8")
    /// Lilac Mist #CFC6F3 — 보조 미스트
    static let dvAccentLilac = Color(hex: "#CFC6F3")

    /// CTA 그라데이션 시작 #9FDDF3
    static let dvCtaStart = Color(hex: "#9FDDF3")
    /// CTA 그라데이션 종료 #E8C3D3
    static let dvCtaEnd   = Color(hex: "#E8C3D3")

    // MARK: - 골드 액센트 (CTA, 아이콘, 태그 — 원복)

    /// 앰버 골드 #C8972A — CTA 버튼, 성경 참조, 테마 태그, 아이콘 하이라이트
    static let dvAccentGold  = Color(hex: "#C8972A")
    static let dvGold        = Color(hex: "#C8972A")
    static let dvAccentSoft  = Color(hex: "#F5EDD8")
    static let dvAccent      = Color(hex: "#C8972A")
    static let dvVerseGold   = Color(hex: "#C8972A")

    // MARK: - 텍스트

    /// 본문 주요 텍스트 #F7F3EE
    static let dvTextPrimary   = Color(hex: "#F7F3EE")
    /// 보조 텍스트 #D8D1C8
    static let dvTextSecondary = Color(hex: "#D8D1C8")
    /// 비활성 / 캡션 #AAA39A
    static let dvTextMuted     = Color(hex: "#AAA39A")
    /// 힌트 텍스트
    static let dvTextHint      = Color(hex: "#AAA39A")

    // MARK: - 저장 / 하트

    /// 저장 하트 #E48A9A
    static let dvSaved = Color(hex: "#E48A9A")

    // MARK: - 서피스 / 보더

    /// 구분선 / stroke — white 12%
    static let dvBorderMid     = Color.white.opacity(0.12)
    static let dvSurfaceGlass  = Color.white.opacity(0.10)
    static let dvSurfaceBorder = Color.white.opacity(0.14)
    static let dvOverlay       = Color.black.opacity(0.40)
    static let dvLine          = Color(hex: "#FFFFFF").opacity(0.12)

    // MARK: - 레거시 호환

    static let dvPrimaryDeep  = Color(hex: "#15171C")
    static let dvPrimaryMid   = Color(hex: "#1C1F26")
    static let dvPrimary      = Color.primary
    static let dvBackground   = dvBgDeep  // 레거시 alias (UIColor 의존성 제거)
    static let dvSurface      = dvSurfaceGlass
    static let dvCardFill     = dvSurfaceGlass
    static let dvCardBorder   = dvSurfaceBorder
    static let dvNight        = dvPrimaryDeep
    static let dvDeepNavy     = dvPrimaryMid
    static let dvDarkSlate    = Color(hex: "#252932")
    static let dvTemperature  = dvAccentSky
    static let dvSage         = Color(hex: "#7A9E87")

    // MARK: - Zone 액센트

    static let dvDeepDarkAccent   = Color(hex: "#1A1F31")
    static let dvFirstLightAccent = Color(hex: "#365B8A")
    static let dvRechargeAccent   = Color(hex: "#56727D")
    static let dvRechargeSoft     = Color(hex: "#274040")
    static let dvSecondWindAccent = Color(hex: "#7A7F9A")
    static let dvSecondWindSoft   = Color(hex: "#3A4251")
    static let dvGoldenHourAccent = Color(hex: "#A9828F")

    // MARK: - Morning / Afternoon / Evening (레거시 호환)

    static let dvMorningGold        = dvAccentIvory
    static let dvMorningAmber       = dvAccentBlush
    static let dvNoonSky            = dvAccentSky
    static let dvNoonTeal           = Color(hex: "#56727D")
    static let dvEveningPurple      = dvAccentLilac
    static let dvEveningIndigo      = Color(hex: "#2A3150")
    static let dvDawnIndigo         = Color(hex: "#1A1F31")
    static let dvDawnNavy           = Color(hex: "#171E33")

    // MARK: - 그라데이션 토큰 (레거시 호환)

    static let dvMorningGradStart   = Color(hex: "#2E3656")
    static let dvMorningGradMid     = Color(hex: "#8DB8DA")
    static let dvMorningGradEnd     = Color(hex: "#E8C8D2")
    static let dvAfternoonGradStart = Color(hex: "#243246")
    static let dvAfternoonGradMid   = Color(hex: "#4D6A8F")
    static let dvAfternoonGradEnd   = Color(hex: "#4D6A8F")
    static let dvEveningGradStart   = Color(hex: "#161923")
    static let dvEveningGradMid     = Color(hex: "#2A3150")
    static let dvEveningGradEnd     = Color(hex: "#2A3150")
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
