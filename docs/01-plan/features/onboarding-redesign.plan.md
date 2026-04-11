# Plan: onboarding-redesign

> 생성일: 2026-04-11
> 상태: Plan
> 담당 에이전트: swiftui-builder

---

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 현재 온보딩은 라이트 그라데이션 + 시스템 아이콘으로 메인 앱의 프리미엄 다크 톤과 불일치하고, 가치 증명 없이 닉네임부터 요구하며 감정적 진입점이 없어 이탈률이 높다 |
| **Solution** | Calm/Abide 수준의 프리미엄 감성 온보딩 4단계 — 감성 인트로 → 실제 서비스 체험 → 테마/닉네임 개인화 → 알람+권한 설정 |
| **Function UX Effect** | 첫 화면부터 메인 앱과 동일한 다크 프리미엄 비주얼, 2번째 화면에서 실제 말씀카드+이미지를 먼저 보여줌으로써 "이게 내가 매일 받을 것"을 각인 |
| **Core Value** | 온보딩 완료율 향상 + 첫 알람 설정 유도 (핵심 리텐션 행동) + 브랜드 일관성 확보 |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| **WHY** | 현재 온보딩이 메인 앱 비주얼과 완전히 다른 톤이고, 가치 증명 없이 정보 수집부터 요구 → 유저 이탈 유발 |
| **WHO** | 한국 크리스천 청년/성인, 알람+말씀이라는 새로운 습관을 원하지만 아직 확신이 없는 유저 |
| **RISK** | 4단계로 줄이면 개인화 데이터가 적어짐 / 완전 리빌드 시 기존 UserDefaults 키 호환성 유지 필요 |
| **SUCCESS** | 알람 설정 완료율 70%+ / 알림 권한 허용률 60%+ / 온보딩 완료 소요 시간 60초 이내 |
| **SCOPE** | 4개 신규 SwiftUI 뷰 + OnboardingContainerView + OnboardingViewModel 리빌드. 위치권한 온보딩 제외 |

---

## 1. 요구사항

### 1.1 핵심 요구사항

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| R-01 | 4단계 온보딩 (인트로→체험→개인화→알람+권한) | Must |
| R-02 | 메인 앱과 동일한 다크 프리미엄 비주얼 (dvBgDeep 계열) | Must |
| R-03 | Screen 2에서 실제 말씀카드 + 배경이미지 인터랙티브 체험 | Must |
| R-04 | Screen 3에서 테마 선택 (5~8개 옵션) + 닉네임 입력 | Must |
| R-05 | Screen 4에서 첫 알람 설정 + 알림권한 요청 | Must |
| R-06 | 기존 UserDefaults 키 호환 (onboardingCompleted 등) | Must |
| R-07 | 위치권한은 온보딩에서 제거 → 홈탭 첫 진입 시 요청 | Must |
| R-08 | 완전 리빌드 (현재 TabView + 시스템 아이콘 방식 폐기) | Must |
| R-09 | 각 화면 간 커스텀 전환 애니메이션 (TabView swipe 제거) | Should |
| R-10 | 업셀/구독 화면 온보딩 미포함 | Must Not |

### 1.2 비기능 요구사항

- **성능**: 온보딩 진입 첫 화면 로드 < 200ms
- **접근성**: VoiceOver 지원, 최소 터치 영역 44pt
- **호환성**: iOS 16+

---

## 2. 화면 설계

### Screen 1 — 감성 인트로

**목적**: 브랜드 각인 + 감정적 공감 → "나를 위한 앱"이라는 느낌

```
┌─────────────────────────────┐
│                             │
│   [풀스크린 다크 배경]        │
│   (dvBgDeep + 미세 파티클)   │
│                             │
│         ✦ 로고 애니메이션 ✦   │  ← fade-in 0.8s
│                             │
│      DailyVerse             │  ← 로고타입
│  하루의 끝과 시작을 경건하게  │  ← 슬로건
│                             │
│   "알람이 울릴 때, 말씀이     │  ← 서브카피 (새로 추가)
│    함께 울립니다"             │
│                             │
│   ──────────────────────    │
│                             │
│   [시작하기 →]   (dvAccentGold)│  ← CTA
│                             │
└─────────────────────────────┘
```

