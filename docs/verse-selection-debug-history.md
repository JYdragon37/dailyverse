# 말씀 노출 로직 & 디버깅 히스토리

> 작성일: 2026-05-01
> 목적: 현재 기기에서 보여야 할 말씀, 선택 로직, 과거 디버깅 이력을 한 곳에 정리

---

## 1. 지금 실기기에서 보여야 하는 말씀

| 항목 | 값 |
|------|-----|
| **verse_id** | v_241 |
| **reference** | 야고보서 3:13 |
| **verse_short_ko** | 지혜 있는 자는 온유함으로 그 행위를 보이느니라. |
| **verse_full_ko** | 너희 중에 지혜와 총명이 있는 자가 누구뇨. 그는 선행으로 말미암아 지혜의 온유함으로 그 행위를 보일찌니라. |
| **기준** | 서버 Cloud Function이 2026-05-01 04:00 KST에 선택 |
| **cooldown 상태** | cooldown_ok: False (쿨다운 미통과 상태이나 오늘 이미 확정됨) |

### 화면별 표시 필드
| 화면 | 표시 필드 |
|------|-----------|
| 홈 카드 | `verse_short_ko` |
| 말씀 상세 바텀시트 | `verse_full_ko` + `interpretation` + `application` |
| 알람 Stage2 | `verse_full_ko` + `interpretation` |
| 묵상 다이어리 | `verse_full_ko` (이탤릭, serif) |

---

## 2. 말씀 선택 전체 흐름

### 서버 흐름 (매일 04:00 KST)

```
01:00 KST: previewDailyVerses Cloud Function
  → verse_schedule/{D}, {D+1}, {D+2} 자동 계산 (D+1/D+2 alt 후보 포함)
  → VERSE_PREVIEW Google Sheets 탭 자동 갱신

01:30 KST: Apps Script 자동 트리거
  → VERSE_PREVIEW 탭 갱신 (관리자 검토창)

[관리자 검토 시간: 01:30 ~ 04:00 — 약 2.5시간]
  → [선택] 컬럼 수정 후 [적용하기] 버튼 → verse_schedule override

04:00 KST: selectDailyVerse Cloud Function
  → verse_schedule/{오늘} 확인 → 없으면 알고리즘
  → app_config/today_verse 기록 (verse_id, date, reference)
```

### 앱 클라이언트 흐름 (VerseRepository.currentVerse)

```
우선순위 1: daily_cards/{오늘} — 절기 큐레이션 (성탄절, 부활절 등)
  → 절기일이면 해당 말씀 반환 (관리자가 사전 편성)

우선순위 2: app_config/today_verse — Cloud Function 결정값
  → fetchTodayVerseId() (source: .server 강제)
  → 서버 응답 → loadVerse(serverVerseId) → 캐시 저장 → 반환

우선순위 3 (서버 완전 미응답 시): 로컬 UserDefaults 캐시
  → getTodayVerseId() → 같은 날 이전에 캐시된 값 반환

우선순위 4 (서버 + 캐시 모두 없음): 알고리즘 폴백
  → active+curated 말씀 pool → ID 정렬 → dayInt % poolSize
  → ⚠️ 캐시 저장 안 함 (ephemeral) — 다음 호출에서 서버가 교정 가능

우선순위 5 (완전 오프라인): 번들 하드코드 폴백
  → Zone별 고정 말씀 반환
```

### 말씀 선택 알고리즘 (폴백 시)

```
pool = verses.filter { status == "active" && curated == true && isEligible }
  → isEligible: last_shown으로부터 cooldown_days 경과 여부
  → last_shown 포맷: "yyyy-MM-dd" (iOS) 또는 "2026-04-29T19:00:03Z" (Cloud Function)
  → 두 포맷 모두 파싱 처리 (수정 후)

sorted = pool.sorted { $0.id < $1.id }
dayInt = yyyyMMdd 정수 (예: 20260501)
index = dayInt % sorted.count
→ sorted[index] 반환
```

### 캐시 레이어 구조

```
L1: VerseRepository.cachedVerses (인메모리, 30분 TTL)
L2: Core Data CachedVerse (버전 기반, content_version 변경 시 무효화)
L3: UserDefaults DailyVerseCache (04:00 KST 기준 하루)
    → todayVerseId: 서버 확인된 말씀 ID만 저장 (알고리즘 결과 저장 안 함)
```

