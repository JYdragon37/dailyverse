---
feature: greeting-update
phase: design
created: 2026-04-14
architecture: B — GreetingService @EnvironmentObject
status: active
---

## Context Anchor

| 축 | 내용 |
|----|------|
| WHY | greeting 탭 Zone별 한/영 각 10~12개 변형이 있으나 앱은 1개만 하드코딩 사용 중 |
| WHO | 매일 아침·저녁 앱을 여는 크리스천 사용자 |
| RISK | Firestore 장애 시 폴백 없으면 공백. 텍스트 길이 편차로 레이아웃 깨짐 가능 |
| SUCCESS | Zone 진입 시 항상 표시, 언어 설정 반영, 레이아웃 깨짐 없음 |
| SCOPE | GreetingService(신규) + 업로드 스크립트 + 영향 View 3개 + SettingsView |

---

## 1. 아키텍처 결정 — Option B

기존 `AuthManager`, `SubscriptionManager`, `PermissionManager`와 동일한 `@EnvironmentObject` 패턴 채택.

```
DailyVerseApp
  └── .environmentObject(GreetingService())     ← 신규 주입
        ↓
  HomeView → @EnvironmentObject greetingService
  AlarmStage2View → @EnvironmentObject greetingService
  ONBExperienceView → @EnvironmentObject greetingService
  SettingsView → @AppStorage("greetingLanguage") 직접 관리
```

> **DevotionHomeView 제외**: 이 뷰의 greeting은 닉네임 포함 긴 문장으로 greeting 탭과 성격이 다름. 현행 유지.

---

## 2. 데이터 모델

### 2-1. Greeting.swift (신규)
```swift
struct Greeting: Identifiable, Codable {
    let id: String          // gr_id (예: "gr_deep_dark_ko_01")
    let zoneId: String      // "deep_dark"
    let language: String    // "ko" | "en"
    let text: String        // "이 밤도 당신 편이에요."
    let charCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "gr_id"
        case zoneId = "zone_id"
        case language, text
        case charCount = "char_count"
    }
}
```

### 2-2. GreetingLanguage (GreetingService.swift 내부)
```swift
enum GreetingLanguage: String, CaseIterable {
    case ko     = "ko"
    case en     = "en"
    case random = "random"

    var displayName: String {
        switch self {
        case .ko:     return "한국어"
        case .en:     return "English"
        case .random: return "랜덤"
        }
    }

    /// random일 경우 실제 언어 결정
    func resolved() -> String {
        self == .random ? (Bool.random() ? "ko" : "en") : self.rawValue
    }
}
```

---

## 3. GreetingService 설계

```swift
// Core/Services/GreetingService.swift

@MainActor
class GreetingService: ObservableObject {

    // MARK: - Published
    @Published var currentGreeting: String = ""

    // MARK: - Private
    private var cache: [String: String] = [:]
    // key 형식: "{zone_id}_{resolved_lang}"  예: "deep_dark_ko"

    private let db = Firestore.firestore()

    // MARK: - Public

    /// Zone 진입 시 호출. 캐시 있으면 즉시 반환, 없으면 Firestore fetch.
    func load(for mode: AppMode, language: GreetingLanguage) async {
        let resolvedLang = language.resolved()
        let cacheKey = "\(mode.rawValue)_\(resolvedLang)"

        // 1. 캐시 히트
        if let cached = cache[cacheKey] {
            currentGreeting = cached
            return
        }

        // 2. Firestore fetch
        do {
            let snapshot = try await db.collection("greetings")
                .whereField("zone_id", isEqualTo: mode.rawValue)
                .whereField("language", isEqualTo: resolvedLang)
                .getDocuments()

            let greetings = snapshot.documents.compactMap {
                try? $0.data(as: Greeting.self)
            }

            if let picked = greetings.randomElement() {
                cache[cacheKey] = picked.text
                currentGreeting = picked.text
            } else {
                useFallback(mode: mode, lang: resolvedLang)
            }
        } catch {
            useFallback(mode: mode, lang: resolvedLang)
        }
    }

    /// Zone 전환 시 캐시 무효화 (새 Zone 진입 시 새 greeting 선택)
    func invalidateCache(for mode: AppMode) {
        cache.removeValue(forKey: "\(mode.rawValue)_ko")
        cache.removeValue(forKey: "\(mode.rawValue)_en")
    }

    // MARK: - Private

    private func useFallback(mode: AppMode, lang: String) {
        currentGreeting = lang == "ko" ? mode.greetingKr : mode.greeting
    }
}
```

