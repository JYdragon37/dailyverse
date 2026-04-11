import SwiftUI

// MARK: - MeditationView
// 묵상 탭 루트 뷰 — NavigationStack + DevotionHomeView (4화면 가이드 플로우)

struct MeditationView: View {

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager

    var body: some View {
        NavigationStack {
            DevotionHomeView()
                .navigationTitle("묵상")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(Color.dvBgDeep, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - A. TodayVerseCard

private struct TodayVerseCard: View {
    let verse: Verse?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 묵상")
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.45))

            if let verse = verse {
                Text(verse.verseShortKo)
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(verse.reference)
                    .font(.dvCaption)
                    .foregroundColor(.dvAccentGold)
            } else {
                // 스켈레톤 placeholder
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 14)
                        .padding(.trailing, 60)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 80, height: 12)
                        .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dvBgElevated)
        )
    }
}

// MARK: - B. QuickMeditationCard

private struct QuickMeditationCard: View {
    let todayEntry: MeditationEntry?
    @Binding var quickText: String
    var isQuickFocused: FocusState<Bool>.Binding
    let onSave: () -> Void
    let onSaveRead: () -> Void   // 입력 없이 "읽었어요"
    let onAdd: () -> Void
    let onEdit: () -> Void

    private var isSaveEnabled: Bool {
        !quickText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        if let entry = todayEntry {
            // 작성 완료 상태
            completedCard(entry: entry)
        } else {
            // 미작성 상태 — 인라인 입력
            emptyCard
        }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("오늘 묵상")
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.45))

            // 인라인 TextField
            TextField("오늘 이 말씀이 어떻게 다가왔나요...", text: $quickText, axis: .vertical)
                .font(.dvBody)
                .foregroundColor(.white)
                .tint(.dvAccentGold)
                .lineLimit(1...3)
                .focused(isQuickFocused)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.06))
                )

            // 하단: 읽었어요 + 저장
            HStack {
                // 읽었어요 (입력 없이 저장)
                Button(action: onSaveRead) {
                    Text("읽었어요")
                        .font(.dvCaption)
                        .foregroundColor(.white.opacity(0.35))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onSave) {
                    Text("저장")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSaveEnabled ? .dvAccentGold : .dvAccentGold.opacity(0.3))
                }
                .disabled(!isSaveEnabled)
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dvBgSurface)
        )
    }

    private func completedCard(entry: MeditationEntry) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dvBgSurface)

            // 좌측 골드 바
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.dvAccentGold)
                    .frame(width: 3)
                    .padding(.vertical, 1)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 12) {
                // 상단: 완료 레이블 + 편집 힌트
                HStack {
                    Text("오늘 묵상 ✓")
                        .font(.dvCaption)
                        .foregroundColor(.dvAccentGold)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }

                // 첫 번째 기도제목 텍스트
                if let firstItem = entry.prayerItems.first {
                    Text(firstItem.text)
                        .font(.dvBody)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if entry.prayerItems.count > 1 {
                        Text("외 \(entry.prayerItems.count - 1)개 더")
                            .font(.dvCaption)
                            .foregroundColor(.white.opacity(0.35))
                    }
                }

                // + 추가 버튼
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                        Text("추가")
                            .font(.dvCaption)
                    }
                    .foregroundColor(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onTapGesture { onEdit() }
    }
}

// MARK: - C. StreakSection

private struct StreakSection: View {
    @ObservedObject var streakManager: StreakManager

    private var last28Days: [(dateKey: String, dayNum: Int)] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        return (0..<28).reversed().map { daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
            return (f.string(from: date), cal.component(.day, from: date))
        }
    }

    private var todayKey: String { MeditationEntry.todayKey() }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 스트릭 헤더
            HStack {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 24))
                    Text("\(streakManager.currentStreak)일")
                        .font(.dvTitle)
                        .foregroundColor(.dvAccentGold)
                }
                Spacer()
                Text("연속 묵상")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.45))
            }

            // 28일 캘린더 그리드
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(last28Days, id: \.dateKey) { item in
                    let isMeditated = streakManager.meditatedDatesThisMonth.contains(item.dateKey)
                    let isToday = item.dateKey == todayKey

                    DayDotCell(
                        dayNum: item.dayNum,
                        isMeditated: isMeditated,
                        isToday: isToday
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dvBgSurface)
        )
    }
}

