# DailyVerse — 프로젝트 전체 컨텍스트

> 이 파일은 DailyVerse 프로젝트의 단일 진실 원본(Single Source of Truth)입니다.
> 어떤 LLM이든 이 파일 하나를 읽으면 전체 프로젝트를 즉시 파악할 수 있도록 작성되었습니다.
> 최종 업데이트: 2026-04-11 (PRD v4.0 + 화면 설계 v1.1 기준)

---

## 1. 제품 개요

**DailyVerse**는 크리스천을 위한 iOS 알람 앱이다.
기존 알람의 기계적인 경험에 성경 말씀·감성 이미지·실시간 날씨를 결합하여,
이미 습관화된 "알람 확인" 행동에 영적 루틴을 자연스럽게 얹는다.

- **슬로건**: 하루의 끝과 시작을 경건하게
- **핵심 철학**: 알람 중심 설계. 별도 앱 진입 장벽 최소화. 하루 3번 자연스럽게 말씀 접촉.
- **플랫폼**: iOS 16+ (iPhone 전용, MVP)
- **버전**: v1.0 MVP
- **개발 방식**: Claude Code + SwiftUI

---

## 2. 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| UI | SwiftUI | iOS 16+, Swift 5.9 |
| 백엔드 | Firebase Firestore | 말씀/이미지/유저 데이터 |
| 인증 | Firebase Auth | Apple Sign-In 전용 |
| 스토리지 | Firebase Storage | 감성 이미지 CDN |
| 분석 | Firebase Analytics + Crashlytics | |
| 날씨 | WeatherKit (1차) + OpenWeatherMap (폴백) | 월 50,000콜 무료 |
| 결제 | StoreKit 2 + RevenueCat | ₩24,500/월 |
| 광고 | AdMob Rewarded | 저장탭 7~30일 구간 |
| 로컬 캐시 | Core Data | 오프라인 캐시 |
| 개발 도구 | Claude Code + Cursor | |

### SPM 패키지
```
- firebase-ios-sdk (11.x) — Firebase/Auth, Firebase/Firestore, Firebase/Storage, Firebase/Analytics, Firebase/Crashlytics
- google-mobile-ads-swift (11.x) — AdMob
- purchases-ios (5.x) — RevenueCat
```

---

## 3. 아키텍처: MVVM + Clean Architecture

### 레이어 정의
```
View (SwiftUI)
  ↓ observes
ViewModel (@MainActor, ObservableObject)
  ↓ calls
Service/Repository (protocol-based)
  ↓ uses
Firebase / Core Data / WeatherKit / StoreKit
```

### 의존성 주입 규칙
- `@EnvironmentObject`: 앱 전역 상태 (AuthManager, SubscriptionManager, PermissionManager)
- `@StateObject`: 뷰 소유 ViewModel
- `@ObservedObject`: 부모로부터 주입받는 ViewModel
- 모든 서비스는 프로토콜로 추상화 → 테스트 용이성 확보

### 폴더 구조
```
DailyVerse/
├── App/
│   ├── DailyVerseApp.swift          # @main, Firebase init
│   ├── AppRootView.swift            # 온보딩/홈 분기
│   └── AppDelegate.swift            # UNUserNotificationCenterDelegate
│
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift
│   │   ├── OnboardingWelcomeView.swift
│   │   ├── OnboardingFirstVerseView.swift
│   │   ├── OnboardingLocationView.swift
│   │   ├── OnboardingNotificationView.swift
│   │   ├── OnboardingFirstAlarmView.swift
│   │   └── OnboardingViewModel.swift
│   │
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── VerseCardView.swift
│   │   ├── WeatherWidgetView.swift
│   │   └── CoachMarkOverlay.swift
│   │
│   ├── Alarm/
│   │   ├── AlarmListView.swift
│   │   ├── AlarmViewModel.swift
│   │   ├── AlarmAddEditView.swift
│   │   ├── AlarmStage1View.swift    # 전체화면 알람
│   │   └── AlarmStage2View.swift   # 웰컴 스크린
│   │
│   ├── Saved/
│   │   ├── SavedView.swift
│   │   ├── SavedViewModel.swift
│   │   └── SavedDetailView.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
│
├── Common/
│   ├── Components/
│   │   ├── VerseDetailBottomSheet.swift
│   │   ├── UpsellBottomSheet.swift
│   │   ├── LoginPromptSheet.swift
│   │   └── ToastView.swift
│   └── Extensions/
│       ├── Color+DailyVerse.swift
│       ├── Font+DailyVerse.swift
│       └── Animation+DailyVerse.swift
│
└── Core/
    ├── Models/
    │   ├── Verse.swift
    │   ├── VerseImage.swift
    │   ├── Alarm.swift
    │   ├── User.swift
    │   ├── SavedVerse.swift
    │   ├── DailyVerseCache.swift
    │   └── WeatherData.swift
    ├── Services/
    │   ├── FirestoreService.swift
    │   ├── AuthService.swift
    │   ├── WeatherService.swift
    │   ├── NotificationManager.swift
    │   └── ImageService.swift
    ├── Managers/
    │   ├── AuthManager.swift            # @EnvironmentObject
    │   ├── SubscriptionManager.swift    # @EnvironmentObject
    │   ├── PermissionManager.swift      # @EnvironmentObject
    │   ├── UpsellManager.swift
    │   └── DailyCacheManager.swift
    ├── Repositories/
    │   ├── VerseRepository.swift
    │   ├── AlarmRepository.swift
    │   └── SavedVerseRepository.swift
    └── Persistence/
        ├── PersistenceController.swift  # Core Data stack
        └── DailyVerse.xcdatamodeld
```

---

## 4. 앱 전체 구조

