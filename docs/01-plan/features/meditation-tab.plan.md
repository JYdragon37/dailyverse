# Plan: 묵상 탭 (Gallery → Meditation Tab 교체)

> 작성일: 2026-04-09
> 상태: Draft
> 담당 에이전트: swiftui-builder, data-engineer, firebase-engineer, alarm-engineer

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| 기능명 | 묵상 탭 신설 (Gallery 탭 교체) |
| 핵심 목표 | 리텐션 향상 — 매일 방문 이유 + 개인 아카이브 축적 |
| 탭 구조 변경 | Home \| 알람 \| 말씀들 \| **묵상** \| 프로필 |
| 경쟁사 근거 | Echo Prayer(응답됨), Glorify(감사공간), Hallow(스트릭) 검증된 패턴 |

### Value Delivered

| 관점 | 내용 |
|------|------|
| Problem | 갤러리 탭은 방문 동기가 없고, 리텐션에 기여하지 않음 |
| Solution | 기도 제목 + 감사 기록 + 스트릭으로 매일 돌아오는 이유 생성 |
| Function UX Effect | 알람 → 말씀 → 묵상 기록으로 하루 루틴 완성. 개인 데이터 축적으로 앱 이탈 비용 상승 |
| Core Value | "오늘 받은 말씀이 내 하루에 실제로 연결된다"는 경험 |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| WHY | 갤러리 탭 DAU 기여 없음. 묵상 탭은 매일 방문 이유를 만들어 D7/D30 리텐션↑ |
| WHO | 알람으로 말씀 받는 유저 → 그 말씀을 내 삶과 연결하고 기록하고 싶은 유저 |
| RISK | "묵상"이라는 단어의 진입 장벽. 비기독교인 유저에게 낯설 수 있음 → 심리적 부담 없는 UX 설계 필수 |
| SUCCESS | 묵상 탭 DAU ≥ 40%, 스트릭 7일+ 유저 ≥ 20%, Stage 2 입력 완료율 ≥ 15% |
| SCOPE | Gallery 제거 + 묵상 탭 신설 + Stage 2 선택 입력 연동. 기존 탭 5개 유지 |

---

## 1. 변경 범위 요약

### 제거 대상
- `Features/Gallery/GalleryView.swift`
- `Features/Gallery/GalleryViewModel.swift`
- `MainTabView.swift` 에서 GalleryView 탭 (tag 3)

### Gallery 핀 기능 이전
- **현재**: GalleryView → 모드별 이미지 핀 설정
- **이전 후**:
  1. `SavedDetailView` — "이 이미지를 홈 배경으로 설정" 버튼 추가
  2. `SettingsView` — "홈 배경" 신규 섹션 (현재 핀 이미지 확인 + 해제)
- GalleryViewModel의 `pinImage`, `unpinImage` 로직은 유지, 호출 위치만 변경

### 추가 대상
| 파일 | 설명 |
|------|------|
| `Features/Meditation/MeditationView.swift` | 묵상 탭 메인 화면 |
| `Features/Meditation/MeditationWriteSheet.swift` | 묵상 작성 모달 |
| `Features/Meditation/MeditationViewModel.swift` | 묵상 탭 ViewModel |
| `Features/Meditation/MeditationHistoryView.swift` | 히스토리 상세 |
| `Core/Models/MeditationEntry.swift` | 데이터 모델 |
| `Core/Managers/StreakManager.swift` | 스트릭 관리 |
| `Core/Repositories/MeditationRepository.swift` | Firebase + Core Data CRUD |
| `Core/Persistence/DailyVerse.xcdatamodeld` | Core Data 엔티티 추가 |

### 수정 대상
| 파일 | 변경 내용 |
|------|----------|
| `App/MainTabView.swift` | GalleryView → MeditationView 교체, 탭바 아이콘 변경 |
| `Features/Alarm/AlarmStage2View.swift` | 선택 입력창 추가 |
| `Features/Saved/SavedDetailView.swift` | 이미지 핀 버튼 추가 |
| `Features/Settings/SettingsView.swift` | "홈 배경" 섹션 추가 |
| `Core/Services/FirestoreService.swift` | meditation_logs CRUD 추가 |
| `Core/Services/NotificationManager.swift` | 묵상 리마인더 알림 추가 |

