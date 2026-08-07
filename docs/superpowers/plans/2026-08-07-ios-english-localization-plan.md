# iOS 앱 영어 로컬라이즈 (String Catalog 인프라) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `docs/superpowers/specs/2026-08-07-english-global-launch-design.md`의 2장(하이브리드 아키텍처)을 구현한다 — Apple String Catalog 인프라를 도입하고, 기존 9개 파일·33곳의 `greetingLanguage` 삼항분기를 `appLanguage`로 정리하며, 최초 실행 시 기기 언어 자동감지 버그를 고친다.

**Architecture:** UI 정적 문자열은 `Localizable.xcstrings`(String Catalog)로, 콘텐츠(성경 구절 등 Firestore 데이터)는 기존 `_en`/`_ko` 필드 방식을 그대로 유지한다. 선택된 언어는 `UserDefaults("appLanguage")`에 저장되며, 시스템 로케일과 무관하게 사용자가 설정 화면에서 직접 전환한다(기존 UX 유지). 문자열 조회는 `Bundle(path:)`로 명시적 언어 번들을 로드하는 방식이라, iOS 시스템 로케일 설정과 완전히 독립적으로 동작한다.

**Tech Stack:** SwiftUI, `Testing` 프레임워크(`import Testing`, `@Test`, `#expect` — Swift Testing, XCTest 아님. 기존 `DailyVerseTests.swift`가 이 스타일을 사용 중), Xcode String Catalog (`.xcstrings`).

## Global Constraints
- `project.pbxproj`를 에이전트가 직접 텍스트 편집하는 것은 금지한다 (프로젝트 메모리 규칙: 손상 시 복구 어려움). 새 파일을 Xcode 타겟에 추가해야 하는 단계는 전부 **사용자가 Xcode GUI로 직접 수행**하도록 명시하고, 에이전트는 그 이후 파일 *내용*만 편집한다.
- 기존 `@AppStorage("greetingLanguage")` 변수명은 파일마다 `appLang`/`greetingLanguagePref`/`greetingLanguage`/`langPref`로 제각각이다. 이번 플랜에서 **키 이름만** `"appLanguage"`로 통일한다. Swift 지역 변수명 자체(`appLang` 등)는 굳이 통일하지 않는다 — 이번 스코프와 무관한 리네임은 최소화한다.
- 콘텐츠 선택용 `lang: appLang` 파라미터(예: `verse.verseShort(lang:)`, `verse.interpretationText(lang:)`)는 String Catalog 마이그레이션 대상이 **아니다** — 이건 Firestore 콘텐츠 필드 선택이며 설계문서 2.1절이 명시한 "콘텐츠는 기존 `_en`/`_ko` 필드 방식 유지"에 해당한다. 건드리지 않는다.
- 이번 플랜은 이미 확인된 9개 파일·33개 호출부 + 신규 발견된 `VerseDetailBottomSheet`의 미분기 하드코딩 문자열만 다룬다. 그 외 앱 전역의 나머지 하드코딩 한국어 문자열(예: 온보딩, Saved 리스트 등)은 **후속 플랜(B2)**으로 분리한다 — 이 플랜의 범위가 아니다.

---

## 파일 구조 (이번 플랜에서 건드리는 파일)

| 파일 | 변경 내용 |
|---|---|
| `DailyVerse/DailyVerse/Info.plist` | `CFBundleLocalizations` 추가 (수정) |
| `DailyVerse/DailyVerse/Localizable.xcstrings` | **신규** — String Catalog (Xcode GUI로 생성 후 내용 편집) |
| `DailyVerse/DailyVerse/App/DailyVerseApp.swift` | `AppLanguage` enum, `appLanguageString(_:)` 헬퍼, 자동감지 버그 수정, 키 마이그레이션 로직 추가 (수정) |
| `DailyVerse/DailyVerseTests/DailyVerseTests.swift` | `AppLanguage`/마이그레이션 로직 단위 테스트 추가 (수정, 기존 파일이라 pbxproj 건드릴 필요 없음) |
| `DailyVerse/DailyVerse/App/MainTabView.swift` | 키 리네임 + 탭 라벨 5개 String Catalog 전환 |
| `DailyVerse/DailyVerse/Features/Settings/SettingsView.swift` | 키 리네임 + "Appearance"/"외관" 라벨 전환 |
| `DailyVerse/DailyVerse/Features/Alarm/AlarmStage2View.swift` | 키 리네임 + 버튼/접근성 라벨 8곳 전환 |
| `DailyVerse/DailyVerse/Features/Home/HomeView.swift` | 키 리네임 + "Read More"/"말씀 깊게 보기" 라벨 전환 |
| `DailyVerse/DailyVerse/Common/Components/VerseDetailBottomSheet.swift` | 키 리네임 + 기존에 언어 분기가 전혀 없던 하드코딩 문자열(해석/오늘의 적용/저장/묵상/닫기) 신규 분기 처리 |
| `DailyVerse/DailyVerse/Features/Home/VerseCardView.swift` | 키 리네임만 |
| `DailyVerse/DailyVerse/Features/Saved/SavedDetailView.swift` | 키 리네임만 |
| `DailyVerse/DailyVerse/Features/Alarm/AlarmListView.swift` | 키 리네임만 |

