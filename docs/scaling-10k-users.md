# 1만 유저 단계적 확장 — 예상 문제 & 해결 과제

> 작성일: 2026-04-26
> 상태: 진행 중 (카테고리별 딥다이브)
> 기준: morning manna 현재 스택 (SwiftUI + Firebase + AlarmKit + AdMob + RevenueCat)

---

## 진행 현황

| # | 카테고리 | 상태 |
|---|----------|------|
| 1 | 📖 콘텐츠 | ✅ 완료 |
| 2 | 🖼 이미지 | ✅ 완료 |
| 3 | 🔥 Firebase / Firestore | ✅ 완료 |
| 4 | 📱 디바이스 / iOS 버전 | ✅ 완료 |
| 5 | 🔐 인증 / 계정 관리 | ✅ 완료 |
| 6 | ⏰ 알람 시스템 | ✅ 완료 |
| 7 | 💰 수익화 / 광고 | ✅ 완료 |
| 8 | 🚀 성능 / 속도 | ✅ 완료 |
| 9 | 📞 CS / 유저 응대 | ✅ 완료 |
| 10 | ⚖️ 법적 / 개인정보 | ✅ 완료 |
| 11 | 🏗 기술 부채 | ⬜ 대기 |
| 12 | 📊 모니터링 / 운영 | ⬜ 대기 |

---

## 1. 📖 콘텐츠 ✅ 완료 (2026-04-26)

### 딥다이브 결과

| 항목 | 시작 | 완료 후 |
|------|------|---------|
| verse_short_ko 위반 | 44건 | **0건** ✅ |
| question 없음 | 321건 | **0건** ✅ |
| 원어 표기 위반 | 0건 | **0건** ✅ |
| interpretation 위반 | 35건 | **4건** |
| application 위반 | 216건 | **9건** |
| 말투(설교조) | 2건 | **2건** (기도 인용구, 허용) |
| 위반 없는 말씀 | 18개 | **250개** (14배) |

### 완료된 작업
- `sync_verses.js` 범위 A:Z → A:AZ 확장 (question 필드 동기화 버그 수정)
- `question` 142개 생성 (`generate_meditation_questions.js`)
- `alarm_top_ko` 155개 생성 (`generate_alarm_top_ko.js`)
- `application` 41개 범용화 (Zone 시간대 언급 제거)
- `interpretation` 33개 글자수 조정
- 글자수 기준 현실화: verse_short_ko min 10자, verse_full_ko max 200자, question min 20자, alarm_top_ko min 10자
- `VerseSelector` zone 편향 버그 수정 (daily verse 전체 풀에서 선택)
- `contents-guideline.md` v9.1: interpretation 3단계, application 범용, 테마 풀 17개
- 모든 스크립트에 `preferRest: true` 적용 (gRPC TLS 우회)
- `package.json` npm scripts 정비 (19개 명령어)

### 남은 이슈 (낮은 우선순위)
- interpretation 4건 / application 9건: 글자수 미세 이탈 (수용 가능 수준)
- verse_full_ko 98건: 성경 원문이 200자 초과 (수정 불가)
- alarm_top_ko 34건: 35자 초과 (minor)
- 콘텐츠 신고 채널 미구현 (향후 기능)
- 절기 편성 12개 → 30개 확대 (향후 작업)

---

### 원래 문제 분석

