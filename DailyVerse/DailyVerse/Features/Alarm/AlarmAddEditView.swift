import SwiftUI
import Combine

// MARK: - AlarmAddEditView

struct AlarmAddEditView: View {
    // MARK: Init

    let alarm: Alarm?
    let onSave: (Alarm) -> Void

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @Environment(\.dismiss) private var dismiss

    // MARK: State

    @State private var selectedTime: Date
    @State private var selectedDays: Set<Int>
    @State private var selectedTheme: String
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    private let allThemes = [
        "hope", "courage", "strength", "renewal",
        "wisdom", "focus", "patience", "gratitude",
        "peace", "comfort", "reflection", "rest"
    ]

    private let dayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    // MARK: Init

    init(alarm: Alarm?, onSave: @escaping (Alarm) -> Void) {
        self.alarm = alarm
        self.onSave = onSave

        if let alarm {
            _selectedTime = State(initialValue: alarm.time)
            _selectedDays = State(initialValue: Set(alarm.repeatDays))
            _selectedTheme = State(initialValue: alarm.theme)
        } else {
            // 추가 모드: 다음 정시로 초기화
            let nextHour = Calendar.current.date(
                bySetting: .minute, value: 0,
                of: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            ) ?? Date()
            _selectedTime = State(initialValue: nextHour)
            _selectedDays = State(initialValue: Set([0, 1, 2, 3, 4, 5, 6]))
            _selectedTheme = State(initialValue: "hope")
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                // 시간 선택
                Section {
                    DatePicker(
                        "",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .center)
                } header: {
                    Text("시간")
                        .font(.dvSectionTitle)
                }

                // 반복 요일
                Section {
                    WeekdaySelector(selectedDays: $selectedDays)

                    Text(repeatSummaryText)
                        .font(.dvCaption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                } header: {
                    Text("반복")
                        .font(.dvSectionTitle)
                }

                // 주제 (테마)
                Section {
                    if subscriptionManager.isPremium {
                        Picker("테마", selection: $selectedTheme) {
                            ForEach(allThemes, id: \.self) { theme in
                                Text(themeDisplayName(theme))
                                    .tag(theme)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .accessibilityLabel("테마 선택")
                    } else {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.dvAccent)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("자동 배분")
                                    .font(.dvBody)
                                Text("시간대에 맞는 주제가 자동으로 선택됩니다")
                                    .font(.dvCaption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("Premium")
                                .font(.dvCaption.weight(.semibold))
                                .foregroundColor(.dvAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .stroke(Color.dvAccent, lineWidth: 1)
                                )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            upsellManager.show(trigger: .alarmTheme)
                        }
                        .accessibilityLabel("테마 자유 선택은 Premium 기능입니다")
                    }
                } header: {
                    Text("주제")
                        .font(.dvSectionTitle)
                }

                // 말씀 미리보기
                Section {
                    let verse = previewVerse
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\"\(verse.textKo)\"")
                            .font(.dvVerseText)
                            .foregroundColor(.dvPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(verse.reference)
                            .font(.dvCaption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("말씀 미리보기: \(verse.textKo), \(verse.reference)")
                } header: {
                    Text("말씀 미리보기")
                        .font(.dvSectionTitle)
                }
            }
            .navigationTitle(alarm == nil ? "새 알람" : "알람 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .accessibilityLabel("취소")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장하기") {
                        handleSave()
                    }
                    .font(.dvBody.weight(.semibold))
                    .disabled(selectedDays.isEmpty)
                    .accessibilityLabel(selectedDays.isEmpty ? "요일을 선택해야 저장할 수 있습니다" : "알람 저장하기")
                }
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    ToastView(message: toastMessage)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.dvSheetAppear, value: showToast)
        }
        .sheet(isPresented: $upsellManager.shouldShow) {
            UpsellBottomSheet()
                .environmentObject(subscriptionManager)
                .environmentObject(upsellManager)
        }
    }

    // MARK: - 저장 처리

    private func handleSave() {
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: selectedTime,
            repeatDays: Array(selectedDays).sorted(),
            theme: subscriptionManager.isPremium ? selectedTheme : autoTheme,
            isEnabled: alarm?.isEnabled ?? true,
            snoozeCount: 0
        )

