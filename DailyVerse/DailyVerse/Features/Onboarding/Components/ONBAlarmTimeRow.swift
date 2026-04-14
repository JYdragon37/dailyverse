import SwiftUI

// Design Ref: §4.6 — 알람 시간 행, 토글 + DatePicker 조합, dvAccentGold 활성 상태

struct ONBAlarmTimeRow: View {
    let icon: String
    let label: String
    var iconColor: Color = .white
    @Binding var isEnabled: Bool
    @Binding var time: Date

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 22))
                .foregroundColor(isEnabled ? iconColor : iconColor.opacity(0.4))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(label) 알람")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.4))

                if isEnabled {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .tint(.dvAccentGold)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .tint(.dvAccentGold)
                .labelsHidden()
                .accessibilityLabel("\(label) 알람 \(isEnabled ? "켜짐" : "꺼짐")")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isEnabled ? 0.08 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isEnabled ? Color.dvAccentGold.opacity(0.4) : Color.white.opacity(0.10),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isEnabled)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        Color.dvBgDeep.ignoresSafeArea()
        VStack(spacing: 12) {
            ONBAlarmTimeRow(
                icon: "sunrise.fill", label: "아침",
                isEnabled: .constant(true),
                time: .constant(
                    Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
                )
            )
            ONBAlarmTimeRow(
                icon: "moon.fill", label: "저녁",
                isEnabled: .constant(false),
                time: .constant(
                    Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
                )
            )
        }
        .padding()
    }
}