| 문제 | 규모 | 대응 |
|------|------|------|
| **말씀 반복 노출** | active 398개 × cooldown 7일 = 56일 후 반복 시작. 매일 쓰는 유저는 2개월 내 동일 말씀 경험 | Zone별 최소 100개 이상 확보 목표. 특히 `deep_dark`, `peak_mode` 부족 구간 우선 보충 |
| **Zone별 분포 불균형** | 일부 Zone에 말씀이 편중되면 특정 시간대 유저가 반복 빠르게 경험 | Sheets `STATS` 탭에서 Zone별 active 수 주기적 모니터링 |
| **해석(interpretation) 품질 편차** | 유저가 많아질수록 신학적으로 문제 있는 표현 제보 증가 | `content-checker` QA 정기 실행 + 번영신학 위험 표현 flagging 강화 |
| **개역한글 출처 표기** | 앱 정보 섹션에 출처 표기 필요하나 미구현 시 법적 문제 | SettingsView 앱 정보 섹션에 "성경 본문: 개역한글, 대한성서공회" 고정 문구 추가 필수 |
| **절기 편성 누락** | 추석·설·부활절·성탄절 등 절기에 일반 말씀 노출 시 컨텍스트 부조화 | `daily_cards/` 연간 주요 절기 사전 등록. 현재 12개 → 30개 이상으로 확대 |
| **콘텐츠 신고 채널 부재** | 유저가 부적절한 말씀/해석 발견해도 신고할 곳 없음 | 말씀 상세 화면에 "신고하기" 버튼 추가 (이메일 딥링크라도) |

---

## 2. 🖼 이미지 ✅ 완료 (2026-04-27)

### 딥다이브 결과

| 항목 | 처리 내용 |
|------|---------|
| bright 톤 이미지 부족 | rise_ignite 6장 + peak_mode 8장 추가 (img_096~118) |
| peak_mode 이미지 7개→15개 | 8장 추가 완성 |
| recharge/second_wind 보강 | 각 5장, 4장 추가 |
| 날씨별 Zone 배경 0개 | rainy 16개 + snowy 8개 weather 필드 완성 |
| weather 필드 미설정 | 68개 전체 weather 컬럼 일괄 태깅 |
| 폴더 구조 혼재 | `image-assets/` 최상위 통합 (zone-backgrounds + verse-images) |
| Custom 출처 36개 | Genspark Commercial — 저작권 문제 없음 확인 |

### 완료된 작업
- 감성 이미지 91개 → **114개** (img_096~118, +23장)
- Zone 배경 weather 태깅: rainy 16개, snowy 8개, misty 6개, cloudy 3개
- snowy Zone 배경 8개 전 Zone 완성
- `image-assets/` 폴더 구조: zone-backgrounds(날씨 상위) + verse-images(Zone 상위)
- `.gitignore`: 이미지 파일 git 제외 (Firebase Storage에 원본)
- `sync_zone_backgrounds.js` 경로 업데이트

### 남은 이슈 (낮은 우선순위)
- deep_dark/first_light/golden_hour/wind_down 감성 이미지 추가 가능 (현재 충분)
- peak_mode/recharge snowy 배경 품질 개선 가능 (현재 통과)

---

### 원래 문제 분석

| 문제 | 규모 | 대응 |
|------|------|------|
| **이미지 풀 부족** | 현재 95개. 매일 앱 실행하면 3달 내 모든 이미지 반복 | 월 20~30장씩 지속 추가. Zone별 최소 15장 이상 |
| **Firebase Storage CDN 비용 급등** | 1만명 × 하루 3회 노출 × 1.5MB = 약 45GB/일 egress. 무료 한도 즉시 초과 | `ImageService`에 URL 캐싱 TTL 연장 (30분 → 24시간). 동일 이미지 반복 다운로드 방지 |
| **이미지 로드 실패 UX** | 느린 네트워크에서 배경 없이 텍스트만 노출되는 깨진 화면 | `RemoteImageView` fallback gradient 처리 + placeholder shimmer 개선 |
| **이미지 저작권** | Genspark Pro 상업적 사용 가능 확인됨. 단 약관 변경 시 리스크 | 분기별 Genspark 약관 확인. 중요 이미지는 CC0/자체 제작으로 교체 계획 |
| **업로드 파이프라인 병목** | 유저 수 늘면 이미지 수요 증가. 현재 수동 업로드 | `upload_design_test.js` 자동화 + 검수 프로세스 문서화 |

---

## 3. 🔥 Firebase / Firestore ✅ 완료 (2026-04-27)

### 딥다이브 결과