---

## 2. 유저 플로우 전체

### 2-1. 일반 묵상 작성 플로우 (핵심 플로우)

```
앱 진입 또는 탭바 [묵상] 탭 탭
│
├── [오늘 묵상 미기록 상태]
│   └── "오늘의 묵상" 카드 (작성 전 상태)
│       - 오늘의 말씀 참조 표시
│       - [+ 오늘의 묵상 시작하기] CTA 버튼
│       └── 탭 → MeditationWriteSheet 열림 (Slide-up 0.3s)
│
│           [MeditationWriteSheet]
│           ├── 오늘의 말씀 참조 카드 (탭하면 말씀 상세 바텀시트)
│           ├── 빠른 템플릿 칩: [😰 걱정] [🙏 부탁] [✨ 감사]
│           │   → 탭하면 해당 접두사 입력창에 자동 삽입
│           ├── 기도 제목 입력 필드 (multiline, 최대 200자/항목)
│           ├── [+ 기도 제목 추가] (최대 5개)
│           ├── 감사 기록 입력 필드 (선택, 최대 100자)
│           └── [저장하기] 버튼 (기도 제목 1개 이상 시 활성화)
│
│               탭 → 저장 완료
│               ├── 스트릭 +1 (오늘 처음 저장이라면)
│               ├── Toast: "✅ 오늘의 묵상이 기록되었어요"
│               ├── Heart pulse 애니메이션 (0.4s)
│               └── 시트 닫힘 → 메인 화면 업데이트
│
└── [오늘 묵상 완료 상태]
    └── "오늘의 묵상" 카드 (작성 후 상태)
        - ✅ 체크 배지 + 말씀 참조
        - 기도 제목 목록 (응답됨 배지 포함)
        - 감사 기록 (있으면 표시)
        - [편집] 버튼 → MeditationWriteSheet (기존 내용 채워진 상태)
```

### 2-2. 알람 연동 플로우 (Stage 2 경유)

```
알람 울림 (Stage 0 배너)
│
└── 배너 탭 → 앱 진입 (Stage 1 전체화면)
    "두려워하지 말라 내가 너와 함께 함이라"
    이사야 41:10
    [🔄 스누즈 5분] [종료]
    │
    └── [종료] 탭 → Stage 2 (Fade-in 0.6s)

        [Stage 2 — 웰컴 스크린]
        감성 이미지 풀스크린
        Good Morning ☀️  /  2026년 4월 9일 수요일
        말씀 카드
        날씨 위젯
        ─────────────────────────────────
        💭 오늘 이 말씀으로 한 마디  (선택)
        ┌──────────────────────────────┐
        │  마음에 떠오르는 것을 적어보세요... │
        └──────────────────────────────┘
        ─────────────────────────────────
        [♥저장]  [다음 말씀]  [× 닫기]
        │
        ├── 입력 후 [× 닫기] 탭
        │   → 묵상 탭에 오늘의 기록으로 자동 저장
        │   → 스트릭 인정 (묵상 1개 이상 기준 충족)
        │   → Toast: "✅ 오늘의 묵상이 기록되었어요"
        │   → 홈 탭으로 이동
        │
        ├── 입력 없이 [× 닫기] 탭
        │   → 저장 없이 홈 탭으로 이동 (기존 동작 유지)
        │
        └── [♥저장] 탭 (기존 동작) → 별개로 작동, 입력창과 무관
```

### 2-3. 기도 제목 응답됨 체크 플로우

```
묵상 탭 → 오늘의 묵상 카드 또는 히스토리 카드
│
└── 기도 제목 항목 롱프레스 (0.5s 햅틱)
    또는 항목 우측 끝 [···] 버튼 탭
    │
    └── 액션 시트 표시:
        [응답됨으로 표시] / [편집] / [삭제] / [취소]
        │
        └── [응답됨으로 표시] 탭
            → 기도 제목에 ✓ 배지 추가 (Green)
            → Toast: "🙏 기도에 응답하셨네요"
            → answeredAt 타임스탬프 기록
            → (이미 응답됨이면 → "응답됨 해제" 선택지 표시)
```

### 2-4. 히스토리 열람 플로우

