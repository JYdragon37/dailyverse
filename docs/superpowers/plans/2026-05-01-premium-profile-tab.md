# Premium 구매 UI — 프로필 탭 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 프로필 탭과 Saved 탭에 Premium 구매 UI를 추가하여 Free 유저가 자연스럽게 프리미엄 구독 화면에 접근할 수 있도록 한다.

**Architecture:** SettingsView(프로필 탭)에 구독 섹션을 추가하고, NavigationLink로 신규 PremiumUpgradeView를 연결한다. SavedView 하단에는 Free 유저 전용 배너를 추가해 `.sheet`로 같은 PremiumUpgradeView를 표시한다.

**Tech Stack:** SwiftUI (iOS 16+), `SubscriptionManager` (@EnvironmentObject), 기존 디자인 토큰 (`Color+DailyVerse`, `Font+DailyVerse`)

**Spec:** `docs/superpowers/specs/2026-05-01-premium-profile-tab-design.md`

---

## 파일 맵

| 파일 | 변경 유형 |
|------|-----------|
| `DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift` | **신규 생성** |
| `DailyVerse/DailyVerse/Features/Settings/SettingsView.swift` | **수정** (구독 섹션 추가) |
| `DailyVerse/DailyVerse/Features/Saved/SavedView.swift` | **수정** (배너 + sheet 추가) |

---

## Task 1: PremiumUpgradeView 기본 구조 생성

**Files:**
- Create: `DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift`

- [ ] **Step 1: 파일 생성 — 뷰 뼈대 + #Preview**

`DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift` 를 다음 내용으로 생성:

```swift
import SwiftUI

struct PremiumUpgradeView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                comparisonTable
                ctaSection
            }
            .padding(.bottom, 40)
        }
        .background(Color.dvBgDeep.ignoresSafeArea())
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.dvBgDeep.opacity(0.95), for: .navigationBar)
    }

    // MARK: - Sections (stub)

    private var headerSection: some View {
        Text("Header")
            .foregroundColor(.white)
            .padding(.top, 40)
    }

    private var comparisonTable: some View {
        Text("Table")
            .foregroundColor(.white)
    }

    private var ctaSection: some View {
        Text("CTA")
            .foregroundColor(.white)
    }
}

#Preview {
    NavigationStack {
        PremiumUpgradeView()
            .environmentObject(SubscriptionManager())
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Xcode에서 빌드 확인**

Xcode에서 `Cmd+B` 또는 터미널:
```bash
cd /Users/jeongyong/workspace/dailyverse/DailyVerse
xcodebuild -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift
git commit -m "feat: add PremiumUpgradeView stub"
```

---

## Task 2: PremiumUpgradeView — 헤더 섹션 구현

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift`

- [ ] **Step 1: headerSection 구현**

`PremiumUpgradeView.swift` 의 `headerSection` 스텁을 다음으로 교체:

```swift
private var headerSection: some View {
    VStack(spacing: 12) {
        // 왕관 아이콘
        ZStack {
            Circle()
                .fill(Color.dvAccentGold.opacity(0.12))
                .frame(width: 72, height: 72)
            Text("👑")
                .font(.system(size: 36))
        }
        .padding(.top, 40)

        // 타이틀
        Text("PREMIUM")
            .font(.system(size: 26, weight: .black))
            .foregroundColor(Color.dvAccentGold)
            .tracking(3)

        // 부제
        Text("하루의 말씀이 더 깊어집니다")
            .font(.dvSubtitle)
            .foregroundColor(.white.opacity(0.55))
            .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 32)
}
```

- [ ] **Step 2: #Preview 확인 — 헤더가 올바르게 표시되는지**

Xcode `#Preview` 캔버스에서:
- 왕관 원형 배경 (골드, 낮은 opacity)
- "PREMIUM" 골드 대문자 텍스트
- "하루의 말씀이 더 깊어집니다" 회색 부제

빌드 확인: `xcodebuild -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift
git commit -m "feat: implement PremiumUpgradeView header section"
```

---

## Task 3: PremiumUpgradeView — 비교 테이블 구현

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift`

- [ ] **Step 1: 비교 테이블 데이터 타입 + comparisonTable 구현**

`PremiumUpgradeView` 내부에 타입과 데이터를 추가하고, `comparisonTable` 스텁을 교체:

```swift
// 파일 상단 struct PremiumUpgradeView 내부에 추가

private struct FeatureRow {
    let title: String
    let free: String
    let premium: String
}

private let features: [FeatureRow] = [
    FeatureRow(title: "말씀 아카이브",  free: "7일",   premium: "무제한"),
    FeatureRow(title: "알람 테마",      free: "자동",  premium: "자유 선택"),
    FeatureRow(title: "광고",          free: "있음",  premium: "없음"),
    FeatureRow(title: "카드 워터마크", free: "있음",  premium: "없음"),
    FeatureRow(title: "묵상 기록",     free: "무제한", premium: "무제한"),
]