```
DailyVerse
├── 온보딩 (최초 1회)
│   ├── Screen 1: 웰컴 스크린
│   ├── Screen 2: 첫 말씀 경험 (가치 증명)
│   ├── Screen 3: 위치 권한 요청
│   ├── Screen 4: 알림 권한 요청
│   └── Screen 5: 첫 알람 설정 유도
│
├── 메인 앱 (TabView — 4탭)
│   ├── 탭 1: Home (집 아이콘)
│   ├── 탭 2: Alarm (알람 아이콘)
│   ├── 탭 3: Saved (즐겨찾기 아이콘)
│   └── 탭 4: Settings (설정 아이콘)
│
└── 모달 / 오버레이
    ├── 알람 울림 Stage 0 (잠금화면 알림 배너)
    ├── 알람 울림 Stage 1 (앱 진입 전체화면)
    ├── 알람 울림 Stage 2 (웰컴 스크린)
    ├── 말씀 상세 바텀시트
    ├── 업셀 바텀시트
    ├── 로그인 유도 바텀시트
    └── 광고 시청 모달 (AdMob Rewarded)
```

---

## 5. Home 탭 — 3모드 자동 전환

### 모드 시간대
| 모드 | 시간대 | 인사말 | 테마 | 날씨 표시 |
|------|--------|--------|------|-----------|
| 아침 | 05:00–12:00 | Good Morning ☀️ | hope, courage, strength, renewal | 현재 날씨 |
| 낮   | 12:00–20:00 | Good Afternoon 🌤 | wisdom, focus, patience, gratitude | 현재 날씨 |
| 저녁 | 20:00–05:00 | Good Evening 🌙 | peace, comfort, reflection, rest | 현재 + 내일 아침 예보 |

### 모드 전환 규칙
- 시간대에 따라 레이아웃 구조는 동일, 콘텐츠·이미지 톤만 자동으로 바뀐다
- 모드 전환 애니메이션: Cross-dissolve 1.0s
- 각 모드의 말씀은 해당 모드 **최초 진입 시 결정**되며 **하루 동안 고정**
- 자정(05:00 기준)에 새로운 말씀 배정
- Free 유저: 모드당 말씀 1개 제공
- Premium 유저: [다음 말씀] 버튼으로 무제한 탭마다 새 말씀

### Home 화면 구성 요소
```
[감성 이미지 — 풀스크린 배경]
│
├── 인사말 + 시간 (Good Morning / 06:32 AM)
│
├── 말씀 카드 (탭 → 상세 바텀시트)
│   ├── 말씀 텍스트 (text_ko)
│   ├── 성경 참조 (이사야 41:10)
│   └── 테마 태그 (Hope ▸)
│
├── 날씨 위젯
│   ├── 도시명 + 온도
│   ├── 습도 + 미세먼지 등급
│   └── (저녁) 내일 아침 예보
│
└── [+ 알람 설정하기] CTA (알람 0개일 때 3일간 표시)
```

### 말씀 카드 확장 바텀시트
```
[말씀 전체 텍스트 (text_full_ko)]
[해석 (interpretation)]
[일상 적용 (application)]
[이사야 41:10]
[저장 ♥] [다음 말씀] [×]
── Premium ──────────────
[테마 변경: Hope ▼] (Premium only)
```

---

## 6. 알람 탭

### 알람 목록
- 최대 3개 알람
- 각 카드: 시간, 반복 요일, 주제(테마), ON/OFF 토글
- 스와이프 삭제 + 3초간 [되돌리기]
- [+ 새 알람 추가] 버튼 (3개 초과 시 비활성화)

### 알람 추가/수정 모달
```
시간: [TimePicker — 06:00 AM]
반복: [월][화][수][목][금][토][일] (기본: 전체 선택 = 매일)
주제: [Hope ▼] ← Free: 🔒 자동 배분 / Premium: 자유 선택
말씀 미리보기: ["두려워하지 말라..." / 이사야 41:10]
[저장하기]
```

요일 선택 요약: 전체→"매일", 평일→"주중", 주말→"주말", 특정→나열, 미선택→저장 비활성화

저장 완료 토스트: `"✅ 내일 {HH:mm}, 말씀이 함께 올릴 거예요"` (2초 표시)

### Free 자동 테마 배분 로직
- 알람 시간대 기반 테마 풀에서 최근 7일 내 표시된 테마를 제외
- 나머지 중 랜덤 선택
- 각 알람(최대 3개)은 독립적인 히스토리를 가짐

---

## 7. 알람 울림 UX — 3단계

### Stage 0 — 잠금화면 알림 배너
앱이 백그라운드/종료 상태에서 알람 발동 시, UNNotificationCenter를 통해 말씀 텍스트 포함 배너를 표시.
유저가 앱을 열기 전에 이미 말씀을 만나는 첫 번째 접점.

```swift
let content = UNMutableNotificationContent()
content.title = "DailyVerse 🔔"
content.body = "\"두려워하지 말라 내가 너와 함께 함이라\"\n이사야 41:10 • Hope"
content.sound = UNNotificationSound.default
content.userInfo = ["verse_id": "v_001", "mode": "morning"]
```

### Stage 1 — 앱 진입 전체화면
배너 탭 시 앱이 전체화면으로 전환. **TabBar·NavigationBar 완전 숨김**.
설계 원칙: 말씀 외에 아무것도 없어야 한다.

```
[다크 그라데이션 풀스크린 배경]
│
├── 말씀 텍스트 (대형, 중앙)
│   "두려워하지 말라
│    내가 너와 함께 함이라"
│   이사야 41:10
│
└── 하단 버튼
    [🔄 스누즈 5분] | [종료]
```

- 스누즈: 최대 3회 제한. 3회 초과 시 버튼 비활성화 + "더 이상 스누즈할 수 없어요 🔒"
- 스누즈 탭: 5분 후 알람 재스케줄링 후 백그라운드 복귀
- 종료 탭: Stage 2로 Fade-in 0.6s 전환
- 포그라운드 상태: willPresent 델리게이트로 배너 없이 Stage 1 오버레이 즉시 표시

### Stage 2 — 웰컴 스크린
[종료] 탭 후 0.6초 Fade-in으로 전환. 말씀 + 날씨 + 저장/다음 말씀 액션이 한 화면에 담긴다.

