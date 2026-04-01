import SwiftUI
import Combine

@MainActor
final class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var showAddEdit: Bool = false
    @Published var editingAlarm: Alarm? = nil
    @Published var toastMessage: String?

    private var pendingDeleteAlarm: Alarm?
    private var undoTask: Task<Void, Never>?

    private let alarmRepository: AlarmRepository
    private let notificationManager: NotificationManager
    private let verseRepository: VerseRepository

    // MARK: - Init

    init(
        alarmRepository: AlarmRepository = AlarmRepository(),
        notificationManager: NotificationManager = .shared,
        verseRepository: VerseRepository = VerseRepository()
    ) {
        self.alarmRepository = alarmRepository
        self.notificationManager = notificationManager
        self.verseRepository = verseRepository
    }

    // MARK: - Load

    func loadAlarms() {
        alarms = alarmRepository.fetchAll()
    }

    // MARK: - Save

    func saveAlarm(_ alarm: Alarm) {
        do {
            try alarmRepository.save(alarm)
            let verse = fallbackVerse(for: alarm)
            notificationManager.cancel(alarmId: alarm.id)
            if alarm.isEnabled {
                notificationManager.schedule(alarm, verse: verse)
            }
            loadAlarms()
            showSavedToast(for: alarm)
        } catch {
            toastMessage = "알람 저장에 실패했습니다."
        }
    }

    // MARK: - Delete + Undo (3초 되돌리기)

    func deleteAlarm(id: UUID) {
        guard let alarm = alarms.first(where: { $0.id == id }) else { return }

        notificationManager.cancel(alarmId: id)
        alarms.removeAll { $0.id == id }
        pendingDeleteAlarm = alarm
        toastMessage = "알람이 삭제되었습니다."

        undoTask?.cancel()
        undoTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            guard let self else { return }
            if let toDelete = self.pendingDeleteAlarm, toDelete.id == id {
                try? self.alarmRepository.delete(id: id)
                self.pendingDeleteAlarm = nil
                self.toastMessage = nil
            }
        }
    }

    func undoDelete() {
        guard let alarm = pendingDeleteAlarm else { return }
        undoTask?.cancel()
        undoTask = nil
        pendingDeleteAlarm = nil
        do {
            try alarmRepository.save(alarm)
        } catch { }
        loadAlarms()
        toastMessage = nil
    }

    // MARK: - Toggle

    func toggleAlarm(id: UUID) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].isEnabled.toggle()
        let alarm = alarms[index]

        do {
            try alarmRepository.update(alarm)
        } catch {
            alarms[index].isEnabled.toggle()
            return
        }

        notificationManager.cancel(alarmId: alarm.id)
        if alarm.isEnabled {
            let verse = fallbackVerse(for: alarm)
            notificationManager.schedule(alarm, verse: verse)
        }
    }

    // MARK: - Free 테마 자동 배분 (CLAUDE.md 섹션 6)

    /// 알람 시간대 기반 테마 풀에서 최근 7일 내 사용된 테마를 제외 후 랜덤 선택.
    /// 각 알람(최대 3개)은 독립적인 히스토리를 가짐 (alarm.id 기반 UserDefaults 키).
    func autoAssignTheme(for alarm: Alarm) -> String {
        let mode = AppMode.fromTime(alarm.time)
        let themePool = mode.themes
        let historyKey = "themeHistory_\(alarm.id.uuidString)"

        let storedHistory = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let isoFormatter = ISO8601DateFormatter()

        // "theme:ISO8601Date" 형식에서 최근 7일 테마 추출
        let recentThemes: [String] = storedHistory.compactMap { entry in
            let parts = entry.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let date = isoFormatter.date(from: parts[1]) else { return nil }
            return date > cutoff ? parts[0] : nil
        }

        let available = themePool.filter { !recentThemes.contains($0) }
        let selected = available.randomElement() ?? themePool.randomElement() ?? "hope"

        // 히스토리 업데이트 — 30일 초과 항목 정리
        let newEntry = "\(selected):\(isoFormatter.string(from: Date()))"
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var updatedHistory = storedHistory.filter { entry in
            let parts = entry.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let date = isoFormatter.date(from: parts[1]) else { return false }
            return date > thirtyDaysAgo
        }
        updatedHistory.append(newEntry)
        UserDefaults.standard.set(updatedHistory, forKey: historyKey)

        return selected
    }

    // MARK: - Private Helpers

    private func fallbackVerse(for alarm: Alarm) -> Verse {
        switch AppMode.fromTime(alarm.time) {
        case .morning: return Verse.fallbackMorning
        case .afternoon: return Verse.fallbackAfternoon
        case .evening: return Verse.fallbackEvening
        }
    }

    private func showSavedToast(for alarm: Alarm) {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: alarm.time)
        let minute = cal.component(.minute, from: alarm.time)
        let timeString = String(format: "%02d:%02d", hour, minute)
        toastMessage = "내일 \(timeString), 말씀이 함께할 거예요"
    }
}
