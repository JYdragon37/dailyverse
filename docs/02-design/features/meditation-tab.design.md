# Design: 묵상 탭 (meditation-tab)

> 작성일: 2026-04-09
> Plan 문서: docs/01-plan/features/meditation-tab.plan.md
> 아키텍처 선택: Option C — 실용적 균형 (Firestore + UserDefaults JSON 캐시)
> 상태: Ready for Implementation

---

## Context Anchor (Plan에서 전파)

| 항목 | 내용 |
|------|------|
| WHY | 갤러리 탭 리텐션 없음 → 매일 돌아오는 이유 생성 (스트릭 + 아카이브) |
| WHO | 알람으로 말씀 받는 유저 → 내 삶과 연결하고 싶은 유저 |
| RISK | "묵상" 진입장벽 → 심리적 부담 없는 UX, 툴팁, 부드러운 빈 상태 |
| SUCCESS | 묵상 탭 DAU ≥ 40%, 스트릭 7일+ ≥ 20%, Stage2 입력 완료율 ≥ 15% |
| SCOPE | Gallery 제거 + 묵상 탭 신설 + Stage 2 연동. 탭 5개 유지 |

---

## 1. 아키텍처 결정 (Option C)

### 선택 근거
| 항목 | 결정 | 이유 |
|------|------|------|
| 저장소 | Firestore primary + UserDefaults JSON 캐시 | DailyCacheManager 기존 패턴 재사용. Core Data 추가 없음 |
| 스트릭 | StreakManager (UserDefaults) | 가볍고 즉각 반응. 앱 삭제 시 리셋 허용 (v1 범위) |
| Stage 2 연동 | 기존 WordOfDaySheet 확장 | 이미 구현된 UI 재사용, 중복 코드 없음 |
| 오프라인 | UserDefaults 임시 저장 → 온라인 복구 시 재시도 | Core Data 없이도 충분 |

### 레이어 다이어그램

```
MeditationView (SwiftUI)
  ↓ observes
MeditationViewModel (@MainActor, ObservableObject)
  ↓ calls
MeditationRepository (class)
  ├── FirestoreService (Firestore primary)
  └── UserDefaults JSON (오프라인 임시 + 최근 캐시)

StreakManager (class, shared singleton)
  └── UserDefaults (currentStreak, longestStreak, lastMeditatedDate)

AlarmCoordinator (기존)
  └── WordOfDaySheet → MeditationRepository 연결 (수정)
```

---

## 2. 파일 구조

### 신규 파일 (5개)

```
DailyVerse/
├── Core/
│   ├── Models/
│   │   └── MeditationEntry.swift          ← 신규
│   ├── Managers/
│   │   └── StreakManager.swift             ← 신규
│   └── Repositories/
│       └── MeditationRepository.swift      ← 신규
└── Features/
    └── Meditation/
        ├── MeditationView.swift             ← 신규 (메인 탭 + 작성 시트 포함)
        └── MeditationViewModel.swift        ← 신규
```

### 수정 파일 (7개)

```
App/MainTabView.swift                        ← GalleryView → MeditationView 교체
Features/Alarm/AlarmStage2View.swift         ← WordOfDaySheet → 묵상 저장 연결
Core/Services/FirestoreService.swift         ← meditation_logs CRUD 추가
Core/Services/NotificationManager.swift     ← 묵상 리마인더 추가
Core/Managers/UpsellManager.swift            ← 신규 트리거 2개 추가
Features/Saved/SavedDetailView.swift         ← Gallery 핀 기능 이전
Features/Settings/SettingsView.swift         ← 홈 배경 섹션 추가
```

### 제거 파일 (2개)

```
Features/Gallery/GalleryView.swift           ← 제거
Features/Gallery/GalleryViewModel.swift      ← 제거
```

---

## 3. 데이터 모델

### 3-1. MeditationEntry.swift (전체 코드)

```swift
import Foundation

// MARK: - MeditationEntry

struct MeditationEntry: Identifiable, Codable, Hashable {
    let id: String                     // UUID().uuidString
    let userId: String                 // Firebase Auth UID ("local" = 비로그인)
    let dateKey: String                // "2026-04-09" (날짜 키, Firestore 문서 ID 겸용)
    let verseId: String                // 당일 말씀 ID
    let verseReference: String         // "이사야 41:10" (캐시용)
    let mode: String                   // AppMode.rawValue
    var prayerItems: [PrayerItem]      // 기도 제목 (최대 5개)
    var gratitudeNote: String?         // 감사 기록 (선택)
    let createdAt: Date
    var updatedAt: Date
    let source: String                 // "manual" | "stage2"

    // MARK: Computed

    var isToday: Bool {
        dateKey == Self.todayKey()
    }

    var answeredCount: Int {
        prayerItems.filter { $0.isAnswered }.count
    }

    // MARK: Factory

    static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    static func make(
        userId: String,
        verseId: String,
        verseReference: String,
        mode: String,
        prayerItems: [PrayerItem],
        gratitudeNote: String?,
        source: String = "manual"
    ) -> MeditationEntry {
        MeditationEntry(
            id: UUID().uuidString,
            userId: userId,
            dateKey: todayKey(),
            verseId: verseId,
            verseReference: verseReference,
            mode: mode,
            prayerItems: prayerItems,
            gratitudeNote: gratitudeNote?.isEmpty == true ? nil : gratitudeNote,
            createdAt: Date(),
            updatedAt: Date(),
            source: source
        )
    }
}

// MARK: - PrayerItem

struct PrayerItem: Identifiable, Codable, Hashable {
    let id: String                // UUID().uuidString
    var text: String              // 최대 200자
    var isAnswered: Bool = false
    var answeredAt: Date? = nil

    static func make(text: String) -> PrayerItem {
        PrayerItem(id: UUID().uuidString, text: text)
    }

    mutating func markAnswered() {
        isAnswered = true
        answeredAt = Date()
    }

    mutating func unmarkAnswered() {
        isAnswered = false
        answeredAt = nil
    }
}
```