```
묵상 탭 하단 "지난 묵상" 섹션 스크롤
│
├── [Free 유저]
│   ├── 최근 7일 카드: 자유 열람, 탭하면 상세 보기
│   └── 8일 이상 카드:
│       - 흐림 처리 (blur radius 6) + 🔒 자물쇠 아이콘
│       - "Premium에서 모든 묵상 기록을 되돌아보세요"
│       - 탭 → 업셀 바텀시트 (기존 UpsellBottomSheet 재사용)
│         메시지: "지난 기도의 응답을 모두 돌아보고 싶으신가요?"
│
└── [Premium 유저]
    ├── 전체 기록 무제한 열람
    ├── 월별 그룹핑 헤더 (2026년 4월, 2026년 3월, ...)
    └── 상단 필터: [전체] [응답됨만]
        → 응답됨 필터: answeredAt 있는 항목만 표시
```

### 2-5. 비로그인 유저 플로우

```
묵상 탭 진입 (비로그인)
│
└── 로컬 저장 허용 (Core Data only)
    - 묵상 작성 가능
    - 스트릭 로컬에서 추적
    - 로그인 유도 배너 상단 표시:
      "로그인하면 묵상 기록이 모든 기기에서 동기화돼요"
      [Apple로 시작하기]  [닫기]

    로그인 시:
    → 로컬 Core Data 기록을 Firebase로 자동 마이그레이션
    → 중복 날짜는 병합 (로컬 우선)
```

---

## 3. 화면별 UI 스펙

### 3-1. 묵상 탭 메인 화면 (MeditationView)

```
NavigationStack
│
├── NavigationBar
│   ├── Center: "묵상"
│   └── Right: calendar.badge.clock 아이콘 → 월별 달력 뷰 (추후)
│
├── ScrollView (vertical)
│   │
│   ├── [스트릭 카드] — 상단 고정
│   │   배경: dvPrimaryDeep + dvAccentGold 그라데이션 테두리 (2px)
│   │   Corner radius: 16
│   │   패딩: 16px
│   │   │
│   │   ├── 🔥 {currentStreak}일 연속 묵상 (dvTitle 폰트, dvAccentGold)
│   │   ├── 서브텍스트:
│   │   │   - 오늘 완료: "오늘도 묵상을 이어가셨네요 ✓"
│   │   │   - 오늘 미완료: "오늘 묵상을 아직 기록하지 않으셨어요"
│   │   └── 이번 달 미니 히트맵 (7열 dot 그리드)
│   │       - 묵상한 날: dvAccentGold dot (6px)
│   │       - 미묵상 날: White opacity 0.2 dot (6px)
│   │       - 오늘: 테두리 표시
│   │
│   ├── [오늘의 묵상 섹션]
│   │   헤더: "오늘의 묵상"  +  날짜 (2026.04.09 수)
│   │   │
│   │   ├── [미작성 상태]
│   │   │   카드: 배경 dvPrimaryMid opacity 0.5, corner 16
│   │   │   │
│   │   │   ├── 오늘의 말씀 참조 뱃지
│   │   │   │   "이사야 41:10 · Hope · 🌅 아침"
│   │   │   └── [+ 오늘의 묵상 시작하기] 버튼 (dvAccentGold, full width)
│   │   │
│   │   └── [작성 완료 상태]
│   │       카드: 배경 dvPrimaryMid opacity 0.5, 좌측 dvAccentGold 3px border
│   │       │
│   │       ├── ✅ 상단 우측 체크 배지
│   │       ├── 말씀 참조 뱃지 "이사야 41:10 · Hope"
│   │       ├── 기도 제목 목록 (최대 2개 표시, 더 있으면 "+N개 더")
│   │       │   각 항목: ● {text}  |  ✓ (응답됨이면 초록 배지)
│   │       ├── 감사 기록 (있으면): ✨ {gratitudeNote}
│   │       └── 우측 하단: [편집] 텍스트 버튼 (dvAccentGold)
│   │
│   └── [지난 묵상 섹션]
│       헤더: "지난 묵상"  +  오른쪽 [전체보기] (Premium만 활성화)
│       │
│       ├── [Free, 8일+ 기록 있음]
│       │   최근 7일: 정상 카드
│       │   8일+: 흐림 + 잠금 카드 + 업셀 CTA
│       │
│       └── 히스토리 카드 (날짜 역순)
│           ┌─────────────────────────────────┐
│           │ 2026.04.08 화 · 🌅 아침          │
│           │ 이사야 41:10 · Hope              │
│           │                                 │
│           │ 🙏 팀장 보고 잘 할 수 있도록       │
│           │ ✨ 점심이 맛있었다               │
│           │                        ✓ 응답됨  │
│           └─────────────────────────────────┘
│           탭 → MeditationHistoryView (상세 화면)
│
└── 빈 상태 (기록 전혀 없음)
    🕊 [비둘기/잎 아이콘, 48pt]
    "오늘 받은 말씀으로
     첫 묵상을 시작해보세요"
    [+ 오늘의 묵상 시작하기] 버튼
```

