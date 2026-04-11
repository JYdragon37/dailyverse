# [Plan] devotion-tab

> Feature: 묵상 탭 4화면 가이드 플로우
> Created: 2026-04-10
> Status: Plan

---

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 현재 묵상 탭은 단일 페이지 빠른 입력 방식으로, 말씀을 깊이 묵상하는 구조적 경험이 없다. |
| **Solution** | 4화면 순차 가이드 플로우 (홈→말씀+해석→묵상응답→완료)로 매일 10분 경건 루틴을 구조화한다. |
| **Function UX Effect** | "오늘도 묵상 진행해볼까?" CTA → 말씀 읽기 → 질문 → 기도 → 완료 스트릭 강화. 완료 시 공유카드로 SNS 공유 유도. |
| **Core Value** | 기계적인 체크리스트가 아닌, 말씀과의 실제 만남을 설계한다. contemplation_ko(묵상 질문)가 핵심 차별점. |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| **WHY** | 기존 묵상탭이 단순 메모장 수준 → 구조화된 영적 루틴으로 진화 필요 |
| **WHO** | 매일 알람을 확인하는 크리스천 유저, 경건 생활을 습관화하고 싶지만 방법을 모르는 사람 |
| **RISK** | 너무 복잡하면 이탈률 ↑ (4화면이 부담될 수 있음) / Screen 3 기도 입력 빈 화면이 어색할 수 있음 |
| **SUCCESS** | Screen 1→3.5 완주율 ≥ 60% / 스트릭 3일 이상 유저 비율 ≥ 30% |
| **SCOPE** | MVP: 4화면 플로우 + 타이핑 읽기 + 공유카드. 제외: TTS, 녹음, Lottie |

---

## 1. 배경 및 목표

### 1.1 현재 상태 (AS-IS)
- `MeditationView`: 단일 스크롤 페이지 (TodayVerseCard + QuickMeditationCard + StreakSection + RecentHistory)
- 입력 구조: `prayerItems[]` (복수 기도제목) + `gratitudeNote?`
- 묵상의 흐름이 없음 — 그냥 텍스트 입력 후 저장

### 1.2 목표 상태 (TO-BE)
- 4화면 순차 NavigationStack push 플로우
- 매일 오늘의 말씀(verseFullKo + interpretation + contemplation_ko)을 중심으로 구조화
- 완료 시 스트릭 강화 + 공유카드 생성

### 1.3 핵심 원칙
- **깊이 우선**: 빠른 입력보다 말씀과의 진짜 만남
- **마찰 최소화**: 강제 입력 최소 (읽기 타이핑 OR 기도 1줄만 필수)
- **보상 설계**: 완료 화면 스트릭 카운트업으로 달성감 제공

---

## 2. 기능 요구사항

### 2.1 Screen 1 — 묵상 홈

| 요소 | 상세 |
|------|------|
| 시간대 인사말 | 05-11시: ☀️ / 12-17시: 🌤️ / 18-22시: 🌙 / 23-04시: 🌌 + {userName} |
| 말씀 카드 | 오늘의 verseShortKo + reference (fade-in 0.6s) |
| CTA 버튼 | "오늘도 묵상 진행해볼까?" → Screen 2 push |
| 스트릭 카운터 | 🔥 N일 연속 묵상 중! (카운트업 0.8s) |
| 캘린더 | 7열 그리드, 완료●/오늘○(테두리)/미완료○ |
| 오늘 묵상 완료 시 | CTA 버튼 → "오늘 묵상 완료 ✓" (비활성화) |

### 2.2 Screen 2 — 말씀 + 해석

| 요소 | 상세 |
|------|------|
| 네비게이션바 | ← 뒤로 / 오늘의 묵상 / 날짜 (M월 d일) |
| 말씀 카드 | verseFullKo, Serif 폰트 18pt, line-height 1.8 |
| 출처 | reference + 번역본(개역개정) |
| TTS 버튼 | 이번 MVP에서 제외 (버튼 없음) |
| 해석 섹션 | verse.interpretation (단락 분리, 15pt) |
| sticky CTA | "오늘의 묵상 완료하기 →" 하단 고정 |
| 투명도 로직 | CTA 진입 시 opacity 50% → 3초 후 100% |

