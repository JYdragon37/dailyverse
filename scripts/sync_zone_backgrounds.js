/**
 * morning manna — Zone 배경 이미지 업로드 (v7.0 — 다중 배경 + 날씨 지원)
 *
 * 변경 이력:
 *   v7.0 (2026-04-26): 다중 배경 지원, 날씨 필드, 자동 tone/mood 추론
 *   v6.0: 8 Zone 지원
 *
 * 파일명 규칙:
 *   bg_{zone_id}_{설명}.jpg             → weather: "all"  (모든 날씨)
 *   bg_{zone_id}_{weather}_{설명}.jpg   → 날씨별 배경
 *
 *   zone_id 목록: deep_dark | first_light | rise_ignite | peak_mode |
 *                 recharge | second_wind | golden_hour | wind_down
 *
 *   weather 키워드 (파일명에 포함 시 자동 감지):
 *     rainy, snowy, cloudy, sunny, misty, foggy, stormy
 *
 * 예시:
 *   bg_deep_dark_banpo_hanriver.jpg          → Zone1, all weather
 *   bg_deep_dark_rainy_neon_streets.jpg      → Zone1, rainy only
 *   bg_golden_hour_autumn_lake_afterglow.jpg → Zone7, all weather
 *
 * 사용법:
 *   zone-backgrounds/ 폴더에 이미지 넣고 실행
 *   node sync_zone_backgrounds.js
 *   node sync_zone_backgrounds.js --dry-run   # 미리보기만
 *
 * 데이터 정책: Sheets 먼저 → Firestore (Single Source of Truth)
 */

const admin  = require('firebase-admin');
const fs     = require('fs');
const path   = require('path');
const { google } = require('googleapis');

// ─── 설정 ────────────────────────────────────────────────────────────────────

const PROJECT_ID          = 'dailyverse-9260d';
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const IMAGES_DIR           = './image-assets/zone-backgrounds';
const SHEETS_ID            = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME           = 'BACKGROUND_IMAGES';
const SHEET_HEADERS        = [
  'image_id', 'filename', 'storage_url', 'zone', 'weather',
  'tone', 'status', 'source', 'license', 'notes',
];

const isDryRun = process.argv.includes('--dry-run');

// ─── Zone 메타데이터 ──────────────────────────────────────────────────────────

const VALID_ZONES = new Set([
  'deep_dark', 'first_light', 'rise_ignite', 'peak_mode',
  'recharge', 'second_wind', 'golden_hour', 'wind_down',
]);

// Zone별 자동 메타데이터
const ZONE_META = {
  deep_dark:   { tone: 'dark',   label: '🌑 Deep Dark   (00–03시)' },
  first_light: { tone: 'dark',   label: '🌒 First Light  (03–06시)' },
  rise_ignite: { tone: 'bright', label: '🌅 Rise & Ignite(06–09시)' },
  peak_mode:   { tone: 'bright', label: '⚡ Peak Mode    (09–12시)' },
  recharge:    { tone: 'mid',    label: '☀️ Recharge     (12–15시)' },
  second_wind: { tone: 'mid',    label: '🌤 Second Wind  (15–18시)' },
  golden_hour: { tone: 'mid',    label: '🌇 Golden Hour  (18–21시)' },
  wind_down:   { tone: 'dark',   label: '🌙 Wind Down    (21–24시)' },
};

// 날씨 키워드 → weather 값 매핑
const WEATHER_KEYWORDS = {
  rainy: 'rainy', raining: 'rainy', rain: 'rainy',
  snowy: 'snowy', snow: 'snowy',
  cloudy: 'cloudy', overcast: 'cloudy',
  foggy: 'misty', misty: 'misty', fog: 'misty',
  stormy: 'stormy', storm: 'stormy',
  sunny: 'sunny', clear: 'sunny',
};

// ─── 파일명 파싱 ──────────────────────────────────────────────────────────────

/**
 * bg_{zone_id}_{...desc...}.jpg 에서 zone_id 추출
 * zone_id는 1~2 단어 (recharge = 1단어, deep_dark = 2단어)
 */
function parseZoneFromFilename(filename) {
  const base  = path.basename(filename, path.extname(filename)); // bg_deep_dark_banpo
  const parts = base.replace(/^bg_/, '').split('_');             // ['deep','dark','banpo']
  const twoWord = parts.slice(0, 2).join('_');                  // deep_dark
  const oneWord = parts[0];                                      // deep
  if (VALID_ZONES.has(twoWord)) return twoWord;
  if (VALID_ZONES.has(oneWord)) return oneWord;
  return null;
}

/**
 * 파일명에서 날씨 키워드 감지
 * bg_deep_dark_rainy_hanriver.jpg → "rainy"
 */
function detectWeather(filename) {
  const lower = filename.toLowerCase();
  for (const [keyword, weather] of Object.entries(WEATHER_KEYWORDS)) {
    if (lower.includes(keyword)) return weather;
  }
  return 'all';
}

// ─── Firebase 초기화 ──────────────────────────────────────────────────────────

function initFirebase() {
  const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: `${PROJECT_ID}.firebasestorage.app`,
    });
  }
  const _db = admin.firestore();
  _db.settings({ preferRest: true });
  return { db: _db, bucket: admin.storage().bucket() };
}