```
[감성 이미지 풀스크린]
│
├── Good Morning ☀️
│   2026년 3월 31일 화요일
│
├── 말씀 카드
│   "두려워하지 말라 내가 너와 함께 함이라"
│   이사야 41:10 · Hope
│
├── 날씨 위젯
│   서울 18°C · 습도 65% · 좋음
│
└── [♥저장] [다음 말씀] [× 닫기]
```

[× 닫기] 탭 시 홈 탭(현재 모드)으로 이동하며 TabBar 다시 노출.

### 알람 울림 엣지케이스
| 상황 | 처리 방식 |
|------|-----------|
| 알람 탭 없이 swipe dismiss | 말씀 경험 없이 넘어감, 다음 알람 정상 발동 |
| 알람 발동 시 인터넷 없음 | Core Data 캐시 말씀으로 Stage 1, 2 정상 작동 |
| 스누즈 중 앱 강제 종료 | UNNotificationRequest 재스케줄링으로 5분 후 유지 |
| Stage 2 [다음 말씀] — Free | 업셀 바텀시트 노출 |
| Stage 2 [♥ 저장] — 미로그인 | 로그인 유도 바텀시트 노출 |
| 복수 알람 동시 발동 | 가장 최근 알람 1개만 Stage 1 표시 |

---

## 8. Saved 탭 — 3단계 접근 모델

| 기간 | Free 접근 | Premium 접근 |
|------|-----------|--------------|
| 0~7일 | ✅ 자유 열람 | ✅ 자유 열람 |
| 7~30일 | 광고 시청 후 열람 | ✅ 자유 열람 |
| 30일 초과 | ❌ 잠금 | ✅ 자유 열람 |

- 2열 그리드, 최신순 정렬
- 광고 잠금 카드: 흐림 처리 + "광고 시청 후 열람하기 ▶"
- Premium 잠금 카드: 🔒 아이콘 + "Premium에서 전체 아카이브를 만나보세요" + [Premium 시작하기]

### 빈 상태 (Empty State) 3가지
1. 비로그인: 북마크 아이콘 + "말씀을 저장하려면 로그인이 필요해요" + [Apple로 시작하기]
2. 로그인 후 저장 없음: 하트 아이콘 + "아직 저장된 말씀이 없어요" + [홈으로 가기]
3. Free 유저 30일 초과만 남음: "지난 말씀을 모두 보고 싶으신가요?" + [Premium 시작하기]

### 카드 상세 화면
```
[감성 이미지 풀스크린] [×]
│
├── "두려워하지 말라 내가 너와 함께 함이라"
│   이사야 41:10
│
├── 📅 2026.03.27  07:12  아침
│   ☁️ 18°C  💧 65%  📋 좋음
│   📍 서울 강남구
│
└── [♥저장 해제] [공유]
```

---

## 9. Settings 탭

### 섹션 구성
1. **계정**: Apple ID, 로그아웃, 계정 탈퇴(빨간색)
2. **구독**: 현재 플랜, [✨ Premium 시작하기 / ₩24,500/월], 플랜 비교
3. **권한**: 위치 허용 상태 + [재설정], 알림 허용 상태 + [재설정]
4. **앱 정보**: 버전, 이용약관, 개인정보처리방침, 오픈소스 라이선스
5. **피드백**: [⭐ 앱 리뷰 남기기], [📨 문의하기]

### 계정 탈퇴 플로우 (4단계)
1. 경고 바텀시트 표시 ("구독 중이면 App Store에서 별도 해지 필요" 안내)
2. Apple Sign-In 재인증
3. Firestore `users/{uid}` + `saved_verses/{uid}` 삭제, Firebase Auth 삭제, RevenueCat logOut()
4. UserDefaults 초기화 후 온보딩 첫 화면으로 이동

---

## 10. 온보딩 플로우

**핵심 원칙**: 가치 먼저, 권한 나중. 말씀 경험을 먼저 제공하고, 권한은 그 이후 요청.

| 화면 | 내용 | 액션 |
|------|------|------|
| Screen 1 웰컴 | 풀스크린 감성 이미지 + "하루의 끝과 시작을 경건하게" | [시작하기 →] |
| Screen 2 첫 말씀 | 이사야 41:10 샘플 말씀 카드 체험 | [다음 →] |
| Screen 3 위치 권한 | 📍 "날씨에 맞는 말씀을 전해드릴게요" | [위치 허용하기] / [나중에] |
| Screen 4 알림 권한 | 🔔 "알람이 울릴 때 말씀이 함께 옵니다" | [알림 허용하기] / [나중에] |
| Screen 5 첫 알람 | 아침 06:00 + 저녁 22:00 카드 | [설정하기] / [건너뛰기] |

### UserDefaults 관리 키 (4개)
```swift
"onboardingCompleted"              // Bool
"locationPermissionRequested"      // Bool
"notificationPermissionRequested"  // Bool
"firstAlarmPromptShown"            // Bool
```

스킵 처리: 최대 3회 스킵 누적 시 강제 완료 처리. 다음 앱 진입 시 스킵 지점부터 재개.

---

## 11. 앱 실행 & 로딩 플로우

```
Stage 1: 스플래시 (0.8초, 로고 fade-in 0.3초)
Stage 2: 데이터 로드
  ├── 유효 캐시(30분 이내) 있음 → 스켈레톤 없이 바로 홈
  ├── 캐시 없음 + 인터넷 있음 → 스켈레톤 표시 → Firebase 로드 → 홈
  └── 캐시 없음 + 오프라인 → 번들 폴백 3개 구절로 홈 렌더링 + 토스트 "오프라인 상태입니다. 저장된 말씀을 표시해요"
Stage 3: 온보딩 완료 여부 확인
  ├── 미완료 → 온보딩
  └── 완료 → 홈 탭
```

---

## 12. 데이터 모델

