# 직접 처리해야 할 TODO

> 이 파일은 Claude가 자동으로 처리할 수 없는 작업들을 기록합니다.
> 마지막 코드 검증: 2026-05-17
> 완료 시 `[x]`로 체크하세요.

---

## 🔴 즉시 — 출시 블로커

### RevenueCat API 키 — ⚠️ Production 키 확인 필요

- [x] **DailyVerseApp.swift:29** — `test_qLgnYIQVMaVTzEsejPWGaCUQrsu` 입력 완료 ✅
- [ ] **출시 전 확인** — `test_` prefix는 Sandbox 환경. RevenueCat 대시보드에서
  Production / Live 키(`appl_` 또는 다른 prefix)가 별도로 있는지 확인.
  있다면 교체 후 커밋. 없으면 현재 키로 진행.

### 미커밋 파일 커밋 필요

- [ ] **알람 사운드 시스템 커밋** — 새 기능이 git에 없음
  ```bash
  git add \
    "DailyVerse/DailyVerse/01_새벽이슬_Morning_Dew_30sec.mp3" \
    "DailyVerse/DailyVerse/02_기쁨의_행진_Joyful_March_30sec.mp3" \
    "DailyVerse/DailyVerse/03_아침_은혜_Grace_Awake_30sec.mp3" \
    "DailyVerse/DailyVerse/04_일어나라_빛을_발하라_Arise_and_Shine_30sec.mp3" \
    "DailyVerse/DailyVerse/05_샬롬의_아침_Shalom_Morning_30sec.mp3" \
    "DailyVerse/DailyVerse/06_은혜의_빛_Light_of_Grace_30sec.mp3" \
    DailyVerse/DailyVerse/Features/Alarm/SoundPickerSheet.swift \
    DailyVerse/DailyVerse/Core/Models/Alarm.swift \
    DailyVerse/DailyVerse/Core/Services/AlarmKitEngine.swift \
    DailyVerse/DailyVerse/Core/Services/LegacyAlarmEngine.swift \
    DailyVerse/DailyVerse/Features/Alarm/AlarmAddEditView.swift \
    DailyVerse/DailyVerse.xcodeproj/project.pbxproj
  git commit -m "feat: 알람 사운드 선택 시스템 — 6개 음원 + SoundPickerSheet"
  ```

---

## 🔴 출시 전 필수 (Xcode + App Store Connect)

- [ ] **PrivacyInfo.xcprivacy Xcode 타겟 포함 확인**
  > Xcode → DailyVerse 타겟 → Build Phases → Copy Bundle Resources
  > `PrivacyInfo.xcprivacy` 있는지 확인. 없으면 + 버튼으로 추가.

- [ ] **Distribution Certificate + Provisioning Profile 유효 확인**
  > Xcode → Signing & Capabilities → Release 설정
  > "Automatically manage signing" 체크 시 자동 처리됨

- [ ] **Archive → TestFlight 업로드 (첫 빌드 확인)**
  > Xcode → Product → Archive → Distribute App → App Store Connect
  > 업로드 완료 후 App Store Connect에서 빌드 처리 대기 (~10분)

- [ ] **App Store Connect — 앱 정보 입력 완료**
  > 스크린샷 5장 (1290×2796px) 준비 및 업로드
  > 앱 설명, 키워드, What's New 입력 (`docs/appstore-metadata.md` 참조)

- [ ] **App Store Connect — Privacy Practices 답변**
  > Data collected: 이름(닉네임), 이메일(Apple Sign-In), 사용 데이터(Analytics)
  > 서드파티 광고: AdMob (광고 ID 수집 여부 답변 필요)

- [ ] **App Store Connect — Age Rating 설문**
  > 4+ 선택 (폭력·성인 콘텐츠 없음)

- [ ] **GitHub Pages 활성화 확인** (이미 완료됐을 수 있음)
  > 저장소 Settings → Pages → Branch: main → /docs → Save
  > `https://jydragon37.github.io/dailyverse/legal/privacy.html` 접속 확인

---

## 🟡 콘텐츠

- [x] **sync_verses.js 실행** — 539개 동기화 완료 (2026-05-17) ✅
- [x] **question 필드** — active+curated 전체 200개 확인, 미보유 0개 ✅
- [x] **application 범용화** — 엄격 기준(알람 끄고/퇴근하며/잠들기 전 등) 위반 0개 ✅

---

## 🟡 이미지

- [ ] **Zone 이미지 부족 보강** — Genspark Pro 생성 후 워크플로우 실행

  | Zone | 목표 |
  |------|------|
  | peak_mode (09~12시) | 10개 이상 |
  | recharge (12~15시) | 10개 이상 |
  | second_wind (15~18시) | 10개 이상 |
  | golden_hour (18~21시) | 10개 이상 |

  > 생성 → `design_test/` 폴더 드롭 → Claude: "design_test 검수해줘" → `🖼️ 이미지 업로드.command`

---

## 🟡 코드 정리

- [x] **AlarmStage1View.swift** — DEPRECATED 주석 추가 완료 ✅
- [x] **앱 종료 시 선택 사운드 미반영** — LegacyAlarmEngine 수정, 선택 음원 우선 적용 ✅

---

## 🟢 운영 (DAU 1,000명 전)

- [ ] **Firebase Blaze 플랜 전환** — Firestore reads 초과 전
- [ ] **Firestore 예산 알림 설정** — $50, $100 threshold
- [ ] **RevenueCat 플랜 확인** — MAU 10,000명 초과 시 유료 전환
- [ ] **CS 채널** — 이메일 자동 응답 또는 카카오채널 개설

---

## ✅ 완료 항목 (검증됨, 2026-05-17)

- [x] **앱스토어 리뷰 URL** — `id6763995142` ✅
- [x] **개인정보처리방침 · 이용약관 URL** — GitHub Pages (jydragon37.github.io) ✅
- [x] **Ad Unit ID** — Secrets.xcconfig에 실제 ID 등록 ✅
- [x] **GADApplicationIdentifier** — Info.plist에 등록 ✅
- [x] **isPremium 광고 조건** — SavedView 5곳 정상 ✅
- [x] **ATT 팝업** — AppTrackingTransparency 구현 완료 ✅
- [x] **개역한글 출처 표기** — SettingsView "성경 본문: 개역한글, 대한성서공회" ✅
- [x] **강제 업데이트 메커니즘** — fetchMinimumVersion 구현 ✅
- [x] **마스터 계정 시스템** — Firestore app_config/master_accounts ✅
- [x] **PremiumUpgradeView** — SettingsView + SavedView 통합 완료 ✅
- [x] **알람 사운드 6종 MP3** — 번들 포함 + pbxproj 등록 + 커밋 완료 ✅
- [x] **SoundPickerSheet** — AlarmAddEditView 통합 + 커밋 완료 ✅
- [x] **NSSupportsLiveActivities** — Info.plist 등록 ✅
- [x] **SKAdNetwork 30개** — Info.plist 등록 ✅
- [x] **UIBackgroundModes audio** — Info.plist 등록 ✅
- [x] **Firestore minimum_version 문서** — 스크립트로 생성 ✅
- [x] **자정 경계 마이그레이션** — Cloud Functions 00:00 KST ✅