### 3-2. 묵상 작성 모달 (MeditationWriteSheet)

```
Sheet (.presentationDetents([.large]))
NavigationStack

NavigationBar:
  Left: [취소]
  Center: "오늘의 묵상"
  Right: (없음)

─────────────────────────────────────

[오늘의 말씀 참조 카드]
(탭하면 VerseDetailBottomSheet 열림)
배경: dvPrimaryMid opacity 0.3, corner 12
"두려워하지 말라 내가 너와 함께 함이라"
이사야 41:10  · Hope

─────────────────────────────────────

기도 제목  ℹ️
(ℹ️ 탭 → 툴팁: "오늘 걱정되는 것, 부탁하고 싶은 것을
               자유롭게 적어보세요")

빠른 시작 칩:
[😰 걱정]  [🙏 부탁]  [✨ 감사]
(탭하면 해당 칩 텍스트를 입력창 앞에 자동 삽입)

┌──────────────────────────────────┐
│ placeholder: "오늘 기도하고 싶은 것을 │
│             적어보세요..."          │
│                                  │
│                         200/200  │
└──────────────────────────────────┘

[+ 기도 제목 추가] (최대 5개, 5개 도달 시 비활성화)
(항목 삭제: 각 항목 우측 × 버튼)

─────────────────────────────────────

오늘 감사한 것  (선택)

┌──────────────────────────────────┐
│ placeholder: "오늘 감사한 한 가지는?"│
└──────────────────────────────────┘

─────────────────────────────────────

[저장하기] ← Full width, dvAccentGold
(기도 제목 1개 이상 입력 시 활성화)
```

### 3-3. 히스토리 상세 화면 (MeditationHistoryView)

```
NavigationStack

NavigationBar:
  Left: [← 뒤로]
  Center: "2026.04.08 화요일"

[말씀 참조 카드]
배경 이미지 섬네일 (있으면) + 말씀 텍스트
"두려워하지 말라 내가 너와 함께 함이라"
이사야 41:10 · Hope · 🌅 아침

[날씨 스냅샷] (저장 시 기록된 경우)
서울 18°C  💧 65%  좋음

─────────────────────────────────────
기도 제목 (N개)

● 팀장 보고 잘 할 수 있도록
  롱프레스 → [응답됨으로 표시 / 삭제]

✓ 오늘 할 일 다 완료하기  (응답됨)
  응답됨: 2026.04.08 오후 5:32

─────────────────────────────────────
감사 기록

✨ 점심이 맛있었다

─────────────────────────────────────
출처: 아침 알람 Stage 2 경유 (또는 "직접 기록")
```

### 3-4. Stage 2 웰컴 스크린 변경

```
[기존 Stage 2 레이아웃 유지]
감성 이미지 풀스크린
Good Morning ☀️
2026년 4월 9일 수요일
말씀 카드
날씨 위젯

────────────────────── (구분선, 높이 0.5, white opacity 0.2)

[신규 추가 영역]
💭  오늘 이 말씀으로 한 마디  (선택)

┌──────────────────────────────────────┐
│  마음에 떠오르는 것을 적어보세요...      │
│  (최대 100자, 키보드 올라오면 위로 스크롤) │
└──────────────────────────────────────┘

────────────────────── (구분선)

[♥저장]  [다음 말씀]  [× 닫기]
```

