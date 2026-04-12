import Foundation
import FirebaseFirestore

// MARK: - MeditationRepository
// Firestore primary + UserDefaults JSON 캐시 (오프라인 임시 저장)

final class MeditationRepository {

    private let db = Firestore.firestore()
    private let kTodayCache = "meditation_today_v1"
    private let kPending    = "meditation_pending_v1"

    // MARK: - Save (Upsert)

    func save(_ entry: MeditationEntry) async throws {
        // 1) 로컬 캐시 즉시 업데이트
        saveTodayCache(entry)

        guard entry.userId != "local" else { return }

        do {
            try await db
                .collection("meditation_logs")
                .document(entry.userId)
                .collection("entries")
                .document(entry.dateKey)
                .setData(from: entry, merge: true)
            removePending(dateKey: entry.dateKey)
        } catch {
            addToPending(entry)
            throw error
        }
    }

    // MARK: - Fetch Today

    func fetchToday(userId: String) async -> MeditationEntry? {
        let today = MeditationEntry.todayKey()
        // 캐시 히트
        if let cached = loadTodayCache(), cached.dateKey == today, cached.userId == userId {
            return cached
        }
        guard userId != "local" else { return nil }
        return try? await db
            .collection("meditation_logs")
            .document(userId)
            .collection("entries")
            .document(today)
            .getDocument(as: MeditationEntry.self)
    }

    // MARK: - Fetch History

    func fetchHistory(userId: String, limit: Int = 30) async -> [MeditationEntry] {
        guard userId != "local" else {
            // 로컬(비로그인) 유저: Firestore 없음 → 오늘 캐시만 history에 포함
            // history가 빈 배열이면 달력 탭 조건(entry != nil)이 충족되지 않고
            // updateMeditatedDates([])가 meditatedDatesThisMonth를 초기화해 동그라미가 사라짐
            if let cached = loadTodayCache(),
               cached.dateKey == MeditationEntry.todayKey() {
                return [cached]
            }
            return []
        }
        let snapshot = try? await db
            .collection("meditation_logs")
            .document(userId)
            .collection("entries")
            .order(by: "date_key", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot?.documents.compactMap {
            try? $0.data(as: MeditationEntry.self)
        } ?? []
    }

    // MARK: - This Month Date Keys (히트맵용)

    func fetchThisMonthDateKeys(userId: String) async -> Set<String> {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        let prefix = f.string(from: Date())
        let all = await fetchHistory(userId: userId, limit: 60)
        return Set(all.map { $0.dateKey }.filter { $0.hasPrefix(prefix) })
    }

    // MARK: - Offline Queue Flush

    func flushPendingIfNeeded() async {
        var pending = loadPending()
        guard !pending.isEmpty else { return }
        var flushed: [String] = []
        for entry in pending {
            do {
                try await db
                    .collection("meditation_logs")
                    .document(entry.userId)
                    .collection("entries")
                    .document(entry.dateKey)
                    .setData(from: entry, merge: true)
                flushed.append(entry.dateKey)
            } catch { break }
        }
        pending.removeAll { flushed.contains($0.dateKey) }
        savePending(pending)
    }

    // MARK: - Private Cache

    private func loadTodayCache() -> MeditationEntry? {
        guard let data = UserDefaults.standard.data(forKey: kTodayCache) else { return nil }
        return try? JSONDecoder().decode(MeditationEntry.self, from: data)
    }

    private func saveTodayCache(_ entry: MeditationEntry) {
        if let data = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(data, forKey: kTodayCache)
        }
    }

    private func loadPending() -> [MeditationEntry] {
        guard let data = UserDefaults.standard.data(forKey: kPending) else { return [] }
        return (try? JSONDecoder().decode([MeditationEntry].self, from: data)) ?? []
    }

    private func savePending(_ entries: [MeditationEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: kPending)
        }
    }

    private func addToPending(_ entry: MeditationEntry) {
        var q = loadPending()
        q.removeAll { $0.dateKey == entry.dateKey }
        q.append(entry)
        savePending(q)
    }

    private func removePending(dateKey: String) {
        var q = loadPending()
        q.removeAll { $0.dateKey == dateKey }
        savePending(q)
    }
}
