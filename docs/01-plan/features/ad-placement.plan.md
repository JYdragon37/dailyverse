---
feature: ad-placement
phase: do
created: 2026-04-26
status: in-progress
---

# 광고 배치 계획 — morning manna

## 개요

AdMob 광고를 유저 경험을 최대한 방해하지 않는 위치에 배치.
Free 유저 대상 수익화 전략의 일환.

---

## 구현 완료된 광고 영역 (6곳)

| # | 화면 | 광고 유형 | 크기 | 파일 |
|---|------|----------|------|------|
| 1 | 말씀 깊게 보기 (VerseDetailBottomSheet) | 배너 | 300×250 | `Common/Components/VerseDetailBottomSheet.swift` |
| 2 | 알람 설정 상세 (AlarmAddEditView) | 배너 | 300×250 | `Features/Alarm/AlarmAddEditView.swift` |
| 3 | 알람 목록 하단 (AlarmListView) | 스마트 배너 | 320×50 | `Features/Alarm/AlarmListView.swift` |
| 4 | 저장된 말씀 그리드 인라인 (SavedView) | 배너 | 300×250 | `Features/Saved/SavedView.swift` |
| 5 | 저장된 말씀 카드 탭 시 (SavedView → SavedDetailView) | 전면 영상 (Interstitial) | 전체화면 | `Features/Saved/SavedView.swift` |
| 6 | 설정 탭 피드백↔계정 섹션 사이 (SettingsView) | 배너 | 300×250 | `Features/Settings/SettingsView.swift` |

### 공유 컴포넌트
- `Common/Components/BannerAdView.swift` — `BannerAdView` (300×250) + `SmartBannerAdView` (320×50)
- `Core/Managers/AdManager.swift` — Rewarded + Interstitial 통합 관리

---

## 광고 로직

### 배너 광고
- `BannerAdView`: `GADBannerView(adSize: GADAdSizeMediumRectangle)` — 300×250
- `SmartBannerAdView`: `GADBannerView(adSize: GADAdSizeBanner)` — 320×50
- 뷰가 나타날 때 자동 로드

### 전면 광고 (Interstitial)
- `AdManager.shared.loadInterstitialAd()` — SavedView `.task`에서 사전 로드
- `SavedView.handleCardTap(_:)` — 광고 준비 완료 시 표시 → 종료 후 상세 화면 오픈
- 광고 미로드 시 graceful fallback (바로 상세 화면 오픈)

### 저장 그리드 인라인 배너
- `filteredVerses`를 6개씩 청크 분할 (`stride(from:to:by:6)`)
- 각 청크 뒤 배너 표시 (마지막 청크 제외)

---

## 현재 상태 (테스트 기간)

> ⚠️ 현재 모든 계정에 광고 표시 중 (프리미엄 계정 포함)

테스트 기간 동안 Premium 조건을 제거한 파일 4곳:

```
AlarmAddEditView.swift  line ~183  // TODO: 출시 전 isPremium 조건 복구
AlarmListView.swift     line ~116  // TODO: 출시 전 isPremium 조건 복구
SavedView.swift         line ~44   // TODO: 출시 전 isPremium 조건 복구
SavedView.swift         line ~183  // TODO: 출시 전 isPremium 조건 복구
SettingsView.swift      line ~68   // TODO: 출시 전 isPremium 조건 복구
```

---

## 출시 전 체크리스트

### 1. Premium 조건 복구
위 5곳에 `if !subscriptionManager.isPremium { }` 래퍼 복구.

```swift
// 복구 예시 (AlarmAddEditView)
if !subscriptionManager.isPremium {
    Section {
        BannerAdView()
            .frame(width: 300, height: 250)
            ...
    } header: { Text("광고").font(.dvSectionTitle) }
}
```

### 2. 실제 Ad Unit ID 교체

| 파일 | 상수/변수 | 현재 (테스트) | 교체 필요 |
|------|----------|-------------|---------|
| `BannerAdView.swift` | `adUnitID` (BannerAdView) | `ca-app-pub-3940256099942544/2934735716` | 실제 Medium Rectangle ID |
| `BannerAdView.swift` | `adUnitID` (SmartBannerAdView) | `ca-app-pub-3940256099942544/2934735716` | 실제 Banner (320×50) ID |
| `AdManager.swift` | `kRewardedAdUnitID` | `ca-app-pub-3940256099942544/1712485313` | 실제 Rewarded ID |
| `AdManager.swift` | `kInterstitialAdUnitID` | `ca-app-pub-3940256099942544/4411468910` | 실제 Interstitial ID |

> AdMob 콘솔에서 앱 등록 후 각 광고 유형별 Ad Unit 생성 필요.

### 3. VerseDetailBottomSheet 확인
이 파일은 처음부터 Premium 조건이 없었음 — 출시 전 조건 추가 여부 판단 필요.

---

## 광고 배치 선정 기준

- **HomeView**: 미배치 — 핵심 영성 경험 영역, 광고 배치 시 앱 가치 훼손
- **알람 Stage 2**: 미배치 — 기상 직후 말씀 집중 순간, 절대 금지
- **온보딩**: 미배치 — 첫인상 저해
- **알람 카드 사이**: 미배치 — 시간 확인 스캔 흐름 방해