**동작 규칙:**
- 입력창 탭 → 키보드 올라옴 → 화면 전체 스크롤 업 (기존 콘텐츠 밀어 올리지 않음, 입력창만 키보드 위로)
- 입력 후 [× 닫기] → 묵상으로 저장 (source: "stage2")
- 미입력 [× 닫기] → 저장 없이 기존 동작 유지
- 입력 후 [♥저장] → 말씀 저장 + 묵상 저장 모두 실행
- 입력창 placeholder는 입력하면 사라짐 (기본 SwiftUI 동작)

---

## 4. 데이터 모델

### 4-1. MeditationEntry.swift

```swift
struct MeditationEntry: Identifiable, Codable {
    let id: String                      // UUID string
    let userId: String                  // Firebase Auth UID (비로그인: "local")
    let date: Date                      // 날짜 (자정 기준, 비교에만 사용)
    let verseId: String                 // 당일 말씀 ID
    let verseReference: String          // "이사야 41:10" (표시용 캐시)
    let mode: String                    // "morning" | "afternoon" | "evening" 등
    var prayerItems: [PrayerItem]       // 기도 제목 목록 (최대 5개)
    var gratitudeNote: String?          // 감사 기록 (선택)
    let createdAt: Date
    var updatedAt: Date
    let source: String                  // "manual" | "stage2"

    // 오늘 날짜인지 체크 (편집 허용 여부)
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct PrayerItem: Identifiable, Codable {
    let id: String                      // UUID string
    var text: String                    // 기도 제목 텍스트 (최대 200자)
    var isAnswered: Bool                // 응답됨 여부
    var answeredAt: Date?               // 응답됨 마킹 시각
}
```

### 4-2. Firestore 스키마

```
meditation_logs/{user_id}/entries/{entry_id}

Fields:
  id: String
  user_id: String
  date: Timestamp          // 날짜 (자정 기준)
  verse_id: String
  verse_reference: String
  mode: String
  prayer_items: [
    {
      id: String,
      text: String,
      is_answered: Bool,
      answered_at: Timestamp?
    }
  ]
  gratitude_note: String?
  created_at: Timestamp
  updated_at: Timestamp
  source: String
```

### 4-3. Core Data 엔티티 추가

**MeditationEntity**
```
Attributes:
  id:           String (indexed)
  user_id:      String
  date:         Date   (indexed)
  json:         String  // MeditationEntry 전체 JSON 직렬화
  is_synced:    Bool    // Firebase 동기화 완료 여부
  created_at:   Date
```

**StreakEntity** (싱글턴, 1개 레코드만 유지)
```
Attributes:
  current_streak:         Int32
  longest_streak:         Int32
  last_meditated_date:    Date
  total_meditation_days:  Int32
```

---

## 5. 스트릭 시스템

### 5-1. 스트릭 인정 기준
- 당일 기도/묵상 1개 이상 작성 = 1일 인정
- Stage 2 입력 포함 (동일 기준 충족)
- 날짜 기준: 자정(00:00) ~ 23:59 (로컬 기기 시각)

### 5-2. StreakManager.swift 책임

```swift
class StreakManager: ObservableObject {
    // 현재 스트릭
    @Published var currentStreak: Int
    // 역대 최장 스트릭
    @Published var longestStreak: Int
    // 총 묵상 일수
    @Published var totalMeditationDays: Int

    // 오늘 묵상 완료 여부
    func didMeditateToday() -> Bool
    // 묵상 저장 시 호출
    func recordMeditation(for date: Date)
    // 앱 시작 시 스트릭 체크 (끊겼는지 확인)
    func checkAndUpdateStreak()
    // 이번 달 묵상 날짜 배열 반환 (히트맵용)
    func meditatedDatesThisMonth() -> [Date]
}
```

### 5-3. 스트릭 엣지케이스

| 상황 | 처리 방식 |
|------|---------|
| 하루 건너뜀 | 스트릭 0으로 리셋, longestStreak는 유지 |
| 같은 날 여러 번 저장 | currentStreak 동일 유지 (중복 카운트 없음) |
| 오프라인 저장 | Core Data에 저장, is_synced = false. 온라인 복구 시 Firebase 동기화 |
| 비로그인 유저 | Core Data만. 로그인 시 자동 마이그레이션 후 Firebase 동기화 |
| 앱 재설치 (비로그인) | StreakEntity 초기화됨 (로컬 데이터 손실) |
| 앱 재설치 (로그인 유저) | Firebase에서 entries 복원 → 스트릭 재계산 |
| 시간대 변경 | 기기 로컬 시각 기준으로만 판단 |
| Stage 2와 직접 작성 같은 날 | MeditationEntry 2개 생성 허용 (날짜별 합산), 스트릭은 1일만 |