### Verse (성경 말씀)
```swift
struct Verse: Identifiable, Codable {
    let id: String              // verse_id (예: "v_001")
    let textKo: String          // 핵심 요약 구절 (카드 표시용)
    let textFullKo: String      // 전체 구절 (바텀시트 표시용)
    let reference: String       // "이사야 41:10"
    let book: String            // "이사야"
    let chapter: Int            // 41
    let verse: Int              // 10
    let mode: [String]          // ["morning"] 또는 ["all"]
    let theme: [String]         // ["hope", "courage"]
    let mood: [String]          // ["bright", "dramatic"]
    let season: [String]        // ["all"]
    let weather: [String]       // ["any"]
    let interpretation: String  // 말씀 의미 해석
    let application: String     // 일상 적용
    let curated: Bool           // 신학 검수 완료 여부
    let status: String          // "active" | "draft" | "inactive"
    let usageCount: Int
}
```

### VerseImage (감성 이미지)
```swift
struct VerseImage: Identifiable, Codable {
    let id: String              // "img_001"
    let filename: String        // "morning_mountain_sunrise.jpg"
    let storageUrl: String      // Firebase Storage URL
    let source: String          // "Unsplash"
    let license: String         // "CC0"
    let mode: [String]          // ["morning"]
    let theme: [String]         // ["hope", "renewal"]
    let mood: [String]          // ["bright", "dramatic"]
    let season: [String]        // ["spring", "summer"]
    let weather: [String]       // ["sunny"]
    let tone: String            // "bright" | "mid" | "dark"
    let status: String          // "active" | "draft"
}
```

### Alarm
```swift
struct Alarm: Identifiable, Codable {
    let id: UUID
    var time: Date              // 알람 시간
    var repeatDays: [Int]       // 0=일, 1=월 ... 6=토
    var theme: String           // "hope", "courage", etc.
    var isEnabled: Bool
    var snoozeCount: Int        // 현재 스누즈 횟수 (최대 3)
}
```

### DailyVerseCache
```swift
struct DailyVerseCache: Codable {
    let date: Date              // 캐시 날짜 (05:00 기준)
    var morningVerseId: String?
    var afternoonVerseId: String?
    var eveningVerseId: String?
}
```

### SavedVerse
```swift
struct SavedVerse: Identifiable, Codable {
    let id: String
    let verseId: String
    let savedAt: Date
    let mode: String            // 저장 당시 모드
    let weatherTemp: Int
    let weatherCondition: String
    let weatherHumidity: Int
    let locationName: String
}
```

### WeatherData
```swift
struct WeatherData: Codable {
    let temperature: Int        // °C
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let humidity: Int           // %
    let dustGrade: String       // "좋음" | "보통" | "나쁨" | "매우나쁨"
    let cityName: String
    let cachedAt: Date
    // 저녁 모드용
    var tomorrowMorningTemp: Int?
    var tomorrowMorningCondition: String?
}
```

---

## 13. Firebase 스키마

### verses/{verse_id}
```
text_ko: String
text_full_ko: String
reference: String
book: String, chapter: Int, verse: Int
mode: [String]       // "morning" | "afternoon" | "evening" | "all"
theme: [String]      // hope, courage, strength, renewal, wisdom, focus, patience, gratitude, peace, comfort, reflection, rest
mood: [String]       // bright, calm, warm, serene, dramatic, cozy
season: [String]     // spring, summer, autumn, winter, all
weather: [String]    // sunny, cloudy, rainy, snowy, any
interpretation: String
application: String
curated: Bool
status: String       // active | draft | inactive
usage_count: Int
```

### images/{image_id}
```
filename: String
storage_url: String
source: String, source_url: String, license: String
mode: [String], theme: [String], mood: [String], season: [String], weather: [String]
tone: String         // bright | mid | dark
status: String       // active | draft
```

### users/{user_id}
```
email: String
display_name: String
created_at: Timestamp
subscription_status: String   // "free" | "premium"
subscription_expire_at: Timestamp
settings: {
  timezone: String
  location_enabled: Bool
  notification_enabled: Bool
  preferred_theme: String
}
```

### saved_verses/{user_id}/verses/{saved_id}
```
verse_id: String
saved_at: Timestamp
mode: String
weather_snapshot: { temp: Int, condition: String, humidity: Int }
location: { city: String, lat: Double, lng: Double }
```

---

## 14. Core Data 스키마

### CachedVerse
```
verse_id: String (indexed)
json: String         // Verse 전체를 JSON으로 직렬화
cached_at: Date
```

### CachedWeather
```
json: String         // WeatherData JSON
cached_at: Date      // TTL 30분
```

### AlarmEntity
```
id: UUID (indexed)
time: Date
repeat_days: String  // JSON 직렬화 [Int]
theme: String
is_enabled: Bool
snooze_count: Int16
```

---

## 15. 말씀 선택 알고리즘

```
1. 현재 모드 기준으로 mode가 일치하는(또는 "all") 구절을 필터링
2. status == "active" && curated == true 인 것만
3. 스코어 산정:
   - 테마 겹침 1개당 +3점
   - 분위기(mood) 겹침 1개당 +2점
   - 날씨(weather) 일치 시 +2점
   - 계절(season) 일치 시 +1점
4. 최고 점수 구절 중 랜덤 선택
5. Free 유저: 결정된 1개 고정 (DailyVerseCache에 저장)
6. Premium [다음 말씀]: 현재 표시 중인 구절 제외 후 재실행
```

---

## 16. 이미지 매칭 알고리즘

```
1. 현재 모드와 일치하는(또는 "all") 이미지 필터링
2. status == "active" 인 것만
3. 스코어: 테마+3, 분위기+2, 날씨+2, 계절+1
4. 최고 점수 이미지 중 랜덤 선택
5. 아침 → bright/mid 톤 우선, 저녁 → dark 톤 우선
```

---

## 17. 구독 모델

| 기능 | Free | Premium (₩24,500/월) |
|------|------|----------------------|
| 3모드 말씀 (모드당 1개) | ✅ | ✅ |
| 실시간 날씨 | ✅ | ✅ |
| 저장 탭 0~7일 | ✅ | ✅ |
| 저장 탭 7~30일 | 광고 시청 필요 | ✅ |
| 저장 탭 30일 초과 | ❌ | ✅ 무제한 |
| 무제한 말씀 열람 | ❌ | ✅ |
| 테마 자유 선택 | ❌ | ✅ |
| 광고 없음 | ❌ | ✅ |

