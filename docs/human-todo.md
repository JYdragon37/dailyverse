# 직접 처리해야 할 TODO

> 이 파일은 Claude가 자동으로 처리할 수 없는 작업들을 기록합니다.
> 카테고리 딥다이브 후 발견된 항목들이 순서대로 추가됩니다.
> 완료 시 `[x]`로 체크하세요.

---

## 📖 콘텐츠

### 🔴 즉시

- [ ] **sync_verses.js 실행** — v_200 zone 수정 내용 Firestore에 반영
  ```bash
  cd scripts && node sync_verses.js
  ```
  > v_200 mode가 Sheets에서 `first_light,all`로 수정됨. sync하면 Firestore에 반영됨.

- [ ] **Firestore curated 필드 확인** — 현재 Firestore에 `"true"` (문자열)로 저장된 게 있는지 직접 확인
  > Firebase 콘솔 → Firestore → verses → 문서 몇 개 열어서 `curated` 필드 타입 확인
  > boolean `true` = 정상 / string `"true"` = sync_verses.js 재실행 필요

### 🟡 단기

- [ ] **question 필드 142개 생성**
  ```bash
  cd scripts && node generate_meditation_questions.js
  ```
  > 생성 후 content-checker로 QA 필수

- [ ] **application 398개 범용화** — content-fixer 에이전트 실행
  > `application`에서 시간대 언급 제거 (`알람 끄고`, `이제 편히 자`, `퇴근하며` 등)
  > 범용 표현으로 교체 (docs/contents-guideline.md §4-3 기준)
  > 수정 후 sync_verses.js로 Firestore 반영

### 🟢 중기

- [ ] **말씀 추가** — 전체 풀 다양성 확보
  > 현재 active 398개. Zone별 편중 있으나 급하지 않음.
  > content-writer 에이전트로 생성 → content-checker QA → sync
  > 목표: 500개+

---

## 🖼 이미지 (카테고리 딥다이브 예정)

### 🔴 즉시

- [ ] **이미지 부족 Zone 보강** — Genspark Pro로 생성
  > 아래 Zone이 이미지 부족 (content-schema.md 기준)

  | Zone | 현황 | 목표 |
  |------|------|------|
  | peak_mode (09~12시) | 부족 | 10개 이상 |
  | recharge (12~15시) | 부족 | 10개 이상 |
  | second_wind (15~18시) | 부족 | 10개 이상 |
  | golden_hour (18~21시) | 부족 | 10개 이상 |

  > 생성 후 워크플로우:
  > 1. `design_test/` 폴더에 드롭
  > 2. Claude Code: "design_test 검수해줘"
  > 3. `🖼️ 이미지 업로드.command` 더블클릭

---

## 📱 디바이스 / iOS 버전

### 🟡 단기

- [ ] **구형 기기 성능 테스트** — iPhone XR 또는 Instruments Network Link Conditioner
  > Xcode → Xcode → Open Developer Tool → Instruments → Time Profiler
  > 또는 Simulator → 추가 설정 → Network Link Conditioner (3G 속도 시뮬레이션)
  > 확인 항목: 첫 로딩 시 스켈레톤 화면 표시 여부, 감성 이미지 로딩 시 버벅임 여부

- [ ] **다양한 기기 레이아웃 점검** — Xcode 시뮬레이터로 확인
  > iPhone SE (3세대, 홈 버튼 있음), iPhone 15 Pro Max (Dynamic Island), iPhone 16
  > 확인 항목: SafeArea 잘림 없는지, 알람 Stage2 레이아웃 정상 여부

---

## 🔧 출시 전 필수

- [ ] **App Store 리뷰 링크 ID 교체** — `SettingsView.swift` 라인 377
  > 현재: `https://apps.apple.com/app/id0` (더미값)
  > 앱 등록 후 부여받은 숫자 ID로 `id0` 교체 필요 (예: `id6736271234`)

- [x] **Ad Unit ID 교체** ✅ 완료 — Secrets.xcconfig에 실제 ID 등록됨
  > banner: ca-app-pub-9794385634652581/3762868800
  > interstitial: ca-app-pub-9794385634652581/8113177357
  > rewarded: ca-app-pub-9794385634652581/8645239404

- [x] **GADApplicationIdentifier 교체** ✅ 완료 — ca-app-pub-9794385634652581~2135671376

- [ ] **isPremium 광고 조건 복구** (테스트 기간 제거한 5곳)
  > `docs/ad-placement.plan.md` TODO 위치 참고

- [ ] **개인정보처리방침 · 이용약관 URL** — `example.com` 플레이스홀더 교체
  > `SettingsView.swift` 내 URL 2곳
  > 실제 호스팅된 페이지 필요 (notion 공개 페이지도 가능)

- [ ] **개역한글 출처 표기** — SettingsView 앱 정보 섹션에 추가
  > "성경 본문: 개역한글, 대한성서공회"

- [ ] **ATT(App Tracking Transparency) 팝업** 구현
  > iOS 14.5+ 광고 추적 허용 팝업 — 미구현 시 App Store 심사 거절

- [ ] **앱스토어 리뷰 URL** 교체
  > `SettingsView.swift` 내 `https://apps.apple.com/app/id0` → 실제 앱 ID

---

## 📊 스케일링 관련 (1만 유저 대비)

- [ ] **Firebase Blaze 플랜 전환** — DAU 1,000명 도달 전
- [ ] **Firestore 예산 알림 설정** — $50, $100 threshold
- [ ] **RevenueCat 플랜 확인** — MAU 10,000명 초과 시 유료 전환
- [ ] **강제 업데이트 메커니즘** — Firestore `app_config/min_version` 문서 추가
- [ ] **CS 응대 채널** — 이메일 자동화 or 카카오채널 개설

---

> 마지막 업데이트: 2026-04-26
> 카테고리 딥다이브 진행에 따라 항목 추가 예정
