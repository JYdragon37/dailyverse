# DailyVerse 변경 로그

> 모든 커밋이 아닌 **주요 아키텍처 결정**과 **중요 발견사항**만 기록.
> "무엇을 했는가"가 아닌 "왜 그렇게 결정했는가" 중심.

---

## 2026-04-26

### AlarmStage1 제거 — iOS 15-25도 Stage2 직행

**결정**: Legacy(iOS 15-25)에서도 Stage1(전체화면 알람)을 건너뛰고 Stage2(웰컴 스크린)로 직행

**이유**: Stage1과 Stage2가 기능적으로 중복. Stage2 한 화면에 통합하는 것이 UX 단순화.

**핵심 발견**: `AppLoadingCoordinator.fetchBackgroundImages()`가 이미 `randomElement()`로 다중 이미지를 선택하도록 구현되어 있었음 → Stage1을 지우고 Stage2에 스누즈 버튼을 추가하는 것만으로 완전 대체 가능.

**변경**:
- `AlarmCoordinator.AlarmStage` 에서 `stage1` 케이스 제거
- `handleNotification()` guard: `stage == .none || stage == .stage1` → `stage == .none`
- `AppRootView`: Stage1 렌더링 블록 제거
- `AlarmStage2View`: 스누즈 버튼 추가 (`canSnooze` false 시 비활성), "말씀 깊게 보기 ^" 힌트 추가

---

### Zone 배경 다중 지원 + 날씨별 배경 (v7.0)

**결정**: Zone 배경을 Zone당 1개 고정 → Zone당 N개 + 날씨별 선택

**핵심 발견**: 앱 코드(`AppLoadingCoordinator`)가 이미 `fetchBackgroundImages()` → `randomElement()`로 다중 이미지를 지원하도록 구현되어 있었음. **앱 코드 수정 0줄**으로 데이터만 추가하면 됐음.

**변경**:
- Firestore 문서 ID: `bg_{zone_id}` 고정 → `bg_{zone_id}_{설명}` (복수 허용)
- `BackgroundImage` 모델: `weather` 필드 추가 (all/sunny/rainy/snowy/misty/cloudy)
- `sync_zone_backgrounds.js` v7.0: 파일명에서 zone_id·weather 자동 파싱
- 이미지 현황: 8개 → 20개 active

---

### 이미지 업로드 워크플로우 표준화

**결정**: 임의 폴더/스크립트 → `design_test/` 폴더 + 커맨드 파일 2개로 통일

**배경**: 이미지 업로드 흐름이 복잡하고 규칙이 없어 오류 발생. 검수→리네임→업로드→삭제 전 단계를 하나의 워크플로우로 묶어야 함.

**구조**:
- `🔍 이미지 검수.command`: "검수해줘" 클립보드 복사 → Claude AI 검수+리네임
- `🖼️ 이미지 업로드.command`: design_test/ → Storage + Sheets + Firestore + 삭제
- `zone-image-inspector` 에이전트 v2.0: 검수 + 리네임 통합, design_test/ 기본값
- 파일명 규칙: `bg_*`(Zone 배경) / `img_*`(감성) / `dc_img_*`(절기) 자동 분류

---

### daily_cards 이미지 1:N 지원

**결정**: `image_id: String?` → `image_ids: [String]` (풀에서 앱이 랜덤 선택)

**설계 원칙**:
- 말씀(`verse_id`): 편집자 확정 1개 → 전체 유저 동일 (공동체 경험)
- 이미지(`image_ids`): 풀에서 앱이 랜덤 → 유저마다 달라도 무방
- Zone 배경: 절기일에도 변경 안 됨

**추가**: `daily_card_images/` Firestore 컬렉션 신설 (`DAILY_CARDS_IMAGES` Sheets 탭, `dc_img_*` 파일 prefix)

**핵심 발견**: `DailyCard.imageId`가 코드에 정의만 되어 있고 실제 어디서도 사용되지 않았음 (완전 미구현 상태). 이번에 `HomeViewModel.loadImage()` + `AlarmCoordinator.loadImage()` 두 곳에 처음으로 연결함.

