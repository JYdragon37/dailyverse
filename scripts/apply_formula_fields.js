/**
 * DailyVerse — 수식 기반 필드 동기화 스크립트
 *
 * 아래 3개 컬럼에 수식을 적용해 원본 컬럼과 자동 동기화합니다:
 *   contemplation_interpretation  =  interpretation
 *   contemplation_appliance       =  application
 *   contemplation_ko              =  verse_full_ko
 *
 * 사용법:
 *   node apply_formula_fields.js
 */

const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

// 수식 매핑: { 대상 컬럼명: 원본 컬럼명 }
const FORMULA_MAP = {
  contemplation_interpretation: 'interpretation',
  contemplation_appliance: 'application',
  contemplation_ko: 'verse_full_ko',
};

// 열 번호(0-indexed) → 열 문자 변환 (0=A, 1=B, ..., 25=Z, 26=AA ...)
function colLetter(idx) {
  let letter = '';
  let n = idx + 1;
  while (n > 0) {
    const rem = (n - 1) % 26;
    letter = String.fromCharCode(65 + rem) + letter;
    n = Math.floor((n - 1) / 26);
  }
  return letter;
}

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  // 1. 헤더 행 읽기
  const headerRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!1:1`,
  });
  const headers = (headerRes.data.values?.[0] || []).map(h => String(h).trim());
  console.log(`헤더 ${headers.length}개 감지: ${headers.join(', ')}\n`);

  // 2. 열 인덱스 확인
  for (const [target, source] of Object.entries(FORMULA_MAP)) {
    const targetIdx = headers.indexOf(target);
    const sourceIdx = headers.indexOf(source);

    if (targetIdx === -1) { console.error(`❌ 대상 컬럼 없음: ${target}`); continue; }
    if (sourceIdx === -1) { console.error(`❌ 원본 컬럼 없음: ${source}`); continue; }

    const targetCol = colLetter(targetIdx);
    const sourceCol = colLetter(sourceIdx);
    console.log(`${target} (${targetCol}) ← =${source} (${sourceCol})`);
  }

  // 3. 데이터 행 수 파악
  const dataRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:A`,
  });
  const totalRows = (dataRes.data.values?.length || 1);
  const dataRowCount = totalRows - 1; // 헤더 제외
  console.log(`\n데이터 행 수: ${dataRowCount}행 (2~${totalRows}행)\n`);

  if (dataRowCount <= 0) {
    console.log('데이터 없음. 종료.');
    return;
  }

  // 4. 각 대상 컬럼에 수식 일괄 적용
  const updates = [];

  for (const [target, source] of Object.entries(FORMULA_MAP)) {
    const targetIdx = headers.indexOf(target);
    const sourceIdx = headers.indexOf(source);
    if (targetIdx === -1 || sourceIdx === -1) continue;

    const targetCol = colLetter(targetIdx);
    const sourceCol = colLetter(sourceIdx);

    // 수식 배열: 각 행에 대해 =SOURCE_COL{rowNum} 형태
    const formulaValues = [];
    for (let row = 2; row <= totalRows; row++) {
      formulaValues.push([`=${sourceCol}${row}`]);
    }

    updates.push({
      range: `${SHEET_NAME}!${targetCol}2:${targetCol}${totalRows}`,
      values: formulaValues,
    });

    console.log(`✅ ${target} → ${formulaValues.length}개 수식 준비 (=${sourceCol}2:${sourceCol}${totalRows})`);
  }

  // 5. 배치 업데이트 실행
  console.log('\n구글 시트에 수식 적용 중...');
  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: {
      valueInputOption: 'USER_ENTERED', // 수식으로 처리
      data: updates,
    },
  });

  console.log('\n🎉 완료! 3개 컬럼에 수식이 적용되었습니다.');
  console.log('→ Google Sheets에서 확인 후 uploadVersesToFirestore() 또는 sync_sheets_to_firestore.js 실행하세요.');
}

main().catch(err => {
  console.error('오류:', err.message || err);
  process.exit(1);
});