---

## Task 1: Info.plist에 로케일 선언 추가

**Files:**
- Modify: `DailyVerse/DailyVerse/Info.plist:11-13`

**Interfaces:**
- Consumes: 없음
- Produces: 없음 (빌드 메타데이터 변경만)

- [ ] **Step 1: `CFBundleLocalizations` 추가**

`DailyVerse/DailyVerse/Info.plist`의 아래 블록:

```xml
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleExecutable</key>
```

를 다음으로 교체:

```xml
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleLocalizations</key>
	<array>
		<string>ko</string>
		<string>en</string>
	</array>
	<key>CFBundleExecutable</key>
```

- [ ] **Step 2: plist 유효성 확인**

Run: `plutil -lint DailyVerse/DailyVerse/Info.plist`
Expected: `DailyVerse/DailyVerse/Info.plist: OK`

- [ ] **Step 3: Commit**

```bash
git add DailyVerse/DailyVerse/Info.plist
git commit -m "feat: Info.plist에 ko/en CFBundleLocalizations 선언 추가"
```

---

## Task 2: String Catalog 생성 (사용자 수행 필요) + 초기 콘텐츠 채우기

**Files:**
- Create (사용자, Xcode GUI): `DailyVerse/DailyVerse/Localizable.xcstrings`

**Interfaces:**
- Consumes: 없음
- Produces: String Catalog에 아래 12개 키 — 이후 Task 5~9에서 사용
  - `tab.home`, `tab.alarm`, `tab.verses`, `tab.journal`, `tab.profile`
  - `settings.section.appearance`
  - `alarm.snooze.button`, `alarm.snooze.interval`, `alarm.snooze.accessibility`, `alarm.snooze.limitReached`, `alarm.rise.button`
  - `verse.readMore`, `verse.readMore.accessibility`
  - `verseDetail.interpretation.label`, `verseDetail.application.label`, `verseDetail.save.saved`, `verseDetail.save.button`, `verseDetail.save.accessibility`, `verseDetail.meditation.button`, `verseDetail.meditation.accessibility`, `verseDetail.close.accessibility`

- [ ] **Step 1 (사용자 수행): Xcode에서 String Catalog 파일 생성**

Xcode에서 `DailyVerse` 타겟의 `DailyVerse/DailyVerse/` 그룹(App/Info.plist가 있는 최상위 그룹)을 우클릭 → **New File... → Resource → Strings Catalog** 선택 → 파일명 `Localizable` → **Targets: DailyVerse 체크** → Create.

> 에이전트가 `project.pbxproj`를 직접 편집하지 않도록 이 단계만 사용자가 수행합니다. 생성 후 다음 스텝은 에이전트가 파일 *내용*을 편집합니다 (pbxproj는 건드리지 않음).

- [ ] **Step 2: 생성 확인**

Run: `test -f DailyVerse/DailyVerse/Localizable.xcstrings && echo "OK"`
Expected: `OK`

- [ ] **Step 3: 초기 콘텐츠 작성**

`DailyVerse/DailyVerse/Localizable.xcstrings` 전체 내용을 아래로 교체 (Xcode가 만든 빈 스캐폴드를 덮어씀):