---

### 묵상 달력 절기일 뱃지

**결정**: daily_cards 등록 날짜에 달력 셀 우상단 ★ 뱃지 표시 (묵상 여부 무관)

**구현**:
- `FirestoreService.fetchHolidayDates(from:to:)`: 날짜 범위 쿼리 → active 절기일 Set 반환
- `MeditationViewModel.holidayDates`: 28일 윈도우 로드
- `DevotionDayDotCell`: `isHoliday` 파라미터 추가, 금색 ★ 뱃지 + 날짜 숫자 골드 강조

---

### 보안 전면 개선 (7개 항목)

**결정**: App Store 출시 전 보안 취약점 일괄 해소

**주요 결정 근거**:

1. **ATS 비활성화 제거**: `NSAllowsArbitraryLoads = true`는 App Store 심사 거절 사유. HTTPS가 이미 모든 외부 API에서 지원되므로 즉시 제거 가능.

2. **API 키 xcconfig 분리**: Info.plist에 하드코딩 = IPA 파일에서 3초 만에 추출 가능. `.gitignore`에 Secrets.xcconfig 등록하고 Xcode xcconfig 시스템 활용.

3. **Firestore Security Rules**: 파일이 없었고 Firebase 콘솔에만 존재 → 버전 관리 불가. `firestore.rules`/`storage.rules` 파일 생성 후 서비스 계정 REST API로 직접 배포.

4. **탈퇴 시 완전 삭제**: `meditation_logs/{uid}` 서브컬렉션이 미삭제 상태였음 → 개인정보보호법 위반 가능. 삭제 순서 중요: 하위 문서 → 부모 문서 순서.

5. **Rate Limiting**: 클라이언트가 `verses/{id}.show_count`를 직접 업데이트 → 무제한 호출로 비용 급증·통계 조작 가능. 5분 쿨다운으로 방어.

6. **SecureStorage**: 묵상 기도·감사를 UserDefaults에 저장하면 iCloud 백업에 포함. `isExcludedFromBackup = true` 디렉토리에 별도 저장.

7. **CryptoKit 암호화 extension**: 기도·감사 필드 AES-GCM 암호화. 기존 평문 데이터 하위 호환 보장 (복호화 실패 시 원문 반환).

**핵심 발견**: Xcode가 열려 있는 동안 외부에서 `project.pbxproj`를 수정하면 Xcode가 자기 버전으로 즉시 덮어씀 → Xcode 종료 후 수정, 또는 Xcode GUI에서 직접 설정이 유일한 방법.

---

### 스프레드시트 구조 전면 개편

**결정**: 탭 18개 → 20개, 기능별 그룹+색상 분리, 수식 자동화

**변경**:
- 탭 그룹: 개요(회색)·데이터(초록)·분석(주황)·가이드(파랑)·로그(빨강)
- OVERVIEW 탭 신설 (맨 왼쪽)
- ZONE_GUIDE 탭 신설 (TAG_GUIDE에서 분리)
- STATS: 하드코딩 → 수식 기반 자동화 (데이터 탭 실시간 참조)
- 이미지 탭 미리보기 열 (IMAGE() 수식) + 행 높이 120px

---

## 알려진 미해결 이슈 업데이트 (2026-04-26)

- ~~콘텐츠: peak_mode, recharge, second_wind Zone 이미지 부족~~ → 해소 (감성 이미지 95개로 증가)
- 묵상 암호화: `MeditationEntry` extension 추가됐으나 실제 `save()/fetch()` 호출 지점에 `encrypt/decrypt` 연결 필요 (현재 미적용)
- OpenWeatherMap API 키: Bundle ID 제한 설정 권장 (OWM 대시보드에서 수동 설정 필요)

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
- ~~콘텐츠: peak_mode, recharge, second_wind Zone 이미지 부족~~ → 2026-04-26 해소
- RevenueCat API Key: 현재 유효하지 않음 (테스트 환경)