private struct DayDotCell: View {
    let dayNum: Int
    let isMeditated: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                // 기본 원
                Circle()
                    .fill(dotFill)
                    .frame(width: 26, height: 26)

                // 오늘 테두리 (미묵상)
                if isToday && !isMeditated {
                    Circle()
                        .stroke(Color.dvAccentGold, lineWidth: 2)
                        .frame(width: 26, height: 26)
                }

                // 오늘 + 묵상 완료: 체크
                if isToday && isMeditated {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Text("\(dayNum)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.40))
        }
    }

    private var dotFill: Color {
        if isMeditated { return .dvAccentGold }
        if isToday { return .clear }
        return Color.white.opacity(0.12)
    }
}

// MARK: - D. RecentMeditationsSection

private struct RecentMeditationsSection: View {
    let entries: [MeditationEntry]
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Text("최근 묵상")
                    .font(.dvSectionTitle)
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Button(action: onShowAll) {
                    Text("전체보기")
                        .font(.dvCaption)
                        .foregroundColor(.dvAccentGold)
                }
                .buttonStyle(.plain)
            }

            // 카드 목록
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                    RecentMeditationRow(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture { onShowAll() }

                    if idx < entries.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.horizontal, 0)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.dvBgSurface)
            )
        }
    }
}

private struct RecentMeditationRow: View {
    let entry: MeditationEntry

    private var formattedDate: String {
        let dfParser = DateFormatter()
        dfParser.dateFormat = "yyyy-MM-dd"
        let dfDisplay = DateFormatter()
        dfDisplay.locale = Locale(identifier: "ko_KR")
        dfDisplay.dateFormat = "M월 d일 E"
        if let date = dfParser.date(from: entry.dateKey) {
            return dfDisplay.string(from: date)
        }
        return entry.dateKey
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.45))

            if let firstItem = entry.prayerItems.first {
                Text(firstItem.text)
                    .font(.dvBody)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Full History Sheet

private struct FullHistorySheet: View {
    let entries: [MeditationEntry]
    let onToggleAnswered: (PrayerItem, MeditationEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvBgDeep.ignoresSafeArea()

                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.25))
                        Text("아직 지난 묵상이 없어요")
                            .font(.dvBody)
                            .foregroundColor(.white.opacity(0.45))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(entries) { entry in
                                HistoryEntryCard(
                                    entry: entry,
                                    onToggleAnswered: { item in
                                        onToggleAnswered(item, entry)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("전체 묵상")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dvBgDeep, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.dvAccentGold)
                }
            }
        }
    }
}

// MARK: - HistoryEntryCard (Full)

private struct HistoryEntryCard: View {
    let entry: MeditationEntry
    let onToggleAnswered: (PrayerItem) -> Void

    private var formattedDate: String {
        let dfParser = DateFormatter()
        dfParser.dateFormat = "yyyy-MM-dd"
        let dfDisplay = DateFormatter()
        dfDisplay.locale = Locale(identifier: "ko_KR")
        dfDisplay.dateFormat = "M월 d일 E"
        if let date = dfParser.date(from: entry.dateKey) {
            return dfDisplay.string(from: date)
        }
        return entry.dateKey
    }

    private var answeredCount: Int {
        entry.prayerItems.filter { $0.isAnswered }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(formattedDate)
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                if answeredCount > 0 {
                    Text("응답됨 \(answeredCount)개")
                        .font(.dvCaption)
                        .foregroundColor(.dvAccentGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.dvAccentGold.opacity(0.15))
                        )
                }
            }

            if !entry.verseReference.isEmpty {
                Text(entry.verseReference)
                    .font(.dvReference)
                    .foregroundColor(.dvAccentGold)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.prayerItems) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Button {
                            onToggleAnswered(item)
                        } label: {
                            Image(systemName: item.isAnswered ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundColor(item.isAnswered ? .dvAccentGold : .white.opacity(0.35))
                        }
                        .buttonStyle(.plain)

                        Text(item.text)
                            .font(.dvBody)
                            .foregroundColor(item.isAnswered ? .white.opacity(0.35) : .white.opacity(0.85))
                            .strikethrough(item.isAnswered, color: .white.opacity(0.35))
                            .lineLimit(2)
                    }
                }
            }

            if let note = entry.gratitudeNote, !note.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("✨")
                        .font(.system(size: 13))
                    Text(note)
                        .font(.dvBody)
                        .foregroundColor(.white.opacity(0.70))
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.dvBgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    MeditationView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
        .preferredColorScheme(.dark)
}
