/**
 * upload_design_test.js — design_test/ 폴더 원클릭 업로드
 *
 * design_test/ 폴더의 선별된 이미지를 자동으로 분류하여
 * Firebase Storage → Google Sheets → Firestore 순서로 반영합니다.
 *
 *   bg_*.jpg  → Zone 고정 배경 (background_images/)
 *   img_*.png → 감성 이미지 (images/)
 *
 * 파일명 규칙:
 *   Zone 배경:   bg_{zone_id}_{설명}.jpg
 *   감성 이미지: img_{zone_id}_{설명}.png
 *   날씨 배경:   bg_{zone_id}_{weather}_{설명}.jpg
 *
 * 사용법:
 *   node upload_design_test.js --dry-run   # 미리보기 (업로드 없음)
 *   node upload_design_test.js             # 실제 실행
 *
 * 데이터 정책: Storage → Sheets (먼저) → Firestore
 */

require('dotenv').config();
const admin  = require('firebase-admin');
const https  = require('https');
const fs     = require('fs');
const path   = require('path');
const { google } = require('googleapis');

// ─── 설정 ────────────────────────────────────────────────────────────────────

const PROJECT_ID           = 'dailyverse-9260d';
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const DESIGN_TEST_DIR      = path.join(__dirname, '..', 'design_test');
const SHEETS_ID            = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';

const isDryRun = process.argv.includes('--dry-run');

// ─── Zone 메타데이터 ──────────────────────────────────────────────────────────

const VALID_ZONES = new Set([
  'deep_dark', 'first_light', 'rise_ignite', 'peak_mode',
  'recharge', 'second_wind', 'golden_hour', 'wind_down',
]);

const ZONE_META = {
  deep_dark:   { tone: 'dark',   mood: ['calm','serene'],    theme: ['rest','comfort','peace'],       label: '🌑 Deep Dark    (00–03시)' },
  first_light: { tone: 'dark',   mood: ['calm','serene'],    theme: ['renewal','hope','peace'],        label: '🌒 First Light  (03–06시)' },
  rise_ignite: { tone: 'bright', mood: ['bright','dramatic'],theme: ['hope','courage','strength'],     label: '🌅 Rise & Ignite(06–09시)' },
  peak_mode:   { tone: 'bright', mood: ['bright'],           theme: ['wisdom','focus','courage'],      label: '⚡ Peak Mode    (09–12시)' },
  recharge:    { tone: 'mid',    mood: ['calm','warm'],      theme: ['patience','gratitude','renewal'],label: '☀️ Recharge     (12–15시)' },
  second_wind: { tone: 'mid',    mood: ['warm'],             theme: ['strength','focus','patience'],   label: '🌤 Second Wind  (15–18시)' },
  golden_hour: { tone: 'mid',    mood: ['warm','serene'],    theme: ['gratitude','rest','reflection'], label: '🌇 Golden Hour  (18–21시)' },
  wind_down:   { tone: 'dark',   mood: ['calm','cozy'],      theme: ['peace','comfort','rest'],        label: '🌙 Wind Down    (21–24시)' },
};

const WEATHER_KEYWORDS = {
  rainy: 'rainy', raining: 'rainy', rain: 'rainy',
  snowy: 'snowy', snow: 'snowy',
  cloudy: 'cloudy', overcast: 'cloudy',
  foggy: 'misty', misty: 'misty', fog: 'misty',
  stormy: 'stormy', storm: 'stormy',
  sunny: 'sunny', clear: 'sunny',
};

// VERSE_IMAGES Sheets 컬럼 순서 (A~Q)
const VI_HEADERS = [
  'filename','storage_url','source','source_url','license',
  'mode','theme','mood','season','weather','tone','status',
  'notes','text_position','image_id','is_sacred_safe','avoid_themes',
];

// BACKGROUND_IMAGES Sheets 컬럼 순서
const BG_HEADERS = [
  'image_id','filename','storage_url','zone','weather',
  'tone','status','source','license','notes',
];

// DAILY_CARDS_IMAGES Sheets 컬럼 순서
const DC_IMG_HEADERS = [
  'dc_image_id','event_tag','filename','storage_url','source','license','notes',
];