### 3-2. Firestore 스키마

```
// 경로: meditation_logs/{userId}/entries/{dateKey}
// dateKey 예시: "2026-04-09"
// 하루에 1개 문서 (upsert)

{
  "id": "uuid-string",
  "user_id": "firebase-uid",
  "date_key": "2026-04-09",
  "verse_id": "v_001",
  "verse_reference": "이사야 41:10",
  "mode": "rise_ignite",
  "prayer_items": [
    {
      "id": "uuid",
      "text": "팀장 보고 잘 할 수 있도록",
      "is_answered": false,
      "answered_at": null
    }
  ],
  "gratitude_note": "점심이 맛있었다",
  "created_at": Timestamp,
  "updated_at": Timestamp,
  "source": "manual"
}
```

### 3-3. UserDefaults 캐시 키

```swift
// 오늘 기록 (최신 상태 캐시)
"meditation_today_v1"     → Data (MeditationEntry JSON)

// 오프라인 대기 큐 (미동기화 항목)
"meditation_pending_v1"   → Data ([MeditationEntry] JSON)

// 스트릭 (StreakManager가 관리)
"streak_current_v1"       → Int
"streak_longest_v1"       → Int
"streak_last_date_v1"     → String ("2026-04-09")
"streak_total_days_v1"    → Int
```

---

## 4. StreakManager.swift (전체 코드)

```swift
import Foundation

// MARK: - StreakManager
// 책임: 스트릭 상태 관리 (UserDefaults 기반)
// 스트릭 인정 기준: 기도 제목 1개 이상 저장 = 1일

@MainActor
final class StreakManager: ObservableObject {

    static let shared = StreakManager()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var totalDays: Int = 0
    @Published private(set) var didMeditateToday: Bool = false

    // UserDefaults 키
    private let kCurrent   = "streak_current_v1"
    private let kLongest   = "streak_longest_v1"
    private let kLastDate  = "streak_last_date_v1"
    private let kTotal     = "streak_total_days_v1"

    private let defaults = UserDefaults.standard

    private init() {
        load()
        checkAndResetIfBroken()
    }

    // MARK: - Public API

    /// 묵상 저장 완료 시 호출
    func recordMeditation() {
        let today = MeditationEntry.todayKey()
        let lastDate = defaults.string(forKey: kLastDate) ?? ""

        if lastDate == today {
            // 오늘 이미 기록 → 중복 카운트 없음
            didMeditateToday = true
            return
        }

        let yesterday = dayBefore(today)
        if lastDate == yesterday {
            // 연속 → 스트릭 +1
            currentStreak += 1
        } else {
            // 끊김 (어제도 아니고 오늘도 아님) → 리셋 후 1
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        totalDays += 1
        didMeditateToday = true

        defaults.set(currentStreak, forKey: kCurrent)
        defaults.set(longestStreak, forKey: kLongest)
        defaults.set(today,         forKey: kLastDate)
        defaults.set(totalDays,     forKey: kTotal)
    }

    /// 앱 시작 시 호출 — 오늘 묵상 여부 + 스트릭 유효성 확인
    func checkAndResetIfBroken() {
        let today = MeditationEntry.todayKey()
        let yesterday = dayBefore(today)
        let lastDate = defaults.string(forKey: kLastDate) ?? ""

        didMeditateToday = (lastDate == today)

        // 어제 또는 오늘이 아니면 스트릭 깨짐
        if !lastDate.isEmpty && lastDate != today && lastDate != yesterday {
            currentStreak = 0
            defaults.set(0, forKey: kCurrent)
        }
    }

    /// 이번 달 묵상한 날짜 Set 반환 (히트맵용) — Repository에서 주입받음
    func updateMeditatedDates(_ dateKeys: Set<String>) {
        self.meditatedDatesThisMonth = dateKeys
    }
    @Published private(set) var meditatedDatesThisMonth: Set<String> = []

    // MARK: - Private

    private func load() {
        currentStreak = defaults.integer(forKey: kCurrent)
        longestStreak = defaults.integer(forKey: kLongest)
        totalDays     = defaults.integer(forKey: kTotal)
    }

    private func dayBefore(_ dateKey: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateKey) else { return "" }
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        return f.string(from: prev)
    }
}
```

