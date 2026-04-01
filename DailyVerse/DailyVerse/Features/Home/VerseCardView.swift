import SwiftUI
import Combine

struct VerseCardView: View {
    let verse: Verse
    let onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verse.textKo)
                        .font(.dvVerseText)
                        .foregroundColor(.dvPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(verse.reference)
                            .font(.dvReference)
                            .foregroundColor(.secondary)

                        if let firstTheme = verse.theme.first {
                            Text(firstTheme.capitalized)
                                .font(.dvCaption)
                                .foregroundColor(.dvAccent)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.dvAccent)
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
