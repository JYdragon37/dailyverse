# Plan: contents-guideline-update

> **Feature**: 콘텐츠 가이드라인 writing guide 업데이트
> **작성일**: 2026-04-14
> **상태**: Plan 확정

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | contents-guideline-update |
| 작성일 | 2026-04-14 |
| 대상 파일 | `docs/contents-guideline.md` (v8.0 → v9.0), `docs/agents-guide.md` (Category G 참조 링크 정리) |

### Value Delivered (4 perspectives)

| 관점 | 내용 |
|------|------|
| Problem | `verse_full_ko`가 앵커라는 생성 흐름이 없고, Zone 컨텍스트가 테마/무드 목록에 머물러 있으며, LLM 프롬프트가 agents-guide에 분산되어 있어 콘텐츠 생성 시 일관성이 떨어짐 |
| Solution | 생성 흐름 명시 + Zone별 유저 상황 기술 + 프롬프트를 guideline에 통합하는 v9.0 업데이트 |
| Function / UX Effect | 콘텐츠 작성자(Claude 포함)가 guideline 한 문서만 보고 전체 생성 파이프라인을 이해하고 즉시 실행할 수 있음 |
| Core Value | 말씀·Zone·유저 상황이 유기적으로 연결된 고품질 콘텐츠 생성 → 앱 감성 경험의 일관성 확보 |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| WHY | 콘텐츠 생성 시 Zone 맥락 누락 + LLM 프롬프트 분산으로 품질이 들쑥날쑥해지는 문제 해결 |
| WHO | 콘텐츠 작성 주체: Claude Code (자동), 콘텐츠 작가 (사람) |
| RISK | 기존 v8.0 필드 스펙/정책(수식 참조, deprecated 이름 등)을 훼손하면 스크립트 오동작 가능 |
| SUCCESS | 가이드 한 문서만으로 verse_full_ko → 전체 필드 생성이 가능한 상태 |
| SCOPE | `docs/contents-guideline.md` 전면 개편. 앱 코드·Firebase 스키마·스크립트 변경 없음 |

---

## 1. 현황 분석 (AS-IS)

### 1-1. 구조적 문제