### 2.3 Screen 3 — 묵상 응답

| 섹션 | 요소 | 상세 |
|------|------|------|
| 읽기 | 핵심 구절 | verse.contemplationKo (없으면 verseShortKo) |
| 읽기 | 입력 방식 | 타이핑 전용 TextField (읽으면서 따라 적기) |
| 읽기 | 완료 조건 | 텍스트 길이 > 0 → ✅ 읽기 완료! |
| 질문 | 묵상 질문 | verse.contemplationKo → 표시만 (입력 없음) |
| 기도 | 한 줄 기도 | TextField maxLength 50자, placeholder "주님, ..." |
| 기도 | 카운터 | 실시간 {count}/50자 |
| CTA | 활성 조건 | 읽기 완료 AND 기도 length > 0 |
| CTA | 비활성 시 | opacity 40%, 탭 시 미완료 섹션 스크롤 |

### 2.4 Screen 3.5 — 완료 화면

| 요소 | 상세 |
|------|------|
| 완료 메시지 | "오늘의 묵상을 마쳤어요" (20pt Bold, 중앙) |
| 스트릭 | 🔥 N일 연속 묵상! (Accent, 카운트업 0.8s spring) |
| 말씀 미니카드 | 오늘 핵심 구절 + reference (Serif, fade-in) |
| 완료 애니메이션 | ✨ SwiftUI scaleEffect + opacity (2s) |
| 공유 버튼 | "📤 카드로 공유하기" → 이미지 생성 + Share Sheet |
| 홈 버튼 | "🏠 홈으로 돌아가기" → Screen 1 pop to root |

### 2.5 공유카드 스펙

| 항목 | 값 |
|------|-----|
| 크기 | 1080 × 1920 px (9:16) |
| 배경 | 그라데이션 #1A1A2E → #2D2D44 |
| 요소 | 앱 로고(상단) + 말씀(중앙, Serif 28px) + reference + 기도(하단, Italic) + 워터마크 |
| 포맷 | PNG → iOS Share Sheet |
| 구현 | UIGraphicsImageRenderer + SwiftUI ImageRenderer |

---

## 3. 데이터 모델 변경

### 3.1 MeditationEntry 확장

```swift
// 신규 추가 필드
var prayer: String?       // 1줄 기도 (max 50자) — guided flow용
var readingText: String?  // 읽기 타이핑 텍스트 — guided flow용

// source 값 추가
// 기존: "manual" | "quick" | "read_only" | "stage2"
// 신규: "guided" (4화면 플로우 완료)
```

### 3.2 Firestore 필드 추가

```
meditation_entries/{user_id}/entries/{date_key}
  + prayer: String?
  + reading_text: String?
  (기존 prayer_items[], gratitude_note 유지)
```

---

## 4. 파일 구조

### 4.1 신규 생성 파일

```
DailyVerse/Features/Meditation/
  ├── DevotionHomeView.swift       # Screen 1 (MeditationView 대체)
  ├── DevotionVerseView.swift      # Screen 2
  ├── DevotionResponseView.swift   # Screen 3
  ├── DevotionCompleteView.swift   # Screen 3.5
  └── DevotionShareCard.swift      # 공유카드 렌더러
```

### 4.2 수정 파일

```
DailyVerse/Features/Meditation/
  ├── MeditationView.swift         # DevotionHomeView로 교체
  └── MeditationViewModel.swift    # saveGuided() 메서드 추가

DailyVerse/Core/Models/
  └── MeditationEntry.swift        # prayer, readingText 필드 추가
```

---

## 5. 화면 전환 스펙

