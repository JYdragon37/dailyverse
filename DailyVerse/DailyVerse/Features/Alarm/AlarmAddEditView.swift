import SwiftUI
import Combine
import AVFoundation

// MARK: - AlarmAddEditView

struct AlarmAddEditView: View {
    let alarm: Alarm?
    let onSave: (Alarm) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    // MARK: State
    @State private var selectedTime: Date
    @State private var selectedDays: Set<Int>
    @State private var selectedTheme: String
    @State private var labelText: String
    @State private var snoozeEnabled: Bool   // [항목 7] "다시 울림" 토글
    @State private var wakeMission: String
    @State private var soundId: String
    @State private var volume: Float
    @State private var alertStyle: String
    @State private var isLabelAutoSet: Bool
    @State private var showSoundPicker: Bool = false

    private var dayLabels: [String] {
        UserDefaults.standard.string(forKey: "appLanguage") == "en"
            ? ["S", "M", "T", "W", "T", "F", "S"]
            : ["일", "월", "화", "수", "목", "금", "토"]
    }

    // MARK: Init

    init(alarm: Alarm?, onSave: @escaping (Alarm) -> Void) {
        self.alarm = alarm
        self.onSave = onSave
        if let alarm {
            _selectedTime   = State(initialValue: alarm.time)
            _selectedDays   = State(initialValue: Set(alarm.repeatDays))
            _selectedTheme  = State(initialValue: alarm.theme)
            _labelText      = State(initialValue: alarm.label)
            _snoozeEnabled  = State(initialValue: alarm.maxSnoozeCount > 0)
            _wakeMission    = State(initialValue: alarm.wakeMission)
            _soundId        = State(initialValue: alarm.soundId)
            _volume         = State(initialValue: alarm.volume)
            _alertStyle     = State(initialValue: alarm.alertStyle)
            _isLabelAutoSet = State(initialValue: false)
        } else {
            let nextHour = Calendar.current.date(bySetting: .minute, value: 0,
                of: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()) ?? Date()
            _selectedTime   = State(initialValue: nextHour)
            _selectedDays   = State(initialValue: Set([0, 1, 2, 3, 4, 5, 6]))
            _selectedTheme  = State(initialValue: "all")
            _labelText      = State(initialValue: Alarm.defaultLabel(for: nextHour))
            _snoozeEnabled  = State(initialValue: true)
            _wakeMission    = State(initialValue: "none")
            _soundId        = State(initialValue: "s01")
            _volume         = State(initialValue: 0.8)
            _alertStyle     = State(initialValue: "soundAndVibration")
            _isLabelAutoSet = State(initialValue: true)
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                // ── 시간 선택 ──
                Section {
                    // 시간 피커 — 높이를 기본의 80% 수준으로 제한
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, maxHeight: 160, alignment: .center)
                        .clipped()
                        .onChange(of: selectedTime) { newTime in
                            if isLabelAutoSet { labelText = Alarm.defaultLabel(for: newTime) }
                        }

                    // 오늘의 말씀 — 골드, 볼드, 16pt, 따옴표 포함
                    Text("\u{201C}\(previewVerse.verseShortKo)\u{201D}")
                        .font(.custom("PretendardVariable", size: 16).weight(.semibold))
                        .foregroundColor(.dvAccentGold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .listRowSeparator(.hidden)
                } header: {
                    Text(appLanguageString("alarmEdit.section.time")).font(.dvSectionTitle)
                }

                // [항목 4] 알람 이름 Section 삭제됨

                // ── 반복 요일 ──
                Section {
                    HStack(spacing: 8) {
                        QuickDayChip(label: appLanguageString("alarmEdit.days.every"), isSelected: isAllDays) { selectAllDays() }
                        QuickDayChip(label: appLanguageString("alarmEdit.days.weekdays"), isSelected: isWeekdays) { selectWeekdays() }
                        QuickDayChip(label: appLanguageString("alarmEdit.days.weekends"), isSelected: isWeekends) { selectWeekends() }
                        Spacer()
                    }
                    .padding(.vertical, 4).listRowSeparator(.hidden)
                    WeekdaySelector(selectedDays: $selectedDays)
                    Text(repeatSummaryText)
                        .font(.dvCaption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center).listRowSeparator(.hidden)
                } header: {
                    Text(appLanguageString("alarmEdit.section.repeat")).font(.dvSectionTitle)
                }

                // ── 알림 방식 ──
                Section {
                    Picker(appLanguageString("alarmEdit.alertStyle"), selection: $alertStyle) {
                        Label(appLanguageString("alarmEdit.alertStyle.soundAndVibration"), systemImage: "bell.and.waveform.fill").tag("soundAndVibration")
                        Label(appLanguageString("alarmEdit.alertStyle.soundOnly"), systemImage: "bell.fill").tag("sound")
                        Label(appLanguageString("alarmEdit.alertStyle.vibrationOnly"), systemImage: "iphone.radiowaves.left.and.right").tag("vibration")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text(appLanguageString("alarmEdit.alertStyle")).font(.dvSectionTitle)
                }

                // ── 알람음 (컴팩트 Row → Sheet) ──
                if alertStyle != "vibration" {
                    Section {
                        Button { showSoundPicker = true } label: {
                            HStack {
                                Text(AlarmSound.sound(for: soundId).displayName)
                                    .font(.dvBody)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(AlarmSound.sound(for: soundId).category.rawValue)
                                    .font(.dvCaption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.4))
                            }
                        }
                        .buttonStyle(.plain)

                        // 볼륨 슬라이더
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(appLanguageString("alarmEdit.volume")).font(.dvBody)
                                Spacer()
                                Text("\(Int(volume * 100))%").font(.dvCaption).foregroundColor(.secondary)
                            }
                            Slider(value: $volume, in: 0.1...1.0, step: 0.1).accentColor(.dvAccentGold)
                        }
                        .padding(.top, 4)
                    } header: {
                        Text(appLanguageString("alarmEdit.section.sound")).font(.dvSectionTitle)
                    }
                }