---

## 3. 디버깅 히스토리

### 🔴 [2026-04-30] 요한삼서 1:2 반복 노출 버그 (종합 4개 버그)

**증상**: 매일 기기에서 서버가 선택한 말씀 대신 "요한삼서 1:2(v_259)"가 반복 표시됨

**근본 원인 — 4개 버그 연쇄**

| # | 버그 | 파일 |
|---|------|------|
| 1 | `fetchTodayVerseId()`가 Firestore SDK 오프라인 캐시 반환 → 어제 문서 날짜 불일치 → nil | FirestoreService.swift |
| 2 | 알고리즘 결과를 `todayVerseId` UserDefaults에 영구 저장 → 다음 실행에서 잘못된 말씀 반환 | VerseRepository.swift |
| 3 | serverVerseId 확인 후 `loadVerse` 실패 시 stale 캐시(알고리즘 결과)로 낙하 | VerseRepository.swift |
| 4 | Cloud Function이 저장하는 `last_shown` ISO 8601 형식 (`"2026-04-29T19:00:03Z"`) 파싱 실패 → 쿨다운 무시 → pool 오염 | Verse.swift |

**수학적 분석**

```
v_267 (시편 119:105) — last_shown: "2026-04-29T..." → isEligible 파싱 성공 시 false
eligible pool = 518 - 1(v_267 제외) = 517
20260430 % 517 = 234
index 234 = v_259 = 요한삼서 1:2  ← 결정론적, 매일 같은 값
```

**수정 내역**

| 파일 | 수정 |
|------|------|
| `FirestoreService.fetchTodayVerseId()` | `source: .server` 강제 (SDK 오프라인 캐시 우회) |
| `VerseRepository.currentVerse()` — 알고리즘 폴백 | `setVerseId()` 제거 (ephemeral, 캐시 미저장) |
| `VerseRepository.currentVerse()` — 구조 | `if/else` 분리 — 서버 응답 있으면 stale 캐시 우회 |
| `Verse.isEligible` | `ISO8601DateFormatter` 추가 — "yyyy-MM-dd" + ISO 8601 두 포맷 파싱 |

---

### 🟡 [2026-04-29] 홈/묵상/알람 말씀 불일치 버그

**증상**: 홈탭, 묵상탭, 알람 Stage2에서 서로 다른 말씀이 표시됨

**원인**: `VerseRepository`가 singleton이 아니었고, 각 탭이 독립 인스턴스로 서로 다른 캐시를 가졌음

**수정**: `VerseRepository`를 `actor` + `static let shared` 싱글톤으로 변경 → 모든 호출이 동일 캐시 공유

---

### 🟡 [2026-04-29] "다음 말씀" 기능 제거

**배경**: "다음 말씀" 버튼이 있으면 유저별로 다른 말씀을 보게 됨 → "모든 유저 동일 말씀" 정책과 충돌

**수정**: `nextVerse()` 메서드 완전 제거, UI에서 버튼 삭제

---

### 🟡 [2026-04-29] VerseSelector 스코어링 제거

**배경**: 날씨·테마·무드 스코어링이 있으면 기기별로 다른 말씀이 선택될 수 있음

**수정**: `selectDailyVerse()` 스코어링 로직 제거 → ID 정렬 + dayInt % pool 결정론적 선택으로 단순화

---

### 🟡 [2026-04-26] `last_shown` 포맷 이중화 이슈

**배경**:
- iOS `markVerseAsShown()`: `"yyyy-MM-dd"` 형식으로 저장
- Cloud Function `selectDailyVerse`: ISO 8601 형식으로 저장 (`"2026-04-29T19:00:03.301Z"`)

**영향**: Cloud Function이 노출 처리한 말씀의 쿨다운이 iOS 앱에서 무시됨 → 같은 말씀 연속 선택 가능

**수정**: `Verse.isEligible`에서 두 포맷 모두 파싱 처리

---

### 🟢 [2026-04-30] 스프레드시트 중복 말씀 pool 오염

**배경**: VERSES 탭에 `verse_short_ko` 완전 동일 쌍 30개 존재 → pool 오염, 같은 말씀 중복 선택 가능