---

## 6. Gallery 핀 기능 이전 상세

### 6-1. SavedDetailView 변경
기존 SavedDetailView 하단에 섹션 추가:

```
─────────────────────────────
홈 배경 이미지로 설정

[🌅 아침]   설정 / 해제
[⚡ 낮]     설정 / 해제
[🌙 저녁]   설정 / 해제
```
- isHomeSafe == false인 이미지: "검토 중인 이미지라 설정 불가" 표시
- 현재 핀 상태는 DVUser.PinnedImages에서 읽어옴 (기존 로직 그대로)

### 6-2. SettingsView 새 섹션

```
홈 배경
  현재 설정된 배경: [이미지 섬네일] 아침 / [섬네일] 낮 / [섬네일] 저녁
  → 각 모드 탭 → "배경 해제" 옵션 (설정은 말씀들 탭에서)
```

---

## 7. 알림 전략

### 7-1. 저녁 묵상 리마인더
- 트리거: 오후 9:00, 당일 MeditationEntry 없는 경우
- 내용: `"📿 오늘 묵상을 아직 기록하지 않으셨어요"`
- 묵상 완료한 날은 전송하지 않음
- 알림 허용한 유저만 (PermissionManager.notificationStatus == .authorized)

### 7-2. 스트릭 위기 알림
- 트리거: 오후 8:00, currentStreak ≥ 3이고 당일 묵상 없는 경우
- 내용: `"🔥 {N}일 스트릭이 위기예요! 오늘 묵상을 기록해보세요"`
- 저녁 리마인더(9시)와 중복 방지: 스트릭 위기 알림 발송일에는 저녁 리마인더 생략

### 7-3. 알림 스케줄링 방식
- UNCalendarNotificationTrigger 사용
- 매일 갱신: 묵상 완료 시 해당 날의 리마인더 취소 (`UNUserNotificationCenter.current().removePendingNotificationRequests`)
- 최대 64개 제한 내에서 7일치 선 스케줄

---

## 8. Free vs Premium 상세

| 기능 | Free | Premium |
|------|:----:|:-------:|
| 오늘의 묵상 작성 | ✅ 무제한 | ✅ 무제한 |
| 기도 제목 추가 (일 최대 5개) | ✅ | ✅ |
| 감사 기록 작성 | ✅ | ✅ |
| 응답됨 체크 | ✅ | ✅ |
| 스트릭 표시 | ✅ | ✅ |
| Stage 2 빠른 입력 | ✅ | ✅ |
| 히스토리 열람 | 최근 7일 | 무제한 |
| 히스토리 "응답됨만 보기" 필터 | ❌ | ✅ |
| 역대 최장 스트릭 표시 | ❌ | ✅ |
| 월별 전체 달력 뷰 | 이번 달만 | 전체 기간 |
| 오프라인 동기화 (클라우드 백업) | ✅ (로그인 시) | ✅ |

---

## 9. 업셀 연동

### 9-1. 묵상 탭 업셀 트리거 (신규)

| 트리거 | 메시지 | 조건 |
|--------|--------|------|
| 8일+ 히스토리 카드 탭 (Free) | "지난 기도의 응답을 모두 돌아보고 싶으신가요?" | Free 유저 |
| "응답됨만 보기" 필터 탭 (Free) | "모든 응답된 기도를 한눈에 만나보세요" | Free 유저 |

### 9-2. 기존 업셀 제한 동일 적용
- 동일 트리거: 24시간 내 최대 1회
- 세션 내 총 2회 제한 (기존 5가지 + 신규 2가지 합산)
- UpsellManager에 신규 트리거 케이스 추가

---

## 10. 빈 상태 (Empty States)

