import SwiftUI

extension Color {
    // Brand colors
    static let dvPrimary = Color.primary
    static let dvAccent = Color(red: 0.27, green: 0.51, blue: 0.95)
    static let dvBackground = Color(UIColor.systemBackground)
    static let dvSurface = Color(UIColor.systemBackground).opacity(0.85)
    static let dvTemperature = Color(red: 0.27, green: 0.51, blue: 0.95)
    static let dvOverlay = Color.black.opacity(0.35)

    // 다크 배경 레이어
    static let dvNight      = Color(red: 0.051, green: 0.067, blue: 0.090)
    static let dvDeepNavy   = Color(red: 0.102, green: 0.122, blue: 0.208)
    static let dvDarkSlate  = Color(red: 0.145, green: 0.169, blue: 0.251)

    // 텍스트 (따뜻한 화이트 시스템)
    static let dvTextPrimary   = Color(red: 0.941, green: 0.929, blue: 0.910)  // #F0EDE8
    static let dvTextSecondary = Color(red: 0.722, green: 0.706, blue: 0.675)  // #B8B4AC
    static let dvTextMuted     = Color(red: 0.478, green: 0.467, blue: 0.435)  // #7A776F

    // 강조색
    static let dvVerseGold = Color(red: 0.831, green: 0.686, blue: 0.431)  // #D4AF6E
    static let dvSaved     = Color(red: 0.910, green: 0.420, blue: 0.478)  // #E86B7A

    // 카드 글라스모피즘
    static let dvCardFill   = Color.white.opacity(0.08)
    static let dvCardBorder = Color.white.opacity(0.13)

    // 모드별 액센트
    static let dvMorningGold   = Color(red: 0.961, green: 0.784, blue: 0.259)
    static let dvMorningAmber  = Color(red: 0.910, green: 0.576, blue: 0.290)
    static let dvNoonSky       = Color(red: 0.290, green: 0.565, blue: 0.851)
    static let dvNoonTeal      = Color(red: 0.231, green: 0.722, blue: 0.627)
    static let dvEveningPurple = Color(red: 0.482, green: 0.408, blue: 0.784)
    static let dvEveningIndigo = Color(red: 0.290, green: 0.271, blue: 0.502)
}