| 항목 | 처리 내용 |
|------|---------|
| Spark → Blaze 전환 | ✅ 이미 완료 |
| fetchVerses() 비용 (~$96/월) | ✅ 버전 기반 캐시 도입 → ~$2~3/월 |
| fetchImages() 비용 | 세션 내 캐시 유지 (cold start만 118 reads — 허용) |
| recent_verse_ids writes | 다음 말씀 버튼 없어 recordVerseShown() 미호출 — 비용 미미 |
| saved_verses 읽기 패턴 | 저장 수만큼 reads, 상세는 Core Data 우선 — 문제 없음 |
| Firestore 보안 규칙 | ✅ 이미 올바르게 설정됨 |

### 완료된 작업
- `VerseRepository.fetchVerses()` v7.0: 버전 체크(1 read) → Core Data → Firestore
- `FirestoreService.fetchRawContentVersion()` 추가
- `DailyCacheManager.loadAllCachedVerses()` 추가

### 예상 비용 (1만 유저)
- 이전: ~4,000,000 reads/일 → $96/월
- 이후: ~20,000 reads/일 → $2~3/월

---

### 원래 문제 분석

| 문제 | 규모 | 대응 |
|------|------|------|
| **Spark → Blaze 전환 시점** | 무료 한도: reads 50,000/일, writes 20,000/일. 1,000명만 돼도 즉시 초과 | 유저 1,000명 도달 전 Blaze 전환 |
| **예상 월 Firestore 비용** | 1만명 × 30회/일 × 30일 = 9,000만 reads = **$54/월**. Storage + writes 포함 $80~150/월 예상 | 앱 레벨 캐시 최대화로 Firestore 직접 읽기 최소화 |
| **`usage_count` 업데이트 비용** | 말씀 노출마다 write 발생. 1만명 × 3회/일 = 30,000 writes/일 | 즉시 write 대신 배치 업데이트 or Firebase Functions 활용 |
| **`recent_verse_ids` 배열 업데이트** | 유저별 최근 30개 ID 저장 → users/{uid} 잦은 업데이트 | 디바이스 로컬(UserDefaults) 저장 → 로그인 시만 Firestore 동기화 |
| **Firestore 보안 규칙** | 규칙 취약 시 데이터 무단 접근/수정 가능 | `saved_verses/{userId}`는 본인만 읽기/쓰기. `verses/`는 읽기만 허용 |
| **오프라인 처리** | 현재 번들 폴백 3개 구절만 존재 | Core Data 캐시 강화. Zone별 말씀 최소 1개씩 유지 |

---

## 4. 📱 디바이스 / iOS 버전 ✅ 완료 (2026-04-27)

### 딥다이브 결과

| 항목 | 처리 내용 |
|------|---------|
| iOS 26 AlarmKit API 안정성 | iOS 26 이미 정식 출시 (2025.09) → API 확정, 리스크 해소 |
| Legacy 앱 강제종료 시 알람 경고 | ✅ 저장 완료 후 iOS 15-25 기기에 경고 토스트 추가 |
| AlarmKit 권한 거부 팝업 | ✅ 권한 거부 시 경고 알럿 + 설정 앱 딥링크 추가 |
| Widget `#available` 가드 | ✅ `DailyVerseAlarmLiveActivity`에 `@available(iOS 26.0, *)` 추가 |
| 구형 기기 성능 테스트 | ⬜ human-todo 추가 (직접 테스트 필요) |

### 완료된 작업
- `AlarmViewModel.showSavedToast()`: iOS 15-25에서 알람 저장 시 "앱을 완전히 종료하면 알람이 울리지 않을 수 있어요" 토스트 3초 추가 표시
- `AlarmViewModel.saveAlarm()`: AlarmKit 권한 거부 시 `showAlarmKitDeniedAlert` 세팅
- `AlarmListView`: AlarmKit 권한 거부 알럿 + "설정 열기" 버튼 추가
- `DailyVerseWidgetsLiveActivity.swift`: `DailyVerseAlarmMetadata`, `DailyVerseAlarmLiveActivity`, `lockScreenView`에 `@available(iOS 26.0, *)` 추가
- `DailyVerseWidgetsBundle.swift`: `DailyVerseAlarmLiveActivity` 조건부 포함 (`if #available(iOS 26.0, *)`)

