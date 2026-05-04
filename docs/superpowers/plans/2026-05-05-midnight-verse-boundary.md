# Midnight Verse Boundary Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 말씀 업데이트 기준 시각을 04:00 KST → 자정(00:00 KST)으로 통일하고, 관리자 검토 워크플로우를 전날 22:00으로 선행하도록 조정한다.

**Architecture:**
- Cloud Functions 스케줄 2개 변경 (cron 표현식)
- iOS 클라이언트 3개 파일의 `hour < 4` 오프셋 로직 제거
- Apps Script 자동 트리거 시각 변경 (01:30 → 22:30 KST)
- 주석 및 CLAUDE.md 문서 동기화

**Tech Stack:** Firebase Cloud Functions v2 (Node.js 20), Swift/SwiftUI (iOS 16+), Google Apps Script

---

## 변경 대상 파일 전체 목록

| 파일 | 변경 유형 |
|------|-----------|
| `functions/index.js` | cron 스케줄 2개 + 주석 |
| `DailyVerse/DailyVerse/Core/Models/DailyVerseCache.swift` | `isValid()` 로직 + 주석 |
| `DailyVerse/DailyVerse/Core/Managers/DailyCacheManager.swift` | `isSameDay()` 로직 + 주석 |
| `DailyVerse/DailyVerse/Core/Services/VerseSelector.swift` | `dailySeedIndex()` 로직 + 주석 |
| `DailyVerse/DailyVerse/Core/Repositories/VerseRepository.swift` | 주석만 |
| `DailyVerse/DailyVerse/Core/Services/FirestoreService.swift` | 주석만 |
| `scripts/setup_verse_preview.js` | Apps Script 트리거 시각 + 주석 |
| `CLAUDE.md` | 스케줄 설명, 워크플로우 다이어그램 |

---

## 변경 전후 비교 — 워크플로우

```
[변경 전]
21:00                 01:00              01:30          04:00
  |                     |                  |              |
  |              previewDailyVerses  AppsScript갱신  selectDailyVerse
  |              (D/D+1/D+2 준비)   (시트 업데이트)  (오늘 말씀 확정)
  |
관리자 검토 불가               ←─── 검토 2.5h ──→

[변경 후]
22:00              22:30          23:59  00:00
  |                  |              |     |
previewDailyVerses  AppsScript갱신  |  selectDailyVerse
(D/D+1/D+2 준비)  (시트 업데이트)  |  (오늘 말씀 확정)
  |                              관리자 검토 ~1.5h
```

---

## 충돌·위험 사항 사전 검토

### ✅ 안전한 것들

1. **`kstDateOffset()` 함수 (functions/index.js)** — 변경 불필요.
   - `new Date() + 9시간`으로 KST 날짜를 계산. 00:00 KST에도 정확히 "오늘" 반환.
   - `selectDailyVerse`가 00:00 KST에 실행되면 `dateStr = "YYYY-MM-DD"` (오늘) → `verse_schedule/{오늘}`을 조회하는데, 이 문서는 전날 22:00 previewDailyVerses가 D+1로 이미 준비해둔 것. 정상.

2. **`selectDailyVerse` Step 8 — `runPreview()` 내부 호출** — 변경 불필요.
   - 말씀 확정 후 D+1/D+2 미리보기를 갱신하는 로직. 자정 실행에도 동일하게 작동.

3. **`daily_cards` 충돌 해소** — 이번 변경의 핵심 목적.
   - `daily_cards/{YYYY-MM-DD}` 는 자정에 "오늘"이 됨.
   - 변경 후 `selectDailyVerse`도 자정에 실행 → 날짜 경계 일치.

4. **iOS 캐시 마이그레이션 불필요** — `cacheKey = "dailyVerseCache_v6"` 유지.
   - 기존 캐시의 `date` 필드는 저장 시각(Date()). 새 `isValid()` 로직이 자정 기준으로 캐시 유효성을 재계산.
   - 전환 즉시 올바른 동작 보장.

