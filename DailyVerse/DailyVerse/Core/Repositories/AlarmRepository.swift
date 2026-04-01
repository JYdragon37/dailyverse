import Foundation
import CoreData
import Combine

class AlarmRepository {
    private let context = PersistenceController.shared.context

    // MARK: - CRUD

    func fetchAll() -> [Alarm] {
        let request = AlarmEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap { Alarm(from: $0) }
    }

    func save(_ alarm: Alarm) throws {
        // upsert: 기존 항목 있으면 삭제 후 재생성
        let existing = fetchEntity(id: alarm.id)
        if let existing {
            context.delete(existing)
        }
        let entity = AlarmEntity(context: context)
        entity.id = alarm.id
        entity.time = alarm.time
        entity.theme = alarm.theme
        entity.isEnabled = alarm.isEnabled
        entity.snoozeCount = Int16(alarm.snoozeCount)
        if let data = try? JSONEncoder().encode(alarm.repeatDays) {
            entity.repeatDays = String(data: data, encoding: .utf8)
        }
        // label, snoozeInterval — Core Data migration 없이 UserDefaults 보조 저장
        AlarmAuxStore.setLabel(alarm.label, for: alarm.id)
        AlarmAuxStore.setSnoozeInterval(alarm.snoozeInterval, for: alarm.id)
        try context.save()
    }

    func delete(id: UUID) throws {
        let request = AlarmEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(request)
        results.forEach { context.delete($0) }
        // 보조 저장 정리
        AlarmAuxStore.remove(for: id)
        try context.save()
    }

    func update(_ alarm: Alarm) throws {
        try save(alarm)
    }

    /// 동기 카운트 — HomeViewModel에서 동기 호출 가능
    func count() -> Int {
        let request = AlarmEntity.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }

    // MARK: - Private Helpers

    private func fetchEntity(id: UUID) -> AlarmEntity? {
        let request = AlarmEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

// MARK: - Alarm ↔ AlarmEntity 변환

extension Alarm {
    init?(from entity: AlarmEntity) {
        guard let id = entity.id,
              let time = entity.time,
              let theme = entity.theme else { return nil }

        var days: [Int] = [0, 1, 2, 3, 4, 5, 6]
        if let daysStr = entity.repeatDays,
           let data = daysStr.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            days = decoded
        }

        // label, snoozeInterval — UserDefaults 보조 저장에서 복원 (없으면 기본값)
        let restoredLabel = AlarmAuxStore.label(for: id)
        let restoredInterval = AlarmAuxStore.snoozeInterval(for: id)

        self.init(
            id: id,
            time: time,
            repeatDays: days,
            theme: theme,
            isEnabled: entity.isEnabled,
            snoozeCount: Int(entity.snoozeCount),
            label: restoredLabel,
            snoozeInterval: restoredInterval
        )
    }
}

// MARK: - AlarmAuxStore (label / snoozeInterval 보조 저장소)
// Core Data 스키마 마이그레이션 없이 label, snoozeInterval을 UserDefaults에 저장합니다.
// 키 패턴: "alarmAux_{uuid}_label", "alarmAux_{uuid}_snoozeInterval"

enum AlarmAuxStore {
    private static func labelKey(for id: UUID) -> String { "alarmAux_\(id.uuidString)_label" }
    private static func intervalKey(for id: UUID) -> String { "alarmAux_\(id.uuidString)_snoozeInterval" }

    static func label(for id: UUID) -> String? {
        UserDefaults.standard.string(forKey: labelKey(for: id))
    }

    static func snoozeInterval(for id: UUID) -> Int {
        let stored = UserDefaults.standard.integer(forKey: intervalKey(for: id))
        return stored > 0 ? stored : 5
    }

    static func setLabel(_ label: String, for id: UUID) {
        UserDefaults.standard.set(label, forKey: labelKey(for: id))
    }

    static func setSnoozeInterval(_ interval: Int, for id: UUID) {
        UserDefaults.standard.set(interval, forKey: intervalKey(for: id))
    }

    static func remove(for id: UUID) {
        UserDefaults.standard.removeObject(forKey: labelKey(for: id))
        UserDefaults.standard.removeObject(forKey: intervalKey(for: id))
    }
}
