import SwiftUI
import Combine

// MARK: - AlarmListView

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @EnvironmentObject private var permissionManager: PermissionManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 알림 권한 거부 배너
                    if permissionManager.notificationStatus == .denied {
                        NotificationPermissionBanner()
                    }

                    if viewModel.alarms.isEmpty {
                        AlarmEmptyStateView {
                            viewModel.showAddEdit = true
                        }
                    } else {
                        alarmList
                    }
                }
            }
            .navigationTitle("Alarm")
            .navigationBarTitleDisplayMode(.large)
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

    private var alarmList: some View {
        List {
            ForEach(viewModel.alarms) { alarm in
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
                .listRowBackground(Color.dvSurface)
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
                        if viewModel.alarms.count >= 3 {
                            Text("(최대 3개)")
                                .font(.dvCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dvAccent)
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
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
                Text(formattedTime)
                    .font(.system(size: 36, weight: .thin, design: .default))
                    .foregroundColor(alarm.isEnabled ? .primary : .secondary)

                Text(alarm.repeatSummary)
                    .font(.dvCaption)
                    .foregroundColor(.secondary)

                Text(alarm.theme.capitalized)
                    .font(.dvCaption)
                    .foregroundColor(.dvAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.dvAccent.opacity(0.12))
                    )
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .accessibilityLabel("\(formattedTime) 알람 \(alarm.isEnabled ? "켜짐" : "꺼짐")")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.dvSurface)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.55)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: alarm.time)
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

            Image(systemName: "alarm")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("아직 알람이 없어요")
                    .font(.dvTitle)
                    .foregroundColor(.primary)

                Text("알람을 설정하면 매일 말씀과 함께\n하루를 시작할 수 있어요")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dvAccent)
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
              isEnabled: true),
        Alarm(time: calendar.date(from: comps22) ?? now,
              repeatDays: [0, 6],
              theme: "peace",
              isEnabled: false)
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