---

## 4. Firestore 컬렉션 스키마

```
greetings/{gr_id}
  gr_id:      String   "gr_deep_dark_ko_01"
  zone_id:    String   "deep_dark"
  language:   String   "ko" | "en"
  text:       String   "이 밤도 당신 편이에요."
  char_count: Int      12
```

**인덱스 필요**: `zone_id ASC` + `language ASC` (복합 인덱스)

---

## 5. 업로드 스크립트 설계

```
scripts/upload_greetings.js

1. Google Sheets greeting 탭 A3:G178 읽기
2. 각 행 → { gr_id, zone_id, language(ko/en 변환), text, char_count }
3. Firestore greetings/{gr_id} batch write (500개 단위)
4. 완료 후 총 업로드 수 출력
```

언어 변환: `"한국어"` → `"ko"`, `"English"` → `"en"`
zone_id: C열(id 컬럼) 수식 결과값 사용

---

## 6. Settings UI 설계

### 추가 위치
`SettingsView.swift` → `appearanceSection` 내부 (기존 외관 섹션에 추가)

```swift
// SettingsView.swift
@AppStorage("greetingLanguage") private var greetingLanguage: String = "random"

// appearanceSection 내부
Picker("인사말 언어", selection: $greetingLanguage) {
    Text("한국어").tag("ko")
    Text("English").tag("en")
    Text("랜덤").tag("random")
}
.pickerStyle(.segmented)
```

> `@AppStorage`는 UserDefaults와 자동 동기화. GreetingService는 `load()` 호출 시 이 값을 읽음.

---

## 7. View 수정 상세

### 7-1. HomeView.swift

**현재 (line 121-130)**:
```swift
private var greetingText: String {
    let g = viewModel.currentMode.greeting   // 하드코딩
    ...
}
```

**변경 후**:
```swift
@EnvironmentObject var greetingService: GreetingService
@AppStorage("greetingLanguage") private var greetingLanguagePref: String = "random"

private var greetingText: String {
    let g = greetingService.currentGreeting.isEmpty
        ? viewModel.currentMode.greeting   // 폴백
        : greetingService.currentGreeting
    // 기존 닉네임 조합 로직 그대로 유지
    ...
}

// Zone 전환 감지 → load 호출
.onChange(of: viewModel.currentMode) { newMode in
    Task {
        let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
        await greetingService.load(for: newMode, language: lang)
    }
}
.task {
    let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
    await greetingService.load(for: viewModel.currentMode, language: lang)
}
```

**minimumScaleFactor 적용**:
```swift
Text(greetingText)
    .font(.system(size: 28, weight: .bold))
    .minimumScaleFactor(0.7)
    .lineLimit(2)
```

### 7-2. AlarmStage2View.swift

**현재 (line 140)**:
```swift
Text(alarmMode.greeting)
```

**변경 후**:
```swift
@EnvironmentObject var greetingService: GreetingService
@AppStorage("greetingLanguage") private var greetingLanguagePref: String = "random"

// greetingHeader 내부
Text(greetingService.currentGreeting.isEmpty
    ? alarmMode.greeting
    : greetingService.currentGreeting)
    .minimumScaleFactor(0.7)
    .lineLimit(2)

// .task에서 load (AlarmStage2는 항상 current zone)
.task {
    let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
    await greetingService.load(for: alarmMode, language: lang)
}
```

### 7-3. ONBExperienceView.swift

**현재**: `greetingText(for: mode)` 함수 → `appMode.greeting` 반환

**변경 후**:
```swift
@EnvironmentObject var greetingService: GreetingService
@AppStorage("greetingLanguage") private var greetingLanguagePref: String = "random"

// onAppear / .task
.task {
    let lang = GreetingLanguage(rawValue: greetingLanguagePref) ?? .random
    await greetingService.load(for: mode, language: lang)
}

// 텍스트 표시
Text(greetingService.currentGreeting.isEmpty
    ? greetingText(for: mode)
    : greetingService.currentGreeting)
    .minimumScaleFactor(0.7)
    .lineLimit(2)
```

### 7-4. DailyVerseApp.swift

```swift
// 기존 @StateObject들 아래에 추가
@StateObject private var greetingService = GreetingService()

// .environmentObject 체인에 추가
.environmentObject(greetingService)
```

