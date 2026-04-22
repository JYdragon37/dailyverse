/**
 * Sheets의 contemplation_ko 값을 Firestore에 강제 업데이트
 */
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const https = require('https');

const SA = require('./serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const PROJECT  = SA.project_id;
const FS_BASE  = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

async function getToken() {
  const auth = new google.auth.GoogleAuth({ credentials: SA, scopes: ['https://www.googleapis.com/auth/datastore'] });
  const client = await auth.getClient();
  const res = await client.getAccessToken();
  return res.token;
}

async function patch(token, verseId, value) {
  const url = `${FS_BASE}/verses/${verseId}?updateMask.fieldPaths=contemplation_ko`;
  const body = JSON.stringify({ fields: { contemplation_ko: { stringValue: value } } });
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'PATCH',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => res.statusCode === 200 ? resolve() : reject(new Error(`${res.statusCode}: ${d.slice(0,100)}`)));
    });
    req.on('error', reject);
    req.write(body); req.end();
  });
}

async function main() {
  const auth = new google.auth.GoogleAuth({ credentials: SA, scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'] });
  const sheets = google.sheets({ version: 'v4', auth });

  const res = await sheets.spreadsheets.values.get({ spreadsheetId: SHEET_ID, range: 'VERSES!A1:BZ250' });
  const rows = res.data.values;
  const h = rows[0];
  const idIdx = h.indexOf('verse_id');
  const fullIdx = h.indexOf('verse_full_ko');

  const verses = [];
  for (let i = 1; i < rows.length; i++) {
    const id = (rows[i][idIdx] || '').trim();
    const val = (rows[i][fullIdx] || '').trim();
    if (id && val) verses.push({ id, val });
  }
  console.log(`총 ${verses.length}개 구절 Firestore 업데이트 시작...`);

  const token = await getToken();
  let ok = 0, fail = 0;

  for (const { id, val } of verses) {
    try {
      await patch(token, id, val);
      ok++;
      if (ok % 30 === 0) console.log(`  ${ok}/${verses.length}...`);
    } catch(e) {
      console.error(`❌ ${id}: ${e.message}`);
      fail++;
    }
  }
  console.log(`\n✅ 완료: ${ok}건 성공, ${fail}건 실패`);
}

main().catch(e => console.error('오류:', e.message));
