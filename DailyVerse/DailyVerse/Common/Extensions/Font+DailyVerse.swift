import SwiftUI

// v5.1 — Calm 벤치마크 타이포그래피 시스템
// - 말씀: Georgia Italic / SF Pro Display Italic (세리프, 경건함)
// - 인사말/닉네임: SF Pro Display Medium (따뜻하고 개인적)
// - UI 레이블/버튼: SF Pro Text Regular
// - 성경 참조: SF Pro Text Medium, Accent Gold

extension Font {

    // MARK: - 말씀 전용 (Serif Italic — 경건함)

    /// 홈 화면 핵심 말씀 (26~28pt, Bold)
    static let dvVerseHero    = Font.custom("Georgia-BoldItalic", size: 26).weight(.bold)
    /// Stage 1 전체화면 말씀 (28pt)
    static let dvStage1Verse  = Font.custom("Georgia-Italic", size: 28)
    /// 바텀시트 전체 구절 (17pt)
    static let dvVerseFullText = Font.custom("Georgia-Italic", size: 17)
    /// 저장 카드 말씀 (14pt)
    static let dvVerseDisplay  = Font.custom("Georgia-Italic", size: 14)
    /// 범용 말씀 텍스트 (18pt)
    static let dvVerseText     = Font.custom("Georgia-Italic", size: 18)

    // MARK: - 인사말 / 닉네임 (SF Pro Display — 따뜻함)

    /// Good Morning, {nickname} (34pt bold)
    static let dvLargeTitle  = Font.system(size: 34, weight: .bold, design: .default)
    /// 시간 / 날씨 보조 텍스트 (17pt medium)
    static let dvSubtitle    = Font.system(size: 17, weight: .medium, design: .default)

    // MARK: - UI 레이블 / 버튼 (SF Pro Text)

    static let dvTitle        = Font.system(size: 22, weight: .semibold)
    static let dvBody         = Font.system(size: 15, weight: .regular)
    static let dvCaption      = Font.system(size: 13, weight: .regular)
    static let dvSectionTitle = Font.system(size: 13, weight: .semibold)

    // MARK: - 성경 참조 (SF Pro Text Medium, Accent Gold에서 사용)

    static let dvReference = Font.system(size: 14, weight: .medium)

    // MARK: - UI Rounded (따뜻한 인터페이스)

    static let dvUITitle    = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let dvUISubtitle = Font.system(size: 17, weight: .medium,   design: .rounded)
    static let dvUIBody     = Font.system(size: 15, weight: .regular,  design: .rounded)
    static let dvUICaption  = Font.system(size: 13, weight: .regular,  design: .rounded)
}
