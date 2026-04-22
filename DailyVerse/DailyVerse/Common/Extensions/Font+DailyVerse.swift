import SwiftUI

// Morning Manna Typography System v1.1
// Single font: Pretendard Variable — UI + 말씀 모두 통일
// Weight으로 계층 구분: Bold(700) 인사말 / SemiBold(600) 말씀 헤드 / Regular(400) 본문

extension Font {

    // MARK: - 말씀 전용 (Pretendard — 모던, 가독성)

    /// 홈·Stage 2 핵심 말씀 (SemiBold 24pt)
    static let dvVerseHero     = Font.custom("PretendardVariable", size: 24).weight(.semibold)
    /// Stage 1 전체화면 말씀 (Regular 22pt)
    static let dvStage1Verse   = Font.custom("PretendardVariable", size: 22)
    /// 바텀시트 전체 구절 (Regular 17pt)
    static let dvVerseFullText = Font.custom("PretendardVariable", size: 17)
    /// 저장 카드 말씀 (Regular 14pt)
    static let dvVerseDisplay  = Font.custom("PretendardVariable", size: 14)
    /// 범용 말씀 텍스트 (Regular 18pt)
    static let dvVerseText     = Font.custom("PretendardVariable", size: 18)

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

    // MARK: - UI Rounded (레거시 호환)

    static let dvUITitle    = Font.custom("PretendardVariable", size: 20).weight(.semibold)
    static let dvUISubtitle = Font.custom("PretendardVariable", size: 17).weight(.medium)
    static let dvUIBody     = Font.custom("PretendardVariable", size: 15)
    static let dvUICaption  = Font.custom("PretendardVariable", size: 13).weight(.medium)
}