### 남은 이슈 (낮은 우선순위)
- iPhone XR(A12) 실기기 또는 Instruments 성능 테스트 미진행 → human-todo
- 다양한 노치/Dynamic Island 기기 시뮬레이터 테스트 필요

### 원래 문제 분석

| 문제 | 규모 | 대응 |
|------|------|------|
| **AlarmKit vs Legacy 분기 버그** | iOS 26+ / iOS 15-25 유저 혼재. 특정 버전에서만 알람 미작동 신고 | Crashlytics에 기기 모델 + iOS 버전 함께 로깅 |
| **iOS 26 AlarmKit API 변경** | iOS 26 이미 정식 출시 (2025.09) — 리스크 해소 | — |
| **구형 디바이스 성능 저하** | iPhone XR(iOS 16 최소 지원)에서 감성 이미지 + 애니메이션 버벅임 | Instruments 프로파일링. 애니메이션 조건부 비활성화 옵션 |
| **다양한 노치/레이아웃** | SafeArea 처리 미흡 시 특정 기기에서 UI 잘림 | iPhone SE·15 Pro Max·16 시뮬레이터 정기 테스트 |

---

## 5. 🔐 인증 / 계정 관리 ✅ 완료 (2026-04-27)

### 딥다이브 결과

| 항목 | 처리 내용 |
|------|---------|
| 이메일 로그인 dead code | ✅ `signUpWithEmail`, `signInWithEmail` 메서드 제거 (앱스토어 심사 리스크 해소) |
| Google 동일 이메일 충돌 | ✅ Firebase 에러 17012 → 친화적 에러 메시지 추가 |
| 말씀 저장 실패 토스트 | ✅ 이미 구현됨, 문구 통일 ("저장에 실패했어요. 다시 시도해주세요") |
| LoginPromptSheet 이메일 버튼 | ✅ 제거 (Google/Apple 2종만 표시) |
| Apple 버튼 가시성 | ✅ 흰색 배경 + 검정 텍스트 (명확하게 보임) |
| SavedView 빈 화면 로고 | ✅ DancingScript 텍스트 → `Image("LogoMMWhite")` 교체 |

### 완료된 작업
- `AuthManager.swift`: `signUpWithEmail`, `signInWithEmail` 제거
- `AuthManager.signInWithGoogle()`: Firebase 17012 에러 → "이미 다른 방법으로 가입된 이메일이에요" 메시지
- `HomeViewModel.swift`: 저장 실패 토스트 문구 통일
- `LoginPromptSheet.swift`: 이메일 버튼 제거, Apple 버튼 흰색 배경으로 가시성 개선
- `SavedView.swift`: 비로그인/빈 상태 로고를 `Image("LogoMMWhite")`로 교체 (두 곳)

### 남은 이슈 (낮은 우선순위)
- Apple Sign-In 정책 변경: Apple Developer 공지 모니터링 필요
- 탈퇴 후 재가입 시 이전 saved_verses 복구 불가: 탈퇴 전 경고 문구로 대응 중
- EmailAuthView.swift: LoginPromptSheet에서 분리됐으나 파일 자체 남아있음 → 심사 전 삭제 검토

### 원래 문제 분석

| 문제 | 규모 | 대응 |
|------|------|------|
| **Apple Sign-In 정책 변경** | Apple 요구사항 변경 시 앱 심사 거절 | Apple Developer 공지 구독 |
| **Google Sign-In 계정 연동 충돌** | Apple + Google 동일 이메일 → Firebase 17012 에러 | ✅ 친화적 에러 메시지 추가 |
| **탈퇴 후 재가입** | uid 바뀌므로 이전 saved_verses 복구 불가 | 탈퇴 전 경고 문구 강화 |
| **이메일 로그인 dead code** | 앱스토어 심사 거절 리스크 | ✅ 코드 제거 완료 |

---

## 6. ⏰ 알람 시스템 ✅ 완료 (2026-04-27)

### 딥다이브 결과

