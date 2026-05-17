# 직접 처리해야 할 TODO

> 이 파일은 Claude가 자동으로 처리할 수 없는 작업들을 기록합니다.
> 마지막 코드 검증: 2026-05-17
> 완료 시 `[x]`로 체크하세요.

---

## 🔴 즉시 — 출시 블로커

### RevenueCat API 키 미입력 (수익화 완전 불능)

- [ ] **DailyVerseApp.swift:29** — `Purchases.configure(withAPIKey: "")` 빈 문자열 교체
  > RevenueCat 대시보드 → 프로젝트 → API Keys → Public SDK key 복사
  > `Purchases.configure(withAPIKey: "appl_XXXX...")` 형태로 입력

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

- [ ] **sync_verses.js 실행** — v_200 zone 수정 Firestore 반영
  ```bash
  cd scripts && NODE_TLS_REJECT_UNAUTHORIZED=0 node sync_verses.js
  ```

- [ ] **question 필드 생성 여부 확인** — 실행 완료 여부 미확인
  > Firebase 콘솔 → verses → 임의 문서 열어 `question` 필드 있는지 확인
  > 없는 문서 많으면: `NODE_TLS_REJECT_UNAUTHORIZED=0 node generate_meditation_questions.js`

- [ ] **application 범용화** — 시간대 언급 제거
  > content-fixer 에이전트로 `application` 필드 시간대 표현 제거
  > 수정 후 `sync_verses.js`로 Firestore 동기화

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

## 🟡 코드 정리 (출시 후 가능)

- [ ] **AlarmStage1View.swift 정리**
  > Stage 1이 제거됐으나 파일 잔존. 상단에 `// DEPRECATED: Stage 1 removed 2026-04-26` 주석 추가 또는 삭제

- [ ] **앱 종료 시 선택 사운드 미반영 이슈**
  > 현재 앱이 완전 종료된 상태에서 오는 UNNotification은 항상 `alarm_song.mp3` 재생
  > (s01~s06 사용자 선택이 killed-state에서는 무시됨)
  > 개선하려면: LegacyAlarmEngine UNNotification 스케줄 시 선택한 mp3 파일명을 sound로 지정

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
- [x] **알람 사운드 6종 MP3** — 번들 포함 + pbxproj 등록 완료 ✅ (커밋 필요)
- [x] **SoundPickerSheet** — AlarmAddEditView 통합 완료 ✅ (커밋 필요)
- [x] **NSSupportsLiveActivities** — Info.plist 등록 ✅
- [x] **SKAdNetwork 30개** — Info.plist 등록 ✅
- [x] **UIBackgroundModes audio** — Info.plist 등록 ✅
- [x] **Firestore minimum_version 문서** — 스크립트로 생성 ✅
- [x] **자정 경계 마이그레이션** — Cloud Functions 00:00 KST ✅
