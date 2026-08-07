# 영어 글로벌 출시 설계 (English Global Launch)

> 작성일: 2026-08-07
> 목표: 마이만나(morning manna)를 미국 중심 영어권 시장에 App Store로 정식 출시
> 스코프: 앱 내 콘텐츠·UI 언어 지원 + App Store Connect 리스팅 로컬라이즈. 결제/가격 로컬라이즈는 제외(별도 프로젝트).

---

## 1. 배경 및 현재 상태

### 1.1 목표
- 1차 목표는 **글로벌 마켓 진출**(신규 영어권 유저 유입)이며, 단순 인앱 접근성 확장이 아니다.
- 타겟 시장: **미국 중심, 영어권 전체 커버** (UK/AU/CA 등은 자연 유입, 별도 로케일 최적화는 하지 않음).
- 서비스 구성(화면 구조, 기능, 요금제 구조)은 한국어판과 동일하게 유지한다. 언어만 다르다.

### 1.2 기존에 이미 진행된 작업 (조사로 확인됨)
- `Verse` 모델에 `verse_full_en`/`verse_short_en`/`interpretation_en`/`application_en` 필드 존재.
- Firestore `verses` 컬렉션: **active 488개 전량 위 4개 필드 100% 완료** (KJV 기반, `content-writer` 에이전트 + Sheets 파이프라인으로 생성).
- `UserDefaults` 키 `greetingLanguage`("ko"/"en")로 9개 파일·33곳에서 `if/else` 삼항분기 방식으로 일부 UI 텍스트 분기 처리 중 (Settings, MainTabView 탭 라벨, HomeView, AlarmStage2View 등).
- Settings에 언어 선택 Picker 존재 (한국어/English, 2개 옵션).

### 1.3 확인된 문제/갭
| 영역 | 상태 |
|---|---|
| 최초 실행 시 언어 자동감지 | **버그**: 커밋 메시지는 "기기 언어 자동 감지"라 되어있으나, 실제 코드(`DailyVerseApp.swift:25-27`)는 무조건 `"ko"` 고정 |
| UI 문자열 아키텍처 | Apple 표준 String Catalog 미사용. 수동 삼항분기 33곳 + 그 외 하드코딩된 한국어 문자열 다수(전체 앱) |
| `verses.question` (묵상 질문, active 488개) | `question_en` **0%** |
| `verses.alarm_top_ko` (알람탭 상단표시, active 488개) | `alarm_top_en` **0%** |
| `greetings` (홈 인사말, 176개) | 영어 버전 **0%** |
| `alarm_greetings` (알람 팝업 인사말, 35개) | 영어 버전 **0%** |
| `daily_cards` (절기 편성, 12개) | `greeting_en` **100% 완료** (이미 끝남) |
| Info.plist `CFBundleLocalizations` | 미선언 |
| App Store Connect 리스팅 | 한국어만 등록. Apple 공식 문서 확인 결과, 미국 등 영어권 유저도 **영어 로케일이 없으면 한국어 리스팅을 그대로 보게 됨** (폴백 없음) |
| Privacy Policy / Terms of Service | 영어본 없음 |

### 1.4 스코프 경계 (제외 항목, 확정)
- **가격/결제 로컬라이즈 제외**: 현재 Premium 구매 UI는 App Store 심사 대응(2.1)으로 전역 숨김 처리되어 있고 `purchase()`/`restore()` 미구현 상태. Free 기능만으로 영어권 유저도 문제없이 이용 가능하므로, RevenueCat/StoreKit 다중 통화·가격 설정은 이번 스코프에서 제외하고 추후 Premium 재도입 시점에 별도 처리.

---

## 2. 아키텍처 결정: 하이브리드 방식

세 가지 방안을 비교한 결과 **하이브리드 방식**을 채택한다.

| | A. String Catalog 전면 전환 | B. 기존 방식(삼항분기) 확장 | **C. 하이브리드 (채택)** |
|---|---|---|---|
| UI 문자열 | Apple 표준 String Catalog | 계속 `if/else` 확장 | **String Catalog로 이전** |
| 콘텐츠(구절/인사말/질문) | 부적합(컴파일타임 문자열 전용) | 기존 `_en` 필드 방식 | **기존 `_en` 필드 방식 유지** |
| 3번째 언어 확장성 | 좋음 | 나쁨 | 좋음 |
| 번역 워크플로 | Xcode 표준 export/import | 수동 코드 리뷰 | UI는 Xcode 표준, 콘텐츠는 기존 Sheets 파이프라인 |