```json
{
  "sourceLanguage" : "ko",
  "strings" : {
    "tab.home" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Home" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "홈" } }
      }
    },
    "tab.alarm" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Alarm" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "알람" } }
      }
    },
    "tab.verses" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Verses" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "말씀들" } }
      }
    },
    "tab.journal" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Journal" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "묵상" } }
      }
    },
    "tab.profile" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Profile" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "프로필" } }
      }
    },
    "settings.section.appearance" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Appearance" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "외관" } }
      }
    },
    "alarm.snooze.button" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "🌙  Snooze" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "🌙  스누즈" } }
      }
    },
    "alarm.snooze.interval" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "in %d min" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "%d분 후" } }
      }
    },
    "alarm.snooze.accessibility" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Snooze for %d minutes" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "%d분 스누즈" } }
      }
    },
    "alarm.snooze.limitReached" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Snooze limit reached" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "스누즈 횟수 초과" } }
      }
    },
    "alarm.rise.button" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "☀️  Rise" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "☀️  일어나기" } }
      }
    },
    "verse.readMore" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Read More" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "말씀 깊게 보기" } }
      }
    },
    "verse.readMore.accessibility" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "View interpretation and application" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "말씀 해석과 일상 적용 보기" } }
      }
    },
    "verseDetail.interpretation.label" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Interpretation" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "해석" } }
      }
    },
    "verseDetail.application.label" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Today's Application" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "오늘의 적용" } }
      }
    },
    "verseDetail.save.saved" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Saved ✓" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "저장됨 ✓" } }
      }
    },
    "verseDetail.save.button" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Save" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "저장" } }
      }
    },
    "verseDetail.save.accessibility" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Save this verse" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "말씀 저장하기" } }
      }
    },
    "verseDetail.meditation.button" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Journal" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "묵상" } }
      }
    },
    "verseDetail.meditation.accessibility" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Go to Journal tab" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "묵상 탭으로 이동" } }
      }
    },
    "verseDetail.close.accessibility" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Close" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "닫기" } }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 4: JSON 유효성 확인**

Run: `python3 -m json.tool DailyVerse/DailyVerse/Localizable.xcstrings > /dev/null && echo "valid json"`
Expected: `valid json`

- [ ] **Step 5: Commit**

```bash
git add DailyVerse/DailyVerse/Localizable.xcstrings DailyVerse/DailyVerse.xcodeproj/project.pbxproj
git commit -m "feat: Localizable.xcstrings String Catalog 추가 (탭/알람/말씀상세 키 20개)"
```

---

## Task 3: `AppLanguage` 헬퍼 + 자동감지 버그 수정 + 키 마이그레이션

**Files:**
- Modify: `DailyVerse/DailyVerse/App/DailyVerseApp.swift:23-27`
- Test: `DailyVerse/DailyVerseTests/DailyVerseTests.swift`

**Interfaces:**
- Produces:
  - `enum AppLanguage: String { case ko, en }` — `var bundle: Bundle` 계산 프로퍼티
  - `func appLanguageString(_ key: String, args: CVarArg...) -> String` — 전역 함수, Task 5~9에서 사용
  - `func migrateAppLanguageKeyIfNeeded(defaults: UserDefaults)` — 마이그레이션 로직(테스트 가능하도록 `UserDefaults` 주입형으로 분리)

- [ ] **Step 1: 실패하는 테스트 작성**

`DailyVerse/DailyVerseTests/DailyVerseTests.swift`의 `struct DailyVerseTests { ... }` 안, `@Test func example()` 아래에 추가:

```swift
    @Test func migratesLegacyGreetingLanguageKey() async throws {
        let defaults = UserDefaults(suiteName: "test.migratesLegacyGreetingLanguageKey")!
        defaults.removePersistentDomain(forName: "test.migratesLegacyGreetingLanguageKey")
        defaults.set("en", forKey: "greetingLanguage")

        migrateAppLanguageKeyIfNeeded(defaults: defaults)

        #expect(defaults.string(forKey: "appLanguage") == "en")
        #expect(defaults.object(forKey: "greetingLanguage") == nil)
    }

    @Test func doesNotOverwriteExistingAppLanguageKey() async throws {
        let defaults = UserDefaults(suiteName: "test.doesNotOverwriteExistingAppLanguageKey")!
        defaults.removePersistentDomain(forName: "test.doesNotOverwriteExistingAppLanguageKey")
        defaults.set("ko", forKey: "appLanguage")
        defaults.set("en", forKey: "greetingLanguage")

        migrateAppLanguageKeyIfNeeded(defaults: defaults)

        #expect(defaults.string(forKey: "appLanguage") == "ko")
    }

    @Test func defaultsToDeviceLanguageWhenNoKeyExists() async throws {
        let defaults = UserDefaults(suiteName: "test.defaultsToDeviceLanguageWhenNoKeyExists")!
        defaults.removePersistentDomain(forName: "test.defaultsToDeviceLanguageWhenNoKeyExists")

        migrateAppLanguageKeyIfNeeded(defaults: defaults, deviceLanguageCode: "en")

        #expect(defaults.string(forKey: "appLanguage") == "en")
    }

    @Test func defaultsToKoreanWhenDeviceLanguageIsNotEnglish() async throws {
        let defaults = UserDefaults(suiteName: "test.defaultsToKoreanWhenDeviceLanguageIsNotEnglish")!
        defaults.removePersistentDomain(forName: "test.defaultsToKoreanWhenDeviceLanguageIsNotEnglish")

        migrateAppLanguageKeyIfNeeded(defaults: defaults, deviceLanguageCode: "ja")

        #expect(defaults.string(forKey: "appLanguage") == "ko")
    }
