# DailyVerse 서브 에이전트 가이드

> 이 프로젝트에서 Claude Code가 활용하는 서브 에이전트 목록입니다.
> 각 에이전트는 특정 역할에 특화되어 있으며, 복잡한 작업을 병렬/순차로 처리합니다.
> 마지막 업데이트: 2026-04-10 (v6.1 — devotion_question 신규 추가 + devotion-question-writer 에이전트)

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
    ├── verse-writer              — 해석(interpretation) + 적용(application) 초안 작성
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
> Google Sheets(원본) → Claude 작성 → 톤 검수 → Firebase 업로드 순서로 진행됩니다.

---

### `verse-writer` (general-purpose 활용)
**역할**: 성경 구절의 해석(interpretation) + 일상 적용(application) 문구 초안 작성
**주로 사용**: 새 말씀 배치 추가, 기존 문구 전면 재작성

**프롬프트 패턴**:
```
아래 성경 구절의 interpretation, application, contemplation_ko를 작성해줘.

구절: {성경 구절 전문}
참조: {책 이름 장:절}
모드: {morning/afternoon/evening/alarm 중 해당}

[interpretation 작성 규칙]
- 분량: 102~154자 (기준 128자, ±20%)
- 성경 시대 배경 또는 저자의 상황을 1문장으로 먼저 소개
- 원어(히브리어·헬라어) 표기 절대 금지
  → 원어 뜻이 중요하면 한국어로 풀어서 설명
- 마지막 문장은 오늘 나의 상황과 연결되도록 마무리
- 말투: ~야, ~이야, ~거야, ~있어, ~돼 (친근한 대화체)

[application 작성 규칙]
- 분량: 49~73자 (기준 61자, ±20%)
- 오늘 바로 실천할 수 있는 구체적 행동 1가지 포함
- 말투: ~봐, ~해봐, ~해도 돼, ~기억해 (부드러운 권유체)
- 설교조·명령조 금지: "반드시 ~해야", "~하십시오" 사용 금지
- {모드}의 시간대(아침/오후/저녁/취침)에 맞는 상황 반영

[contemplation_ko 작성 규칙] (신규)
- 분량: 50~200자
- verse_full_ko와 동일한 구절이어도 되지만, 묵상에 더 적합한 다른 구절 선정도 가능
- 긴 묵상 시간에 천천히 읽을 수 있는 구절 (verse_short_ko보다 깊이 있게)
- 말투: 성경 인용체 (의역 허용)

[contemplation_reference 작성 규칙] (신규)
- 형식: "책이름 장:절" (예: "시편 23:1-2", "이사야 40:31")
- contemplation_ko의 출처

예시:
interpretation: "이 말씀은 바울이 로마 감옥에서 빌립보 교인들에게 쓴 편지야..."
application: "오늘 버거운 일이 있어도 기억해. 능력 주시는 분께 연결된 채로 시작해봐..."
contemplation_ko: "나의 영혼아 잠잠히 하나님만 바라라. 무릇 나의 소망이 그로부터 나오는도다."
contemplation_reference: "시편 62:5"
```

**산출물**: Google Sheets `interpretation`, `application`, `contemplation_ko`, `contemplation_reference` 컬럼에 입력할 텍스트

---

### `tone-reviewer` (general-purpose 활용)
**역할**: 작성된 문구의 말투가 DailyVerse 기준에 맞는지 점검·수정
**주로 사용**: 새 문구 배치 전 QA, 기존 문구 일괄 리뷰 (`fix_tone_v1~v3.js` 패턴)

**톤 기준표**:

| 구분 | 허용 표현 | 금지 표현 |
|------|---------|---------|
| 문장 종결 | ~야, ~이야, ~거야, ~느껴, ~일 거야, ~봐, ~해도 돼, ~있어, ~계셔 | ~이다, ~합니다, ~입니다, ~이라, ~하는 것이다 |
| 권유 | ~해봐, ~기억해, ~말해봐, ~생각해봐 | 반드시 ~해야, 꼭 ~하라, ~하십시오 |
| 설명 | 배경 서사 + 현재 연결 | 설교체 독백, 신학 강의조 |
| 원어 | 한국어로 풀어 설명 | 히브리어·헬라어 직접 표기 (예: "헤세드", "케코스미카") |

**프롬프트 패턴**:
```
아래 말씀 문구들의 말투를 DailyVerse 톤 기준으로 점검해줘.

[톤 기준]
좋음: ~야, ~이야, ~거야, ~있어, ~봐, ~해도 돼
나쁨: ~이다, ~합니다, ~입니다, 반드시 ~해야, 설교조

검토할 문구:
{verse_id}: verse_short_ko = "{텍스트}"
{verse_id}: verse_full_ko = "{텍스트}"
{verse_id}: interpretation = "{텍스트}"
{verse_id}: application = "{텍스트}"
{verse_id}: contemplation_ko = "{텍스트}"
...

결과 형식:
- OK: 수정 불필요
- 수정 필요: 문제 부분 → 수정안

수정이 필요한 항목만 수정안을 제시하고, OK인 건 "OK"만 표시해줘.
```

