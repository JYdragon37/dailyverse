---
name: 2026-04-24 content-checker 검수 수정 이력
description: content-checker 결과 기반 VERSES 탭 일괄 수정 34건 완료
type: project
---

2026-04-24에 content-checker 검수 결과를 받아 VERSES 탭을 수정했다.
수정 스크립트: `scripts/fix_checker_results_20260424.js`

**작업 내용:**

1. **inactive 처리 7건** (P열=status)
   - v_342 이사야 40:31 — 6중 중복
   - v_326 이사야 40:31 — 내부 중복
   - v_346 갈라디아서 6:9 — 5중 중복+번영신학 경계
   - v_341 여호수아 1:9 — 3중 중복
   - v_347 골로새서 3:23 — 3중 중복
   - v_355 빌립보서 4:13 — 3중 중복
   - v_357 로마서 8:31 — 4중 중복

2. **verse_full_ko 번역 오류 수정 2건** (C열)
   - v_408: "천사가" → "여호와의 사자가"
   - v_409: "많으신 긍휼대로" 번역문 원문으로 복원 (개역한글 정확 표기)

3. **verse_short_ko 원문 발췌 교체 25건** (B열)
   - v_340~v_414 범위의 신규 추가 구절들 (v_320~v_419 배치)
   - 원칙: verse_full_ko에서 핵심 문장 직접 발췌, 35자(일부 50자) 이내

**Why:** v_320~v_419 배치 구절의 verse_short_ko가 원문 발췌가 아닌 자체 작성 문장으로 되어 있어 개역한글 원문 표기 원칙 위반.

**How to apply:** 향후 신규 배치 구절 추가 시 verse_short_ko가 verse_full_ko의 직접 인용인지 확인 필요.

**결과:** 34/34건 성공. Firestore 미동기화 상태 → `node scripts/sync_sheets_to_firestore.js` 실행 필요.