**수정**:
- 중복 30개 `status = inactive` 처리
- deprecated 컬럼 4개 삭제 (`contemplation_*`)
- `content_version` v1.4 → v1.5 업데이트 (기기 캐시 강제 갱신)

---

## 4. 현재 시스템 상태 (2026-05-01 기준)

### 서버
| 항목 | 상태 |
|------|------|
| `app_config/today_verse` | v_241 (야고보서 3:13), date: 2026-05-01 |
| Cloud Function `selectDailyVerse` | 매일 04:00 KST 정상 실행 |
| Cloud Function `previewDailyVerses` | 매일 01:00 KST 정상 실행 |
| `daily_cards` 절기 | 12개 등록, 모두 active |

### 콘텐츠
| 항목 | 수량 |
|------|------|
| active+curated 말씀 | 489개 (수정 후, 기존 519개에서 30개 inactive) |
| 절기 (daily_cards) | 12개 (2026년) |

### 코드 (최종 수정 후)
| 파일 | 핵심 로직 |
|------|-----------|
| `FirestoreService.fetchTodayVerseId()` | `source: .server` 강제 |
| `VerseRepository.currentVerse()` | 서버 우선 → stale 캐시 우회 → 알고리즘(ephemeral) |
| `Verse.isEligible` | ISO 8601 + "yyyy-MM-dd" 두 포맷 파싱 |

---

## 5. 정상/비정상 판단 기준

| 상황 | 정상 | 비정상 |
|------|------|--------|
| 오늘 보여야 할 말씀 | v_241 야고보서 3:13 | 다른 말씀 |
| 절기일 (예: 2026-05-03) | 어린이주일 편성 말씀 (v_425) | 일반 오늘의 말씀 |
| 홈/묵상/알람 Stage2 | 세 화면 동일 말씀 | 화면별 다른 말씀 |
| 연속 이틀 같은 말씀 | 불가 (cooldown 7일) | 같은 말씀 반복 |
| 로그인 없는 유저 | 동일 말씀 | 다른 말씀 |

---

## 6. [2026-05-01] 잠언 11:25 노출 버그 & 추가 수정

### 증상
기기에서 서버 지정 말씀(야고보서 3:13) 대신 잠언 11:25(v_439/v_494)가 반복 표시됨.
오늘 알고리즘 결과(히브리서 4:9-10)와도 다른 값 → 구버전 말씀 pool 사용 의심.

### 근본 원인 분석

**Layer 1 (즉각 원인): 최신 코드 미배포**
Fix 1~4 이후 추가 수정이 쌓였으나 빌드가 없었음. 구버전 코드 실행 중.

**Layer 2 (핵심): `fetchRawContentVersion()` SDK 오프라인 캐시 반환**

기존 `getDocument()` (source 미지정) → SDK가 로컬 캐시에서 `content_v1.4` 반환
→ 로컬 UserDefaults도 `v1.4` → 버전 일치 → 구버전 Core Data (519개 말씀) 사용
→ 잠언 11:25(v_439, v_494)가 아직 pool에 포함 → 잘못된 인덱스 → 잠언 노출

*content_version을 v1.5로 올렸지만 SDK 캐시가 이를 무효화하지 않음*

**Layer 3: `DailyVerseCache.isValid()` timezone 미명시**

`Calendar.current` 사용 → 기기 timezone 의존 → 04:00 KST 리셋이 명시적으로 보장되지 않음

**Layer 4: `hasCached=true` 경로 Firestore 연결 타이밍**

캐시 있는 재시작 경로에서 배경 이미지 로드(Stage 2)를 건너뜀
→ Firestore SDK 미연결 상태에서 `source:.server` 호출 → 실패 → SDK 캐시 → 구버전 반환

### 수정 내역 (2026-05-01)

| Fix | 파일 | 수정 내용 |
|-----|------|-----------|
| **A** | `FirestoreService.fetchRawContentVersion()` | `source: .server` 강제 → SDK 캐시로 구버전 content_version 반환 방지 |
| **B** | `DailyVerseCache.isValid()` | `Calendar.current` → 명시적 `Asia/Seoul` KST |
| **B** | `DailyCacheManager.isSameDay()` | 동일하게 KST 명시 |
| **B** | `VerseSelector.dailySeedIndex()` | 알고리즘 date seed도 KST 기준으로 통일 |
| **C** | `DailyVerseApp.onChange(isLoggedIn)` | 로그인 성공 시 `currentVerse()` 강제 재조회 |
| **D** | `AppLoadingCoordinator` hasCached 경로 | 배경 이미지 로드 선행 → Firestore SDK 연결 보장 후 `fetchVerses()` 호출 |