// ─── 파일명 파싱 헬퍼 ─────────────────────────────────────────────────────────

/**
 * dc_img_{event_tag}_{desc}.jpg 에서 event_tag 추출
 * event_tag는 언더스코어 구분 1~2 단어
 * 예: dc_img_childrens_sunday_kids_joy.jpg → event_tag = "childrens_sunday"
 */
function parseEventTag(filename) {
  const base  = path.basename(filename, path.extname(filename));
  const parts = base.replace(/^dc_img_/, '').split('_');
  // 두 단어 조합이 더 자연스러운 경우가 많으므로 앞 2단어를 event_tag로 사용
  return parts.slice(0, 2).join('_');
}

function parseZone(filename) {
  const base  = path.basename(filename, path.extname(filename));
  const parts = base.replace(/^(bg|img)_/, '').split('_');
  const two   = parts.slice(0, 2).join('_');
  const one   = parts[0];
  if (VALID_ZONES.has(two)) return two;
  if (VALID_ZONES.has(one)) return one;
  return null;
}

function detectWeather(filename) {
  const lower = filename.toLowerCase();
  for (const [kw, val] of Object.entries(WEATHER_KEYWORDS)) {
    if (lower.includes(kw)) return val;
  }
  return 'all';
}

// ─── Firebase 초기화 ──────────────────────────────────────────────────────────

function initFirebase() {
  const sa = require(SERVICE_ACCOUNT_PATH);
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(sa),
      storageBucket: `${PROJECT_ID}.firebasestorage.app`,
    });
  }
  return { bucket: admin.storage().bucket() };
}

// Firestore REST API (gRPC 차단 환경 대응)
async function firestoreSet(token, collection, docId, data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (Array.isArray(v)) {
      fields[k] = { arrayValue: { values: v.map(s => ({ stringValue: String(s) })) } };
    } else if (typeof v === 'boolean') {
      fields[k] = { booleanValue: v };
    } else {
      fields[k] = { stringValue: String(v) };
    }
  }
  const body = JSON.stringify({ fields });
  const docPath = `projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`;
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/${docPath}`,
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
      rejectUnauthorized: false,
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(JSON.parse(d));
        else reject(new Error(`Firestore ${res.statusCode}: ${d.substring(0, 200)}`));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function firestoreExists(token, collection, field, value) {
  const body = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: collection }],
      where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: { stringValue: value } } },
      limit: 1,
    },
  });
  return new Promise((resolve) => {
    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`,
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
      rejectUnauthorized: false,
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try {
          const docs = JSON.parse(d);
          resolve(docs.some(r => r.document));
        } catch { resolve(false); }
      });
    });
    req.on('error', () => resolve(false));
    req.write(body);
    req.end();
  });
}

async function initSheets() {
  const sa   = require(SERVICE_ACCOUNT_PATH);
  const auth = new google.auth.GoogleAuth({
    credentials: sa,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  return google.sheets({ version: 'v4', auth: await auth.getClient() });
}

// ─── Sheets 헬퍼 ──────────────────────────────────────────────────────────────

async function getSheetRows(sheets, tabName, colRange) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEETS_ID,
    range: `${tabName}!${colRange}`,
  });
  return res.data.values || [];
}

async function appendSheetRow(sheets, tabName, rowData) {
  await sheets.spreadsheets.values.append({
    spreadsheetId: SHEETS_ID,
    range: `${tabName}!A1`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: [rowData] },
  });
}

async function upsertBgRow(sheets, rowData) {
  const rows  = await getSheetRows(sheets, 'BACKGROUND_IMAGES', 'A:A');
  const imgId = rowData[0];
  const existIdx = rows.findIndex((r, i) => i > 0 && r[0] === imgId);

  if (existIdx !== -1) {
    await sheets.spreadsheets.values.update({
      spreadsheetId: SHEETS_ID,
      range: `BACKGROUND_IMAGES!A${existIdx + 1}:J${existIdx + 1}`,
      valueInputOption: 'RAW',
      requestBody: { values: [rowData] },
    });
    process.stdout.write(` Sheets 업데이트`);
  } else {
    await appendSheetRow(sheets, 'BACKGROUND_IMAGES', rowData);
    process.stdout.write(` Sheets 추가`);
  }
}

