import SwiftUI

struct MeditationWriteSheet: View {

    // MARK: - Parameters

    let existingEntry: MeditationEntry?
    let verseId: String
    let verseText: String          // 오늘의 말씀 전문 (묵상 시 참조용)
    let verseReference: String
    let mode: String
    let onSave: ([PrayerItem], String?) -> Void

    // MARK: - State

    @State private var combinedText: String = ""
    @State private var gratitudeText: String = ""
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed

    private var isEditing: Bool { existingEntry != nil }

    private var isSaveDisabled: Bool {
        combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvBgDeep.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // 오늘의 말씀 전문 카드
                        if !verseText.isEmpty {
                            todayVerseCard
                        }

                        // 말씀 참조 칩
                        if !verseReference.isEmpty {
                            verseReferenceCard
                        }

                        // 묵상 텍스트 영역
                        meditationSection

                        // 감사 기록 (선택)
                        gratitudeSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(isEditing ? "묵상 편집" : "오늘의 묵상")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dvBgDeep, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        handleSave()
                    }
                    .foregroundColor(isSaveDisabled ? .white.opacity(0.25) : .dvAccentGold)
                    .fontWeight(.semibold)
                    .disabled(isSaveDisabled)
                }
            }
            .onAppear {
                prefillIfEditing()
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Today Verse Card (묵상 시 오늘 말씀 전문)

    private var todayVerseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("묵상 한 구절")
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.4))

            Text(verseText)
                .font(.custom("Georgia-Italic", size: 16))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Verse Reference Card

    private var verseReferenceCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 14))
                .foregroundColor(.dvAccentGold)
            Text(verseReference)
                .font(.dvReference)
                .foregroundColor(.dvAccentGold)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dvAccentGold.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dvAccentGold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Meditation Section

    private var meditationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("묵상")
                .font(.dvUITitle)
                .foregroundColor(.white.opacity(0.85))

            TextField(
                "오늘 말씀에서 받은 것, 느낀 것, 기도하고 싶은 것을 자유롭게 적어보세요",
                text: $combinedText,
                axis: .vertical
            )
            .font(.dvBody)
            .foregroundColor(.white.opacity(0.85))
            .tint(.dvAccentGold)
            .lineLimit(4...12)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }

    // MARK: - Gratitude Section

    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("오늘 감사한 것")
                    .font(.dvUITitle)
                    .foregroundColor(.white.opacity(0.85))
                Text("(선택)")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.35))
                Spacer()
            }

            HStack(alignment: .top, spacing: 10) {
                Text("✨")
                    .font(.system(size: 16))
                    .padding(.top, 12)

                TextField("감사한 것을 자유롭게 적어보세요", text: $gratitudeText, axis: .vertical)
                    .font(.dvBody)
                    .foregroundColor(.white.opacity(0.85))
                    .tint(.dvAccentGold)
                    .lineLimit(1...5)
                    .padding(.vertical, 12)
                    .padding(.trailing, 10)
            }
            .padding(.leading, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }

    // MARK: - Actions

    private func handleSave() {
        let trimmed = combinedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 줄바꿈으로 구분된 라인들을 각각 PrayerItem으로 변환
        let lines = trimmed
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let items: [PrayerItem] = lines.isEmpty
            ? [PrayerItem.make(text: trimmed)]
            : lines.map { PrayerItem.make(text: $0) }

        let gratitude = gratitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(items, gratitude.isEmpty ? nil : gratitude)
        dismiss()
    }

    private func prefillIfEditing() {
        guard let entry = existingEntry else { return }
        // 기존 prayerItems를 줄바꿈으로 합쳐서 단일 텍스트로
        combinedText = entry.prayerItems
            .map { $0.text }
            .joined(separator: "\n")
        gratitudeText = entry.gratitudeNote ?? ""
    }
}

// MARK: - Preview

#Preview {
    MeditationWriteSheet(
        existingEntry: nil,
        verseId: "v_001",
        verseText: "두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라",
        verseReference: "이사야 41:10",
        mode: "morning"
    ) { prayerItems, gratitude in
        print("Saved \(prayerItems.count) items, gratitude: \(gratitude ?? "none")")
    }
    .preferredColorScheme(.dark)
}
