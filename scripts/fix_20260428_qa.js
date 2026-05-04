/**
 * fix_20260428_qa.js
 * 2026-04-28 콘텐츠 검수 수정 스크립트
 *
 * 수정 항목:
 *  1. v_505 interpretation: "반드시" → "분명", "알아야 해" → "그 수고가 헛되지 않다는 거야"
 *  2. v_511 interpretation: "생각하고 있지만" → "느껴지지만"
 *  3. v_514 interpretation: 저녁 연상 표현 제거 + "알았으면 좋겠어" → "소중한 부분이야"
 *  4. v_517 interpretation: '넘친다'는 → 넘친다는 (따옴표 제거)
 *  5. v_525 application: "바라봐봐" → "바라봐"
 *  6. v_531 interpretation: '싸운다'는 → 싸운다는 (따옴표 제거)
 *  7. v_534 application: "봐봐" → "봐"
 *  8. v_545 application: "해야 한다는" → "해야 할 것 같은"
 */

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const key = require('./serviceAccountKey.json');

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const VERSES_TAB = 'VERSES';

const COL = {
  verse_id:       0,  // A
  interpretation: 12, // M
  application:    13, // N
};

async function main() {
  const auth = new google.auth.GoogleAuth({
    credentials: key,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  // 1. VERSES 탭 전체 읽기
  console.log('VERSES 탭 데이터 로드 중...');
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SPREADSHEET_ID,
    range: `${VERSES_TAB}!A:N`,
  });
  const rows = res.data.values || [];
  console.log(`총 ${rows.length}행 로드 완료\n`);

  // verse_id → 행 번호 맵 (1-based)
  const verseRowMap = {};
  rows.forEach((row, i) => {
    const vid = (row[COL.verse_id] || '').trim();
    if (vid) verseRowMap[vid] = i + 1;
  });

  function getRow(verseId) {
    const rowNum = verseRowMap[verseId];
    if (!rowNum) return null;
    return rows[rowNum - 1];
  }

  const updates = [];
  const results = [];

  function scheduleUpdate(verseId, colLetter, newValue, fieldLabel, before, after) {
    const rowNum = verseRowMap[verseId];
    if (!rowNum) {
      console.warn(`[WARN] ${verseId} 행을 찾을 수 없음`);
      return;
    }
    updates.push({
      range: `${VERSES_TAB}!${colLetter}${rowNum}`,
      values: [[newValue]],
    });
    results.push({ verseId, field: fieldLabel, before, after });
  }

  // ─────────────────────────────────────────────────────────
  // 1. v_505 interpretation: 어투 수정 2건
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_505');
    const before = row[COL.interpretation];
    // "반드시 열매를 맺는다는 거지" → "분명 열매를 맺는 거야"
    // "알아야 해" → "그 수고가 헛되지 않다는 거야"
    const after = before
      .replace('반드시 열매를 맺는다는 거지', '분명 열매를 맺는 거야')
      .replace('그 수고가 헛되지 않다는 걸 알아야 해', '그 수고가 헛되지 않다는 거야');
    scheduleUpdate('v_505', 'M', after, 'interpretation', before, after);
    console.log('[v_505] interpretation 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 2. v_511 interpretation: 어투 수정
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_511');
    const before = row[COL.interpretation];
    const after = before.replace(
      '혼자 다 해야 한다고 생각하고 있지만',
      '혼자 다 해야 하는 것처럼 느껴지지만'
    );
    scheduleUpdate('v_511', 'M', after, 'interpretation', before, after);
    console.log('\n[v_511] interpretation 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 3. v_514 interpretation: Zone 맥락 수정 + 어투 수정
  //    - "새벽부터 저녁까지" 저녁 연상 표현 제거 → peak_mode 오전 집중 맥락으로
  //    - "알았으면 좋겠어" → "소중한 부분이야"
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_514');
    const before = row[COL.interpretation];
    // 기존: "다윗은 새벽부터 저녁까지 온 세상이 일하는 모습을 관찰하며 그것이 당연한 삶의 방식이라고 노래했어."
    // 수정: 저녁 연상 제거 + 오전 집중 맥락 강조 + 종결 어투 수정
    const after =
      '다윗은 하나님이 만드신 세상이 부지런히 자기 일을 하며 살아가는 모습을 노래했어. 그것이 당연한 삶의 방식이라는 거야. 너도 지금 오전 집중 시간에 책상 앞에서 업무와 공부로 수고하고 있는 거야. 이건 부끄러운 게 아니라 인간의 자연스러운 삶이고, 그 과정 자체가 의미 있는 거야. 성과 압박으로 힘들겠지만, 이 순간의 수고도 삶을 이루는 소중한 부분이야.';
    scheduleUpdate('v_514', 'M', after, 'interpretation', before, after);
    console.log('\n[v_514] interpretation 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 4. v_517 interpretation: 원어 따옴표 제거
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_517');
    const before = row[COL.interpretation];
    const after = before.replace("'넘친다'는", '넘친다는');
    scheduleUpdate('v_517', 'M', after, 'interpretation', before, after);
    console.log('\n[v_517] interpretation 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 5. v_525 application: "봐봐" 중복 제거
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_525');
    const before = row[COL.application];
    const after = before.replace('하늘을 바라봐봐', '하늘을 바라봐');
    scheduleUpdate('v_525', 'N', after, 'application', before, after);
    console.log('\n[v_525] application 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 6. v_531 interpretation: 원어 따옴표 제거
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_531');
    const before = row[COL.interpretation];
    const after = before.replace("'싸운다'는", '싸운다는');
    scheduleUpdate('v_531', 'M', after, 'interpretation', before, after);
    console.log('\n[v_531] interpretation 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 7. v_534 application: "봐봐" 중복 제거
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_534');
    const before = row[COL.application];
    const after = before.replace('천천히 봐봐', '천천히 봐');
    scheduleUpdate('v_534', 'N', after, 'application', before, after);
    console.log('\n[v_534] application 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 8. v_545 application: 어투 수정
  // ─────────────────────────────────────────────────────────
  {
    const row = getRow('v_545');
    const before = row[COL.application];
    const after = before.replace(
      '완벽하게 해야 한다는 생각은',
      '완벽하게 해야 할 것 같은 생각은'
    );
    scheduleUpdate('v_545', 'N', after, 'application', before, after);
    console.log('\n[v_545] application 수정 예약');
    console.log('  before:', before);
    console.log('  after: ', after);
  }

  // ─────────────────────────────────────────────────────────
  // 누락 verse_id 체크
  // ─────────────────────────────────────────────────────────
  const targetIds = ['v_505','v_511','v_514','v_517','v_525','v_531','v_534','v_545'];
  const missingIds = targetIds.filter(id => !verseRowMap[id]);
  if (missingIds.length > 0) {
    console.warn('\n[WARN] 찾을 수 없는 verse_id:', missingIds);
  }

  if (updates.length === 0) {
    console.log('\n업데이트할 항목 없음. 종료.');
    return;
  }

  // ─────────────────────────────────────────────────────────
  // batchUpdate 실행
  // ─────────────────────────────────────────────────────────
  console.log(`\n총 ${updates.length}건 업데이트 실행 중...`);
  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SPREADSHEET_ID,
    requestBody: {
      valueInputOption: 'RAW',
      data: updates,
    },
  });
  console.log('Google Sheets 업데이트 완료.\n');

  // 결과 테이블 출력
  console.log('=== 수정 결과 ===');
  results.forEach(r => {
    console.log(`[${r.verseId}] ${r.field}`);
    console.log(`  수정 전: ${r.before}`);
    console.log(`  수정 후: ${r.after}`);
    console.log('');
  });
}

main().catch(err => {
  console.error('오류:', err.message);
  process.exit(1);
});
