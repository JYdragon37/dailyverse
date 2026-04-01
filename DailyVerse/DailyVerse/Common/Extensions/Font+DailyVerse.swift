import SwiftUI

extension Font {
    // 기존 토큰 (유지)
    static let dvLargeTitle  = Font.system(size: 34, weight: .bold, design: .serif)
    static let dvTitle       = Font.system(size: 22, weight: .semibold)
    static let dvVerseText   = Font.system(size: 18, weight: .medium, design: .serif)
    static let dvVerseFullText = Font.system(size: 16, weight: .regular, design: .serif)
    static let dvStage1Verse = Font.system(size: 24, weight: .medium, design: .serif)
    static let dvReference   = Font.system(size: 14, weight: .regular)
    static let dvBody        = Font.system(size: 15, weight: .regular)
    static let dvSubtitle    = Font.system(size: 17, weight: .medium)
    static let dvCaption     = Font.system(size: 13, weight: .regular)
    static let dvSectionTitle = Font.system(size: 13, weight: .semibold)

    // Verse 전용 (Serif, 크기 확대)
    static let dvVerseHero    = Font.system(size: 28, weight: .light, design: .serif)
    static let dvVerseDisplay = Font.system(size: 22, weight: .regular, design: .serif)

    // UI 전용 (Rounded — 따뜻한 인터페이스)
    static let dvUITitle    = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let dvUISubtitle = Font.system(size: 17, weight: .medium, design: .rounded)
    static let dvUIBody     = Font.system(size: 15, weight: .regular, design: .rounded)
    static let dvUICaption  = Font.system(size: 13, weight: .regular, design: .rounded)
}