| 항목 | 처리 내용 |
|------|---------|
| 알람 배너 말씀 고착 | 허용 범위 (Stage2는 항상 최신 말씀 표시) |
| 저전력 모드 알람 미작동 | ✅ 경고 토스트 추가 — AlarmViewModel observer |
| 콘텐츠 업데이트 후 알람 재등록 | ✅ scenePhase.active 시 버전 변경 감지 → 자동 재등록 |
| UNNotification 64개 한도 추적 | ✅ schedule() 완료 후 콘솔 로그 (`📊 UNNotification 등록 개수: N/64`) |

### 완료된 작업
- `Notification+DailyVerse.swift`: `.dvLowPowerModeWarning` 추가
- `DailyVerseApp.swift`: `NSProcessInfoPowerStateDidChangeNotification` 감지 → `.dvLowPowerModeWarning` 포스트
- `DailyVerseApp.swift`: `scenePhase == .active` 시 `AlarmBackgroundService.shared.reregisterIfVersionChanged()` 호출
- `AlarmBackgroundService.reregisterIfVersionChanged()`: `cachedVerseContentVersion` 변경 감지 → 알람 알림 일괄 재등록
- `AlarmViewModel.init()`: `.dvLowPowerModeWarning` 수신 시 4초 경고 토스트
- `LegacyAlarmEngine.schedule()`: 등록 완료 후 `logPendingNotificationCount()` 호출 (Xcode 콘솔 전용)

### 남은 이슈 (낮은 우선순위)

| 문제 | 규모 | 대응 |
|------|------|------|
| **알람 미작동 신고** | 가장 많이 들어올 CS 이슈. 배터리 최적화·권한 설정 등 복합 원인 | FAQ에 자가진단 가이드 필수. 권한 체크 화면 개선 |
| **스누즈 엣지케이스** | 스누즈 3회 제한이 엣지케이스에서 무한 반복 가능성 | `snoozeCount` 검증 로직 단위 테스트 |
| **타임존 이슈** | 해외 교민 유저 발생 시 타임존 처리 오류 | 서버사이드 타임존 기록 추가 권장 |
| **알람 3개 제한 컴플레인** | "왜 3개밖에 못 만드나요?" CS 이슈 예상 | 제한 이유를 UI에 설명 문구로 추가 |

---

## 7. 💰 수익화 / 광고

| 문제 | 규모 | 대응 |
|------|------|------|
| **AdMob 정책 위반** | 광고 위치가 정책 위반 시 계정 정지 | AdMob Better Ads 가이드라인 확인. `AlarmAddEditView` 배너 위치 검토 |
| **ATT 팝업 미구현** | iOS 14.5+ 기기에서 IDFA 수집 시 반드시 필요. 미구현 시 심사 거절 + 광고 수익 감소 | `AppTrackingTransparency` 프레임워크 추가. 첫 실행 시 팝업 |
| **RevenueCat 비용** | 무료: MAU 10,000명까지. 초과 시 월 $199 | MAU 9,000명 도달 시 플랜 전환 준비 |
| **구독 환불 처리** | Apple 환불 후 앱 내 Premium 상태 유지 문제 | RevenueCat webhook → 즉시 `subscription_status` 업데이트 |
| **출시 전 isPremium 조건 복구** | 현재 모든 계정에 광고 표시 중 — 프리미엄 유저에게 광고 노출 시 구독 해지 유발 | `ad-placement.plan.md` TODO 5곳 복구 필수 |

---

## 8. 🚀 성능 / 속도

| 문제 | 규모 | 대응 |
|------|------|------|
| **앱 콜드 스타트 지연** | Firebase 초기화 + Firestore 쿼리 + 이미지 로드 겹치면 3초+ 지연 | 스플래시 동안 비동기 선처리. 캐시 히트 시 Firestore 쿼리 스킵 |
| **이미지 중복 다운로드** | 같은 이미지를 홈/알람/저장 탭에서 각각 다운로드 | NSCache 기반 인메모리 이미지 캐시 도입 |
| **Firestore 쿼리 최적화** | `verses/` 전체 읽기 시 비용·속도 문제 | Zone 필터 쿼리 + 인덱스 사전 생성 |
| **저장 그리드 스크롤 성능** | 저장 말씀 100개 이상 시 그리드 렌더링 버벅임 | 페이지네이션(20개씩) 도입 검토 |

