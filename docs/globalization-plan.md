# morning manna — 영어 글로벌화 계획

> 작성일: 2026-05-07
> 현재 상태: 계획 수립 완료 (미착수)
> 목표: iOS 단일 앱 내 한국어 + 영어 지원 (표준 iOS 로컬라이제이션)

---

## 1. 전략 결정

### 채택: 단일 앱 + iOS 로컬라이제이션 (Option A)

iOS 기기 언어에 따라 자동 전환:
- 기기 언어 = 한국어 → 한국어 UI + 한국어 콘텐츠
- 기기 언어 = English → 영어 UI + 영어 콘텐츠

**채택 이유**: App Store 리뷰/평점 축적을 한 앱에서 관리. 코드베이스 단일 유지.

---

## 2. 현황 진단

| 항목 | 수치 |
|------|------|
| 전체 Swift 파일 | 95개 |
| 한국어 텍스트 포함 파일 | 94개 (98.9%) |
| 한글 문자열 인스턴스 | 약 2,715개 |
| 현재 Localization 인프라 | Build setting만 켜져 있음, 실제 구현 없음 |
| `Localizable.strings` / `.xcstrings` | ❌ 없음 |

---

## 3. 작업 범위

글로벌화는 **UI 문자열 + 콘텐츠 DB** 두 영역 모두 필요.

```
UI 문자열 (~2,715개)
     +
성경 말씀 콘텐츠 (~398개 구절)
├── verse_full_ko → verse_full_en
├── verse_short_ko → verse_short_en
├── interpretation → interpretation_en
├── application → application_en
└── question → question_en

인사말 콘텐츠
├── greetings/ (134개) → 영문 인사말
└── alarm_greetings/ (35개) → 영문 인사말
```

---

## 4. 파일 구조 (구현 시)

### iOS String Catalog (Xcode 15+ 권장)

```
DailyVerse/
└── Resources/
    └── Localizable.xcstrings      ← JSON 기반, Git 친화적
```

`Localizable.xcstrings` 구조:
```json
{
  "sourceLanguage": "ko",
  "strings": {
    "alarm.list.empty.title": {
      "comment": "알람 탭 빈 상태 제목",
      "localizations": {
        "ko": { "stringUnit": { "value": "알람이 없어요" } },
        "en": { "stringUnit": { "value": "No alarms yet" } }
      }
    }
  }
}
```

### Key 네이밍 체계

```
{feature}.{component}.{description}

예시:
alarm.list.empty.title
alarm.add.save.button
home.verse.detail.label
onboarding.welcome.subtitle
settings.language.korean
```

### 코드 변경 패턴

```swift
// 기존 (변경 전)
Text("알람이 없어요")

// 변경 후
Text("alarm.list.empty.title", tableName: "Localizable")
// 또는
Text(String(localized: "alarm.list.empty.title"))
```

---

## 5. Firestore DB 구조 변경

```
// 현재
verses/{id}
  verse_full_ko: "두려워하지 말라 내가 너와 함께 함이라"
  interpretation: "하나님이 우리 곁에..."
  application: "오늘 두려운 일이 있다면..."

// 글로벌화 후
verses/{id}
  verse_full_ko: "두려워하지 말라 내가 너와 함께 함이라"   ← 유지
  verse_full_en: "Fear not, for I am with you"              ← 신규
  verse_short_ko: "두려워하지 말라"
  verse_short_en: "Fear not"
  interpretation_ko: "하나님이 우리 곁에..."               ← rename (기존 interpretation)
  interpretation_en: "God promises His presence..."          ← 신규
  application_ko: "오늘 두려운 일이 있다면..."             ← rename (기존 application)
  application_en: "When you face fear today..."              ← 신규
  question_ko: "지금 당신이 두려워하는 것은 무엇인가요?"
  question_en: "What are you afraid of right now?"           ← 신규
```

> **주의**: 기존 `interpretation`, `application` 필드는 `_ko` suffix로 rename 필요.
> iOS 앱 코드도 동시에 수정해야 함 (VerseSelector, FirestoreService 등).

---

## 6. Google Sheets 탭 구조 변경

| 탭 | 추가 컬럼 |
|----|----------|
| `VERSES` | `verse_full_en`, `verse_short_en`, `interpretation_en`, `application_en`, `question_en` |
| `HOME_GREETINGS` | `text_en` |
| `ALARM_GREETINGS` | `text_en` |

> Google Sheets = Single Source of Truth 원칙 유지.
> 모든 영문 콘텐츠를 Sheets에 먼저 작성 → `sync_verses.js` 업데이트 → Firestore 동기화.

---

## 7. 성경 저작권 (중요)

| 번역본 | 저작권 상태 | 상업적 사용 |
|--------|-----------|------------|
| **KJV** (King James Version) | 퍼블릭 도메인 ✅ | 자유롭게 사용 가능 |
| **WEB** (World English Bible) | 퍼블릭 도메인 ✅ | 자유롭게 사용 가능 |
| ESV | 저작권 있음 ⚠️ | 500구절 초과 시 라이선스 필요 |
| NIV | 저작권 있음 ❌ | 별도 라이선스 필요 |

**권장**: **KJV** (가장 광범위하게 알려진 공개 도메인 번역)
또는 **WEB** (현대적 영어, 완전 공개)

