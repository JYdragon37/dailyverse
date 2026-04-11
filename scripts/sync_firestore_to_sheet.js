/**
 * sync_firestore_to_sheet.js
 *
 * Firestore verses 컬렉션 → Google Sheets VERSES 탭 역동기화
 * verse_id 기준으로 매칭하여 모든 필드를 시트에 업데이트합니다.
 *
 * 사용법:
 *   node sync_firestore_to_sheet.js           # 전체 동기화
 *   node sync_firestore_to_sheet.js --dry-run # 미리보기 (시트 변경 없음)
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

const isDryRun = process.argv.includes('--dry-run');

// ── 컬럼 순서 (헤더 기준) ──────────────────────────────────────
const COLUMN_ORDER = [
  'verse_id', 'verse_short_ko', 'verse_full_ko', 'reference',
  'book', 'chapter', 'verse', 'mode', 'theme', 'mood', 'season', 'weather',
  'interpretation', 'application', 'curated', 'status', 'notes',
  'usage_count', 'cooldown_days', 'last_shown', 'show_count',
  'alarm_top_ko', 'contemplation_ko', 'contemplation_reference',
  'contemplation_interpretation', 'contemplation_appliance', 'question',
];

// Firestore 문서 → 시트 행 배열 변환
function docToRow(id, data) {
  return COLUMN_ORDER.map(col => {
    if (col === 'verse_id') return id;
    const val = data[col];
    if (val === undefined || val === null) return '';
    if (Array.isArray(val)) return val.join(', ');
    return String(val);
  });
}

async function main() {
  console.log('=== Firestore → Google Sheets 동기화 ===');
  console.log('dry-run:', isDryRun, '\n');

  // 1) Firestore 전체 읽기
  console.log('Firestore 읽는 중...');
  const snap = await db.collection('verses').orderBy('__name__').get();
  const firestoreDocs = {};
  snap.forEach(d => { firestoreDocs[d.id] = d.data(); });
  console.log('Firestore 문서:', Object.keys(firestoreDocs).length, '개\n');

  // 2) 시트 현재 상태 읽기
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_TAB}!A:AA`,
  });
  const sheetRows = res.data.values || [];
  const headers = sheetRows[0];
  console.log('시트 현재 행 수 (헤더 포함):', sheetRows.length);

  // verse_id → 시트 행 번호 맵 (1-based, 헤더는 1행)
  const verseIdCol = headers.indexOf('verse_id');
  const rowMap = {};
  for (let i = 1; i < sheetRows.length; i++) {
    const vid = sheetRows[i][verseIdCol];
    if (vid) rowMap[vid] = i + 1; // 1-based row number
  }

  // 3) 변경사항 계산
  const updates = []; // { range, values }
  const newRows = []; // Firestore에는 있지만 시트에 없는 행

  for (const [id, data] of Object.entries(firestoreDocs)) {
    const row = docToRow(id, data);
    if (rowMap[id]) {
      // 기존 행 업데이트
      updates.push({ range: `${SHEET_TAB}!A${rowMap[id]}:AA${rowMap[id]}`, values: [row] });
    } else {
      // 신규 행 추가
      newRows.push(row);
    }
  }

  console.log('업데이트 대상:', updates.length, '행');
  console.log('신규 추가 대상:', newRows.length, '행\n');

  if (isDryRun) {
    console.log('[dry-run] 첫 3개 미리보기:');
    updates.slice(0, 3).forEach(u => {
      const row = u.values[0];
      console.log(' ', row[0], '|', row[1]?.slice(0,20), '|', row[21] || '(alarm_top_ko 없음)', '|', row[26]?.slice(0,20) || '(question 없음)');
    });
    console.log('\n[dry-run] 실제 시트 변경 없음.');
    return;
  }

  // 4) batchUpdate로 기존 행 업데이트 (500개씩)
  const CHUNK = 500;
  for (let i = 0; i < updates.length; i += CHUNK) {
    const chunk = updates.slice(i, i + CHUNK);
    await sheets.spreadsheets.values.batchUpdate({
      spreadsheetId: SHEET_ID,
      requestBody: { valueInputOption: 'RAW', data: chunk },
    });
    process.stdout.write(`업데이트 ${Math.min(i + CHUNK, updates.length)}/${updates.length}... `);
  }

  // 5) 신규 행 append
  if (newRows.length > 0) {
    await sheets.spreadsheets.values.append({
      spreadsheetId: SHEET_ID,
      range: `${SHEET_TAB}!A:AA`,
      valueInputOption: 'RAW',
      requestBody: { values: newRows },
    });
    console.log('\n신규 행 추가:', newRows.length, '개');
  }

  console.log('\n✅ 동기화 완료');
}

main().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
