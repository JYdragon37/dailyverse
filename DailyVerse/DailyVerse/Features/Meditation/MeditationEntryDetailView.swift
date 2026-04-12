import SwiftUI

// MARK: - MeditationEntryDetailView
// 묵상 달력 날짜 탭 시 표시되는 풀스크린 상세 뷰

struct MeditationEntryDetailView: View {
    let entry: MeditationEntry
    @Environment(\.dismiss) private var dismiss

    @State private var verse: Verse? = nil
    @State private var showDetailSheet = false

    // MARK: - Background

    private var backgroundGradient: LinearGradient {
        let mode = AppMode(rawValue: entry.mode) ?? AppMode.current()
        return LinearGradient(colors: mode.gradientColors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Verse Block

    private var verseBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verse?.verseFullKo ?? entry.verseReference)
                .font(.system(size: 21, weight: .semibold))
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

            HStack(spacing: 8) {
                Text(entry.verseReference)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 18)

            // #15: 항상 탭 힌트 표시
            HStack(spacing: 4) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .medium))
                Text("묵상 기록 보기")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.5))
            .padding(.top, 20)
        }
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
    }

    // MARK: - Detail Sheet

    private var meditationDetailSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 8)

                // 날짜
                Text(formattedEntryDate)
                    .font(.dvCaption)
                    .foregroundColor(.secondary)

                // 해석 + 적용
                interpretationSection
                applicationSection

                // 질문
                VStack(alignment: .leading, spacing: 8) {
                    Label("묵상 질문", systemImage: "bubble.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(questionText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(5)
                }

                // 읽기 텍스트 (있을 때만)
                if let reading = entry.readingText, !reading.isEmpty {
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("말씀 필사", systemImage: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(reading)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }
                }

                // 한 줄 기도 (있을 때만)
                if let prayer = entry.prayer, !prayer.isEmpty {
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("한 줄 기도", systemImage: "hands.sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(prayer)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }
                }

                // 기도 제목들 (있을 때만)
                if !entry.prayerItems.isEmpty {
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("기도 제목", systemImage: "heart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        ForEach(entry.prayerItems) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: item.isAnswered ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isAnswered ? .dvAccentGold : .secondary)
                                    .accessibilityLabel(item.isAnswered ? "응답됨" : "기도 중")
                                Text(item.text)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(item.isAnswered ? .secondary : .primary)
                                    .strikethrough(item.isAnswered, color: .secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 해석 섹션 (contemplationInterpretation 우선, 없으면 interpretation)

    @ViewBuilder
    private var interpretationSection: some View {
        let text = verse?.contemplationInterpretation ?? verse?.interpretation ?? ""
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("해석", systemImage: "lightbulb")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(5)
            }
            Divider().padding(.vertical, 4)
        }
    }

    // MARK: - 일상 적용 섹션

    @ViewBuilder
    private var applicationSection: some View {
        let text = verse?.application ?? ""
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("일상 적용", systemImage: "heart.text.square")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(5)
            }
            Divider().padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private var questionText: String {
        verse?.question
            ?? "이 말씀이 오늘 나의 삶에 어떻게 다가왔나요?"
    }

    private var formattedEntryDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        let display = DateFormatter()
        display.locale = Locale(identifier: "ko_KR")
        display.dateFormat = "yyyy년 M월 d일 EEEE"
        if let date = parser.date(from: entry.dateKey) {
            return display.string(from: date)
        }
        return entry.dateKey
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 배경: imageUrl 있으면 저장 당시 이미지, 없으면 모드 그라데이션
            if let urlString = entry.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        backgroundGradient
                    }
                }
                .ignoresSafeArea()
                .clipped()
            } else {
                backgroundGradient.ignoresSafeArea()
            }

            // 다크 오버레이 (이미지/그라데이션 위 가독성 확보)
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // 말씀 블록 — 48% 위치
            GeometryReader { geo in
                let w = geo.size.width
                let hPad = max(w * 0.13, 40.0)
                verseBlock
                    .padding(.horizontal, hPad)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .position(x: w / 2, y: geo.size.height * 0.48)
                    .onTapGesture {
                        showDetailSheet = true  // #15: 항상 탭 가능
                    }
                    .accessibilityLabel("묵상 기록 보기")
                    .accessibilityHint("탭하면 묵상 내용을 확인할 수 있어요")
            }
        }
        // #16: 상단 오버레이 — 날짜(좌) + 닫기(우)
        .overlay(alignment: .top) {
            HStack(alignment: .center) {
                // 날짜 (상단 좌측, 일기처럼)
                Text(formattedEntryDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

                Spacer()

                // 닫기 버튼 (우상단)
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(8)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
                .accessibilityLabel("닫기")
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
        .sheet(isPresented: $showDetailSheet) {
            meditationDetailSheet
        }
        .task {
            verse = DailyCacheManager.shared.loadCachedVerse(id: entry.verseId)
                ?? Verse.fallbackVerses.first { $0.id == entry.verseId }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleEntry = MeditationEntry(
        id: "preview-001",
        userId: "local",
        dateKey: "2026-04-10",
        verseId: "fallback_rise_ignite",
        verseReference: "이사야 41:10",
        mode: "rise_ignite",
        prayerItems: [
            PrayerItem(text: "가족의 건강", isAnswered: false),
            PrayerItem(text: "오늘 회의 잘 마무리되게", isAnswered: true)
        ],
        gratitudeNote: nil,
        createdAt: Date(),
        updatedAt: Date(),
        source: "guided",
        prayer: "주님, 오늘 하루도 함께해 주세요.",
        readingText: "두려워하지 말라 내가 너와 함께 함이라",
        imageUrl: nil
    )
    MeditationEntryDetailView(entry: sampleEntry)
}
