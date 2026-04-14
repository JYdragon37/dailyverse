/**
 * DailyVerse — 콘텐츠 컬럼 글자수 카운트 컬럼 추가 스크립트
 *
 * 아래 콘텐츠 컬럼들의 글자수를 세는 len_ 컬럼을 시트 가장 오른쪽에 추가합니다:
 *   verse_full_ko    → len_verse_full_ko
 *   verse_short_ko   → len_verse_short_ko  (없으면 text_ko로 시도)
 *   interpretation   → len_interpretation
 *   application      → len_application
 *   alarm_top_ko     → len_alarm_top_ko
 *   question         → len_question
 *
 * 사용법:
 *   node add_char_count_columns.js
 *
 * 재실행 안전: 이미 len_ 컬럼이 있으면 덮어씌웁니다.
 */

const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

// 대상 콘텐츠 컬럼 목록 (순서 유지)
// 각 항목: { lenName: 'len_xxx', candidates: ['컬럼명1', '컬럼명2'] }
// candidates 순서대로 시트에서 찾아 첫 번째 존재하는 것 사용
const TARGET_COLUMNS = [
  { lenName: 'len_verse_full_ko',   candidates: ['verse_full_ko'] },
  { lenName: 'len_verse_short_ko',  candidates: ['verse_short_ko', 'text_ko'] },
  { lenName: 'len_interpretation',  candidates: ['interpretation'] },
  { lenName: 'len_application',     candidates: ['application'] },
  { lenName: 'len_alarm_top_ko',    candidates: ['alarm_top_ko'] },
  { lenName: 'len_question',        candidates: ['question'] },
];

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
  console.log(`헤더 ${headers.length}개 감지:\n  ${headers.join(', ')}\n`);

  // 2. 데이터 행 수 파악
  const dataRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:A`,
  });
  const totalRows = dataRes.data.values?.length || 1;
  const dataRowCount = totalRows - 1;
  console.log(`데이터 행 수: ${dataRowCount}행 (2~${totalRows}행)\n`);

  if (dataRowCount <= 0) {
    console.log('데이터 없음. 종료.');
    return;
  }

  // 3. 처리할 컬럼 목록 결정
  // 이미 존재하는 len_ 컬럼은 해당 위치에 덮어쓰고,
  // 없는 len_ 컬럼은 현재 헤더 끝 이후에 순서대로 추가
  const processed = [];

  for (const { lenName, candidates } of TARGET_COLUMNS) {
    // 원본 컬럼 찾기
    let sourceCol = null;
    let sourceColName = null;
    for (const cand of candidates) {
      const idx = headers.indexOf(cand);
      if (idx !== -1) {
        sourceCol = idx;
        sourceColName = cand;
        break;
      }
    }

    if (sourceCol === null) {
      console.log(`⏭  스킵: ${lenName} — 원본 컬럼 없음 (후보: ${candidates.join(', ')})`);
      continue;
    }

    // len_ 컬럼이 이미 있는지 확인
    const existingIdx = headers.indexOf(lenName);

    processed.push({
      lenName,
      sourceColIdx: sourceCol,
      sourceColName,
      existingIdx, // -1이면 새로 추가
    });
  }

  if (processed.length === 0) {
    console.log('처리할 컬럼이 없습니다. 종료.');
    return;
  }

  // 4. 새로 추가할 컬럼들의 헤더 위치 결정
  // 기존 len_ 컬럼은 제자리, 신규는 현재 헤더 끝부터 순서대로
  let nextNewIdx = headers.length; // 새 컬럼이 붙을 시작 인덱스

  // 신규 컬럼들에 대해 인덱스 할당
  for (const item of processed) {
    if (item.existingIdx === -1) {
      item.targetIdx = nextNewIdx++;
    } else {
      item.targetIdx = item.existingIdx;
    }
  }

  console.log('처리 계획:');
  for (const item of processed) {
    const status = item.existingIdx === -1 ? '신규 추가' : '덮어쓰기';
    console.log(
      `  [${status}] ${item.lenName} (${colLetter(item.targetIdx)}) ← LEN(${item.sourceColName}[${colLetter(item.sourceColIdx)}])`
    );
  }
  console.log('');

  // 5. 신규 컬럼을 위한 그리드 확장 (열 수 부족 시 appendDimension)
  const newHeaders = processed.filter(item => item.existingIdx === -1);
  if (newHeaders.length > 0) {
    // 스프레드시트 메타데이터에서 현재 시트 columnCount 확인
    const spreadsheetMeta = await sheets.spreadsheets.get({
      spreadsheetId: SHEET_ID,
      fields: 'sheets(properties(sheetId,title,gridProperties))',
    });
    const sheetMeta = spreadsheetMeta.data.sheets?.find(
      s => s.properties?.title === SHEET_NAME
    );
    const currentColCount = sheetMeta?.properties?.gridProperties?.columnCount || 0;
    const neededColCount = headers.length + newHeaders.length;

    console.log(`현재 그리드 열 수: ${currentColCount}, 필요한 열 수: ${neededColCount}`);

    if (neededColCount > currentColCount) {
      const sheetId = sheetMeta?.properties?.sheetId;
      const addCount = neededColCount - currentColCount;
      console.log(`열 ${addCount}개 확장 중...`);

      await sheets.spreadsheets.batchUpdate({
        spreadsheetId: SHEET_ID,
        requestBody: {
          requests: [
            {
              appendDimension: {
                sheetId,
                dimension: 'COLUMNS',
                length: addCount,
              },
            },
          ],
        },
      });
      console.log(`열 ${addCount}개 확장 완료\n`);
    }

    // 신규 헤더들을 각각의 위치에 write
    const headerUpdates = newHeaders.map(item => ({
      range: `${SHEET_NAME}!${colLetter(item.targetIdx)}1`,
      values: [[item.lenName]],
    }));

    await sheets.spreadsheets.values.batchUpdate({
      spreadsheetId: SHEET_ID,
      requestBody: {
        valueInputOption: 'RAW',
        data: headerUpdates,
      },
    });
    console.log(`헤더 ${newHeaders.length}개 추가 완료\n`);
  }

  // 6. 각 len_ 컬럼에 LEN() 수식 일괄 적용
  const dataUpdates = [];

  for (const item of processed) {
    const sourceColLetter = colLetter(item.sourceColIdx);
    const targetColLetter = colLetter(item.targetIdx);

    const formulaValues = [];
    for (let row = 2; row <= totalRows; row++) {
      formulaValues.push([`=LEN(${sourceColLetter}${row})`]);
    }

    dataUpdates.push({
      range: `${SHEET_NAME}!${targetColLetter}2:${targetColLetter}${totalRows}`,
      values: formulaValues,
    });

    console.log(`✅ ${item.lenName} — ${formulaValues.length}개 수식 준비 (=LEN(${sourceColLetter}2)~=LEN(${sourceColLetter}${totalRows}))`);
  }

  console.log('\n구글 시트에 LEN() 수식 적용 중...');
  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: {
      valueInputOption: 'USER_ENTERED',
      data: dataUpdates,
    },
  });

  console.log('\n완료! len_ 컬럼이 시트에 추가/업데이트되었습니다.');
  console.log(`→ 총 ${processed.length}개 컬럼 처리 (신규: ${newHeaders.length}개, 덮어쓰기: ${processed.length - newHeaders.length}개)`);
}

main().catch(err => {
  console.error('오류:', err.message || err);
  process.exit(1);
});