**근거**: 정적 UI 문자열(메뉴명, 버튼, 알럿)과 서버발 동적 콘텐츠(성경 구절, 인사말)는 애초에 다른 메커니즘으로 다루는 것이 Apple 권장 표준이다. String Catalog는 컴파일 타임에 고정된 문자열용이며 Firestore에서 오는 동적 콘텐츠에는 적용되지 않는다. 콘텐츠는 이미 90%(구절 기준) 완성된 `_en` 필드 파이프라인을 그대로 재사용한다.

### 2.1 UI 문자열 처리
- `Info.plist`에 `CFBundleLocalizations: [ko, en]` 추가.
- `en.lproj`/`ko.lproj` 기반 String Catalog(`Localizable.xcstrings`) 도입.
- 기존 9개 파일·33곳의 `greetingLanguage` 삼항분기 + 그 외 하드코딩된 한국어 UI 문자열 전체를 String Catalog 키로 전환.
- `UserDefaults` 키 `greetingLanguage` → `appLanguage`로 리네임. 기존 유저의 저장된 값은 마이그레이션 코드로 보존(키 이름만 바뀌고 값 유실 없음).

### 2.2 언어 선택 동작
- 앱 내 "설정 > 언어 선택"은 **기기 언어와 독립적인 수동 토글**로 유지한다 (기존 UX 그대로, iOS 시스템 로케일 연동 방식으로 바꾸지 않음).
- 최초 실행 시 기본값 로직을 수정한다: `Locale.current.language.languageCode == "en"` → 기본값 `"en"`, 그 외 → 기본값 `"ko"`. (현재 버그: 무조건 `"ko"` 고정을 수정)
- 선택된 언어 값(`appLanguage`)은 두 곳에 동일하게 적용된다: ① String Catalog의 `Bundle(path:)` 명시적 로드, ② Firestore 콘텐츠 필드 선택(`_en` vs `_ko`).
- 안전장치: 콘텐츠 필드가 예외적으로 비어있는 경우(정상 플로우에서는 3장의 콘텐츠 갭 해소로 발생하지 않아야 함) 빈 화면 대신 한국어 텍스트로 폴백한다.

---

## 3. 콘텐츠 갭 해소 (필수 선행 작업)

### 3.1 제약사항
CLAUDE.md의 "모든 유저 동일 말씀" 원칙에 따라 `selectDailyVerse` Cloud Function이 매일 자정 **단 하나의 verse_id**를 선택해 전 유저(언어 무관)에게 강제 적용한다. 즉 그날 선택된 구절의 `question_en`/`alarm_top_en`이 비어있으면 영어 유저는 그날 해당 항목이 빈 화면으로 노출된다.

**결론: 영어 지원을 실제로 오픈하기 전에 아래 4개 필드 카테고리는 반드시 100% 완료되어야 한다.**

### 3.2 채워야 할 항목 (정확한 수치, Firestore 직접 조회로 확인)
| 대상 | 개수 | 필드 |
|---|---|---|
| `verses` (active) | 488개 | `question_en` |
| `verses` (active) | 488개 | `alarm_top_en` |
| `greetings` | 176개 | 영어 버전 전체 |
| `alarm_greetings` | 35개 | 영어 버전 전체 |

### 3.3 방법
- 기존 파이프라인 재사용: Google Sheets(Single Source of Truth) → `content-writer` 에이전트/생성 스크립트 → `sync_verses.js`(또는 대응 스크립트)로 Firestore 반영.
- `question_en`은 기존 한국어 `question`(묵상 응답 질문)의 의미를 유지하되 영어 문화적 맥락에 맞게 새로 작성(직역 아님) — 기존 `interpretation_en`/`application_en` 생성 시 적용한 원칙과 동일.
- `alarm_top_en`은 없으면 `verse_short_en`으로 폴백 가능하나(스키마 상 선택 필드), 알람탭 UX 일관성을 위해 이번에 전량 채운다.
- 완료 후 `scripts/verify_en_fields.js`류 검증 스크립트로 100% 커버리지 확인.