        onSave(newAlarm)

        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let timeStr = formatter.string(from: selectedTime)
        toastMessage = "내일 \(timeStr), 말씀이 함께 울릴 거예요"

        withAnimation(.dvSheetAppear) {
            showToast = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                dismiss()
            }
        }
    }

    // MARK: - 요일 요약

    private var repeatSummaryText: String {
        let days = Array(selectedDays).sorted()
        if days.count == 7 { return "매일" }
        if Set(days) == Set([1, 2, 3, 4, 5]) { return "주중" }
        if Set(days) == Set([0, 6]) { return "주말" }
        if days.isEmpty { return "반복 없음" }
        return days.map { dayLabels[$0] }.joined(separator: ", ")
    }

    // MARK: - 말씀 미리보기 선택

    private var previewVerse: Verse {
        // 선택된 시간대에 맞는 fallback 구절 반환
        // Premium 유저는 selectedTheme에 맞는 구절 우선
        let timeMode = AppMode.fromTime(selectedTime)
        let themeToMatch = subscriptionManager.isPremium ? selectedTheme : nil

        if let themeToMatch {
            let candidates: [Verse] = [.fallbackMorning, .fallbackAfternoon, .fallbackEvening]
            if let matched = candidates.first(where: { $0.theme.contains(themeToMatch) }) {
                return matched
            }
        }

        switch timeMode {
        case .morning: return .fallbackMorning
        case .afternoon: return .fallbackAfternoon
        case .evening: return .fallbackEvening
        }
    }

    // MARK: - Free 자동 테마 배분 (AlarmViewModel.autoAssignTheme과 동일한 로직)

    private var autoTheme: String {
        let mode = AppMode.fromTime(selectedTime)
        let themePool = mode.themes
        // 저장 시점의 임시 알람 ID로 히스토리 조회 (편집 모드에서는 기존 alarm.id 사용)
        let alarmId = alarm?.id ?? UUID()
        let historyKey = "themeHistory_\(alarmId.uuidString)"

        let storedHistory = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let isoFormatter = ISO8601DateFormatter()

        let recentThemes: [String] = storedHistory.compactMap { entry in
            let parts = entry.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let date = isoFormatter.date(from: parts[1]) else { return nil }
            return date > cutoff ? parts[0] : nil
        }

        let available = themePool.filter { !recentThemes.contains($0) }
        return available.randomElement() ?? themePool.randomElement() ?? "hope"
    }

    // MARK: - 테마 한글 표시명

    private func themeDisplayName(_ theme: String) -> String {
        let map: [String: String] = [
            "hope": "소망",
            "courage": "용기",
            "strength": "힘",
            "renewal": "새로움",
            "wisdom": "지혜",
            "focus": "집중",
            "patience": "인내",
            "gratitude": "감사",
            "peace": "평안",
            "comfort": "위로",
            "reflection": "묵상",
            "rest": "안식"
        ]
        return map[theme] ?? theme.capitalized
    }
}

// MARK: - WeekdaySelector

private struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Int>

    private let dayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                DayToggleButton(
                    label: dayLabels[index],
                    isSelected: selectedDays.contains(index)
                ) {
                    if selectedDays.contains(index) {
                        selectedDays.remove(index)
                    } else {
                        selectedDays.insert(index)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("반복 요일 선택")
    }
}

// MARK: - DayToggleButton

private struct DayToggleButton: View {
    let label: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(label)
                .font(.dvCaption.weight(isSelected ? .semibold : .regular))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.dvAccent : Color.secondary.opacity(0.12))
                )
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)요일 \(isSelected ? "선택됨" : "선택 안됨")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("추가 모드 — Free") {
    AlarmAddEditView(alarm: nil) { _ in }
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
}

#Preview("수정 모드 — Premium") {
    let pm = SubscriptionManager()
    pm.isPremium = true

    let calendar = Calendar.current
    var comps = calendar.dateComponents([.year, .month, .day], from: Date())
    comps.hour = 6; comps.minute = 30
    let alarmTime = calendar.date(from: comps) ?? Date()

    let alarm = Alarm(
        time: alarmTime,
        repeatDays: [1, 2, 3, 4, 5],
        theme: "courage",
        isEnabled: true
    )

    return AlarmAddEditView(alarm: alarm) { _ in }
        .environmentObject(pm)
        .environmentObject(UpsellManager())
}