---

## 5. MeditationRepository.swift (전체 코드)

```swift
import Foundation
import FirebaseFirestore

// MARK: - MeditationRepository
// 책임: Firestore (primary) + UserDefaults JSON (오프라인 캐시/대기열)

final class MeditationRepository {

    private let db = Firestore.firestore()
    private let kToday   = "meditation_today_v1"
    private let kPending = "meditation_pending_v1"
    private let defaults = UserDefaults.standard

    // MARK: - 저장 (Upsert)

    /// 오늘의 묵상 저장. 오프라인이면 대기열에 저장 후 나중에 재시도.
    func save(_ entry: MeditationEntry) async throws {
        // 1) 로컬 캐시 즉시 업데이트 (UI 즉각 반영)
        saveTodayCache(entry)

        // 2) Firestore 저장 시도
        guard entry.userId != "local" else { return } // 비로그인 → 로컬만
        do {
            try await db
                .collection("meditation_logs")
                .document(entry.userId)
                .collection("entries")
                .document(entry.dateKey)
                .setData(from: entry, merge: true)
            // 성공 시 대기열 제거
            removePendingEntry(dateKey: entry.dateKey)
        } catch {
            // 실패 시 대기열에 추가 (재시도 대상)
            addToPendingQueue(entry)
            throw error
        }
    }

    /// 응답됨 체크 업데이트
    func updatePrayerItem(
        _ item: PrayerItem,
        in entry: MeditationEntry
    ) async throws {
        guard entry.userId != "local" else {
            // 로컬 캐시만 업데이트
            var cached = todayCache()
            if var cachedEntry = cached {
                if let idx = cachedEntry.prayerItems.firstIndex(where: { $0.id == item.id }) {
                    cachedEntry.prayerItems[idx] = item
                    saveTodayCache(cachedEntry)
                }
            }
            return
        }
        // Firestore: prayer_items 배열 전체 교체 (ArrayUnion은 struct 불가)
        var updated = entry
        if let idx = updated.prayerItems.firstIndex(where: { $0.id == item.id }) {
            updated.prayerItems[idx] = item
            updated.updatedAt = Date()
        }
        try await save(updated)
    }

    // MARK: - 조회

    /// 오늘 묵상 (캐시 우선 → Firestore 폴백)
    func fetchToday(userId: String) async -> MeditationEntry? {
        let today = MeditationEntry.todayKey()
        // 캐시 히트
        if let cached = todayCache(), cached.dateKey == today, cached.userId == userId {
            return cached
        }
        // Firestore
        guard userId != "local" else { return nil }
        return try? await db
            .collection("meditation_logs")
            .document(userId)
            .collection("entries")
            .document(today)
            .getDocument(as: MeditationEntry.self)
    }

    /// 히스토리 (최신순, limit 개수)
    func fetchHistory(userId: String, limit: Int = 30) async -> [MeditationEntry] {
        guard userId != "local" else { return [] }
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

    /// 이번 달 묵상한 dateKey Set (히트맵용)
    func fetchThisMonthDateKeys(userId: String) async -> Set<String> {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        let prefix = f.string(from: Date())
        let all = await fetchHistory(userId: userId, limit: 60)
        return Set(all.map { $0.dateKey }.filter { $0.hasPrefix(prefix) })
    }

    // MARK: - 오프라인 대기열 플러시

    /// 네트워크 복구 시 호출 — 대기 중인 항목 일괄 업로드
    func flushPendingQueue() async {
        var pending = pendingQueue()
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
            } catch {
                break // 네트워크 여전히 없으면 중단
            }
        }
        pending.removeAll { flushed.contains($0.dateKey) }
        savePendingQueue(pending)
    }

    // MARK: - Private Cache Helpers

    private func todayCache() -> MeditationEntry? {
        guard let data = defaults.data(forKey: kToday) else { return nil }
        return try? JSONDecoder().decode(MeditationEntry.self, from: data)
    }

    private func saveTodayCache(_ entry: MeditationEntry) {
        if let data = try? JSONEncoder().encode(entry) {
            defaults.set(data, forKey: kToday)
        }
    }

    private func pendingQueue() -> [MeditationEntry] {
        guard let data = defaults.data(forKey: kPending) else { return [] }
        return (try? JSONDecoder().decode([MeditationEntry].self, from: data)) ?? []
    }

    private func savePendingQueue(_ entries: [MeditationEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: kPending)
        }
    }

    private func addToPendingQueue(_ entry: MeditationEntry) {
        var queue = pendingQueue()
        queue.removeAll { $0.dateKey == entry.dateKey } // 중복 제거
        queue.append(entry)
        savePendingQueue(queue)
    }

    private func removePendingEntry(dateKey: String) {
        var queue = pendingQueue()
        queue.removeAll { $0.dateKey == dateKey }
        savePendingQueue(queue)
    }
}
```

---

## 6. MeditationViewModel.swift (전체 코드)