```

- [ ] **Step 2: 테스트 실행 → 컴파일 실패 확인**

Run: `xcodebuild test -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' -only-testing:DailyVerseTests GENERATE_INFOPLIST_FILE=YES 2>&1 | tail -30`

> `GENERATE_INFOPLIST_FILE=YES`는 `DailyVerseTests` 타겟에 이 빌드 설정이 원래부터 빠져있던 기존 저장소 버그를 pbxproj를 건드리지 않고 우회하는 커맨드라인 오버라이드다 (모든 `xcodebuild test` 실행에 항상 붙여야 한다).

Expected: 컴파일 에러 — `cannot find 'migrateAppLanguageKeyIfNeeded' in scope`

- [ ] **Step 3: 구현 작성**

`DailyVerse/DailyVerse/App/DailyVerseApp.swift`의 아래 블록:

```swift
    init() {
        // 최초 실행 시 기기 언어로 자동 설정
        if UserDefaults.standard.object(forKey: "greetingLanguage") == nil {
            UserDefaults.standard.set("ko", forKey: "greetingLanguage")
        }
```

를 다음으로 교체:

```swift
    init() {
        migrateAppLanguageKeyIfNeeded(defaults: .standard)
```

그리고 파일 맨 아래(마지막 `}` 뒤)에 추가:

```swift

// MARK: - AppLanguage

enum AppLanguage: String {
    case ko, en

    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

/// 현재 선택된 언어(`appLanguage`)에 맞는 String Catalog 값을 명시적으로 조회한다.
/// 시스템 로케일과 무관하게, 설정 화면에서 사용자가 고른 언어를 그대로 따른다.
func appLanguageString(_ key: String, args: CVarArg...) -> String {
    let code = UserDefaults.standard.string(forKey: "appLanguage") ?? "ko"
    let lang = AppLanguage(rawValue: code) ?? .ko
    let format = NSLocalizedString(key, bundle: lang.bundle, comment: "")
    return args.isEmpty ? format : String(format: format, arguments: args)
}

/// 구 버전 키(`greetingLanguage`) → 신규 키(`appLanguage`) 마이그레이션.
/// 신규 키가 이미 있으면 아무것도 하지 않는다. 둘 다 없으면 기기 언어로 자동 감지한다.
func migrateAppLanguageKeyIfNeeded(
    defaults: UserDefaults,
    deviceLanguageCode: String = Locale.current.language.languageCode?.identifier ?? "ko"
) {
    if defaults.object(forKey: "appLanguage") != nil {
        return
    }
    if let legacy = defaults.string(forKey: "greetingLanguage") {
        defaults.set(legacy, forKey: "appLanguage")
        defaults.removeObject(forKey: "greetingLanguage")
        return
    }
    defaults.set(deviceLanguageCode == "en" ? "en" : "ko", forKey: "appLanguage")
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

Run: `xcodebuild test -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' -only-testing:DailyVerseTests GENERATE_INFOPLIST_FILE=YES 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`, 4개 신규 테스트 모두 PASS

- [ ] **Step 5: Commit**

```bash
git add DailyVerse/DailyVerse/App/DailyVerseApp.swift DailyVerse/DailyVerseTests/DailyVerseTests.swift
git commit -m "fix: 최초 실행 언어 자동감지 버그 수정 + appLanguage 키 마이그레이션 추가"
```

---

