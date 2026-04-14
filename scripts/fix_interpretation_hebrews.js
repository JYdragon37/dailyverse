/**
 * fix_interpretation_hebrews.js
 *
 * 원어(히브리어/헬라어) 음역 표기가 포함된 6개 구절의 interpretation 필드 수정
 * 대상: v_054, v_056, v_060, v_064, v_065, v_089
 */

const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

// 수정 대상: verse_id → 위반 구문(검색용) + 수정 후 전체 interpretation
const FIXES = [
  {
    verseId: 'v_054',
    violationSnippet: '"프루레오"는',
    description: '빌립보서 4:7',
  },
  {
    verseId: 'v_056',
    violationSnippet: '"두나토스"는',
    description: '마가복음 10:27',
  },
  {
    verseId: 'v_060',
    violationSnippet: '"알레테이아"는',
    description: '요한복음 8:32',
  },
  {
    verseId: 'v_064',
    violationSnippet: '"카이로"는',
    description: '갈라디아서 6:9',
  },
  {
    verseId: 'v_065',
    violationSnippet: '"로기켄 라트레이안"은',
    description: '로마서 12:1',
  },
  {
    verseId: 'v_089',
    violationSnippet: '"카린 안티 카리토스"는',
    description: '요한복음 1:16',
  },
];

