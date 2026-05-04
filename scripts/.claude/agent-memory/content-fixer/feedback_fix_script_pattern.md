---
name: Sheets 수정 스크립트 패턴
description: content-fixer가 Google Sheets를 업데이트할 때 사용하는 표준 패턴
type: feedback
---

행 번호를 하드코딩하지 말고 항상 A열 동적 탐색으로 verse_id → 행번호 맵을 먼저 구성한다.

**Why:** verse_id 순서가 Sheets에서 고정되지 않으며, 삽입/삭제로 행 번호가 바뀔 수 있다. 이전 스크립트들이 하드코딩 행 번호를 사용해 잘못된 셀을 덮어쓴 사례가 있었다.

**How to apply:**
1. `sheets.spreadsheets.values.get({ range: 'VERSES!A:A' })`로 A열 전체 읽기
2. `colAValues.forEach((row, i) => { rowMap[row[0]] = i + 1; })` 로 맵 구성
3. 수정 전 `missingIds` 체크로 대상 누락 경고
4. `sheets.spreadsheets.values.batchUpdate()`로 한 번에 처리

환경 변수: `NODE_TLS_REJECT_UNAUTHORIZED=0` 필수 (TLS 인증서 검증 우회).
스크립트 내부에서 `process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';` 선언 또는 실행 시 prefix로 지정.
