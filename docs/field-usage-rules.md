# 화면별 필드 사용 규칙 (Field Usage Rules)

> **목적**: AI·개발자가 화면별로 어떤 필드를 표시하는지 즉시 확인하기 위한 단일 참조 문서
> **원칙**: 이 파일이 코드와 충돌 시 **코드가 정답** (이 문서를 코드에 맞게 수정)
> **최종 확인**: 2026-04-27 실제 코드 전수 검증 완료

---

## 말씀 필드 한눈에 보기

| 필드 | Swift 프로퍼티 | 길이 기준 | 용도 요약 |
|------|--------------|---------|---------|
| `verse_short_ko` | `verseShortKo` | **35자 이내** | 알람 목록 카드, 알람 Stage1, 알람 추가 미리보기 |
| `verse_full_ko` | `verseFullKo` | 최대 200자 | 홈 메인 카드, 알람 Stage2, 저장 상세, 바텀시트 |
| `alarm_top_ko` | `alarmTopKo` | 35자 이내 (선택) | 알람 목록 전용, 없으면 `verseShortKo` 폴백 |
| `interpretation` | `interpretation` | 80~150자 | 바텀시트 해석 섹션 |
| `application` | `application` | 40~80자 | 바텀시트 / 저장 상세 적용 섹션 |
| `question` | `question` | 20~80자 | 묵상 탭 응답 질문 |

---

## 화면별 표시 필드 (코드 검증 완료)

### 🏠 홈 탭

| 위치 | 표시 필드 | 코드 위치 |
|------|---------|---------|
| **메인 말씀 카드 (본문)** | `verseFullKo` ✅ | HomeView.swift:230 |
| 성경 참조 | `reference` | HomeView.swift:240 |
| 바텀시트 해석 | `interpretation` | VerseDetailBottomSheet.swift:38 |
| 바텀시트 적용 | `application` | VerseDetailBottomSheet.swift:53 |

> ⚠️ **content-schema.md 라인 28 오류**: `verse_short_ko`로 잘못 기재됨 → 실제는 `verseFullKo`

---

### ⏰ 알람 탭

| 위치 | 표시 필드 | 코드 위치 |
|------|---------|---------|
| **알람 목록 상단 말씀 카드** | `alarmTopKo` → 없으면 `verseShortKo` 폴백 | AlarmListView.swift:190 |
| **알람 추가/수정 미리보기** | `verseShortKo` | AlarmAddEditView.swift:78 |

---

### ⏰ 알람 울림

| 화면 | 표시 필드 | 코드 위치 |
|------|---------|---------|
| **Stage 1 (전체화면)** | `verseShortKo` | AlarmStage1View.swift:109 |
| **Stage 2 (웰컴 스크린)** | `verseFullKo` | AlarmStage2View.swift:243 |

---

### ♥ 저장 탭

| 위치 | 표시 필드 | 코드 위치 |
|------|---------|---------|
| **저장 상세 화면 (본문)** | `verseFullKo` | SavedDetailView.swift:24-26 |
| 성경 참조 | `reference` | SavedDetailView.swift:68 |
| 일상 적용 | `application` | SavedDetailView.swift:185 |

---

## 이미지 필드 규칙

| 화면 | 이미지 소스 | 비고 |
|------|-----------|------|
| 홈 배경 (Zone) | `background_images/` 컬렉션 | Zone 기준 랜덤, 날씨별 분기 |
| 알람 Stage1/2 배경 | `images/` 컬렉션 (감성 이미지) | 스코어링 알고리즘 |
| 저장 썸네일/상세 | `images/` 컬렉션 | 저장 시점 imageUrl 스냅샷 |

---

## 자주 헷갈리는 규칙 요약

```
홈 메인 카드  → verseFullKo   (긴 원문 전체 표시)
알람 Stage1  → verseShortKo  (35자 이내, 잠금화면 임팩트용)
알람 Stage2  → verseFullKo   (웰컴 스크린, 충분한 여백)
알람 목록    → alarmTopKo → (없으면) verseShortKo
바텀시트 본문 → verseFullKo   (원문 전체)
```

---

## 연관 문서

| 문서 | 역할 |
|------|------|
| `docs/content-schema.md` | 필드 스키마 전체 정의, Sheets-Firestore 매핑 |
| `docs/contents-guideline.md` | 콘텐츠 생성 규칙, 글자수 기준, LLM 프롬프트 |
| `CLAUDE.md` | 앱 전체 스펙 (Single Source of Truth) |

---

> 이 문서는 코드 변경 시 동기화 필요. AI가 화면별 필드를 물을 때 이 문서를 우선 참조.