// comparisonTable 스텁 교체:
private var comparisonTable: some View {
    VStack(spacing: 0) {
        // 헤더 행
        HStack(spacing: 0) {
            Text("기능")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)

            Text("Free")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 72, alignment: .center)

            Text("Premium")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.dvAccentGold)
                .frame(width: 96, alignment: .center)
                .padding(.trailing, 16)
        }
        .frame(height: 36)
        .background(Color.dvBgSurface)

        // 상단 구분선
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)

        // 기능 행들
        ForEach(Array(features.enumerated()), id: \.offset) { index, row in
            featureRow(row, isLast: index == features.count - 1)
        }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(.horizontal, 16)
    .padding(.bottom, 32)
}

private func featureRow(_ row: FeatureRow, isLast: Bool) -> some View {
    VStack(spacing: 0) {
        HStack(spacing: 0) {
            Text(row.title)
                .font(.dvBody)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)

            Text(row.free)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.40))
                .frame(width: 72, alignment: .center)

            Text(row.premium)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.dvAccentGold)
                .frame(width: 96, alignment: .center)
                .padding(.trailing, 16)
        }
        .frame(height: 48)
        .background(
            HStack(spacing: 0) {
                Color.clear.frame(maxWidth: .infinity)
                Color.clear.frame(width: 72)
                Color.dvAccentGold.opacity(0.06).frame(width: 96)
            }
        )

        if !isLast {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
                .padding(.leading, 16)
        }
    }
    .background(Color.dvBgSurface)
}
```

- [ ] **Step 2: 빌드 확인**

```bash
cd /Users/jeongyong/workspace/dailyverse/DailyVerse
xcodebuild -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```
Expected: `BUILD SUCCEEDED`

Preview에서 확인:
- 5개 기능 행이 표시됨
- Premium 열이 골드 색상으로 강조됨
- Free 열은 낮은 opacity

- [ ] **Step 3: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift
git commit -m "feat: implement PremiumUpgradeView comparison table"
```

---

