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
        try context.save()
    }

    func delete(id: UUID) throws {
        let request = AlarmEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(request)
        results.forEach { context.delete($0) }
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

        self.init(
            id: id,
            time: time,
            repeatDays: days,
            theme: theme,
            isEnabled: entity.isEnabled,
            snoozeCount: Int(entity.snoozeCount)
        )
    }
}