```swift
import SwiftUI

// MARK: - MeditationViewModel

@MainActor
final class MeditationViewModel: ObservableObject {

    // MARK: Published State

    @Published var todayEntry: MeditationEntry?        // 오늘의 묵상
    @Published var history: [MeditationEntry] = []     // 과거 기록
    @Published var isLoading = false
    @Published var toastMessage: String?
    @Published var showWriteSheet = false              // 작성 모달 표시

    // MARK: Dependencies

    private let repository: MeditationRepository
    let streakManager: StreakManager                   // View에서 직접 접근

    // MARK: Init

    init(
        repository: MeditationRepository = MeditationRepository(),
        streakManager: StreakManager = .shared
    ) {
        self.repository = repository
        self.streakManager = streakManager
    }

    // MARK: - Load

    func load(userId: String) async {
        isLoading = true
        async let today = repository.fetchToday(userId: userId)
        async let hist  = repository.fetchHistory(userId: userId, limit: 30)
        async let monthKeys = repository.fetchThisMonthDateKeys(userId: userId)

        todayEntry = await today
        history    = await hist
        streakManager.updateMeditatedDates(await monthKeys)
        streakManager.checkAndResetIfBroken()
        isLoading = false
    }

    // MARK: - Save

    /// 묵상 작성 완료 시 호출
    func saveEntry(
        userId: String,
        verseId: String,
        verseReference: String,
        mode: String,
        prayerItems: [PrayerItem],
        gratitudeNote: String?,
        source: String = "manual"
    ) async {
        let entry = MeditationEntry.make(
            userId: userId.isEmpty ? "local" : userId,
            verseId: verseId,
            verseReference: verseReference,
            mode: mode,
            prayerItems: prayerItems,
            gratitudeNote: gratitudeNote,
            source: source
        )
        do {
            try await repository.save(entry)
            todayEntry = entry
            // 기존 히스토리에 오늘 항목 upsert
            history.removeAll { $0.dateKey == entry.dateKey }
            history.insert(entry, at: 0)
            // 스트릭 업데이트
            streakManager.recordMeditation()
            // 이번 달 히트맵 업데이트
            let monthKeys = await repository.fetchThisMonthDateKeys(userId: userId)
            streakManager.updateMeditatedDates(monthKeys)
            showToast("✅ 오늘의 묵상이 기록되었어요")
        } catch {
            // 오프라인 임시 저장됨
            todayEntry = entry
            streakManager.recordMeditation()
            showToast("📶 오프라인 상태예요. 연결되면 자동으로 저장돼요")
        }
        showWriteSheet = false
    }

    // MARK: - Answer Prayer

    func toggleAnswered(item: PrayerItem, in entry: MeditationEntry) async {
        guard var updated = (history.first { $0.id == entry.id } ?? todayEntry) else { return }
        guard let idx = updated.prayerItems.firstIndex(where: { $0.id == item.id }) else { return }

        if updated.prayerItems[idx].isAnswered {
            updated.prayerItems[idx].unmarkAnswered()
        } else {
            updated.prayerItems[idx].markAnswered()
            showToast("🙏 기도에 응답하셨네요")
        }
        updated.updatedAt = Date()

        do {
            try await repository.save(updated)
        } catch {
            // 오프라인 시에도 로컬 상태는 반영
        }
        // 로컬 상태 업데이트
        if updated.isToday { todayEntry = updated }
        if let hi = history.firstIndex(where: { $0.id == entry.id }) {
            history[hi] = updated
        }
    }

    // MARK: - Delete Prayer Item

    func deletePrayerItem(_ item: PrayerItem, in entry: MeditationEntry) async {
        guard var updated = (history.first { $0.id == entry.id } ?? todayEntry) else { return }
        updated.prayerItems.removeAll { $0.id == item.id }
        updated.updatedAt = Date()
        do { try await repository.save(updated) } catch {}
        if updated.isToday { todayEntry = updated }
        if let hi = history.firstIndex(where: { $0.id == entry.id }) {
            history[hi] = updated
        }
    }

    // MARK: - Toast

    func showToast(_ message: String) {
        toastMessage = message
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            self?.toastMessage = nil
        }
    }

    // MARK: - History Access Control

    /// Free 유저 히스토리 잠금 기준: 7일 이전 항목
    func isLocked(_ entry: MeditationEntry, isPremium: Bool) -> Bool {
        guard !isPremium else { return false }
        guard let date = dateFromKey(entry.dateKey) else { return false }
        let daysDiff = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return daysDiff > 7
    }

    private func dateFromKey(_ key: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }
}
```

---

## 7. MeditationView.swift (전체 코드)