| 문제 | 영향 |
|------|------|
| 생성 흐름 미정의 | `verse_full_ko` 먼저 작성 → 나머지 파생 규칙이 명확하지 않아 필드별로 따로 작성하게 됨 |
| Zone 컨텍스트 부재 | Zone 기준표(#10)가 테마·무드 목록만 있고, 유저가 그 시간대에 어떤 상태인지 기술 없음 → Zone에 맞는 톤 생성 불가 |
| LLM 프롬프트 분산 | 실제 프롬프트는 agents-guide.md Category G에만 있음 → 두 문서를 번갈아 봐야 함 |
| 섹션 6·7 독립성 불명확 | 이미지 관리(섹션 6·7)가 텍스트 콘텐츠 생성과 혼재 → "콘텐츠 생성 가이드"와 "이미지 관리 가이드"가 섞임 |
| 알람 맥락 단편적 | 알람 울림 순간(잠에서 깨는 순간 / 취침 직전)의 사용자 심리·상태 반영이 5-2절에만 짧게 언급됨 |

### 1-2. TO-BE 구조

```
contents-guideline.md v9.0

Part 1. 콘텐츠 생성 (텍스트)
  §0. 데이터 소스 접근
  §1. 콘텐츠 전체 구조
  §2. 필드 매핑 (현행 유지)
  §3. 수식 동기화 정책 (현행 유지)
  [NEW] §4. 콘텐츠 생성 파이프라인
    4-1. 생성 흐름 (verse_full_ko → 전체)
    4-2. Zone 기준표 (유저 상황 + 감정 + 톤 가이드 포함)
    4-3. Zone별 작성 예시
  §5. Verse 필드 규격 (현행 §4 → §5로 이동, 프롬프트 통합)
  §6. Alarm Verse 필드 규격 (현행 §5 → §6으로 이동)
  §7. 글자수 가이드라인
  §8. UI 문구

Part 2. 이미지 관리 (독립 섹션)
  §9. VerseImage (현행 §6)
  §10. BackgroundImage (현행 §7)
```

---

## 2. 요구사항

### 2-1. 기능 요구사항

#### FR-01: 콘텐츠 생성 파이프라인 명시 (신규)
- `verse_full_ko`를 앵커로, 나머지 모든 텍스트 필드가 파생·확장되는 단방향 흐름을 시각적으로 표현
- 생성 순서: `verse_full_ko` → `verse_short_ko` → `interpretation` + `application` → `alarm_top_ko` (선택) → `question` (독립)
- "역방향 작성 금지" 원칙 명시 (short 먼저 쓰고 full 채우는 방식 금지)

#### FR-02: Zone 기준표 확장 (업데이트)
현재 Zone 기준표에 아래 4개 항목 추가:
- **유저 상황**: 그 시간대에 유저가 실제로 무엇을 하고 있는지 (예: 알람 끄고 누워 있는 상태, 점심 먹고 잠깐 쉬는 상태)
- **감정 상태**: 유저가 그 순간 느끼는 지배적 감정
- **말씀 톤 가이드**: 이 Zone에서 말씀이 어떤 역할을 해야 하는지 (위로 / 동기부여 / 성찰 등)
- **application 시간대 반영 예시**: Zone별 application 작성 예시 1개

#### FR-03: LLM 프롬프트 통합 (신규)
agents-guide.md Category G의 프롬프트를 contents-guideline에 흡수:
- `verse-writer` 프롬프트 → §5 Verse 필드 규격 내 "생성 프롬프트" 항목으로
- `tone-reviewer` 기준표 → §5 내 톤 기준표로
- `scripture-checker` 패턴 → §5 내 금지 패턴으로
- `devotion-question-writer` 프롬프트 → §5 `question` 필드 내로
- 통합 후 agents-guide.md Category G는 "→ 상세 규칙: docs/contents-guideline.md §5" 참조 링크만 유지

#### FR-04: 섹션 6·7 독립 선언 (구조 변경)
- 문서 상단에 "Part 1: 텍스트 콘텐츠 / Part 2: 이미지 관리" 구분선 추가
- 섹션 9(VerseImage), 10(BackgroundImage) 앞에 "이 섹션은 이미지 에셋 관리이며 텍스트 콘텐츠 생성과 독립적입니다" 명시

#### FR-05: 알람 맥락 강화 (업데이트)
- §6 Alarm Verse에 "알람 울림 순간 유저 심리" 항목 추가
- 아침 알람 / 취침 알람 각각의 심리 상태 + 말씀이 해야 할 역할 기술
- Zone별 알람 tone 예시 확장

### 2-2. 비기능 요구사항

| 항목 | 기준 |
|------|------|
| 하위 호환 | v8.0의 모든 필드명·수식 정책·deprecated 이름 기록 유지 |
| 코드 영향 없음 | 앱 코드·스크립트·Firebase 스키마 변경 없음 |
| 단일 진실 원본 | 모든 콘텐츠 생성 규칙은 이 파일 하나에서 참조 가능해야 함 |

---

## 3. 상세 설계: 신규 추가 섹션

### 3-1. 콘텐츠 생성 파이프라인 (FR-01)

```
[성경 구절 선정]
       ↓
[verse_full_ko] ← 앵커. 40~120자. 먼저 확정 필수.
       ↓
[verse_short_ko] ← full에서 핵심 문장 추출 (20~60자)
   ↙           ↘
[interpretation]  [application]
  (102~154자)       (49~73자)
  말씀 배경·의미    Zone 맥락 반영 행동 가이드
       ↓
[alarm_top_ko] ← 선택. verse_short_ko ≤ 35자이면 생략

[question] ← 독립 생성. 묵상 맥락 연결만 있으면 됨
```

**역방향 작성 금지 원칙:**
- verse_short_ko를 먼저 쓰고 verse_full_ko를 채우는 방식 금지
- interpretation이나 application에 없는 내용을 verse_full_ko에서 역추론하는 방식 금지

### 3-2. Zone 기준표 확장 (FR-02)

8개 Zone 각각에 추가될 항목:

```
| Zone | 시간대 | 유저 상황 | 감정 상태 | 말씀 역할 | theme 풀 | mood 풀 | application 예시 |
```

예시 (rise_ignite):
- **유저 상황**: 알람 끄고 일어나야 하는 순간, 아직 이불 속, 오늘 일정이 머릿속에 스쳐지남
- **감정 상태**: 설렘 20% + 나른함 50% + 부담 30%
- **말씀 역할**: 오늘 하루 시작할 힘을 주는 짧은 격려. 무겁지 않게, 가볍게 밀어주기
- **application 예시**: "알람 끄고 30초만 눈 감아봐. 오늘도 혼자가 아님을 기억하며 시작해."

### 3-3. 통합 생성 프롬프트 구조 (FR-03)

각 필드 규격 내에 아래 서브섹션 추가:

```markdown
#### [필드명] 생성 프롬프트
···
아래 구절의 [필드명]를 작성해줘.

verse_full_ko: {확정된 전체 구절}
reference: {참조}
zone: {대상 zone}
유저 상황: {해당 zone의 유저 상황}

[작성 규칙]
- ...
```

---

## 4. 작업 범위

### 변경 파일

| 파일 | 변경 유형 | 내용 |
|------|---------|------|
| `docs/contents-guideline.md` | 전면 개편 (v8.0 → v9.0) | 구조 재편 + 신규 섹션 추가 |
| `docs/agents-guide.md` | Category G 경량화 | 프롬프트 본문 제거 → 참조 링크로 대체 |

### 변경 없는 파일
- 앱 소스 코드 전체
- Firebase 스키마
- Node.js 스크립트
- Google Sheets 구조

---

## 5. 위험 요소

| 위험 | 대응 |
|------|------|
| 기존 §4 번호 체계 변경 → 다른 문서에서 참조 충돌 | 구 번호 → 신 번호 매핑 테이블을 문서 하단에 명시 |
| 프롬프트 통합 시 agents-guide와 내용 불일치 | 통합 완료 후 agents-guide 즉시 경량화 (동시 작업) |
| Zone 상황 기술이 주관적 → 실제 사용에 맞지 않을 수 있음 | 기존 알람 UX 설계(CLAUDE.md §7)와 정합성 확인 |

---

## 6. 성공 기준

- [ ] `verse_full_ko` → 전체 필드 생성 흐름이 다이어그램으로 명시됨
- [ ] 8개 Zone 각각에 유저 상황·감정·말씀 역할이 기술됨
- [ ] LLM 프롬프트가 각 필드 규격 항목 내에 포함됨
- [ ] 섹션 6·7이 "Part 2: 이미지 관리"로 명확히 분리됨
- [ ] 알람 울림 순간 심리·말씀 역할이 §6에 기술됨
- [ ] agents-guide.md Category G가 참조 링크만 남음
- [ ] v8.0 하위 호환 유지 (필드명·수식 정책 변경 없음)
