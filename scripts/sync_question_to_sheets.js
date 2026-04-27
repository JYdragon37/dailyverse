/**
 * sync_question_to_sheets.js (1회성)
 *
 * Firestore verses 컬렉션의 question 필드 값을
 * Google Sheets VERSES 탭의 해당 verse_id 행 question 컬럼에 역동기화합니다.
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');
const SHEET_TAB = 'VERSES';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(KEY_FILE)) });
}
const db = admin.firestore();
db.settings({ preferRest: true });  // gRPC 대신 REST 사용 (로컬 TLS 우회)

const isDryRun = process.argv.includes('--dry-run');

async function main() {
  console.log('=== Firestore question → Sheets 역동기화 ===');
  console.log('dry-run:', isDryRun, '\n');

  // 1) Firestore 전체 읽기 (question 필드)
  console.log('Firestore verses 읽는 중...');
  const snap = await db.collection('verses').orderBy('__name__').get();
  const firestoreQuestions = {};
  snap.forEach(d => {
    const q = d.data().question;
    if (q !== undefined && q !== null && q !== '') {
      firestoreQuestions[d.id] = q;
    }
  });
  console.log(`Firestore 총 문서: ${snap.size}개 | question 있는 문서: ${Object.keys(firestoreQuestions).length}개\n`);

  // 2) Google Sheets 현재 상태 읽기
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_TAB}!A1:AZ1`,
  });
  const headers = (res.data.values || [[]])[0];
  console.log('시트 헤더 컬럼 수:', headers.length);

  const verseIdCol = headers.indexOf('verse_id');
  const questionCol = headers.indexOf('question');
  if (verseIdCol === -1) throw new Error('verse_id 컬럼을 찾을 수 없습니다.');
  if (questionCol === -1) throw new Error('question 컬럼을 찾을 수 없습니다.');

  // 컬럼 인덱스를 A1 notation으로 변환
  function colIndexToLetter(idx) {
    let letter = '';
    idx++; // 1-based
    while (idx > 0) {
      const mod = (idx - 1) % 26;
      letter = String.fromCharCode(65 + mod) + letter;
      idx = Math.floor((idx - mod) / 26);
    }
    return letter;
  }

  const questionColLetter = colIndexToLetter(questionCol);
  console.log(`verse_id 컬럼: ${colIndexToLetter(verseIdCol)} (인덱스 ${verseIdCol})`);
  console.log(`question 컬럼: ${questionColLetter} (인덱스 ${questionCol})\n`);

  // 3) 전체 시트에서 verse_id 컬럼 읽기
  const allRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_TAB}!A:AZ`,
  });
  const sheetRows = allRes.data.values || [];
  console.log('시트 총 행 수 (헤더 포함):', sheetRows.length);

  // verse_id → 행 번호 맵 (1-based)
  const rowMap = {};
  for (let i = 1; i < sheetRows.length; i++) {
    const vid = sheetRows[i][verseIdCol];
    if (vid) rowMap[vid] = i + 1; // 1-based (헤더가 1행)
  }

  // 4) 업데이트 목록 생성
  const updates = [];
  for (const [verseId, question] of Object.entries(firestoreQuestions)) {
    const rowNum = rowMap[verseId];
    if (!rowNum) {
      console.warn(`  경고: ${verseId} 시트에 없음 (스킵)`);
      continue;
    }
    // 현재 시트 값과 비교
    const currentVal = (sheetRows[rowNum - 1] || [])[questionCol] || '';
    if (currentVal === question) continue; // 이미 같으면 스킵

    updates.push({
      range: `${SHEET_TAB}!${questionColLetter}${rowNum}`,
      values: [[question]],
      verseId,
      question,
    });
  }

  console.log(`업데이트 대상: ${updates.length}개 (이미 동일한 값 스킵됨)\n`);

  if (isDryRun) {
    console.log('[dry-run] 첫 5개 미리보기:');
    updates.slice(0, 5).forEach(u => {
      console.log(`  ${u.verseId} → "${u.question.slice(0, 40)}..." (행 ${u.range})`);
    });
    console.log('\n[dry-run] 실제 시트 변경 없음.');
    return;
  }

  if (updates.length === 0) {
    console.log('변경할 내용이 없습니다. 모두 동일합니다.');
    return;
  }

  // 5) batchUpdate (500개씩)
  const CHUNK = 500;
  let done = 0;
  for (let i = 0; i < updates.length; i += CHUNK) {
    const chunk = updates.slice(i, i + CHUNK);
    await sheets.spreadsheets.values.batchUpdate({
      spreadsheetId: SHEET_ID,
      requestBody: {
        valueInputOption: 'RAW',
        data: chunk.map(u => ({ range: u.range, values: u.values })),
      },
    });
    done += chunk.length;
    process.stdout.write(`  업데이트 ${done}/${updates.length}...\n`);
  }

  console.log('\n✅ 완료: Firestore question → Sheets 역동기화 완료');
}

main().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