```swift
import SwiftUI

// MARK: - MeditationView (묵상 탭 메인)

struct MeditationView: View {

    @StateObject private var viewModel = MeditationViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager

    // 홈뷰에서 오늘의 말씀 참조 (AlarmCoordinator 또는 HomeViewModel 경유)
    // 없으면 빈 값으로 graceful 처리
    var todayVerseId: String = ""
    var todayVerseReference: String = ""
    var todayMode: String = AppMode.current.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvBgDeep.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.dvAccentGold)
                } else if viewModel.todayEntry == nil && viewModel.history.isEmpty {
                    emptyStateView
                } else {
                    mainScrollView
                }

                // 토스트
                if let msg = viewModel.toastMessage {
                    VStack {
                        Spacer()
                        ToastView(message: msg)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 12)
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.toastMessage)
                }
            }
            .navigationTitle("묵상")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showWriteSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.dvAccentGold)
                    }
                    .accessibilityLabel("오늘의 묵상 작성")
                }
            }
        }
        .sheet(isPresented: $viewModel.showWriteSheet) {
            MeditationWriteSheet(
                existingEntry: viewModel.todayEntry,
                verseId: todayVerseId,
                verseReference: todayVerseReference,
                mode: todayMode
            ) { prayerItems, gratitudeNote in
                Task {
                    await viewModel.saveEntry(
                        userId: authManager.userId ?? "",
                        verseId: todayVerseId,
                        verseReference: todayVerseReference,
                        mode: todayMode,
                        prayerItems: prayerItems,
                        gratitudeNote: gratitudeNote
                    )
                }
            }
        }
        .task {
            await viewModel.load(userId: authManager.userId ?? "local")
        }
    }

    // MARK: - Main Scroll View

    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 스트릭 카드
                streakCard
                    .padding(.horizontal, 16)

                // 오늘의 묵상 섹션
                todaySection
                    .padding(.horizontal, 16)

                // 지난 묵상 섹션
                if !viewModel.history.filter({ !$0.isToday }).isEmpty {
                    historySection
                        .padding(.horizontal, 16)
                }

                Spacer().frame(height: 20)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.system(size: 24))
                        Text("\(viewModel.streakManager.currentStreak)일 연속 묵상")
                            .font(.dvTitle)
                            .foregroundColor(.dvAccentGold)
                    }
                    Text(viewModel.streakManager.didMeditateToday
                         ? "오늘도 묵상을 이어가셨네요 ✓"
                         : "오늘 묵상을 아직 기록하지 않으셨어요")
                        .font(.dvCaption)
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
            }

            // 이번 달 히트맵
            StreakHeatmapView(
                meditatedDates: viewModel.streakManager.meditatedDatesThisMonth
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dvPrimaryDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.dvAccentGold.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("오늘의 묵상")
                .font(.dvUITitle)
                .foregroundColor(.white.opacity(0.85))

            if let entry = viewModel.todayEntry {
                TodayEntryCard(entry: entry) {
                    viewModel.showWriteSheet = true
                } onToggleAnswered: { item in
                    Task { await viewModel.toggleAnswered(item: item, in: entry) }
                }
            } else {
                // 미작성 상태
                Button {
                    viewModel.showWriteSheet = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            if !todayVerseReference.isEmpty {
                                Text(todayVerseReference)
                                    .font(.dvCaption)
                                    .foregroundColor(.dvAccentGold)
                            }
                            Text("+ 오늘의 묵상 시작하기")
                                .font(.dvBody)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.dvPrimaryMid.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        let isPremium = subscriptionManager.isPremium
        let pastEntries = viewModel.history.filter { !$0.isToday }

        return VStack(alignment: .leading, spacing: 10) {
            Text("지난 묵상")
                .font(.dvUITitle)
                .foregroundColor(.white.opacity(0.85))

            ForEach(pastEntries) { entry in
                if viewModel.isLocked(entry, isPremium: isPremium) {
                    // 잠금 카드
                    LockedHistoryCard()
                        .onTapGesture {
                            if upsellManager.shouldShowUpsell(for: .meditationHistory) {
                                // UpsellBottomSheet 표시 (기존 메커니즘 재사용)
                            }
                        }
                } else {
                    HistoryEntryCard(entry: entry) { item in
                        Task { await viewModel.toggleAnswered(item: item, in: entry) }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundColor(.dvAccentGold.opacity(0.6))

            VStack(spacing: 8) {
                Text("오늘 받은 말씀으로")
                    .font(.dvTitle)
                    .foregroundColor(.white.opacity(0.85))
                Text("첫 묵상을 시작해보세요")
                    .font(.dvTitle)
                    .foregroundColor(.white.opacity(0.85))
            }
            .multilineTextAlignment(.center)

            Text("걱정되는 것, 감사한 것을\n자유롭게 적어보세요")
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)

            Button {
                viewModel.showWriteSheet = true
            } label: {
                Text("+ 오늘의 묵상 시작하기")
                    .font(.dvBody.weight(.semibold))
                    .foregroundColor(.dvPrimaryDeep)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Color.dvAccentGold)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - StreakHeatmapView (이번 달 히트맵)

private struct StreakHeatmapView: View {
    let meditatedDates: Set<String>

    private var calendarDays: [(key: String, day: Int)] {
        let cal = Calendar.current
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: now) else { return [] }
        return range.map { day -> (String, Int) in
            var c = comps; c.day = day
            let date = cal.date(from: c)!
            return (f.string(from: date), day)
        }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(calendarDays, id: \.key) { item in
                let isMeditated = meditatedDates.contains(item.key)
                let isToday = item.key == MeditationEntry.todayKey()
                Circle()
                    .fill(isMeditated ? Color.dvAccentGold : Color.white.opacity(0.12))
                    .frame(width: 7, height: 7)
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color.dvAccentGold : Color.clear, lineWidth: 1.5)
                            .padding(-3)
                    )
            }
        }
    }
}

// MARK: - TodayEntryCard

private struct TodayEntryCard: View {
    let entry: MeditationEntry
    let onEdit: () -> Void
    let onToggleAnswered: (PrayerItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 상단: 말씀 참조 + 편집
            HStack {
                Text(entry.verseReference)
                    .font(.dvCaption)
                    .foregroundColor(.dvAccentGold)
                Spacer()
                Button("편집", action: onEdit)
                    .font(.dvCaption)
                    .foregroundColor(.dvAccentGold.opacity(0.7))
            }

            Divider().background(Color.white.opacity(0.1))

            // 기도 제목
            ForEach(entry.prayerItems) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.isAnswered ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isAnswered ? .green : .white.opacity(0.3))
                        .onTapGesture { onToggleAnswered(item) }
                    Text(item.text)
                        .font(.dvBody)
                        .foregroundColor(item.isAnswered ? .white.opacity(0.45) : .white.opacity(0.85))
                        .strikethrough(item.isAnswered, color: .white.opacity(0.3))
                }
            }

            // 감사 기록
            if let note = entry.gratitudeNote, !note.isEmpty {
                HStack(spacing: 6) {
                    Text("✨")
                    Text(note)
                        .font(.dvBody)
                        .foregroundColor(.white.opacity(0.65))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.dvPrimaryMid.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.dvAccentGold.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - HistoryEntryCard

private struct HistoryEntryCard: View {
    let entry: MeditationEntry
    let onToggleAnswered: (PrayerItem) -> Void

    private var dateDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: entry.dateKey) else { return entry.dateKey }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ko_KR")
        out.dateFormat = "M월 d일 E"
        return out.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateDisplay)
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.45))
                Spacer()
                if entry.answeredCount > 0 {
                    Text("✓ \(entry.answeredCount)개 응답됨")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            Text(entry.verseReference)
                .font(.dvCaption.weight(.medium))
                .foregroundColor(.dvAccentGold.opacity(0.75))

            if let first = entry.prayerItems.first {
                HStack(spacing: 6) {
                    Image(systemName: first.isAnswered ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(first.isAnswered ? .green : .white.opacity(0.25))
                        .font(.system(size: 13))
                        .onTapGesture { onToggleAnswered(first) }
                    Text(first.text)
                        .font(.dvBody)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                    if entry.prayerItems.count > 1 {
                        Text("+\(entry.prayerItems.count - 1)")
                            .font(.dvCaption)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dvPrimaryMid.opacity(0.3))
        )
    }
}

// MARK: - LockedHistoryCard

private struct LockedHistoryCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("지난 묵상")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.3))
                Text("Premium에서 모든 기록을 되돌아보세요")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Image(systemName: "lock.fill")
                .foregroundColor(.white.opacity(0.25))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dvPrimaryMid.opacity(0.2))
        )
        .blur(radius: 0.5)
    }
}

// MARK: - Preview

#Preview {
    MeditationView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
}
```

