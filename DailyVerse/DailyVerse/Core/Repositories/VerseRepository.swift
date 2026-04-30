import Foundation
import Combine
import FirebaseCrashlytics

actor VerseRepository {
    /// 싱글톤 — actor 격리로 currentVerse() 동시 호출 방지 (홈/묵상 말씀 불일치 버그 수정)
    static let shared = VerseRepository()

    private let firestoreService = FirestoreService()
    private let cacheManager = DailyCacheManager.shared
    private let selector = VerseSelector()

    private var cachedVerses: [Verse] = []
    private var cachedImages: [VerseImage] = []
    private var lastFetched: Date?

    // 버전 기반 캐시 — UserDefaults 키
    private let kCachedVerseVersion = "cachedVerseContentVersion"

    // MARK: - Verses

    /// 전체 말씀 로드 — 버전 기반 캐시 (v7.0)
    ///
    /// 절감 효과:
    ///   - 버전 동일: 1 read (content_version 확인만)
    ///   - 버전 변경: ~200 reads (기존과 동일, 콘텐츠 업데이트 시만)
    ///
    /// 우선순위:
    ///   1. 인메모리 캐시 (30분 TTL) — 가장 빠른 경로
    ///   2. 버전 체크 → Core Data 캐시 (버전 일치 시)
    ///   3. Firestore 전체 fetch (버전 불일치 또는 캐시 없음)
    func fetchVerses() async throws -> [Verse] {
        // 1. 인메모리 캐시 (30분 TTL)
        if !cachedVerses.isEmpty, let last = lastFetched, Date().timeIntervalSince(last) < 1800 {
            return cachedVerses
        }
        do {
            return try await _fetchVersesInternal()
        } catch {
            print("❌ [VerseRepository] fetchVerses 실패: \(error.localizedDescription)")
            print("❌ [VerseRepository] 상세: \(error)")
            Crashlytics.crashlytics().record(error: error)
            throw error
        }
    }

    private func _fetchVersesInternal() async throws -> [Verse] {

        // 2. 버전 체크 (1 read)
        let remoteVersion = (try? await firestoreService.fetchRawContentVersion()) ?? ""
        let localVersion  = UserDefaults.standard.string(forKey: kCachedVerseVersion) ?? ""

        if !remoteVersion.isEmpty && remoteVersion == localVersion {
            // 버전 일치 → Core Data에서 전체 로드 (0 Firestore reads)
            let cached = await MainActor.run { cacheManager.loadAllCachedVerses() }
            if !cached.isEmpty {
                cachedVerses = cached
                lastFetched  = Date()
                return cached
            }
        }

        // 3. Firestore 전체 fetch (버전 불일치 or Core Data 미스)
        let verses = try await firestoreService.fetchVerses()
        cachedVerses = verses
        lastFetched  = Date()
        // 버전 기록 + Core Data 갱신
        if !remoteVersion.isEmpty {
            UserDefaults.standard.set(remoteVersion, forKey: kCachedVerseVersion)
        }
        let versesToCache = verses
        await MainActor.run { versesToCache.forEach { cacheManager.cacheVerse($0) } }
        // Q2: 버전 변경 시 이미지 디스크 캐시 클리어 → 새 이미지 URL 반영
        await MainActor.run { ImageDiskCache.shared.clearAll() }
        return verses
    }

    /// 현재 모드 말씀 반환 (일별 고정)
    ///
    /// 선택 우선순위:
    /// 1. daily_cards/{오늘} 큐레이션 데이터
    /// 2. DailyVerseCache (오늘 이미 결정된 말씀)
    /// 3. Cooldown 통과 알고리즘 선택
    /// 4. 번들 폴백
    ///
    /// ⚠️ 일관성 보장 원칙:
    /// - 각 await 이후 반드시 캐시를 재확인 (double-check)
    ///   → 동시에 실행 중인 다른 Task가 먼저 캐시를 설정했으면 그 값을 사용
    ///   → 홈/묵상/알람 어느 경로로 호출해도 같은 날 같은 Zone은 같은 말씀 반환
    /// 오늘의 말씀 — 하루 1회 결정, Zone/유저 무관하게 동일 (04:00 기준)
    /// userId 제외 로직 없음: daily verse는 결정론적이어야 모든 화면이 일치함
    func currentVerse(for mode: AppMode, weather: WeatherData?) async -> Verse {

        // ── 특정 verseId로 verse 본문 로드 (캐시 → Firestore) ─────────────────
        func loadVerse(id: String) async -> Verse? {
            if let v = cacheManager.loadCachedVerse(id: id) {
                cacheManager.setVerseId(id, for: mode)
                return v
            }
            if let verses = try? await fetchVerses(),
               let found = verses.first(where: { $0.id == id }) {
                cacheManager.setVerseId(found.id, for: mode)
                return found
            }
            return nil
        }

        // 1. 절기 큐레이션 (daily_cards — 성탄절, 부활절 등 특별일)
        if let card = try? await firestoreService.fetchDailyCard(for: Date(), mode: mode),
           let verseId = card.verseId,
           let v = await loadVerse(id: verseId) {
            return v
        }

        // 2. 서버 선택 말씀 (app_config/today_verse — Cloud Function 04:00 KST 기록)
        let serverVerseId = await firestoreService.fetchTodayVerseId()

        if let serverVerseId {
            // 로컬 캐시가 서버와 이미 일치하면 즉시 반환 (네트워크 최소화)
            if let cachedId = cacheManager.getTodayVerseId(),
               cachedId == serverVerseId,
               let v = cacheManager.loadCachedVerse(id: serverVerseId) {
                return v
            }
            // 불일치 or 캐시 없음 → 서버 버전으로 업데이트
            if let v = await loadVerse(id: serverVerseId) { return v }

            // 서버 ID는 알지만 verse 본문 로드 실패 → stale 캐시 사용 금지
            // (캐시에 이전 알고리즘 결과가 남아 있어도 서버 판단을 우선)
            // → 아래 알고리즘 폴백으로 낙하

        } else {
            // 3. 로컬 캐시 폴백 — 서버가 완전 미응답일 때만 사용
            //    ⚠️ serverVerseId를 받았을 때는 이 블록에 진입하지 않음
            //    → 기존 알고리즘 결과가 캐시에 남아도 오래된 값을 반환하지 않음
            if let cachedId = cacheManager.getTodayVerseId(),
               let v = cacheManager.loadCachedVerse(id: cachedId) {
                return v
            }
        }

        // 4. 알고리즘 폴백 (서버 응답 있으나 verse 로드 실패 OR 서버 미응답 + 캐시 없음)
        // ⚠️ setVerseId 호출 없음 — 알고리즘 결과를 todayVerseId에 저장하지 않음
        //    저장하면 다음 currentVerse() 호출 시 step3에서 잘못된 구절이 반환됨
        if let verses = try? await fetchVerses(),
           let selected = selector.selectDailyVerse(from: verses, weather: nil) {
            return selected
        }

        // 5. 번들 폴백 (완전 오프라인)
        return fallbackVerse(for: mode)
    }

    // nextVerse 제거됨 — 다음 말씀 기능 없음 (모든 유저 동일 말씀 정책)

    // MARK: - Images

    func fetchImages() async throws -> [VerseImage] {
        if !cachedImages.isEmpty { return cachedImages }
        let images = try await firestoreService.fetchImages()
        cachedImages = images
        return images
    }

    // MARK: - Fallback

    private func fallbackVerse(for mode: AppMode) -> Verse {
        switch mode {
        case .deepDark:   return Verse.fallbackDeepDark
        case .firstLight: return Verse.fallbackFirstLight
        case .riseIgnite: return Verse.fallbackRiseIgnite
        case .peakMode:   return Verse.fallbackPeakMode
        case .recharge:   return Verse.fallbackRecharge
        case .secondWind: return Verse.fallbackSecondWind
        case .goldenHour: return Verse.fallbackGoldenHour
        case .windDown:   return Verse.fallbackWindDown
        }
    }
}