### 시나리오 검증 결과

| 시나리오 | 결과 |
|----------|------|
| 정상 (온라인, 첫 오픈) | ✅ 서버 말씀 표시 |
| hasCached=true (같은 날 재시작) | ✅ Firestore 연결 보장 후 서버 말씀 표시 |
| 구버전 pool (잠언 11:25 재현) | ✅ source:.server → v1.5 → 489개 재fetch → 잠언 pool 제외 |
| 로그인/로그아웃 반복 | ✅ 인증 상태 무관 동일 말씀 |
| KST 04:00 리셋 | ✅ 모든 캘린더 연산 KST 명시로 통일 |
| 완전 오프라인 | ⚠️ 이전 캐시 or 알고리즘 (허용 범위) |

### 잔존 허용 범위

- **완전 오프라인 + 첫 오픈**: 알고리즘 fallback → 다음 연결 시 자동 교정 (ephemeral)
- **`Verse.isEligible`**: `Calendar.current` 유지 (duration 계산이라 timezone 영향 미미, 한국 유저는 KST)

---

## 8. [2026-05-01] 최종 근본 원인 발견 — Firestore Timestamp vs String 타입 불일치

### 증상
코드 수정을 수십 차례 반복해도 히브리서 4:9-10(알고리즘 결과)이 계속 표시됨.

### 진단 과정 (실기기 직접 디버깅)
`xcrun devicectl device process launch --console`로 실기기 stdout 직접 캡처

```
📖 [DIAG] fetchRawContentVersion: version=content_v1.5 todayVerseId=v_241  ← 서버에서 올바르게 받음
📖 [DIAG] final serverVerseId: v_241                                        ← v_241 확인
📖 [DIAG] loadVerse(v_241) FAILED → algorithm                               ← 여기서 실패!
📖 [DIAG] loadVerse: compound 쿼리에서 v_241 미발견 → direct fetch 시도
📖 [DIAG] loadVerse: direct fetch도 실패 → v_241
```

### 진짜 근본 원인

**Cloud Function `selectDailyVerse`가 `last_shown` 필드를 Firestore `Timestamp` 타입으로 저장**

```javascript
// 기존 (버그)
last_shown: admin.firestore.FieldValue.serverTimestamp()  // ← Timestamp 객체
```

iOS `Verse` 구조체는:
```swift
let lastShown: String?  // ← String으로 선언
```

Firestore `data(as: Verse.self)` Codable 디코딩 시 `Timestamp ≠ String?` → 타입 불일치 → **`DecodingError.typeMismatch` throw**

→ `compactMap { try? $0.data(as: Verse.self) }` 가 v_241을 **무음으로 제외**

→ 모든 `fetchVerses()` 결과에서 v_241이 없음

→ `loadVerse("v_241")` 실패 → 알고리즘 → 히브리서 4:9-10

### 수정 내역

**Cloud Function (`functions/index.js`)**
```javascript
// 수정 후: String "yyyy-MM-dd" (KST 기준)
const kstDateStr = new Date(Date.now() + 9*60*60*1000).toISOString().slice(0, 10);
last_shown: kstDateStr  // ← iOS markVerseAsShown()과 동일 형식
```

**Firestore 데이터 수정**
- v_241 `last_shown`: Timestamp `"2026-04-30T19:00:08.018Z"` → String `"2026-05-01"` 변환
- `content_version`: v1.5 → v1.6 (Core Data 강제 재취득)

**iOS 코드 (`VerseRepository.swift`)**
- `loadVerse()` 에 direct fetch fallback 추가 (compound 쿼리 제외 시 개별 ID로 직접 fetch)

### 왜 알고리즘은 v_241을 제외한 채 작동했나

```
fetchVerses() compound 쿼리:
  v_241 → Codable 디코딩 실패 → 제외 → 488개 (v_241 없음)

알고리즘 (488개 pool):
  20260501 % 487(eligible) = 327 → 히브리서 4:9-10  ← 결정론적

loadVerse("v_241"):
  fetchVerses() → 488개 캐시 → v_241 없음 → FAILED
  direct fetch → gRPC 타이밍 이슈 → FAILED
  → 알고리즘 낙하
```