---

## 8. MeditationWriteSheet.swift (전체 코드)

```swift
import SwiftUI

// MARK: - MeditationWriteSheet

struct MeditationWriteSheet: View {

    // 수정 모드 시 기존 항목 (nil = 신규)
    let existingEntry: MeditationEntry?
    let verseId: String
    let verseReference: String
    let mode: String
    let onSave: ([PrayerItem], String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var prayerTexts: [String] = [""]
    @State private var gratitudeText: String = ""
    @FocusState private var focusedField: Int?

    private var canSave: Bool {
        prayerTexts.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvBgDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // 오늘의 말씀 참조 카드
                        if !verseReference.isEmpty {
                            verseRefCard
                        }

                        // 기도 제목 섹션
                        prayerSection

                        // 감사 기록 섹션
                        gratitudeSection

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(existingEntry == nil ? "오늘의 묵상" : "묵상 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") { saveAndDismiss() }
                        .foregroundColor(canSave ? .dvAccentGold : .white.opacity(0.25))
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { prefillIfEditing() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Verse Ref Card

    private var verseRefCard: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .foregroundColor(.dvAccentGold)
            Text(verseReference)
                .font(.dvBody.weight(.medium))
                .foregroundColor(.dvAccentGold)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dvAccentGold.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dvAccentGold.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - Prayer Section

    private var prayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text("기도 제목")
                    .font(.dvUITitle)
                    .foregroundColor(.white.opacity(0.85))
                // 툴팁 버튼
                Button {
                    // ToastView 재사용하거나 Alert
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.35))
                }
                .accessibilityLabel("기도 제목이란?")
            }

            // 빠른 템플릿 칩
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TemplateChip(label: "😰 걱정") {
                        appendTemplate("😰 걱정: ")
                    }
                    TemplateChip(label: "🙏 부탁") {
                        appendTemplate("🙏 부탁: ")
                    }
                    TemplateChip(label: "✨ 감사") {
                        appendTemplate("✨ 감사: ")
                    }
                }
            }

            // 기도 제목 입력 필드들
            ForEach(prayerTexts.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle")
                        .foregroundColor(.white.opacity(0.25))
                        .font(.system(size: 14))
                        .padding(.top, 12)

                    TextField(
                        idx == 0 ? "오늘 기도하고 싶은 것을 적어보세요..." : "기도 제목 추가...",
                        text: $prayerTexts[idx],
                        axis: .vertical
                    )
                    .font(.dvBody)
                    .foregroundColor(.white)
                    .tint(.dvAccentGold)
                    .lineLimit(1...4)
                    .focused($focusedField, equals: idx)
                    .padding(.vertical, 10)

                    if prayerTexts.count > 1 {
                        Button {
                            prayerTexts.remove(at: idx)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
            }

            // + 추가 버튼
            if prayerTexts.count < 5 {
                Button {
                    prayerTexts.append("")
                    focusedField = prayerTexts.count - 1
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("기도 제목 추가")
                    }
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }

    // MARK: - Gratitude Section

    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("오늘 감사한 것")
                    .font(.dvUITitle)
                    .foregroundColor(.white.opacity(0.85))
                Text("(선택)")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.35))
            }

            HStack(alignment: .top, spacing: 10) {
                Text("✨")
                    .padding(.top, 10)
                TextField("오늘 감사한 한 가지는?", text: $gratitudeText, axis: .vertical)
                    .font(.dvBody)
                    .foregroundColor(.white)
                    .tint(.dvAccentGold)
                    .lineLimit(1...3)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }

    // MARK: - Helpers

    private func appendTemplate(_ prefix: String) {
        if let idx = prayerTexts.indices.last, prayerTexts[idx].isEmpty {
            prayerTexts[idx] = prefix
        } else if prayerTexts.count < 5 {
            prayerTexts.append(prefix)
        }
        focusedField = prayerTexts.count - 1
    }

    private func saveAndDismiss() {
        let items = prayerTexts
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { PrayerItem.make(text: $0) }
        let gratitude = gratitudeText.trimmingCharacters(in: .whitespaces)
        onSave(items, gratitude.isEmpty ? nil : gratitude)
        dismiss()
    }

    private func prefillIfEditing() {
        guard let entry = existingEntry else { return }
        prayerTexts = entry.prayerItems.map { $0.text }.isEmpty ? [""] : entry.prayerItems.map { $0.text }
        gratitudeText = entry.gratitudeNote ?? ""
    }
}

// MARK: - TemplateChip

private struct TemplateChip: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                )
        }
    }
}

#Preview {
    MeditationWriteSheet(
        existingEntry: nil,
        verseId: "v_001",
        verseReference: "이사야 41:10",
        mode: "rise_ignite"
    ) { _, _ in }
    .environmentObject(AuthManager())
}
```

