/**
 * upload_alarm_greetings.js
 * alarm_greetings Firestore 컬렉션 + ALARM_GREETINGS Sheets 탭 생성
 * 알람 화면 전용 인사말: '일어날 시간이에요' 뉘앙스, {name} 포함하지 않음 (앱에서 닉네임 추가)
 */
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const https = require('https');

const SA = require('./serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const PROJECT  = SA.project_id;
const FS_BASE  = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

// ─── 알람 인사말 데이터 ────────────────────────────────────────────────────────
// 각 Zone × 언어 × 복수 변형 (앱에서 랜덤 선택)
const ALARM_GREETINGS = [
  // ── deep_dark (00–03) ──
  { gr_id:'ag_001', zone_id:'deep_dark', language:'ko', text:'이 시간에 일어나셨군요.', char_count:13 },
  { gr_id:'ag_002', zone_id:'deep_dark', language:'ko', text:'아직 깊은 밤이에요.', char_count:10 },
  { gr_id:'ag_003', zone_id:'deep_dark', language:'ko', text:'새벽을 깨우는 알람이에요.', char_count:13 },
  { gr_id:'ag_004', zone_id:'deep_dark', language:'en', text:'Time to wake up.', char_count:16 },
  { gr_id:'ag_005', zone_id:'deep_dark', language:'en', text:'Rise in the deep night.', char_count:23 },

  // ── first_light (03–06) ──
  { gr_id:'ag_011', zone_id:'first_light', language:'ko', text:'일어날 시간이에요.', char_count:9 },
  { gr_id:'ag_012', zone_id:'first_light', language:'ko', text:'새벽이 밝아오고 있어요.', char_count:12 },
  { gr_id:'ag_013', zone_id:'first_light', language:'ko', text:'세상보다 먼저 일어난 아침이에요.', char_count:17 },
  { gr_id:'ag_014', zone_id:'first_light', language:'en', text:'Rise and shine!', char_count:15 },
  { gr_id:'ag_015', zone_id:'first_light', language:'en', text:'Early bird alarm!', char_count:17 },

  // ── rise_ignite (06–09) ──
  { gr_id:'ag_021', zone_id:'rise_ignite', language:'ko', text:'좋은 아침이에요, 일어날 시간이에요!', char_count:19 },
  { gr_id:'ag_022', zone_id:'rise_ignite', language:'ko', text:'아침 알람이에요, 일어나세요!', char_count:15 },
  { gr_id:'ag_023', zone_id:'rise_ignite', language:'ko', text:'오늘 하루의 시작이에요.', char_count:12 },
  { gr_id:'ag_024', zone_id:'rise_ignite', language:'en', text:'Good morning! Rise and shine!', char_count:29 },
  { gr_id:'ag_025', zone_id:'rise_ignite', language:'en', text:'Morning alarm! Time to get up!', char_count:30 },

  // ── peak_mode (09–12) ──
  { gr_id:'ag_031', zone_id:'peak_mode', language:'ko', text:'오전 알람이에요, 일어나세요!', char_count:15 },
  { gr_id:'ag_032', zone_id:'peak_mode', language:'ko', text:'활기찬 오전이 기다리고 있어요.', char_count:16 },
  { gr_id:'ag_033', zone_id:'peak_mode', language:'en', text:'Morning alarm!', char_count:14 },
  { gr_id:'ag_034', zone_id:'peak_mode', language:'en', text:'Wake up, it\'s a great morning!', char_count:30 },

  // ── recharge (12–15) ──
  { gr_id:'ag_041', zone_id:'recharge', language:'ko', text:'점심 알람이에요.', char_count:8 },
  { gr_id:'ag_042', zone_id:'recharge', language:'ko', text:'잠깐 쉬는 시간 알람이에요.', char_count:14 },
  { gr_id:'ag_043', zone_id:'recharge', language:'en', text:'Midday alarm!', char_count:13 },
  { gr_id:'ag_044', zone_id:'recharge', language:'en', text:'Lunch break alarm!', char_count:18 },

  // ── second_wind (15–18) ──
  { gr_id:'ag_051', zone_id:'second_wind', language:'ko', text:'오후 알람이에요.', char_count:8 },
  { gr_id:'ag_052', zone_id:'second_wind', language:'ko', text:'오후를 깨우는 알람이에요.', char_count:13 },
  { gr_id:'ag_053', zone_id:'second_wind', language:'en', text:'Afternoon alarm!', char_count:16 },
  { gr_id:'ag_054', zone_id:'second_wind', language:'en', text:'Time to get moving again!', char_count:25 },

  // ── golden_hour (18–21) ──
  { gr_id:'ag_061', zone_id:'golden_hour', language:'ko', text:'저녁 알람이에요.', char_count:8 },
  { gr_id:'ag_062', zone_id:'golden_hour', language:'ko', text:'하루 마무리 알람이에요.', char_count:12 },
  { gr_id:'ag_063', zone_id:'golden_hour', language:'en', text:'Evening alarm!', char_count:14 },
  { gr_id:'ag_064', zone_id:'golden_hour', language:'en', text:'Golden hour alarm!', char_count:18 },

  // ── wind_down (21–24) ──
  { gr_id:'ag_071', zone_id:'wind_down', language:'ko', text:'밤 알람이에요.', char_count:7 },
  { gr_id:'ag_072', zone_id:'wind_down', language:'ko', text:'오늘 하루도 수고했어요, 알람이에요.', char_count:19 },
  { gr_id:'ag_073', zone_id:'wind_down', language:'en', text:'Night alarm!', char_count:12 },
  { gr_id:'ag_074', zone_id:'wind_down', language:'en', text:'Wind down alarm!', char_count:16 },
];

// ─── Google Auth ───────────────────────────────────────────────────────────────
async function getAuth() {
  return new google.auth.GoogleAuth({
    credentials: SA,
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
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

// ─── Firestore REST ────────────────────────────────────────────────────────────
async function firestoreSet(token, collection, docId, fields) {
  const url = `${FS_BASE}/${collection}/${docId}`;
  const body = JSON.stringify({
    fields: Object.fromEntries(
      Object.entries(fields).map(([k, v]) => [
        k,
        typeof v === 'number' ? { integerValue: String(v) } : { stringValue: String(v) }
      ])
    )
  });
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

// ─── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const auth = await getAuth();
  const token = await getToken(auth);

  // 1. Firestore: alarm_greetings 컬렉션 업로드
  console.log(`Firestore alarm_greetings 업로드 (${ALARM_GREETINGS.length}건)...`);
  let ok = 0;
  for (const g of ALARM_GREETINGS) {
    try {
      await firestoreSet(token, 'alarm_greetings', g.gr_id, g);
      ok++;
    } catch(e) {
      console.error(`❌ ${g.gr_id}: ${e.message}`);
    }
  }
  console.log(`✅ Firestore ${ok}/${ALARM_GREETINGS.length}건 완료`);

  // 2. Sheets: ALARM_GREETINGS 탭 생성 및 데이터 업로드
  console.log('\nSheets ALARM_GREETINGS 탭 업로드...');
  const sheets = google.sheets({ version: 'v4', auth });

  // 탭 추가 (이미 있으면 무시)
  try {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: SHEET_ID,
      resource: { requests: [{ addSheet: { properties: { title: 'ALARM_GREETINGS' } } }] }
    });
    console.log('  ALARM_GREETINGS 탭 생성됨');
  } catch(e) {
    console.log('  ALARM_GREETINGS 탭 이미 존재');
  }

  const headers = ['gr_id','zone_id','language','text','char_count'];
  const rows = [headers, ...ALARM_GREETINGS.map(g => headers.map(h => g[h]))];
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: 'ALARM_GREETINGS!A1',
    valueInputOption: 'RAW',
    resource: { values: rows },
  });
  console.log(`✅ Sheets ${ALARM_GREETINGS.length}건 완료`);
  console.log('\n🎉 alarm_greetings 초기 데이터 업로드 완료');
}

main().catch(e => { console.error('오류:', e.message); process.exit(1); });
