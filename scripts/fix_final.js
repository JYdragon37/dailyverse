const { google } = require('googleapis');
const key = require('/Users/jeongyong/workspace/dailyverse/scripts/serviceAccountKey.json');
const auth = new google.auth.GoogleAuth({ credentials: key, scopes: ['https://www.googleapis.com/auth/spreadsheets'] });

async function main() {
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });
  const spreadsheetId = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
  const sheetId = 0;

  const r = await sheets.spreadsheets.values.get({ spreadsheetId, range: 'VERSES!A2:M200' });
  const rows = r.data.values || [];

  const targets = {};
  rows.forEach((row, i) => {
    const id = row[0];
    if (['v_079','v_071','v_081'].includes(id)) {
      if (!targets[id]) targets[id] = { rowNum: i+2, interp: row[12]||'' };
      else targets[id].dupRow = i+2;
    }
  });

  console.log('타겟:', JSON.stringify(Object.keys(targets).map(k => ({ id:k, row: targets[k].rowNum, dup: targets[k].dupRow }))));

  // v_079: "아나파우오"는 제거
  const v079 = targets['v_079'];
  if (v079) {
    const old = '"아나파우오"는 잠시 멈추고 숨을 돌린다는 뜻이야.';
    const rep = "이 구절의 '쉼'은 잠시 멈추고 숨을 돌린다는 뜻이야.";
    const fixed = v079.interp.replace(old, rep);
    await sheets.spreadsheets.values.update({
      spreadsheetId, range: 'VERSES!M' + v079.rowNum,
      valueInputOption: 'RAW', requestBody: { values: [[fixed]] }
    });
    console.log('v_079 수정 완료:', fixed.substring(0,60));
  }

  // v_071: "토브 바헤세드"는 제거
  const v071 = targets['v_071'];
  if (v071) {
    const old = '"토브 바헤세드"는 좋으심과 언약적 사랑이야.';
    const rep = "이 '선하심과 인자하심'은 하나님의 좋으심과 변치 않는 언약적 사랑이야.";
    const fixed = v071.interp.replace(old, rep);
    await sheets.spreadsheets.values.update({
      spreadsheetId, range: 'VERSES!M' + v071.rowNum,
      valueInputOption: 'RAW', requestBody: { values: [[fixed]] }
    });
    console.log('v_071 수정 완료:', fixed.substring(0,60));
  }

  // v_081 중복 삭제
  const v081 = targets['v_081'];
  if (v081 && v081.dupRow) {
    await sheets.spreadsheets.batchUpdate({ spreadsheetId, requestBody: { requests: [{
      deleteDimension: { range: { sheetId, dimension: 'ROWS', startIndex: v081.dupRow-1, endIndex: v081.dupRow } }
    }]}});
    console.log('v_081 중복 row', v081.dupRow, '삭제 완료');
  } else {
    console.log('v_081 중복 없음 (이미 처리됨)');
  }

  console.log('✅ 완료');
}
main().catch(console.error);