---

## 4. App Store Connect 리스팅 로컬라이즈

- Primary language(한국어) 유지, **"English (U.S.)" 로케일 추가 등록**.
- 번역 대상: 앱 이름, 부제목(30자), 설명(4,000자), 프로모션 텍스트, 키워드(100자), 릴리즈 노트.
- 키워드는 한국어 키워드의 직역이 아니라, 미국 크리스천 알람앱 시장(Bible App, Abide, Alarmy, YouVersion 등 경쟁 앱) 기준으로 별도 리서치하여 작성한다 — 직역은 검색 매칭에 기여하지 않는다.
- 스크린샷: 기존 스크린샷은 한국어 UI 기준이라 재사용 불가. **2장의 UI 마이그레이션(2.1절) 완료 후** 영어 UI로 재촬영하여 `screenshots/`, `design-assets/appstore-screenshots/`에 영어 세트로 추가.

---

## 5. 법적 문서

- Privacy Policy, Terms of Service **영어본 신규 작성** (한국어 원문의 직역이 아니라 미국 유저 대상 법적 어휘·관행에 맞게 작성).
- 앱 내 Settings > 앱 정보의 "이용약관/개인정보처리방침" 링크가 `appLanguage` 값에 따라 다른 URL(한/영)을 가리키도록 연결.
- 성경 저작권 표기 갱신: 영어본에는 "King James Version, Public Domain"을 반영 (기존 한국어본의 "개역한글, 대한성서공회" 표기에 대응).

---

## 6. 실행 순서 및 테스트 계획

### 6.1 실행 순서 (의존관계 기준)
```
Phase 1 (병렬 가능, 서로 의존 없음)
├─ 1A. 콘텐츠 갭 채우기 (3장) — question_en/alarm_top_en 488개, greetings_en 176개, alarm_greetings_en 35개
├─ 1B. UI 문자열 → String Catalog 마이그레이션 + appLanguage 리네임 + 자동감지 버그 수정 (2장)
└─ 1C. Privacy Policy / Terms 영어본 작성 (5장)

Phase 2 (1B 완료 후)
└─ 2A. 영어 UI 스크린샷 재촬영

Phase 3 (1A+1B+1C+2A 완료 후)
├─ 3A. App Store Connect English(U.S.) 로케일 등록 (4장)
└─ 3B. QA (6.2절)

Phase 4
└─ TestFlight 영어 베타 → App Store 심사 제출
```

### 6.2 QA 체크리스트
- 언어 토글 시 앱 내 모든 화면(온보딩·홈·알람·저장·설정·알람팝업)에 한/영 혼용 텍스트가 없는지 화면별 점검.
- 오늘의 말씀이 영어 유저에게 `question_en`/`alarm_top_en`까지 정상 노출되는지 (Phase 1A 완료가 전제조건).
- 최초 실행 시 기기 언어 자동감지 정상 동작(영어 기기 → en, 그 외 → ko) + 설정에서 수동 전환 시 즉시 반영 확인.
- 기존 한국어 플로우 리그레션 없는지, `greetingLanguage` → `appLanguage` 마이그레이션이 기존 유저 설정값을 보존하는지 확인.
- Firestore 필드 예외적 누락 시 빈 화면 대신 한국어 폴백이 동작하는지 확인 (3장 완료 후에는 실제 발생하지 않아야 함 — 방어 코드 검증 목적).

---

## 7. 열린 질문 / 후속 과제 (이번 스코프 아님)
- Premium 가격/결제 로컬라이즈(RevenueCat/StoreKit 다중 통화)는 별도 프로젝트로 진행.
- UK/AU/CA 등 영어권 세부 로케일 최적화(통화 표기, 날씨 단위 등)는 이번 스코프에 없음 — 미국 중심 영어 하나로 전체 영어권 커버.
- 3번째 언어 확장은 이번 설계(String Catalog + `_en`/`_ko` 필드 패턴)로 구조적으로는 준비되나, 실제 착수는 별도 요청 시.
