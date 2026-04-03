import SwiftUI
import Combine

// MARK: - AlarmListView

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @EnvironmentObject private var permissionManager: PermissionManager

    // Fix 4: 날씨 + 오늘의 말씀
    @State private var cachedWeather: WeatherData?
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
                        // 빈 상태에서도 날씨/말씀 표시
                        VStack(spacing: 0) {
                            alarmTopSection
                            AlarmEmptyStateView {
                                viewModel.showAddEdit = true
                            }
                        }
                    } else {
                        // 날씨+말씀 섹션 + 알람 리스트
                        VStack(spacing: 0) {
                            alarmTopSection
                            alarmList
                        }
                    }
                }
            }
            .navigationTitle("Alarm")
            .task {
                // Fix 4: 날씨 캐시 로드
                cachedWeather = WeatherCacheManager().load()
                // Fix 4: 오늘의 말씀 로드 (DailyCacheManager → Core Data)
                let mode = AppMode.current()
                if let id = DailyCacheManager.shared.getVerseId(for: mode),
                   let verse = DailyCacheManager.shared.loadCachedVerse(id: id) {
                    todayVerse = verse
                } else {
                    todayVerse = OfflineFallbackManager.shared.fallbackVerse(for: mode)
                }
            }
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
        }
    }

    // MARK: - Alarm List

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

    // MARK: - 날씨 + 말씀 상단 섹션 (List 밖 — 상태 변경 즉시 반영 보장)
    @ViewBuilder
    private var alarmTopSection: some View {
        VStack(spacing: 10) {
            // 시간별 일기예보 (캐시된 날씨 있을 때만)
            if let weather = cachedWeather {
                AlarmHourlyForecastCard(weather: weather)
                    .padding(.horizontal, 16)
            }
            // 오늘의 말씀 (항상 표시 — 날씨 없어도 표시)
            if let verse = todayVerse {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(verse.textKo)
                            .font(.custom("Georgia-BoldItalic", size: 17))
                            .foregroundColor(.white.opacity(0.88))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verse.reference)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.dvGold)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
                )
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
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
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                    .padding(.bottom, 140)  // 탭바 위 더 여유있게
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

// MARK: - Fix 4: 알람 화면 시간별 일기예보 카드

private struct AlarmHourlyForecastCard: View {
    let weather: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                Text("시간별 일기예보")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
            }

            if weather.hourlyForecast.isEmpty {
                Text("예보 정보 없음")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(Array(weather.hourlyForecast.enumerated()), id: \.offset) { idx, item in
                            AlarmHourlyItem(item: item, isNow: idx == 0)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
    }
}

private struct AlarmHourlyItem: View {
    let item: HourlyForecastItem
    let isNow: Bool

    private var timeLabel: String {
        if isNow { return "지금" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h시"
        return f.string(from: item.time)
    }

    private var conditionIcon: String {
        switch item.condition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "sun.max.fill"
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            Text(timeLabel)
                .font(.system(size: 11, weight: isNow ? .semibold : .regular))
                .foregroundColor(.white.opacity(0.75))
                .frame(height: 15)
            Image(systemName: conditionIcon)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 24, height: 24)
            Text("\(item.temperature)°")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(height: 18)
        }
        .frame(width: 38)
    }
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