**핵심 차이점**:
- 현재: 라이트 그라데이션 (#F8DC99 → #99C8F2) + system book.fill
- 변경: dvBgDeep 다크 배경 + 브랜드 로고 + 파티클 효과 (subtle)
- 새 서브카피: "알람이 울릴 때, 말씀이 함께 울립니다" (핵심 가치 한 줄 전달)

---

### Screen 2 — 체험 (Value-First)

**목적**: 설명하지 말고, 보여준다. "이게 매일 내가 받을 것"

```
┌─────────────────────────────┐
│  [현재 Zone 배경이미지]       │  ← 실제 앱 배경 사용
│  [다크 오버레이]              │
│                             │
│  ☀️ Rise & Ignite, 친구      │  ← 시간대 인사 (데모)
│     06:32 AM                │
│                             │
│  ┌───────────────────────┐  │
│  │ "두려워하지 말라        │  │  ← 실제 말씀카드 (인터랙티브)
│  │  내가 너와 함께        │  │
│  │  함이라"              │  │
│  │           이사야 41:10│  │
│  └───────────────────────┘  │
│                             │
│  ✨ 매일 이 말씀이 알람과      │  ← 설명 문구
│     함께 도착해요             │
│                             │
│  ──────────────────────     │
│  [다음 →]                    │
└─────────────────────────────┘
```

**핵심**: 실제 앱과 동일한 `HomeView` 컴포넌트 일부를 onboarding에 임베드. 유저가 실제 제품을 미리 경험.

---

### Screen 3 — 개인화 (Headspace 2-Question 패턴 적용)

**목적**: 테마 선택으로 콘텐츠를 내 것으로 만들기 + 닉네임
**리서치 근거**: Headspace "기존 루틴에 붙이기" + Calm 목적 질문 2개 압축 원칙

```
┌─────────────────────────────┐
│  [다크 배경]                 │
│                             │
│  지금 당신에게 필요한 건      │  ← 공감 질문
│  어떤 말씀인가요?             │
│                             │
│  ┌────────┐ ┌────────┐      │
│  │ 🌟 용기 │ │ 🕊 평안 │      │  ← 테마 선택 그리드
│  └────────┘ └────────┘      │  (2×3 or 2×4 그리드)
│  ┌────────┐ ┌────────┐      │
│  │ 💡 지혜 │ │ 🙏 감사 │      │
│  └────────┘ └────────┘      │
│  ┌────────┐ ┌────────┐      │
│  │ 💪 힘   │ │ ✨ 회복 │      │
│  └────────┘ └────────┘      │
│                             │
│  ─────────────────────      │
│  우리가 어떻게 불러드릴까요?   │  ← 닉네임 (동일 화면, 하단)
│  [____친구__________]        │
│                             │
│  [다음 →]                    │
└─────────────────────────────┘
```

**핵심**:
- 복수 선택 가능 (최대 2-3개)
- 선택된 테마 → Firestore/UserDefaults에 저장 → 말씀 알고리즘에 반영
- 닉네임을 같은 화면에 통합 (별도 화면 낭비 제거)

---

### Screen 4 — 첫 알람 + 권한 (Permission Priming 적용)

**목적**: 핵심 리텐션 행동(알람 설정)을 온보딩에서 완료. 권한 요청을 Permission Priming으로 65%+ 수락 유도.
**리서치 근거**: Appcues 데이터 — pre-prompt 사전 교육 시 알림 수락률 45% → 65%+

```
┌─────────────────────────────┐
│  [다크 배경]                 │
│                             │
│  언제 말씀을 받고 싶으신가요?  │  ← 감정적 프레이밍
│                             │
│  ┌────────────────────────┐ │
│  │  ☀️ 아침   ⏰ 06:00 AM  │ │  ← TimePicker + toggle
│  └────────────────────────┘ │
│  ┌────────────────────────┐ │
│  │  🌙 저녁   ⏰ 10:00 PM  │ │
│  └────────────────────────┘ │
│                             │
│  ─────────────────────      │
│  🔔 알람이 울릴 때 말씀이     │  ← 알림 권한 설명 (설정 후 표시)
│     함께 오려면 알림이 필요해요│
│                             │
│  [알림 허용하기]  (gold 버튼) │  ← 권한 요청 CTA
│  [나중에]         (ghost)    │
│                             │
│  [시작하기 →]    (완료 CTA)   │  ← 온보딩 완료
└─────────────────────────────┘
```

**흐름**: 알람 시간 선택 → 저장 → "알림 허용하기" 표시 → 권한 요청 → 완료

---

## 3. 경쟁사 레퍼런스 (베스트 프랙티스 적용 포인트)

### 3.1 핵심 데이터 (리서치 기반)

| 지표 | 데이터 | 출처 |
|------|--------|------|
| Value-First 체험 시 D1 리텐션 | **2~3배 향상** | Appcues, AppAgent |
| Permission Priming 적용 시 알림 수락률 | **45% → 65%+** | Appcues 2024 |
| 사용자가 직접 권한 버튼 탭 시 수락률 | **89%** (시스템 팝업 대비) | AppAgent |
| 온보딩 최적 개인화 질문 수 | **2개 이하** | Calm/Headspace 패턴 |
| 설치 당일 페이월 노출 안 할 시 전환 기회 손실 | **82%** | dev.to/paywallpro |

### 3.2 앱별 채택 패턴

| 앱 | 채택할 패턴 | DailyVerse 적용 |
|----|-----------|----------------|
| **Calm** | Value-first (첫 화면에서 즉시 체험) | Screen 2에서 실제 말씀카드 체험 먼저 |
| **Calm** | 딥 네이비/다크 프리미엄 비주얼 | dvBgDeep + 파티클 = 성스럽고 고급스러운 인트로 |
| **Headspace** | "타이밍 질문" — 기존 루틴에 붙이기 | "언제 말씀을 묵상하시나요?" (QT 시간 연결) |
| **Headspace** | 2개 핵심 개인화 질문으로 압축 | 언제 + 무엇이 필요한지 2개만 |
| **Glorify** | 다크+골드 프리미엄 + 영적 성장 은유 | DailyVerse 기존 dvAccentGold와 일치 |
| **Abide** | 체험 후 페이월 — "구독 전 실제 경험" | 나중에 (현재 MVP는 제외) |
| **YouVersion** | 알람/리마인더를 핵심 완료 행동으로 | Screen 4 알람 설정이 온보딩의 "미션 완료" |

### 3.3 한국 크리스천 시장 특수성

| 특성 | DailyVerse 적용 포인트 |
|------|----------------------|
| **QT(Quiet Time) 문화** 강함 | "기존 QT 시간을 알람으로" 포지셔닝 → 신규 습관 아닌 기존 습관 강화 |
| **새벽기도 문화** | 새벽 5~6시 사용자 = 새벽기도 연결 카피 유효 |
| "또 하나의 앱" 거부감 | **"알람은 이미 쓰고 있어요 — 거기에 말씀만 얹는 거예요"** 포지셔닝 |
| 소그룹/셀 문화 | (향후) 친구와 함께 묵상 기능 → D7/D30 리텐션 드라이버 |

### 3.4 Permission Priming 설계 (알림권한 수락률 65%+ 목표)

```
[시스템 팝업 전에 표시할 Pre-prompt 화면]

"⏰ 알람이 울릴 때, 말씀이 함께 울립니다

 [실제 알림 배너 목업 이미지]
 DailyVerse 🔔
 "두려워하지 말라 내가 너와 함께 함이라"
 이사야 41:10 · Rise & Ignite

 알람과 동시에 오늘의 말씀이 잠금화면에 나타나요.
 허용하지 않으면 알람만 울립니다."

[알림 허용하기] → 시스템 팝업 호출
[나중에]
```

---

## 4. 기술 설계 개요

### 4.1 파일 구조 (리빌드)

```
Features/Onboarding/
├── OnboardingContainerView.swift    ← 리빌드 (커스텀 전환 애니메이션)
├── OnboardingViewModel.swift        ← 리빌드 (테마 선택 상태 추가)
├── Screens/
│   ├── ONBIntroView.swift           ← 신규 (Screen 1)
│   ├── ONBExperienceView.swift      ← 신규 (Screen 2 - 체험)
│   ├── ONBPersonalizeView.swift     ← 신규 (Screen 3 - 테마+닉네임)
│   └── ONBAlarmPermissionView.swift ← 신규 (Screen 4 - 알람+권한)
└── Components/
    ├── ONBThemeChip.swift           ← 신규 (테마 선택 칩)
    └── ONBAlarmTimeRow.swift        ← 신규 (알람 시간 행)
```

### 4.2 OnboardingViewModel 변경사항

```swift
// 추가될 State
@Published var selectedThemes: [String] = []    // 테마 다중 선택
@Published var morningAlarmEnabled: Bool = true
@Published var eveningAlarmEnabled: Bool = false
@Published var morningAlarmTime: Date = ...     // 기본 06:00
@Published var eveningAlarmTime: Date = ...     // 기본 22:00

// 기존 UserDefaults 키 유지 (호환성)
// onboardingCompleted, nicknameSet 등 그대로
```

### 4.3 화면 전환 애니메이션

```swift
// 현재: TabView swipe (수평)
// 변경: 커스텀 ZStack + offset 기반 전환

// 옵션 A: 슬라이드 업 (각 화면이 아래에서 위로 올라옴)
// 옵션 B: Fade + scale (Calm 스타일)
// 옵션 C: 슬라이드 오른쪽 (기존과 유사하되 더 부드럽게)
```

### 4.4 위치권한 이동

```swift
// 현재: OnboardingLocationView (Screen 3)
// 변경: PermissionManager에서 홈탭 첫 진입 시 요청
//        HomeViewModel.loadData() → checkAndRequestLocationIfNeeded()
```

---

## 5. 데이터 변경사항

### 5.1 UserDefaults (기존 키 유지 + 추가)

| 키 | 변경 | 설명 |
|----|------|------|
| `onboardingCompleted` | 유지 | 온보딩 완료 여부 |
| `nicknameSet` | 유지 | 닉네임 설정 여부 |
| `notificationPermissionRequested` | 유지 | 알림 권한 요청 여부 |
| `locationPermissionRequested` | 유지 (온보딩에서 미사용) | 위치 권한 |
| `firstAlarmPromptShown` | 유지 | 첫 알람 설정 여부 |
| `selectedThemes` | **신규** | 유저 선택 테마 배열 (JSON) |

### 5.2 Firestore 유저 문서 (선택사항)

```
users/{uid}.preferred_themes: [String]   // 로그인 유저만 저장
```

---

## 6. 성공 기준

| 지표 | 목표 | 측정 방법 |
|------|------|---------|
| 온보딩 완료율 | ≥ 85% | Screen 1 진입 대비 Screen 4 완료 |
| 알람 설정율 | ≥ 70% | Screen 4 완료 시 알람 1개 이상 설정 |
| 알림권한 허용율 | ≥ 60% | iOS 권한 팝업 허용 탭 |
| 온보딩 소요 시간 | ≤ 60초 | 첫 화면 진입 ~ 완료 |
| 테마 선택율 | ≥ 80% | Screen 3 건너뛰지 않고 선택 |

---

## 7. 구현 순서

| 순서 | 작업 | 예상 파일 |
|------|------|----------|
| 1 | OnboardingViewModel 리빌드 | OnboardingViewModel.swift |
| 2 | ONBIntroView (Screen 1) | ONBIntroView.swift |
| 3 | ONBExperienceView (Screen 2) | ONBExperienceView.swift |
| 4 | ONBPersonalizeView + ONBThemeChip (Screen 3) | ONBPersonalizeView.swift, ONBThemeChip.swift |
| 5 | ONBAlarmPermissionView + ONBAlarmTimeRow (Screen 4) | ONBAlarmPermissionView.swift, ONBAlarmTimeRow.swift |
| 6 | OnboardingContainerView 리빌드 (전환 애니메이션) | OnboardingContainerView.swift |
| 7 | 위치권한 → HomeViewModel 이동 | HomeViewModel.swift |
| 8 | AppRootView 연결 검증 | AppRootView.swift |

---

## 8. 리스크

| 리스크 | 확률 | 대응 |
|--------|------|------|
| Screen 2 말씀카드 로딩 지연 | 중 | 폴백 구절(fallbackRiseIgnite) 즉시 표시 후 비동기 로드 |
| 기존 UserDefaults 키 충돌 | 저 | 동일 키 이름 유지, 신규 키만 추가 |
| 테마 선택이 알고리즘에 미반영 | 중 | VerseSelector에 preferred_themes 가중치 추가 |
| 온보딩 스킵 후 설정 미완 | 중 | HomeViewModel에서 firstAlarmPromptShown 체크 → CTA 표시 |
