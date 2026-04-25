/**
 * upload_alarm_greetings.js
 * Sheets ALARM_GREETINGS 탭 → Firestore alarm_greetings 컬렉션 단방향 sync
 * Sheets가 원본. 하드코딩 데이터 없음.
 */
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const https = require('https');

const SA = require('./serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const PROJECT  = SA.project_id;
const FS_BASE  = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

// ─── Google Auth ───────────────────────────────────────────────────────────────
async function getAuth() {
  return new google.auth.GoogleAuth({
    credentials: SA,
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets.readonly',
      'https://www.googleapis.com/auth/datastore',
    ],
  });
}

let _token = null;
async function getToken(auth) {
  if (_token) return _token;
  const client = await auth.getClient();
  const res = await client.getAccessToken();
  _token = res.token;
  return _token;
}

// ─── Sheets: ALARM_GREETINGS 탭 읽기 ──────────────────────────────────────────
async function readSheetGreetings(auth) {
  const sheets = google.sheets({ version: 'v4', auth });
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: 'ALARM_GREETINGS!A1:E',
  });
  const rows = res.data.values || [];
  if (rows.length < 2) throw new Error('ALARM_GREETINGS 탭에 데이터가 없습니다.');

  const [header, ...dataRows] = rows;
  // 헤더 인덱스 매핑 (순서 변경에 유연하게 대응)
  const idx = {};
  header.forEach((h, i) => { idx[h.trim()] = i; });

  const required = ['gr_id', 'zone_id', 'language', 'text', 'char_count'];
  for (const col of required) {
    if (idx[col] === undefined) throw new Error(`헤더에 '${col}' 컬럼이 없습니다.`);
  }

  return dataRows
    .filter(row => row[idx['gr_id']] && row[idx['gr_id']].trim())
    .map(row => ({
      gr_id:      row[idx['gr_id']].trim(),
      zone_id:    row[idx['zone_id']]    || '',
      language:   row[idx['language']]   || '',
      text:       row[idx['text']]       || '',
      char_count: parseInt(row[idx['char_count']], 10) || 0,
    }));
}

// ─── Firestore REST ────────────────────────────────────────────────────────────
function fsRequest(method, path, token, body) {
  return new Promise((resolve, reject) => {
    const url = `${FS_BASE}/${path}`;
    const bodyStr = body ? JSON.stringify(body) : null;
    const req = https.request(url, {
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...(bodyStr ? { 'Content-Length': Buffer.byteLength(bodyStr) } : {}),
      },
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(d || '{}'));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${d.slice(0, 200)}`));
        }
      });
    });
    req.on('error', reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function firestoreSet(token, collection, docId, fields) {
  const body = {
    fields: Object.fromEntries(
      Object.entries(fields).map(([k, v]) => [
        k,
        typeof v === 'number' ? { integerValue: String(v) } : { stringValue: String(v) }
      ])
    )
  };
  await fsRequest('PATCH', `${collection}/${docId}`, token, body);
}

async function firestoreListIds(token, collection) {
  // pageToken 루프로 전체 문서 ID 수집
  const ids = [];
  let pageToken = null;
  do {
    const qs = pageToken ? `?pageToken=${encodeURIComponent(pageToken)}&pageSize=300` : '?pageSize=300';
    const res = await fsRequest('GET', `${collection}${qs}`, token, null);
    for (const doc of (res.documents || [])) {
      ids.push(doc.name.split('/').pop());
    }
    pageToken = res.nextPageToken || null;
  } while (pageToken);
  return ids;
}

async function firestoreDelete(token, collection, docId) {
  await fsRequest('DELETE', `${collection}/${docId}`, token, null);
}

// ─── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const auth = await getAuth();
  const token = await getToken(auth);

  // 1. Sheets에서 읽기
  console.log('Sheets ALARM_GREETINGS 탭 읽는 중...');
  const greetings = await readSheetGreetings(auth);
  console.log(`  ${greetings.length}건 읽음`);

  // 2. Firestore 기존 문서 ID 목록
  console.log('Firestore alarm_greetings 기존 문서 조회 중...');
  const existingIds = await firestoreListIds(token, 'alarm_greetings');
  console.log(`  기존 ${existingIds.length}건`);

  // 3. Upsert
  console.log(`\nFirestore upsert 중...`);
  const sheetIds = new Set(greetings.map(g => g.gr_id));
  let upsertOk = 0;
  for (const g of greetings) {
    try {
      await firestoreSet(token, 'alarm_greetings', g.gr_id, g);
      upsertOk++;
    } catch (e) {
      console.error(`  ❌ upsert ${g.gr_id}: ${e.message}`);
    }
  }
  console.log(`  ✅ upsert ${upsertOk}/${greetings.length}건 완료`);

  // 4. Sheets에 없는 문서 삭제
  const toDelete = existingIds.filter(id => !sheetIds.has(id));
  if (toDelete.length > 0) {
    console.log(`\n삭제 대상 ${toDelete.length}건: ${toDelete.join(', ')}`);
    let delOk = 0;
    for (const id of toDelete) {
      try {
        await firestoreDelete(token, 'alarm_greetings', id);
        delOk++;
        console.log(`  🗑️  삭제: ${id}`);
      } catch (e) {
        console.error(`  ❌ 삭제 ${id}: ${e.message}`);
      }
    }
    console.log(`  ✅ 삭제 ${delOk}/${toDelete.length}건 완료`);
  } else {
    console.log('\n삭제 대상 없음');
  }

  console.log('\n🎉 alarm_greetings Sheets → Firestore sync 완료');
}

main().catch(e => { console.error('오류:', e.message); process.exit(1); });