### ⚠️ 주의 사항

1. **Apps Script 트리거** — `setup_verse_preview.js`의 APPS_SCRIPT_CODE 문자열 안에 있음.
   - 이 스크립트를 재실행해도 **기존에 설치된 Google Apps Script 트리거는 자동 업데이트되지 않음**.
   - 수동 조치 필요: Google Sheets → 확장 프로그램 → Apps Script → `setupTimeTrigger()` 재실행.
   - 플랜 마지막 태스크에 수동 조치 안내 포함.

2. **Firebase Functions 배포** — 코드 수정 후 반드시 `firebase deploy --only functions` 실행.
   - 배포 전까지 기존 04:00 스케줄이 유지됨.

3. **배포 순서** — Functions 먼저, iOS 앱 나중.
   - Server 먼저 자정 기준으로 변경 → 그 다음 iOS 캐시 경계 변경.
   - 반대 순서면 iOS가 자정에 캐시 무효화하지만 server는 04:00까지 old verse를 제공 → 빈 화면 가능성.

4. **절기 테스트** — `daily_cards/{오늘}` 조회와 `verse_schedule/{오늘}` 조회가 이제 동일 날짜 기준. 절기 당일 자정에 정상 동작하는지 확인 필요.

---

## Task 1: Cloud Functions — 스케줄 변경

**Files:**
- Modify: `functions/index.js:1-10` (파일 상단 주석)
- Modify: `functions/index.js:138-151` (previewDailyVerses)
- Modify: `functions/index.js:281-288` (selectDailyVerse)

- [ ] **Step 1: `previewDailyVerses` cron 수정**

`functions/index.js:139` 변경:
```js
// 변경 전
schedule:  '0 1 * * *',

// 변경 후
schedule:  '0 22 * * *',
```

- [ ] **Step 2: `selectDailyVerse` cron 수정**

`functions/index.js:283` 변경:
```js
// 변경 전
schedule:  '0 4 * * *',

// 변경 후
schedule:  '0 0 * * *',
```

- [ ] **Step 3: 파일 상단 주석 업데이트**

`functions/index.js:1-12` 변경:
```js
/**
 * morning manna — Firebase Cloud Functions
 *
 * [1] previewDailyVerses  (22:00 KST — 전날 저녁)
 *     D / D+1 / D+2 말씀을 미리 선정하고 Firestore verse_schedule/{date}에 기록.
 *     → 관리자가 Google Sheets VERSE_PREVIEW 탭에서 확인·수정 가능 (22:30~23:59, 약 1.5h).
 *
 * [2] selectDailyVerse    (00:00 KST — 자정)
 *     오늘의 말씀을 확정해 app_config/today_verse에 기록.
 *     verse_schedule/{today}가 있으면 그 verse를 사용(관리자 선정 우선).
 *     없으면 알고리즘으로 자동 선택.
 *
 * [3] getVerseSchedule    (HTTP GET)
 *     D/D+1/D+2 스케줄 데이터를 JSON으로 반환.
 *     Google Sheets Apps Script가 이 엔드포인트를 호출해 시트를 업데이트.
 *
 * [4] applyVerseOverrides (HTTP POST)
 *     Google Sheets "적용하기" 버튼이 호출.
 *     관리자가 선택한 override를 verse_schedule에 저장.
 */
```

- [ ] **Step 4: 검증 — cron 표현식 확인**

```
'0 22 * * *' with timeZone: 'Asia/Seoul'
= 매일 22:00 KST = 매일 13:00 UTC

'0 0 * * *' with timeZone: 'Asia/Seoul'
= 매일 00:00 KST = 매일 15:00 UTC (전날)
```

