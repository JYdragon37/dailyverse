import SwiftUI
import Combine

struct VerseCardView: View {
    let verse: Verse
    let onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.dvCardFill)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.dvCardBorder, lineWidth: 0.5)
            )
            .overlay {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verse.textKo)
                        .font(.dvVerseDisplay)
                        .foregroundColor(.dvTextPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(verse.reference)
                            .font(.dvReference)
                            .foregroundColor(.dvTextSecondary)

                        if let firstTheme = verse.theme.first {
                            Text(firstTheme.capitalized)
                                .font(.dvCaption)
                                .foregroundColor(.dvVerseGold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.dvVerseGold.opacity(0.2))
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.dvTextMuted)
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                onTap()
            }
            .accessibilityLabel("\(verse.textKo). \(verse.reference)")
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VerseCardView(verse: .fallbackMorning) {
            // tap action
        }
        .padding(.horizontal, 20)
    }
}