**산출물**: 수정 필요 항목 목록 + 수정안 → `fix_tone_v{N}.js` 스크립트로 반영

---

### `scripture-checker` (general-purpose 활용)
**역할**: 원어 표기 제거 + 성경 역사적 배경 팩트체크
**주로 사용**: 초안 작성 후 원어 표기 여부 스캔 (`patch_alarm_interpretations.js` 패턴)

**프롬프트 패턴**:
```
아래 interpretation 문구들에서 히브리어·헬라어 원어 표기가 있으면 모두 찾아줘.
원어 표기를 한국어 풀이로 대체한 수정안도 함께 제시해줘.

금지 패턴 예시:
- "히브리어 '라아'는..." → "히브리어 표현이지만 풀이로: '풍성하게 이끈다'는 뜻인데..."
- "헬라어 '케코스미카'는..." → "'이미 완전히 이겼다'는 완료형 표현인데..."
- "헤세드의 흔적이..." → "변함없는 사랑의 흔적이..."

검토할 문구:
{verse_id}: interpretation = "{interpretation 텍스트}"
{verse_id}: contemplation_ko = "{contemplation_ko 텍스트}"
...

결과:
- 원어 없음: OK
- 원어 발견: 해당 부분 → 대체 수정안
```

**산출물**: 패치 대상 리스트 → `patch_alarm_interpretations.js` 형태로 Firebase 반영

---

### `devotion-question-writer` (general-purpose 활용)
**역할**: 특정 말씀에 대한 묵상 응답 화면용 개인화 질문 생성
**주로 사용**: 새 verse 배치 추가 시, 또는 devotion_question 일괄 생성 시

**입력 필드**:
- `verse_short_ko`: 핵심 요약 구절 (카드 표시용)
- `reference`: 성경 참조 (예: "이사야 41:10")
- `interpretation`: 말씀 해석 문구
- `contemplation_ko`: 묵상 작성 시트용 구절

**출력 필드**:
- `devotion_question`: 40~80자 질문형 문장 (닉네임 없이 저장)

**프롬프트 패턴**:
```
아래 말씀에 대한 묵상 질문(devotion_question)을 생성해줘.

말씀: {verse_short_ko}
참조: {reference}
해석: {interpretation}
묵상 구절: {contemplation_ko}

[devotion_question 작성 규칙]
- 분량: 40~80자 (1~2문장)
- 형식: 질문형 문장
- 닉네임 없이 저장 (앱에서 "{name}님, " 앞붙임으로 동적 합성)
- 톤: 따뜻하고 개인적인 어조, 일상 언어 사용, 종교적 어조 최소화
- 대답 형태: 선택형 / 회상형 / 상상형 중 하나로
- 연결: 말씀의 핵심 메시지를 일상 삶과 연결
- 금지: 설교조 질문, 신앙 점검 형태 ("기도했나요?", "말씀을 읽었나요?")
- 금지: "~해야 합니까?", "~하셨나요?" 등 경어체
- 누구나 공감할 수 있는 보편적 질문 (신앙 유무와 관계없이)

[좋은 예시]
- "요즘 당신을 가장 두렵게 만드는 것은 무엇인가요?"
- "오늘 이 말씀이 가장 필요한 순간은 언제일까요?"
- "지금 당신의 시선은 어디를 향해 있나요?"
- "힘든 시간 속에서 당신을 위로해준 것이 있나요?"

[나쁜 예시]
- "오늘 하나님께 기도했나요?" (종교적 점검)
- "말씀을 암송해봤나요?" (신앙 행위 점검)
- "여러분은 어떻게 생각하십니까?" (경어체, 방송 어투)
```

**산출물**: `devotion_question` 필드값 → `generate_devotion_questions.js` 스크립트로 Firebase 반영

---

### `content-patcher` (Node.js 스크립트)
**역할**: 검수 완료된 문구를 Google Sheets 또는 Firestore에 배치 업로드
**주로 사용**: 문구 수정 완료 후 실제 반영

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
node fix_tone_v3.js      # 톤 수정 반영
node patch_final.js      # 최종 패치
node upload_verses_*.js  # 신규 말씀 업로드
```

---

### 콘텐츠 제작 파이프라인 전체 흐름

```
[1] 원본 구절 준비
    Google Sheets (VERSES / ALARM_VERSES 탭)
    → read_sheet_data.js 로 현재 내용 확인

[2] 초안 작성 (verse-writer)
    Claude 대화에서 interpretation + application 작성
    → 분량: interpretation 102~154자 / application 49~73자 / contemplation_ko 50~200자

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

[6] 최종 확인
    ! node read_tone_check.js
    → Google Sheets에서 최종 내용 재확인
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
