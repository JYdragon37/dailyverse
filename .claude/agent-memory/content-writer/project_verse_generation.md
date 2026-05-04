---
name: 말씀 대량 생성 패턴
description: 신규 VERSES 탭 대량 추가 시 사용하는 스크립트·중복 확인·배분 패턴
type: project
---

## 확정된 작업 패턴 (2026-04-28)

**Single Source of Truth**: Google Sheets VERSES 탭 → 이후 `node sync_verses.js`로 Firestore 동기화

### 스크립트 위치
- 생성 스크립트: `/Users/jeongyong/workspace/dailyverse/scripts/generate_verses_50.js`
- 참고 스크립트: `add_new_verses.js` (기존 배치 생성 패턴)

### 실행 방법
```bash
cd /Users/jeongyong/workspace/dailyverse/scripts
NODE_TLS_REJECT_UNAUTHORIZED=0 node generate_verses_50.js
```

### 현황 (2026-04-28 기준)
- 기존 마지막 verse_id: v_436 (row 424)
- 이번 추가 범위: v_437 ~ v_486 (50개)
- Sheets row 범위: 426 ~ 490번 행

**Why:** SSL 인증서 검증이 로컬 환경에서 차단됨 → NODE_TLS_REJECT_UNAUTHORIZED=0 필수
**How to apply:** Google Sheets API 호출 시 항상 이 환경변수 설정

### 중복 체크 필수
신규 구절 추가 전 반드시 기존 reference 목록 조회 후 비교:
```js
const r = await sheets.spreadsheets.values.get({ range: 'VERSES!D2:D500' });
```
- 잠언 3:24, 마가복음 6:31, 갈라디아서 6:9, 이사야 43:2, 시편 63:1, 이사야 50:4, 마가복음 1:35, 나훔 1:7 등이 이미 존재함 (2026-04-28 확인)

### COLUMN_ORDER (헤더 기준)
verse_id, verse_short_ko, verse_full_ko, reference, book, chapter, verse, mode, theme, mood, season, weather, interpretation, application, curated, status, notes, usage_count, cooldown_days, last_shown, show_count, alarm_top_ko, contemplation_ko, contemplation_reference, contemplation_interpretation, contemplation_appliance, question