// ─── Zone 배경 업로드 (bg_*.jpg) ─────────────────────────────────────────────

async function uploadZoneBg(bucket, token, sheets, localPath) {
  const filename = path.basename(localPath);
  const zoneId   = parseZone(filename);
  if (!zoneId) return { skip: true, reason: 'Zone 파싱 실패' };

  const meta        = ZONE_META[zoneId];
  const weather     = detectWeather(filename);
  const ext         = path.extname(filename).toLowerCase();
  const imageId     = path.basename(filename, ext);          // bg_deep_dark_banpo_hanriver
  const storagePath = `backgrounds/${filename}`;
  const contentType = ext === '.png' ? 'image/png' : 'image/jpeg';
  const storageUrl  = `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${storagePath}`;

  process.stdout.write(`  [bg] ${filename}\n       → ${meta.label}  weather:${weather}  id:${imageId}\n`);

  if (isDryRun) { process.stdout.write('       [dry-run]\n'); return { ok: true }; }

  // 1) Storage
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: { contentType, cacheControl: 'public, max-age=31536000' },
  });
  await bucket.file(storagePath).makePublic();
  process.stdout.write('       Storage ✅');

  // 2) Sheets 먼저
  const bgRow = [
    imageId, filename, storageUrl, zoneId, weather,
    meta.tone, 'active', 'morning manna Design', 'Commercial', '',
  ];
  await upsertBgRow(sheets, bgRow);
  process.stdout.write(' Sheets ✅');

  // 3) Firestore (REST API — gRPC 차단 환경 대응)
  await firestoreSet(token, 'background_images', imageId, {
    bg_id: imageId, filename, storage_url: storageUrl,
    zone: zoneId, mode: zoneId, weather,
    tone: meta.tone, status: 'active',
    source: 'morning manna Design', license: 'Commercial',
  });
  process.stdout.write(' Firestore ✅\n');

  return { ok: true };
}

// ─── 감성 이미지 업로드 (img_*.png) ──────────────────────────────────────────

async function getNextImgId(sheets) {
  const rows = await getSheetRows(sheets, 'VERSE_IMAGES', 'O:O');  // image_id 열
  const ids  = rows.flat().filter(v => /^img_\d+$/.test(v));
  const max  = ids.reduce((m, id) => Math.max(m, parseInt(id.replace('img_',''))), 49);
  return max + 1;
}

async function uploadVerseImage(bucket, token, sheets, localPath, nextIdx) {
  const filename = path.basename(localPath);
  const zoneId   = parseZone(filename);
  if (!zoneId) return { skip: true, reason: 'Zone 파싱 실패' };

  const meta        = ZONE_META[zoneId];
  const imageId     = `img_${String(nextIdx).padStart(3, '0')}`;
  const storagePath = `images/${filename}`;
  const contentType = 'image/png';
  const storageUrl  = `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${storagePath}`;

  process.stdout.write(`  [img] ${filename}\n       → ${meta.label}  id:${imageId}\n`);

  if (isDryRun) { process.stdout.write('       [dry-run]\n'); return { ok: true }; }

  // 중복 체크 (Sheets filename 열로 확인 — REST 방식)
  const exists = await firestoreExists(token, 'images', 'filename', filename);
  if (exists) { process.stdout.write('       이미 등록됨, 건너뜀\n'); return { skip: true }; }

  // 1) Storage
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: { contentType, cacheControl: 'public, max-age=31536000' },
  });
  await bucket.file(storagePath).makePublic();
  process.stdout.write('       Storage ✅');

  // 2) Sheets 먼저 (VI_HEADERS 순서에 맞게)
  const viRow = [
    filename,                    // A filename
    storageUrl,                  // B storage_url
    'morning manna Design',      // C source
    '',                          // D source_url
    'Commercial',                // E license
    zoneId,                      // F mode
    meta.theme.join(','),        // G theme
    meta.mood.join(','),         // H mood
    'all',                       // I season
    'all',                       // J weather (감성 이미지는 날씨 무관)
    meta.tone,                   // K tone
    'active',                    // L status
    '',                          // M notes
    'bottom',                    // N text_position
    imageId,                     // O image_id
    'TRUE',                      // P is_sacred_safe
    '',                          // Q avoid_themes
  ];
  await appendSheetRow(sheets, 'VERSE_IMAGES', viRow);
  process.stdout.write(' Sheets ✅');

  // 3) Firestore (REST API)
  await firestoreSet(token, 'images', imageId, {
    image_id:      imageId,
    filename,
    storage_url:   storageUrl,
    source:        'morning manna Design',
    license:       'Commercial',
    mode:          [zoneId],
    theme:         meta.theme,
    mood:          meta.mood,
    season:        ['all'],
    weather:       ['all'],
    tone:          meta.tone,
    text_position: 'bottom',
    is_sacred_safe: true,
    avoid_themes:  [],
    status:        'active',
  });
  process.stdout.write(' Firestore ✅\n');

  return { ok: true };
}