// 각 구절의 interpretation 수정 함수
function applyFix(verseId, original) {
  switch (verseId) {
    case 'v_054':
      // "프루레오"는 군사 용어야. → 이 구절에서 '지킨다'는 표현은 군사용어에서 온 거야.
      return original.replace(
        /"프루레오"는 군사 용어야\./,
        "이 구절에서 '지킨다'는 표현은 군사용어에서 온 거야."
      );

    case 'v_056':
      // "두나토스"는 단순히 가능하다는 게 아니라, 능력이 있다는 뜻이야. → 이 말씀에서 '하실 수 있다'는 단순한 가능성이 아니라 실제 능력이 있다는 선언이야.
      return original.replace(
        /"두나토스"는 단순히 가능하다는 게 아니라, 능력이 있다는 뜻이야\./,
        "이 말씀에서 '하실 수 있다'는 단순한 가능성이 아니라 실제 능력이 있다는 선언이야."
      );

    case 'v_060':
      // "알레테이아"는 단순한 사실 정보가 아니야. → 이 구절의 '진리'는 단순한 사실 정보가 아니야.
      return original.replace(
        /"알레테이아"는 단순한 사실 정보가 아니야\./,
        "이 구절의 '진리'는 단순한 사실 정보가 아니야."
      );

    case 'v_064':
      // "카이로"는 단순한 시간이 아니라 "적절한 때"야. → 이 '때'는 단순한 시간이 아니라 하나님이 정하신 적절한 때야.
      return original.replace(
        /"카이로"는 단순한 시간이 아니라 "적절한 때"야\./,
        "이 '때'는 단순한 시간이 아니라 하나님이 정하신 적절한 때야."
      );

    case 'v_065':
      // "로기켄 라트레이안"은 "이성적 예배", "합당한 예배"야. → 이 구절의 '영적 예배'는 이성적이고 합당한 예배, 즉 몸으로 드리는 일상 전체가 예배가 된다는 뜻이야.
      return original.replace(
        /"로기켄 라트레이안"은 "이성적 예배", "합당한 예배"야\./,
        "이 구절의 '영적 예배'는 이성적이고 합당한 예배, 즉 몸으로 드리는 일상 전체가 예배가 된다는 뜻이야."
      );

    case 'v_089':
      // "카린 안티 카리토스"는 은혜에 더해진 은혜야. → 이 '은혜 위에 은혜'란 받은 은혜가 끝나도 또 새 은혜가 채워진다는 뜻이야.
      return original.replace(
        /"카린 안티 카리토스"는 은혜에 더해진 은혜야\./,
        "이 '은혜 위에 은혜'란 받은 은혜가 끝나도 또 새 은혜가 채워진다는 뜻이야."
      );

    default:
      return original;
  }
}

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(__dirname, SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  // 헤더 읽기
  console.log('📋 헤더 읽는 중...');
  const hRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!1:1`,
  });
  const headers = hRes.data.values[0];
  const idColIdx = headers.indexOf('verse_id');
  const interpColIdx = headers.indexOf('interpretation');

  if (idColIdx === -1 || interpColIdx === -1) {
    throw new Error(`필수 컬럼 없음. verse_id=${idColIdx}, interpretation=${interpColIdx}`);
  }

  // 열 인덱스 → 알파벳 변환
  const colLetter = (n) => {
    let s = '';
    let x = n + 1;
    while (x > 0) {
      s = String.fromCharCode(65 + ((x - 1) % 26)) + s;
      x = Math.floor((x - 1) / 26);
    }
    return s;
  };

  const idColLetter = colLetter(idColIdx);
  const interpColLetter = colLetter(interpColIdx);

  console.log(`  verse_id 열: ${idColLetter} (${idColIdx})`);
  console.log(`  interpretation 열: ${interpColLetter} (${interpColIdx})\n`);

  // 전체 데이터 읽기 (verse_id + interpretation 열)
  console.log('📖 시트 데이터 읽는 중...');
  const maxCol = colLetter(Math.max(idColIdx, interpColIdx));
  const dRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:${maxCol}`,
  });
  const rows = dRes.data.values || [];
  console.log(`  총 ${rows.length}행 로드\n`);

  // 수정 대상 행 찾기
  const targetIds = new Set(FIXES.map((f) => f.verseId));
  const rowMap = {}; // verseId → { rowIndex, currentInterp }

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i] || [];
    const vid = row[idColIdx];
    if (vid && targetIds.has(vid)) {
      rowMap[vid] = {
        rowIndex: i + 1, // 1-based row number in sheet
        currentInterp: row[interpColIdx] || '',
      };
    }
  }

  // 수정 작업
  const batchData = [];
  const results = [];

  for (const fix of FIXES) {
    const found = rowMap[fix.verseId];
    if (!found) {
      console.warn(`  ⚠️  ${fix.verseId} 행 없음`);
      results.push({ verseId: fix.verseId, status: '행 없음' });
      continue;
    }

    const { rowIndex, currentInterp } = found;

    // 위반 구문 포함 여부 확인
    if (!currentInterp.includes(fix.violationSnippet)) {
      console.log(`  ✓ ${fix.verseId} (${fix.description}): 위반 구문 없음 (이미 수정됨?)`);
      console.log(`    현재값: ${currentInterp.substring(0, 80)}...`);
      results.push({ verseId: fix.verseId, status: '위반 구문 없음' });
      continue;
    }

    const newInterp = applyFix(fix.verseId, currentInterp);

    if (newInterp === currentInterp) {
      console.warn(`  ⚠️  ${fix.verseId}: 치환 실패 (regex 불일치)`);
      results.push({ verseId: fix.verseId, status: '치환 실패' });
      continue;
    }

    // 길이 체크
    if (newInterp.length > 200) {
      console.warn(`  ⚠️  ${fix.verseId}: 수정 후 ${newInterp.length}자 (200자 초과)`);
    }

    console.log(`  ✏️  ${fix.verseId} (${fix.description}) → 행 ${rowIndex}`);
    console.log(`    수정 전: ...${currentInterp.substring(0, 60)}...`);
    console.log(`    수정 후: ...${newInterp.substring(0, 60)}...`);
    console.log(`    길이: ${currentInterp.length}자 → ${newInterp.length}자\n`);

    batchData.push({
      range: `${SHEET_NAME}!${interpColLetter}${rowIndex}`,
      values: [[newInterp]],
    });

    results.push({
      verseId: fix.verseId,
      description: fix.description,
      before: currentInterp.substring(0, 30),
      after: newInterp.substring(0, 30),
      status: '수정됨',
    });
  }

  if (batchData.length === 0) {
    console.log('변경 대상 없음. 종료.');
    process.exit(0);
  }

  // Sheets 업데이트
  console.log(`\n📝 Google Sheets 업데이트 중 (${batchData.length}개)...`);
  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: { valueInputOption: 'RAW', data: batchData },
  });
  console.log(`  ✅ ${batchData.length}개 행 업데이트 완료\n`);

  // 결과 보고
  console.log('=== 수정 결과 ===');
  console.log('| verse_id | reference | 수정 전 (30자) | 수정 후 (30자) |');
  console.log('|---|---|---|---|');
  for (const r of results) {
    if (r.status === '수정됨') {
      console.log(`| ${r.verseId} | ${r.description} | ${r.before} | ${r.after} |`);
    } else {
      console.log(`| ${r.verseId} | - | ${r.status} | - |`);
    }
  }

  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
