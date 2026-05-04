---
name: 2026-04-28 QA 수정 이력
description: v_503~v_552 범위 QA 결과 기반 VERSES 탭 수정 10건 (8 verse_id, 8 Sheets 셀) 완료
type: project
---

2026-04-28에 QA 검수 결과를 받아 VERSES 탭을 수정했다.
수정 스크립트: `scripts/fix_20260428_qa.js`
대상 범위: v_503~v_552 (행 491~540)

**작업 내용:**

1. **어투 위반 (forbidden_tone) 수정 5건**
   - v_505 interpretation: "반드시 열매를 맺는다는 거지" → "분명 열매를 맺는 거야"
   - v_505 interpretation: "알아야 해" → "그 수고가 헛되지 않다는 거야"
   - v_511 interpretation: "생각하고 있지만" → "느껴지지만"
   - v_545 application: "해야 한다는" → "해야 할 것 같은"
   - v_514 interpretation: "알았으면 좋겠어" → "소중한 부분이야"

2. **원어 직접 표기 위반 수정 2건** (따옴표로 단어 강조한 형태)
   - v_517 interpretation: `'넘친다'는` → `넘친다는`
   - v_531 interpretation: `'싸운다'는` → `싸운다는`

3. **application "봐봐" 중복 표현 수정 2건**
   - v_525 application: "바라봐봐" → "바라봐"
   - v_534 application: "천천히 봐봐" → "천천히 봐"

4. **Zone 맥락 재작성 1건**
   - v_514 interpretation (peak_mode, 09-12시):
     "새벽부터 저녁까지" 저녁 연상 표현 제거 → 오전 집중 맥락으로 재작성
     배경 문장을 "하나님이 만드신 세상이 부지런히 자기 일을 하며 살아가는 모습을 노래했어"로 교체

**Why:** v_503~v_552 배치 구절 중 어투·원어 표기·중복 표현·Zone 맥락 위반 항목.

**How to apply:** 원어 따옴표 강조 패턴(`'단어'는`)은 원어 직접 표기 위반으로 간주하여 따옴표 제거.

**결과:** 8건 성공. Firestore 미동기화 상태 → `node scripts/sync_verses.js` 실행 필요.
