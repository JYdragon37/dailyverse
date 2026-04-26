import Foundation
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Rate Limiting (통계 쓰기 남용 방지)
    private var lastVerseStatUpdate: [String: Date] = [:]
    private let verseStatCooldown: TimeInterval = 300  // 5분 쿨다운

    // MARK: - Verses

    func fetchVerses() async throws -> [Verse] {
        let snapshot = try await db.collection("verses")
            .whereField("status", isEqualTo: "active")
            .whereField("curated", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Verse.self) }
    }

    /// 말씀 단건 조회 (저장 탭 상세 표시용)
    func fetchVerse(id: String) async throws -> Verse? {
        let doc = try await db.collection("verses").document(id).getDocument()
        return try? doc.data(as: Verse.self)
    }

    /// v5.1 — 말씀 노출 후 last_shown + show_count 업데이트 (하위 호환 유지)
    func markVerseAsShown(verseId: String) async {
        // Rate limit: 동일 말씀은 5분 내 재업데이트 방지
        let now = Date()
        let key = "mark_\(verseId)"
        if let last = lastVerseStatUpdate[key], now.timeIntervalSince(last) < verseStatCooldown {
            return
        }
        lastVerseStatUpdate[key] = now

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        try? await db.collection("verses").document(verseId).updateData([
            "last_shown": today,
            "show_count": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - 유저별 말씀 이력 (v6.0 — 1만 유저 대응 중복 노출 최소화)

    /// 유저의 최근 본 말씀 ID 목록 조회 (max 30)
    func fetchRecentVerseIds(userId: String) async -> [String] {
        guard let doc = try? await db.collection("users").document(userId).getDocument(),
              let ids = doc.data()?["recent_verse_ids"] as? [String] else { return [] }
        return ids
    }

    /// 말씀 노출 후 유저 이력 추가 + 전역 verse_stats 업데이트
    /// - recentIds: 현재 유저의 이력 (FIFO, max 30)
    func recordVerseShown(verseId: String, userId: String, zone: String, currentIds: [String]) async {
        // Rate limit: 동일 말씀+유저 조합은 5분 내 재기록 방지
        let now = Date()
        let key = "record_\(userId)_\(verseId)"
        if let last = lastVerseStatUpdate[key], now.timeIntervalSince(last) < verseStatCooldown {
            return
        }
        lastVerseStatUpdate[key] = now

        // 유저 이력: 최신 verseId 앞에 추가, max 30개 유지
        var updated = [verseId] + currentIds.filter { $0 != verseId }
        if updated.count > 30 { updated = Array(updated.prefix(30)) }

        // users/{uid}.recent_verse_ids 업데이트
        try? await db.collection("users").document(userId).updateData([
            "recent_verse_ids": updated
        ])

        // verse_stats/{verse_id} 글로벌 통계 업데이트 (STATS 시트 연동용)
        let statsRef = db.collection("verse_stats").document(verseId)
        try? await statsRef.setData([
            "verse_id": verseId,
            "total_shown": FieldValue.increment(Int64(1)),
            "last_updated": FieldValue.serverTimestamp(),
            "zone_breakdown.\(zone)": FieldValue.increment(Int64(1))
        ], merge: true)
    }

    // MARK: - Images

    func fetchImages() async throws -> [VerseImage] {
        let snapshot = try await db.collection("images")
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: VerseImage.self) }
    }

    // MARK: - Daily Cards (v5.1 신규 — 큐레이션 카드)

    /// Bug E 수정: 모드별 큐레이션 카드 가져오기
    /// Firestore 구조: daily_cards/{YYYY-MM-DD}/{mode} (서브컬렉션 또는 모드 키)
    /// 현재 구조: daily_cards/{YYYY-MM-DD} 문서에 mode별 키 포함
    /// daily_cards/{date} 조회. image_ids 배열 지원 (dc_img_* → daily_card_images 컬렉션)
    func fetchDailyCard(for date: Date, mode: AppMode) async throws -> DailyCard? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let doc = try await db.collection("daily_cards").document(dateString).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }

        // all_zones=true면 모드 무관 공통 데이터 사용, 아니면 모드별 키 우선
        let allZones = data["all_zones"] as? Bool ?? false
        let modeData = allZones ? data : (data[mode.rawValue] as? [String: Any] ?? data)

        // image_ids: 배열 우선, 없으면 단일 image_id를 배열로 변환 (하위 호환)
        let imageIds: [String] = {
            if let arr = (modeData["image_ids"] ?? data["image_ids"]) as? [String] { return arr }
            if let single = (modeData["image_id"] ?? data["image_id"]) as? String, !single.isEmpty {
                return [single]
            }
            return []
        }()

        return DailyCard(
            date: dateString,
            verseId: modeData["verse_id"] as? String ?? data["verse_id"] as? String,
            imageIds: imageIds,
            label: data["event_name"] as? String ?? modeData["label"] as? String,
            note: data["notes"] as? String ?? modeData["note"] as? String,
            greetingKo: data["greeting_ko"] as? String,
            greetingEn: data["greeting_en"] as? String,
            eventName: data["event_name"] as? String
        )
    }

    /// daily_cards 컬렉션에서 날짜 범위 내 절기일 Set<"yyyy-MM-dd"> 반환
    /// 캘린더에서 절기 뱃지 표시용. active == true 인 문서만 포함.
    func fetchHolidayDates(from startDate: Date, to endDate: Date) async throws -> Set<String> {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let startStr = fmt.string(from: startDate)
        let endStr   = fmt.string(from: endDate)

        let snapshot = try await db.collection("daily_cards")
            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: startStr)
            .whereField(FieldPath.documentID(), isLessThanOrEqualTo: endStr)
            .whereField("active", isEqualTo: true)
            .getDocuments()

        return Set(snapshot.documents.map { $0.documentID })
    }

    /// daily_card_images/{dc_img_id} 단건 조회 → VerseImage로 변환
    func fetchDailyCardImage(id: String) async throws -> VerseImage? {
        let doc = try await db.collection("daily_card_images").document(id).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        guard let storageUrl = data["storage_url"] as? String, !storageUrl.isEmpty else { return nil }
        let eventTag = data["event_tag"] as? String ?? ""
        return VerseImage(
            id: id,
            filename: data["filename"] as? String ?? id,
            storageUrl: storageUrl,
            source: data["source"] as? String ?? "morning manna Design",
            sourceUrl: nil,
            license: data["license"] as? String ?? "Commercial",
            mode: ["all"],
            theme: [eventTag],
            mood: ["warm"],
            season: ["all"],
            weather: ["all"],
            tone: "mid",
            status: "active",
            textPosition: "bottom",
            textColor: nil,
            isSacredSafe: true,
            avoidThemes: [],
            notes: data["notes"] as? String
        )
    }

    // MARK: - Saved Verses

    func fetchSavedVerses(userId: String) async throws -> [SavedVerse] {
        let snapshot = try await db.collection("saved_verses")
            .document(userId)
            .collection("verses")
            .order(by: "saved_at", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: SavedVerse.self) }
    }

    func saveVerse(_ savedVerse: SavedVerse, userId: String) async throws {
        try await db.collection("saved_verses")
            .document(userId)
            .collection("verses")
            .document(savedVerse.id)
            .setData(from: savedVerse)
    }

    func deleteSavedVerse(id: String, userId: String) async throws {
        try await db.collection("saved_verses")
            .document(userId)
            .collection("verses")
            .document(id)
            .delete()
    }

    // MARK: - Background Images (#3 시간대별 배경)

    /// Zone 및 날씨 조건에 맞는 배경 이미지 후보 목록 반환 → 호출부에서 .randomElement() 선택
    /// 날씨 필터 규칙:
    ///   - weather == "all" → 항상 후보
    ///   - weather == "sunny" | "cloudy" | "misty" | "clear" → 항상 후보 (맑음 계열)
    ///   - weather == "rainy" → weatherCondition == "rainy" 일 때만 후보
    ///   - weather == "snowy" → weatherCondition == "snowy" 일 때만 후보
    func fetchBackgroundImages(for mode: AppMode, weatherCondition: String = "all") async throws -> [BackgroundImage] {
        let snapshot = try await db.collection("background_images")
            .whereField("zone", isEqualTo: mode.rawValue)
            .whereField("status", isEqualTo: "active")
            .getDocuments()

        let all = snapshot.documents.compactMap { try? $0.data(as: BackgroundImage.self) }

        // 맑음 계열: 날씨에 무관하게 항상 후보
        let clearVariants: Set<String> = ["all", "sunny", "cloudy", "misty", "clear"]

        return all.filter { bg in
            if clearVariants.contains(bg.weather) { return true }
            // precipitation 계열: 실제 날씨가 일치할 때만 후보
            return bg.weather == weatherCondition
        }
    }

    /// 하위 호환 — 단일 문서 방식 (레거시 경로; 새 로직은 fetchBackgroundImages 사용)
    func fetchBackgroundImage(for mode: AppMode) async throws -> BackgroundImage? {
        let candidates = try await fetchBackgroundImages(for: mode, weatherCondition: "all")
        return candidates.randomElement()
    }

    // MARK: - User

    func createUser(uid: String, email: String, displayName: String, nickname: String = "친구") async throws {
        let userData: [String: Any] = [
            "email": email,
            "display_name": displayName,
            "nickname": nickname,
            "created_at": Timestamp(date: Date()),
            "subscription_status": "free",
            "pinned_images": [:],
            "settings": [
                "timezone": TimeZone.current.identifier,
                "location_enabled": false,
                "notification_enabled": false,
                "preferred_theme": "hope",
                "wake_mission": "none"
            ]
        ]
        try await db.collection("users")
            .document(uid)
            .setData(userData, merge: true)
    }

    func fetchUser(uid: String) async throws -> DVUser? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try? doc.data(as: DVUser.self)
    }

    /// v5.1 — 닉네임 업데이트
    func updateNickname(_ nickname: String, userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "nickname": nickname
        ])
    }

    /// v5.1 — 모드별 핀 이미지 설정
    func updatePinnedImage(_ imageId: String?, forMode mode: AppMode, userId: String) async throws {
        let modeKey = mode.rawValue
        if let imageId {
            try await db.collection("users").document(userId).updateData([
                "pinned_images.\(modeKey)": imageId
            ])
        } else {
            try await db.collection("users").document(userId).updateData([
                "pinned_images.\(modeKey)": FieldValue.delete()
            ])
        }
    }

    func deleteUserData(uid: String) async throws {
        // 1. saved_verses 삭제
        let savedVerses = try await db.collection("saved_verses")
            .document(uid).collection("verses").getDocuments()
        for doc in savedVerses.documents {
            try await doc.reference.delete()
        }
        try? await db.collection("saved_verses").document(uid).delete()

        // 2. meditation_logs 삭제 (기도·감사 개인 데이터)
        let meditationEntries = try await db.collection("meditation_logs")
            .document(uid).collection("entries").getDocuments()
        for doc in meditationEntries.documents {
            try await doc.reference.delete()
        }
        try? await db.collection("meditation_logs").document(uid).delete()

        // 3. users 문서 삭제
        try await db.collection("users").document(uid).delete()
    }

    // MARK: - 콘텐츠 DB 버전

    /// app_config/content_version 문서에서 현재 버전 반환
    func fetchContentVersion() async throws -> String {
        let doc = try await db.collection("app_config").document("content_version").getDocument()
        guard let version = doc.data()?["current_version"] as? String else { return "알 수 없음" }
        let total = doc.data()?["total_active_verses"] as? Int ?? 0
        let desc = doc.data()?["description"] as? String ?? ""
        return "\(version) (\(total)개) — \(desc)"
    }
}

// MARK: - DailyCard 모델 (daily_cards 컬렉션)

struct DailyCard {
    let date: String            // "YYYY-MM-DD"
    let verseId: String?        // 편집자 확정 말씀 1개
    let imageIds: [String]      // dc_img_* 이미지 풀 — 앱이 랜덤 선택, daily_card_images/ 컬렉션
    let label: String?          // "부활절 특별 말씀" 등
    let note: String?           // 큐레이션 의도 메모
    // 절기 특별 인사말 (없으면 greetings 컬렉션 사용)
    let greetingKo: String?
    let greetingEn: String?
    let eventName: String?      // "크리스마스", "부활절" 등
}
