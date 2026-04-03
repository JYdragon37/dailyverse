import SwiftUI

struct VerseDetailBottomSheet: View {
    let verse: Verse
    let onSave: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void

    @ObservedObject private var nicknameManager = NicknameManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // 1. 원문 (타이틀 유지)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("원문")
                            .font(.dvSectionTitle)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(verse.textFullKo)
                            .font(.dvVerseFullText)
                            .foregroundColor(.dvPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }

                    Text(verse.reference)
                        .font(.dvReference)
                        .foregroundColor(.dvAccentGold)

                    Divider()

                    // 2. 일상 적용 — 타이틀 없이, 닉네임 포함 (#5: "일상 적용" 타이틀 제거)
                    Text(applicationWithNickname)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)

                    Divider()

                    // 3. 해석 — 맨 아래 (#6)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("해석")
                            .font(.dvSectionTitle)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(verse.interpretation)
                            .font(.dvBody)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) { actionBar }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // 닉네임 + 일상 적용 텍스트
    private var applicationWithNickname: String {
        let nickname = nicknameManager.nickname
        return "\(nickname), \(verse.application)"
    }

    // #7 버튼 UI — 앱 톤앤매너 (dvGold + dark glass)
    private var actionBar: some View {
        HStack(spacing: 10) {
            // 저장 버튼 — dvGold 그라데이션 (주 CTA)
            Button(action: onSave) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                    Text("저장")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.dvGold, Color.dvGold.opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .accessibilityLabel("말씀 저장하기")

            // 다음 말씀 — Glassmorphism 보조 버튼
            Button(action: onNext) {
                Text("다음 말씀")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
            }
            .accessibilityLabel("다음 말씀 보기")

            // 닫기 — 미니 아이콘 버튼
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    )
                    .foregroundColor(.white.opacity(0.7))
            }
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            // 시트 하단 배경도 통일감 있게
            Color.dvBgDeep.opacity(0.85)
                .overlay(Rectangle().fill(.ultraThinMaterial))
        )
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            VerseDetailBottomSheet(
                verse: .fallbackMorning,
                onSave: {},
                onNext: {},
                onClose: {}
            )
        }
}