확인 방법: [crontab.guru](https://crontab.guru)에서 `0 22 * * *`, `0 0 * * *` 검증.

- [ ] **Step 5: Firebase Functions 배포**

```bash
cd /Users/jeongyong/workspace/dailyverse/functions
firebase deploy --only functions
```

배포 완료 메시지 확인:
```
✔  functions[previewDailyVerses(asia-northeast3)] Successful
✔  functions[selectDailyVerse(asia-northeast3)] Successful
```

- [ ] **Step 6: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add functions/index.js
git commit -m "feat(functions): change verse update boundary from 04:00 to 00:00 KST

- previewDailyVerses: 01:00 → 22:00 KST (prev evening)
- selectDailyVerse: 04:00 → 00:00 KST (midnight)
- Admin review window: 22:00-23:59 KST (~1.5h)"
```

---

## Task 2: iOS — DailyVerseCache.isValid() 수정

**Files:**
- Modify: `DailyVerse/DailyVerse/Core/Models/DailyVerseCache.swift:37-51`

- [ ] **Step 1: 현재 코드 확인**

```swift
// 현재 (lines 37-51)
// 04:00 KST 기준으로 "오늘"을 판단 (새벽 00–03은 전날 취급)
static func isValid(_ cache: DailyVerseCache) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    let now = Date()
    let hour = calendar.component(.hour, from: now)
    let referenceDate: Date
    if hour < 4 {
        referenceDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
    } else {
        referenceDate = now
    }
    return calendar.isDate(cache.date, inSameDayAs: referenceDate)
}
```

- [ ] **Step 2: 자정 기준으로 변경**

```swift
// 변경 후 (lines 37-46)
// 자정(00:00 KST) 기준으로 "오늘"을 판단 — Cloud Function 00:00 KST 기준과 통일
static func isValid(_ cache: DailyVerseCache) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    return calendar.isDate(cache.date, inSameDayAs: Date())
}
```

- [ ] **Step 3: 파일 상단 주석 업데이트**

`DailyVerseCache.swift:9` 변경:
```swift
// 변경 전
// 하루 1개 verse — 04:00에 확정, 모든 탭에서 공유

// 변경 후
// 하루 1개 verse — 자정(00:00 KST)에 확정, 모든 탭에서 공유
```

- [ ] **Step 4: 커밋**

```bash
git add DailyVerse/DailyVerse/Core/Models/DailyVerseCache.swift
git commit -m "fix(cache): change DailyVerseCache validity boundary from 04:00 to midnight KST"
```

---

## Task 3: iOS — DailyCacheManager.isSameDay() 수정

**Files:**
- Modify: `DailyVerse/DailyVerse/Core/Managers/DailyCacheManager.swift:159-172`

- [ ] **Step 1: 현재 코드 확인**

```swift
// 현재 (lines 159-172)
/// DailyVerseCache.isValid()와 동일한 04:00 KST 기준 "같은 날" 판단
/// - 새벽 00–03 KST은 전날로 취급
private static func isSameDay(_ date: Date, as reference: Date) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    func effectiveDay(_ d: Date) -> Date {
        let hour = calendar.component(.hour, from: d)
        if hour < 4 {
            return calendar.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return d
    }
    return calendar.isDate(effectiveDay(date), inSameDayAs: effectiveDay(reference))
}
```

- [ ] **Step 2: 자정 기준으로 변경**

```swift
// 변경 후 (lines 159-165)
/// 자정(00:00 KST) 기준 "같은 날" 판단 — DailyVerseCache.isValid()와 동일 기준
private static func isSameDay(_ date: Date, as reference: Date) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    return calendar.isDate(date, inSameDayAs: reference)
}
```

- [ ] **Step 3: `loadCachedVerse()` 내부 주석 업데이트**

`DailyCacheManager.swift:111-113` 변경:
```swift
// 변경 전
// TTL: DailyVerseCache.isValid()와 완전히 동일한 04:00 기준 하루
// ★ 이전 isSameDay(cachedAt, Date()) 방식은 cachedAt에도 effectiveDay를 적용해
//   새벽 0~3시에 저장된 캐시를 같은 날 오후에 만료로 잘못 판단하는 버그가 있었다.
//   DailyVerseCache(date: cachedAt)을 임시 생성해 isValid()로 체크하면
//   UserDefaults 캐시와 동일한 기준으로 TTL을 판단한다.