                // ── 다시 울림 ──
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appLanguageString("alarmEdit.snooze.title"))
                                .font(.dvBody)
                            Text(appLanguageString("alarmEdit.snooze.subtitle"))
                                .font(.dvCaption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $snoozeEnabled)
                            .labelsHidden()
                            .tint(.dvAccentGold)
                    }
                }

                // ── 광고 영역 (Free 유저만) ──
                if !subscriptionManager.isPremium {
                    Section {
                        BannerAdView()
                            .frame(width: 300, height: 250)
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } header: { Text(appLanguageString("alarmEdit.section.ad")).font(.dvSectionTitle) }
                }

                // ── 주제 ──
                Section {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(Array(themeDataList.prefix(4)), id: \.id) { info in
                            ThemeThumbnailCell(
                                info: info,
                                isSelected: selectedTheme == info.id
                            ) {
                                selectedTheme = info.id
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    Text(appLanguageString("alarmEdit.section.theme")).font(.dvSectionTitle)
                }

                // 웨이크업 미션: 실제 동작 미구현(WakeMissionView 미연결)이라 이번 버전에서 숨김.
                // wakeMission 값은 "none"으로 저장되며, 기능 완성 시 Section 복원 예정. (심사 2.1 대응)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(alarm == nil ? appLanguageString("alarmEdit.title.new") : appLanguageString("alarmEdit.title.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerSheet(selectedSoundId: $soundId)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appLanguageString("common.cancel")) { dismiss() }.accessibilityLabel(appLanguageString("common.cancel"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(appLanguageString("alarmEdit.save")) { handleSave() }
                        .font(.dvBody.weight(.semibold))
                        .disabled(selectedDays.isEmpty)
                }
            }
        }
    }

    // MARK: - 저장

    private func handleSave() {
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: selectedTime,
            repeatDays: Array(selectedDays).sorted(),
            theme: selectedTheme,
            isEnabled: alarm?.isEnabled ?? true,
            snoozeCount: 0,
            label: labelText,
            snoozeInterval: 5,                         // [항목 7] 항상 5분 고정
            maxSnoozeCount: snoozeEnabled ? 3 : 0,     // [항목 7] 토글에 따라
            wakeMission: wakeMission,
            soundId: soundId,
            volume: volume,
            alertStyle: alertStyle
        )
        onSave(newAlarm)
        dismiss()
    }

    // MARK: - 요일 헬퍼

    private var isAllDays: Bool { selectedDays == Set(0...6) }
    private var isWeekdays: Bool { selectedDays == Set(1...5) }
    private var isWeekends: Bool { selectedDays == Set([0, 6]) }
    private func selectAllDays()  { selectedDays = Set(0...6) }
    private func selectWeekdays() { selectedDays = Set(1...5) }
    private func selectWeekends() { selectedDays = Set([0, 6]) }

    private var repeatSummaryText: String {
        let days = Array(selectedDays).sorted()
        if days.count == 7 { return appLanguageString("alarmEdit.days.every") }
        if Set(days) == Set([1,2,3,4,5]) { return appLanguageString("alarmEdit.days.weekdays") }
        if Set(days) == Set([0,6]) { return appLanguageString("alarmEdit.days.weekends") }
        if days.isEmpty { return appLanguageString("alarmEdit.days.none") }
        return days.map { dayLabels[$0] }.joined(separator: ", ")
    }

    // MARK: - 말씀 미리보기

    private var previewVerse: Verse {
        let mode = AppMode.fromTime(selectedTime)
        if let id = DailyCacheManager.shared.getTodayVerseId(),
           let cached = DailyCacheManager.shared.loadCachedVerse(id: id) { return cached }
        if let matched = Verse.fallbackVerses.first(where: { $0.theme.contains(selectedTheme) }) { return matched }
        switch mode {
        case .deepDark:   return .fallbackDeepDark
        case .firstLight: return .fallbackFirstLight
        case .riseIgnite: return .fallbackRiseIgnite
        case .peakMode:   return .fallbackPeakMode
        case .recharge:   return .fallbackRecharge
        case .secondWind: return .fallbackSecondWind
        case .goldenHour: return .fallbackGoldenHour
        case .windDown:   return .fallbackWindDown
        }
    }

    // MARK: - [항목 5] 테마 데이터

    struct ThemeInfo: Identifiable {
        let id: String
        let name: String
        let subtitle: String
        let icon: String
        let topColor: Color
        let bottomColor: Color

        var displayName: String { appLanguageString("alarmTheme.\(id).name") }
        var displaySubtitle: String { appLanguageString("alarmTheme.\(id).subtitle") }
    }

    private let themeDataList: [ThemeInfo] = [
        .init(id: "peace",       name: "평안",   subtitle: "소음 속에서 평온 찾기",   icon: "leaf.fill",                  topColor: Color(hex: "#2A6A4A"), bottomColor: Color(hex: "#1A3A28")),
        .init(id: "courage",     name: "새 힘",  subtitle: "독수리처럼 비상하는 힘",  icon: "bolt.fill",                  topColor: Color(hex: "#8A4A2A"), bottomColor: Color(hex: "#4A2010")),
        .init(id: "gratitude",   name: "감사",   subtitle: "모든 것을 세어보기",      icon: "heart.fill",                  topColor: Color(hex: "#8A6A2A"), bottomColor: Color(hex: "#4A3810")),
        .init(id: "all",          name: "모든 말씀", subtitle: "어떤 말씀도 좋아요",    icon: "sparkles",                   topColor: Color(hex: "#3A3A7A"), bottomColor: Color(hex: "#1A1A4A")),
        .init(id: "hope",        name: "소망",   subtitle: "내일을 향한 기대",        icon: "sparkles",                   topColor: Color(hex: "#2A5C8A"), bottomColor: Color(hex: "#1A3058")),
        .init(id: "strength",    name: "힘",     subtitle: "새 힘을 얻으리니",        icon: "figure.strengthtraining.traditional", topColor: Color(hex: "#7A3A6A"), bottomColor: Color(hex: "#401A38")),
        .init(id: "renewal",     name: "새로움", subtitle: "새 피조물로 거듭나기",    icon: "arrow.triangle.2.circlepath",topColor: Color(hex: "#2A7A5A"), bottomColor: Color(hex: "#1A4030")),
        .init(id: "focus",       name: "집중",   subtitle: "한 가지에 집중하기",      icon: "target",                     topColor: Color(hex: "#5A3A8A"), bottomColor: Color(hex: "#301A50")),
        .init(id: "patience",    name: "인내",   subtitle: "끝까지 견디는 믿음",      icon: "hourglass",                  topColor: Color(hex: "#5A7A3A"), bottomColor: Color(hex: "#303A18")),
        .init(id: "comfort",     name: "위로",   subtitle: "상한 마음을 품으시는 분", icon: "hand.heart.fill",             topColor: Color(hex: "#8A4A6A"), bottomColor: Color(hex: "#4A2038")),
        .init(id: "reflection",  name: "묵상",   subtitle: "말씀을 깊이 새기기",      icon: "moon.stars.fill",             topColor: Color(hex: "#2A2A6A"), bottomColor: Color(hex: "#0A0A38")),
        .init(id: "rest",        name: "안식",   subtitle: "영혼의 쉼을 찾아서",      icon: "moon.zzz.fill",               topColor: Color(hex: "#1A2A5A"), bottomColor: Color(hex: "#0A1230")),
    ]
}

