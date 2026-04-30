import SwiftUI
import Combine

// MARK: - AlarmListView

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @EnvironmentObject private var permissionManager: PermissionManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var todayVerse: Verse?
    @State private var showMaxAlarmsAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvBgDeep.ignoresSafeArea()

                VStack(spacing: 0) {
                    if permissionManager.notificationStatus == .denied {
                        NotificationPermissionBanner()
                    }

                    if viewModel.alarms.isEmpty {
                        VStack(spacing: 0) {
                            AlarmEmptyStateView { viewModel.showAddEdit = true }
                        }
                    } else {
                        alarmListWithHeader
                    }
                }
            }
            .navigationTitle("알람")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.dvBgDeep.opacity(0.85), for: .navigationBar)
            .toolbar {
                if viewModel.alarms.count < 3 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { viewModel.showAddEdit = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .accessibilityLabel("새 알람 추가")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { addAlarmButton }
            .overlay(alignment: .bottom) { toastOverlay }
        }
        .sheet(isPresented: $viewModel.showAddEdit) {
            AlarmAddEditView(alarm: nil) { newAlarm in viewModel.saveAlarm(newAlarm) }
        }
        .sheet(item: $viewModel.editingAlarm) { alarm in
            AlarmAddEditView(alarm: alarm) { updated in viewModel.saveAlarm(updated) }
        }
        .onAppear {
            viewModel.loadAlarms()
            Task { await permissionManager.checkNotification() }
            refreshTodayVerse()
        }
        // 온보딩에서 알람 저장 완료 시 즉시 반영 (알람 탭이 이미 열려있는 경우)
        .onReceive(NotificationCenter.default.publisher(for: .dvAlarmSaved)) { _ in
            viewModel.loadAlarms()
        }
        .alert("알람 권한 제한", isPresented: $viewModel.showAlarmKitDeniedAlert) {
            Button("설정 열기") { permissionManager.openAppSettings() }
            Button("확인", role: .cancel) {}
        } message: {
            Text("AlarmKit 권한이 거부되어 있어요.\n앱을 완전히 종료하면 알람이 울리지 않을 수 있어요.\n설정 앱에서 morning manna → 알람 권한을 허용해주세요.")
        }
    }

    // MARK: - 말씀 로드

    private func refreshTodayVerse() {
        let mode = AppMode.current()
        let currentId = todayVerse?.id
        let pool = DailyCacheManager.shared.loadAlarmTopKoPool(excluding: currentId)
        if let verse = pool.randomElement() { todayVerse = verse; return }
        if let id = DailyCacheManager.shared.getVerseId(for: mode),
           let verse = DailyCacheManager.shared.loadCachedVerse(id: id),
           verse.id != currentId { todayVerse = verse; return }
        let fallbacks = Verse.fallbackVerses.filter { $0.id != currentId }
        todayVerse = fallbacks.randomElement() ?? OfflineFallbackManager.shared.fallbackVerse(for: mode)
    }

    // MARK: - 다음 활성 알람

    private var nextEnabledAlarm: Alarm? {
        sortedAlarms.first(where: { $0.isEnabled })
    }

    // MARK: - 통합 리스트 (헤더 + 알람)

    private var alarmListWithHeader: some View {
        List {
            // [항목 1] 다가오는 알람 박스
            Section {
                upcomingAlarmSection
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20))
            }

            // [항목 2] 알람 카드 3개 유지
            ForEach(sortedAlarms) { alarm in
                AlarmCardRow(alarm: alarm, onToggle: { viewModel.toggleAlarm(id: alarm.id) })
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
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
            }

            // [광고] 알람 목록 하단 배너 (Free 유저만 표시)
            if !subscriptionManager.isPremium {
            Section {
                SmartBannerAdView()
                    .frame(width: 320, height: 50)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20))
            }
            } // if !subscriptionManager.isPremium
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - 다가오는 알람 섹션

    @ViewBuilder
    private var upcomingAlarmSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("다가오는 알람")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            if let alarm = nextEnabledAlarm {
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
                        .padding(.leading, 18)

                    VStack(alignment: .leading, spacing: 14) {
                        // 시간 표시
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(alarmHourMinute(alarm.time))
                                .font(.system(size: 44, weight: .bold, design: .default))
                                .foregroundColor(.white)
                            Text(alarmAmPm(alarm.time))
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        // 카운트다운
                        Text(countdownText(for: alarm))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))

                        // 구분선
                        Divider()
                            .background(Color.white.opacity(0.12))

                        // 오늘의 말씀
                        if let verse = todayVerse {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("For you")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.dvAccentGold.opacity(0.80))
                                    .tracking(0.8)

                                Text("\u{201C}\(verse.alarmTopKo ?? verse.verseShortKo)\u{201D}")
                                    .font(.custom("PretendardVariable", size: 15))
                                    .foregroundColor(.white.opacity(0.88))
                                    .lineSpacing(4)

                                Text(verse.reference)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.dvGold.opacity(0.75))
                            }
                        }
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.dvBgSurface)
                        // 좌측 골드 글로우 그라데이션
                        LinearGradient(
                            colors: [Color.dvAccentGold.opacity(0.08), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.dvAccentGold.opacity(0.12), lineWidth: 1)
                )
            } else {
                // 활성 알람 없을 때
                Text("활성화된 알람이 없어요")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - 시간 포맷 헬퍼

    private func alarmHourMinute(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "hh:mm"
        return f.string(from: date)
    }

    private func alarmAmPm(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "a"
        return f.string(from: date)
    }

    private func countdownText(for alarm: Alarm) -> String {
        let cal = Calendar.current
        var comp = cal.dateComponents([.hour, .minute], from: alarm.time)
        comp.second = 0
        guard let fire = cal.nextDate(after: Date(), matching: comp, matchingPolicy: .nextTime) else { return "" }
        let interval = fire.timeIntervalSinceNow
        let hours = Int(interval / 3600)
        let mins = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "\(hours)시간 \(mins)분 후 알람이 울립니다" }
        return "\(mins)분 후 알람이 울립니다"
    }

    // MARK: - 정렬

    private var sortedAlarms: [Alarm] {
        viewModel.alarms.sorted {
            let cal = Calendar.current
            let aH = cal.component(.hour, from: $0.time)
            let aM = cal.component(.minute, from: $0.time)
            let bH = cal.component(.hour, from: $1.time)
            let bM = cal.component(.minute, from: $1.time)
            return aH * 60 + aM < bH * 60 + bM
        }
    }

    // MARK: - 하단 추가 버튼

    private var addAlarmButton: some View {
        Group {
            if !viewModel.alarms.isEmpty {
                Button {
                    if viewModel.alarms.count >= 3 { showMaxAlarmsAlert = true }
                    else { viewModel.showAddEdit = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 16, weight: .semibold))
                        Text("새 알람 추가").font(.dvBody)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.dvAccentGold)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.dvAccentGold.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.dvAccentGold.opacity(0.35), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 72)
                }
                .accessibilityLabel(viewModel.alarms.count >= 3 ? "알람 최대 3개 도달" : "새 알람 추가")
                .alert("알람은 최대 3개까지\n설정할 수 있어요", isPresented: $showMaxAlarmsAlert) {
                    Button("확인", role: .cancel) {}
                } message: { Text("기존 알람을 삭제한 뒤 새 알람을 추가해주세요.") }
            }
        }
    }

    // MARK: - 토스트

    @ViewBuilder
    private var toastOverlay: some View {
        if let message = viewModel.toastMessage {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Text(message).font(.dvBody).foregroundColor(.white)
                    Button("되돌리기") {
                        withAnimation(.dvSheetAppear) { viewModel.undoDelete() }
                    }
                    .font(.dvBody.weight(.semibold))
                    .foregroundColor(.dvAccent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.black.opacity(0.78)))
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
                Text(formattedTime)
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(alarm.isEnabled ? .white : Color.dvTextHint)

                HStack(spacing: 6) {
                    Text(alarm.repeatSummary).font(.dvCaption).foregroundColor(Color.dvTextSecondary)
                    Text("·").font(.dvCaption).foregroundColor(Color.dvTextSecondary)
                    Text(alarm.themeKorean)
                        .font(.dvCaption).foregroundColor(.dvGold)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(Color.dvGold.opacity(0.15)))
                }

                Text(nextFireText(for: alarm))
                    .font(.dvCaption)
                    .foregroundColor(nextFireColor(for: alarm))
            }

            Spacer()

            Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { _ in onToggle() }))
                .labelsHidden()
                .tint(Color.dvGold)
                .accessibilityLabel("\(formattedTime) 알람 \(alarm.isEnabled ? "켜짐" : "꺼짐")")
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.dvBorderMid, lineWidth: 1))
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.55)
    }

    private var formattedTime: String {
        let f = DateFormatter(); f.dateFormat = "hh:mm a"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: alarm.time)
    }

    private func nextFireText(for alarm: Alarm) -> String {
        guard alarm.isEnabled else { return "꺼져 있음" }
        let cal = Calendar.current
        var comp = cal.dateComponents([.hour, .minute], from: alarm.time); comp.second = 0
        guard let fire = cal.nextDate(after: Date(), matching: comp, matchingPolicy: .nextTime) else { return "" }
        let interval = fire.timeIntervalSinceNow
        if cal.isDateInToday(fire) {
            let h = Int(interval / 3600); let m = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if h > 0 { return "오늘 \(h)시간 \(m)분 뒤" }
            return "오늘 \(m)분 뒤"
        }
        return "내일"
    }

    private func nextFireColor(for alarm: Alarm) -> Color {
        guard alarm.isEnabled else { return .secondary }
        let cal = Calendar.current
        var comp = cal.dateComponents([.hour, .minute], from: alarm.time); comp.second = 0
        guard let fire = cal.nextDate(after: Date(), matching: comp, matchingPolicy: .nextTime) else { return .secondary }
        return cal.isDateInToday(fire) ? .dvAccent : .secondary
    }
}

