import SwiftUI

// Morning Manna Typography System v1.0
// Primary UI: Pretendard Variable (PostScript: PretendardVariable)
// Editorial Serif: Noto Serif KR (PostScript: NotoSerifCJKkr-Regular / NotoSerifCJKkr-SemiBold)
// Fallback: SF Pro System

extension Font {

    // MARK: - 말씀 전용 (Noto Serif KR — 경건함)

    /// 홈 화면 핵심 말씀 (SemiBold 24pt)
    static let dvVerseHero     = Font.custom("NotoSerifCJKkr-SemiBold", size: 24)
    /// Stage 1 전체화면 말씀 (Regular 22pt)
    static let dvStage1Verse   = Font.custom("NotoSerifCJKkr-Regular", size: 22)
    /// 바텀시트 전체 구절 (Regular 17pt)
    static let dvVerseFullText = Font.custom("NotoSerifCJKkr-Regular", size: 17)
    /// 저장 카드 말씀 (Regular 14pt)
    static let dvVerseDisplay  = Font.custom("NotoSerifCJKkr-Regular", size: 14)
    /// 범용 말씀 텍스트 (Regular 18pt)
    static let dvVerseText     = Font.custom("NotoSerifCJKkr-Regular", size: 18)

    // MARK: - 인사말 / UI (Pretendard Variable)

    /// 인사말 "Good Morning, NY" (Bold 32pt)
    static let dvLargeTitle = Font.custom("PretendardVariable", size: 32).weight(.bold)
    /// 시간 / 날씨 보조 (Medium 17pt)
    static let dvSubtitle   = Font.custom("PretendardVariable", size: 17).weight(.medium)

    // MARK: - UI 레이블 / 버튼

    static let dvTitle        = Font.custom("PretendardVariable", size: 22).weight(.semibold)
    static let dvBody         = Font.custom("PretendardVariable", size: 15)
    static let dvCaption      = Font.custom("PretendardVariable", size: 13).weight(.medium)
    static let dvSectionTitle = Font.custom("PretendardVariable", size: 13).weight(.semibold)
    static let dvReference    = Font.custom("PretendardVariable", size: 14).weight(.medium)

    // MARK: - UI Rounded (레거시 호환 — Pretendard로 대체)

    static let dvUITitle    = Font.custom("PretendardVariable", size: 20).weight(.semibold)
    static let dvUISubtitle = Font.custom("PretendardVariable", size: 17).weight(.medium)
    static let dvUIBody     = Font.custom("PretendardVariable", size: 15)
    static let dvUICaption  = Font.custom("PretendardVariable", size: 13).weight(.medium)
}
