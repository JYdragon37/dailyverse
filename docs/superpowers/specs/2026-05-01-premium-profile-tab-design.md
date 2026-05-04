# Premium 구매 UI — 프로필 탭 설계

**날짜**: 2026-05-01
**범위**: UI/레이아웃만 (RevenueCat 실제 결제 연동 없음)
**진입점**: 프로필 탭 + Saved 탭 배너

---

## 1. 목표

무료 유저가 프리미엄 구독을 쉽게 발견하고 구매 화면에 접근할 수 있도록 한다.
기존 SettingsView 구조를 최소한으로 변경하면서, 전용 구매 페이지를 별도 뷰로 분리한다.

---

## 2. 변경 파일 목록

| 파일 | 변경 유형 | 설명 |
|------|-----------|------|
| `Features/Settings/PremiumUpgradeView.swift` | **신규 생성** | Premium 전용 구매 페이지 |
| `Features/Settings/SettingsView.swift` | **수정** | "구독" 섹션 카드 추가 |
| `Features/Saved/SavedView.swift` | **수정** | Free 유저 하단 배너 추가 |

---

## 3. PremiumUpgradeView (신규)

### 위치
`DailyVerse/Features/Settings/PremiumUpgradeView.swift`

### 진입 방식
- SettingsView의 NavigationLink (push)
- SavedView 하단 배너 탭 시 `.sheet`

### 레이아웃 (스크롤 뷰)

```
NavigationBar: "Premium" (← 뒤로가기)

[헤더 영역]
  👑 (아이콘)
  "PREMIUM"  (dvAccentGold, 대문자)
  "하루의 말씀이 더 깊어집니다"  (subtitle)

[비교 테이블]
  ┌──────────────┬──────────┬──────────────┐
  │ 기능          │  Free    │  Premium ✨  │
  ├──────────────┼──────────┼──────────────┤
  │ 말씀 아카이브  │  7일     │  무제한       │
  │ 테마 선택     │  자동     │  자유 선택    │
  │ 광고          │  있음     │  없음         │
  │ 카드 워터마크  │  있음     │  없음         │
  │ 묵상 기록     │  무제한   │  무제한       │
  └──────────────┴──────────┴──────────────┘
  (Premium 열: dvAccentGold 색상 강조)

[CTA 영역]
  [₩24,500/월 시작하기]  (dvAccentGold 배경, 꽉 찬 버튼)
  [구독 복원하기]  (텍스트 버튼, 작은 크기)
  "구독은 App Store에서 언제든지 해지 가능합니다" (주석)
```

### Premium 유저 상태
- `subscriptionManager.isPremium == true` 이면 CTA 버튼 대신 "이미 Premium이에요 ✓" 표시
- 비교 테이블의 현재 플랜(Premium) 열에 체크 표시

### 버튼 동작 (UI만)
- "시작하기" → `Task { await subscriptionManager.purchase() }` 호출 (현재 Analytics 로그만)
- "구독 복원하기" → `Task { await subscriptionManager.restore() }` 호출 (현재 빈 구현)

---

## 4. SettingsView 수정

### 추가 위치
`profileCard` 바로 아래, `sectionCard(title: "외관")` 위

### 추가 내용

```swift
// Free 유저이거나 Premium 유저 모두 표시 (상태만 다름)
sectionCard(title: "구독") { subscriptionRows }
```

### subscriptionRows

**Free 유저 (`!subscriptionManager.isPremium`)**
```
NavigationLink → PremiumUpgradeView
  [icon: star.fill, gold] "Premium 업그레이드"  ›
  subtitle: "무제한 아카이브 · 광고 없음 · 테마 자유 선택"
```

**Premium 유저 (`subscriptionManager.isPremium`)**
```
  [icon: checkmark.seal.fill, gold] "Premium 구독 중"
  trailing: "✓" (체크, 탭 불가)
  subtitle: 만료일 있을 경우 "~까지" 표시, 없으면 생략
```

### NavigationStack 연결
SettingsView는 이미 `NavigationStack`을 사용하므로 `NavigationLink(destination:)` 그대로 사용.

---

## 5. SavedView 수정

### 추가 위치
`savedGrid` 내 `LazyVStack` 마지막, 말씀 목록 아래

### 표시 조건
- `!subscriptionManager.isPremium && !viewModel.savedVerses.isEmpty`

### 배너 레이아웃

```
┌─────────────────────────────────────────┐
│  👑  더 많은 말씀을 기록하고               │
│      되돌아보고 싶으신가요?               │
│                                         │
│      [Premium 시작하기  →]               │
└─────────────────────────────────────────┘
```

- 배경: `dvBgSurface` + 골드 테두리 (opacity 0.25)
- 버튼 탭 → `showPremiumUpgrade = true` → `.sheet { PremiumUpgradeView() }`

### State 추가
```swift
@State private var showPremiumUpgrade = false
```

---

## 6. 디자인 토큰

기존 `Color+DailyVerse.swift` 확장 없이 기존 토큰만 사용:

| 용도 | 토큰 |
|------|------|
| 골드 강조 | `Color.dvAccentGold` |
| 카드 배경 | `Color.dvBgSurface` |
| 배경 | `Color.dvBgDeep` |
| 주요 텍스트 | `Color.white` |
| 보조 텍스트 | `Color.white.opacity(0.45)` |
| Premium 열 배경 | `Color.dvAccentGold.opacity(0.08)` |

---

## 7. 제외 범위

- RevenueCat 상품 조회 (`Purchases.shared.offerings()`) — 향후 구현
- StoreKit 결제창 실제 표시 — 향후 구현
- 구독 성공 후 `isPremium` 업데이트 — 향후 구현
- 업셀 트리거 빈도 제한 연동 — 향후 구현