> 앱 정보/이용약관에 출처 표기 필수:
> - 한국어: "성경 본문: 개역한글, 대한성서공회"
> - 영어: "Scripture quotations from the King James Version (KJV), public domain"

---

## 8. Settings 언어 선택 메뉴

현재 Settings에 "인사말 언어 [한국어] [랜덤]" 항목이 존재.
여기에 영어 옵션 추가:

```
Settings → 앱 설정 → 인사말 언어
[한국어] [English] [랜덤]
```

또는 시스템 언어 자동 감지 + 수동 override 옵션 제공.

---

## 9. 난이도 / 소요 시간

| 단계 | 작업 내용 | 난이도 | Sonnet 자율 처리 | 소요 시간 |
|------|----------|--------|-----------------|-----------|
| **1. 인프라 세팅** | xcstrings 생성, 프로젝트 설정 | ★☆☆☆☆ | ✅ 가능 | 1~2일 |
| **2. UI 문자열 추출** | 94개 파일 → key-value 추출 | ★★★☆☆ | ✅ 가능 | 3~5일 |
| **3. 영문 번역 (UI)** | 버튼/레이블/토스트 영문 작성 | ★★☆☆☆ | ✅ 가능 | 2~3일 |
| **4. 말씀 콘텐츠 영문화** | 398개 구절 + interpretation + application | ★★★★☆ | ⚠️ 반자동 | **2~3주** |
| **5. 인사말 영문화** | greetings 134개 + alarm_greetings 35개 | ★★☆☆☆ | ✅ 가능 | 3~5일 |
| **6. 날짜/숫자 포맷** | "M월 d일" → locale-aware 처리 | ★★☆☆☆ | ✅ 가능 | 1~2일 |
| **7. App Store 메타데이터** | 영문 설명, 스크린샷, 키워드 | ★☆☆☆☆ | ✅ 가능 | 1일 |

**총 예상 소요**: Sonnet 집중 진행 시 **3~4주**

> 병목 구간: 말씀 콘텐츠 영문화 (Phase 4).
> ESV/NIV 원문 대신 KJV 원문을 성경 API로 자동 매핑하면 단축 가능.

---

## 10. 실행 계획 (Phase별)

### Phase 1 — 인프라 (2~3일)
- [ ] `Localizable.xcstrings` 생성
- [ ] `AppLanguageManager` 싱글톤 추가 (언어 감지 + 수동 선택)
- [ ] Firestore 필드 구조 확정 (`_ko` / `_en` suffix 방식)
- [ ] Google Sheets `VERSES` 탭에 `_en` 컬럼 추가

### Phase 2 — UI 문자열 (1주)
- [ ] 94개 파일에서 한글 `Text()` 전수 추출
- [ ] Key 네이밍 체계 수립 및 `Localizable.xcstrings` 등록
- [ ] 영문 번역 작성
- [ ] 복수형 처리 (`stringsdict` 또는 xcstrings plural 기능)

### Phase 3 — 콘텐츠 DB (2~3주)
- [ ] KJV/WEB 원문 API로 `verse_full_en` 자동 매핑
- [ ] `verse_short_en` Claude Haiku로 추출
- [ ] `interpretation_en` / `application_en` Claude Haiku로 일괄 생성
- [ ] `sync_verses.js` 업데이트 → `_en` 필드 포함 Firestore 동기화
- [ ] `FirestoreService.swift` 필드명 업데이트 (`interpretation` → `interpretation_ko`)

### Phase 4 — 엣지케이스 폴리싱 (3~5일)
- [ ] 날짜 포맷 locale 처리 (`"M월 d일"` → `DateFormatter` locale-aware)
- [ ] 공기질 단계 ("좋음/보통/나쁨/매우나쁨" → "Good/Moderate/Bad/Very Bad")
- [ ] 기기 언어 변경 시 실시간 반영 테스트
- [ ] RTL 언어 대비 레이아웃 확인 (추후 확장 고려)

### Phase 5 — 글로벌 출시 (2~3일)
- [ ] App Store Connect 영문 메타데이터 작성
- [ ] 영문 스크린샷 생성
- [ ] 이용약관/개인정보처리방침 영문 버전
- [ ] 성경 저작권 표기 추가 (KJV 선택 시)

---

## 11. 특이사항 & 주의점

### 날짜 포맷
```swift
// 변경 전 (한국어 고정)
"M월 d일 EEE"

// 변경 후 (locale-aware)
let formatter = DateFormatter()
formatter.locale = Locale.current
formatter.dateStyle = .medium
```

### 복수형 처리
```swift
// 한국어: "외 3개 더"
// 영어: "3 more" (단수/복수 구분 없음)
// 단, 일부 언어(프랑스어 등)는 복수형 규칙 복잡
// → xcstrings의 plural 기능 활용
```

### 인터폴레이션 문자열
```swift
// 변경 전
"\(streakManager.currentStreak)일 연속"

// 변경 후
String(localized: "streak.days \(streakManager.currentStreak)")
// xcstrings에서: "%lld days in a row" (en) / "%lld일 연속" (ko)
```

---

## 12. 참고 문서

- [Apple Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [String Catalogs (Xcode 15+)](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [KJV Public Domain](https://www.kingjamesbibleonline.org/About-The-King-James-Bible/)
- [World English Bible](https://worldenglishbible.org/)
- 관련 내부 문서: `docs/content-schema.md`, `docs/contents-guideline.md`
