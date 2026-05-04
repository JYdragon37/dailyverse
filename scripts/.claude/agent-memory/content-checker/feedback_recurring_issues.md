---
name: 반복 오류 패턴
description: 신규 구절 배치 추가 시 자주 발생하는 오류 유형과 자동 탐지 방법
type: feedback
---

신규 구절 배치(v_220~v_299 + v_320~v_419 + v_503~v_552 검수 기준) 추가 시 반복적으로 발생하는 오류 패턴.

## 1. "기억해." 마침표 단독 패턴 — 가장 빈번한 위반

application과 interpretation 모두에서 발생. 탐지 패턴: `/기억해\./`

- application: v_283, v_285, v_290, v_291, v_293, v_294, v_298 (7건)
- interpretation: v_221, v_228, v_233, v_234, v_237, v_284 (6건)

**Why:** content-rules.json에 `"기억해\\."` 가 forbidden_tone_patterns 첫 항목. "기억해봐."는 OK, "기억해." 단독은 위반.
**How to apply:** 새 배치 검수 시 가장 먼저 `/기억해\./` 패턴 grep 수행.

## 2. verse_short_ko 50자 초과

v_296(54자), v_298(51자), v_299(58자) — 성경 원문을 그대로 넣어 초과하는 경우.
content-rules.json 기준 max 50자.

**How to apply:** `verse_short_ko.length > 50` 조건으로 자동 탐지.

## 3. interpretation 4단계 구조 — ①배경 누락이 가장 흔함

점수 2점 이하 구절: v_226, v_230, v_280, v_284, v_249, v_255, v_257 (10건/79개)
- ①배경 누락이 가장 흔한 패턴: 저자/상황 언급 없이 바로 해석으로 진입
- ④Zone 연결 누락: peak_mode 구절에서 "오전" 시간대 언급 없는 경우

## 4. 번역 오류 — 개역개정 표현 혼용

개역한글을 사용해야 하는데 개역개정 표현이 섞이는 경우:
- "평안을" (개역개정) → "평강을" (개역한글): 요한복음 14:27
- "그를 믿는 자마다 멸망하지 않고" → "저를 믿는 자마다 멸망치 않고": 요한3:16
- "온 마음으로" → "전심으로": 예레미야 29:13
- "평안한 집" → "화평한 집": 이사야 32:18
- "천사가" (개역개정) → "여호와의 사자가" (개역한글): 열왕기상 19:7 (v_408)
- "많으신 긍휼대로" (개역개정) → "풍성하신 긍휼을 따라" (개역한글): 베드로전서 1:3 (v_409)
- "명예를" → "크신 이름을": 사무엘상 12:22 (v_405)

**How to apply:** 신규 배치에 요한복음/예레미야/이사야/열왕기상/베드로전서 구절 있으면 개역한글 원문과 반드시 대조.

## 5. verse_short_ko 개념 요약형 문장 사용 — v_320~v_419에서 대량 발생

verse_short_ko가 개역한글 원문을 그대로 발췌하지 않고, 개념을 새로 요약한 문장으로 작성된 경우:
- "오늘도 주와 함께 일어나 힘차게 달려가자" (시편 5:3) — 원문에 없는 표현
- "주님의 이름으로 나아가니 이길 수 있어" (시편 20:7) — 원문에 없는 표현

v_320~v_419 중 28건이 이 패턴. 이 배치는 verse_short_ko를 응원 문구처럼 새로 작성했음.
탐지 방법: verse_short_ko 앞 8자가 verse_full_ko에 없으면 개념 요약형으로 판단.

**Why:** verse_short_ko는 개역한글 원문의 핵심 발췌여야 함. 새로 작성한 문장은 저작권·신학 정확성 모두 문제.
**How to apply:** 신규 배치 검수 시 verse_short_ko ↔ verse_full_ko 포함 관계 자동 체크 필수.

## 6. Haiku 배치 특유 패턴 — v_503~v_552 (2026-04-28 검수)

Haiku 모델로 생성된 배치에서 Sonnet 배치와 다른 특이 패턴:

**긍정적 차이:**
- verse_short_ko 길이 초과 0건 (Sonnet v_320~v_419: 3건)
- verse_short_ko 개념 요약형 0건 (Sonnet v_320~v_419: 28건) — 이번 배치는 원문 발췌 잘 유지
- 번영신학 0건
- interpretation/application 글자수 모두 범위 내

**반복 오류 패턴:**
- `반드시` 사용: v_505 (interpretation)
- `해야 한다` 사용: v_511(interpretation), v_545(application)
- `알았으면 좋겠어`: v_514 (interpretation 종결 — 교사조)
- 따옴표 원어 표기: v_517 `'넘친다'는`, v_531 `'싸운다'는` — 원어 직접 표기와 동일 패턴
- `봐봐` 동사 중복: v_525, v_534 — Haiku 배치에서 처음 등장한 패턴

**Zone 맥락:**
- deep_dark 15개, peak_mode 15개, recharge 10개, second_wind 10개로 균등 분배
- v_514 peak_mode인데 interpretation에 「저녁까지」 표현
- v_537 recharge인데 application에 「오늘 아침부터」 표현

**Haiku vs Sonnet 종합:**
- Haiku는 verse_short_ko 품질이 오히려 더 좋음
- interpretation 구조 완성도는 Sonnet과 비슷 (2점 이하 2/50건 = 4%)
- forbidden_tone_patterns 위반율은 비슷 (약 6~8%)