## Task 4: PremiumUpgradeView — CTA 섹션 구현

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift`

- [ ] **Step 1: ctaSection 구현**

`ctaSection` 스텁을 다음으로 교체:

```swift
private var ctaSection: some View {
    VStack(spacing: 12) {
        if subscriptionManager.isPremium {
            // Premium 유저 상태
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.dvAccentGold)
                Text("이미 Premium이에요")
                    .font(.dvSubtitle)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.dvAccentGold.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.dvAccentGold.opacity(0.25), lineWidth: 1)
            )
        } else {
            // 구매 버튼
            Button {
                Task { await subscriptionManager.purchase() }
            } label: {
                VStack(spacing: 3) {
                    Text("Premium 시작하기")
                        .font(.system(size: 16, weight: .bold))
                    Text("₩24,500/월")
                        .font(.system(size: 13, weight: .medium))
                        .opacity(0.75)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dvAccentGold)
                .foregroundColor(Color(hex: "#1A2340"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // 복원 버튼
            Button {
                Task { await subscriptionManager.restore() }
            } label: {
                Text("구독 복원하기")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
        }

        // 안내 문구
        Text("구독은 App Store에서 언제든지 해지할 수 있습니다")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.25))
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
    .padding(.horizontal, 24)
}
```

- [ ] **Step 2: Preview에 Premium 상태 추가 확인**

`#Preview` 블록을 다음으로 업데이트하여 두 상태 모두 확인:

```swift
#Preview("Free 유저") {
    NavigationStack {
        PremiumUpgradeView()
            .environmentObject(SubscriptionManager())
    }
    .preferredColorScheme(.dark)
}

#Preview("Premium 유저") {
    let sm = SubscriptionManager()
    sm.isPremium = true
    return NavigationStack {
        PremiumUpgradeView()
            .environmentObject(sm)
    }
    .preferredColorScheme(.dark)
}
```

> 주의: `SubscriptionManager.isPremium`이 `private(set)` 이면 테스트용으로 직접 설정이 안 될 수 있음.
> 그 경우 Preview에서는 Free 상태 하나만 확인하고 넘어가도 됨.

빌드 확인:
```bash
cd /Users/jeongyong/workspace/dailyverse/DailyVerse
xcodebuild -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Features/Settings/PremiumUpgradeView.swift
git commit -m "feat: implement PremiumUpgradeView CTA section"
```

---

## Task 5: SettingsView — 구독 섹션 추가

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Settings/SettingsView.swift`

- [ ] **Step 1: `subscriptionSection` 프로퍼티 추가**

`SettingsView.swift`의 `// MARK: - 외관 섹션` 위에 다음을 삽입:

```swift
// MARK: - 구독 섹션

@ViewBuilder
private var subscriptionRows: some View {
    if subscriptionManager.isPremium {
        // Premium 유저
        HStack(spacing: 14) {
            iconBadge("checkmark.seal.fill", color: Color.dvAccentGold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Premium 구독 중")
                    .font(.dvBody)
                    .foregroundColor(.white)
                if let expDate = subscriptionManager.expirationDate {
                    Text("갱신일: \(expDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.40))
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color.dvAccentGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    } else {
        // Free 유저 — NavigationLink
        NavigationLink {
            PremiumUpgradeView()
                .environmentObject(subscriptionManager)
        } label: {
            HStack(spacing: 14) {
                iconBadge("star.fill", color: Color.dvAccentGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium 업그레이드")
                        .font(.dvBody)
                        .foregroundColor(.white)
                    Text("무제한 아카이브 · 광고 없음 · 테마 자유 선택")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: body에 구독 섹션 카드 삽입**

`SettingsView.body` 의 `// ── 외관 ──` 줄 바로 위에 다음을 삽입:

```swift
// ── 구독 ─────────────────────────────────
sectionCard(title: "구독") { subscriptionRows }
    .padding(.top, 4)
```

즉, 삽입 후 순서는:
```
profileCard
sectionCard("구독") { subscriptionRows }   // ← 새로 삽입
sectionCard("외관") { appearanceRows }
sectionCard("앱 설정") { permissionRows }
...
```

- [ ] **Step 3: 빌드 확인**

```bash
cd /Users/jeongyong/workspace/dailyverse/DailyVerse
xcodebuild -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```
Expected: `BUILD SUCCEEDED`

#Preview에서 확인:
- 프로필 카드 아래 "구독" 섹션이 표시됨
- Free 유저: "Premium 업그레이드" 행 + 골드 아이콘 + chevron

- [ ] **Step 4: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Features/Settings/SettingsView.swift
git commit -m "feat: add subscription section to SettingsView"
```

---

## Task 6: SavedView — 하단 Premium 배너 추가

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Saved/SavedView.swift`

- [ ] **Step 1: State 변수 추가**

`SavedView`의 `@State` 변수 블록에 추가:

```swift
@State private var showPremiumUpgrade = false
```

- [ ] **Step 2: premiumBanner 뷰 추가**

`SavedView` 내부에 다음 프로퍼티 추가 (`// MARK: - Content` 섹션 아래 아무 곳):

```swift
private var premiumBanner: some View {
    Button {
        showPremiumUpgrade = true
    } label: {
        HStack(spacing: 16) {
            Text("👑")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text("더 많은 말씀을 되돌아보고 싶으신가요?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("Premium으로 전체 아카이브를 열어보세요")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.50))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.dvAccentGold)
        }
        .padding(16)
        .background(Color.dvBgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.dvAccentGold.opacity(0.22), lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 24)
}
```

- [ ] **Step 3: savedGrid에 배너 삽입**

`savedGrid` 프로퍼티의 `LazyVStack` 끝에 배너를 추가.

현재 `savedGrid`에서 `LazyVStack(spacing: 0) {` 블록이 닫히기 직전에 다음을 삽입:

```swift
// Premium 업그레이드 배너 (Free 유저, 말씀 있을 때만)
if !subscriptionManager.isPremium {
    premiumBanner
}
```

- [ ] **Step 4: `.sheet` modifier 추가**

`SavedView.body` 의 기존 `.sheet(isPresented: $showLoginPrompt)` 블록 바로 다음에 추가:

```swift
.sheet(isPresented: $showPremiumUpgrade) {
    NavigationStack {
        PremiumUpgradeView()
            .environmentObject(subscriptionManager)
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 5: 빌드 확인**

```bash
cd /Users/jeongyong/workspace/dailyverse/DailyVerse
xcodebuild -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```
Expected: `BUILD SUCCEEDED`

시뮬레이터에서 확인:
- 저장된 말씀이 있는 Free 유저 → 그리드 하단에 골드 테두리 배너 표시
- 배너 탭 → PremiumUpgradeView가 sheet으로 올라옴

- [ ] **Step 6: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Features/Saved/SavedView.swift
git commit -m "feat: add premium upgrade banner to SavedView"
```

---

## Task 7: 통합 확인 및 마무리

**Files:**
- No new files

- [ ] **Step 1: 프로필 탭 → Premium 페이지 진입 확인**

시뮬레이터에서:
1. 프로필 탭 탭 → "구독" 섹션에 "Premium 업그레이드" 행 보임
2. 행 탭 → PremiumUpgradeView가 push 애니메이션으로 열림
3. 비교 테이블 5개 행 표시 확인
4. "₩24,500/월 시작하기" 버튼 탭 → 아무 일도 없음 (UI only, 정상)
5. "구독 복원하기" 탭 → 아무 일도 없음 (정상)
6. 뒤로 가기 정상 작동

- [ ] **Step 2: Saved 탭 → Premium 페이지 진입 확인**

시뮬레이터에서:
1. Saved 탭 탭 → 저장 말씀 목록 하단에 배너 표시 확인
2. 배너 탭 → PremiumUpgradeView가 sheet으로 올라옴
3. 스와이프 다운으로 닫힘 확인

- [ ] **Step 3: 최종 빌드**

```bash
cd /Users/jeongyong/workspace/dailyverse/DailyVerse
xcodebuild -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED` with no warnings related to new files

- [ ] **Step 4: 최종 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git status
git commit -m "feat: premium upgrade UI — profile tab entry + saved tab banner"
```