**수익 예상**: 월 수익 = 1,000 × 5% × ₩24,500 × 70% = ₩857,500

---

## 18. 업셀 설계

### 트리거 5가지
| 트리거 | 메시지 |
|--------|--------|
| [다음 말씀] 탭 (Free) | "오늘 말씀이 더 필요하신가요?" |
| [♥ 저장] 탭 (Free/비로그인) | "이 말씀을 간직하고 싶으신가요?" |
| 저장탭 7~30일 카드 탭 | "광고 없이 모든 기록을 되돌아보세요" |
| 저장탭 30일 초과 카드 탭 | "모든 말씀 기록을 되돌아보세요" |
| 알람 테마 선택 탭 (Free) | "지금 필요한 말씀을 직접 고르세요" |

### 노출 제한
- 동일 트리거: 24시간 내 최대 1회
- 세션 내 총 2회
- 24시간 내 재탭 시: 업셀 없이 잠금 아이콘만 표시
- UserDefaults로 트리거별 마지막 노출 시간 저장

---

## 19. 권한 처리

### 위치 권한 4가지 상태
| 상태 | 처리 |
|------|------|
| authorizedWhenInUse | 날씨 위젯 정상 작동 |
| notDetermined | "위치를 허용하면 날씨에 맞는 말씀을 만날 수 있어요" + [허용하기] |
| denied/restricted | "위치 권한이 없어요" + [설정 열기] (iOS Settings 딥링크) |
| API 오류 | 캐시 사용 또는 동일 오류 UI |

### 알림 권한
- notDetermined: 탭 시 iOS 권한 팝업 호출
- denied: Settings 딥링크 제공
- 알람 탭 진입 시 상단 배너로 권한 없음 경고
- 앱 포그라운드 진입마다 `PermissionManager.checkAll()` 호출

---

## 20. 인증 설계

- Apple Sign-In만 지원 (Firebase Auth 연동)
- Free 기능: 비로그인 이용 가능
- [♥ 저장] 첫 탭 시 로그인 바텀시트 표시
- **pendingSave**: 로그인 전 저장 시도 → 메모리에 임시 저장 → 로그인 성공 후 Firestore 자동 저장

### Apple Sign-In 실패 케이스 5가지
| 케이스 | 처리 |
|--------|------|
| 사용자 취소 | 바텀시트 유지, pendingSave 보존 |
| 네트워크 오류 | 토스트 "인터넷 연결을 확인해주세요" |
| Firebase 인증 오류 | 토스트 + Crashlytics 로그 |
| Apple ID 제한 | 토스트 "설정을 확인해주세요" |
| Firestore 문서 생성 실패 | 백그라운드 3회 재시도 후 저장 완료 토스트 |

---

## 21. 화면 전환 애니메이션 스펙

| 전환 상황 | 애니메이션 |
|-----------|-----------|
| 탭 전환 | 기본 iOS TabView |
| Stage 1 → Stage 2 | Fade-in 0.6s ease-in-out |
| 바텀시트 등장 | Slide-up 0.3s |
| 모드 전환 (아침→낮→저녁) | Cross-dissolve 1.0s |
| 말씀 카드 → 상세 | Scale-up + Fade 0.4s |
| 저장 완료 | Heart pulse 애니메이션 |

---

## 22. 코딩 컨벤션

### 파일명 규칙
- View: `[FeatureName]View.swift` (예: `HomeView.swift`)
- ViewModel: `[FeatureName]ViewModel.swift`
- Service: `[Name]Service.swift`
- Manager: `[Name]Manager.swift`
- Repository: `[Name]Repository.swift`
- Model: 모델명 그대로 (예: `Verse.swift`)

### 변수명
- 서비스 인스턴스: `firestore`, `auth`, `weatherService`
- Combine/async 패턴: `async/await` 사용 (Combine은 최소화)
- Published 변수: `@Published var verses: [Verse] = []`

### SwiftUI 규칙
- 모든 View는 `#Preview` 제공
- 컬러: `Color+DailyVerse.swift` extension에서 관리
- 폰트: `Font+DailyVerse.swift` extension에서 관리
- iOS 16+ API만 사용 (`.navigationStack`, `.sheet(item:)` 등)

---

## 23. 에이전트 역할 분담

| 에이전트 | 담당 영역 | 호출 시점 |
|----------|-----------|----------|
| `ios-architect` | 프로젝트 구조, 아키텍처, SPM | Sprint 1 |
| `data-engineer` | 데이터 모델, Core Data, 알고리즘 | Sprint 1~2 |
| `firebase-engineer` | Firebase 전체 스택 | Sprint 1~2 |
| `swiftui-builder` | 모든 SwiftUI 뷰 | Sprint 3~6 |
| `alarm-engineer` | 알람/알림 시스템 | Sprint 4 |
| `weather-engineer` | 날씨 서비스 | Sprint 2 |
| `subscription-engineer` | 수익화 (결제, 광고, 업셀) | Sprint 5 |
| `qa-engineer` | 테스트, 검증 | 각 Sprint 완료 후 |

---

## 24. 스프린트 계획 요약

| Sprint | 주요 작업 | 담당 에이전트 |
|--------|-----------|--------------|
| **1. 기반** | Xcode 설정, 아키텍처, 데이터 모델, Core Data, Firebase 초기화 | ios-architect, data-engineer, firebase-engineer |
| **2. 서비스** | Firestore, Auth, WeatherKit, VerseSelector, DailyCacheManager | firebase-engineer, weather-engineer, data-engineer |
| **3. Home 탭** | HomeView (3모드), VerseCard, WeatherWidget, 바텀시트 | swiftui-builder, data-engineer |
| **4. 알람 시스템** | AlarmList, AlarmModal, Stage 1/2 전체화면, 엣지케이스 | alarm-engineer, swiftui-builder |
| **5. Saved + Settings** | SavedGrid, 접근 제어, RevenueCat, AdMob, 업셀 | swiftui-builder, subscription-engineer |
| **6. 온보딩 + Polish** | 온보딩 5화면, 스플래시, 애니메이션, 오프라인 처리 | swiftui-builder, data-engineer |
| **7. QA** | 유닛 테스트, 엣지케이스 시나리오, App Store 준비 | qa-engineer |