## Task 4: 나머지 6개 파일 — 키 리네임만 (콘텐츠 선택용, UI 문자열 아님)

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Home/VerseCardView.swift:8`
- Modify: `DailyVerse/DailyVerse/Features/Saved/SavedDetailView.swift:15,32`
- Modify: `DailyVerse/DailyVerse/Features/Alarm/AlarmListView.swift:10`

**Interfaces:**
- Consumes: 없음 (독립적인 키 리네임)
- Produces: 없음

- [ ] **Step 1: VerseCardView.swift 리네임**

`DailyVerse/DailyVerse/Features/Home/VerseCardView.swift:8`

```swift
    @AppStorage("greetingLanguage") private var appLang: String = "ko"
```
→
```swift
    @AppStorage("appLanguage") private var appLang: String = "ko"
```

- [ ] **Step 2: SavedDetailView.swift 리네임 + UI 문자열 전환**

`DailyVerse/DailyVerse/Features/Saved/SavedDetailView.swift:15`

```swift
    @AppStorage("greetingLanguage") private var appLang: String = "ko"
```
→
```swift
    @AppStorage("appLanguage") private var appLang: String = "ko"
```

같은 파일 32번째 줄:
```swift
        return appLang == "en" ? "Loading verse..." : "말씀을 불러오는 중..."
```
이 줄은 변경하지 않는다 (이미 정상적으로 언어 분기되어 있고, 이번 플랜의 신규 String Catalog 키 목록에 포함하지 않았다 — 후속 플랜 B2에서 다룬다).

- [ ] **Step 3: AlarmListView.swift 리네임**

`DailyVerse/DailyVerse/Features/Alarm/AlarmListView.swift:10`

```swift
    @AppStorage("greetingLanguage") private var appLang: String = "ko"
```
→
```swift
    @AppStorage("appLanguage") private var appLang: String = "ko"
```

- [ ] **Step 4: 빌드 확인**

Run: `xcodebuild build -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -15`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DailyVerse/DailyVerse/Features/Home/VerseCardView.swift DailyVerse/DailyVerse/Features/Saved/SavedDetailView.swift DailyVerse/DailyVerse/Features/Alarm/AlarmListView.swift
git commit -m "refactor: greetingLanguage → appLanguage 키 리네임 (VerseCardView/SavedDetailView/AlarmListView)"
```

---

## Task 5: MainTabView — 탭 라벨 5개 String Catalog 전환

**Files:**
- Modify: `DailyVerse/DailyVerse/App/MainTabView.swift:85-96`

**Interfaces:**
- Consumes: `appLanguageString(_:)` (Task 3), String Catalog 키 `tab.home`/`tab.alarm`/`tab.verses`/`tab.journal`/`tab.profile` (Task 2)
- Produces: 없음

- [ ] **Step 1: 탭 라벨 배열 교체**

`DailyVerse/DailyVerse/App/MainTabView.swift:85-96`

```swift
    @AppStorage("greetingLanguage") private var appLang: String = "ko"

    private var tabs: [(Int, String, String)] {
        let isEn = appLang == "en"
        return [
            (0, isEn ? "Home"    : "홈",     "house.fill"),
            (1, isEn ? "Alarm"   : "알람",   "alarm.fill"),
            (2, isEn ? "Verses"  : "말씀들", "book.closed.fill"),
            (3, isEn ? "Journal" : "묵상",   "pencil.and.scribble"),
            (4, isEn ? "Profile" : "프로필", "person.circle"),
        ]
    }
```
→
```swift
    @AppStorage("appLanguage") private var appLang: String = "ko"

    private var tabs: [(Int, String, String)] {
        [
            (0, appLanguageString("tab.home"),    "house.fill"),
            (1, appLanguageString("tab.alarm"),   "alarm.fill"),
            (2, appLanguageString("tab.verses"),  "book.closed.fill"),
            (3, appLanguageString("tab.journal"), "pencil.and.scribble"),
            (4, appLanguageString("tab.profile"), "person.circle"),
        ]
    }
```

- [ ] **Step 2: 빌드 확인**

Run: `xcodebuild build -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -15`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 시뮬레이터 수동 확인**

Run: `xcodebuild -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' -configuration Debug build 2>&1 | tail -5 && open -a Simulator`

앱을 실행해 설정 > 언어를 English로 바꾼 뒤, 하단 탭바가 Home/Alarm/Verses/Journal/Profile로 표시되는지 확인. 한국어로 되돌리면 홈/알람/말씀들/묵상/프로필로 돌아오는지 확인.
Expected: 두 언어 모두 정상 표시, 혼용 없음.

- [ ] **Step 4: Commit**

```bash
git add DailyVerse/DailyVerse/App/MainTabView.swift
git commit -m "feat: 탭바 라벨을 String Catalog 키로 전환 (tab.home 등)"
```

