---
feature: greeting-update
phase: plan
created: 2026-04-14
status: active
---

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | greeting-update — Zone별 동적 인사말 시스템 |
| 날짜 | 2026-04-14 |
| 범위 | Firestore 동기화 + 언어 설정 + 동적 랜덤 선택 + UI 길이 대응 |

### Value Delivered (4-Perspective)

| 관점 | 내용 |
|------|------|
| Problem | 인사말이 Zone당 1개로 고정되어 반복 노출 시 신선함이 없음. 영/한 선호도 반영 불가 |
| Solution | Firestore greetings 컬렉션에서 Zone별 풀을 구성, 랜덤 선택 + 언어 설정 적용 |
| Function UX Effect | 매 Zone 진입마다 다른 인사말 경험. 선호 언어로 일관된 감성 전달 |
| Core Value | 콘텐츠 다양성 확보 → 재방문 동기 강화, 크리스천 감성 루틴의 완성도 상승 |

## Context Anchor

| 축 | 내용 |
|----|------|
| WHY | greeting 탭에 Zone별 한/영 각 10~12개 변형이 준비됐으나 앱에서 활용하지 못하고 있음 |
| WHO | 매일 아침·저녁 앱을 여는 크리스천 사용자 |
| RISK | Firestore 장애 시 폴백 없으면 인사말 공백 발생. 텍스트 길이 편차로 레이아웃 깨짐 가능 |
| SUCCESS | Zone 진입 시 항상 인사말 표시, 언어 설정 반영, UI 레이아웃 깨짐 없음 |
| SCOPE | GreetingService + Settings UI + 영향받는 View 4개 수정. Firestore 업로드 스크립트 포함 |

---

## 1. 요구사항

### 1-1. Firestore greetings 컬렉션 구축
- Google Sheets `greeting` 탭 데이터를 Firestore `greetings/` 컬렉션으로 업로드
- 문서 ID = `gr_id` (예: `gr_deep_dark_ko_01`)
- 필드: `zone_id`, `language` (`ko` | `en`), `text`, `char_count`
- 업로드 스크립트: `scripts/upload_greetings.js`

### 1-2. 언어 설정 (Settings)
- SettingsView 내 "앱 설정" 섹션에 "인사말 언어" 항목 추가
- 선택지: **한국어** / **English** / **랜덤** (기본값: 랜덤)
- UserDefaults 키: `greetingLanguage` (String: `"ko"` | `"en"` | `"random"`)
- 설정 변경 즉시 적용 (다음 Zone 진입 시 반영)

### 1-3. GreetingService
- Zone(`AppMode`) + 언어 설정을 받아 Firestore에서 해당 풀을 fetch
- 랜덤 선택 후 반환
- **캐시 정책**: Zone 진입 시 1회 선택 고정 (같은 Zone 내에서는 동일 인사말 유지)
- 캐시 키: `zone.rawValue` (Zone 전환 시 자동 무효화)
- **폴백**: Firestore 실패 시 `AppMode.greeting` / `AppMode.greetingKr` 하드코딩 값 사용

### 1-4. UI 텍스트 길이 대응
- greeting 텍스트를 표시하는 모든 뷰에 `minimumScaleFactor(0.7)` + `lineLimit(2)` 적용
- 레이아웃 영역(높이·너비)은 고정, 텍스트만 축소
- 영향 뷰: HomeView, AlarmStage2View, ONBExperienceView, DevotionHomeView

### 1-5. AppMode 정리
- `greeting`, `greetingKr` 프로퍼티는 폴백용으로 유지 (삭제 금지)
- 앱 코드에서 직접 `appMode.greeting` 호출 → `GreetingService` 경유로 전환

---

## 2. 기술 설계 개요

### GreetingService 인터페이스
```swift
class GreetingService: ObservableObject {
    @Published var currentGreeting: String = ""

    func loadGreeting(for mode: AppMode) async
    // zone_id 기준 Firestore 쿼리 → 언어 필터 → 랜덤 선택 → 캐시 저장
}
```

### 캐시 구조 (메모리)
```swift
private var cache: [String: String] = [:]
// key: "deep_dark_ko", value: "이 밤도 당신 편이에요."
```

### 언어 선택 로직
```swift
enum GreetingLanguage: String {
    case ko, en, random
}

// random일 경우: Bool.random() → ko or en
```

### Firestore 쿼리
```
greetings
  where zone_id == "deep_dark"
  where language == "ko"   // 또는 "en"
  → 전체 fetch 후 randomElement()
```

### Settings UI 위치
```
SettingsView
└── Section: 앱 설정 (기존 또는 신규)
    └── Row: 인사말 언어
        └── Picker: 한국어 / English / 랜덤
```

---

## 3. 영향 범위

| 파일 | 변경 유형 | 내용 |
|------|-----------|------|
| `scripts/upload_greetings.js` | 신규 | Sheets → Firestore 업로드 |
| `Core/Services/GreetingService.swift` | 신규 | 랜덤 greeting fetch + 캐시 |
| `Core/Models/Greeting.swift` | 신규 | Greeting 데이터 모델 |
| `App/AppMode.swift` | 유지 | 폴백용 하드코딩 값 보존 |
| `Features/Settings/SettingsView.swift` | 수정 | 언어 설정 Picker 추가 |
| `Features/Home/HomeView.swift` | 수정 | GreetingService 연동 + minimumScaleFactor |
| `Features/Alarm/AlarmStage2View.swift` | 수정 | 동일 |
| `Features/Onboarding/Screens/ONBExperienceView.swift` | 수정 | 동일 |
| `Features/Meditation/DevotionHomeView.swift` | 수정 | 동일 |

---

## 4. 구현 순서

1. **Firestore 업로드** — `upload_greetings.js` 작성 및 실행 (데이터 선행 확보)
2. **Greeting 모델** — `Greeting.swift` 데이터 구조 정의
3. **GreetingService** — fetch + 캐시 + 폴백 구현
4. **Settings** — `greetingLanguage` UserDefaults + SettingsView UI
5. **View 연동** — HomeView 우선, 나머지 3개 뷰 순차 적용
6. **UI 길이 대응** — minimumScaleFactor 일괄 적용 및 시뮬레이터 확인

---

## 5. 성공 기준

- [ ] 모든 Zone에서 인사말이 항상 표시됨 (Firestore 정상 / 오프라인 폴백 포함)
- [ ] 언어 설정(한/영/랜덤)이 즉시 반영됨
- [ ] 같은 Zone 내 앱 재진입 시 동일 greeting 유지
- [ ] Zone 전환 시 새 greeting 선택됨
- [ ] 가장 긴 greeting(EN 31자)도 레이아웃 깨짐 없이 표시됨
- [ ] Firestore 실패 시 하드코딩 폴백으로 정상 표시됨

---

## 6. 미포함 범위 (Out of Scope)

- greeting 콘텐츠 추가 생성 (이미 Sheets에 충분한 데이터 있음)
- greeting 즐겨찾기 / 저장 기능
- Premium/Free 차별화 (모든 유저 동일 greeting 풀)
