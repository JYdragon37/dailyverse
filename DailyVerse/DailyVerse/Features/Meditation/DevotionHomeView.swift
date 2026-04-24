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
    @State private var isCalendarExpanded = false   // 달력 펼치기/접기

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

    private var greetingIconColor: Color {
        switch greeting.icon {
        case "sun.max.fill", "cloud.sun.fill", "moon.fill", "moon.stars.fill":
            return Color(red: 0.98, green: 0.82, blue: 0.28) // 웜 옐로우
        default:
            return .dvAccentSky
        }
    }

    private var greetingBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: greeting.icon)
                .font(.system(size: 24))
                .foregroundColor(greetingIconColor)

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
        HStack(spacing: 0) {
            // 좌측 골드 인덱스 바
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color.dvAccentGold, Color.dvAccentGold.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 4)
                .padding(.leading, 20)

            // 말씀 내용
            VStack(alignment: .leading, spacing: 10) {
                // Today's verse 레이블
                Text("Today's verse")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.dvAccentGold.opacity(0.80))
                    .tracking(0.8)

                if let verse = viewModel.todayVerse {
                    Text(verse.verseShortKo)
                        .font(.custom("PretendardVariable", size: 17))
                        .foregroundColor(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(6)

                    Text(verse.reference)
                        .font(.dvCaption)
                        .foregroundColor(.dvAccentGold)
                } else {
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
            .padding(.vertical, 20)
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.dvBgSurface)
                // 좌측 골드 글로우 그라데이션
                LinearGradient(
                    colors: [Color.dvAccentGold.opacity(0.08), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dvAccentGold.opacity(0.12), lineWidth: 1)
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

            // 첫 방문 힌트 — 묵상 기록이 한 번도 없는 유저에게만 표시
            if viewModel.history.isEmpty {
                Text("💡 처음이라면, 마음에 걸리는 한 단어만 적어도 돼요")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.40))
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - 4. Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // 헤더 + 달력 토글 버튼
            HStack {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 24))
                    Text("\(displayedStreak)일")
                        .font(.dvTitle)
                        .foregroundColor(.dvAccentGold)
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isCalendarExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isCalendarExpanded ? "접기" : "전체 달력")
                            .font(.dvCaption)
                            .foregroundColor(.dvAccentGold)
                        Image(systemName: isCalendarExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.dvAccentGold)
                    }
                }
                .buttonStyle(.plain)
            }

            // Compact (14일) or Full (월별) 달력
            if isCalendarExpanded {
                DevotionCalendarGrid(
                    viewModel: viewModel,
                    history: viewModel.history,
                    onEntryTap: { entry in selectedMeditationEntry = entry }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                DevotionCompactGrid(
                    streakManager: viewModel.streakManager,
                    history: viewModel.history,
                    onEntryTap: { entry in selectedMeditationEntry = entry }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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

// MARK: - DevotionCompactGrid (기본 14일 뷰)

private struct DevotionCompactGrid: View {

    @ObservedObject var streakManager: StreakManager
    var history: [MeditationEntry]
    var onEntryTap: (MeditationEntry) -> Void

    private static let iso: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var last14Days: [(dateKey: String, dayNum: Int)] {
        let cal = Calendar.current
        return (0..<14).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            return (Self.iso.string(from: date), cal.component(.day, from: date))
        }
    }

    private var weekdayLabels: [String] {
        let cal = Calendar.current
        return (0..<7).map { col in
            let date = cal.date(byAdding: .day, value: -(13 - col), to: Date())!
            return Self.weekdays[cal.component(.weekday, from: date) - 1]
        }
    }

    private var todayKey: String { MeditationEntry.todayKey() }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(weekdayLabels, id: \.self) { name in
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.40))
                    .frame(maxWidth: .infinity)
            }
            ForEach(last14Days, id: \.dateKey) { item in
                let isMeditated = streakManager.meditatedDatesThisMonth.contains(item.dateKey)
                let isToday     = item.dateKey == todayKey
                let entry       = history.first { $0.dateKey == item.dateKey }
                DevotionDayDotCell(dayNum: item.dayNum,
                                   isMeditated: isMeditated,
                                   isToday: isToday)
                .contentShape(Rectangle())
                .onTapGesture { if isMeditated, let entry { onEntryTap(entry) } }
            }
        }
    }
}

// MARK: - DevotionCalendarGrid (월별 네비게이션)

private struct DevotionCalendarGrid: View {

    @ObservedObject var viewModel: MeditationViewModel
    var history: [MeditationEntry]
    var onEntryTap: (MeditationEntry) -> Void

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private static let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var todayKey: String { MeditationEntry.todayKey() }

    // 표시 중인 월의 헤더 텍스트 "2026년 4월"
    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: viewModel.calendarMonth)
    }

    // 미래 월 이동 불가
    private var canGoForward: Bool {
        let cal = Calendar.current
        return cal.compare(viewModel.calendarMonth, to: Date(), toGranularity: .month) == .orderedAscending
    }

    // 이번 달인지 여부
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(viewModel.calendarMonth, equalTo: Date(), toGranularity: .month)
    }

    // 해당 월의 날짜 그리드 (빈 셀 포함)
    private var gridCells: [(dateKey: String?, dayNum: Int?)] {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: viewModel.calendarMonth)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay) else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstDay) - 1  // 0=일

        var cells: [(dateKey: String?, dayNum: Int?)] = []
        // 앞 빈 셀
        for _ in 0..<firstWeekday { cells.append((nil, nil)) }
        // 날짜 셀
        let f = Self.isoFormatter
        for day in range {
            comps.day = day
            if let date = cal.date(from: comps) {
                cells.append((f.string(from: date), day))
            }
        }
        return cells
    }

    var body: some View {
        VStack(spacing: 12) {
            // ── 월 네비게이션 헤더 ──────────────────────────
            HStack {
                Button { viewModel.changeCalendarMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(monthTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                    if viewModel.isCalendarLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(.white.opacity(0.45))
                    }
                }

                Spacer()

                Button { viewModel.changeCalendarMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canGoForward ? .white.opacity(0.6) : .white.opacity(0.15))
                        .frame(width: 32, height: 32)
                }
                .disabled(!canGoForward)
            }

            // ── 요일 헤더 ───────────────────────────────────
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Self.weekdayNames, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.40))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                }
            }

            // ── 날짜 그리드 ─────────────────────────────────
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(gridCells.enumerated()), id: \.offset) { _, cell in
                    if let dateKey = cell.dateKey, let dayNum = cell.dayNum {
                        let isMeditated = viewModel.calendarMeditatedDates.contains(dateKey)
                        let isToday = dateKey == todayKey
                        let entry = history.first { $0.dateKey == dateKey }

                        DevotionDayDotCell(dayNum: dayNum,
                                           isMeditated: isMeditated,
                                           isToday: isToday)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isMeditated, let entry { onEntryTap(entry) }
                        }
                    } else {
                        // 빈 셀 (월 첫 주 앞부분)
                        Color.clear.frame(height: 28 + 5 + 14)
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