// ─── Daily Card 이미지 업로드 (dc_img_*) ─────────────────────────────────────

async function uploadDailyCardImage(bucket, token, sheets, localPath) {
  const filename  = path.basename(localPath);
  const eventTag  = parseEventTag(filename);
  const imageId   = path.basename(filename, path.extname(filename)); // dc_img_childrens_sunday_kids_joy
  const ext       = path.extname(filename).toLowerCase();
  const contentType = ext === '.png' ? 'image/png' : 'image/jpeg';
  const storagePath = `daily_card_images/${filename}`;
  const storageUrl  = `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${storagePath}`;

  process.stdout.write(`  [dc] ${filename}\n       → event_tag:${eventTag}  id:${imageId}\n`);
  if (isDryRun) { process.stdout.write('       [dry-run]\n'); return { ok: true }; }

  // 중복 체크
  const exists = await firestoreExists(token, 'daily_card_images', 'dc_image_id', imageId);
  if (exists) { process.stdout.write('       이미 등록됨, 건너뜀\n'); return { skip: true }; }

  // 1) Storage
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: { contentType, cacheControl: 'public, max-age=31536000' },
  });
  await bucket.file(storagePath).makePublic();
  process.stdout.write('       Storage ✅');

  // 2) Sheets 먼저
  const dcRow = [
    imageId, eventTag, filename, storageUrl,
    'morning manna Design', 'Commercial', '',
  ];
  // DAILY_CARDS_IMAGES 탭 헤더 확인 후 append
  const existingRows = await getSheetRows(sheets, 'DAILY_CARDS_IMAGES', 'A:A');
  if (existingRows.length === 0) {
    await appendSheetRow(sheets, 'DAILY_CARDS_IMAGES', DC_IMG_HEADERS);
  }
  await appendSheetRow(sheets, 'DAILY_CARDS_IMAGES', dcRow);
  process.stdout.write(' Sheets ✅');

  // 3) Firestore daily_card_images/{imageId}
  await firestoreSet(token, 'daily_card_images', imageId, {
    dc_image_id: imageId, event_tag: eventTag, filename,
    storage_url: storageUrl, source: 'morning manna Design', license: 'Commercial',
    status: 'active',
  });
  process.stdout.write(' Firestore ✅\n');

  return { ok: true };
}

// ─── 메인 ────────────────────────────────────────────────────────────────────