// 변경 후
// TTL: DailyVerseCache.isValid()와 동일한 자정(00:00 KST) 기준 하루
// DailyVerseCache(date: cachedAt)을 임시 생성해 isValid()로 체크 → UserDefaults 캐시와 동일 기준
```

- [ ] **Step 4: `getTodayVerseId()` 주석 업데이트**

`DailyCacheManager.swift:33-34` 변경:
```swift
// 변경 전
/// 오늘의 verse ID 조회 (04:00 기준 일일 고정)

// 변경 후
/// 오늘의 verse ID 조회 (자정 기준 일일 고정)
```

- [ ] **Step 5: 커밋**

```bash
git add DailyVerse/DailyVerse/Core/Managers/DailyCacheManager.swift
git commit -m "fix(cache): simplify isSameDay to midnight KST boundary"
```

---

## Task 4: iOS — VerseSelector.dailySeedIndex() 수정

**Files:**
- Modify: `DailyVerse/DailyVerse/Core/Services/VerseSelector.swift:128-149`

- [ ] **Step 1: 현재 코드 확인**

```swift
// 현재 (lines 128-149)
/// 오늘 날짜(04:00 기준)를 시드로 사용한 결정론적 인덱스 반환
/// - 같은 날이면 count가 같을 때 항상 동일한 인덱스를 반환
/// - 새벽 00–03은 전날로 취급 (DailyVerseCache.isValid와 동일 기준)
private static func dailySeedIndex(count: Int) -> Int {
    guard count > 1 else { return 0 }
    // KST 명시 — Cloud Function의 04:00 KST 기준과 dayInt 통일
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    let now = Date()
    let hour = calendar.component(.hour, from: now)
    let referenceDate: Date
    if hour < 4 {
        referenceDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
    } else {
        referenceDate = now
    }
    // "yyyyMMdd" 형식 숫자를 시드로 사용
    let dayInt = calendar.component(.year, from: referenceDate) * 10000
        + calendar.component(.month, from: referenceDate) * 100
        + calendar.component(.day, from: referenceDate)
    return dayInt % count
}
```

- [ ] **Step 2: 자정 기준으로 변경**

```swift
// 변경 후 (lines 128-143)
/// 오늘 날짜(자정 기준)를 시드로 사용한 결정론적 인덱스 반환
/// - 같은 날이면 count가 같을 때 항상 동일한 인덱스를 반환
/// - KST 명시 — Cloud Function 00:00 KST 기준과 dayInt 통일
private static func dailySeedIndex(count: Int) -> Int {
    guard count > 1 else { return 0 }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    let now = Date()
    // "yyyyMMdd" 형식 숫자를 시드로 사용
    let dayInt = calendar.component(.year, from: now) * 10000
        + calendar.component(.month, from: now) * 100
        + calendar.component(.day, from: now)
    return dayInt % count
}
```

- [ ] **Step 3: 커밋**

```bash
git add DailyVerse/DailyVerse/Core/Services/VerseSelector.swift
git commit -m "fix(selector): remove hour<4 offset from dailySeedIndex — midnight KST boundary"
```

---

## Task 5: iOS — 주석 업데이트 (VerseRepository, FirestoreService)

**Files:**
- Modify: `DailyVerse/DailyVerse/Core/Repositories/VerseRepository.swift` (주석만)
- Modify: `DailyVerse/DailyVerse/Core/Services/FirestoreService.swift` (주석만)

- [ ] **Step 1: VerseRepository 주석 업데이트**

`VerseRepository.swift:104` 변경:
```swift
// 변경 전
/// 오늘의 말씀 — 하루 1회 결정, Zone/유저 무관하게 동일 (04:00 기준)

