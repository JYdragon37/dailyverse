---
name: Google Sheets 업로드 패턴
description: VERSES 탭에 신규 구절을 추가할 때의 올바른 인증 방식과 헤더 순서
type: feedback
---

## Sheets API 인증

JWT 직접 생성 방식은 403 오류 발생. 반드시 GoogleAuth keyFile 방식 사용.

```js
const auth = new google.auth.GoogleAuth({
  keyFile: SERVICE_ACCOUNT_PATH,
  scopes: ['https://www.googleapis.com/auth/spreadsheets'],
});
```

**Why:** JWT 방식은 "callers without established identity" 403 오류 발생 확인됨

## VERSES 탭 헤더 컬럼 순서 (2026-04-24 확인)

A: verse_id, B: verse_short_ko, C: verse_full_ko, D: reference, E: book,
F: chapter, G: verse, H: mode, I: theme, J: mood, K: season, L: weather,
M: interpretation, N: application, O: curated, P: status, Q: notes,
R: usage_count, S: cooldown_days, T: last_shown, U: show_count,
V: alarm_top_ko, W: contemplation_ko, X: contemplation_reference,
Y: contemplation_interpretation, Z: contemplation_appliance, AA: question,
AB: len_verse_full_ko, AC: len_verse_short_ko, AD: len_interpretation,
AE: len_application, AF: len_alarm_top_ko, AG: len_question

contemplation_* 및 len_* 컬럼은 수식으로 자동 계산 — 직접 입력 불필요

## 글자수 검증 기준

실제 적용 기준 (content-rules.json 기준):
- verse_short_ko: 10~60자
- verse_full_ko: 20~200자
- interpretation: 80~200자
- application: 30~100자

가이드라인 권장 기준 (contents-guideline.md §7):
- interpretation: 102~154자 (기준 128자)
- application: 49~73자 (기준 61자)

**How to apply:** 자체 검증 스크립트는 content-rules.json 기준으로 통과 판정, 실제 작성 시 가이드라인 권장 범위 최대한 준수