async function main() {
  if (!fs.existsSync(DESIGN_TEST_DIR)) {
    console.error(`❌ design_test/ 폴더 없음: ${DESIGN_TEST_DIR}`);
    process.exit(1);
  }

  // 파일 분류
  const allFiles = fs.readdirSync(DESIGN_TEST_DIR)
    .filter(f => /\.(jpg|jpeg|png)$/i.test(f) && !f.startsWith('.'));

  const bgFiles  = allFiles.filter(f => f.startsWith('bg_')).sort();
  const imgFiles = allFiles.filter(f => f.startsWith('img_')).sort();
  const dcFiles  = allFiles.filter(f => f.startsWith('dc_img_')).sort();

  console.log(`\n🖼️  morning manna Design Test 업로드${isDryRun ? ' [DRY-RUN]' : ''}`);
  console.log(`📂 bg_* (Zone 배경): ${bgFiles.length}개 | img_* (감성 이미지): ${imgFiles.length}개 | dc_img_* (절기 이미지): ${dcFiles.length}개`);
  console.log(`📁 폴더: ${DESIGN_TEST_DIR}\n`);

  const { bucket } = initFirebase();
  const sheets = await initSheets();

  // Firestore REST 토큰 (gRPC 차단 환경 대응)
  let token = null;
  if (!isDryRun) {
    const sa   = require(SERVICE_ACCOUNT_PATH);
    const auth = new google.auth.GoogleAuth({ credentials: sa, scopes: ['https://www.googleapis.com/auth/datastore'] });
    token = (await (await auth.getClient()).getAccessToken()).token;
  }

  // ── Zone 배경 처리 ─────────────────────────────────────────────────────────
  console.log('═══════════════════════════════════════════');
  console.log(`Zone 배경 (bg_*.jpg) — ${bgFiles.length}개`);
  console.log('═══════════════════════════════════════════');

  let bgOk = 0, bgSkip = 0, bgFail = 0;
  for (const f of bgFiles) {
    try {
      const r = await uploadZoneBg(bucket, token, sheets, path.join(DESIGN_TEST_DIR, f));
      if (r.ok) bgOk++; else bgSkip++;
    } catch (e) {
      console.error(`  ❌ ${f}: ${e.message}`);
      bgFail++;
    }
  }

  // ── 감성 이미지 처리 ───────────────────────────────────────────────────────
  console.log('\n═══════════════════════════════════════════');
  console.log(`감성 이미지 (img_*.png) — ${imgFiles.length}개`);
  console.log('═══════════════════════════════════════════');

  let nextIdx = isDryRun ? 50 : await getNextImgId(sheets);
  console.log(`  다음 image_id 시작: img_${String(nextIdx).padStart(3,'0')}\n`);

  let viOk = 0, viSkip = 0, viFail = 0;
  for (const f of imgFiles) {
    try {
      const r = await uploadVerseImage(bucket, token, sheets, path.join(DESIGN_TEST_DIR, f), nextIdx);
      if (r.ok) { viOk++; nextIdx++; } else viSkip++;
    } catch (e) {
      console.error(`  ❌ ${f}: ${e.message}`);
      viFail++;
    }
  }

  // ── 절기 이미지 처리 ────────────────────────────────────────────────────────
  let dcOk = 0, dcSkip = 0, dcFail = 0;
  if (dcFiles.length > 0) {
    console.log('\n═══════════════════════════════════════════');
    console.log(`절기 이미지 (dc_img_*) — ${dcFiles.length}개`);
    console.log('═══════════════════════════════════════════');
    for (const f of dcFiles) {
      try {
        const r = await uploadDailyCardImage(bucket, token, sheets, path.join(DESIGN_TEST_DIR, f));
        if (r.ok) dcOk++; else dcSkip++;
      } catch (e) {
        console.error(`  ❌ ${f}: ${e.message}`);
        dcFail++;
      }
    }
  }

  // ── 결과 ────────────────────────────────────────────────────────────────────
  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║             업로드 완료 요약              ║');
  console.log('╠══════════════════════════════════════════╣');
  console.log(`║ Zone 배경   성공:${String(bgOk).padStart(3)}  건너뜀:${String(bgSkip).padStart(3)}  실패:${String(bgFail).padStart(3)} ║`);
  console.log(`║ 감성 이미지 성공:${String(viOk).padStart(3)}  건너뜀:${String(viSkip).padStart(3)}  실패:${String(viFail).padStart(3)} ║`);
  if (dcFiles.length > 0)
    console.log(`║ 절기 이미지 성공:${String(dcOk).padStart(3)}  건너뜀:${String(dcSkip).padStart(3)}  실패:${String(dcFail).padStart(3)} ║`);
  console.log('╚══════════════════════════════════════════╝');

  if (!isDryRun && (bgOk + viOk) > 0) {
    console.log('\n✅ 다음 단계:');
    console.log('  1. Sheets VERSE_IMAGES 탭에서 theme 값 세밀 조정 (선택)');
    console.log('  2. zone-image-inspector로 오버레이 필요 이미지 검수 (선택)');
    console.log('  3. 앱 재실행 시 새 배경 자동 적용됨');
  }

  process.exit(0);
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