// 변경 후
/// 오늘의 말씀 — 하루 1회 결정, Zone/유저 무관하게 동일 (자정 기준)
```

- [ ] **Step 2: FirestoreService 주석 업데이트**

`FirestoreService.swift:96` 변경:
```swift
// 변경 전
/// 서버에서 매일 04:00 KST에 결정한 오늘의 verseId 반환

// 변경 후
/// 서버에서 매일 00:00 KST(자정)에 결정한 오늘의 verseId 반환
```

`FirestoreService.swift:363` 변경:
```swift
// 변경 전
// today_verse_id: Cloud Function이 매일 04:00 KST에 content_version과 함께 기록

// 변경 후
// today_verse_id: Cloud Function이 매일 00:00 KST(자정)에 content_version과 함께 기록
```

- [ ] **Step 3: 커밋**

```bash
git add DailyVerse/DailyVerse/Core/Repositories/VerseRepository.swift
git add DailyVerse/DailyVerse/Core/Services/FirestoreService.swift
git commit -m "docs(ios): update 04:00 KST references to midnight in comments"
```

---

## Task 6: Apps Script — 트리거 시각 변경

**Files:**
- Modify: `scripts/setup_verse_preview.js:393-411` (setupTimeTrigger 함수)
- Modify: `scripts/setup_verse_preview.js:241-242` (APPS_SCRIPT_CODE 상단 주석)

- [ ] **Step 1: `setupTimeTrigger` 시각 변경**

`setup_verse_preview.js:393-411` 변경:
```js
// 변경 전
function setupTimeTrigger() {
  // 기존 트리거 삭제
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(t => {
    if (t.getHandlerFunction() === 'refreshVersePreview') {
      ScriptApp.deleteTrigger(t);
    }
  });
  // 새 트리거 등록 (01:30 KST = 16:30 UTC)
  ScriptApp.newTrigger('refreshVersePreview')
    .timeBased()
    .atHour(1)
    .nearMinute(30)
    .everyDays(1)
    .inTimezone('Asia/Seoul')
    .create();
  SpreadsheetApp.getUi().alert('✅ 매일 01:30 KST 자동 갱신 트리거 설정 완료');
}

// 변경 후
function setupTimeTrigger() {
  // 기존 트리거 삭제
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(t => {
    if (t.getHandlerFunction() === 'refreshVersePreview') {
      ScriptApp.deleteTrigger(t);
    }
  });
  // 새 트리거 등록 (22:30 KST = 13:30 UTC)
  // previewDailyVerses(22:00 KST) 완료 후 30분 뒤 시트 갱신
  ScriptApp.newTrigger('refreshVersePreview')
    .timeBased()
    .atHour(22)
    .nearMinute(30)
    .everyDays(1)
    .inTimezone('Asia/Seoul')
    .create();
  SpreadsheetApp.getUi().alert('✅ 매일 22:30 KST 자동 갱신 트리거 설정 완료');
}
```

- [ ] **Step 2: APPS_SCRIPT_CODE 헤더 주석 업데이트**

`setup_verse_preview.js:241-244` 변경:
```js
// 변경 전
// morning manna — VERSE_PREVIEW 관리 스크립트
// Apps Script 편집기에서 실행됩니다.

// 변경 후
// morning manna — VERSE_PREVIEW 관리 스크립트
// Apps Script 편집기에서 실행됩니다.
// 자동 갱신: 매일 22:30 KST (previewDailyVerses 22:00 실행 후 30분)
// 관리자 검토 창: 22:30 ~ 23:59 KST (약 1.5시간)
// selectDailyVerse 확정: 매일 00:00 KST (자정)
```

- [ ] **Step 3: 콘솔 안내 메시지 업데이트**

`setup_verse_preview.js:461` 변경:
```js
// 변경 전
console.log('   5. [🔮 말씀 관리] → setupTimeTrigger 실행 (매일 01:30 자동 갱신 등록)');

