import SwiftUI

// MARK: - DevotionHomeView
// 묵상 탭 Screen 1 — 홈 (인사말 + 말씀 카드 + CTA + 스트릭 섹션)

struct DevotionHomeView: View {

    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var nicknameManager = NicknameManager.shared

    @StateObject private var viewModel = MeditationViewModel()

    // MARK: - Animation State

    @State private var verseAppeared = false
    @State private var displayedStreak = 0
    @State private var hasLoadedOnce = false
    @State private var selectedMeditationEntry: MeditationEntry? = nil

    // MARK: - Greeting

    private var greeting: (icon: String, text: String) {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = nicknameManager.nickname
        switch hour {
        case 5..<12:
            return ("sun.max.fill", "\(name), 좋은 아침이야. 오늘 하루를 말씀과 함께 시작해볼까?")
        case 12..<18:
            return ("cloud.sun.fill", "\(name), 잠깐 쉬어가자. 바쁜 하루 중에 잠시 멈추는 시간.")
        case 18..<23:
            return ("moon.fill", "\(name), 오늘 하루도 벌써 해가지고 저녁 시간이네. 고생 많았어.")
        default:
            return ("sparkles", "\(name), 늦은 밤이네. 오늘 하루를 말씀으로 마무리해볼까.")
        }
    }

    // MARK: - Today Completed

    private var todayCompleted: Bool {
        let todayKey = MeditationEntry.todayKey()
        return viewModel.streakManager.meditatedDatesThisMonth.contains(todayKey)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // 1. 시간대 인사말 블록
                greetingBlock

                // 2. 말씀 카드
                verseCard

                // 3. CTA 버튼
                ctaButton

                // 4. 스트릭 섹션
                streakSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(Color.dvBgDeep.ignoresSafeArea())
        .fullScreenCover(item: $selectedMeditationEntry) { entry in
            MeditationEntryDetailView(entry: entry)
        }
        .task {
            let userId = authManager.userId ?? "local"
            await viewModel.load(userId: userId)
            withAnimation(.easeOut(duration: 0.6)) {
                verseAppeared = true
            }
            hasLoadedOnce = true
            animateStreakCount(to: viewModel.streakManager.currentStreak)
        }
        .onChange(of: viewModel.streakManager.currentStreak) { newValue in
            guard hasLoadedOnce else { return }
            animateStreakCount(to: newValue)
        }
    }

    // MARK: - 1. Greeting Block

    private var greetingBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: greeting.icon)
                .font(.system(size: 24))
                .foregroundColor(.dvAccentGold)

            Text(greeting.text)
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(5)

            Spacer()
        }
    }

    // MARK: - 2. Verse Card

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let verse = viewModel.todayVerse {
                Text(verse.verseShortKo)
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)

                Text(verse.reference)
                    .font(.dvCaption)
                    .foregroundColor(.dvAccentGold)
            } else {
                // 로딩 스켈레톤
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
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dvBgSurface)
        )
        .opacity(verseAppeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: verseAppeared)
    }

    // MARK: - 3. CTA Button

    @ViewBuilder
    private var ctaButton: some View {
        if todayCompleted {
            // 완료 상태
            HStack {
                Spacer()
                Text("오늘 묵상 완료 ✓")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                Spacer()
            }
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dvBgElevated)
            )
        } else {
            // 미완료 → DevotionVerseView로 이동
            NavigationLink {
                if let verse = viewModel.todayVerse {
                    DevotionVerseView(verse: verse, viewModel: viewModel)
                }
            } label: {
                HStack {
                    Spacer()
                    Text("오늘도 묵상 진행해볼까?")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.dvAccentGold)
                )
            }
            .disabled(viewModel.todayVerse == nil)
        }
    }

    // MARK: - 4. Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 28) {

            // 헤더
            HStack {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 24))
                    Text("\(displayedStreak)일")
                        .font(.dvTitle)
                        .foregroundColor(.dvAccentGold)
                }
                Spacer()
                Text("연속 묵상")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.45))
            }

            // 14일 캘린더 그리드
            DevotionCalendarGrid(
                streakManager: viewModel.streakManager,
                history: viewModel.history,
                onEntryTap: { entry in selectedMeditationEntry = entry }
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dvBgSurface)
        )
    }

    // MARK: - Helpers

    private func animateStreakCount(to target: Int) {
        guard target > 0 else {
            displayedStreak = 0
            return
        }
        let stepDuration = 0.8 / Double(target)
        for i in 0...target {
            let delay = stepDuration * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayedStreak = i
            }
        }
    }
}

// MARK: - DevotionCalendarGrid

private struct DevotionCalendarGrid: View {

    @ObservedObject var streakManager: StreakManager
    var history: [MeditationEntry]
    var onEntryTap: (MeditationEntry) -> Void

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    private var last14Days: [(dateKey: String, dayNum: Int)] {
        let cal = Calendar.current
        return (0..<14).reversed().map { daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
            return (Self.isoFormatter.string(from: date), cal.component(.day, from: date))
        }
    }

    /// 첫 번째 행(7일 전~13일 전)의 요일 헤더 레이블
    private var weekdayLabels: [String] {
        let cal = Calendar.current
        return (0..<7).map { col in
            let date = cal.date(byAdding: .day, value: -(13 - col), to: Date())!
            let weekday = cal.component(.weekday, from: date) - 1  // 0=일, 6=토
            return Self.weekdayNames[weekday]
        }
    }

    private var todayKey: String { MeditationEntry.todayKey() }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            // 요일 헤더 행
            ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .frame(maxWidth: .infinity)
            }

            // 날짜 셀 (14일)
            ForEach(last14Days, id: \.dateKey) { item in
                let isMeditated = streakManager.meditatedDatesThisMonth.contains(item.dateKey)
                let isToday = item.dateKey == todayKey
                let entry = history.first { $0.dateKey == item.dateKey }

                DevotionDayDotCell(
                    dayNum: item.dayNum,
                    isMeditated: isMeditated,
                    isToday: isToday
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if isMeditated, let entry {
                        onEntryTap(entry)
                    }
                }
            }
        }
    }
}

// MARK: - DevotionDayDotCell

private struct DevotionDayDotCell: View {
    let dayNum: Int
    let isMeditated: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(dotFill)
                    .frame(width: 28, height: 28)

                // 오늘 미완료: 골드 stroke
                if isToday && !isMeditated {
                    Circle()
                        .stroke(Color.dvAccentGold, lineWidth: 2)
                        .frame(width: 28, height: 28)
                }

                // 오늘 완료: 체크마크
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

// MARK: - Preview

#Preview {
    NavigationStack {
        DevotionHomeView()
            .environmentObject(AuthManager())
            .environmentObject(SubscriptionManager())
            .environmentObject(UpsellManager())
            .preferredColorScheme(.dark)
    }
}
