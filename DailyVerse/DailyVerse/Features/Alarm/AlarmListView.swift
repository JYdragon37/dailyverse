import SwiftUI
import Combine

// MARK: - AlarmListView

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @EnvironmentObject private var permissionManager: PermissionManager

    @State private var todayVerse: Verse?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.dvBgDeep, Color(hex: "#0D1033"), Color(hex: "#1A0E2E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if permissionManager.notificationStatus == .denied {
                        NotificationPermissionBanner()
                    }

                    if viewModel.alarms.isEmpty {
                        VStack(spacing: 0) {
                            alarmTopSection
                            AlarmEmptyStateView {
                                viewModel.showAddEdit = true
                            }
                        }
                    } else {
                        // 오늘의 말씀 + 알람 리스트를 하나의 List로 → 함께 스크롤
                        alarmListWithHeader
                    }
                }
            }
            .navigationTitle("Alarm")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.dvBgDeep.opacity(0.85), for: .navigationBar)
            .toolbar {
                if viewModel.alarms.count < 3 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showAddEdit = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .accessibilityLabel("새 알람 추가")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addAlarmButton
            }
            .overlay(alignment: .bottom) {
                toastOverlay
            }
        }
        .sheet(isPresented: $viewModel.showAddEdit) {
            AlarmAddEditView(alarm: nil) { newAlarm in
                viewModel.saveAlarm(newAlarm)
            }
        }
        .sheet(item: $viewModel.editingAlarm) { alarm in
            AlarmAddEditView(alarm: alarm) { updated in
                viewModel.saveAlarm(updated)
            }
        }
        .onAppear {
            viewModel.loadAlarms()
            Task { await permissionManager.checkNotification() }
            refreshTodayVerse()  // 탭 진입마다 새 말씀
        }
    }

    // MARK: - 탭마다 말씀 변경

    private func refreshTodayVerse() {
        let mode = AppMode.current()
        // Core Data 캐시에서 랜덤 말씀 선택 (현재 말씀 제외)
        let currentId = todayVerse?.id
        if let id = DailyCacheManager.shared.getVerseId(for: mode),
           let verse = DailyCacheManager.shared.loadCachedVerse(id: id),
           verse.id != currentId {
            todayVerse = verse
            return
        }
        // 폴백 구절 중 랜덤
        let fallbacks = Verse.fallbackVerses.filter { $0.id != currentId }
        todayVerse = fallbacks.randomElement() ?? OfflineFallbackManager.shared.fallbackVerse(for: mode)
    }

    // MARK: - 오늘의 말씀 + 알람 리스트 통합 (함께 스크롤)

    private var alarmListWithHeader: some View {
        List {
            // 오늘의 말씀 — verse 있을 때만 Section 표시 (nil 시 빈 섹션 방지)
            if todayVerse != nil {
                Section {
                    alarmTopSection
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 28, bottom: 8, trailing: 28))
                }
            }

            // 알람 카드들
            ForEach(sortedAlarms) { alarm in
                AlarmCardRow(
                    alarm: alarm,
                    onToggle: { viewModel.toggleAlarm(id: alarm.id) }
                )
                .contentShape(Rectangle())
                .onTapGesture { viewModel.editingAlarm = alarm }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteAlarm(id: alarm.id)
                        viewModel.toastMessage = "알람이 삭제되었습니다"
                    } label: { Label("삭제", systemImage: "trash") }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 28, bottom: 6, trailing: 28))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Alarm List (빈 상태용, 기존 유지)

    private var sortedAlarms: [Alarm] {
        viewModel.alarms.sorted { a, b in
            let cal = Calendar.current
            let aH = cal.component(.hour, from: a.time)
            let aM = cal.component(.minute, from: a.time)
            let bH = cal.component(.hour, from: b.time)
            let bM = cal.component(.minute, from: b.time)
            return aH * 60 + aM < bH * 60 + bM
        }
    }

    // MARK: - 말씀 상단 섹션
    @ViewBuilder
    private var alarmTopSection: some View {
        if let verse = todayVerse {
            VStack(alignment: .center, spacing: 8) {

                // 섹션 레이블 — 가운데 정렬
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.dvGold)
                    Text("오늘의 말씀")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.dvGold)
                }

                // 말씀 카드 — 가운데 정렬 고정 높이
                VStack(alignment: .center, spacing: 8) {
                    Text(verse.alarmTextKo ?? verse.textKo)
                        .font(.custom("Georgia-BoldItalic", size: 16))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(4)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)

                    Text(verse.reference)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.dvGold.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                // 고정 높이: alarmTextKo 최대 50자 기준
                .frame(height: 110)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.dvGold.opacity(0.11),
                                    Color.dvGold.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.dvGold.opacity(0.22), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
            }
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
    }

    private var alarmList: some View {
        List {
            // 알람 카드들만
            ForEach(sortedAlarms) { alarm in
                AlarmCardRow(
                    alarm: alarm,
                    onToggle: { viewModel.toggleAlarm(id: alarm.id) }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.editingAlarm = alarm
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteAlarm(id: alarm.id)
                        viewModel.toastMessage = "알람이 삭제되었습니다"
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                    .accessibilityLabel("알람 삭제")
                }
                .listRowBackground(Color.clear)  // 카드 자체 배경 사용
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 28, bottom: 6, trailing: 28))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - 하단 추가 버튼

    private var addAlarmButton: some View {
        Group {
            if !viewModel.alarms.isEmpty {
                Button {
                    viewModel.showAddEdit = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("새 알람 추가")
                            .font(.dvBody)
                        // (최대 3개) 텍스트 제거
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    // #3 dvGold 그라데이션 버튼
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color.dvGold, Color.dvGold.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .disabled(viewModel.alarms.count >= 3)
                .opacity(viewModel.alarms.count >= 3 ? 0.45 : 1.0)
                .accessibilityLabel(viewModel.alarms.count >= 3 ? "알람 최대 3개 도달" : "새 알람 추가")
            }
        }
    }

    // MARK: - 토스트 오버레이

    @ViewBuilder
    private var toastOverlay: some View {
        if let message = viewModel.toastMessage {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Text(message)
                        .font(.dvBody)
                        .foregroundColor(.white)

                    Button("되돌리기") {
                        withAnimation(.dvSheetAppear) {
                            viewModel.undoDelete()
                        }
                    }
                    .font(.dvBody.weight(.semibold))
                    .foregroundColor(.dvAccent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.78))
                )
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.dvSheetAppear, value: viewModel.toastMessage)
        }
    }
}