// MARK: - 알림 권한 배너

private struct NotificationPermissionBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.slash.fill").foregroundColor(.orange).accessibilityHidden(true)
            Text("알림 권한이 없어요. 설정에서 허용해주세요").font(.dvCaption).foregroundColor(.primary)
            Spacer()
            Button("설정") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .font(.dvCaption.weight(.semibold)).foregroundColor(.orange)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.12)))
        .padding(.horizontal, 16).padding(.top, 8)
    }
}

// MARK: - 빈 상태

private struct AlarmEmptyStateView: View {
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "alarm").font(.system(size: 64, weight: .thin)).foregroundColor(Color.dvTextHint).accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("아직 알람이 없어요").font(.dvTitle).foregroundColor(.white)
                Text("알람을 설정하면 매일 말씀과 함께\n하루를 시작할 수 있어요")
                    .font(.dvBody).foregroundColor(Color.dvTextSecondary).multilineTextAlignment(.center)
            }
            Button { onAdd() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("첫 알람 추가하기").font(.dvBody.weight(.semibold))
                }
                .frame(maxWidth: 240).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color.dvGold, Color.dvGold.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .foregroundColor(.white)
            }
            Spacer(); Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview("알람 있음") {
    AlarmListView()
        .environmentObject(PermissionManager())
        .environmentObject(SubscriptionManager())
}
#Preview("알람 없음") {
    AlarmListView()
        .environmentObject(PermissionManager())
        .environmentObject(SubscriptionManager())
}
