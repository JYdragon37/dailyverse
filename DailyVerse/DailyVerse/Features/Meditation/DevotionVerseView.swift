import SwiftUI

// MARK: - DevotionVerseView (Screen 2 — 오늘의 말씀 + 텍스트 입력 + 읽기 + 해석)
// #6: 텍스트 입력칸을 '오늘의 묵상' 카드 바로 아래로 이동
// #7: 세 영역(말씀/읽기/해석) 폰트 통일 + 해석 들여쓰기 수정
// #9: CTA 버튼 배경을 전체 VStack에 적용

struct DevotionVerseView: View {

    let verse: Verse?
    @ObservedObject var viewModel: MeditationViewModel
    @EnvironmentObject private var authManager: AuthManager

    // 수정 모드 pre-fill (기본값: 빈 문자열 = 신규 작성)
    var prefillReadingText: String = ""
    var editMode: Bool = false
    var prefillPrayer: String = ""
    var prefillGratitude: [String] = []

    @State private var readingText: String = ""
    @FocusState private var isReadingFocused: Bool

    // 통일 폰트
    private let contentFont = Font.system(size: 17, weight: .regular)
    private let contentColor = Color.white.opacity(0.88)

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // 신규 작성이 아닐 때(수정 모드) onAppear에서 pre-fill
                VStack(alignment: .leading, spacing: 24) {
                    readingSection
                    dashedDivider

                    let interp = verse?.interpretationText(lang: UserDefaults.standard.string(forKey: "appLanguage") ?? "ko") ?? ""
                    if !interp.isEmpty {
                        verseSectionHeader("💡 " + appLanguageString("verseDetail.interpretation.label"))
                        interpretationText(interp)
                        dashedDivider
                    }

                    verseSectionHeader("📖 " + appLanguageString("meditation.today"))
                    verseCard
                    writingInput

                    Color.clear.frame(height: 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.immediately)

            stickyCTA
        }
        .background(Color.dvBgDeep.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dvBgDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(appLanguageString("meditation.today"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - 1. 말씀 카드

    private var verseCard: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(verse?.verseShort(lang: UserDefaults.standard.string(forKey: "appLanguage") ?? "ko") ?? appLanguageString("saved.loading"))
                .font(contentFont)
                .foregroundColor(contentColor)
                .lineSpacing(17 * 0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dvBgSurface)
        )
    }

    // MARK: - 2. 텍스트 입력

    private var writingInput: some View {
        TextField(appLanguageString("meditation.readingPrompt"), text: $readingText, axis: .vertical)
            .font(contentFont)
            .foregroundColor(.white)
            .tint(.dvAccentGold)
            .lineLimit(2...6)
            .focused($isReadingFocused)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isReadingFocused ? Color.dvAccentGold.opacity(0.5) : Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isReadingFocused)
    }

    // MARK: - 3. 말씀 읽기

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            verseSectionHeader(appLanguageString("meditation.readingSection"))

            let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "ko"
            let readingTarget = verse?.verseFull(lang: lang) ?? verse?.verseShort(lang: lang) ?? ""  // 개역한글/KJV 원문 통일
            if !readingTarget.isEmpty {
                VStack(alignment: .trailing, spacing: 12) {
                    Text(readingTarget)
                        .font(contentFont)
                        .foregroundColor(contentColor)
                        .lineSpacing(17 * 0.7)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 오늘의 묵상 카드와 동일한 출처 표기
                    VStack(alignment: .trailing, spacing: 4) {
                        if let reference = verse?.referenceDisplay {
                            Text("— \(reference)")
                                .font(.dvReference)
                                .foregroundColor(.dvAccentGold)
                        }
                        Text(appLanguageString("meditation.translationCredit"))
                            .font(.dvCaption)
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.dvBgSurface)
                )
            }
        }
    }

    // MARK: - 4. 해석 텍스트 (#7 들여쓰기 수정 — padding 제거)

    private func interpretationText(_ text: String) -> some View {
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(contentFont)
                    .foregroundColor(contentColor)
                    .lineSpacing(17 * 0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.dvBgSurface)
        )
    }

    // MARK: - Sticky CTA

    private var stickyCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.dvBgDeep.opacity(0), Color.dvBgDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            NavigationLink(
                destination: DevotionResponseView(
                    verse: verse,
                    readingText: readingText,
                    viewModel: viewModel,
                    prefillPrayer: prefillPrayer,
                    prefillGratitude: prefillGratitude,
                    isEditMode: editMode
                )
            ) {
                Text(editMode ? appLanguageString("meditation.editResponse") : appLanguageString("meditation.writeResponse"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.dvAccentGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.dvAccentGold.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.dvAccentGold.opacity(0.35), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 76)  // DVTabBar 위 여백 유지
        }
        .background(Color.dvBgDeep)
        .onAppear {
            if readingText.isEmpty && !prefillReadingText.isEmpty {
                readingText = prefillReadingText
            }
        }
    }

    // MARK: - Helpers

    private func verseSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
    }

    private var dashedDivider: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .foregroundColor(Color.white.opacity(0.20))
        }
        .frame(height: 1)
    }

    private var formattedDate: String {
        let isEnglish = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isEnglish ? "en_US" : "ko_KR")
        formatter.dateFormat = isEnglish ? "MMM d" : "M월 d일"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DevotionVerseView(
            verse: .fallbackRiseIgnite,
            viewModel: MeditationViewModel()
        )
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
    }
    .preferredColorScheme(.dark)
}
