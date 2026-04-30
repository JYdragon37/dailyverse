# morning manna — 변경 이력

> 최종 업데이트: 2026-04-30
> 형식: `[날짜] 버전/태그 — 변경 내용`

---

## 2026-04-30 (말씀 버그 수정 + 절기 캘린더 + 스프레드시트 정리)

### 버그 수정 — 잘못된 말씀 표시 (요한삼서 1:2 반복 노출)

**근본 원인**: 3개의 버그가 연쇄 작동
1. **Firestore SDK 오프라인 캐시 반환** — `fetchTodayVerseId()`가 서버 연결 전 어제 캐시 문서를 반환해 날짜 체크 실패 → nil → 알고리즘 폴백
2. **알고리즘 결과 영구 캐시 저장** — 알고리즘이 선택한 잘못된 구절이 UserDefaults에 저장돼 다음 실행에서도 반환
3. **서버 응답 시에도 stale 캐시 반환** — serverVerseId를 받아도 `loadVerse` 실패 시 캐시된 잘못된 구절 반환
4. **`isEligible` ISO 8601 파싱 실패** — Cloud Function이 `"2026-04-29T19:00:03Z"` 형식으로 저장하는 `last_shown`을 `"yyyy-MM-dd"` 포매터로 파싱 실패 → 쿨다운 무시 → eligible pool 오염

**수정 내역**:
- `FirestoreService.fetchTodayVerseId()`: `source: .server` 강제 → Firestore SDK 캐시 우회, 오프라인 시만 캐시 폴백
- `VerseRepository.currentVerse()`: 알고리즘 폴백 결과 `setVerseId()` 제거 (ephemeral)
- `VerseRepository.currentVerse()`: `if/else` 구조로 서버 응답 시 stale 캐시 우회
- `Verse.isEligible`: `ISO8601DateFormatter` 추가 — `"yyyy-MM-dd"` + ISO 8601 두 포맷 모두 처리

**확인된 수학**: `20260430 % 517 = 234` → index 234 = v_259(요한삼서) — 결정론적 버그였음

### 스프레드시트 정리 (Google Sheets)

- **VERSES 중복 30개 inactive 처리**: `verse_short_ko` 완전 동일 쌍 정리 (시편 23:1-2 3중복 등)
- **deprecated 컬럼 4개 삭제**: `contemplation_ko`, `contemplation_reference`, `contemplation_interpretation`, `contemplation_appliance` (schema_v1.3/v1.4 제거 선언됐으나 시트에 잔존)
- **HOME_GREETINGS 중복 39개 삭제**: 배치 생성 시 앞부분 복붙으로 발생한 중복 인사말
- **content_version** `v1.4` → `v1.5` 업데이트 (기기 캐시 강제 갱신)

### Admin Script 정리

- `upload_to_firestore.gs` 삭제 — `admin_apps_script.gs`(v3.1)에 통합
- `admin_apps_script.gs` 버그 수정:
  - VERSE_PREVIEW notes 컬럼 참조 오류 수정 (18열→19열)
  - `buildVerseDocument_()` 타입 처리 개선 (`ARRAY_FIELDS`, `INT_FIELDS`, `BOOL_FIELDS` 상수화)

### 묵상 달력 — 절기 표시 기능

- **달력 별표 탭 시 절기 이름 표시**: 절기일(`★`) 셀 탭 → 날짜 숫자 ↔ 절기명 fade 토글 (고정 높이, 레이아웃 shift 없음)
- **묵상 다이어리 날짜에 절기명 추가**: `"성탄절 · 2026년 12월 25일 목요일"` 형식
- 갤러리 저장 이미지(`DiarySnapshotView`)에도 절기명 반영
- `fetchHolidayDates()` → `fetchHolidayMap()` 변경 — `[String: String]` (날짜→절기명) 반환
- `holidayDates: Set<String>` → `holidayMap: [String: String]`

### 묵상 수정 완료 화면 (`EditCompleteView`)

- 이모지 `✅` → SF Symbol `pencil.and.scribble` (골드, `.light` weight)
- 방사형 glow: `dvAccentSky`(파란색) → `dvAccentGold` (앱 색상 통일)

---

## 2026-04-27 (앱스토어 준비 + UI 수정)

### 앱스토어 준비
- **번들 ID 변경**: `dragonbear.DailyVerse` → `com.morningmanna.app` (위젯: `.widgets`)
- **GoogleService-Info.plist 교체**: 새 번들 ID 기반 Firebase 앱 등록
- **App Store 앱 등록**: Apple ID `6763995142` (morning manna)
- **App Store 리뷰 링크** 교체 (`id0` → `id6763995142`)
- **이용약관/개인정보처리방침** GitHub Pages 생성 (`docs/legal/`)
- **appstore-metadata.md** 작성 (앱 설명, 키워드, 카테고리, 스크린샷 가이드)
- **GitHub Pages** `.nojekyll` 추가로 Jekyll 빌드 오류 수정
- **ATT 팝업**: 앱 시작 → 첫 알람 저장 시점으로 이동, 메시지 개선