// MARK: - AlarmCardRow

private struct AlarmCardRow: View {
    let alarm: Alarm
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // #3 시간: 흰색 (활성) / 힌트 (비활성)
                Text(formattedTime)
                    .font(.system(size: 36, weight: .thin, design: .default))
                    .foregroundColor(alarm.isEnabled ? .white : Color.dvTextHint)

                if !alarm.label.isEmpty {
                    Text(alarm.label)
                        .font(.dvCaption)
                        .foregroundColor(Color.dvTextSecondary)
                }

                HStack(spacing: 6) {
                    Text(alarm.repeatSummary)
                        .font(.dvCaption)
                        .foregroundColor(Color.dvTextSecondary)

                    Text("·")
                        .font(.dvCaption)
                        .foregroundColor(Color.dvTextSecondary)

                    // #3 테마 칩: dvGold
                    Text(alarm.theme.capitalized)
                        .font(.dvCaption)
                        .foregroundColor(.dvGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.dvGold.opacity(0.15))
                        )
                }

                Text(nextFireText(for: alarm))
                    .font(.dvCaption)
                    .foregroundColor(nextFireColor(for: alarm))
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(Color.dvGold)   // #3 골드 토글
            .accessibilityLabel("\(formattedTime) 알람 \(alarm.isEnabled ? "켜짐" : "꺼짐")")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        // #3 Glassmorphism 카드 (그림자 제거)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.dvBorderMid, lineWidth: 1)
                )
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.55)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: alarm.time)
    }

    private func nextFireText(for alarm: Alarm) -> String {
        guard alarm.isEnabled else { return "꺼져 있음" }
        let cal = Calendar.current
        var comp = cal.dateComponents([.hour, .minute], from: alarm.time)
        comp.second = 0
        guard let fire = cal.nextDate(
            after: Date(),
            matching: comp,
            matchingPolicy: .nextTime
        ) else { return "" }

        let interval = fire.timeIntervalSinceNow
        if cal.isDateInToday(fire) {
            let hours = Int(interval / 3600)
            let mins = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if hours > 0 { return "오늘 \(hours)시간 \(mins)분 뒤" }
            return "오늘 \(mins)분 뒤"
        }
        return "내일"
    }

    private func nextFireColor(for alarm: Alarm) -> Color {
        guard alarm.isEnabled else { return .secondary }
        let cal = Calendar.current
        var comp = cal.dateComponents([.hour, .minute], from: alarm.time)
        comp.second = 0
        guard let fire = cal.nextDate(
            after: Date(),
            matching: comp,
            matchingPolicy: .nextTime
        ) else { return .secondary }
        return cal.isDateInToday(fire) ? .dvAccent : .secondary
    }
}