---

## 9. 수정 파일별 변경 내용

### 9-1. MainTabView.swift

```swift
// 변경 전
GalleryView().tag(3)
// (3, "갤러리", "photo.on.rectangle")

// 변경 후
MeditationView(
    todayVerseId: homeViewModel.currentVerseId,
    todayVerseReference: homeViewModel.currentVerseReference,
    todayMode: homeViewModel.currentMode.rawValue
).tag(3)
// (3, "묵상", "leaf.fill")
```

**HomeViewModel에 추가할 computed properties:**
```swift
var currentVerseId: String { /* DailyCacheManager에서 읽기 */ }
var currentVerseReference: String { /* 로드된 Verse에서 읽기 */ }
```

### 9-2. AlarmStage2View.swift — WordOfDaySheet 연결

```swift
// 기존: WordOfDaySheet → 말씀 텍스트만 표시
// 변경: WordOfDaySheet → 묵상 저장 연결

// AlarmStage2View에 추가
@State private var quickMeditationText: String = ""

// WordOfDaySheet 클로저에 저장 로직 추가:
WordOfDaySheet(verse: verse, mode: alarmMode) { inputText in
    showWordSheet = false
    if !inputText.isEmpty {
        // MeditationRepository에 Stage2 경유 저장
        Task {
            let repo = MeditationRepository()
            let item = PrayerItem.make(text: inputText)
            let entry = MeditationEntry.make(
                userId: authManager.userId ?? "local",
                verseId: verse.id,
                verseReference: verse.reference,
                mode: alarmMode.rawValue,
                prayerItems: [item],
                gratitudeNote: nil,
                source: "stage2"
            )
            try? await repo.save(entry)
            await StreakManager.shared.recordMeditation()
        }
    }
}

// WordOfDaySheet에 텍스트 입력창 추가:
// (기존 말씀 표시 유지 + 하단에 TextField 추가)
// onDismiss 콜백을 (String) -> Void 로 변경
```