### UI/UX 수정
- **홈 화면 레이아웃**: 말씀 시작 위치 `33% top-anchor` 고정 (인사말 길이 무관)
- **홈 말씀 ScrollView**: 긴 말씀(150자+) 스크롤 지원 추가
- **AlarmStage2 레이아웃**: 말씀 시작 `50% top-anchor` + ScrollView + 버튼 노출 보장(110pt)
- **VerseDetailBottomSheet**: `Color.black.opacity(0.7)` 반투명 배경 (iOS 16.4+ presentationBackground)
- **VerseDetailBottomSheet**: `isSaved @Binding` 교체 (비로그인 '저장됨' 즉시 표시 버그 수정)
- **HomeView**: 비로그인 저장 시 시트 닫은 후 0.35초 딜레이 → 로그인 팝업
- **HomeView**: 묵상 탭 전환 시 `showLoginPrompt` 초기화 (팝업 잔류 버그 수정)
- **AlarmListView**: 알람 레이블("아침의 말씀" 등) 제거
- **AlarmListView**: 테마 영어 → 한국어 (`Hope→소망`, `Courage→새 힘` 등 17개)
- **Alarm.swift**: `themeKorean` computed property 추가

### 기술 부채 정리 (Category 11)
- Dead code 4개 삭제: `ImageService.swift`, `SettingsViewModel.swift`, `EmailAuthView.swift`, `TextLimitTestView.swift`
- `isPremium` 광고 조건 5곳 복구
- **마스터 계정 시스템**: `SubscriptionManager.checkMasterAccount()` + Firestore `app_config/master_accounts`
- 레거시 `fetchBackgroundImage` (단수) 제거 → `Legacy_Backup/` 보관

### Firestore 초기화 스크립트
- `scripts/setup_app_config.js`: `minimum_version` + `master_accounts` 문서 생성 완료

---

## 2026-04-27 (1만 유저 스케일링 딥다이브 완료)

### 스케일링 12개 카테고리 완료 (`docs/scaling-10k-users.md`)

| # | 카테고리 | 주요 작업 |
|---|----------|---------|
| 1 | 콘텐츠 | 말씀 품질 14배 개선, zone 편향 버그 수정 |
| 2 | 이미지 | Zone 배경 다중·날씨별 분류, 이미지 폴더 구조 개편 |
| 3 | Firebase | **버전 기반 캐시 v7.0** — reads 99% 절감 ($96→$2~3/월) |
| 4 | 디바이스/iOS | 저전력 모드 경고, 알람 자동 재등록, @available 가드 |
| 5 | 인증/계정 | 이메일 dead code 제거, Google 17012 에러 메시지, 로고 교체 |
| 6 | 알람 시스템 | 저전력 모드 토스트, 버전 변경 시 알람 재등록, 카운트 로그 |
| 7 | 수익화/광고 | AdMob 실제 Unit ID 등록, ATT 팝업, 광고 재시도 로직 |
| 8 | 성능/속도 | 스플래시 딜레이 분기, 이미지 캐시 50MB 한도 + LRU |
| 9 | CS/유저응대 | Analytics 12개 이벤트, Crashlytics 비크래시 에러 기록 |
| 10 | 법적/개인정보 | PrivacyInfo.xcprivacy, SKAdNetwork 30개, 개역한글 출처 |
| 11 | 기술 부채 | dead code 정리, isPremium 복구, 마스터 계정 |
| 12 | 모니터링/운영 | Crashlytics 유저 ID, 강제 업데이트 메커니즘 |

---

## 2026-04-26 (콘텐츠 + 이미지 + Firebase)

### 콘텐츠 품질 개선
- `sync_verses.js` 범위 `A:Z` → `A:AZ` 확장 (question 필드 누락 버그 수정)
- `question` 142개 생성 (`generate_meditation_questions.js`)
- `alarm_top_ko` 155개 생성
- `application` 41개 범용화 (시간대 언급 제거)
- 글자수 기준 현실화: `verse_short_ko` min 10자, `verse_full_ko` max **150자**
- `contents-guideline.md` v9.1: interpretation 3단계, 테마 풀 17개

### 이미지 관리
- `image-assets/` 통합 폴더 구조 (zone-backgrounds / verse-images)
- Zone 배경 `weather` 필드 태깅 (rainy/snowy/misty/cloudy/all)
- snowy 배경 8개 Zone 완성, 감성 이미지 23장 추가
- `upload_design_test.js` 원클릭 업로드 파이프라인

### Firebase 최적화
- `VerseRepository.fetchVerses()` v7.0: 버전 체크(1 read) → Core Data → Firestore
- `DailyCacheManager.loadAllCachedVerses()` 추가
- `FirestoreService.fetchRawContentVersion()` 추가

---

## 2026-04-25 (브랜딩 리뉴얼 + schema_v1.3)

- 앱 이름: **DailyVerse → morning manna** (mm)
- schema_v1.3: `contemplation_ko`, `contemplation_reference` 제거
- `contents-guideline.md` v9.0 통합
- 공통 필드 통일: `contemplation_*` → `interpretation` / `application`

---

## 문서 현황

| 문서 | 역할 |
|------|------|
| `CLAUDE.md` | 앱 전체 스펙 (Single Source of Truth) |
| `docs/human-todo.md` | 출시 전 필수 체크리스트 |
| `docs/field-usage-rules.md` | 화면별 필드 사용 규칙 |
| `docs/scaling-10k-users.md` | 1만 유저 스케일링 딥다이브 |
| `docs/appstore-metadata.md` | 앱스토어 등록 메타데이터 |
| `docs/content-schema.md` | 콘텐츠 스키마 전체 정의 |
| `docs/contents-guideline.md` | 콘텐츠 생성 규칙 + LLM 가이드 |
| `Legacy_Backup/` | 제거된 레거시 코드 원본 |
