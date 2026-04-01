import SwiftUI
import Combine

struct OnboardingFirstAlarmView: View {
    var viewModel: OnboardingViewModel
    @State private var morningEnabled: Bool = true
    @State private var eveningEnabled: Bool = true

    private let alarmRepository = AlarmRepository()
    private let notificationManager = NotificationManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.dvAccent)
                    .accessibilityLabel("알람 아이콘")

                Text("매일 말씀과 함께\n하루를 시작하세요")
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                // 아침 알람 카드
                HStack(spacing: 12) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("아침")
                            .font(.dvCaption)
                            .foregroundColor(.secondary)
                        Text("06:00 AM")
                            .font(.dvSubtitle)
                    }

                    Spacer()

                    Toggle("아침 알람", isOn: $morningEnabled)
                        .labelsHidden()
                        .accessibilityLabel("아침 알람 06:00 AM 활성화")
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(12)

                // 저녁 알람 카드
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.dvAccent)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("저녁")
                            .font(.dvCaption)
                            .foregroundColor(.secondary)
                        Text("10:00 PM")
                            .font(.dvSubtitle)
                    }

                    Spacer()

                    Toggle("저녁 알람", isOn: $eveningEnabled)
                        .labelsHidden()
                        .accessibilityLabel("저녁 알람 10:00 PM 활성화")
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button("설정하기") {
                    saveSelectedAlarms()
                    viewModel.markFirstAlarmShown()
                    viewModel.complete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!morningEnabled && !eveningEnabled)
                .accessibilityLabel("선택한 알람 설정하기")
                .padding(.horizontal, 32)

                Button("건너뛰기") {
                    viewModel.complete()
                }
                .font(.dvBody)
                .foregroundColor(.secondary)
                .accessibilityLabel("알람 설정 건너뛰기")
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Private

    /// 토글 상태에 따라 기본 알람 2개를 Core Data에 저장하고 알림을 스케줄한다.
    private func saveSelectedAlarms() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        if morningEnabled {
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 6
            components.minute = 0
            components.second = 0
            let time = calendar.date(from: components) ?? Date()
            let alarm = Alarm(
                id: UUID(),
                time: time,
                repeatDays: [0, 1, 2, 3, 4, 5, 6],
                theme: "hope",
                isEnabled: true,
                snoozeCount: 0
            )
            try? alarmRepository.save(alarm)
            notificationManager.schedule(alarm, verse: Verse.fallbackMorning)
        }

        if eveningEnabled {
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 22
            components.minute = 0
            components.second = 0
            let time = calendar.date(from: components) ?? Date()
            let alarm = Alarm(
                id: UUID(),
                time: time,
                repeatDays: [0, 1, 2, 3, 4, 5, 6],
                theme: "peace",
                isEnabled: true,
                snoozeCount: 0
            )
            try? alarmRepository.save(alarm)
            notificationManager.schedule(alarm, verse: Verse.fallbackEvening)
        }
    }
}

#Preview {
    OnboardingFirstAlarmView(viewModel: OnboardingViewModel())
}