// 변경 후
console.log('   5. [🔮 말씀 관리] → setupTimeTrigger 실행 (매일 22:30 자동 갱신 등록)');
```

- [ ] **Step 4: 커밋**

```bash
git add scripts/setup_verse_preview.js
git commit -m "fix(scripts): update Apps Script trigger from 01:30 to 22:30 KST"
```

---

## Task 7: CLAUDE.md 문서 업데이트

**Files:**
- Modify: `CLAUDE.md` — 여러 위치

- [ ] **Step 1: Cloud Functions 스케줄 테이블 업데이트**

CLAUDE.md의 "13-B. Cloud Functions" 테이블 변경:
```markdown
// 변경 전
| `selectDailyVerse` | Scheduled | 매일 **04:00 KST** | ...
| `previewDailyVerses` | Scheduled | 매일 **01:00 KST** | ...

// 변경 후
| `selectDailyVerse` | Scheduled | 매일 **00:00 KST** (자정) | ...
| `previewDailyVerses` | Scheduled | 매일 **22:00 KST** (전날 저녁) | ...
```

- [ ] **Step 2: 관리자 워크플로우 다이어그램 업데이트**

CLAUDE.md의 "관리자 말씀 관리 워크플로우" 코드블록 변경:
```markdown
// 변경 전
매일 01:00 KST → previewDailyVerses 자동 실행
  → verse_schedule/{D}, {D+1}, {D+2} 자동 생성

매일 01:30 KST → Apps Script 자동 실행 (시간 기반 트리거)
  → VERSE_PREVIEW 탭 자동 갱신

관리자 검토 (01:30 ~ 04:00, 약 2.5시간 여유)
  → [선택] 컬럼: 1=auto, 2=alt_1, 3=alt_2, 4=alt_3
  → [🔮 말씀 관리] → [적용하기] 버튼 → override 저장

매일 04:00 KST → selectDailyVerse 자동 실행
  → verse_schedule 확인 → 확정 → app_config/today_verse 기록

// 변경 후
매일 22:00 KST → previewDailyVerses 자동 실행 (전날 저녁)
  → verse_schedule/{D}, {D+1}, {D+2} 자동 생성

매일 22:30 KST → Apps Script 자동 실행 (시간 기반 트리거)
  → VERSE_PREVIEW 탭 자동 갱신

관리자 검토 (22:30 ~ 23:59, 약 1.5시간 여유)
  → [선택] 컬럼: 1=auto, 2=alt_1, 3=alt_2, 4=alt_3
  → [🔮 말씀 관리] → [적용하기] 버튼 → override 저장

매일 00:00 KST → selectDailyVerse 자동 실행 (자정)
  → verse_schedule 확인 → 확정 → app_config/today_verse 기록
```

- [ ] **Step 3: app_config/today_verse 스키마 주석 업데이트**

CLAUDE.md에서 `app_config/today_verse` 설명의 Cloud Function 언급:
```markdown
// 변경 전
> Cloud Function `selectDailyVerse` 가 매일 04:00 KST 자동 업데이트.

// 변경 후
> Cloud Function `selectDailyVerse` 가 매일 00:00 KST(자정) 자동 업데이트.
```

- [ ] **Step 4: Home 탭 모드 시간대 표에서 04:00 관련 내용 확인**

CLAUDE.md Section 5 "모드 시간대" 테이블 — 현재 `아침: 05:00–12:00` 으로 04:00 기준이 없으므로 변경 불필요.

- [ ] **Step 5: "말씀 선택 알고리즘" 섹션 업데이트 (Section 15)**

```markdown
// 변경 전
Cloud Function (selectDailyVerse) — 매일 04:00 KST 자동 실행
...
4. app_config/today_verse 문서에 { verse_id, date, reference, selected_at } 기록

앱 클라이언트:
1. DailyCacheManager.todayVerseId 유효 → 즉시 반환 (Firestore 호출 없음)
...

