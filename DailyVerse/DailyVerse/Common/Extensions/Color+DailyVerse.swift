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

    // MARK: - 8 Zone 액센트 색상 (v6.0)

    // Zone 1 — Deep Dark (00–03) 극야 보라
    static let dvDeepDarkAccent  = Color(hex: "#3D2B6B")  // 딥 퍼플

    // Zone 2 — First Light (03–06) 새벽 블루
    static let dvFirstLightAccent = Color(hex: "#2A4A8A")  // 스틸 블루

    // Zone 5 — Recharge (12–15) 민트 그린
    static let dvRechargeAccent  = Color(hex: "#2A8A7A")  // 틸 그린
    static let dvRechargeSoft    = Color(hex: "#1A5A50")  // 다크 틸

    // Zone 6 — Second Wind (15–18) 황금빛 황혼 전
    static let dvSecondWindAccent = Color(hex: "#8A7A2A")  // 다크 골드
    static let dvSecondWindSoft   = Color(hex: "#5A4A10")  // 어두운 황금

    // Zone 7 — Golden Hour (18–21) 앰버 골드
    static let dvGoldenHourAccent = Color(hex: "#C87020")  // 버닝 오렌지

    // MARK: - Design System v3.0 (경건하고 신비로운 분위기)

    /// 딥 다크 배경 #090D18
    static let dvBgDeep     = Color(hex: "#090D18")
    /// 카드 서피스 #0F1420
    static let dvBgSurface  = Color(hex: "#0F1420")
    /// Elevated 서피스 #1C2333
    static let dvBgElevated = Color(hex: "#1C2333")
    /// dvAccentGold와 통일
    static let dvGold       = dvAccentGold
    /// 세이지 그린 #7A9E87
    static let dvSage       = Color(hex: "#7A9E87")
    /// 힌트 텍스트 — white 30%
    static let dvTextHint   = Color.white.opacity(0.30)
    /// 미드 보더 — white 14%
    static let dvBorderMid  = Color.white.opacity(0.14)

    // MARK: - 시간대 그라데이션 색상 (v3.0)

    /// 아침 그라데이션 시작 — 딥 퍼플
    static let dvMorningGradStart = Color(hex: "#1A0E2E")
    /// 아침 그라데이션 중간 — 퍼플
    static let dvMorningGradMid   = Color(hex: "#3D1F5A")
    /// 아침 그라데이션 끝 — 코랄
    static let dvMorningGradEnd   = Color(hex: "#C9704A")

    /// 오후 그라데이션 시작 — 딥 네이비
    static let dvAfternoonGradStart = Color(hex: "#0D1B2A")
    /// 오후 그라데이션 중간 — 네이비 블루
    static let dvAfternoonGradMid   = Color(hex: "#1B3A5C")
    /// 오후 그라데이션 끝 — 스틸 블루
    static let dvAfternoonGradEnd   = Color(hex: "#2E7DAA")

    /// 저녁 그라데이션 시작 — 거의 검정
    static let dvEveningGradStart = Color(hex: "#06080F")
    /// 저녁 그라데이션 중간 — 딥 인디고
    static let dvEveningGradMid   = Color(hex: "#0D1533")
    /// 저녁 그라데이션 끝 — 인디고 블루
    static let dvEveningGradEnd   = Color(hex: "#1A2460")

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