// MARK: - 테마 썸네일 셀 ([항목 5])

private struct ThemeThumbnailCell: View {
    let info: AlarmAddEditView.ThemeInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // 그라데이션 배경
                LinearGradient(
                    colors: [info.topColor, info.bottomColor],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                // 하단 어두운 오버레이 (텍스트 가독성)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center, endPoint: .bottom
                )

                // 콘텐츠
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: info.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text(info.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(info.displaySubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                // 선택 체크마크
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.dvAccentGold : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(info.displayName) \(appLanguageString("alarmEdit.theme.word")) \(isSelected ? appLanguageString("alarmEdit.theme.selected") : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 소리 미리 듣기 플레이어

/// 알람음 탭 시 2.5초 짧게 재생하는 싱글턴
final class SoundPreviewPlayer: NSObject {
    static let shared = SoundPreviewPlayer()
    private var player: AVAudioPlayer?
    private override init() {}

    func play(soundId: String, completion: @escaping () -> Void) {
        // AlarmSound 모델에서 파일명 조회
        let filename = AlarmSound.sound(for: soundId).filename

        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3")
                     ?? Bundle.main.url(forResource: filename, withExtension: "caf")
                     ?? Bundle.main.url(forResource: filename, withExtension: "wav")
        else {
            completion()
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.6
            player?.play()
        } catch {
            completion()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - WeekdaySelector

private struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Int>
    private var dayLabels: [String] {
        UserDefaults.standard.string(forKey: "appLanguage") == "en"
            ? ["S", "M", "T", "W", "T", "F", "S"]
            : ["일", "월", "화", "수", "목", "금", "토"]
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                DayToggleButton(label: dayLabels[i], isSelected: selectedDays.contains(i)) {
                    var days = selectedDays
                    if days.contains(i) { days.remove(i) } else { days.insert(i) }
                    selectedDays = days
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DayToggleButton: View {
    let label: String; let isSelected: Bool; let onToggle: () -> Void
    var body: some View {
        Button(action: onToggle) {
            Text(label)
                .font(.dvCaption.weight(isSelected ? .semibold : .regular))
                .frame(width: 36, height: 36)
                .background(Circle().fill(isSelected ? Color.dvAccent : Color.secondary.opacity(0.12)))
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}

private struct QuickDayChip: View {
    let label: String; let isSelected: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.dvCaption.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? Color.dvAccent : Color.secondary.opacity(0.10)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("추가 모드") {
    AlarmAddEditView(alarm: nil) { _ in }
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
}