---

## 9. 📞 CS / 유저 응대

| 문제 | 대응 |
|------|------|
| **응대 이메일 자동화** | Gmail 필터로 카테고리별 자동 분류. "알람 미작동", "구독 환불", "계정 탈퇴" FAQ 자동 답장 |
| **앱스토어 리뷰 관리** | 1~2점 리뷰에 24시간 내 공식 답글. `SKStoreReviewRequest` 타이밍 최적화 |
| **카카오채널 / 인스타DM** | 한국 유저는 이메일보다 카카오/인스타 문의 선호. 채널 개설 고려 |
| **알람 미작동 자가진단 가이드** | 설정 → 알림 → morning manna 허용 여부 등 단계별 가이드 |
| **강제 업데이트 메커니즘** | 치명적 버그 수정 시 구버전 강제 업데이트. 현재 미구현 |

---

## 10. ⚖️ 법적 / 개인정보

| 문제 | 대응 |
|------|------|
| **개인정보처리방침 미비** | 현재 `https://example.com/privacy` 플레이스홀더. 실제 URL 필수 (심사 거절 사유) |
| **이용약관 미비** | 동일하게 플레이스홀더. 법무 검토 후 실제 약관 페이지 개설 |
| **만 14세 미만 처리** | 앱 내 연령 확인 없음. 개인정보처리방침에 미성년자 조항 추가 |
| **위치정보 수집 고지** | WeatherKit 사용 시 위치정보 수집. `NSLocationWhenInUseUsageDescription` 문구 명확히 |
| **개역한글 출처 표기** | SettingsView 앱 정보 섹션에 "대한성서공회" 표기 고정 추가 |

---

## 11. 🏗 기술 부채

| 문제 | 대응 |
|------|------|
| **`AlarmStage1View.swift` 미사용 코드** | Stage 1 제거 후에도 파일 잔존 | 정리 또는 `// DEPRECATED` 명확히 표기 |
| **테스트 코드 부재** | `VerseSelector`, `DailyCacheManager` 핵심 로직에 단위 테스트 없음 | Sprint 7 계획대로 `DailyVerseTests/` 구현 |
| **Ad Unit ID 하드코딩** | 테스트 ID가 코드에 직접 박혀 있음 | `Secrets.xcconfig`에 Ad Unit ID 추가 |
| **`example.com` 플레이스홀더 URL** | 이용약관·개인정보처리방침·앱스토어 URL 모두 더미 | 배포 전 모두 실제 URL로 교체 |

---

## 12. 📊 모니터링 / 운영

| 구축 필요 항목 | 도구 |
|----------------|------|
| 크래시 실시간 알림 | Crashlytics + Slack webhook |
| DAU / 리텐션 추적 | Firebase Analytics 커스텀 이벤트 |
| 알람 발동률 추적 | `alarm_triggered` 이벤트 로깅 |
| Firestore 비용 모니터링 | Firebase 콘솔 예산 알림 ($50, $100 threshold) |
| 구독 전환율 추적 | RevenueCat Dashboard |
| 이미지 로드 실패율 | Firebase Performance Monitoring |

---

## 우선순위 요약

### 배포 전 반드시 (심사 거절 또는 법적 리스크)
- [ ] ATT 팝업 구현
- [ ] 개인정보처리방침 / 이용약관 실제 URL
- [ ] 개역한글 출처 표기 (SettingsView)
- [ ] isPremium 광고 조건 복구 (5곳)
- [ ] Ad Unit ID → Secrets.xcconfig 이동

### DAU 1,000명 전
- [ ] Firebase Blaze 플랜 전환
- [ ] Firestore 예산 알림 설정
- [ ] 이미지 캐시 최적화
- [ ] 강제 업데이트 메커니즘

### DAU 5,000명 전
- [ ] `usage_count` 로컬 캐시 + 배치 업데이트
- [ ] `recent_verse_ids` UserDefaults 이전
- [ ] CS 자동응대 채널
- [ ] 말씀 Zone별 100개 이상 확보
