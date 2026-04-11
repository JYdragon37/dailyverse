import SwiftUI

struct VerseCardView: View {
    let verse: Verse
    var image: VerseImage? = nil
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 본문 텍스트 — 핵심 메시지, 크게
            Text(verse.verseShortKo)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)

            // 출처 + 테마
            HStack(spacing: 8) {
                Text(verse.reference)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                if let firstTheme = verse.theme.first, firstTheme != "all" {
                    Text(firstTheme.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.dvVerseGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dvVerseGold.opacity(0.2))
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
        .onTapGesture { onTap() }
        .accessibilityLabel("\(verse.verseShortKo). \(verse.reference)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.28), Color(red: 0.05, green: 0.05, blue: 0.15)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
        VerseCardView(verse: .fallbackMorning) {}
            .padding(.horizontal, 20)
    }
}
