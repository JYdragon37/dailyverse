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

                    // #5 원문 섹션 타이틀 추가
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

                    // 해석
                    VStack(alignment: .leading, spacing: 8) {
                        Text("해석")
                            .font(.dvSectionTitle)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(verse.interpretation)
                            .font(.dvBody)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // #5 일상 적용 — 닉네임 앞에 표시
                    VStack(alignment: .leading, spacing: 8) {
                        Text("일상 적용")
                            .font(.dvSectionTitle)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(applicationWithNickname)
                            .font(.dvBody)
                            .foregroundColor(.primary)
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

    // #5 닉네임 + 일상 적용 텍스트
    private var applicationWithNickname: String {
        let nickname = nicknameManager.nickname
        let text = verse.application
        // 첫 문장 앞에 "{닉네임}, " 추가
        return "\(nickname), \(text)"
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: onSave) {
                Label("저장", systemImage: "heart.fill")
                    .font(.dvBody)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("말씀 저장하기")

            Button(action: onNext) {
                Text("다음 말씀")
                    .font(.dvBody)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("다음 말씀 보기")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            VerseDetailBottomSheet(
                verse: .fallbackMorning,
                onSave: {},
                onNext: {},
                onClose: {}
            )
        }
}
