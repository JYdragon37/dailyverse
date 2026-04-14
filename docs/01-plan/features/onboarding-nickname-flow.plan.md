---
feature: onboarding-nickname-flow
phase: plan
created: 2026-04-14
status: active
---

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | 온보딩 닉네임 플로우 개편 |
| 날짜 | 2026-04-14 |
| 범위 | Screen 추가(닉네임 단독 페이지) + Experience 2장 확대 + Personalize 닉네임 섹션 제거 |

### Value Delivered (4-Perspective)

| 관점 | 내용 |
|------|------|
| **Problem** | 닉네임 입력이 테마 선택과 같은 화면에 묶여 맥락이 없고, 말씀 체험이 1장으로 앱 컨셉 전달이 부족 |
| **Solution** | 닉네임을 앱 진입 직후 단독 페이지에서 타이핑 애니메이션으로 유도하고, Zone4·Zone1 2장 체험으로 아침/새벽 컨셉을 각인 |
| **Function UX Effect** | 이름 입력 즉시 "In the Zone, {name}" 형태로 반영돼 개인화 체감 ↑ / 2장 스와이프로 앱의 시간대별 컨셉 직접 체험 |
| **Core Value** | 닉네임 입력율 향상 + 온보딩 완료율 유지 + "매일 다른 시간대에 말씀이 온다"는 핵심 가치 전달 |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| **WHY** | 닉네임을 먼저 받아야 이후 화면(인사말, 말씀 체험)에서 즉시 개인화를 보여줄 수 있음 |
| **WHO** | 온보딩 첫 진입 유저 — 앱이 뭘 해주는지 아직 모르는 상태 |
| **RISK** | 타이핑 애니메이션이 끝나기 전에 유저가 입력하면 애니메이션 충돌 / 페이지 수 4→5로 증가로 완료율 소폭 하락 가능성 |
| **SUCCESS** | 닉네임 입력율 60%+ (기본값 NY 포함) / 온보딩 완료 소요 시간 70초 이내 / 2번 체험 화면 체류율 80%+ |
| **SCOPE** | 5개 파일 수정 + 1개 신규 파일. UserDefaults 키 호환성 유지 필수 |

---

## 1. 요구사항

### 1.1 새 온보딩 플로우 (5단계)

| Page | 화면 | 변경 여부 |
|------|------|----------|
| 0 | ONBIntroView | 변경 없음 |
| 1 | **ONBNicknameView** (NEW) | 신규 생성 |
| 2 | ONBExperienceView | 1장 → 2장 내부 카드 |
| 3 | ONBPersonalizeView | 닉네임 섹션 제거 |
| 4 | ONBAlarmPermissionView | 변경 없음 |

`OnboardingViewModel.totalPages = 4 → 5`

---

### 1.2 ONBNicknameView — 상세 요구사항

#### 타이핑 애니메이션 시퀀스

| 단계 | 동작 | 딜레이 |
|------|------|--------|
| 1 | 빈 필드, 커서 깜빡임 | 0.8s 대기 |
| 2 | '내 이름' 타이핑 (글자당 ~120ms) | — |
| 3 | 0.8s 정지 | — |
| 4 | 백스페이스로 전부 지움 (글자당 ~80ms) | — |
| 5 | '나윤' 타이핑 | — |
| 6 | 0.8s 정지 | — |
| 7 | 백스페이스로 전부 지움 | — |
| 8 | 'NY' 타이핑 | — |
| 9 | 커서 멈춤 — 유저 입력 대기 | — |

- 애니메이션 진행 중 유저가 탭하면 즉시 애니메이션 중단 + 필드 포커스
- 완료 시 `nicknameInput = "NY"` 기본값으로 설정
- 유저가 직접 입력 시 `nicknameInput` 업데이트 (기존 로직 그대로)
- CTA: "시작하기 →" (항상 활성, NY가 기본값이므로)

#### UI 구조

```
[온보딩 그라데이션 배경]
│
├── "매일 어떻게 불러드릴까요?"  (타이틀, fade-in)
│
├── TextField with typing animation
│   └── placeholder: "" (애니메이션이 플레이스홀더 역할)
│
└── CTA "시작하기 →" (하단 고정)
```

---

### 1.3 ONBExperienceView — 2장 카드

#### 내부 구조: TabView (.page style) 2장

| 카드 | Zone | AppMode | 인사말 | 말씀 | 강조 문구 |
|------|------|---------|--------|------|----------|
| Card 1 | Zone4 | peakMode | `⚡ In the Zone, {name}` | v_086 (시편 27:13-14) | "✨ 매일 아침, 새로운 말씀이 알람과 함께 도착해요" 배너 |
| Card 2 | Zone1 | deepDark | `🌑 Still up, Night Owl? {name}` | v_009 (시편 139:9-10) | "하루를 하나님의 말씀으로 시작하세요,\n매일 달라지는 멋진 배경과 함께 말씀이 선물됩니다" |