---

### Sprint 1 — 프로젝트 기반 구축
> 모든 개발의 뼈대. 이후 스프린트가 이 위에서 동작함.

| # | 태스크 | 담당 에이전트 | 산출물 |
|---|--------|-------------|--------|
| 1-1 | Xcode 프로젝트 생성 + 폴더 구조 스캐폴딩 | `ios-architect` | 전체 폴더 트리 + 빈 Swift 파일들 |
| 1-2 | SPM 패키지 추가 (Firebase, RevenueCat, GoogleMobileAds) | `ios-architect` | Package.swift 의존성 설정 |
| 1-3 | DailyVerseApp.swift + AppDelegate.swift + AppRootView.swift | `ios-architect` | 앱 진입점 + 온보딩/홈 분기 |
| 1-4 | MainTabView.swift (4탭 기본 구조) | `ios-architect` | TabView 스텁 |
| 1-5 | AppMode.swift + Color/Font/Animation Extension | `ios-architect` | 공통 타입 + 디자인 토큰 |
| 1-6 | 전체 Swift 데이터 모델 (Verse, VerseImage, Alarm, User, SavedVerse, DailyVerseCache, WeatherData) | `data-engineer` | Core/Models/ 7개 파일 |
| 1-7 | Core Data 스키마 + PersistenceController.swift | `data-engineer` | DailyVerse.xcdatamodeld, PersistenceController.swift |
| 1-8 | Firebase 초기화 설정 가이드 (GoogleService-Info.plist 연동) | `firebase-engineer` | Firebase 설정 완료 |

---

### Sprint 2 — 서비스 레이어
> 비즈니스 로직의 심장. 뷰는 이 레이어를 호출하기만 함.

| # | 태스크 | 담당 에이전트 | 산출물 |
|---|--------|-------------|--------|
| 2-1 | FirestoreService.swift (verses/images fetch, saved_verses CRUD) | `firebase-engineer` | FirestoreService.swift |
| 2-2 | AuthService.swift + AuthManager.swift (Apple Sign-In + pendingSave) | `firebase-engineer` | AuthService.swift, AuthManager.swift |
| 2-3 | WeatherService.swift (WeatherKit + OpenWeatherMap 폴백 + 30분 캐시) | `weather-engineer` | WeatherService.swift, WeatherCacheManager.swift |
| 2-4 | VerseSelector.swift (모드/테마/날씨/계절 스코어링 알고리즘) | `data-engineer` | VerseSelector.swift |
| 2-5 | DailyCacheManager.swift (일별 말씀 고정 캐시, 05:00 기준) | `data-engineer` | DailyCacheManager.swift |
| 2-6 | PermissionManager.swift (위치/알림 권한 상태 관리) | `alarm-engineer` | PermissionManager.swift |
| 2-7 | VerseRepository.swift + SavedVerseRepository.swift | `data-engineer` | Repository 파일 2개 |
| **2-QA** | Sprint 2 검증 (서비스 레이어 유닛 테스트) | `qa-engineer` | 검증 완료 |

병렬 가능: 2-1, 2-3, 2-4 동시 진행 가능

---

### Sprint 3 — Home 탭
> 앱의 얼굴. 가장 복잡한 화면.

| # | 태스크 | 담당 에이전트 | 산출물 |
|---|--------|-------------|--------|
| 3-1 | HomeViewModel.swift (모드 판단, 말씀/날씨 로드, CTA 상태) | `data-engineer` | HomeViewModel.swift |
| 3-2 | HomeView.swift (3모드 레이아웃 + Cross-dissolve 1.0s 전환) | `swiftui-builder` | HomeView.swift |
| 3-3 | VerseCardView.swift (말씀 카드 UI) | `swiftui-builder` | VerseCardView.swift |
| 3-4 | WeatherWidgetView.swift (온도/상태/미세먼지, 저녁: 내일 예보 포함) | `swiftui-builder` | WeatherWidgetView.swift |
| 3-5 | VerseDetailBottomSheet.swift (전체 구절 + 해석 + 저장/다음/닫기) | `swiftui-builder` | VerseDetailBottomSheet.swift |
| 3-6 | CoachMarkOverlay.swift (최초 1회, 말씀카드 → Alarm탭 순서) | `swiftui-builder` | CoachMarkOverlay.swift |
| 3-7 | ToastView.swift (공통 토스트 컴포넌트) | `swiftui-builder` | ToastView.swift |
| **3-QA** | Sprint 3 검증 (3모드 전환, 카드 탭, 애니메이션) | `qa-engineer` | 검증 완료 |

병렬 가능: 3-2, 3-3, 3-4 동시 진행 가능

---

### Sprint 4 — 알람 탭 + 알람 울림 UX
> DailyVerse의 핵심 차별점.

| # | 태스크 | 담당 에이전트 | 산출물 |
|---|--------|-------------|--------|
| 4-1 | AlarmRepository.swift (Core Data CRUD) | `alarm-engineer` | AlarmRepository.swift |
| 4-2 | NotificationManager.swift (스케줄링, 스누즈, 취소, 재스케줄) | `alarm-engineer` | NotificationManager.swift |
| 4-3 | AlarmCoordinator.swift (Stage 전환 상태 관리) | `alarm-engineer` | AlarmCoordinator.swift |
| 4-4 | AppDelegate UNUserNotificationCenterDelegate 구현 (willPresent, didReceive) | `alarm-engineer` | AppDelegate.swift 업데이트 |
| 4-5 | AlarmViewModel.swift | `alarm-engineer` | AlarmViewModel.swift |
| 4-6 | AlarmListView.swift (알람 카드 + ON/OFF + 스와이프 삭제 + 되돌리기) | `swiftui-builder` | AlarmListView.swift |
| 4-7 | AlarmAddEditView.swift (TimePicker + 반복 + 테마 + 미리보기 + 저장) | `swiftui-builder` | AlarmAddEditView.swift |
| 4-8 | AlarmStage1View.swift (탭바 없음, 전체화면, 스누즈/종료 버튼) | `alarm-engineer` + `swiftui-builder` | AlarmStage1View.swift |
| 4-9 | AlarmStage2View.swift (Fade-in 0.6s, 말씀+날씨+저장/다음/닫기) | `alarm-engineer` + `swiftui-builder` | AlarmStage2View.swift |
| 4-10 | 알람 엣지케이스 9가지 처리 | `alarm-engineer` | 엣지케이스 핸들러 완료 |
| **4-QA** | Sprint 4 검증 (Stage 1/2 UX, 9가지 엣지케이스) | `qa-engineer` | 검증 완료 |

