# morning manna — 변경 이력

> 최종 업데이트: 2026-04-27
> 형식: `[날짜] 버전/태그 — 변경 내용`

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