**v_086 full_ko:**
> "내가 산 자들의 땅에서 여호와의 선하심을 보게 될 것을 믿었도다. 너는 여호와를 바라라, 강하고 담대하라, 여호와를 바라라." — 시편 27:13-14

**v_009 full_ko:**
> "내가 새벽 날개를 치며 바다 끝에 거할지라도 거기서도 주의 손이 나를 인도하시며 주의 오른손이 나를 붙드시리이다." — 시편 139:9-10

#### 레이아웃

```
[배경 이미지 or 폴백 그라데이션 — 카드별 다른 톤]
│
├── 인사말 ({zone icon} {greeting}, {name})      ← 상단, fade-in
├── 배너 or 설명 문구                             ← 카드별 다름
├── 말씀 카드 (고정 텍스트)                        ← 중앙
│
└── [하단 고정]
    ├── 내부 페이지 도트 (• •)                    ← 2장 표시
    └── CTA "매일 멋진 배경과 말씀이 선물로 도착해요 →"  ← 공통
```

- 배경: Card1은 `riseIgnite` 이미지 톤 (bright), Card2는 `deepDark` 그라데이션 폴백
- 내부 도트는 외부 온보딩 도트와 별개
- CTA는 현재 카드가 마지막(Card2)일 때만 `vm.next()` 호출, Card1일 때는 Card2로 이동

---

### 1.4 ONBPersonalizeView — 닉네임 섹션 제거

제거 대상:
- "그리고" 구분선 HStack
- "매일 어떻게 불러드릴까요?" VStack (TextField + 유효성 검증 포함)
- 관련 `@FocusState`, `showNicknameLimitAlert` State 제거
- `.scrollDismissesKeyboard(.interactively)` 제거 가능

유지: 테마 그리드, CTA 버튼 "다음으로 →"

---

### 1.5 OnboardingViewModel — 변경사항

| 변경 | 내용 |
|------|------|
| `totalPages` | `4 → 5` |
| `nicknameInput` 초기화 | 타이핑 애니메이션 완료 후 `"NY"` 설정 |
| `nicknameDisplay` | greeting 조합용 computed property (트레일링 구두점 처리 포함) |
| UserDefaults 호환 | 기존 `nicknameKey` 그대로 유지 |

---

## 2. 제약사항

| ID | 제약 | 이유 |
|----|------|------|
| C-01 | UserDefaults 닉네임 키 변경 불가 | 기존 유저 호환성 |
| C-02 | 총 페이지 수 5개 초과 금지 | 완료율 |
| C-03 | 타이핑 애니메이션은 인터럽트 가능해야 함 | UX 원칙 |
| C-04 | v_086, v_009 텍스트 하드코딩 | 네트워크 불필요, 항상 즉시 표시 |

---

## 3. 구현 범위

### 신규 생성
- `Screens/ONBNicknameView.swift`

### 수정
- `OnboardingContainerView.swift` — page 1에 ONBNicknameView 삽입, totalPages 반영
- `OnboardingViewModel.swift` — totalPages 5, nicknameDisplay 추가
- `Screens/ONBExperienceView.swift` — 내부 2장 TabView 구조로 전면 개편
- `Screens/ONBPersonalizeView.swift` — 닉네임 섹션 제거

### 변경 없음
- `ONBIntroView.swift`
- `ONBAlarmPermissionView.swift`
- `ONBThemeChip.swift`

---

## 4. 리스크

| 리스크 | 가능성 | 대응 |
|--------|--------|------|
| 타이핑 애니메이션 중 유저 인터럽트 충돌 | 중 | Timer 즉시 cancel + 필드 포커스 |
| Card1 → Card2 전환 시 배경 전환 어색 | 중 | cross-dissolve 0.6s |
| `totalPages` 변경으로 진행 도트 깨짐 | 낮 | ForEach 범위 자동 반영 |

---

## 5. 완료 기준 (Success Criteria)

| ID | 기준 |
|----|------|
| SC-01 | 타이핑 애니메이션이 '내 이름' → '나윤' → 'NY' 순서로 자동 실행 |
| SC-02 | 애니메이션 중 탭 시 즉시 중단, 필드 편집 가능 |
| SC-03 | 입력된 닉네임이 Card1 인사말 "In the Zone, {name}"에 반영 |
| SC-04 | 입력된 닉네임이 Card2 인사말 "Still up, Night Owl? {name}"에 반영 |
| SC-05 | Card1에 v_086 말씀 + "매일 아침..." 배너 표시 |
| SC-06 | Card2에 v_009 말씀 + "하루를... 선물됩니다" 설명 표시 |
| SC-07 | ONBPersonalizeView에 닉네임 입력 섹션 없음 |
| SC-08 | 온보딩 전체 5페이지 도트 정상 표시 |