---

## 8. 캐시 무효화 타이밍

| 상황 | 처리 |
|------|------|
| Zone 전환 (시간 경과) | `onChange(of: currentMode)` → `invalidateCache` 불필요, 새 key로 자동 miss |
| 언어 설정 변경 | 캐시 전체 clear (`cache.removeAll()`) 필요 없음 — 새 key(lang 변경)로 자동 miss |
| 앱 재시작 | 메모리 캐시이므로 자동 초기화 → Zone 진입 시 재fetch |

> 같은 Zone 내 재진입: 동일 `cacheKey`로 히트 → 같은 greeting 유지 (요구사항 충족)

---

## 9. 텍스트 길이 대응 규칙

| 항목 | 값 |
|------|-----|
| minimumScaleFactor | `0.7` (최대 30% 축소) |
| lineLimit | `2` |
| 레이아웃 영역 | 고정 (높이 변경 없음) |
| 적용 뷰 | HomeView, AlarmStage2View, ONBExperienceView |

greeting 탭 최대 길이: EN 31자. 폰트 크기 28 기준 → 축소 시 19.6pt까지. 2줄 허용 시 충분.

---

## 10. 테스트 시나리오

| # | 시나리오 | 기대 결과 |
|---|----------|-----------|
| T1 | Firestore 정상 + Zone deep_dark + 언어 ko | greeting 탭 ko 변형 중 1개 랜덤 표시 |
| T2 | 같은 Zone 재진입 | 동일 greeting 유지 |
| T3 | Zone 전환 (deep_dark → first_light) | 새 greeting 선택됨 |
| T4 | 언어 설정 en 변경 후 재진입 | en 변형 표시 |
| T5 | 언어 설정 random | ko 또는 en 중 하나 랜덤 표시 |
| T6 | Firestore 실패 (오프라인) | AppMode 하드코딩 폴백 표시, 공백 없음 |
| T7 | 가장 긴 EN greeting (31자) | 레이아웃 깨짐 없이 표시 |
| T8 | Settings 언어 변경 | 다음 Zone 진입 시 즉시 반영 |

---

## 11. 구현 가이드

### 11.1 파일 목록

| 파일 | 작업 | 우선순위 |
|------|------|----------|
| `scripts/upload_greetings.js` | 신규 — Sheets → Firestore 업로드 | 1 (데이터 선행) |
| `Core/Models/Greeting.swift` | 신규 — 모델 정의 | 2 |
| `Core/Services/GreetingService.swift` | 신규 — 서비스 로직 | 3 |
| `App/DailyVerseApp.swift` | 수정 — @StateObject + .environmentObject 추가 | 4 |
| `Features/Settings/SettingsView.swift` | 수정 — Picker 추가 | 5 |
| `Features/Home/HomeView.swift` | 수정 — 서비스 연동 + scaleFactor | 6 |
| `Features/Alarm/AlarmStage2View.swift` | 수정 — 서비스 연동 + scaleFactor | 7 |
| `Features/Onboarding/Screens/ONBExperienceView.swift` | 수정 — 서비스 연동 + scaleFactor | 8 |

### 11.2 구현 순서 체크리스트

- [ ] `upload_greetings.js` 작성 및 실행 → Firestore 데이터 확인
- [ ] `Greeting.swift` 모델 작성
- [ ] `GreetingService.swift` 작성 (load + cache + fallback)
- [ ] `DailyVerseApp.swift` — greetingService 주입
- [ ] `SettingsView.swift` — appearanceSection에 Picker 추가
- [ ] `HomeView.swift` — greetingService 연동, minimumScaleFactor
- [ ] `AlarmStage2View.swift` — 동일
- [ ] `ONBExperienceView.swift` — 동일
- [ ] 시뮬레이터 T1~T8 시나리오 확인

### 11.3 Session Guide

| 모듈 | 내용 | 예상 규모 |
|------|------|-----------|
| Module 1 — 데이터 | upload_greetings.js + Greeting.swift + GreetingService.swift | ~120줄 |
| Module 2 — 설정 | DailyVerseApp.swift + SettingsView.swift | ~20줄 |
| Module 3 — View 연동 | HomeView + AlarmStage2View + ONBExperienceView | ~40줄 |

**권장 세션 분할**: Module 1 → Module 2+3 (2세션)
또는 `/pdca do greeting-update`로 전체 한 번에 진행 가능.