// 변경 후
Cloud Function (selectDailyVerse) — 매일 00:00 KST(자정) 자동 실행
...
4. app_config/today_verse 문서에 { verse_id, date, reference, selected_at } 기록

앱 클라이언트:
1. DailyCacheManager.todayVerseId 유효 → 즉시 반환 (Firestore 호출 없음)
...
```

또한:
```markdown
// 변경 전
- **04:00 KST 기준**: 00:00~03:59는 전날 말씀, 04:00~23:59는 오늘 말씀

// 변경 후
- **00:00 KST 기준(자정)**: 자정부터 새 말씀 제공, daily_cards 날짜 전환과 일치
```

- [ ] **Step 6: 커밋**

```bash
git add CLAUDE.md
git commit -m "docs(claude): update all 04:00 KST references to midnight boundary"
```

---

## Task 8: 수동 조치 — Google Apps Script 트리거 재설정

> ⚠️ **이 태스크는 자동화 불가. 반드시 수동 실행 필요.**

- [ ] **Step 1: Google Sheets 열기**

[morning manna 콘텐츠 시트](https://docs.google.com/spreadsheets/d/1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig/edit) → 확장 프로그램 → Apps Script 클릭

- [ ] **Step 2: 기존 트리거 삭제**

Apps Script 편집기 좌측 메뉴 → ⏰ 트리거 → `refreshVersePreview` 01:30 트리거 삭제

- [ ] **Step 3: 새 트리거 설정**

방법 A (권장): Apps Script 편집기에서 `setupTimeTrigger` 함수 직접 실행
방법 B: 트리거 메뉴에서 수동으로 22:30 KST 트리거 추가

- [ ] **Step 4: 트리거 확인**

Apps Script 트리거 목록에서 `refreshVersePreview` → 22:30 KST 표시 확인

---

## Task 9: 배포 후 검증

- [ ] **Step 1: Firebase Functions 스케줄 확인**

Firebase Console → Functions → previewDailyVerses 세부 정보 → "Schedule" 란 확인
- 예상: `0 22 * * *` (Asia/Seoul)

Firebase Console → Functions → selectDailyVerse 세부 정보 → "Schedule" 란 확인
- 예상: `0 0 * * *` (Asia/Seoul)

- [ ] **Step 2: `triggerPreview` HTTP 엔드포인트로 수동 실행**

```bash
curl "https://asia-northeast3-dailyverse-9260d.cloudfunctions.net/triggerPreview"
```

예상 응답:
```json
{
  "message": "미리보기 갱신 완료",
  "dates": ["2026-05-05: ...", "2026-05-06: ...", "2026-05-07: ..."]
}
```

- [ ] **Step 3: Firestore 확인**

Firebase Console → Firestore → `verse_schedule` 컬렉션 → 오늘/내일/모레 날짜 문서 존재 확인

- [ ] **Step 4: iOS 빌드 확인**

Xcode에서 빌드 성공 확인 (Swift 컴파일 오류 없음)

- [ ] **Step 5: iOS 자정 경계 수동 테스트**

시뮬레이터 시간을 23:59 KST → 00:01 KST로 변경 후:
- 앱 실행 → 캐시가 무효화되어 새 말씀 fetch 확인
- `DailyVerseCache.isValid()` → false (이전 날 캐시)
- `VerseSelector.dailySeedIndex()` → 새 dayInt 반환

---

## 배포 순서 요약

```
1. functions/index.js 수정 → firebase deploy --only functions  [Task 1]
2. iOS Swift 파일 수정 (Task 2~5) → Xcode 빌드 확인
3. scripts/setup_verse_preview.js 수정  [Task 6]
4. CLAUDE.md 업데이트  [Task 7]
5. Google Apps Script 트리거 수동 재설정  [Task 8]
6. 전체 검증  [Task 9]
```

> **중요**: Firebase Functions 배포는 Task 1에서 즉시 수행. iOS 코드 변경(Task 2~5)은 앱 스토어 배포 주기에 맞춰 별도 진행 가능.
