---
name: v_432-v_486 QA 결과 (2026-04-28)
description: 신규 말씀 71행 검수 결과, 중복 ID 패턴, 핵심 이슈
type: project
---

**run_id:** 2026-04-28-001

총 71행 / 고유 구절 55개 (v_432~v_486) 검수 완료.

**가장 심각한 문제: 중복 ID 16개 (Critical)**
v_437~v_452 구간에서 각 verse_id가 2행에 걸쳐 중복 존재. 행 425~456 총 32행인데 ID는 16개만 부여됨. Sheets 편집 시 ID 자동 채번 수식이 깨진 것으로 추정. sync_verses.js 실행 전 반드시 해결 필요.

동시에 동일 성경 구절 이중 등록도 3건 확인 (마11:29, 시62:8, 시23:3).

**Why:** fetch_verses.js의 중복 ID 스킵 로직으로 인해 앱에는 두 번째 구절이 표시되지 않을 수 있음.

**How to apply:** Sheets에서 v_437~v_452 각 ID에 해당하는 두 구절 중 어떤 것을 해당 ID로 확정할지 결정 후, 나머지 구절에 신규 ID(v_487~v_502 또는 이어서) 부여.

**번영신학 경계선 구절:** v_439(잠11:25), v_462(잠21:5), v_464(잠10:4), v_468(잠13:4) — 잠언 성과-보상 구절들. interpretation/application이 물질적 복 연결을 피하고 있으나 완화 정도 추가 검토 권장.

**어투 위반:** v_461(잠2:6) interpretation 내 "기억해." 마침표 단독 명령형.

**구조 미흡 (실제 2점):** v_461(잠2:6), v_486(눅21:36).

**Zone 정합성:** 전반적으로 양호. recharge/second_wind/peak_mode/deep_dark/rise_ignite/first_light 각 시간대 맥락이 interpretation과 application에 잘 반영됨.
