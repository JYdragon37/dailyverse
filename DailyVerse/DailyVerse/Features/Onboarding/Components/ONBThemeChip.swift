import SwiftUI
import UIKit

// Design Ref: §4.5 — 테마 선택 칩, 최대 3개 선택, 선택 시 dvAccentGold 배경

struct ONBThemeChip: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    var isDisabled: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            if isDisabled {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } else {
                onTap()
            }
        }) {
            HStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .black : (isDisabled ? .white.opacity(0.3) : .white))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.dvAccentGold : (isDisabled ? Color.white.opacity(0.06) : Color.white.opacity(0.14)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? Color.clear : (isDisabled ? Color.white.opacity(0.12) : Color.white.opacity(0.28)),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDisabled)
        .accessibilityLabel("\(label) 테마 \(isSelected ? "선택됨" : "선택 안됨")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        Color.dvBgDeep.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ONBThemeChip(emoji: "🌟", label: "용기", isSelected: true)  { }
            ONBThemeChip(emoji: "🕊️", label: "평안", isSelected: false) { }
            ONBThemeChip(emoji: "💡", label: "지혜", isSelected: false) { }
            ONBThemeChip(emoji: "🙏", label: "감사", isSelected: true)  { }
        }
        .padding()
    }
}
