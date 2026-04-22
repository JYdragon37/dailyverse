/**
 * sync_contemplation_ko.js
 *
 * contemplation_ko = verse_full_ko 로 통일
 *  1. Google Sheets contemplation_ko 컬럼을 verse_full_ko 값으로 덮어쓰기
 *  2. Firestore REST API로 각 verse 문서의 contemplation_ko 필드 업데이트
 *
 * 사용법: NODE_TLS_REJECT_UNAUTHORIZED=0 node sync_contemplation_ko.js
 */

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const https = require('https');

const SERVICE_ACCOUNT = require('./serviceAccountKey.json');
const SHEET_ID  = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const PROJECT   = SERVICE_ACCOUNT.project_id;
const FS_BASE   = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

// ─── Google Auth ───────────────────────────────────────────────────────────

async function getAuth() {
  return new google.auth.GoogleAuth({
    credentials: SERVICE_ACCOUNT,
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/datastore',
    ],
  });
}

// ─── Firestore REST helper ─────────────────────────────────────────────────

let _accessToken = null;
async function getAccessToken(auth) {
  if (_accessToken) return _accessToken;
  const client = await auth.getClient();
  const res = await client.getAccessToken();
  _accessToken = res.token;
  return _accessToken;
}

async function firestorePatch(auth, docPath, fields) {
  const token = await getAccessToken(auth);
  const fieldPaths = Object.keys(fields).map(k => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
  const url = `${FS_BASE}/${docPath}?${fieldPaths}`;

  const body = {
    fields: Object.fromEntries(
      Object.entries(fields).map(([k, v]) => [k, { stringValue: v ?? '' }])
    ),
  };

  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => res.statusCode === 200 ? resolve() : reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 200)}`)));
    });
    req.on('error', reject);
    req.write(JSON.stringify(body));
    req.end();
  });
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function main() {
  const auth  = await getAuth();
  const sheets = google.sheets({ version: 'v4', auth });

  // 1. 시트 전체 읽기
  console.log('📖 Sheets 읽는 중...');
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: 'VERSES!A1:BZ250',
  });
  const rows    = res.data.values;
  const headers = rows[0];
  const idIdx       = headers.indexOf('verse_id');
  const fullIdx     = headers.indexOf('verse_full_ko');
  const contemIdx   = headers.indexOf('contemplation_ko');

  if (contemIdx === -1) { console.error('contemplation_ko 컬럼 없음'); return; }

  // 업데이트가 필요한 행 추출
  const toUpdate = [];
  for (let i = 1; i < rows.length; i++) {
    const row   = rows[i];
    const id    = (row[idIdx]  || '').trim();
    const full  = (row[fullIdx] || '').trim();
    const contem = (row[contemIdx] || '').trim();
    if (!id || !full) continue;
    if (full !== contem) toUpdate.push({ rowNum: i + 1, id, full });
  }
  console.log(`수정 필요 행: ${toUpdate.length}건`);

  // 2. Sheets 업데이트 (contemplation_ko = verse_full_ko 값)
  console.log('\n✏️  Sheets contemplation_ko 업데이트 중...');
  const contemColLetter = colLetter(contemIdx);
  const updateData = toUpdate.map(({ rowNum, full }) => ({
    range: `VERSES!${contemColLetter}${rowNum}`,
    values: [[full]],
  }));

  if (updateData.length > 0) {
    await sheets.spreadsheets.values.batchUpdate({
      spreadsheetId: SHEET_ID,
      resource: {
        valueInputOption: 'RAW',
        data: updateData,
      },
    });
    console.log(`✅ Sheets ${updateData.length}건 업데이트 완료`);
  }

  // 3. Firestore 업데이트 (REST API)
  console.log('\n🔥 Firestore contemplation_ko 업데이트 중...');
  let fsOk = 0, fsFail = 0;
  for (const { id, full } of toUpdate) {
    try {
      await firestorePatch(auth, `verses/${id}`, { contemplation_ko: full });
      fsOk++;
      if (fsOk % 20 === 0) console.log(`  ${fsOk}/${toUpdate.length} 완료...`);
    } catch (e) {
      console.error(`  ❌ ${id}: ${e.message}`);
      fsFail++;
    }
  }
  console.log(`✅ Firestore ${fsOk}건 완료, 실패 ${fsFail}건`);

  console.log('\n🎉 완료: contemplation_ko = verse_full_ko 통일');
}

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

main().catch(e => { console.error('오류:', e.message); process.exit(1); });
