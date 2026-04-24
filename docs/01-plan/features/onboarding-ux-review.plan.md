# onboarding-ux-review Planning Document

> **Summary**: 현재 구현된 4화면 온보딩(공감→닉네임→체험→알람설정)을 프로덕트 원칙 대비 검토하고, 전환율을 최대화하는 개선안을 도출한다
>
> **Project**: DailyVerse iOS
> **Version**: v1.0 MVP
> **Author**: PM Agent
> **Date**: 2026-04-16
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 현재 온보딩은 닉네임 수집(Screen 1)이 알람 체험(Screen 2) 앞에 배치되어 "가치 먼저, 마찰 나중" 원칙을 위반한다. After 배경이 쿨톤(민트-보라)이라 따뜻한 영적 공감 감정을 전달하지 못한다. 닉네임 강제 입력이 CTA를 막아 완료율을 떨어뜨린다 |
| **Solution** | Screen 순서 재배열(공감→체험→닉네임→알람설정) + After 배경 웜톤 전환 + 닉네임 기본값 허용으로 CTA 상시 활성화 |
| **Function/UX Effect** | 유저가 마찰 없이 말씀 체험을 먼저 경험 → 제품 가치 각인 후 개인화(닉네임)와 클라이맥스(알람 설정) 진행 → "내일 아침이 기대된다"는 감정으로 마무리 |
| **Core Value** | 알람 설정 완료율 70%+ 확보 / "노력 없이도 말씀 앞에 서게 해준다"는 핵심 가치를 온보딩에서 직접 증명 |

---

## Context Anchor

| Key | Value |
|-----|-------|
| **WHY** | 닉네임이 체험 앞에 있어 마찰이 발생 + 쿨톤 배경이 따뜻한 영적 공감을 방해 → 온보딩 이탈 유발 |
| **WHO** | A타입 크리스천 — QT 하고 싶지만 작심삼일인 바쁜 한국 크리스천 청년/성인 |
| **RISK** | 닉네임을 뒤로 미루면 Stage 2 체험에서 nicknameDisplay가 "NY" 기본값으로 표시됨 → 체험 품질 저하 가능 |
| **SUCCESS** | 알람 설정 완료율 ≥70% / 온보딩 전체 완료율 ≥85% / 소요시간 ≤60초 |
| **SCOPE** | Screen 순서 변경(코드 수정 최소화) + ONBIntroView 배경 웜톤 전환 + 닉네임 CTA 활성화 정책 변경 |

---

## 1. Overview

### 1.1 Purpose

현재 구현된 온보딩 4화면을 프로덕트 원칙(가치 먼저 / 알람 설정이 클라이맥스 / 내일 아침 마법 예고)에 비추어 검토하고,
전환율을 저해하는 요소를 제거한 개선안을 정의한다.

### 1.2 Background

`onboarding-redesign.plan.md`(2026-04-11)에서 설계한 4화면이 구현 완료되었으나,
디자인 에이전트 피드백과 실제 코드 검토 결과 아래 3가지 구조적 문제가 발견되었다:

