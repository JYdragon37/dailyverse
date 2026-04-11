import SwiftUI

// MARK: - DevotionVerseView (Screen 2 — 오늘의 말씀 + 읽기 + 해석)

struct DevotionVerseView: View {

    let verse: Verse?
    @ObservedObject var viewModel: MeditationViewModel
    @EnvironmentObject private var authManager: AuthManager

    @State private var readingText: String = ""
    @FocusState private var isReadingFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.dvBgDeep.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 1. 오늘의 묵상 말씀
                    verseSectionHeader("📖 오늘의 묵상")
                    verseCard

                    dashedDivider

                    // 2. 말씀 읽기 / 쓰기 입력
                    readingSection

                    dashedDivider

                    // 3. 해석 (contemplationInterpretation 우선, 없으면 interpretation)
                    let interp = verse?.contemplationInterpretation ?? verse?.interpretation ?? ""
                    if !interp.isEmpty {
                        verseSectionHeader("💡 해석")
                        interpretationText(interp)
                    }

                    Color.clear.frame(height: 88)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            stickyCTA
        }
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

    // MARK: - 말씀 카드

    private var verseCard: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(verse?.verseFullKo ?? "말씀을 불러오는 중이에요...")
                .font(.dvVerseText)
                .foregroundColor(.white)
                .lineSpacing(18 * 0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dvBgSurface)
        )
    }

    // MARK: - 읽기 섹션

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            verseSectionHeader("✏️ 말씀 읽기")

            Text("오늘의 말씀을 천천히 읽거나 써보세요.")
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.55))

            VStack(alignment: .leading, spacing: 10) {
                // contemplationKo 우선, 없으면 verseShortKo
                let readingTarget = verse?.contemplationKo ?? verse?.verseShortKo ?? ""
                if !readingTarget.isEmpty {
                    Text(readingTarget)
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TextField("말씀을 따라 적어보세요... (선택)", text: $readingText, axis: .vertical)
                    .font(.dvBody)
                    .foregroundColor(.white)
                    .tint(.dvAccentGold)
                    .lineLimit(1...5)
                    .focused($isReadingFocused)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dvBgSurface)
            )
        }
    }

    // MARK: - 해석 텍스트

    private func interpretationText(_ text: String) -> some View {
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(.dvBody)
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(15 * 0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
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

            NavigationLink(
                destination: DevotionResponseView(
                    verse: verse,
                    readingText: readingText,
                    viewModel: viewModel
                )
            ) {
                Text("다음 →")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.dvAccentGold)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Color.dvBgDeep)
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
