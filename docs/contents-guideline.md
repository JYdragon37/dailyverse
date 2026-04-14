# DailyVerse 콘텐츠 가이드라인

> **상태**: 확정 — v9.0
> 마지막 업데이트: 2026-04-14 (생성 파이프라인·Zone 컨텍스트·LLM 프롬프트 통합)

---

## 📌 데이터 소스 접근

| 항목 | 내용 |
|------|------|
| **Google Sheets** | [DailyVerse 콘텐츠 시트 열기](https://docs.google.com/spreadsheets/d/1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig/edit) |
| **편집 권한** | ✅ Claude Code가 `scripts/serviceAccountKey.json`으로 직접 편집 가능 |
| **Sheets → Firestore** | `node scripts/sync_sheets_to_firestore.js` |
| **수식 재적용** | `node scripts/apply_formula_fields.js` |

---

## 목차

**Part 1: 텍스트 콘텐츠 생성**

1. [콘텐츠 전체 구조](#1-콘텐츠-전체-구조)
2. [필드명 전체 매핑](#2-필드명-전체-매핑)
3. [수식 동기화 정책](#3-수식-동기화-정책)
4. [**콘텐츠 생성 파이프라인**](#4-콘텐츠-생성-파이프라인) ← **핵심 — 작성 전 필독**
5. [Verse 텍스트 필드 규격 + LLM 프롬프트](#5-verse--홈-말씀)
6. [Alarm Verse 필드 규격](#6-alarm-verse--알람-말씀)
7. [글자수 가이드라인](#7-글자수-가이드라인)
8. [UI 문구](#8-ui-문구)

**Part 2: 이미지 관리 (텍스트 생성과 독립)**

9. [VerseImage — 감성 배경 이미지](#9-verseimage--감성-배경-이미지)
10. [BackgroundImage — 존별 고정 배경](#10-backgroundimage--존별-고정-배경)

**Appendix**

- [컬럼명 변경 이력](#appendix-컬럼명-변경-이력)

---

# Part 1: 텍스트 콘텐츠 생성

---

## 1. 콘텐츠 전체 구조

```
Firestore
├── verses/            v_001 ~ v_101     홈화면 말씀 (101개, 전체 active)
├── alarm_verses/      av_001 ~ av_105   알람 말씀 (105개)
├── images/                              감성 배경 이미지 메타데이터 (49개 active)
└── background_images/                   Zone별 고정 배경 (8개)

Firebase Storage
├── images/            *.jpg, *.webp     감성 이미지 원본 (59개 업로드 완료)
└── background_images/                   Zone 배경 원본 (8개)
```

**콘텐츠 현황 요약 (2026-04-10 기준)**

| 컬렉션 | 총수 | active | 비고 |
|--------|------|--------|------|
| verses | 101 | 101 | question 필드 작성 예정 |
| alarm_verses | 105 | - | av_001~av_105 |
| images | 49 | 49 | Zone별 편차 큼 (§9-9 참고) |
| background_images | 12 | 8 신Zone + 4 구Zone | 구Zone은 코드 미참조 |

---

## 2. 필드명 전체 매핑 (v6.0 확정)

> 코드·스크립트·Firestore 문서 작성 시 아래 컬럼명을 기준으로 사용합니다.

| 번호 | 탭 | 섹션 | 타이틀(코드명) | UI 표시명 | Firestore 컬렉션 | 컬럼명 |
|------|-----|------|----------------|----------|----------------|--------|
| 1.1.1 | 홈 | 메인 카드 | main_title | 메인 글귀 | verses | verse_full_ko |
| 1.2.1 | 홈 | 팝업 | application | 오늘의 적용 | verses | application |
| 1.2.2 | 홈 | 팝업 | interpretation | 해석 | verses | interpretation |
| 2.1.1 | 알람 | 알람 목록 상단 | alarm_main | 오늘의 말씀 | verses | alarm_top_ko → 없으면 verse_short_ko |
| 2.2.1 | 알람 | Stage 1 전체화면 | alarm_stage1 | 알람 메인 글귀 | verses | verse_short_ko (Group B) |
| 2.3.1 | 알람 | Stage 2 웰컴 | alarm_stage2 | 알람 전문 글귀 | verses | verse_full_ko (Group A) |
| 2.3.2 | 알람 | Stage 2 한마디 | alarm_word | 오늘의 한마디 | verses | verse_short_ko (Group B) |
| 3.1.1 | 말씀들 | 썸네일 카드 | saved_title | 저장 메인 글귀 | saved_verses | verse_full_ko (저장 시 복사) |
| 3.2.1 | 말씀들 | 저장 상세화면 | saved_application | 저장된 적용 | verses (동적) | application |
| 3.2.2 | 말씀들 | 저장 상세화면 | saved_interpretation | 저장된 해석 | verses (동적) | interpretation |
| 4.1.1 | 묵상 | 오늘의 묵상 카드 | contemplation_main | 오늘의 묵상 | verses | verse_short_ko |
| 4.2.1 | 묵상 | 묵상 작성 시트 | contemplation_mission | 묵상 한 구절 | verses | contemplation_ko + contemplation_reference |
| 4.2.2 | 묵상 | 묵상 S2 해석 섹션 | contemplation_interpretation | 묵상 해석 | verses | contemplation_interpretation (Group P) |
| 4.2.3 | 묵상 | 묵상 S3 일상 적용 | contemplation_appliance | 묵상 일상 적용 | verses | contemplation_appliance (Group O) |
| 4.3.1 | 묵상 | 묵상 응답 화면 | devotion_question | 묵상 질문 | verses | question |

---

## 2-1. 데이터 라이프사이클 및 화면별 필드 매핑 가이드

### 갱신 정책 (Lifecycle)

#### 🔄 수시 변경 (Random Access)
| 항목 | 내용 |
|------|------|
| 대상 화면 | ⏰ 알람 탭 — 오늘의 말씀 카드 |
| 대상 필드 | `alarm_top_ko` (없으면 `verse_short_ko` 폴백) |
| 로직 | 페이지 진입/오픈 시마다 `alarm_top_ko` 필드가 있는 구절만 풀에서 무작위 호출 |
| 컬렉션 | `verses/` |

#### 📅 일일 고정 (Daily Sync)
| 항목 | 내용 |
|------|------|
| 기준 시간 | 매일 오전 06:00 KST |
| 로직 | 해당 시간에 그날의 '오늘의 말씀' 데이터셋 확정 → 5개 Sync Group으로 앱 전반 배포 |

---

### 동기화 그룹 (Sync Groups)

#### 🅰️ Group A — Full Verse (상세 구절)
| 연동 화면 | 주요 필드 |
|---------|---------|
| 🏠 홈 탭 메인 | `verse_full_ko`, `reference`, `theme[0]` |
| ⏰ 알람 Stage 2 (웰컴) | `verse_full_ko`, `reference`, `theme[0]` |
| 🔖 말씀들 그리드 카드 | `verse_full_ko` (SavedVerse 저장 시 스냅샷) |
| 🍃 묵상 S2 말씀 카드 | `verse_short_ko`, `reference` |

#### 🅱️ Group B — Short Verse (요약/가독성)
| 연동 화면 | 주요 필드 |
|---------|---------|
| ⏰ 알람 Stage 1 (전체화면) | `verse_short_ko` |
| ⏰ 알람 Stage 2 → 오늘의 한마디 | `verse_short_ko` |
| 🍃 묵상 탭 홈 (오늘의 말씀 카드) | `verse_short_ko`, `reference` |
| 🍃 묵상 S2 읽기 섹션 | `contemplation_ko` → (없으면) `verse_short_ko` |

#### 🅾️ Group O — Application (오늘의 적용)
| 연동 화면 | 주요 필드 |
|---------|---------|
| 🏠 홈 말씀 상세 바텀시트 | `application` |
| 🔖 말씀들 저장 상세 | `application` |
| 🍃 묵상 S3 일상 적용 | `contemplation_appliance` → (없으면) `application` |

#### 🅿️ Group P — Interpretation (해석)
| 연동 화면 | 주요 필드 |
|---------|---------|
| 🏠 홈 말씀 상세 바텀시트 | `interpretation` |
| 🔖 말씀들 저장 상세 | `interpretation` |
| 🍃 묵상 S2 해석 섹션 | `contemplation_interpretation` → (없으면) `interpretation` |

#### 🆀 Group Q — Unique (단독 항목)
| 연동 화면 | 주요 필드 |
|---------|---------|
| 🍃 묵상 S3 묵상 질문 | `question` (없으면 기본 문구 하드코딩) |
| 🍃 묵상 기록보기 | `contemplation_interpretation`, `application` |

---

## 3. 수식 동기화 정책

> 아래 컬럼들은 Google Sheets에서 수식으로 원본 컬럼을 자동 참조합니다.
> **원본만 관리하면 됩니다 — 별도 작성 불필요.**

| 시트 컬럼 (자동) | 참조 원본 | 이유 |
|----------------|---------|-----|
| `contemplation_interpretation` | `interpretation` | interpretation 내용이 더 좋음 |
| `contemplation_appliance` | `application` | application 내용이 더 좋음 |
| `contemplation_ko` | `verse_full_ko` | verse_full_ko 내용이 더 좋음 |
| `contemplation_reference` | `reference` | reference와 동일 출처 |

> 수식 재적용 필요 시: `node scripts/apply_formula_fields.js`
> Firestore 반영: `node scripts/sync_sheets_to_firestore.js`

---

## 3-1. 화면별 필드 사용 맵 (v9.0)

| 탭 | 화면 / 섹션 | 표시 필드 | 원본 | 비고 |
|----|------------|---------|------|------|
| **홈** | 메인 말씀 카드 | `verse_full_ko`, `reference`, `theme[0]` | `verses/` | 일일 갱신 (06:00) |
| **홈** | 말씀 상세 바텀시트 → 해석 | `interpretation` | `verses/` | |
| **홈** | 말씀 상세 바텀시트 → 적용 | `application` | `verses/` | |
| **알람** | 알람 탭 상단 카드 | `alarm_top_ko` → 없으면 `verse_short_ko` | `verses/` | 수시 랜덤 |
| **알람** | Stage 0 잠금화면 배너 | `verse_short_ko`, `reference` | `verses/` | |
| **알람** | Stage 1 전체화면 | `verse_short_ko`, `reference` | `verses/` | |
| **알람** | Stage 2 웰컴 — 말씀 | `verse_full_ko`, `reference` | `verses/` | |
| **알람** | Stage 2 오늘의 한마디 | `verse_short_ko` | `verses/` | |
| **말씀들** | 그리드 썸네일 카드 | `verse_full_ko` | `saved_verses/` | 저장 시 스냅샷 |
| **말씀들** | 저장 상세 → 해석 | `interpretation` | `verses/` | 동적 참조 |
| **말씀들** | 저장 상세 → 적용 | `application` | `verses/` | 동적 참조 |
| **묵상** | 홈 — 오늘의 말씀 카드 | `verse_short_ko`, `reference` | `verses/` | |
| **묵상** | S2 말씀 카드 | `verse_short_ko`, `reference` | `verses/` | |
| **묵상** | S2 읽기 섹션 — 구절 | `contemplation_ko` (=`verse_full_ko`) | `verses/` | 수식 자동 |
| **묵상** | S2 해석 섹션 | `contemplation_interpretation` (=`interpretation`) | `verses/` | 수식 자동 |
| **묵상** | S3 일상 적용 | `contemplation_appliance` (=`application`) | `verses/` | 수식 자동 |
| **묵상** | S3 묵상 질문 | `question` | `verses/` | 없으면 기본 문구 |
| **묵상** | 기록보기 | `contemplation_interpretation`, `application`, `question` | `verses/` | |

---

## 4. 콘텐츠 생성 파이프라인

> ⚠️ **작성 전 반드시 이 섹션을 먼저 읽으세요.**
> 모든 텍스트 콘텐츠는 `verse_full_ko`에서 시작하여 아래 흐름으로 생성됩니다.

---

### 4-1. 생성 흐름 (단방향)

```
[1단계] 성경 구절 선정 + Zone 지정
           ↓
[2단계] verse_full_ko 확정 ← 앵커. 반드시 가장 먼저.
           ↓
[3단계] verse_short_ko 추출 ← full에서 핵심 문장 선택 또는 그대로 사용
           ↓
    ┌──────┴──────┐
    ↓             ↓
[4단계]      [4단계]
interpretation  application
 (말씀 배경·     (Zone 맥락 반영
  의미·연결)      행동 가이드)
    └──────┬──────┘
           ↓
[5단계] alarm_top_ko (선택)
  verse_short_ko ≤ 35자이면 생략, 초과하면 더 압축

[독립]  question
  verse_full_ko / contemplation_ko와 맥락 연결만 확인하면 됨
  다른 필드 확정 후 별도 생성 가능
```

**역방향 작성 금지 원칙**
- `verse_short_ko`를 먼저 쓰고 `verse_full_ko`를 채우는 방식 금지
- `interpretation`이나 `application` 아이디어를 먼저 잡고 `verse_full_ko`를 역으로 선정하는 방식 금지
- `verse_full_ko`가 확정되지 않으면 나머지 필드 작성 시작 금지

---

### 4-2. Zone 기준표

> **8개 Zone** = DailyVerse가 하루를 나누는 단위. 각 Zone은 유저가 처한 상황과 감정이 다르므로,
> 같은 성경 구절이어도 Zone에 따라 `application` 톤과 `verse_short_ko` 선택이 달라져야 합니다.

| Zone | 시간대 | 유저 상황 | 감정 상태 | 말씀 역할 | theme 풀 | mood 풀 |
|------|--------|---------|---------|---------|---------|---------|
| 🌑 **deep_dark** | 00~03 | 잠이 안 와 뒤척이거나, 불안·걱정으로 혼자 깨어 있음. 야간 근무 중이기도 함. 세상이 고요하고 유독 혼자인 느낌 | 외로움 · 불안 · 조용한 갈망 | 조용한 동반자. "너 혼자가 아니야"라는 안심. 설교 아닌 나직한 위로 | stillness, surrender, grace, faith | serene, calm |
| 🌒 **first_light** | 03~06 | 이른 새벽 기도·묵상을 위해 일어남. 아직 가족도 깨지 않은 고요함 속. 하루가 시작되기 전 마지막 정적 | 고요한 기대 · 영적 준비 · 하루 전의 정적 | 하루를 시작하기 전 영적 호흡. 새 날에 대한 조용한 기대감 부여 | faith, renewal, stillness, hope | serene, calm |
| 🌅 **rise_ignite** | 06~09 | 알람이 울려 잠에서 깨는 순간. 이불 속에서 폰 확인 중. 오늘 해야 할 것들이 머릿속에 스침 | 나른함 50% + 부담 30% + 작은 설렘 20% | 가볍게 밀어주는 격려. 무겁지 않고, "오늘도 할 수 있어"라는 짧은 에너지 | hope, courage, strength, renewal | bright, dramatic |
| ⚡ **peak_mode** | 09~12 | 업무·공부에 집중하는 시간. 회의·과제·프로젝트 한창. 성과 압박이 있음 | 집중 · 스트레스 · 책임감 | 지혜와 용기. 지금 하는 일에 의미를 부여하고 흔들리지 않게 | wisdom, focus, courage, strength | bright, dramatic |
| ☀️ **recharge** | 12~15 | 점심 식사 후 잠깐 쉬는 시간. 스마트폰 보거나 짧은 산책 중. 오후가 두렵기도 함 | 나른함 · 작은 허탈감 · 재충전 필요 | 잠깐의 쉼에서 내면 충전. 서두르지 않아도 된다는 안도감 | rest, patience, gratitude, comfort | calm, warm |
| 🌤 **second_wind** | 15~18 | 오후 슬럼프. 하루 후반을 마무리해야 하는 타이밍. "조금만 더"가 필요한 순간 | 피로감 · 마무리 의지 · 희미한 집중 | 후반전을 뛸 힘 재점화. 포기하지 않고 마무리하게 | strength, focus, patience, wisdom | warm, calm |
| 🌇 **golden_hour** | 18~21 | 퇴근·귀가 중이거나 저녁을 마친 상태. 하루를 자연스럽게 돌아보는 시간 | 수고함 · 감사 · 때로는 아쉬움이나 허무 | 오늘 하루에 의미를 부여하는 감사. 수고했음을 인정해주는 따뜻함 | gratitude, reflection, comfort, peace | warm, serene |
| 🌙 **wind_down** | 21~24 | 씻고 잠자리에 들기 전. 마지막 폰 스크롤 또는 취침 알람 맞추는 시간 | 피로 · 평안 욕구 · 내일에 대한 은은한 기대 또는 불안 | 오늘의 짐을 내려놓게 하는 고요한 위로. 편히 쉬어도 된다는 허락 | peace, rest, comfort, stillness | cozy, calm |

---

### 4-3. Zone별 application 작성 원칙

`application`은 **Zone의 시간대 상황을 직접 반영**해야 합니다.
유저가 그 순간 실제로 무엇을 하고 있는지를 상상하고 거기서 출발하세요.

| Zone | 좋은 예 | 나쁜 예 (시간대 무시) |
|------|--------|-----------------|
| deep_dark | "지금 뒤척이고 있다면, 숨 한 번 천천히 내쉬어봐. 이 밤도 혼자가 아니야." | "오늘 하루 감사한 마음으로 시작해봐." |
| rise_ignite | "알람 끄고 30초만 눈 감아봐. 오늘도 혼자가 아님을 기억하며 시작해." | "말씀을 묵상하며 하나님께 기도해봐." |
| peak_mode | "막히는 일이 있다면 잠깐 멈춰봐. 지혜는 조급함이 아닌 고요함에서 나와." | "저녁에 오늘을 돌아보며 감사해봐." |
| recharge | "지금 이 쉬는 시간, 억지로 생산적이려 하지 않아도 돼. 그냥 쉬어." | "매일 아침 새로운 마음으로 일어나봐." |
| wind_down | "알람을 맞추며 기억해. 내일 무슨 일이 생겨도 그분 손 안에 있어. 이제 편히 자." | "하나님의 말씀으로 하루를 시작해봐." |

---

## 5. Verse — 홈 말씀

**Firestore 컬렉션**: `verses/`
**ID 형식**: `v_001`, `v_002` ...
**사용 위치**: 홈화면 카드, 알람 Stage 1/2, 묵상 탭, 저장 탭

---

### 5-1. 텍스트 필드 규격

#### `verse_full_ko` — 전체 구절 ← **앵커. 항상 가장 먼저 확정**

| 항목 | 기준 |
|------|------|
| 용도 | 홈 메인 글귀, 말씀 상세 바텀시트, 저장 썸네일, 알람 Stage 2 전문 글귀 |
| 분량 | **40~120자** |
| 형식 | 전체 구절 의역 — 끊기지 않게 자연스럽게 |
| 말투 | 성경 인용체 또는 현대어 의역 |
| **구두점** | **띄어쓰기, 줄바꿈(`\n`), 마침표(`.`), 쉼표(`,`)를 철저하게 지킨다. 두 문장 이상이면 쉼표 또는 줄바꿈으로 호흡을 구분한다** |
| 예시 ✅ | `"두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라, 나는 네 하나님이 됨이라.\n내가 너를 굳세게 하리라."` |
| 이전 이름 | ~~text_full_ko~~ (deprecated) |

---

#### `verse_short_ko` — 핵심 요약 구절

| 항목 | 기준 |
|------|------|
| 용도 | 알람 Stage 1 전체화면, 알람 목록 오늘의 말씀, 묵상 카드 메인, Stage 2 한마디 |
| 분량 | **20~60자** |
| 형식 | `verse_full_ko`에서 핵심 문장 추출 또는 그대로 사용. 새로 만들거나 축약·합성 금지 |
| 말투 | 친근체 (`~야`, `~이야`) 또는 성경 인용체 |
| **구두점** | **마침표(`.`), 쉼표(`,`)를 철저하게 지킨다** |
| 이전 이름 | ~~text_ko~~ (deprecated) |

**`verse_short_ko` 결정 규칙 (우선순위 순)**

1. `verse_full_ko`가 **60자 이하**이면 → `verse_short_ko = verse_full_ko`
2. `verse_full_ko`가 **단일 문장** (마침표 1개 이하)이면 → `verse_short_ko = verse_full_ko`
3. `verse_full_ko`가 **복수 문장이고 60자 초과**이면 → 핵심 문장 1개를 추출 (20~60자)
   - 추출 기준: 말씀의 핵심 메시지가 담긴 가장 임팩트 있는 한 문장
   - 원문에 있는 문장을 그대로 선택 (합성·재창작 금지)

---

#### `interpretation` — 해석

| 항목 | 기준 |
|------|------|
| 용도 | 홈 바텀시트 "해석" 섹션, 묵상 S2 해석, 말씀들 저장 상세 |
| 분량 | **102~154자** (기준 128자, ±20%) |
| 구조 | ① 성경 배경/맥락 1문장 → ② 구절의 의미 1~2문장 → ③ 오늘과의 연결 1문장 |
| 줄바꿈 | 2~3문장마다 `\n` 삽입 |
| **원어 금지** | **히브리어·헬라어 직접 표기 절대 금지** (한국어 풀이로 대체) |
| 말투 금지 | ~이다, ~합니다, ~입니다, 설교조 |
| 말투 허용 | ~야, ~이야, ~거야, ~있어, ~계셔 |

**좋은 예 vs 나쁜 예**:
```
❌ 나쁨: '히브리어 "두마야"는 잠잠히 고정한다는 뜻이야.'
         '헤세드의 흔적이 곳곳에 담겨 있어.'

✅ 좋음: '다윗이 수많은 적들에게 둘러싸인 상황에서 쓴 시야.\n
"잠잠히 바라라"는 소음 속에서도 하나님께만 시선을 고정하는 태도야.\n
상황이 아닌 임재가 나의 안전이 되는 거야.'
```

---

#### `application` — 일상 적용

| 항목 | 기준 |
|------|------|
| 용도 | 홈 바텀시트 "오늘의 적용" 섹션, 묵상 S3 적용, 말씀들 저장 상세 |
| 분량 | **49~73자** (기준 61자, ±20%) |
| 구조 | 오늘 바로 할 수 있는 구체적 행동 1가지 |
| **말투** | ~해봐, ~기억해, ~말해봐, ~생각해봐, ~내려놔 |
| **금지** | 반드시 ~해야, 꼭 ~하라, ~하십시오, ~해야 한다 |
| **Zone 반영** | **해당 Zone의 시간대 상황을 직접 반영 필수** (§4-3 참고) |

---

#### `alarm_top_ko` — 알람 목록 상단 전용 글귀 (선택)

| 항목 | 기준 |
|------|------|
| 용도 | 알람 탭 목록 상단 "오늘의 말씀" |
| 분량 | **15~35자** |
| 형식 | 짧고 강렬한 핵심 문장 |
| 말투 | 성경 인용체 또는 친근체 |
| 주의 | `verse_short_ko`가 35자 이하이면 생략 가능 → `verse_short_ko`로 대체 |
| 이전 이름 | ~~alarm_text_ko~~ (deprecated) |

---

#### `question` — 묵상 응답 질문

| 항목 | 기준 |
|------|------|
| 용도 | 묵상 응답 화면 "묵상 질문" 섹션 |
| 분량 | **40~80자** (1~2문장) |
| 형식 | 질문형 문장. 닉네임 없이 저장 (앱에서 `"{name}님, "` 앞붙임) |
| 톤 | 따뜻하고 개인적인 질문. 일상 언어 사용. 종교적 어조 최소화 |
| 대답 유형 | 선택형 / 회상형 / 상상형 중 하나 |
| **금지** | 닉네임 직접 포함, 설교조, "~해야 합니까?", 신앙 점검 형태 |
| **연결** | 동일 구절의 `verse_full_ko` 또는 `contemplation_ko`와 맥락 연결 필수 |

**좋은 예시**:
```
"요즘 당신을 가장 두렵게 만드는 것은 무엇인가요?"
"오늘 이 말씀이 가장 필요한 순간은 언제일까요?"
"지금 당신의 시선은 어디를 향해 있나요?"
"힘든 시간 속에서 당신을 위로해준 것이 있나요?"
```

**나쁜 예시**:
```
"오늘 하나님께 기도했나요?" (종교적 점검)
"말씀을 암송해봤나요?" (신앙 행위 점검)
"여러분은 어떻게 생각하십니까?" (경어체, 방송 어투)
```

---

#### `contemplation_ko` — 묵상 작성 시트용 구절

| 항목 | 기준 |
|------|------|
| 용도 | 묵상 탭 "묵상 한 구절" 영역 |
| 분량 | **50~200자** |
| 형식 | `verse_full_ko`와 동일하거나 묵상에 더 적합한 다른 구절 선정 가능 |
| 말투 | 성경 인용체 (의역 허용) |
| 톤 | 긴 묵상 시간에 천천히 읽을 수 있는 구절. `verse_short_ko`보다 깊이 있게 |
| **현재 상태** | **수식으로 `verse_full_ko` 자동 참조 — 별도 작성 불필요** |

---

#### `contemplation_reference` — 묵상 구절 출처

| 항목 | 기준 |
|------|------|
| 형식 | `"책이름 장:절"` (예: `"시편 62:5"`, `"이사야 40:31"`) |
| **현재 상태** | **수식으로 `reference` 자동 참조 — 별도 작성 불필요** |

---

### 5-2. 메타데이터 필드 규격

| 필드 | 타입 | 허용값 | 규칙 |
|------|------|--------|------|
| `mode` | String 배열 | Zone명 8가지 또는 `all` | 최소 1개, 다중 허용 |
| `theme` | String 배열 | 아래 테마 풀 참고 | Zone 테마와 일치해야 매칭됨 |
| `mood` | String 배열 | serene, calm, bright, dramatic, warm, cozy | Zone 무드와 일치해야 매칭됨 |
| `season` | String 배열 | spring, summer, autumn, winter, all | 복수 허용 |
| `weather` | String 배열 | sunny, cloudy, rainy, snowy, any | 복수 허용 |
| `status` | String | `active`, `draft`, `inactive` | 배포 전 반드시 `draft` |
| `curated` | Boolean | true / false | 신학 검수 완료 시 `true` |
| `cooldown_days` | Int | 7 (기본) | 동일 구절 재출현 방지 기간 (일) |
| `usage_count` | Int | 0~ | 자동 증가, 초기값 0 |

---

### 5-3. 목표 수량

| 기준 | 목표 |
|------|------|
| Zone당 최솟값 | 10개 active (cooldown 7일 기준 일주일 순환) |
| 전체 목표 | **80개+** |
| 현재 보유 | v_001~v_101 (101개) ✅ |

---

### 5-4. 신규 Verse 통합 생성 프롬프트

> `{}`로 표시된 부분만 채워서 Claude에 그대로 전달하세요.
> Zone별 유저 상황·application 컨텍스트는 **§4-2 Zone 기준표**에서 복사해 넣으세요.

---

#### 사용 순서
1. `{성경 구절 원문}`, `{참조}`, `{zone_id}` 채우기
2. §4-2에서 해당 Zone의 `유저 상황`과 `application 컨텍스트` 복사해 채우기
3. Claude에 전달 → JSON 출력 확인 → 자기검증 체크리스트 통과 확인

---

```
[역할]
너는 DailyVerse 앱의 말씀 콘텐츠 작가야.
DailyVerse는 크리스천을 위한 iOS 알람 앱으로, 하루 8개 시간대(Zone)마다
유저의 상황에 맞는 성경 말씀을 제공해.
글쓰기 스타일: 설교자가 아닌 유저의 신앙 친구. 교회 강단 언어 아님.
목표: 그 순간 유저에게 필요한 말씀을 가장 자연스럽고 따뜻하게 전달.

━━━━━━━━━━━━━━━━━━━━━━
[입력]
성경 구절 (원문 또는 참고 번역): {성경 구절 원문}
참조: {책이름 장:절}
Zone: {zone_id}
유저 상황: {§4-2 Zone 기준표 → "유저 상황" 항목 복사}
application 컨텍스트: {§4-2 Zone 기준표 → "application 예시" 항목의 상황 부분}
━━━━━━━━━━━━━━━━━━━━━━

[생성 순서 — 반드시 이 순서로. 앞 필드가 확정되어야 다음으로 넘어간다]

① verse_full_ko → ② verse_short_ko → ③ interpretation → ④ application → ⑤ alarm_top_ko → ⑥ question

━━━━━━━━━━━━━━━━━━━━━━

[① verse_full_ko | 40~120자 | 앵커]

규칙:
- 현대 한국어 자연스러운 의역 (고어체·직역 금지)
- 두 문장 이상이면 쉼표(,) 또는 \n으로 호흡 구분
- 마침표·쉼표·띄어쓰기 빠짐없이

✅ 좋은 예:
"두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라, 나는 네 하나님이 됨이라.\n내가 너를 굳세게 하리라."

❌ 나쁜 예:
"두려워하지 말지어다. 주께서 함께 계시니라." → 고어체
"하나님께서 두려워하지 말라고 말씀하셨습니다." → 설명체·경어

━━━━━━━━━━━━━━━━━━━━━━

[② verse_short_ko | 20~60자 | full에서 추출]

규칙:
- verse_full_ko에서 핵심 문장 1개를 그대로 선택 (합성·축약·재창작 금지)
- verse_full_ko가 60자 이하 → 그대로 사용
- 복수 문장이고 60자 초과 → 가장 임팩트 있는 1문장만 그대로

✅ 좋은 예 (위 full에서 추출):
"두려워하지 말라, 내가 너와 함께 함이라."

❌ 나쁜 예:
"두렵지 않아도 돼, 하나님이 함께야." → 재창작
"내가 너를 굳세게 하리라, 두려워 말라." → 문장 합성

━━━━━━━━━━━━━━━━━━━━━━

[③ interpretation | 102~154자]

구조 (반드시 이 순서):
① 저자·화자가 처한 구체적 상황 1문장
   → "~가 ~한 상황에서 쓴 말씀이야" 형태
   → 역사적·개인적 상황 (전쟁 중, 감옥에서, 포로 시절, 광야에서 등)
② 이 구절의 핵심 의미 1~2문장
   → 원어 단어 직접 표기 절대 금지 (뜻은 한국어로만 풀어서)
   → 신학 용어 없이 일상 언어로
③ 지금 유저에게 연결되는 말 1문장
   → "지금 네가...", "이 말씀은 오늘 너에게..." 형태

총 102~154자. 2~3문장마다 \n 삽입.
말투: ~야, ~이야, ~거야, ~있어, ~계셔
금지: ~이다, ~합니다, ~입니다, 설교조

✅ 좋은 예:
"이사야가 바벨론 포로로 끌려가 절망에 빠진 이스라엘 백성에게 전한 말씀이야.\n'두려워하지 말라'는 상황이 바뀌기 전에 먼저 임재를 선언하는 거야. 조건이 없어.\n지금 네 앞의 두려움보다 그분이 크다는 걸 기억해."

❌ 나쁜 예:
"히브리어 '야레'는 두려움을 뜻해..." → 원어 단어 직접 표기
"이 말씀은 우리에게 큰 위로를 줍니다." → 설교조·경어

━━━━━━━━━━━━━━━━━━━━━━

[④ application | 49~73자]

⚠️ 이 필드는 Zone 시간대와 유저 상황이 문장 안에 자연스럽게 녹아 있어야 해.
유저는 지금 "{application 컨텍스트}" 상황에 있어.

규칙:
- 오늘 바로 실천 가능한 구체적 행동 1가지
- 유저 상황·시간대·장소감이 문장 배경에 느껴져야 함
- 말투: ~해봐, ~기억해, ~말해봐, ~생각해봐, ~내려놔
- 금지: 반드시, 꼭, ~해야 한다, ~하십시오

✅ 좋은 예 (rise_ignite — 알람 끄고 이불 속):
"알람 끄고 30초만 눈 감아봐. 오늘도 혼자가 아님을 기억하며 시작해."

✅ 좋은 예 (wind_down — 취침 전 마지막 폰):
"알람을 맞추며 기억해. 내일 무슨 일이 생겨도 그분 손 안에 있어. 이제 편히 자."

❌ 나쁜 예:
"저녁에 오늘 하루를 돌아보며 감사해봐." → rise_ignite에 저녁 언급
"반드시 말씀으로 하루를 시작해야 해." → 강요

━━━━━━━━━━━━━━━━━━━━━━

[⑤ alarm_top_ko | 15~35자 | 선택]

- verse_short_ko가 35자 이하이면 → null
- 35자 초과이면 → verse_short_ko를 더 압축한 15~35자 핵심 한 문장

━━━━━━━━━━━━━━━━━━━━━━

[⑥ question | 40~80자]

입력: verse_full_ko + interpretation 핵심 메시지

규칙:
- 질문형 문장. 닉네임 없이 저장 (앱이 "{name}님, " 앞에 자동 합성)
- 형태: 선택형("A와 B 중") / 회상형("~했던 경험") / 상상형("~라면") 중 1가지
- 일상 언어, 종교 어조 최소화
- 신앙 유무와 무관하게 누구나 공감할 수 있어야 함

금지:
- "기도했나요?", "말씀을 읽었나요?" (신앙 행위 점검)
- "~해야 합니까?", "~하셨나요?" (경어체)
- 닉네임 직접 포함

✅ 좋은 예:
"요즘 가장 두렵게 느껴지는 것은 무엇인가요?" (회상형)
"지금 당신의 시선은 어디를 향해 있나요?" (성찰형)
"두려움보다 더 크다고 느껴지는 것이 있나요?" (선택형)

❌ 나쁜 예:
"오늘 하나님께 기도하셨나요?" → 신앙 행위 점검
"두려움이 찾아올 때 어떻게 해야 합니까?" → 경어·강요

━━━━━━━━━━━━━━━━━━━━━━

[자기검증 — 출력 전 반드시 확인. 통과 못 하면 수정 후 출력]

□ verse_full_ko에 고어체·직역·경어가 없는가?
□ verse_short_ko가 full에서 그대로 추출됐는가? (합성·재창작 아님)
□ interpretation에 히브리어·헬라어 단어가 없는가?
□ interpretation이 "①저자상황 → ②핵심의미 → ③오늘연결" 순서인가?
□ application에 해당 Zone 시간대 상황이 문장 안에 느껴지는가?
□ application에 "반드시", "꼭", "~해야" 표현이 없는가?
□ question에 닉네임이 없는가?
□ question이 신앙 행위 점검 형태가 아닌가?
□ 모든 필드의 글자수가 지정 범위 안에 있는가?

━━━━━━━━━━━━━━━━━━━━━━

[출력 형식 — JSON만 출력. 다른 텍스트 없이]
{
  "verse_full_ko": "...",
  "verse_short_ko": "...",
  "interpretation": "...",
  "application": "...",
  "alarm_top_ko": "..." 또는 null,
  "question": "..."
}
```

---

### 5-5. 콘텐츠 검수 체크리스트

신규 콘텐츠 생성 후 아래 항목을 순서대로 확인합니다.

**[필수 확인]**

| # | 항목 | 확인 기준 |
|---|------|---------|
| 1 | verse_full_ko 먼저 확정 여부 | short/interpretation/application이 full 확정 후 작성됐는지 |
| 2 | 원어 표기 없음 | 히브리어·헬라어 단어 없음 (예: 헤세드, 두마야, 케코스미카 등) |
| 3 | interpretation 말투 | ~이다/~합니다/~입니다/설교조 없음 |
| 4 | application Zone 반영 | 시간대 상황이 직접 반영됐는지 (새벽에 "아침을 시작해봐" 금지) |
| 5 | 글자수 범위 | 각 필드별 §7 글자수 가이드라인 내에 있는지 |
| 6 | 구두점 | 마침표·쉼표 누락 없는지 |
| 7 | application 강요 없음 | "반드시", "꼭", "~해야" 없음 |

**[원어 표기 감지 패턴]**
```
금지 예:
- "히브리어 '라아'는..."
- "헬라어 '케코스미카'는 완료형이야..."
- "헤세드는..."
- "아가페..."

허용 대체 표현:
- "히브리어 표현이지만 풀이로: '풍성하게 이끈다'는 뜻인데..."
- "'이미 완전히 이겼다'는 완료형 표현인데..."
- "변함없는 사랑이..."
- "조건 없는 사랑이..."
```

---

## 6. Alarm Verse — 알람 말씀

**Firestore 컬렉션**: `alarm_verses/`
**ID 형식**: `av_001`, `av_002` ...
**사용 위치**: 알람 탭 "오늘의 말씀" 카드 (Random Access)

---

### 6-1. Verse(verses/)와의 차이점

| 항목 | Verse (v_) | Alarm Verse (av_) |
|------|-----------|------------------|
| 컬렉션 | verses/ | alarm_verses/ |
| verse_short_ko | 선택 | **필수** |
| application 톤 | 일반 일상 | 알람 울림 순간 맥락 |
| mode | 모든 Zone 가능 | 주로 아침·저녁 Zone |
| 알람 탭 카드 사용 | ❌ | ✅ (`alarm_top_ko` 필드 보유 구절) |

---

### 6-2. 알람 울림 순간 유저 심리

> `alarm_verses`는 알람이 실제로 울리는 순간과 연결된 콘텐츠입니다.
> 이 순간 유저의 심리를 정확히 이해하고 거기서 출발하는 말씀이어야 합니다.

#### 아침 알람 (rise_ignite, first_light, peak_mode)

| 항목 | 내용 |
|------|------|
| 유저 상태 | 잠에서 막 깨어나는 순간. 이불 속, 아직 눈이 반쯤 감김 |
| 심리 | 나른함 + 일어나기 싫음 + 오늘 할 일에 대한 부담 |
| 원하는 것 | "일어나도 괜찮아", "오늘도 할 수 있어" — 무겁지 않은 첫 마디 |
| 말씀 역할 | **짧고 강한 격려.** 설교 아닌 친구가 옆에서 해주는 말 한 마디 |
| **금지** | 긴 설명, 무거운 신앙 고백 요구, "오늘 열심히 살아야 해" 식의 압박 |

```
✅ 좋은 예:
- "알람이 울리면 30초만 눈 감아봐. 오늘 하루도 하나님 손 안에 있어."
- "내일 이 알람이 울릴 때, '오늘은 하나님이 만드신 날이야'라고 한 번만 말해봐."

❌ 나쁜 예:
- "매일 아침 하나님께 감사해야 한다."
- "오늘도 경건한 마음으로 하루를 시작하십시오."
```

#### 취침 전 알람 (wind_down, golden_hour)

| 항목 | 내용 |
|------|------|
| 유저 상태 | 하루를 마무리하고 잠자리에 드는 순간. 취침 알람을 맞추고 폰을 내려놓으려는 시간 |
| 심리 | 피로함 + 오늘 하루에 대한 회한 또는 감사 + 내일에 대한 은은한 불안 |
| 원하는 것 | "오늘도 잘 했어", "내려놓고 쉬어도 돼" — 허락과 안심 |
| 말씀 역할 | **오늘의 짐을 내려놓게 하는 고요한 위로.** 평안히 자도 된다는 말 |
| **금지** | 내일을 위한 다짐 요구, 신앙 점검 형태, 에너지 넘치는 밝은 톤 |

```
✅ 좋은 예:
- "알람을 맞추며 기억해. 내일 무슨 일이 생기든 하나님 손 안에 있어. 이제 편히 자."
- "오늘의 무게를 내려놓고 쉬어. 그분이 돌보신다."

❌ 나쁜 예:
- "반드시 하나님께 기도하고 자야 한다."
- "내일을 위해 오늘 밤 말씀으로 준비하세요."
```

---

### 6-3. Alarm Verse 생성 프롬프트

> 알람 전용 콘텐츠. §5-4 통합 프롬프트보다 필드가 적고, 알람 순간 심리에 더 집중합니다.

```
[역할]
너는 DailyVerse 앱의 말씀 콘텐츠 작가야.
알람이 울리는 그 순간, 유저의 첫 번째 말씀 접점이 되는 콘텐츠를 써.
설교자가 아닌 친구처럼. 무겁지 않게. 그 순간에 딱 맞게.

━━━━━━━━━━━━━━━━━━━━━━
[입력]
성경 구절 (원문 또는 참고 번역): {성경 구절 원문}
참조: {책이름 장:절}
알람 타입: {아침 알람 / 취침 알람}
Zone: {rise_ignite / first_light / peak_mode / golden_hour / wind_down 중 선택}
━━━━━━━━━━━━━━━━━━━━━━

[알람 순간 유저 심리 — 이 심리에서 출발해]

아침 알람 (rise_ignite / first_light / peak_mode):
  → 잠에서 막 깨어나는 순간. 이불 속, 눈이 반쯤 감김
  → 나른함 + 일어나기 싫음 + 오늘 할 일에 대한 부담
  → 유저가 원하는 것: 무겁지 않은 첫 마디. "일어나도 괜찮아"
  → 말씀 역할: 짧고 강한 격려. 친구가 옆에서 해주는 말 한 마디

취침 알람 (wind_down / golden_hour):
  → 하루를 마무리하고 잠자리에 드는 순간
  → 피로함 + 오늘 하루에 대한 회한 또는 감사 + 내일에 대한 은은한 불안
  → 유저가 원하는 것: "오늘도 잘 했어", "내려놓고 쉬어도 돼"
  → 말씀 역할: 평안히 자도 된다는 조용한 허락

━━━━━━━━━━━━━━━━━━━━━━

[① verse_full_ko | 40~120자 | 앵커]

- 현대 한국어 자연스러운 의역 (고어체 금지)
- 쉼표(,) 또는 \n으로 호흡 구분
- 마침표·쉼표 빠짐없이

✅ 좋은 예: "두려워하지 말라, 내가 너와 함께 함이라.\n내가 너를 굳세게 하리라."
❌ 나쁜 예: "두려워하지 말지어다. 주께서 함께하시느니라." → 고어체

━━━━━━━━━━━━━━━━━━━━━━

[② verse_short_ko | 20~60자 | 필수]

- verse_full_ko에서 핵심 문장 1개 그대로 추출 (합성·재창작 금지)
- 알람 Stage 1 전체화면에 크게 표시됨 → 잠 깬 눈에 한눈에 들어와야 함

✅ 좋은 예: "두려워하지 말라, 내가 너와 함께 함이라."
❌ 나쁜 예: "내가 항상 너 곁에 있을 거야." → 재창작

━━━━━━━━━━━━━━━━━━━━━━

[③ application | 49~73자]

⚠️ 알람이 울리는 그 물리적 순간이 문장 안에 있어야 해.

아침 알람이면: 알람 끄는 행동, 이불 속, 눈 뜨는 순간을 배경으로
취침 알람이면: 알람 맞추는 행동, 폰 내려놓는 순간, 잠자리를 배경으로

말투: ~해봐, ~기억해, ~내려놔
금지: 반드시, 꼭, ~해야 한다, 내일 아침/저녁 언급 (타임존 혼선)

✅ 좋은 예 (아침):
"알람 끄고 30초만 눈 감아봐. 오늘도 혼자가 아님을 기억하며 시작해."

✅ 좋은 예 (취침):
"알람을 맞추며 기억해. 내일 무슨 일이 생겨도 그분 손 안에 있어. 이제 편히 자."

❌ 나쁜 예:
"반드시 하나님께 기도하고 자야 한다." → 강요
"오늘 저녁 말씀을 묵상하며 잠들어봐." → 맥락 혼선

━━━━━━━━━━━━━━━━━━━━━━

[④ alarm_top_ko | 15~35자]

알람 탭 상단 카드에 표시되는 초단문.
verse_short_ko를 한 번 더 압축해. 알람을 맞추는 순간 눈에 꽂히는 강도.

✅ 좋은 예: "두려워하지 말라, 내가 함께해."
❌ 나쁜 예: "하나님께서는 항상 우리와 함께하십니다." → 경어·길이 초과

━━━━━━━━━━━━━━━━━━━━━━

[자기검증 — 출력 전 반드시 확인]

□ verse_full_ko에 고어체가 없는가?
□ verse_short_ko가 full에서 그대로 추출됐는가?
□ application에 알람 울리는 그 물리적 순간이 배경으로 느껴지는가?
□ application에 강요 표현("반드시", "꼭", "~해야")이 없는가?
□ 모든 필드 글자수가 범위 안에 있는가?

━━━━━━━━━━━━━━━━━━━━━━

[출력 형식 — JSON만 출력]
{
  "verse_full_ko": "...",
  "verse_short_ko": "...",
  "application": "...",
  "alarm_top_ko": "..."
}
```

---

### 6-4. 목표 수량

| 분류 | 목표 | 현재 |
|------|------|------|
| 아침용 (rise_ignite + first_light + peak_mode) | 30개+ | ✅ |
| 저녁/취침용 (golden_hour + wind_down) | 30개+ | ✅ |
| 기타 Zone | 15개+ | ✅ |
| **전체** | **75개+** | **av_001~av_105 (105개)** |

---

## 7. 글자수 가이드라인

> 스크린샷 실측 기준. 신규 콘텐츠 작성 시 반드시 준수합니다.

| 컬럼명 | 기준 글자수 | 범위 | 비고 |
|--------|-----------|------|------|
| verse_full_ko | 40자 | 40~120자 | **앵커. 먼저 확정.** 구두점·줄바꿈 철저 |
| verse_short_ko | full에서 추출 | **20~60자** | full 확정 후 작성. 마침표·쉼표 철저 |
| alarm_top_ko | short 이하 | 15~35자 | short ≤ 35자이면 생략 가능 |
| interpretation | 128자 | 102~154자 | 80~120% |
| application | 61자 | 49~73자 | 80~120%. Zone 상황 반영 필수 |
| question | 60자 | 40~80자 | 질문형. 닉네임 없이 |
| contemplation_ko | — | 50~200자 | 수식 자동 (별도 작성 불필요) |
| contemplation_interpretation | — | 80~150자 | 수식 자동 |
| contemplation_appliance | — | 40~80자 | 수식 자동 |

---

## 8. UI 문구

### 8-1. Zone 인사말 (확정)

| Zone | 영문 | 한국어 |
|------|------|--------|
| deep_dark | Still up, Night Owl? | 아직 안 잤어요? |
| first_light | Rise before the world. | 세상보다 먼저 일어난 당신. |
| rise_ignite | Good Morning | 좋은 아침이에요, 오늘도 파이팅! |
| peak_mode | In the Zone | 지금 당신, 최고의 상태예요. |
| recharge | Breathe. Reset. | 잠깐 숨 고르고, 다시 달려요. |
| second_wind | Second Wind's here. | 두 번째 바람이 왔어요, 마무리해봐요. |
| golden_hour | Good Evening | 수고했어요, 오늘 하루도. |
| wind_down | Rest well. | 오늘도 잘 했어요, 푹 쉬어요. |

---

### 8-2. 날씨 권고 문구 (확정)

**UV Index (5단계)**

| 등급 | 범위 | 문구 |
|------|------|------|
| 낮음 | 0~2 | 외출 시 특별한 보호 불필요 |
| 보통 | 3~5 | 긴 소매나 모자 권장 |
| 높음 | 6~7 | 선크림 필수, 11-15시 자제 |
| 매우높음 | 8~10 | 11-15시 외출 최소화 |
| 위험 | 11+ | 외출을 피해주세요 |

**미세먼지 PM2.5 (4단계)**

| 등급 | 범위 | 문구 |
|------|------|------|
| 좋음 | 0~15㎍ | 외출하기 좋은 날이에요 |
| 보통 | 16~35㎍ | 민감한 분은 마스크 권장 |
| 나쁨 | 36~75㎍ | 마스크 착용, 외출 자제 |
| 매우나쁨 | 76㎍+ | 외출을 피해주세요 |

**강수 (3단계)**

| 확률 | 문구 |
|------|------|
| 20%+ | 가볍게 우산 챙겨요 |
| 40%+ | 우산 챙기는 게 좋아요 |
| 70%+ | 우산을 꼭 챙기세요 |

---

### 8-3. 온보딩 / 토스트 / EmptyState 문구

통일 기준 별도 정의 필요

---

---

# Part 2: 이미지 관리

> ⚠️ **이 파트는 이미지 에셋 관리입니다.**
> Part 1 텍스트 콘텐츠 생성과 **완전히 독립적**입니다.
> 이미지 관련 작업 시에만 참고하세요.

---

## 9. VerseImage — 감성 배경 이미지

**Firestore 컬렉션**: `images/`
**Firebase Storage**: `images/*.jpg`
**사용 위치**: 홈화면 배경 (말씀·날씨 알고리즘 매칭), 알람 Stage 1/2 배경, 저장 썸네일

---

### 9-1. 파일 규격

| 항목 | 기준 |
|------|------|
| 해상도 | 최소 **1080 × 1920px** (세로형 9:16) |
| 파일 형식 | JPEG (품질 85%+) 또는 WebP |
| 파일 크기 | 최대 **3MB** |
| 색공간 | sRGB |
| 방향 | 세로 (portrait) 전용 |

---

### 9-2. 소스 기준

| 소스 | 라이선스 | 사용 가능 여부 |
|------|---------|-------------|
| Genspark Pro | 상업적 사용 가능 | ✅ 현재 주력 소스 |
| Unsplash CC0 | 무료 상업 사용 | ✅ |
| 기타 유료 스톡 | 별도 확인 필요 | 확인 후 사용 |

---

### 9-3. 이미지 선정 기준

#### 허용하는 이미지
- 자연 풍경: 산, 바다, 하늘, 숲, 들판, 호수, 사막, 설경
- 감성적·경건한 분위기 — "하나님의 창조물"처럼 느껴지는 장면
- 추상적 빛, 구름, 물결, 안개
- 성지 지명 배경 (예루살렘, 페트라, 갈릴리) — 단, 관광사진 느낌 제외
- 실루엣 인물 (얼굴 비식별)

#### 금지하는 이미지
- 인물 얼굴 (정면 식별 가능한 얼굴)
- 십자가, 교회 건물, 종교 아이콘 등 특정 종교 상징
- 폭력적·선정적·공포스러운 이미지
- 특정 브랜드·로고·텍스트 노출
- 도시 야경, 인공 구조물 위주 이미지 (자연 없음)
- 너무 밝거나 채도가 높아 말씀 텍스트가 안 보이는 이미지

#### 톤(tone) 선정 기준
| tone | 설명 | 예시 피사체 |
|------|------|-----------|
| **bright** | 밝고 선명, 개방감 | 맑은 하늘, 일출 직후, 풍경 전경 |
| **mid** | 중간 밝기, 따뜻하거나 차분 | 골든아워, 안개 낀 숲, 흐린 날 |
| **dark** | 어둡고 깊이 있음, 고요함 | 별빛, 새벽 직전, 심야 설경, 어두운 숲 |

---

### 9-4. 메타데이터 필드 전체 규격

| 필드 | 필수 | 허용값 | 태깅 기준 |
|------|------|--------|---------|
| `filename` | ✅ | 파일명 | 중복 체크 키 — 스크립트 자동 설정 |
| `storage_url` | ✅ | Firebase Storage URL | 스크립트 자동 설정 |
| `tone` | ✅ | bright / mid / dark | **매칭 핵심** — Zone별 선호 톤 참고 |
| `is_sacred_safe` | ✅ | true / false | 홈/알람 배경 노출 여부 |
| `text_position` | ✅ | top / center / bottom | 이미지의 밝은 영역 반대에 말씀 표시 |
| `text_color` | ✅ | light / dark | 배경 어두우면 light, 밝으면 dark |
| `mode` | ✅ | zone명 또는 `all` | 어울리는 시간대 Zone (복수 허용) |
| `theme` | ✅ | 테마 풀 | 이미지가 떠올리게 하는 테마 (1~3개) |
| `mood` | ✅ | serene / calm / bright / dramatic / warm / cozy | 이미지의 감정적 분위기 |
| `season` | 선택 | spring / summer / autumn / winter / all | 계절감이 뚜렷하면 지정 |
| `weather` | 선택 | sunny / cloudy / rainy / snowy / any | 날씨가 명확하면 지정 |
| `avoid_themes` | 선택 | 테마명 배열 | 이 이미지와 부적합한 테마 |
| `source` | ✅ | Genspark Pro / Unsplash | 저작권 추적용 |
| `license` | ✅ | Commercial / CC0 | |
| `status` | ✅ | active / draft | 신규 업로드 시 `active` (스크립트 기본값) |

---

### 9-5. text_position · text_color 설정 방법

```
이미지를 보고 판단:

text_position:
  - 이미지 상단이 어둡고 하단이 밝음 → "top"    (말씀이 상단에 표시)
  - 이미지 전체가 균등함                → "center"
  - 이미지 상단이 밝고 하단이 어둠     → "bottom" (말씀이 하단에 표시)

text_color:
  - 말씀이 표시될 영역(text_position)이 어두움 → "light"  (흰 텍스트)
  - 말씀이 표시될 영역이 밝음               → "dark"   (어두운 텍스트)
```

**예시**:
- 야간 숲 이미지 → tone: dark, text_position: center, text_color: light
- 일출 하늘 이미지 (하단에 산 실루엣) → tone: bright, text_position: bottom, text_color: light
- 안개 낀 호수 (전체 밝음) → tone: mid, text_position: center, text_color: dark

---

### 9-6. 파일명 → 메타데이터 자동 추론 키워드

`upload_local_images.js` 스크립트가 파일명에서 키워드를 감지해 자동 태깅합니다.

**mode 키워드**

| 키워드 | 자동 매핑 Zone |
|--------|--------------|
| deep_dark, midnight, night, aurora, moonlit, milky_way | deep_dark |
| first_light, dawn, blue_hour, foggy, misty | first_light |
| rise_ignite, sunrise, morning, rainbow, lighthouse | rise_ignite |
| peak_mode, peak, noon | peak_mode |
| recharge, midday | recharge |
| second_wind, autumn_archway | second_wind |
| golden_hour, sunset, dusk, twilight, santorini | golden_hour |
| wind_down, evening, frozen, monastery | wind_down |

**theme 키워드**

| 키워드 | 자동 매핑 테마 |
|--------|--------------|
| hope, guidance, lighthouse, rainbow | hope, renewal |
| faith, church, monastery, cathedral | faith, stillness |
| stillness, desert, campfire, milky_way | stillness, surrender |
| wisdom, petra, ruins, ancient | wisdom, courage |
| peace, ocean, beach, lake, meadow | peace, comfort |
| grace, aurora, fog | grace, rest |

> 자동 추론이 부정확하면 업로드 후 Firestore에서 직접 수정

---

### 9-7. Zone별 tone 우선순위

| Zone | 시간대 | 선호 tone | 이유 |
|------|--------|---------|------|
| 🌑 deep_dark | 00~03 | **dark** | 깊은 밤 — 고요하고 어두운 분위기 |
| 🌒 first_light | 03~06 | **dark** | 여명 직전 — 어둠이 걷히는 느낌 |
| 🌅 rise_ignite | 06~09 | **bright** | 일출 — 에너지 넘치는 밝음 |
| ⚡ peak_mode | 09~12 | **bright** | 한낮 — 선명하고 활기찬 빛 |
| ☀️ recharge | 12~15 | **mid** | 정오 — 따뜻하지만 차분 |
| 🌤 second_wind | 15~18 | **mid** | 오후 — 따뜻한 자연광 |
| 🌇 golden_hour | 18~21 | **mid** | 노을 — 황금빛 중간 톤 |
| 🌙 wind_down | 21~24 | **dark** | 밤 마무리 — 깊고 고요한 어둠 |

---

### 9-8. 이미지 선택 알고리즘 (앱 내부 로직)

```
1단계: 필터
  - status == "active" AND is_sacred_safe != false

2단계: 핀 이미지 우선 (UserDefaults pinnedImage_{zone})
  - 유저가 직접 지정한 이미지 최우선 적용

3단계: Zone 모드 필터
  - mode.contains(currentZone) OR mode.contains("all")

4단계: 스코어링
  theme 일치 1개당  +3점 (all이면 +3)
  mood 일치 1개당   +2점 (all이면 +2)
  weather 일치      +2점 (any 포함)
  season 일치       +1점 (all 포함)
  tone 선호 일치    +2점
  tone이 mid        +1점 (부분 점수)

5단계: 최고점 이미지 중 랜덤 1개 선택
```

---

### 9-9. 현재 보유 현황 및 우선순위 (2026-04-10)

| Zone | 현재 | 목표 | 상태 |
|------|------|------|------|
| 🌑 deep_dark | 9개 | 10~15개 | ⚠️ 1개 부족 |
| 🌒 first_light | 11개 | 10~15개 | ✅ |
| 🌅 rise_ignite | 12개 | 10~15개 | ✅ |
| ⚡ peak_mode | 3개 | 10~15개 | 🚨 **7개 부족** |
| ☀️ recharge | 4개 | 10~15개 | 🚨 **6개 부족** |
| 🌤 second_wind | 4개 | 10~15개 | 🚨 **6개 부족** |
| 🌇 golden_hour | 8개 | 10~15개 | ⚠️ 2개 부족 |
| 🌙 wind_down | 7개 | 10~15개 | ⚠️ 3개 부족 |
| 🌐 all | 3개 | 5~10개 | ⚠️ |
| **합계** | **49개** | **80~120개** | **31~71개 추가 필요** |

**신규 이미지 제작 우선순위**: peak_mode > recharge > second_wind > golden_hour

---

### 9-10. 이미지 업로드 방법

**방법 1: GUI (권장)**
```
루트 폴더의 "🖼️ 이미지 업로드.command" 더블클릭
→ images_to_upload/ 폴더의 모든 이미지 자동 업로드
→ 이미 Firestore에 등록된 파일명은 자동 건너뜀
```

**방법 2: 터미널**
```bash
cd /Users/jeongyong/workspace/dailyverse/scripts
node upload_local_images.js
```

**업로드 플로우**:
```
images_to_upload/ 에 파일 추가
    ↓
파일명 키워드로 mode/theme/mood/tone 자동 추론
    ↓
Firebase Storage 업로드
    ↓
Firestore images/{image_id} 문서 생성
    ↓
Google Sheets IMAGES 탭에 행 추가
```

> 업로드 후 Firestore에서 메타데이터 정확성 확인 필수 (특히 is_sacred_safe, text_position)

---

## 10. BackgroundImage — 존별 고정 배경

**Firestore 컬렉션**: `background_images/`
**Firebase Storage**: `background_images/*.jpg`
**사용 위치**: 홈화면 메인 배경 (VerseImage보다 우선 적용)

---

### 10-1. 구조

- Zone당 **1장** 큐레이션 고정 → 총 **8장**
- VerseImage 알고리즘과 무관 — Zone에 1:1 고정
- 홈화면에서 **currentBackground**로 로드됨 (없으면 VerseImage 폴백)

---

### 10-2. Firestore ID 규칙

| bg_id | Zone | 시간대 |
|-------|------|--------|
| `bg_deep_dark` | 🌑 Deep Dark | 00~03시 |
| `bg_first_light` | 🌒 First Light | 03~06시 |
| `bg_rise_ignite` | 🌅 Rise & Ignite | 06~09시 |
| `bg_peak_mode` | ⚡ Peak Mode | 09~12시 |
| `bg_recharge` | ☀️ Recharge | 12~15시 |
| `bg_second_wind` | 🌤 Second Wind | 15~18시 |
| `bg_golden_hour` | 🌇 Golden Hour | 18~21시 |
| `bg_wind_down` | 🌙 Wind Down | 21~24시 |

> **deprecated** (코드 미참조, Firestore 정리 권장):
> `bg_morning`, `bg_afternoon`, `bg_evening`, `bg_dawn`

---

### 10-3. 이미지 선정 기준

- **파일 규격**: VerseImage와 동일 (1080×1920px, JPEG 85%+, 3MB 이하)
- **품질 기준**: VerseImage보다 더 엄선 — 홈화면에 장시간 노출됨
- **Zone 대표성**: 해당 Zone의 색감·분위기·시간대감이 명확해야 함
- **텍스트 가독성**: 말씀 텍스트 영역이 충분히 어두워야 함 (다크 오버레이 0.25~0.40 적용됨)
- **업로드 위치**: `scripts/background_images_to_upload/` 폴더

---

### 10-4. 현재 보유 현황 (2026-04-10)

| Zone | Firestore bg_id | Storage 파일 | 상태 |
|------|----------------|------------|------|
| 🌑 deep_dark | bg_deep_dark | bg_deep_dark.jpg | ✅ active |
| 🌒 first_light | bg_first_light | bg_first_light.jpg | ✅ active |
| 🌅 rise_ignite | bg_rise_ignite | bg_rise_ignite.jpg | ✅ active |
| ⚡ peak_mode | bg_peak_mode | bg_peak_mode.jpg | ✅ active |
| ☀️ recharge | bg_recharge | bg_recharge.jpg | ✅ active |
| 🌤 second_wind | bg_second_wind | bg_second_wind.jpg | ✅ active |
| 🌇 golden_hour | bg_golden_hour | bg_golden_hour.jpg | ✅ active |
| 🌙 wind_down | bg_wind_down | bg_wind_down.jpg | ✅ active |

---

## Appendix: 컬럼명 변경 이력

> v6.0 기준으로 아래 컬럼명이 변경되었습니다. deprecated 이름은 사용하지 않습니다.

| 기존 (deprecated) | 신규 | 적용 컬렉션 |
|------------------|------|-----------|
| text_ko | verse_short_ko | verses, alarm_verses |
| text_full_ko | verse_full_ko | verses, alarm_verses |
| alarm_text_ko | alarm_top_ko | verses |
| verse_text_short | verse_full_ko | saved_verses |
| devotion_question | question | verses |

---

> **섹션 번호 변경 이력 (v8.0 → v9.0)**
>
> | v8.0 | v9.0 | 내용 |
> |------|------|------|
> | §4 | §5 | Verse 필드 규격 |
> | §5 | §6 | Alarm Verse |
> | §6 | §9 | VerseImage (Part 2로 이동) |
> | §7 | §10 | BackgroundImage (Part 2로 이동) |
> | §8 | §7 | 글자수 가이드라인 |
> | §9 | §8 | UI 문구 |
> | (신규) | §4 | 콘텐츠 생성 파이프라인 |