---

## Task 6: SettingsView — "Appearance"/"외관" 섹션 라벨 전환

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Settings/SettingsView.swift:19,70`

**Interfaces:**
- Consumes: `appLanguageString(_:)`, 키 `settings.section.appearance`
- Produces: 없음

- [ ] **Step 1: 키 리네임**

`DailyVerse/DailyVerse/Features/Settings/SettingsView.swift:19`

```swift
    @AppStorage("greetingLanguage") private var greetingLanguage: String = "ko"
```
→
```swift
    @AppStorage("appLanguage") private var greetingLanguage: String = "ko"
```

- [ ] **Step 2: 섹션 타이틀 전환**

같은 파일 70번째 줄:
```swift
                    sectionCard(title: greetingLanguage == "en" ? "Appearance" : "외관") { appearanceRows }
```
→
```swift
                    sectionCard(title: appLanguageString("settings.section.appearance")) { appearanceRows }
```

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild build -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -15`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add DailyVerse/DailyVerse/Features/Settings/SettingsView.swift
git commit -m "feat: Settings 외관 섹션 타이틀을 String Catalog 키로 전환"
```

> 참고: `SettingsView.swift`의 나머지 `greetingLanguage`(372, 385번째 줄) 사용부는 이번 플랜에서 리네임 대상이 아니다 — 372번째 줄은 이번에 변경한 변수(`greetingLanguage`, 19번째 줄에서 키만 바뀜)를 그대로 계속 참조하므로 자동으로 호환된다. 385번째 줄의 `Picker("언어 / Language", ...)`는 언어 선택 UI 자체의 라벨로, 의도적으로 두 언어를 동시에 표시하는 문구라 변경하지 않는다.

---

## Task 7: AlarmStage2View — 버튼/접근성 라벨 전환

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Alarm/AlarmStage2View.swift:10,276,285,301,303,321-322,327`

**Interfaces:**
- Consumes: `appLanguageString(_:args:)`, 키 `verse.readMore`/`verse.readMore.accessibility`/`alarm.snooze.button`/`alarm.snooze.interval`/`alarm.snooze.accessibility`/`alarm.snooze.limitReached`/`alarm.rise.button`
- Produces: 없음

- [ ] **Step 1: 키 리네임 (10번째 줄)**

```swift
    @AppStorage("greetingLanguage") private var greetingLanguagePref: String = "ko"
```
→
```swift
    @AppStorage("appLanguage") private var greetingLanguagePref: String = "ko"
```

- [ ] **Step 2: "Read More" 라벨 전환 (276번째 줄)**

```swift
                    Text(greetingLanguagePref == "en" ? "Read More" : "말씀 깊게 보기")
```
→
```swift
                    Text(appLanguageString("verse.readMore"))
```

- [ ] **Step 3: 접근성 라벨 전환 (285번째 줄)**

```swift
            .accessibilityLabel(greetingLanguagePref == "en" ? "View interpretation and application" : "말씀 해석과 일상 적용 보기")
```
→
```swift
            .accessibilityLabel(appLanguageString("verse.readMore.accessibility"))
```

- [ ] **Step 4: 스누즈 버튼 라벨 전환 (301, 303번째 줄)**

```swift
                        Text(greetingLanguagePref == "en" ? "🌙  Snooze" : "🌙  스누즈")
```
→
```swift
                        Text(appLanguageString("alarm.snooze.button"))
```

```swift
                        Text(greetingLanguagePref == "en" ? "in \(coordinator.activeSnoozeInterval) min" : "\(coordinator.activeSnoozeInterval)분 후")
```
→
```swift
                        Text(appLanguageString("alarm.snooze.interval", args: coordinator.activeSnoozeInterval))
```

- [ ] **Step 5: 스누즈 접근성 라벨 전환 (321-322번째 줄)**

```swift
                    ? (greetingLanguagePref == "en" ? "Snooze for \(coordinator.activeSnoozeInterval) minutes" : "\(coordinator.activeSnoozeInterval)분 스누즈")
                    : (greetingLanguagePref == "en" ? "Snooze limit reached" : "스누즈 횟수 초과")
```
→
```swift
                    ? appLanguageString("alarm.snooze.accessibility", args: coordinator.activeSnoozeInterval)
                    : appLanguageString("alarm.snooze.limitReached")
```

- [ ] **Step 6: "Rise" 버튼 라벨 전환 (327번째 줄)**

