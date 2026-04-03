import SwiftUI
import Combine

// MARK: - AlarmAddEditView

struct AlarmAddEditView: View {
    // MARK: Init

    let alarm: Alarm?
    let onSave: (Alarm) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: State

    @State private var selectedTime: Date
    @State private var selectedDays: Set<Int>
    @State private var selectedTheme: String
    @State private var labelText: String
    @State private var snoozeInterval: Int
    @State private var maxSnoozeCount: Int
    @State private var wakeMission: String
    @State private var soundId: String
    @State private var volume: Float
    @State private var alertStyle: String   // "sound" | "vibration" | "soundAndVibration"
    @State private var isLabelAutoSet: Bool

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
            _selectedTime      = State(initialValue: alarm.time)
            _selectedDays      = State(initialValue: Set(alarm.repeatDays))
            _selectedTheme     = State(initialValue: alarm.theme)
            _labelText         = State(initialValue: alarm.label)
            _snoozeInterval    = State(initialValue: alarm.snoozeInterval)
            _maxSnoozeCount    = State(initialValue: alarm.maxSnoozeCount)
            _wakeMission       = State(initialValue: alarm.wakeMission)
            _soundId           = State(initialValue: alarm.soundId)
            _volume            = State(initialValue: alarm.volume)
            _alertStyle        = State(initialValue: alarm.alertStyle)
            _isLabelAutoSet    = State(initialValue: false)
        } else {
            let nextHour = Calendar.current.date(
                bySetting: .minute, value: 0,
                of: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            ) ?? Date()
            _selectedTime      = State(initialValue: nextHour)
            _selectedDays      = State(initialValue: Set([0, 1, 2, 3, 4, 5, 6]))
            _selectedTheme     = State(initialValue: "hope")
            _labelText         = State(initialValue: Alarm.defaultLabel(for: nextHour))
            _snoozeInterval    = State(initialValue: 5)
            _maxSnoozeCount    = State(initialValue: 3)
            _wakeMission       = State(initialValue: "none")
            _soundId           = State(initialValue: "piano")
            _volume            = State(initialValue: 0.8)
            _alertStyle        = State(initialValue: "soundAndVibration")
            _isLabelAutoSet    = State(initialValue: true)
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
                    .onChange(of: selectedTime) { newTime in
                        // 라벨이 자동 설정 상태일 때만 시간 변경에 따라 갱신
                        if isLabelAutoSet {
                            labelText = Alarm.defaultLabel(for: newTime)
                        }
                    }
                } header: {
                    Text("시간")
                        .font(.dvSectionTitle)
                }

                // 알람 이름
                Section {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.dvAccent)
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        TextField("알람 이름 (선택사항)", text: $labelText)
                            .font(.dvBody)
                            .onChange(of: labelText) { _ in
                                // 유저가 직접 입력하면 자동 설정 모드 해제
                                isLabelAutoSet = false
                            }
                    }
                } header: {
                    Text("알람 이름")
                        .font(.dvSectionTitle)
                }

                // 반복 요일
                Section {
                    // 빠른 선택 Chip
                    HStack(spacing: 8) {
                        QuickDayChip(label: "매일", isSelected: isAllDays) { selectAllDays() }
                        QuickDayChip(label: "주중", isSelected: isWeekdays) { selectWeekdays() }
                        QuickDayChip(label: "주말", isSelected: isWeekends) { selectWeekends() }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .listRowSeparator(.hidden)

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

                // 주제 (테마) — v5.1: 단일 플랜, 모든 유저 자유 선택
                Section {
                    Picker("테마", selection: $selectedTheme) {
                        ForEach(allThemes, id: \.self) { theme in
                            Text(themeDisplayName(theme)).tag(theme)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("주제")
                        .font(.dvSectionTitle)
                }

                // 웨이크업 미션 (v5.1 신규)
                Section {
                    Picker("미션", selection: $wakeMission) {
                        Text("없음").tag("none")
                        Text("흔들기").tag("shake")
                        Text("수학 문제").tag("math")
                        Text("타이핑 ✨").tag("typing")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("웨이크업 미션")
                        .font(.dvSectionTitle)
                } footer: {
                    Text("미션을 완료해야 말씀 화면으로 이동합니다")
                        .font(.dvCaption)
                        .foregroundColor(.secondary)
                }

                // 알람 소리 & 진동 선택 (v5.1)
                Section {
                    // 알림 방식 선택
                    Picker("알림 방식", selection: $alertStyle) {
                        Label("소리 + 진동", systemImage: "bell.and.waveform.fill").tag("soundAndVibration")
                        Label("소리만", systemImage: "bell.fill").tag("sound")
                        Label("진동만", systemImage: "iphone.radiowaves.left.and.right").tag("vibration")
                    }
                    .pickerStyle(.navigationLink)

                    // 소리가 포함된 경우만 소리 종류 + 볼륨 표시
                    if alertStyle != "vibration" {
                        Picker("소리 종류", selection: $soundId) {
                            Text("은은한 피아노").tag("piano")
                            Text("자연 소리").tag("nature")
                            Text("찬양 멜로디").tag("hymn")
                        }
                        .pickerStyle(.navigationLink)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("볼륨").font(.dvBody)
                                Spacer()
                                Text("\(Int(volume * 100))%").font(.dvCaption).foregroundColor(.secondary)
                            }
                            Slider(value: $volume, in: 0.1...1.0, step: 0.1)
                                .accentColor(.dvAccentGold)
                        }
                    }
                } header: {
                    Text("알람 소리 / 진동").font(.dvSectionTitle)
                }

                // 스누즈 설정 (v5.1: 1/3/5/10분, 0~10회)
                Section {
                    Picker("스누즈 간격", selection: $snoozeInterval) {
                        Text("1분").tag(1)
                        Text("3분").tag(3)
                        Text("5분").tag(5)
                        Text("10분").tag(10)
                    }
                    .pickerStyle(.segmented)

                    Stepper("최대 \(maxSnoozeCount)회", value: $maxSnoozeCount, in: 0...10)
                        .font(.dvBody)
                } header: {
                    Text("스누즈 설정")
                        .font(.dvSectionTitle)
                } footer: {
                    Text("최대 횟수만큼 스누즈 후 알람이 해제됩니다")
                        .font(.dvCaption)
                        .foregroundColor(.secondary)
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
        }
        // v5.1: 단일 플랜 — UpsellBottomSheet 제거
    }

    // MARK: - 저장 처리

    private func handleSave() {
        // v5.1: 단일 플랜 — 모든 유저 선택 테마 사용
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: selectedTime,
            repeatDays: Array(selectedDays).sorted(),
            theme: selectedTheme,
            isEnabled: alarm?.isEnabled ?? true,
            snoozeCount: 0,
            label: labelText,
            snoozeInterval: snoozeInterval,
            maxSnoozeCount: maxSnoozeCount,
            wakeMission: wakeMission,
            soundId: soundId,
            volume: volume,
            alertStyle: alertStyle
        )

        onSave(newAlarm)
        // 토스트는 AlarmViewModel.showSavedToast(for:)에서 처리
        dismiss()
    }

    // MARK: - 빠른 요일 선택 헬퍼

    private var isAllDays: Bool { selectedDays == Set(0...6) }
    private var isWeekdays: Bool { selectedDays == Set(1...5) }
    private var isWeekends: Bool { selectedDays == Set([0, 6]) }

    private func selectAllDays()  { selectedDays = Set(0...6) }
    private func selectWeekdays() { selectedDays = Set(1...5) }
    private func selectWeekends() { selectedDays = Set([0, 6]) }

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
        // v5.1: 단일 플랜 — 선택 테마에 맞는 구절 우선
        let timeMode = AppMode.fromTime(selectedTime)
        let candidates: [Verse] = [.fallbackMorning, .fallbackAfternoon, .fallbackEvening, .fallbackDawn]
        if let matched = candidates.first(where: { $0.theme.contains(selectedTheme) }) {
            return matched
        }
        switch timeMode {
        case .morning:   return .fallbackMorning
        case .afternoon: return .fallbackAfternoon
        case .evening:   return .fallbackEvening
        case .dawn:      return .fallbackDawn
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
                    var days = selectedDays
                    if days.contains(index) {
                        days.remove(index)
                    } else {
                        days.insert(index)
                    }
                    selectedDays = days
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

// MARK: - QuickDayChip

private struct QuickDayChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.dvCaption.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.dvAccent : Color.secondary.opacity(0.10))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) 선택 \(isSelected ? "됨" : "안됨")")
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
        isEnabled: true,
        label: "아침의 말씀",
        snoozeInterval: 10
    )

    return AlarmAddEditView(alarm: alarm) { _ in }
        .environmentObject(pm)
        .environmentObject(UpsellManager())
}
