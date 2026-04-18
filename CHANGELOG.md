# DailyVerse 변경 로그

> 모든 커밋이 아닌 **주요 아키텍처 결정**과 **중요 발견사항**만 기록.
> "무엇을 했는가"가 아닌 "왜 그렇게 결정했는가" 중심.

---

## 2026-04-18

### AlarmKit 잠금화면 알람 시스템 완성 (iOS 26)

**결정**: `UNNotification` → `AlarmKit` + `ActivityKit` 듀얼 엔진 전환

**배경**: 사용자가 알라미처럼 잠금화면에서 전체화면 알람 + Face ID 자동 앱 오픈을 원함.

**핵심 발견사항**:
- `ForegroundContinuableIntent` + `requestToContinueInForeground()`는 "요청"이라 잠금화면에서 거부 가능 → **`supportedModes: .foreground(.immediate)`가 정답** (강제)
- Live Activity `Activity.request()`는 백그라운드(StopIntent)에서 불가 → **알람 등록 시점(포그라운드)에서 미리 시작**해야 함
- `DVPostAlarmAttributes`를 앱과 Widget Extension이 공유하려면 **같은 소스 파일을 양쪽 타겟에 포함** 필수 (모듈명이 다르면 ActivityKit이 다른 타입으로 인식)
- `NSSupportsLiveActivities` Info.plist 없으면 `Activity.request()` 에러 없이 silently fail
- Widget Extension의 `Info.plist`에 `CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)` 없으면 "bundle identifier not prefixed" 빌드 에러

**AlarmKit SDK API 확인 (헤더 직접 읽음)**:
- `Alarm.ID` = `Foundation.UUID` typealias (별도 타입 아님)
- 스누즈 작동: `AlarmManager.AlarmConfiguration(countdownDuration:)` init 직접 사용 + `countdownDuration.postAlert` 지정 필수 (`.alarm()` static에는 파라미터 없음)
- `AlarmPresentation.Alert.stopButton` = iOS 26.1 deprecated
- 커스텀 알람 사운드: `AlertConfiguration.AlertSound.named("alarm_song.mp3")`

---

### SwiftUI safeAreaInset 자동실행 버그 발견 및 수정

**증상**: Stage2가 열리자마자 자동으로 닫힘 (`stage2 → none` 로그)

**원인**: SwiftUI가 `safeAreaInset` 내 버튼의 액션을 뷰 전환 애니메이션 중 자동 실행

**해결**: `dismissAll()`에 2초 타임가드 (`stageSetAt` 기반) — SwiftUI 자동실행은 ms 단위, 사용자 탭은 2초+ 후

---

### 온보딩 Stage2 표시 순서 버그 수정

**증상**: 앱 첫 실행 시 온보딩 전에 Stage2가 먼저 표시됨

**원인**: `AlarmCoordinator.init()`에서 `pendingAlarmKitStop`을 처리할 때 `onboardingCompleted`가 아직 미확정 상태 (Firebase Auth 비동기)

**해결**: pending 처리를 `AppRootView.task`로 이동 — `loadingCoordinator.start()` 완료 후 `onboardingCompleted` 확정된 시점에 처리

---

### AlarmBackgroundService 타이밍 충돌 수정

**증상**: AlarmKit 알람 발동 후 `stage = .stage1`이 자동 세팅되어 Stage2 전환 차단

**원인**: `AlarmViewModel.saveAlarm()`이 iOS 26에서도 `AlarmBackgroundService.rescheduleTimers()`를 호출 → 타이머가 등록되어 알람 시각에 `dvAlarmTriggered` 포스팅 → `stage = .stage1` 세팅

**해결**: `rescheduleTimers()`에 `if #available(iOS 26.0, *) { return }` 가드 추가

---

## 2026-04-15

### 콘텐츠 시스템 v9.0 — 개역한글 원문 전환

**결정**: 모든 말씀을 개역한글(1961, 퍼블릭 도메인)로 통일

**배경**: 저작권 리스크 제거. 2011년 저작권 만료로 자유롭게 사용 가능.

**변경**: `verse_full_ko`, `verse_short_ko` → 개역한글 원문 기반으로 전면 교체. `update_to_korv.js` 스크립트 사용.

---

### Zone 시스템 8개 세분화

**결정**: 기존 3모드(아침/낮/저녁) → 8-Zone (deepDark, firstLight, riseIgnite, peakMode, recharge, secondWind, goldenHour, windDown)

**배경**: 하루 8개 시간대별로 다른 감성과 말씀 테마가 필요.

---

## 2026-04-10

### 하루 1개 말씀 통일 정책

**결정**: Zone별 다른 말씀 → 하루 1개 말씀을 모든 탭(홈/묵상/알람)에서 동일하게

**배경**: 사용자가 아침에 본 말씀을 저녁에도 동일하게 묵상할 수 있어야 함. 일관성 확보.

**구현**: `DailyCacheManager.getTodayVerseId()` → 모든 Zone에서 동일한 `todayVerseId` 반환

---

## 2026-04-09

### 온보딩 v2.0 — 4화면 리디자인

**변경**: 5화면 → 4화면 (위치/알림 권한 별도 화면 제거)
- Screen 1: 공감 (Before/After 알람 애니메이션)
- Screen 2: 닉네임 입력
- Screen 3: 체험 (Stage1/2 시뮬레이션)
- Screen 4: 알람 설정 + 권한 요청

---

## 알려진 미해결 이슈 / 향후 작업

- Live Activity 잠금화면 권한: 온보딩에서 자연스럽게 요청하는 방법 개선 필요 (현재: 첫 알람 등록 시 자동 팝업)
- iOS 15-25 백그라운드 서비스: 앱 완전 종료 시 알람 100% 보장 불가 (iOS 원천 한계)
- 콘텐츠: peak_mode, recharge, second_wind Zone 이미지 부족 (각 7개 미만)
- RevenueCat API Key: 현재 유효하지 않음 (테스트 환경)