| From → To | 방식 | 애니메이션 |
|-----------|------|-----------|
| Screen 1 → 2 | NavigationStack push | 우→좌 |
| Screen 2 → 3 | NavigationStack push | 우→좌 |
| Screen 3 → 3.5 | fullScreenCover | Cross-dissolve fade |
| Screen 3.5 → 1 | dismiss + pop to root | 좌→우 |
| Screen 2 → 1 | pop | 좌→우 |
| Screen 3 → 2 | pop | 좌→우 |

---

## 6. 컬러 & 디자인 토큰

와이어프레임 지정 컬러를 기존 DailyVerse 컬러 시스템에 매핑:

| 와이어프레임 | 값 | DailyVerse 매핑 |
|------------|-----|----------------|
| Background | #1A1A2E | `Color.dvBgDeep` |
| Primary text | #FFFFFF | `Color.white` |
| Secondary text | #A0A0B0 | `Color.white.opacity(0.55)` |
| Accent (Gold Brown) | #D4A574 | `Color.dvAccentGold` |
| Streak Active | #FF8C42 | 신규: `Color.dvStreakOrange` 또는 `.orange` |
| Card BG | dvBgSurface / dvBgElevated | 기존 유지 |
| Ivory | #F5E6CA | 신규: 공유카드 텍스트용만 |

---

## 7. 성공 기준 (Success Criteria)

| # | 기준 | 측정 방법 |
|---|------|----------|
| SC-1 | Screen 1→3.5 완주율 ≥ 60% | `source == "guided"` 저장 비율 |
| SC-2 | 기존 히스토리(MeditationEntry) 정상 표시 | 기존 prayerItems[] 렌더링 확인 |
| SC-3 | 공유카드 Share Sheet 정상 호출 | UIGraphicsImageRenderer 렌더링 성공 |
| SC-4 | 스트릭 카운터 정확도 | 날짜 경계 엣지케이스 테스트 |
| SC-5 | CTA 비활성 → 활성 조건 정확 작동 | 읽기+기도 조건 미충족 시 탭 차단 |

---

## 8. 리스크

| 리스크 | 대응 |
|--------|------|
| Screen 3.5에서 pop to root 시 Screen 1 캘린더 업데이트 누락 | onAppear에서 viewModel.load() 재호출 또는 StreakManager 옵저버 |
| 공유카드 ImageRenderer가 SwiftUI View를 비동기로 렌더링 → 빈 이미지 | `ImageRenderer.render(rasterizationScale:)` + MainActor 보장 |
| contemplation_ko가 nil인 말씀 (일부 미입력 가능성) | nil이면 verseShortKo로 폴백 |
| MeditationEntry prayer/readingText 필드: 기존 Firestore 문서 nil | Optional 처리로 backward-compatible |

---

## 9. 구현 순서 (스프린트 내)

| 순서 | 파일 | 예상 규모 |
|------|------|----------|
| 1 | MeditationEntry.swift — 필드 추가 | ~10줄 |
| 2 | DevotionHomeView.swift — Screen 1 | ~200줄 |
| 3 | DevotionVerseView.swift — Screen 2 | ~150줄 |
| 4 | DevotionResponseView.swift — Screen 3 | ~250줄 |
| 5 | DevotionCompleteView.swift — Screen 3.5 | ~180줄 |
| 6 | DevotionShareCard.swift — 공유카드 렌더러 | ~100줄 |
| 7 | MeditationViewModel.swift — saveGuided() 추가 | ~40줄 |
| 8 | MeditationView.swift — DevotionHomeView로 교체 | 기존 파일 대체 |

**총 예상**: ~930줄 신규, ~50줄 수정

---

## 10. 제외 항목 (v2.0 예정)

- 🔊 TTS 음성 듣기 (AVSpeechSynthesizer)
- 🎙️ 녹음 기능 (AVFoundation)
- 🎬 Lottie 애니메이션
- 캘린더 날짜 탭 → 과거 묵상 바텀시트
- 묵상 리마인더 알림 시간 커스터마이징
