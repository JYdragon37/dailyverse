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
        // label + v5.1 새 필드 — Core Data migration 없이 UserDefaults 보조 저장
        AlarmAuxStore.setLabel(alarm.label, for: alarm.id)
        AlarmAuxStore.setSnoozeInterval(alarm.snoozeInterval, for: alarm.id)
        AlarmAuxStore.setMaxSnoozeCount(alarm.maxSnoozeCount, for: alarm.id)
        AlarmAuxStore.setWakeMission(alarm.wakeMission, for: alarm.id)
        AlarmAuxStore.setSoundId(alarm.soundId, for: alarm.id)
        AlarmAuxStore.setVolume(alarm.volume, for: alarm.id)
        AlarmAuxStore.setAlertStyle(alarm.alertStyle, for: alarm.id)
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

        // 모든 필드 복원 (없으면 기본값)
        self.init(
            id: id,
            time: time,
            repeatDays: days,
            theme: theme,
            isEnabled: entity.isEnabled,
            snoozeCount: Int(entity.snoozeCount),
            label: AlarmAuxStore.label(for: id),
            snoozeInterval: AlarmAuxStore.snoozeInterval(for: id),
            maxSnoozeCount: AlarmAuxStore.maxSnoozeCount(for: id),
            wakeMission: AlarmAuxStore.wakeMission(for: id),
            soundId: AlarmAuxStore.soundId(for: id),
            volume: AlarmAuxStore.volume(for: id),
            alertStyle: AlarmAuxStore.alertStyle(for: id)
        )
    }
}

// MARK: - AlarmAuxStore
// Core Data 스키마 마이그레이션 없이 모든 Alarm 확장 필드를 UserDefaults에 저장.

enum AlarmAuxStore {
    private static func key(_ field: String, for id: UUID) -> String {
        "alarmAux_\(id.uuidString)_\(field)"
    }

    // MARK: - label
    static func label(for id: UUID) -> String? {
        UserDefaults.standard.string(forKey: key("label", for: id))
    }
    static func setLabel(_ v: String, for id: UUID) {
        UserDefaults.standard.set(v, forKey: key("label", for: id))
    }

    // MARK: - snoozeInterval
    static func snoozeInterval(for id: UUID) -> Int {
        let s = UserDefaults.standard.integer(forKey: key("snoozeInterval", for: id))
        return s > 0 ? s : 5
    }
    static func setSnoozeInterval(_ v: Int, for id: UUID) {
        UserDefaults.standard.set(v, forKey: key("snoozeInterval", for: id))
    }

    // MARK: - maxSnoozeCount (v5.1)
    static func maxSnoozeCount(for id: UUID) -> Int {
        let s = UserDefaults.standard.integer(forKey: key("maxSnoozeCount", for: id))
        return s > 0 ? s : 3
    }
    static func setMaxSnoozeCount(_ v: Int, for id: UUID) {
        UserDefaults.standard.set(v, forKey: key("maxSnoozeCount", for: id))
    }

    // MARK: - wakeMission (v5.1)
    static func wakeMission(for id: UUID) -> String {
        UserDefaults.standard.string(forKey: key("wakeMission", for: id)) ?? "none"
    }
    static func setWakeMission(_ v: String, for id: UUID) {
        UserDefaults.standard.set(v, forKey: key("wakeMission", for: id))
    }

    // MARK: - soundId (v5.1)
    static func soundId(for id: UUID) -> String {
        UserDefaults.standard.string(forKey: key("soundId", for: id)) ?? "piano"
    }
    static func setSoundId(_ v: String, for id: UUID) {
        UserDefaults.standard.set(v, forKey: key("soundId", for: id))
    }

    // MARK: - volume (v5.1)
    static func volume(for id: UUID) -> Float {
        let s = UserDefaults.standard.float(forKey: key("volume", for: id))
        return s > 0 ? s : 0.8
    }
    static func setVolume(_ v: Float, for id: UUID) {
        UserDefaults.standard.set(v, forKey: key("volume", for: id))
    }

    // MARK: - alertStyle (v5.1)
    static func alertStyle(for id: UUID) -> String {
        UserDefaults.standard.string(forKey: key("alertStyle", for: id)) ?? "soundAndVibration"
    }
    static func setAlertStyle(_ v: String, for id: UUID) {
        UserDefaults.standard.set(v, forKey: key("alertStyle", for: id))
    }

    // MARK: - 전체 삭제
    static func remove(for id: UUID) {
        ["label", "snoozeInterval", "maxSnoozeCount", "wakeMission",
         "soundId", "volume", "alertStyle"].forEach {
            UserDefaults.standard.removeObject(forKey: key($0, for: id))
        }
    }
}