```swift
                    Text(greetingLanguagePref == "en" ? "☀️  Rise" : "☀️  일어나기")
```
→
```swift
                    Text(appLanguageString("alarm.rise.button"))
```

- [ ] **Step 7: 빌드 확인**

Run: `xcodebuild build -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -15`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 시뮬레이터 수동 확인**

알람 팝업(Stage2)을 English 상태에서 트리거해 "Read More"/"🌙 Snooze"/"in N min"/"☀️ Rise" 문구가 정상 표시되는지, 스누즈 3회 초과 시 "Snooze limit reached"로 전환되는지 확인.
Expected: 혼용 없이 전부 영어로 표시.

- [ ] **Step 9: Commit**

```bash
git add DailyVerse/DailyVerse/Features/Alarm/AlarmStage2View.swift
git commit -m "feat: AlarmStage2 버튼/접근성 라벨을 String Catalog 키로 전환"
```

> 참고: 45번째 줄 `alarmMode.alarmGreetingKr`/`alarmGreetingEn` 분기와 27, 95, 256번째 줄의 `verse.verseFull(lang:)`류 콘텐츠 선택 호출부는 이번 플랜의 대상이 아니다(Global Constraints 참조) — `greetingLanguagePref` 변수 자체의 키는 Step 1에서 이미 리네임됐으므로 그대로 정상 동작한다. 430번째 줄의 별도 `langPref` 변수도 동일한 이유로 키만 리네임한다: `@AppStorage("greetingLanguage") private var langPref: String = "ko"` → `@AppStorage("appLanguage") private var langPref: String = "ko"`.

---

## Task 8: HomeView — "Read More" 라벨 전환 + 키 리네임

**Files:**
- Modify: `DailyVerse/DailyVerse/Features/Home/HomeView.swift:13,303`

**Interfaces:**
- Consumes: `appLanguageString(_:)`, 키 `verse.readMore`
- Produces: 없음

- [ ] **Step 1: 키 리네임 (13번째 줄)**

```swift
    @AppStorage("greetingLanguage") private var greetingLanguagePref: String = "ko"
```
→
```swift
    @AppStorage("appLanguage") private var greetingLanguagePref: String = "ko"
```

- [ ] **Step 2: "Read More" 라벨 전환 (303번째 줄)**

```swift
                Text(greetingLanguagePref == "en" ? "Read More" : "말씀 깊게 보기")
```
→
```swift
                Text(appLanguageString("verse.readMore"))
```

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild build -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -15`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add DailyVerse/DailyVerse/Features/Home/HomeView.swift
git commit -m "feat: HomeView Read More 라벨을 String Catalog 키로 전환"
```

> 참고: 101, 107, 217, 245, 315, 342, 360번째 줄은 `GreetingLanguage`/콘텐츠 선택(`verse.verseFull(lang:)`) 관련이라 이번 플랜의 대상이 아니다.

---

## Task 9: VerseDetailBottomSheet — 미분기 하드코딩 문자열 신규 처리 (버그 수정)

이 파일은 조사 중 발견된 버그다: `해석`/`오늘의 적용`/`저장`/`묵상`/`닫기` 라벨이 애초에 언어 분기 없이 한국어로 고정되어 있었다. English 유저에게는 지금까지 이 화면이 한국어로만 보였다.

**Files:**
- Modify: `DailyVerse/DailyVerse/Common/Components/VerseDetailBottomSheet.swift:26,38,53,102,119,126,141,156`

**Interfaces:**
- Consumes: `appLanguageString(_:)`, 키 `verseDetail.interpretation.label`/`verseDetail.application.label`/`verseDetail.save.saved`/`verseDetail.save.button`/`verseDetail.save.accessibility`/`verseDetail.meditation.button`/`verseDetail.meditation.accessibility`/`verseDetail.close.accessibility`
- Produces: 없음

- [ ] **Step 1: 키 리네임 (26번째 줄)**

```swift
    @AppStorage("greetingLanguage") private var appLang: String = "ko"
```
→
```swift
    @AppStorage("appLanguage") private var appLang: String = "ko"
```

- [ ] **Step 2: "해석" 라벨 (38번째 줄)**

```swift
                        Label("해석", systemImage: "text.magnifyingglass")
```
→
```swift
                        Label(appLanguageString("verseDetail.interpretation.label"), systemImage: "text.magnifyingglass")
```