### 9-3. FirestoreService.swift — meditation_logs CRUD

```swift
// 추가 (MeditationRepository에서 직접 Firestore 접근하므로
//        FirestoreService에는 별도 메서드 불필요.
//        Codable 자동 인코딩/디코딩 활용)
```

### 9-4. NotificationManager.swift — 리마인더 추가

```swift
// 기존 알람 스케줄링 로직 하단에 추가

func scheduleMeditationReminders() {
    // 저녁 리마인더 (21:00) + 스트릭 위기 (20:00, streak >= 3)
    // 매일 갱신 (묵상 완료 시 해당 날 취소)
    let center = UNUserNotificationCenter.current()

    // 1) 저녁 리마인더
    let eveningContent = UNMutableNotificationContent()
    eveningContent.title = "DailyVerse"
    eveningContent.body = "📿 오늘 묵상을 아직 기록하지 않으셨어요"
    eveningContent.sound = .default
    var eveningComponents = DateComponents()
    eveningComponents.hour = 21
    eveningComponents.minute = 0
    let eveningTrigger = UNCalendarNotificationTrigger(
        dateMatching: eveningComponents, repeats: true
    )
    let eveningRequest = UNNotificationRequest(
        identifier: "meditation.evening.reminder",
        content: eveningContent,
        trigger: eveningTrigger
    )
    center.add(eveningRequest)
}

func cancelMeditationRemindersForToday() {
    // 묵상 완료 시 호출
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(
            withIdentifiers: ["meditation.evening.reminder",
                              "meditation.streak.warning"]
        )
    // 내일 것 다시 스케줄
    scheduleMeditationReminders()
}
```

### 9-5. UpsellManager.swift — 신규 트리거

```swift
enum UpsellTrigger {
    // 기존 5가지 ...
    case nextVerse
    case savedVerse
    case savedTabOld
    case savedTabExpired
    case alarmTheme
    // 신규 2가지
    case meditationHistory    // 8일+ 히스토리 카드 탭
    case meditationFilter     // 응답됨 필터 탭 (Free)
}
```

---

## 10. 구현 순서 (세션별 가이드)

### Session 1 — 데이터 레이어 (약 2~3시간)
1. `MeditationEntry.swift` 생성
2. `StreakManager.swift` 생성
3. `MeditationRepository.swift` 생성
4. `FirestoreService.swift` — Codable 확장 확인 (별도 변경 없음)

### Session 2 — 묵상 탭 UI (약 3~4시간)
5. `MeditationViewModel.swift` 생성
6. `MeditationView.swift` 생성 (메인 + 서브 컴포넌트 포함)
7. `MeditationWriteSheet.swift` 생성
8. `MainTabView.swift` — GalleryView → MeditationView 교체, 탭바 아이콘 변경

### Session 3 — 연동 (약 2시간)
9. `AlarmStage2View.swift` — WordOfDaySheet 확장 (입력창 + 저장 연결)
10. `HomeViewModel.swift` — currentVerseId, currentVerseReference 프로퍼티 추가

### Session 4 — 알림 + 업셀 + Gallery 정리 (약 2시간)
11. `NotificationManager.swift` — 리마인더 추가
12. `UpsellManager.swift` — 신규 트리거 추가
13. `SavedDetailView.swift` — Gallery 핀 UI 이전
14. `SettingsView.swift` — 홈 배경 섹션 추가
15. `GalleryView.swift`, `GalleryViewModel.swift` 파일 제거

---

## 11. 엣지케이스 처리 요약

| 케이스 | 처리 |
|--------|------|
| 오늘 묵상 미기록 + 스트릭 0 | 빈 상태 화면 표시 |
| 오프라인 저장 | UserDefaults 임시 저장 + 토스트 "자동으로 저장돼요" |
| 비로그인 | 로컬 저장 허용, 로그인 유도 배너 (선택) |
| Stage2 입력 후 탭에서 중복 | dateKey 기준 upsert — 덮어쓰지 않고 prayerItems에 추가 |
| 응답됨 체크 오프라인 | 로컬 상태만 변경, 토스트 없음 (silent) |
| Free 유저 8일+ 탭 | 업셀 24시간 제한 적용, 초과 시 잠금 아이콘만 |
| 스트릭 앱 삭제 후 재설치 | UserDefaults 초기화 → 0부터 재시작 (v1 허용 범위) |
| Stage 2 입력 + 직접 탭 작성 같은 날 | dateKey 동일 → upsert (Stage2 기록 위에 병합) |

---

## 12. 제거 주의 사항

`GalleryView.swift`, `GalleryViewModel.swift` 제거 전 확인:
- `GalleryViewModel.pinImage()`, `unpinImage()` 로직 → `SavedDetailView`로 이전 완료 후 제거
- `DVUser.PinnedImages` 모델은 유지 (User.swift에 남겨둠)
- MainTabView에서 `import` 제거

---

*다음 단계: Session 1부터 순서대로 구현 시작*
*구현 후: `/pdca analyze meditation-tab` 으로 Gap 분석*