1. **화면 순서**: 닉네임(마찰)이 체험(가치)보다 먼저 나온다
2. **After 배경 톤**: 쿨톤(#4EC4B0→#9080CC) — 원칙과 다르게 따뜻함이 느껴지지 않음
3. **CTA 차단**: 닉네임 미입력 시 "시작하기" 버튼 비활성화 → 완료율 저하

### 1.3 Related Documents

- 원본 설계: `docs/01-plan/features/onboarding-redesign.plan.md`
- 닉네임 플로우: `docs/01-plan/features/onboarding-nickname-flow.plan.md`

---

## 2. 현재 온보딩 원칙 준수 평가

### 원칙 1 — 유저의 문제를 첫 화면에서 정면으로 건드림

**평가: 부분 충족**

ONBIntroView의 Before(어두운 알람 흔들림)→After(말씀 카드 등장) 전환은 의도적으로 설계되었다.
그러나 After 배경이 쿨톤(민트-보라 그라데이션)이라 "따뜻함"과 "경건함"이 시각적으로 전달되지 않는다.
슬로건("매일 아침, 알람이 아닌 말씀으로 눈을 뜨세요")은 포지셔닝과 정확히 일치한다.

**개선 필요**: After 배경을 웜톤(앰버-골드 계열)으로 전환. blur bloom 효과 추가.

---

### 원칙 2 — 알람 설정이 온보딩의 클라이맥스

**평가: 충족**

ONBAlarmPermissionView(Screen 3)는 시간 피커 + "내일 아침 말씀 받기" CTA로 설계되어 원칙과 일치한다.
단, Screen 1(닉네임)에서 CTA가 차단되는 구조가 유저를 소진시켜 클라이맥스 도달 전 이탈을 유발할 수 있다.

**개선 필요**: 닉네임 미입력 시 기본값("NY")으로 진행 허용.

---

### 원칙 3 — 권한 요청은 맥락에 맞게 자연스럽게 (전용 화면 없음)

**평가: 충족**

현재 구현은 알람 설정 화면 내에서 "내일 아침 말씀 받기" CTA 탭 시 알림 권한을 요청한다.
별도 전용 권한 화면이 없으며, 원칙과 일치한다.

---

### 원칙 4 — 진짜 마법은 내일 아침에 일어남 — 온보딩은 그 마법을 예고하는 역할

**평가: 미충족**

ONBAlarmPermissionView 완료 후 아무런 "예고" 없이 온보딩이 끝난다.
"내일 아침 {시간}에 말씀이 함께 울릴 거예요" 같은 마무리 메시지가 없다.
ONBExperienceView Stage 3(해석+적용)은 가치를 보여주지만,
"내일"에 대한 기대감을 만드는 메시지로 연결되지 않는다.

**개선 필요**: 알람 설정 완료 직후 "내일 {HH:mm}, 말씀이 함께 울려요" 확인 화면 또는 토스트 추가.

---

## 3. 화면별 핵심 문제 및 개선 우선순위

### P0 — 즉시 수정 (전환율 직접 영향)

| # | 화면 | 문제 | 개선안 |
|---|------|------|--------|
| P0-1 | Screen 1 (닉네임) | 닉네임 미입력 시 CTA 비활성화 → 완료율 저하 | 기본값 "NY"로 CTA 항상 활성화. 미입력 경고 문구 제거 |
| P0-2 | Screen 0 (공감 After) | After 배경이 쿨톤 → 따뜻함/경건함 미전달 | After 배경을 웜톤(앰버 #F5A623 → 딥네이비 #1A2340) 또는 다크 골드 계열로 전환 |

### P1 — 이번 이터레이션 (UX 완성도)

| # | 화면 | 문제 | 개선안 |
|---|------|------|--------|
| P1-1 | Screen 0→1 전환 | blur bloom 효과 없음 | Before→After 전환 시 blur bloom 0.3s 추가 (디자인 에이전트 피드백) |
| P1-2 | Screen 1 (닉네임) | 말씀 카드 spring 등장 없음 | warmVerse 카드에 `.spring(response: 0.6, dampingFraction: 0.7)` 진입 애니메이션 추가 |
| P1-3 | Screen 0 (공감) | 슬로건 전체 동시 페이드인 | 두 줄 순차 페이드인 (0.15s 간격) |
| P1-4 | Screen 3 (알람설정) | 완료 후 기대감 메시지 없음 | 완료 시 "내일 {HH:mm}, 말씀이 함께 울려요" 확인 토스트 or 마무리 카드 |

### P2 — 다음 이터레이션

| # | 화면 | 문제 | 개선안 |
|---|------|------|--------|
| P2-1 | 순서 전체 | 닉네임이 체험 앞에 위치 | 순서를 공감→체험→닉네임→알람으로 재배열 (하단 상세 참조) |
| P2-2 | Screen 2 (체험) | Stage 3 후 "다음" 버튼이 화면 흐름을 끊음 | Stage 3 하단에 "내일 {시간}, 이 말씀이 알람과 함께 와요" 멘트 추가 후 자동 진행 |
| P2-3 | Screen 1 (닉네임) | 타이핑 예시가 "NY"(영문 이니셜)라 한국 유저에게 어색 | 예시를 "민준", "서연" 같은 한국 이름으로 교체 고려 |

---

## 4. 화면 순서 분석

### 4.1 현재 순서

```
공감(0) → 닉네임(1) → 체험(2) → 알람설정(3)
```

**문제**: 마찰(닉네임 입력)이 가치(말씀 체험) 앞에 있다.
유저는 아직 앱의 가치를 경험하지 못한 상태에서 개인 정보를 요구받는다.
Calm/Headspace 연구에서 "가치 먼저, 정보 수집 나중" 원칙은 D1 리텐션을 2~3배 향상시킨다.

### 4.2 권장 순서 — Option A (권장)

```
공감(0) → 체험(1) → 닉네임(2) → 알람설정(3)
```

**이유**:
- 공감 화면에서 "이런 앱이 있다"를 인식
- 체험 화면에서 실제 알람+말씀 UX를 먼저 경험 → "이거 나한테 필요하다" 확신
- 확신이 생긴 후 닉네임 입력 → 마찰이 선물처럼 느껴짐 ("이 앱이 나를 이름으로 불러줄 것")
- 닉네임이 있는 상태에서 알람 설정 → Stage 2 체험 시 "Good Morning, {이름}"이 personalized

**트레이드오프**: 체험 화면(ONBExperienceView) Stage 2에서 닉네임이 없으면 "NY"로 표시됨. 수용 가능.

### 4.3 Option B (차선)

```
공감(0) → 체험(1) → 닉네임+알람(2 — 통합)
```

화면 수를 3개로 줄여 완료율을 높이는 방안. 단, 알람 설정이 닉네임과 같은 화면에 있어 클라이맥스 희석.
MVP에서는 Option A 권장.

---

## 5. "내일 아침이 기대된다" 감정 생성 — 현재 부족한 점

### 5.1 현재 흐름의 감정 곡선

```
공감 → 닉네임(마찰, 감정 저하) → 체험(상승) → 알람설정(평탄) → 완료(아무것도 없음)
```

마지막이 "완료" 없이 끝난다. 알람 설정 후 앱이 바로 홈으로 이동한다.

### 5.2 필요한 감정 피크

클라이맥스는 알람 설정 완료 직후여야 한다. 이 순간 유저는:
- 내일 아침 몇 시에 말씀을 받을지 알고 있다
- 이것이 어떤 경험인지(Stage 1/2 체험으로) 이미 안다

여기서 다음 두 가지가 없으면 기대감이 형성되지 않는다:

**누락 요소 1**: 구체적인 미래 시각 확인
"내일 오전 07:00, 말씀이 함께 울려요" — 시간이 구체적일수록 기대감이 높아진다.

**누락 요소 2**: 알람 설정 완료에 대한 시각적 보상
현재는 CTA 탭 → 홈 이동. 완료 애니메이션, 체크마크, 확인 피드백이 없다.

### 5.3 개선 방향

ONBAlarmPermissionView의 "내일 아침 말씀 받기" CTA 탭 후:
1. 체크 애니메이션 0.5s 재생
2. "내일 {HH:mm}, 말씀이 함께 울려요 🔔" 한 줄 표시 (1.5s)
3. 홈으로 전환

총 추가 시간: 약 2초. 이 2초가 리텐션을 결정한다.

---

## 6. 최종 권장 온보딩 플로우

### 권장 구성 (4화면, 순서 변경)

```
Screen 0 — 공감 (ONBIntroView)
  핵심 메시지: "매일 아침, 알람이 아닌 말씀으로 눈을 뜨세요"
  역할: 문제 공감 + Before/After 대비로 제품 컨셉 전달
  변경사항: After 배경 웜톤 전환, 슬로건 순차 페이드인

Screen 1 — 체험 (ONBExperienceView) ← 닉네임과 순서 교체
  핵심 메시지: "이게 내일 아침 당신이 경험할 것입니다"
  역할: 실제 알람+말씀 UX를 직접 경험 → 가치 각인
  변경사항: Stage 3 말미에 "내일 {시간}에 이 말씀이 알람과 함께 와요" 문구 추가

Screen 2 — 닉네임 (ONBNicknameView) ← 체험 뒤로 이동
  핵심 메시지: "DailyVerse가 당신을 뭐라고 불러드릴까요?"
  역할: 확신이 생긴 후 개인화 → 마찰이 아닌 선물로 느껴짐
  변경사항: CTA 항상 활성화(기본값 "NY" 적용), 타이핑 예시 한국 이름으로 교체

Screen 3 — 알람설정 (ONBAlarmPermissionView) ← 클라이맥스 유지
  핵심 메시지: "첫 말씀 알람을 설정해볼까요?"
  역할: 온보딩의 클라이맥스 — 리텐션 행동 완료
  변경사항: 완료 후 시각적 확인("내일 {HH:mm}, 말씀이 함께 울려요") 추가
```

### 각 화면 소요 시간 (목표: 전체 ≤60초)

| 화면 | 예상 체류 시간 | 비고 |
|------|-------------|------|
| Screen 0 (공감) | 5~8초 | 애니메이션 자동 진행 + CTA |
| Screen 1 (체험) | 15~20초 | Stage 1→2→3 인터랙션 |
| Screen 2 (닉네임) | 8~12초 | 타이핑 애니메이션 + 입력 |
| Screen 3 (알람설정) | 8~12초 | 피커 + CTA |
| **합계** | **36~52초** | 목표 60초 이내 달성 |

---

## 7. Requirements

### 7.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | ONBIntroView After 배경을 웜톤(앰버-딥네이비 계열)으로 변경 | P0 | Pending |
| FR-02 | ONBNicknameView CTA: 닉네임 미입력 시 기본값 "NY"로 진행 허용 (항상 활성) | P0 | Pending |
| FR-03 | 슬로건 두 줄을 순차 페이드인 (0.15s 간격) | P1 | Pending |
| FR-04 | ONBIntroView Before→After 전환에 blur bloom 효과 추가 | P1 | Pending |
| FR-05 | warmVerse 말씀 카드 spring 진입 애니메이션 추가 | P1 | Pending |
| FR-06 | ONBAlarmPermissionView 완료 후 "내일 {HH:mm}, 말씀이 함께 울려요" 확인 메시지 | P1 | Pending |
| FR-07 | OnboardingContainerView 화면 순서 변경: 공감→체험→닉네임→알람설정 | P2 | Pending |
| FR-08 | ONBNicknameView 타이핑 예시를 한국 이름으로 교체 | P2 | Pending |

### 7.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| 완료율 | 온보딩 전체 완료율 ≥85% | Analytics: screen_0_view → screen_3_complete |
| 알람 설정율 | 알람 설정 완료율 ≥70% | Analytics: alarm_created_in_onboarding |
| 성능 | 각 화면 첫 렌더 <200ms | Xcode Instruments |
| 소요시간 | 전체 온보딩 ≤60초 | Firebase Analytics avg_session_duration |

---

## 8. Success Criteria

### 8.1 Definition of Done (P0 기준)

- [ ] FR-01: After 배경 웜톤 전환 완료 (시각적으로 따뜻함 느껴짐)
- [ ] FR-02: 닉네임 미입력 상태에서도 CTA 탭 가능, "NY"로 저장됨
- [ ] 기존 온보딩 완료율/알람 설정율 지표와 비교 기준선 설정

### 8.2 Definition of Done (P1 포함)

- [ ] FR-03~FR-06 모두 구현
- [ ] 알람 설정 완료 후 확인 메시지 표시 및 홈 전환 정상 동작
- [ ] iOS 16+ 기기에서 회귀 테스트 통과

---

## 9. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 화면 순서 변경(P2) 시 닉네임이 없는 상태에서 체험 화면 실행 → "Good Morning, NY" 표시 | Low | High | nicknameDisplay 기본값 "NY" 유지. 유저 체험에 큰 영향 없음 |
| After 배경 웜톤 전환 시 슬로건 텍스트 가독성 저하 | Medium | Low | 텍스트에 `.shadow(color: .black.opacity(0.3))` 추가로 대비 확보 |
| 완료 확인 메시지 추가 시 onboardingCompleted 저장 타이밍 이슈 | High | Low | 확인 메시지 표시 전에 completeOnboarding() 호출 완료 보장 |
| 기존 온보딩 UserDefaults 키 호환성 | High | Low | 기존 키 변경 없음. 순서 변경은 뷰 레이어만 영향 |

---

## 10. Impact Analysis

### 10.1 Changed Resources

| Resource | Type | Change Description |
|----------|------|--------------------|
| `ONBIntroView.swift` | SwiftUI View | After 배경 색상, blur bloom 애니메이션, 슬로건 순차 페이드인 |
| `ONBNicknameView.swift` | SwiftUI View | CTA 활성화 정책 변경 (항상 활성), 타이핑 예시 교체 |
| `ONBAlarmPermissionView.swift` | SwiftUI View | 완료 후 확인 메시지 추가 |
| `OnboardingContainerView.swift` | SwiftUI View | 화면 순서 변경 (P2) |
| `OnboardingViewModel.swift` | ViewModel | 순서 변경 시 page index 매핑 수정 (P2) |

### 10.2 Current Consumers

| Resource | Operation | Code Path | Impact |
|----------|-----------|-----------|--------|
| `onboardingCompleted` | WRITE | `OnboardingViewModel.completeOnboarding()` | None |
| `nicknameInput` | READ | `ONBExperienceView.vm.nicknameDisplay` | nicknameDisplay 기본값 "NY" 유지로 안전 |
| `currentPage` | READ/WRITE | `OnboardingContainerView.pageOffset()` | 순서 변경 시 page index 검증 필요 |

---

## 11. Next Steps

1. [ ] CTO 검토 및 승인
2. [ ] P0 항목 즉시 구현 (FR-01, FR-02)
3. [ ] P1 항목 이번 스프린트 내 구현 (FR-03~FR-06)
4. [ ] P2 항목 다음 이터레이션 계획 수립 (화면 순서 변경)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-16 | Initial draft — PM 온보딩 UX 검토 | PM Agent |