async function initSheets() {
  const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
  const auth = new google.auth.GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  return google.sheets({ version: 'v4', auth: await auth.getClient() });
}

// ─── Sheets upsert ────────────────────────────────────────────────────────────

async function upsertSheetRow(sheets, rowData) {
  const range = `${SHEET_NAME}!A:J`;
  const getRes = await sheets.spreadsheets.values.get({ spreadsheetId: SHEETS_ID, range });
  const rows = getRes.data.values || [];

  if (rows.length === 0) {
    await sheets.spreadsheets.values.append({
      spreadsheetId: SHEETS_ID, range, valueInputOption: 'RAW',
      requestBody: { values: [SHEET_HEADERS] },
    });
    rows.push(SHEET_HEADERS);
  }

  const imageId = rowData[0];
  const existingIdx = rows.findIndex((r, i) => i > 0 && r[0] === imageId);

  if (existingIdx !== -1) {
    // 기존 행 → 전체 업데이트 (storage_url + weather 필드 갱신)
    await sheets.spreadsheets.values.update({
      spreadsheetId: SHEETS_ID,
      range: `${SHEET_NAME}!A${existingIdx + 1}:J${existingIdx + 1}`,
      valueInputOption: 'RAW',
      requestBody: { values: [rowData] },
    });
    console.log(`   📝 Sheets 업데이트: ${imageId}`);
  } else {
    await sheets.spreadsheets.values.append({
      spreadsheetId: SHEETS_ID, range, valueInputOption: 'RAW',
      requestBody: { values: [rowData] },
    });
    console.log(`   📝 Sheets 추가: ${imageId}`);
  }
}

// ─── 메인 업로드 ──────────────────────────────────────────────────────────────

async function uploadOne(bucket, db, sheets, localPath) {
  const filename = path.basename(localPath);
  const zoneId   = parseZoneFromFilename(filename);
  if (!zoneId) {
    console.warn(`⚠️  파일명에서 Zone 파싱 실패, 건너뜀: ${filename}`);
    return false;
  }

  const meta       = ZONE_META[zoneId];
  const weather    = detectWeather(filename);
  const ext        = path.extname(filename).toLowerCase();
  const imageId    = path.basename(filename, ext);          // bg_deep_dark_banpo_hanriver
  const storagePath = `backgrounds/${filename}`;
  const contentType = ext === '.png' ? 'image/png' : 'image/jpeg';
  const storageUrl  = `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${storagePath}`;
  const weatherTag  = weather !== 'all' ? ` [${weather}]` : '';

  console.log(`\n📤 ${filename}  →  ${meta.label}${weatherTag}`);
  console.log(`   zone: ${zoneId}  |  tone: ${meta.tone}  |  weather: ${weather}  |  id: ${imageId}`);

  if (isDryRun) {
    console.log(`   [dry-run] 건너뜀`);
    return true;
  }

  // 1) Storage 업로드
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: { contentType, cacheControl: 'public, max-age=31536000' },
  });
  await bucket.file(storagePath).makePublic();
  console.log(`   ✅ Storage: ${storageUrl}`);

  // 2) Sheets 먼저 (Single Source of Truth)
  const rowData = [
    imageId, filename, storageUrl, zoneId, weather,
    meta.tone, 'active', 'morning manna Design', 'Commercial', '',
  ];
  await upsertSheetRow(sheets, rowData);

  // 3) Firestore (Sheets 성공 후)
  await db.collection('background_images').doc(imageId).set({
    bg_id:       imageId,
    filename,
    storage_url: storageUrl,
    zone:        zoneId,
    mode:        zoneId,      // BackgroundImage.mode CodingKey 호환
    weather,
    tone:        meta.tone,
    status:      'active',
    source:      'morning manna Design',
    license:     'Commercial',
  });
  console.log(`   ✅ Firestore: background_images/${imageId}`);

  return true;
}

async function main() {
  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
    console.log(`\n📁 폴더 생성: ${IMAGES_DIR}/`);
    console.log('이미지를 넣고 다시 실행하세요. 파일명 규칙:');
    console.log('  bg_{zone_id}_{설명}.jpg');
    console.log('  bg_{zone_id}_{weather}_{설명}.jpg  (rainy/snowy/cloudy/sunny/misty)');
    process.exit(0);
  }

  const files = fs.readdirSync(IMAGES_DIR)
    .filter(f => /\.(jpg|jpeg|png)$/i.test(f) && f.startsWith('bg_'))
    .map(f => path.join(IMAGES_DIR, f))
    .sort();

  console.log(`\n🌅 morning manna Zone 배경 업로드 v7.0${isDryRun ? ' [DRY-RUN]' : ''}`);
  console.log(`📂 발견된 bg_* 파일: ${files.length}개\n`);
  if (files.length === 0) { console.log('업로드할 파일이 없습니다.'); process.exit(0); }

  const { db, bucket } = initFirebase();
  const sheets = await initSheets();

  let ok = 0, fail = 0;
  for (const f of files) {
    try {
      if (await uploadOne(bucket, db, sheets, f)) ok++;
      else fail++;
    } catch (e) {
      console.error(`❌ ${path.basename(f)}: ${e.message}`);
      fail++;
    }
  }

  console.log(`\n✨ 완료! 성공: ${ok}  실패: ${fail}`);
  process.exit(0);
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