---

### Sprint 5 — Saved 탭 + Settings 탭
> 수익화 게이팅과 사용자 관리.

| # | 태스크 | 담당 에이전트 | 산출물 |
|---|--------|-------------|--------|
| 5-1 | SavedViewModel.swift (3단계 접근 제어 로직) | `data-engineer` | SavedViewModel.swift |
| 5-2 | SavedView.swift (2열 그리드 + 빈 상태 3가지) | `swiftui-builder` | SavedView.swift |
| 5-3 | SavedDetailView.swift (전체 구절 + 저장일시 + 날씨스냅샷 + 공유) | `swiftui-builder` | SavedDetailView.swift |
| 5-4 | SubscriptionManager.swift (RevenueCat + StoreKit 2) | `subscription-engineer` | SubscriptionManager.swift |
| 5-5 | AdManager.swift (AdMob Rewarded 광고) | `subscription-engineer` | AdManager.swift |
| 5-6 | UpsellManager.swift (트리거 5종 + 24시간/세션 2회 노출 제한) | `subscription-engineer` | UpsellManager.swift |
| 5-7 | UpsellBottomSheet.swift (트리거별 감성 메시지) | `swiftui-builder` | UpsellBottomSheet.swift |
| 5-8 | LoginPromptSheet.swift (로그인 유도 + pendingSave 연동) | `swiftui-builder` | LoginPromptSheet.swift |
| 5-9 | SettingsView.swift (5섹션: 계정/구독/권한/앱정보/피드백) | `swiftui-builder` | SettingsView.swift |
| 5-10 | 계정 탈퇴 플로우 4단계 (Apple 재인증 → Firestore 삭제 → RevenueCat logOut → 초기화) | `firebase-engineer` + `subscription-engineer` | 계정 탈퇴 완료 |
| **5-QA** | Sprint 5 검증 (저장탭 날짜 접근, 업셀 트리거 5종, 광고 플로우) | `qa-engineer` | 검증 완료 |

병렬 가능: 5-2, 5-4, 5-9 동시 진행 가능

---

### Sprint 6 — 온보딩 + 앱 실행 플로우 + Polish
> 첫 인상 + 마무리.

| # | 태스크 | 담당 에이전트 | 산출물 |
|---|--------|-------------|--------|
| 6-1 | SplashView.swift + AppLoadingCoordinator.swift (3단계 로딩 플로우) | `swiftui-builder` + `data-engineer` | SplashView.swift, AppLoadingCoordinator.swift |
| 6-2 | OnboardingContainerView.swift (5화면 TabView 페이지) | `swiftui-builder` | OnboardingContainerView.swift |
| 6-3 | OnboardingWelcomeView.swift | `swiftui-builder` | OnboardingWelcomeView.swift |
| 6-4 | OnboardingFirstVerseView.swift (이사야 41:10 샘플 체험) | `swiftui-builder` | OnboardingFirstVerseView.swift |
| 6-5 | OnboardingLocationView.swift + OnboardingNotificationView.swift | `swiftui-builder` | 권한 요청 화면 2개 |
| 6-6 | OnboardingFirstAlarmView.swift (06:00 + 22:00 기본값) | `swiftui-builder` | OnboardingFirstAlarmView.swift |
| 6-7 | OnboardingViewModel.swift (UserDefaults 4키 + 스킵 3회 강제 완료) | `data-engineer` | OnboardingViewModel.swift |
| 6-8 | OfflineFallbackManager.swift (번들 폴백 3개 구절 + 토스트) | `data-engineer` | OfflineFallbackManager.swift |
| 6-9 | 전체 애니메이션 polish (Heart pulse, Scale-up+Fade, Cross-dissolve) | `swiftui-builder` | Animation+DailyVerse.swift 완성 |
| **6-QA** | Sprint 6 검증 (온보딩 5화면, 스킵 로직, 오프라인 폴백, 스플래시) | `qa-engineer` | 검증 완료 |

---

### Sprint 7 — QA + 출시 준비
> 버그 없는 앱.

| # | 태스크 | 담당 에이전트 | 산출물 |
|---|--------|-------------|--------|
| 7-1 | Unit Tests (VerseSelector, DailyCacheManager, AppMode, AlarmRepository) | `qa-engineer` | DailyVerseTests/ |
| 7-2 | 알람 엣지케이스 9가지 전체 시나리오 테스트 | `qa-engineer` | 테스트 리포트 |
| 7-3 | 구독/광고 플로우 검증 (Free→업셀→광고→열람→Premium 전환) | `qa-engineer` | 검증 리포트 |
| 7-4 | 오프라인 3가지 시나리오 검증 (캐시 있음/없음/완전 오프라인) | `qa-engineer` | 검증 리포트 |
| 7-5 | Firebase Analytics 이벤트 + Crashlytics 정상 동작 확인 | `firebase-engineer` | 이벤트 목록 확인 |
| 7-6 | App Store 제출 준비 (Privacy Manifest, Info.plist, 권한 문구) | `ios-architect` | 제출 체크리스트 완료 |

---

## 25. 콘텐츠 현황 (2026-04-15 기준, v9.0)

### 데이터 소스 접근 정보