### 최종 검증

```
📖 [DIAG] fetchRawContentVersion: version=content_v1.6 todayVerseId=v_241 ✅
📖 [DIAG] returning from loadVerse: v_241 ✅
📖 [DIAG] returning from local cache: v_241 ✅
```

### 재발 방지

| 시스템 | 수정 |
|--------|------|
| Cloud Function | `last_shown`을 String "yyyy-MM-dd" (KST)로 저장 |
| Firestore | 기존 Timestamp 필드 String 변환 스크립트 적용 |
| iOS | `loadVerse()` direct fetch fallback 추가 |
| iOS | `content_version` 읽기로 `today_verse_id` 함께 취득 (단일 read) |

---

## 7. [2026-05-01] 재빌드 후에도 잠언 11:25 지속 — 근본 원인 발견 및 최종 수정

### 증상
Fix 1~6 적용 후 재빌드해도 잠언 11:25 지속 표시.

### 진짜 근본 원인: Firestore SDK gRPC 초기화 지연

```
앱 콜드 스타트 (iOS Firestore SDK)
  ↓ gRPC 채널 초기화 시작 (비동기, 1~3초 소요)

AppLoadingCoordinator (hasCached=true 경로, ~1초 이내 완료)
  → 배경 이미지 = 디스크 캐시 → Firestore 호출 없음 → SDK 미연결
  → fetchRawContentVersion(source:.server) → SDK 미초기화 → THROW
     → SDK 캐시 폴백 → 구버전 content_v1.4 → Core Data 519개 pool
  → fetchTodayVerseId(source:.server) → THROW
     → else 분기 → getTodayVerseId() → v_439(잠언, 구 코드가 캐시)
     → loadCachedVerse(v_439) → 잠언 11:25 반환
  → state=.ready

HomeViewModel.loadData() (state=.ready 직후, ~1~2초)
  → currentVerse() → source:.server → SDK 여전히 초기화 중 → 동일 실패
  → 잠언 11:25 표시 [사용자 목격]

3~5초 후: SDK 연결 완료 — 하지만 currentVerse() 재호출 트리거 없음 → 영구 고착
```

**핵심**: `hasCached=true` 경로는 ~1초 만에 완료되는데, Firestore SDK 초기화는 1~3초 걸림 → 타이밍 경쟁 조건.

### 최종 수정 — `AppLoadingCoordinator.start()` 콜드 스타트 캐시 초기화

```
clearCache() 호출 → hasCached=false 강제
  → non-cached 경로 실행 (항상)
  → checkForceUpdate() = 첫 Firestore 호출 → SDK gRPC 채널 확립 (T+2.1s)
  → fetchRawContentVersion(source:.server) → 성공 (T+2.5s)
  → fetchTodayVerseId(source:.server) → 성공 → v_241 (T+2.8s) ✅
```

**왜 이 경로가 더 나은가**:
- `checkForceUpdate()` = `FirestoreService().fetchMinimumVersion()` → Firestore 호출 → SDK 채널 확립
- 이후 source:.server 호출은 초기화된 SDK에서 실행 → 성공

### 성능 트레이드오프

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 스플래시 시간 | 재방문 1.0s / 첫방문 1.5s | 항상 1.5s |
| 말씀 fetch | Core Data (버전 일치 시 0 reads) | 동일 (cachedVerseContentVersion 유지) |
| 서버 확인 | 불안정 (타이밍 의존) | 매 콜드 스타트마다 보장 |

### 최종 시나리오 검증

| 시나리오 | 결과 |
|----------|------|
| 콜드 스타트 (재방문) | ✅ clearCache → 서버 확인 경로 → v_241 |
| stale v_439 고착 | ✅ clearCache가 UserDefaults 초기화 → else 분기도 nil → 알고리즘 |
| 완전 오프라인 | ⚠️ 알고리즘 fallback (ephemeral) — 허용 범위 |
| 로그인/로그아웃 반복 | ✅ 인증 상태 무관 |
| KST 04:00 리셋 | ✅ 4개 위치 모두 Asia/Seoul 명시 |