| 상태 | 화면 | CTA |
|------|------|-----|
| 비로그인 + 기록 없음 | 🕊 아이콘 + "오늘 받은 말씀으로 첫 묵상을 시작해보세요" | [+ 오늘의 묵상 시작하기] |
| 로그인 + 기록 없음 | 동일 | 동일 |
| 로그인 + 기록 있음 + 오늘 미완료 | 스트릭 카드 + 오늘 묵상 미작성 카드 | [+ 오늘의 묵상 시작하기] |
| Free + 7일 이상 기록 잠금 | 흐림 처리 카드 + 잠금 메시지 | [Premium 시작하기] |

---

## 11. 애니메이션 스펙

| 전환 | 애니메이션 |
|------|----------|
| MeditationWriteSheet 등장 | Slide-up 0.3s (기존 바텀시트와 동일) |
| 저장 완료 | Heart pulse 0.4s (기존 Animation+DailyVerse 재사용) |
| 스트릭 숫자 증가 | CountUp 애니메이션 0.5s |
| 히트맵 dot 렌더링 | Fade-in 0.2s staggered (각 dot 5ms 간격) |
| 응답됨 체크 배지 | Scale + Fade-in 0.3s (green color) |
| 잠금 카드 blur | 즉시 표시 (애니메이션 없음) |

---

## 12. 구현 순서 (우선순위)

### Phase 1 — 핵심 기능 (반드시 함께 출시)
1. `MainTabView.swift` — GalleryView → MeditationView 탭 교체, 아이콘 변경
2. `Core/Models/MeditationEntry.swift` — 데이터 모델
3. `Core/Persistence/` — Core Data 엔티티 (MeditationEntity, StreakEntity)
4. `Core/Managers/StreakManager.swift`
5. `Core/Repositories/MeditationRepository.swift` — Core Data CRUD + Firebase CRUD
6. `Features/Meditation/MeditationViewModel.swift`
7. `Features/Meditation/MeditationView.swift` — 메인 화면 (스트릭 카드 + 오늘 섹션 + 히스토리)
8. `Features/Meditation/MeditationWriteSheet.swift` — 작성 모달
9. `Features/Alarm/AlarmStage2View.swift` — 선택 입력창 추가
10. Gallery 파일 제거 (GalleryView.swift, GalleryViewModel.swift)

### Phase 2 — 리텐션 완성
11. 히스토리 Free/Premium 게이팅 (7일 잠금)
12. 응답됨 체크 기능 (롱프레스 + 액션 시트)
13. Firebase 실시간 동기화 (오프라인 → 온라인 복구)
14. 비로그인 로컬 저장 → 로그인 시 마이그레이션

### Phase 3 — 알림 + 업셀
15. `NotificationManager.swift` — 저녁 리마인더 + 스트릭 위기 알림
16. `UpsellManager.swift` — 신규 트리거 2개 추가
17. `SavedDetailView.swift` + `SettingsView.swift` — Gallery 핀 기능 이전

---

## 13. 성공 기준 (KPI)

| 지표 | 목표값 | 측정 방법 |
|------|--------|---------|
| 묵상 탭 DAU / 전체 DAU | ≥ 40% | Firebase Analytics |
| 스트릭 7일 이상 유저 비율 | ≥ 20% | Firestore 집계 |
| Stage 2 입력 완료율 | ≥ 15% | source == "stage2" 비율 |
| 묵상 탭 → Premium 전환 기여율 | ≥ 20% | UpsellManager 트리거 분석 |
| 응답됨 체크 DAU | ≥ 10% | Firestore 집계 |

---

## 14. 제외 범위 (이번 버전에서 하지 않는 것)

| 기능 | 이유 |
|------|------|
| 커뮤니티 기도 (공개 기도 제목) | 개인정보 민감, 모더레이션 필요 → 추후 |
| 기도 시간 통계 (몇 분 기도했는지) | 측정 불가능 (텍스트 기반) → 추후 |
| 음성 기도 녹음 | 스토리지 비용 + 개인정보 → 추후 |
| AI 기도문 자동 생성 | 신학적 검토 필요 → 추후 |
| 기도 카테고리 태그 | 초기 과부하 → 추후 |
| 월별 달력 전체 뷰 | Phase 2에서 검토 |

---

*이 문서는 구현 시작 전 최종 확인을 받아야 합니다.*
*다음 단계: `/pdca design meditation-tab` 으로 설계 문서 작성*