- [ ] **Step 3: "오늘의 적용" 라벨 (53번째 줄)**

```swift
                        Label("오늘의 적용", systemImage: "sparkles")
```
→
```swift
                        Label(appLanguageString("verseDetail.application.label"), systemImage: "sparkles")
```

- [ ] **Step 4: 저장 버튼 텍스트 (102번째 줄)**

```swift
                    Text(isSaved ? "저장됨 ✓" : "저장")
```
→
```swift
                    Text(isSaved ? appLanguageString("verseDetail.save.saved") : appLanguageString("verseDetail.save.button"))
```

- [ ] **Step 5: 저장 버튼 접근성 라벨 (119번째 줄)**

```swift
            .accessibilityLabel("말씀 저장하기")
```
→
```swift
            .accessibilityLabel(appLanguageString("verseDetail.save.accessibility"))
```

- [ ] **Step 6: 묵상 버튼 텍스트 (126번째 줄)**

```swift
                    Text("묵상")
```
→
```swift
                    Text(appLanguageString("verseDetail.meditation.button"))
```

- [ ] **Step 7: 묵상 버튼 접근성 라벨 (141번째 줄)**

```swift
            .accessibilityLabel("묵상 탭으로 이동")
```
→
```swift
            .accessibilityLabel(appLanguageString("verseDetail.meditation.accessibility"))
```

- [ ] **Step 8: 닫기 버튼 접근성 라벨 (156번째 줄)**

```swift
            .accessibilityLabel("닫기")
```
→
```swift
            .accessibilityLabel(appLanguageString("verseDetail.close.accessibility"))
```

- [ ] **Step 9: 빌드 확인**

Run: `xcodebuild build -project DailyVerse/DailyVerse.xcodeproj -scheme DailyVerse -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -15`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 10: 시뮬레이터 수동 확인**

English 상태에서 말씀 상세 바텀시트를 열어 "Interpretation"/"Today's Application"/"Save"/"Journal"/닫기(X) 아이콘 접근성이 전부 영어로 표시되는지 VoiceOver 또는 Accessibility Inspector로 확인. 저장 탭 시 "Saved ✓"로 바뀌는지 확인.
Expected: 혼용 없이 전부 영어. 한국어 상태에서는 기존과 동일하게 표시.

- [ ] **Step 11: Commit**

```bash
git add DailyVerse/DailyVerse/Common/Components/VerseDetailBottomSheet.swift
git commit -m "fix: VerseDetailBottomSheet 미분기 하드코딩 문자열을 String Catalog 키로 전환

해석/오늘의 적용/저장/묵상/닫기 라벨이 언어 분기 없이 한국어로 고정되어 있던 버그 수정."
```

---

## Self-Review 결과 (플랜 작성자 기준)

1. **스펙 커버리지**: 설계문서 2.1절(String Catalog 도입), 2.2절(자동감지 버그 수정 + Bundle 명시적 로드)을 각각 Task 1-2, Task 3에서 구현. 33개 기존 호출부는 Task 4(리네임만 필요한 3파일)와 Task 5-9(실제 UI 라벨 전환이 필요한 6파일)로 전부 커버됨.
2. **플레이스홀더 스캔**: "TBD"/"추가 처리 필요" 등 표현 없음. 모든 스텝에 실제 코드 diff 포함.
3. **타입 일관성**: `appLanguageString(_:args:)` 시그니처를 Task 3에서 정의한 그대로 Task 5-9 전체에서 동일하게 사용.
4. **범위 경계**: Global Constraints에 명시한 대로, 콘텐츠 선택용 `lang:` 파라미터와 이번 플랜에 없는 나머지 하드코딩 문자열(SettingsView 372번째 줄 등)은 의도적으로 제외 — 각 Task 말미에 "참고" 각주로 왜 제외했는지 명시함.

---

## 후속 플랜 (이번 스코프 아님)
- **B2**: 이번 플랜에서 다루지 않은 앱 전역의 나머지 하드코딩 한국어 문자열(온보딩 4화면, Saved 그리드 빈 상태, Alert/Toast 문구 등) String Catalog 전환.
- **A**: 콘텐츠 갭 채우기(`question_en`/`alarm_top_en` 488개, `greetings_en` 176개, `alarm_greetings_en` 35개) — 기존 Sheets 파이프라인 실행. 코드 변경 없음.
- **C**: App Store Connect English(U.S.) 로케일 등록, 영어 스크린샷 촬영, Privacy Policy/Terms 영어본 작성.
