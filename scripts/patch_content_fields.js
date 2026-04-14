/**
 * patch_content_fields.js
 *
 * 특정 verse_id의 interpretation/application 필드를 수정합니다.
 * Google Sheets + Firestore 동시 업데이트.
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
}
const db = admin.firestore();

// ── 수정 데이터 정의 ─────────────────────────────────────────────
const PATCHES = [
  // ── A: 어투 수정 ──────────────────────────────────────────────
  {
    id: 'v_146',
    field: 'application',
    newValue: `오늘 밤 힘들었다면 알람을 맞추며 떠올려봐.
지금 뿌리는 눈물이 내일의 기쁨이 될 거야.`
  },
  {
    id: 'v_116',
    field: 'application',
    newValue: `알람을 맞추며 생각해봐.
어떤 어두운 밤도 아침을 막을 수 없어.`
  },
  {
    id: 'v_123',
    field: 'application',
    newValue: `오늘 밤 알람을 맞추며 생각해봐.
내일도 하나님이 만드신 날이야.`
  },
  {
    id: 'v_179',
    field: 'application',
    newValue: `오늘 밤 알람 맞추기 전에, 오늘 하루 선하심의 흔적 하나를 찾아봐.
분명 있을 거야.`
  },

  // ── B: Zone 맥락 수정 (deep_dark) ────────────────────────────
  {
    id: 'v_051',
    field: 'application',
    newValue: `잠이 안 오는 이 시간에 조용히 중얼거려봐.
"주님, 지금 이 새벽에도 내 곁에 계시네요."`
  },
  {
    id: 'v_088',
    field: 'application',
    newValue: `잠 못 드는 이 시간에 이 기도를 그대로 드려봐.
"주님, 지금 내 말과 마음이 주님 앞에 합당하게 해주세요."`
  },

  // ── C: 원어 표기 + Zone 복합 수정 ────────────────────────────
  {
    id: 'v_069',
    field: 'interpretation',
    newValue: `이 구절의 '인내'는 단순한 기다림이 아니야.
짓눌려도 아래서 버티는 것, 쓰러지지 않고 서있는 거야.
마라톤처럼 포기하지 않는 끈기야.
하나님의 약속은 반드시 이루어져. 그 사이에 필요한 건 딱 하나, 버티는 거야.`
  },
  {
    id: 'v_070',
    field: 'interpretation',
    newValue: `이 구절의 '공의'는 올바른 질서와 정의를 뜻해.
하나님의 공의가 세워질 때 평화가 열매로 온다는 거야.
그건 단순한 갈등 없음이 아니라, 온전한 평화 — 모든 것이 제자리에 있는 온전한 상태야.
오늘 네 삶에서 제자리에 있지 않은 것이 있다면 하나씩 바르게 세워봐.`
  },
  {
    id: 'v_070',
    field: 'application',
    newValue: `오늘 하루 한 번이라도 누군가에게 공정하게 대해봐. 그 작은 정의가 모여 평강을 만든다는 것을 생각해봐.`
  },
];

// ── Google Sheets 업데이트 ────────────────────────────────────────
async function updateSheet(patches, rowMap, headers) {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(__dirname, SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const intCol = headers.indexOf('interpretation');
  const appCol = headers.indexOf('application');

  const colLetter = n => {
    let s = ''; let x = n + 1;
    while (x > 0) { s = String.fromCharCode(65 + ((x - 1) % 26)) + s; x = Math.floor((x - 1) / 26); }
    return s;
  };

  const batchData = [];
  for (const p of patches) {
    const rowNum = rowMap[p.id];
    if (!rowNum) { console.warn(`  ⚠️  ${p.id} 행 번호 없음`); continue; }
    const col = p.field === 'interpretation' ? intCol : appCol;
    const colL = colLetter(col);
    batchData.push({
      range: `${SHEET_NAME}!${colL}${rowNum}`,
      values: [[p.newValue]]
    });
  }

  if (batchData.length === 0) { console.log('  시트: 업데이트 없음'); return; }

  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: { valueInputOption: 'RAW', data: batchData }
  });
  console.log(`  ✅ 시트 ${batchData.length}개 셀 업데이트`);
}

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('\n📊 Google Sheets 행 번호 조회 중...');

  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(__dirname, SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:N`
  });
  const rows = res.data.values || [];
  const headers = rows[0];
  const idCol = headers.indexOf('verse_id');

  // verse_id → 행 번호(1-based) 맵 생성
  const rowMap = {};
  for (let i = 1; i < rows.length; i++) {
    const vid = (rows[i][idCol] || '').trim();
    if (vid) rowMap[vid] = i + 1;
  }

  // 수정 대상 verse_id 목록
  const targetIds = [...new Set(PATCHES.map(p => p.id))];
  for (const id of targetIds) {
    console.log(`  ${id}: 행 ${rowMap[id] || '미발견'}`);
  }

  console.log('\n🔥 Firestore 업데이트 중...');
  // verse_id별로 묶어서 한 번에 업데이트
  const firestoreUpdates = {};
  for (const p of PATCHES) {
    if (!firestoreUpdates[p.id]) firestoreUpdates[p.id] = {};
    firestoreUpdates[p.id][p.field] = p.newValue;
  }

  const batch = db.batch();
  for (const [id, fields] of Object.entries(firestoreUpdates)) {
    console.log(`  ✏️  ${id}: ${Object.keys(fields).join(', ')}`);
    batch.update(db.collection('verses').doc(id), fields);
  }
  await batch.commit();
  console.log(`  ✅ Firestore ${Object.keys(firestoreUpdates).length}개 문서 업데이트`);

  console.log('\n📊 Google Sheets 업데이트 중...');
  await updateSheet(PATCHES, rowMap, headers);

  console.log('\n✨ 완료!');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
