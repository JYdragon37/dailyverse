import SwiftUI
import UIKit

// MARK: - EmojiView
// iOS 18 시뮬레이터 SwiftUI Text 이모지 렌더링 버그 우회 — UILabel 기반
struct EmojiView: UIViewRepresentable {
    let text: String
    let size: CGFloat

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        configure(label)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        configure(label)
    }

    private func configure(_ label: UILabel) {
        label.text = text
        label.font = UIFont.systemFont(ofSize: size)
    }
}

// MARK: - ONBThemeChip
// Design Ref: §4.5 — 테마 선택 칩, 최대 3개 선택, 선택 시 dvAccentGold 배경

struct ONBThemeChip: View {
    let emoji: String
    let label: String
    let iconColor: Color
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
            HStack(spacing: 8) {
                Image(systemName: emoji)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .black : (isDisabled ? .white.opacity(0.3) : iconColor))
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .black : (isDisabled ? .white.opacity(0.3) : .white))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
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
            ONBThemeChip(emoji: "star.fill",    label: "용기", iconColor: .yellow, isSelected: true)  { }
            ONBThemeChip(emoji: "bird.fill",    label: "평안", iconColor: .cyan,   isSelected: false) { }
            ONBThemeChip(emoji: "lightbulb.fill", label: "지혜", iconColor: .orange, isSelected: false) { }
            ONBThemeChip(emoji: "heart.fill",   label: "감사", iconColor: .pink,   isSelected: true)  { }
        }
        .padding()
    }
}
