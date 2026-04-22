import SwiftUI

// MARK: - DevotionVerseView (Screen 2 — 오늘의 말씀 + 텍스트 입력 + 읽기 + 해석)
// #6: 텍스트 입력칸을 '오늘의 묵상' 카드 바로 아래로 이동
// #7: 세 영역(말씀/읽기/해석) 폰트 통일 + 해석 들여쓰기 수정
// #9: CTA 버튼 배경을 전체 VStack에 적용

struct DevotionVerseView: View {

    let verse: Verse?
    @ObservedObject var viewModel: MeditationViewModel
    @EnvironmentObject private var authManager: AuthManager

    @State private var readingText: String = ""
    @FocusState private var isReadingFocused: Bool

    // 통일 폰트
    private let contentFont = Font.system(size: 17, weight: .regular)
    private let contentColor = Color.white.opacity(0.88)

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    readingSection
                    dashedDivider

                    let interp = verse?.contemplationInterpretation ?? verse?.interpretation ?? ""
                    if !interp.isEmpty {
                        verseSectionHeader("💡 해석")
                        interpretationText(interp)
                        dashedDivider
                    }

                    verseSectionHeader("📖 오늘의 묵상")
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
                    Text("오늘의 묵상")
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
            Text(verse?.verseShortKo ?? "말씀을 불러오는 중이에요...")
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
        TextField("말씀을 따라 적어보세요 (선택)", text: $readingText, axis: .vertical)
            .font(contentFont)
            .foregroundColor(.white)
            .tint(.dvAccentGold)
            .lineLimit(1...5)
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
            verseSectionHeader("✏️ 말씀 읽기")

            let readingTarget = verse?.contemplationKo ?? verse?.verseShortKo ?? ""
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
                        if let reference = verse?.reference {
                            Text("— \(reference)")
                                .font(.dvReference)
                                .foregroundColor(.dvAccentGold)
                        }
                        Text("개역개정")
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
                    viewModel: viewModel
                )
            ) {
                Text("다음 →")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 76)  // DVTabBar 위 여백 유지
        }
        .background(Color.dvBgDeep)
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
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
