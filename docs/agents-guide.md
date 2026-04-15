# DailyVerse 서브 에이전트 가이드

> 이 프로젝트에서 Claude Code가 활용하는 서브 에이전트 목록입니다.
> 각 에이전트는 특정 역할에 특화되어 있으며, 복잡한 작업을 병렬/순차로 처리합니다.
> 마지막 업데이트: 2026-04-12 (v8.0 — 수식 필드 정책, Sheets 직접 편집 권한 추가)

---

## 📌 데이터 소스 직접 접근

| 항목 | 내용 |
|------|------|
| **Google Sheets** | [DailyVerse 콘텐츠 시트](https://docs.google.com/spreadsheets/d/1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig/edit) |
| **편집 권한** | ✅ `scripts/serviceAccountKey.json`으로 Claude Code가 직접 편집 가능 |
| **Sheets ID** | `1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig` |
| **시트 탭** | `VERSES` (v_001~v_180+), `ALARM_VERSES` (av_001~av_105) |

**주요 스크립트**:
```bash
cd /Users/jeongyong/workspace/dailyverse/scripts

node apply_formula_fields.js    # contemplation_* 수식 재적용 (4개 컬럼)
node sync_sheets_to_firestore.js  # Sheets 전체 → Firestore 동기화
node upload_verses.js           # 신규 말씀 업로드
```

---

## 카테고리 구조

```
DailyVerse 에이전트
│
├── 🎨 Category A. 화면 개발 (UI/UX)
│   ├── swiftui-builder       — SwiftUI 뷰 구현
│   ├── design-researcher     — 디자인 레퍼런스 리서치
│   ├── design-engineer       — 디자인 시스템 적용
│   └── design-reviewer       — 디자인 일관성 검증
│
├── 🔧 Category B. iOS 기능 구현
│   ├── ios-architect         — 프로젝트 구조·아키텍처
│   ├── alarm-engineer        — 알람·알림 시스템
│   ├── weather-engineer      — 날씨 서비스 레이어
│   └── subscription-engineer — 결제·광고·업셀
│
├── 🗄️ Category C. 백엔드 & 데이터
│   ├── firebase-engineer     — Firebase 전체 스택
│   └── data-engineer         — 데이터 모델·Core Data·알고리즘
│
├── ✅ Category D. 품질 & 검증
│   ├── qa-engineer           — 테스트·시나리오 검증
│   ├── bkit:gap-detector     — 설계↔구현 갭 분석
│   ├── bkit:code-analyzer    — 코드 품질 분석
│   └── bkit:qa-strategist    — QA 전략 수립
│
├── 📊 Category E. PDCA 관리
│   ├── bkit:pdca-iterator    — 자동 반복 개선
│   ├── bkit:report-generator — 완료 보고서 생성
│   └── bkit:product-manager  — 요구사항 분석·우선순위
│
├── 🔍 Category F. 탐색 & 분석
│   ├── Explore               — 코드베이스 탐색
│   ├── general-purpose       — 리서치·웹 검색
│   └── Plan                  — 구현 계획 설계
│
└── ✍️ Category G. 콘텐츠 제작 (말씀 문구)
    ├── content-writer            — 신규 말씀 콘텐츠 생성 (Claude API 배치, VERSES/ALARM_VERSES/greeting)
    ├── content-checker           — AI 판단 항목 점검 (Zone 맥락·interpretation 구조·번영신학)
    ├── content-fixer             — 수정 사항 Sheets + Firestore 배치 반영
    ├── verse-writer              — interpretation + application 초안 작성
    ├── tone-reviewer             — 말투 기준 점검 (설교체 → 친구체)
    ├── scripture-checker         — 원어 표기 제거 + 성경 배경 팩트체크
    ├── devotion-question-writer  — 묵상 응답 화면용 개인화 질문 생성
    └── content-patcher           — Google Sheets → Firestore 배치 업로드
```

---

## Category A — 화면 개발 (UI/UX)

### `swiftui-builder`
**역할**: 모든 SwiftUI 뷰 구현
**주로 사용**: Sprint 3~6 UI 구현, 화면 수정 요청

**프롬프트 패턴**:
```
DailyVerse iOS 앱의 {뷰 이름}을 구현/수정해주세요.

규칙:
- project.pbxproj 절대 수정 금지 (신규 파일 추가 불가)
- 수정 전 반드시 Read 툴로 현재 내용 확인
- iOS 16+ API만 사용
- 기존 Color+DailyVerse, Font+DailyVerse extension 활용

작업 내용:
{구체적인 변경 사항}

수정 완료 후 변경된 라인과 before/after 요약해주세요.
```

**담당 화면**:
- HomeView, VerseCardView, WeatherWidgetView
- AlarmListView, AlarmAddEditView, AlarmStage1View, AlarmStage2View
- SavedView, SavedDetailView
- SettingsView, OnboardingView 5화면
- UpsellBottomSheet, LoginPromptSheet, ToastView

---

### `design-researcher`
**역할**: 타 앱 UI/UX 패턴 리서치
**주로 사용**: 새 화면 설계 전, 경쟁앱 벤치마킹

**프롬프트 패턴**:
```
DailyVerse iOS 앱의 {기능명} 화면 설계를 위한 레퍼런스를 조사해주세요.

조사 대상 앱: {앱 목록 — Calm, Headspace, YouVersion, Apple Weather 등}
조사 항목:
- UI 패턴 (레이아웃, 컴포넌트 구조)
- 색상 팔레트 및 타이포그래피
- 인터랙션·애니메이션 방식
- 권고 문구 톤앤매너

DailyVerse 감성(청록→보라 그라데이션, 골드 강조, 경건한 분위기)과
어울리는 방향을 제안해주세요.
```

---

### `design-engineer`
**역할**: 디자인 리서치 결과를 코드로 적용
**주로 사용**: `design-researcher` 완료 후 실제 구현

**프롬프트 패턴**:
```
design-researcher의 리서치 결과를 바탕으로 DailyVerse의 {화면명}을
아래 디자인 방향으로 업데이트해주세요.

적용 파일:
- Color+DailyVerse.swift
- Font+DailyVerse.swift
- Animation+DailyVerse.swift
- {해당 View 파일}

디자인 방향:
{design-researcher 결과 요약}

project.pbxproj 수정 금지. 기존 파일만 수정합니다.
```

---

### `design-reviewer`
**역할**: 구현된 화면의 디자인 일관성 검증
**주로 사용**: 화면 구현 완료 후 QA 전

**프롬프트 패턴**:
```
DailyVerse의 아래 화면들의 디자인 일관성을 검증해주세요.

검증 항목:
- 색상 대비 비율 (WCAG AA: 4.5:1 이상)
- 폰트 계층 일관성 (dvLargeTitle > dvTitle > dvBody > dvCaption)
- 애니메이션 통일성 (easeInOut 기준)
- 다크 모드 지원 여부
- 간격 리듬 (8pt grid 기준)
- 코너 라디우스 일관성

검증 화면: {파일 경로 목록}

불일치 항목은 파일:라인 형태로 명시하고 수정 방법을 제시해주세요.
```

---

## Category B — iOS 기능 구현

### `ios-architect`
**역할**: Xcode 프로젝트 구조·아키텍처·SPM 패키지
**주로 사용**: Sprint 1 프로젝트 초기 설정, 아키텍처 결정

**프롬프트 패턴**:
```
DailyVerse iOS 프로젝트의 {작업명}을 처리해주세요.

프로젝트 정보:
- 플랫폼: iOS 16+, Swift 5.9
- 아키텍처: MVVM + Clean Architecture
- 패키지: Firebase, RevenueCat, GoogleMobileAds

작업 내용:
{구체적인 아키텍처/설정 작업}

project.pbxproj 수정이 필요한 경우:
반드시 Python 스크립트 방식으로 처리하고,
괄호 균형 검증 후 파일 저장하세요.
(규칙: docs/pbxproj-rules.md 참고)
```

---

### `alarm-engineer`
**역할**: UNUserNotificationCenter, 알람 UX 3단계, 스누즈 로직
**주로 사용**: Sprint 4 알람 시스템

**프롬프트 패턴**:
```
DailyVerse의 알람 시스템 관련 작업입니다.

알람 아키텍처:
- NotificationManager: 스케줄링·취소·재스케줄
- AlarmCoordinator: Stage 전환 상태 관리
- AlarmRepository: Core Data CRUD
- 3단계 UX: Stage0(잠금화면) → Stage1(전체화면) → Stage2(웰컴)

작업 내용:
{구체적인 알람 작업}

주요 엣지케이스 9가지 처리 필수:
- 오프라인, 스누즈 강제종료, 복수 알람 동시 발동 등
```

**⚠️ 중요 변경 (v7.0)**:
- `AlarmStage1View`, `AlarmStage2View`는 이제 `verses` 컬렉션 Daily Sync를 사용
- `alarm_verses` 컬렉션은 알람 탭 오늘의 말씀 카드(`alarm_top_ko`, Random Access)에만 사용
- Stage1: Group B → `verses`의 `verse_short_ko` 사용
- Stage2: Group A → `verses`의 `verse_full_ko` 사용
- 오프라인 폴백: `fallbackVerses` 유지

---

### `weather-engineer`
**역할**: WeatherKit + OpenWeatherMap 폴백 + 30분 캐시
**주로 사용**: Sprint 2 날씨 서비스, 날씨 UI 수정

**프롬프트 패턴**:
```
DailyVerse의 날씨 서비스 관련 작업입니다.

날씨 레이어 구조:
- WeatherService: WeatherKit(1차) → OWM(폴백)
- WeatherCacheManager: Core Data 30분 캐시, 스키마 버전 관리
- WeatherData: 현재날씨·시간별·7일예보·UV·미세먼지(에어코리아/OWM)
- WeatherWidgetView: 홈 미니 위젯
- WeatherDetailSheet: HomeView 내 상세 시트

작업 내용:
{구체적인 날씨 작업}

캐시 스키마 변경 시: schemaVersion 버전업 필수 (현재 v7)
OWM One Call 3.0은 유료 — 폴백 시 uvIndex nil 처리 정상
```

---

### `subscription-engineer`
**역할**: StoreKit 2, RevenueCat, AdMob Rewarded, 업셀 트리거
**주로 사용**: Sprint 5 수익화

**프롬프트 패턴**:
```
DailyVerse의 수익화 레이어 관련 작업입니다.

수익화 구조:
- SubscriptionManager: RevenueCat SDK, 엔타이틀먼트 체크
- AdManager: AdMob Rewarded 광고
- UpsellManager: 트리거 5종 × 24시간/세션 2회 노출 제한
- 단일 플랜: 모든 유저 전체 무제한 (v5.1 이후)

작업 내용:
{구체적인 수익화 작업}

업셀 트리거 5가지:
[다음 말씀] / [저장] / [저장탭 7~30일] / [저장탭 30일+] / [테마 선택]
```

---

## Category C — 백엔드 & 데이터

### `firebase-engineer`
**역할**: Firestore CRUD, Firebase Auth, Storage, Analytics
**주로 사용**: Sprint 1~2 Firebase 연동, 데이터 스키마 변경

**프롬프트 패턴**:
```
DailyVerse Firebase 관련 작업입니다.

Firebase 구조:
- Firestore: verses/{id}, images/{id}, users/{uid},
             saved_verses/{uid}/verses/{saved_id}
- Auth: Apple Sign-In 전용 (+ Google Sign-In)
- Storage: 감성 이미지 CDN
- pendingSave: 비로그인 저장 → 로그인 후 자동 복구

작업 내용:
{구체적인 Firebase 작업}

Apple Sign-In 실패 케이스 5가지 처리 필수.
계정 탈퇴 4단계 플로우 (Apple 재인증 → Firestore 삭제 → RevenueCat logOut → 초기화)
```

---

### `data-engineer`
**역할**: Swift 데이터 모델, Core Data, 말씀 선택 알고리즘, 캐시
**주로 사용**: Sprint 1~2 데이터 레이어, 알고리즘 수정

**프롬프트 패턴**:
```
DailyVerse 데이터 레이어 관련 작업입니다.

핵심 모델: Verse, VerseImage, Alarm, User, SavedVerse,
           DailyVerseCache, WeatherData, MeditationEntry

말씀 선택 알고리즘 (VerseSelector):
- 모드 필터 → status=active & curated=true
- 스코어: 테마(+3) · 분위기(+2) · 날씨(+2) · 계절(+1) · 톤(+2)
- 최고점 중 랜덤 선택

DailyCacheManager: 05:00 기준 일별 말씀 고정, Core Data 저장

작업 내용:
{구체적인 데이터 레이어 작업}
```

---

## Category D — 품질 & 검증

### `qa-engineer`
**역할**: XCTest, 시나리오 테스트, App Store 체크리스트
**주로 사용**: 각 Sprint 완료 후 검증

**프롬프트 패턴**:
```
DailyVerse Sprint {N} 완료 후 검증을 수행해주세요.

검증 범위:
{테스트할 기능 목록}

필수 검증 항목:
- 알람 엣지케이스 9가지 (오프라인/스누즈/복수알람 등)
- 구독/광고 플로우 (Free→업셀→광고→열람→Premium)
- 오프라인 3가지 시나리오
- 온보딩 완료/스킵/재개

결과를 테스트 리포트 형태로 정리해주세요.
```

---

### `bkit:gap-detector`
**역할**: 설계 문서↔실제 구현 갭 분석
**주로 사용**: 구현 완료 후 설계 적합성 검증

**프롬프트 패턴**:
```
[bkit gap-detector 자동 실행]
/pdca analyze {feature} 명령으로 자동 호출됩니다.
설계 문서(docs/02-design/)와 구현 코드를 비교하여
Match Rate를 계산하고 갭 리스트를 생성합니다.
```

---

### `bkit:code-analyzer`
**역할**: 코드 품질·보안·아키텍처 준수 분석
**주로 사용**: PR 전, 코드 리뷰 요청 시

**프롬프트 패턴**:
```
[bkit code-analyzer 자동 실행]
"코드 분석해줘", "품질 검사" 키워드로 자동 트리거됩니다.
OWASP Top 10, 아키텍처 일관성, 성능 이슈를 분석합니다.
```

---

### `bkit:qa-strategist`
**역할**: QA 전략 수립, 테스트 계획 작성
**주로 사용**: 복잡한 기능의 체계적 QA 계획이 필요할 때

**프롬프트 패턴**:
```
[bkit qa-strategist 자동 실행]
"테스트 전략", "QA 계획" 키워드로 자동 트리거됩니다.
```

---

## Category E — PDCA 관리

### `bkit:pdca-iterator`
**역할**: Match Rate < 90% 시 자동 반복 코드 수정
**주로 사용**: /pdca iterate 명령 또는 갭 분석 후 자동 수정

**프롬프트 패턴**:
```
[bkit pdca-iterator 자동 실행]
/pdca iterate {feature} 명령으로 자동 호출됩니다.
gap-detector 결과를 기반으로 최대 5회 반복 수정하며,
Match Rate ≥ 90% 달성 시 자동 종료합니다.
```

---

### `bkit:report-generator`
**역할**: PDCA 사이클 완료 보고서 생성
**주로 사용**: /pdca report 명령

**프롬프트 패턴**:
```
[bkit report-generator 자동 실행]
/pdca report {feature} 명령으로 자동 호출됩니다.
PRD → Plan → Design → 구현 → 분석 전 과정을
Executive Summary 형태로 정리합니다.
```

---

### `bkit:product-manager`
**역할**: 요구사항 분석, 기능 우선순위, 사용자 스토리 작성
**주로 사용**: 새 기능 정의 단계

**프롬프트 패턴**:
```
[bkit product-manager 자동 실행]
"요구사항", "기능 정의", "우선순위" 키워드로 자동 트리거됩니다.
PRD 형태로 요구사항을 구조화합니다.
```

---

## Category F — 탐색 & 분석

### `Explore`
**역할**: 코드베이스 빠른 탐색, 키워드/패턴 검색
**주로 사용**: 특정 코드 위치 파악이 필요할 때

**프롬프트 패턴**:
```
DailyVerse 앱에서 {키워드/기능}와 관련된 코드를 탐색해주세요.

탐색 범위: /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/
찾아야 할 것: {구체적인 탐색 목표}

파일 경로, 라인 번호, 코드 내용을 정리해서 보고해주세요.
코드 수정은 하지 말고 탐색/분석만 수행하세요.
```

---

### `general-purpose`
**역할**: 웹 리서치, 복잡한 멀티스텝 분석
**주로 사용**: 외부 정보 조사 (날씨 API, 앱 UX 벤치마킹 등)

**프롬프트 패턴**:
```
{조사 주제}에 대해 리서치해주세요.

DailyVerse 컨텍스트:
- iOS 크리스천 알람 앱
- 감성 이미지 + 성경 말씀 + 날씨 결합
- 배려하는 친구의 말투, 청록→보라 그라데이션 감성

조사 항목:
{구체적인 조사 내용}

DailyVerse에 적합한 방향으로 정리해주세요.
```

---

### `Plan`
**역할**: 구현 전략 설계, 아키텍처 트레이드오프 분석
**주로 사용**: 복잡한 기능 구현 전 설계 단계

**프롬프트 패턴**:
```
[bkit Plan 에이전트]
/pdca plan {feature} 또는 /plan-plus {feature} 명령으로 활용됩니다.
요구사항 확인 → 설계 옵션 3가지 생성 → 선택 → Plan 문서 작성
```

---

---

## Category G — 콘텐츠 제작 (말씀 문구)

> 말씀 해석·일상 적용 문구를 작성하고 DailyVerse 톤에 맞게 다듬는 파이프라인입니다.
>
> **콘텐츠 QA 파이프라인**: 생성(content-writer) → 자동검증(check_content_quality.js) → AI검증(content-checker) → 수정(content-fixer)
>
> 📖 **상세 규칙·LLM 프롬프트**: [`docs/contents-guideline.md`](./contents-guideline.md) §4~§6
> - §4: 콘텐츠 생성 파이프라인 (Zone 기준표 + 생성 흐름)
> - §5: Verse 필드 규격 + 통합 생성 프롬프트 + 검수 체크리스트
> - §6: Alarm Verse 필드 규격 + 알람 심리 + 생성 프롬프트

---

### `content-writer` (Claude Code 에이전트)
**역할**: 신규 말씀 콘텐츠 생성 — VERSES, ALARM_VERSES, greeting 탭 지원
**주로 사용**: 새 말씀 배치 추가, Zone별 콘텐츠 보충, question 일괄 생성

> 📖 **생성 프롬프트**: `docs/contents-guideline.md` §5-4 (통합 생성 프롬프트)

**핵심 규칙**:
- `verse_full_ko`를 **먼저** 확정 → 나머지 필드 파생
- Zone 유저 상황 반영 필수 (`ZONE_GUIDE` Firestore/Sheets 참고)
- 개역한글 원문 사용 시: `scripts/update_to_korv.js` 활용

**관련 스크립트**: `generate_question_new.js`, `update_to_korv.js`

---

### `content-checker` (Claude Code 에이전트)
**역할**: AI 판단 항목 점검 — `check_content_quality.js`로 잡기 어려운 주관적 품질 검증
**주로 사용**: 배치 생성 후 QA, 기존 콘텐츠 정기 점검

**검증 항목**:
- Zone 맥락 정합성 (application이 해당 시간대 유저 상황에 맞는지)
- interpretation 3단계 구조 완성도 (①저자상황 → ②핵심의미 → ③오늘연결)
- 번영신학 위험 표현 감지
- question 신앙 점검 형태 여부

**프롬프트 패턴**:
```
DailyVerse verses/ 컬렉션의 {필드명} 필드를 아래 v9.0 가이드라인으로 점검해줘.
serviceAccountKey 경로: /Users/jeongyong/workspace/dailyverse/scripts/serviceAccountKey.json

[검수 기준]
(docs/contents-guideline.md §5-5 콘텐츠 검수 체크리스트 내용)

출력: 수정 필요 항목만 상세히 (verse_id, 기존 텍스트, 문제, 수정안)
코드 수정은 하지 말고 점검 + 수정안 제안만.
```

**산출물**: 수정 필요 항목 목록 → `content-fixer`에 전달

---

### `content-fixer` (Claude Code 에이전트)
**역할**: `content-checker` 또는 `check_content_quality.js` 결과를 받아 실제 수정 수행
**주로 사용**: AI 검증 완료 후 Firestore + Sheets 반영

**처리 방식**:
1. 수정 목록을 Node.js 패치 스크립트로 작성
2. Firestore `verses/` 컬렉션 업데이트
3. Google Sheets `VERSES` 탭 해당 컬럼 업데이트
4. 완료 후 verse_id 목록 출력

**프롬프트 패턴**:
```
아래 수정 목록을 Firestore verses/ + Google Sheets VERSES 탭에 반영해줘.

serviceAccountKey 경로: /Users/jeongyong/workspace/dailyverse/scripts/serviceAccountKey.json
Sheets ID: 1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig

수정 목록 ({필드명}만 업데이트):
v_xxx: "수정된 텍스트"
v_yyy: "수정된 텍스트"
...
```

**스크립트 경로**: `/Users/jeongyong/workspace/dailyverse/scripts/`

---

### `verse-writer` (general-purpose 활용)
**역할**: 성경 구절의 전체 텍스트 필드 초안 작성
**주로 사용**: 새 말씀 배치 추가, 기존 문구 전면 재작성

> 📖 **상세 규칙·프롬프트**: `docs/contents-guideline.md` §5-4 "신규 Verse 통합 생성 프롬프트"

**빠른 참고**:
- 생성 순서: `verse_full_ko` → `verse_short_ko` → `interpretation` + `application` → `alarm_top_ko`
- 원어(히브리어·헬라어) 직접 표기 절대 금지
- `application`은 대상 Zone의 시간대 상황 직접 반영 필수
- `contemplation_*` 필드는 수식 자동 참조 — 별도 작성 불필요

**산출물**: Google Sheets `interpretation`, `application` 컬럼에 입력할 텍스트

---

### `tone-reviewer` (general-purpose 활용)
**역할**: 작성된 문구의 말투가 DailyVerse 기준에 맞는지 점검·수정
**주로 사용**: 새 문구 배치 전 QA (`fix_tone_v1~v3.js` 패턴)

> 📖 **상세 규칙**: `docs/contents-guideline.md` §5-5 "콘텐츠 검수 체크리스트"

| 허용 | 금지 |
|------|------|
| ~야, ~이야, ~거야, ~있어, ~봐, ~해도 돼 | ~이다, ~합니다, ~입니다, 반드시 ~해야 |
| 배경 서사 + 현재 연결 | 설교체 독백, 히브리어·헬라어 직접 표기 |

**산출물**: 수정 필요 항목 목록 → `fix_tone_v{N}.js` 스크립트로 반영

---

### `scripture-checker` (general-purpose 활용)
**역할**: 원어 표기 제거 + 성경 역사적 배경 팩트체크
**주로 사용**: 초안 작성 후 원어 표기 여부 스캔

> 📖 **금지 패턴**: `docs/contents-guideline.md` §5-5 "원어 표기 감지 패턴"

**산출물**: 패치 대상 리스트 → `patch_alarm_interpretations.js` 형태로 Firebase 반영

---

### `devotion-question-writer` (general-purpose 활용)
**역할**: 특정 말씀에 대한 묵상 응답 화면용 개인화 질문 생성
**주로 사용**: 새 verse 배치 추가 시, 또는 question 일괄 생성 시

> 📖 **상세 규칙·프롬프트**: `docs/contents-guideline.md` §5-1 "`question` 필드"

**핵심 규칙**:
- `question` 필드는 동일 구절 `verse_full_ko`/`contemplation_ko`와 맥락 연결 필수
- 필드명: `question` (구버전 `devotion_question` 사용 금지)
- Group Q (Unique): 독립 관리, 다른 필드와 Sync 없음

**산출물**: `question` 필드값 → `generate_devotion_questions.js` 스크립트로 Firebase 반영

---

### `content-patcher` (Node.js 스크립트)
**역할**: 검수 완료된 문구를 Google Sheets 또는 Firestore에 배치 업로드
**주로 사용**: 문구 수정 완료 후 실제 반영

**업로드 시 Sync Group 인식**:
- Group A 필드: `verse_full_ko`, `reference` → 홈/알람S2/말씀들/묵상S2
- Group B 필드: `verse_short_ko`, `contemplation_ko` → 알람S1/묵상홈/묵상S2읽기
- Group O 필드: `application`, `contemplation_appliance` → 바텀시트/묵상S3
- Group P 필드: `interpretation`, `contemplation_interpretation` → 해석시트/묵상S2해석
- Group Q 필드: `question` → 묵상S3질문
- Random Access: `alarm_top_ko` → 알람탭 카드 (`alarm_top_ko` 있는 구절만 풀 대상)

**스크립트 패턴** (`scripts/` 디렉토리):
```javascript
// 패턴: fix_tone_v{N}.js, patch_*.js, rewrite_*.js
const admin = require('firebase-admin');
const db = admin.firestore();

const updates = {
  v_001: { interpretation: '...', application: '...' },
  v_002: { interpretation: '...', application: '...' },
};

for (const [id, data] of Object.entries(updates)) {
  await db.collection('verses').doc(id).update(data);
}
```

**사용 방법**:
```bash
cd /Users/jeongyong/workspace/dailyverse/scripts
node fix_tone_v3.js            # 톤 수정 반영
node patch_final.js            # 최종 패치
node upload_verses_*.js        # 신규 말씀 업로드
node apply_formula_fields.js   # contemplation_* 수식 재적용 (4개 컬럼)
node sync_sheets_to_firestore.js  # Sheets 전체 → Firestore 동기화
```

---

### 콘텐츠 제작 파이프라인 전체 흐름

```
[1] 원본 구절 준비
    Google Sheets (VERSES / ALARM_VERSES 탭)
    → read_sheet_data.js 로 현재 내용 확인

[2] 초안 작성 (verse-writer)
    Claude 대화에서 interpretation + application 작성
    → 분량: interpretation 102~154자 / application 49~73자
    → contemplation_* 4개 필드는 수식으로 자동 참조 (별도 작성 불필요)

[3] 톤 검수 (tone-reviewer)
    작성된 문구를 톤 기준표로 일괄 검토
    → 수정 필요 항목 목록 추출
    → fix_tone_v{N}.js 스크립트 작성

[4] 원어 검수 (scripture-checker)
    히브리어·헬라어 표기 스캔
    → 발견 시 한국어 풀이로 교체
    → patch_alarm_interpretations.js 스크립트 작성

[5] Firebase 반영 (content-patcher)
    ! node fix_tone_v3.js
    ! node patch_alarm_interpretations.js
    → 또는 전체 동기화: node sync_sheets_to_firestore.js

[6] 최종 확인
    ! node read_tone_check.js
    → Google Sheets 확인: https://docs.google.com/spreadsheets/d/1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig/edit
```

---

### 콘텐츠 품질 체크리스트

문구 작성 후 아래 항목을 반드시 확인합니다:

- [ ] interpretation이 102~154자 범위 내인가? (기준 128자)
- [ ] 원어(히브리어·헬라어) 표기가 없는가?
- [ ] 성경 시대 배경이 1문장 이상 포함됐는가?
- [ ] 마지막 문장이 오늘 상황과 연결됐는가?
- [ ] application에 구체적 행동(~봐, ~해봐)이 있는가?
- [ ] "반드시", "꼭 ~해야", "~하십시오" 표현이 없는가?
- [ ] 모드(아침/오후/저녁/취침)에 맞는 시간대가 반영됐는가?
- [ ] 전체 문구가 ~야, ~이야, ~거야 친구체로 마무리됐는가?

---

## 에이전트 조합 패턴 (자주 쓰는 세트)

### 1. 화면 개발 세트
```
design-researcher → design-engineer → swiftui-builder → design-reviewer
[리서치]          → [디자인 적용]   → [뷰 구현]       → [검증]
```

### 2. 날씨 기능 세트
```
general-purpose(리서치) → weather-engineer(구현) → qa-engineer(검증)
```

### 3. 새 기능 전체 세트
```
bkit:product-manager → Explore(현황파악) → swiftui-builder(UI)
                     ↓
              data-engineer(모델) + firebase-engineer(서버)
                     ↓
              bkit:gap-detector → bkit:pdca-iterator → bkit:report-generator
```

### 4. 버그 수정 세트
```
Explore(원인파악) → swiftui-builder 또는 해당 engineer(수정) → bkit:gap-detector(검증)
```

### 5. PDCA 사이클
```
/pdca plan → /pdca design → 구현 에이전트들 → /pdca analyze → /pdca report
```

### 6. 말씀 문구 제작 세트
```
verse-writer(초안) → tone-reviewer(말투 검수) → scripture-checker(원어 제거) → content-patcher(업로드)
```

### 7. 문구 일괄 리뷰 세트 (기존 말씀 수정)
```
read_tone_check.js(현황 파악) → tone-reviewer(수정안) → fix_tone_v{N}.js(반영)
```

---

## 에이전트 선택 가이드

| 요청 유형 | 사용 에이전트 |
|----------|-------------|
| "화면 만들어줘", "UI 수정해줘" | `swiftui-builder` |
| "다른 앱은 어떻게 하나요?" | `design-researcher` + `general-purpose` |
| "알람이 안 울려요" | `alarm-engineer` |
| "날씨 데이터가 이상해요" | `weather-engineer` |
| "Firebase 저장이 안 돼요" | `firebase-engineer` |
| "이 코드가 맞나요?" | `bkit:gap-detector` + `bkit:code-analyzer` |
| "새 기능 계획 짜줘" | `/pdca plan {feature}` |
| "전체 앱에서 X를 찾아줘" | `Explore` |
| "X에 대해 조사해줘" | `general-purpose` |
| "말씀 해석·적용 써줘" | `verse-writer` |
| "이 문구 말투 좀 봐줘" | `tone-reviewer` |
| "히브리어 표기 지워줘" | `scripture-checker` |
| "Firebase에 반영해줘" | `content-patcher` (Node.js 스크립트) |

---

## 주의사항

### project.pbxproj 수정 규칙
> `docs/pbxproj-rules.md` 참고 — 모든 에이전트에 동일 적용

- **에이전트에게 pbxproj 직접 수정 지시 금지**
- 신규 파일 추가 시: Python 스크립트 + 괄호 검증 필수
- UUID: 반드시 24자리 16진수 [0-9A-F]
- files 배열 안에 객체 정의 삽입 금지

### SourceKit 에러 구분
에이전트가 파일을 수정한 후 SourceKit 에러가 표시될 수 있습니다.
**실제 빌드 에러와 구분 방법**:
- `Cannot find type 'X' in scope` → 다른 파일 타입, **false positive**
- `No such module 'X'` → SPM 모듈, **false positive**
- `Return from initializer without initializing all stored properties` → **실제 에러 가능성 있음** (파일 직접 확인)
- `Missing argument for parameter 'X'` → **실제 에러**, 즉시 수정 필요