// MARK: - 알림 권한 경고 배너

private struct NotificationPermissionBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.slash.fill")
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("알림 권한이 없어요. 설정에서 허용해주세요")
                .font(.dvCaption)
                .foregroundColor(.primary)

            Spacer()

            Button("설정") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.dvCaption.weight(.semibold))
            .foregroundColor(.orange)
            .accessibilityLabel("알림 권한 설정 열기")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.12))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - 빈 상태 뷰

private struct AlarmEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // #3 다크 테마 Empty State
            Image(systemName: "alarm")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(Color.dvTextHint)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("아직 알람이 없어요")
                    .font(.dvTitle)
                    .foregroundColor(.white)

                Text("알람을 설정하면 매일 말씀과 함께\n하루를 시작할 수 있어요")
                    .font(.dvBody)
                    .foregroundColor(Color.dvTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onAdd()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("첫 알람 추가하기")
                        .font(.dvBody.weight(.semibold))
                }
                .frame(maxWidth: 240)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.dvGold, Color.dvGold.opacity(0.75)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
            .accessibilityLabel("첫 알람 추가하기")

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview("알람 있음") {
    let vm = AlarmViewModel()
    let now = Date()
    let calendar = Calendar.current
    var comps6 = calendar.dateComponents([.year, .month, .day], from: now)
    comps6.hour = 6; comps6.minute = 0
    var comps22 = calendar.dateComponents([.year, .month, .day], from: now)
    comps22.hour = 22; comps22.minute = 0

    vm.alarms = [
        Alarm(time: calendar.date(from: comps6) ?? now,
              repeatDays: [1, 2, 3, 4, 5],
              theme: "hope",
              isEnabled: true,
              label: "아침의 말씀",
              snoozeInterval: 5),
        Alarm(time: calendar.date(from: comps22) ?? now,
              repeatDays: [0, 6],
              theme: "peace",
              isEnabled: false,
              label: "저녁 묵상",
              snoozeInterval: 10)
    ]

    return AlarmListView()
        .environmentObject(PermissionManager())
}


#Preview("알람 없음") {
    AlarmListView()
        .environmentObject(PermissionManager())
}

#Preview("알림 권한 거부") {
    let pm = PermissionManager()
    // Preview에서 denied 상태 시뮬레이션은 실제 권한 API 우회 불가 — 런타임 확인
    return AlarmListView()
        .environmentObject(pm)
}