| 항목 | 내용 |
|------|------|
| **Google Sheets** | [DailyVerse 콘텐츠 시트](https://docs.google.com/spreadsheets/d/1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig/edit) |
| **편집 권한** | ✅ 서비스 계정 직접 편집 가능 (`scripts/serviceAccountKey.json`) |
| **상세 가이드** | `docs/contents-guideline.md` (v9.0 — 생성 파이프라인·Zone 컨텍스트·LLM 프롬프트 통합) |

> Claude Code는 `scripts/serviceAccountKey.json`을 통해 Google Sheets API 편집 권한을 보유합니다.

---

### 주요 스크립트

| 스크립트 | 용도 |
|--------|------|
| `sync_sheets_to_firestore.js` | Sheets → Firestore 전체 동기화 |
| `sync_firestore_to_sheet.js` | Firestore → Sheets 역동기화 |
| `apply_formula_fields.js` | contemplation_* 수식 필드 재적용 (4개 컬럼) |
| `generate_question_new.js` | `question` 필드 생성 (Claude API, --dry-run/--range 지원) |
| `update_to_korv.js` | `verse_full_ko`/`verse_short_ko` 개역한글 원문 업데이트 |
| `check_content_quality.js` | 콘텐츠 품질 검증 (글자수·말투·원어 표기) |
| `setup_content_guide.js` | WRITING_GUIDE + ZONE_GUIDE 탭/컬렉션 동기화 |

---

### Google Sheets 탭 구조

| 탭 | 용도 |
|----|------|
| `VERSES` | 메인 말씀 (v_001~v_180) |
| `ALARM_VERSES` | 알람 탭 전용 말씀 (av_001~av_105) |
| `WRITING_GUIDE` | 필드별 생성 규칙 + LLM 프롬프트 (v9.0) |
| `ZONE_GUIDE` | 8개 Zone × 유저 상황·감정·말씀 역할·application 예시 |
| `IMAGES` | 감성 배경 이미지 메타데이터 |

---

### Firestore 컬렉션 구조

| 컬렉션 | 범위/수량 | 용도 |
|--------|---------|------|
| `verses/` | v_001~v_180 (active **161개**, inactive 18개) | 홈화면 + 알람 + 묵상 탭 말씀 |
| `alarm_verses/` | av_001~av_105 (105개) | 알람 탭 오늘의 말씀 카드 전용 |
| `writing_guide/` | 7개 문서 | 필드별 생성 규칙 + LLM 프롬프트 |
| `zone_guide/` | 8개 문서 | Zone별 유저 상황·감정·말씀 역할 |

---

### verses/ 컬렉션 필드 현황 (v9.0)

| 필드 | 상태 | 비고 |
|------|------|------|
| `verse_full_ko` | ✅ 전체 완료 | **개역한글 원문** (1961, 퍼블릭 도메인) |
| `verse_short_ko` | ✅ 전체 완료 | 개역한글에서 핵심 문장 추출 |
| `interpretation` | ✅ 전체 완료 | DailyVerse 독자 작성 (친근한 현대 한국어) |
| `application` | ✅ 전체 완료 | Zone 시간대 반영 행동 가이드 |
| `question` | ✅ 전체 완료 | 묵상 응답 질문 180개 생성 (`generate_question_new.js`) |
| `contemplation_*` | ✅ 수식 자동 | Sheets 수식으로 원본 컬럼 자동 참조 — 별도 작성 불필요 |
| `alarm_top_ko` | 선택 필드 | verse_short_ko ≤ 35자이면 생략 |

---

### 말씀 저작권 (v9.0 변경)

| 필드 | 출처 | 저작권 |
|------|------|--------|
| `verse_full_ko`, `verse_short_ko` | **개역한글** (대한성서공회, 1961) | 퍼블릭 도메인 (2011년 만료) — 출처 표기 필수 |
| `interpretation`, `application`, `question` | DailyVerse 독자 작성 | DailyVerse 소유 |

> ⚠️ 앱 이용약관/정보 섹션에 "성경 본문: 개역한글, 대한성서공회" 출처 표기 필요

---

### 콘텐츠 생성 파이프라인 (v9.0)

```
verse_full_ko (개역한글 원문, 앵커)
    ↓
verse_short_ko (핵심 문장 추출)
    ↓
interpretation + application (DailyVerse 독자 작성, Zone 반영)
    ↓
question (묵상 응답 질문, Claude API)
```

상세 규칙 및 LLM 프롬프트: `docs/contents-guideline.md §4~§6`

---

### 콘텐츠 QA 프로세스

| 단계 | 에이전트/스크립트 | 주요 검증 항목 |
|------|----------------|-------------|
| 생성 | `content-writer`, `generate_question_new.js`, `update_to_korv.js` | 신규 콘텐츠 생성 |
| 자동 검증 | `check_content_quality.js` | 글자수·말투·원어 표기·중복 |
| AI 검증 | `content-checker` | Zone 맥락 정합성·interpretation 구조·번영신학 위험 표현 |
| 수정 | `content-fixer` | Sheets + Firestore 배치 업데이트 |

---

### 데이터 라이프사이클 정책

| 주기 | 대상 | 방식 |
|------|------|------|
| 수시 | `alarm_verses/` (`alarm_top_ko` 보유 구절) | 알람 탭 카드에서 랜덤 호출 |
| 일일 06:00 고정 | `verses/` | 5개 Sync Group(A/B/O/P/Q) 기반 배포 |

### 이미지

- Genspark Pro 플랜 기반 생성 (상업적 사용 가능)
- Zone별 고정 배경 8개 (`background_images/`) + 감성 이미지 49개 (`images/`) active
- 부족 Zone: peak_mode(7개↓), recharge(6개↓), second_wind(6개↓) 추가 필요

---

## 26. KPI 목표

- **North Star Metric**: 알람 발동 DAU × 아침 UX 완주율
- Free → Premium 전환율 목표: 3~5%
- 크래시율 목표: < 0.5%
- App Store 평점 목표: ≥ 4.5
- D1/D7/D30 리텐션 추적
