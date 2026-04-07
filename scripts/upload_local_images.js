/**
 * DailyVerse — images_to_upload/ 하위 모든 이미지 자동 업로드
 *
 * 특징:
 *   - 하위 폴더 포함 재귀 탐색 (압축 해제 후 폴더째로 넣어도 OK)
 *   - Firestore에 이미 등록된 filename이면 자동 건너뜀 (중복 없음)
 *   - 파일명 키워드로 mode/theme/mood/tone 자동 추론
 *   - Firebase Storage 업로드 + Firestore 저장 + IMAGES 시트 행 추가
 *
 * 사용법:
 *   node upload_local_images.js
 */

const admin  = require('firebase-admin');
const { google } = require('googleapis');
const path   = require('path');
const fs     = require('fs');

const PROJECT_ID           = 'dailyverse-9260d';
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID             = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const IMAGES_DIR           = './images_to_upload';

// ─── 파일명 키워드 → 메타데이터 추론 ────────────────────────────────────────

const KEYWORD_META = [
  // Mode
  { kw: ['deep_dark','midnight','night','dark_forest','campfire_dark','aurora','moonlit','milky_way'],
    mode: ['deep_dark'] },
  { kw: ['first_light','dawn','blue_hour','foggy','misty_mountain','early'],
    mode: ['first_light'] },
  { kw: ['rise_ignite','sunrise','morning','angkor','rainbow','after_rain','lighthouse','awakening'],
    mode: ['rise_ignite'] },
  { kw: ['peak_mode','peak','noon'],
    mode: ['peak_mode'] },
  { kw: ['recharge','midday'],
    mode: ['recharge'] },
  { kw: ['second_wind','autumn_archway'],
    mode: ['second_wind'] },
  { kw: ['golden_hour','sunset','dusk','cathedral_alley','twilight','ocean_beach','santorini'],
    mode: ['golden_hour'] },
  { kw: ['wind_down','evening','frozen','moonlit','monastery_cliff'],
    mode: ['wind_down'] },

  // Theme
  { kw: ['hope','guidance','lighthouse','rainbow','after_rain','awakening'],  theme: ['hope','renewal'] },
  { kw: ['faith','church','chapel','monastery','cathedral','prayer'],          theme: ['faith','stillness'] },
  { kw: ['stillness','desert','campfire','night','milky_way','moonlit'],       theme: ['stillness','surrender'] },
  { kw: ['wisdom','petra','ruins','ancient'],                                  theme: ['wisdom','courage'] },
  { kw: ['grace','aurora','fog','wonder'],                                     theme: ['grace','rest'] },
  { kw: ['peace','ocean','beach','coast','lake','meadow'],                     theme: ['peace','comfort'] },
  { kw: ['renewal','restoration','forest_morning','autumn','archway'],         theme: ['renewal','hope'] },
  { kw: ['reflection','twilight','cliff','journey'],                           theme: ['reflection','peace'] },
  { kw: ['gratitude','golden','santorini'],                                    theme: ['gratitude','peace'] },
  { kw: ['strength','alpine','frozen'],                                        theme: ['strength','courage'] },

  // Mood
  { kw: ['dramatic','angkor','mountain','rainbow','peak'],         mood: ['dramatic','bright'] },
  { kw: ['bright','morning','sunrise','after_rain'],               mood: ['bright','hopeful'] },
  { kw: ['warm','golden','sunset','autumn','campfire'],            mood: ['warm','cozy'] },
  { kw: ['serene','lake','monastery','misty','blue_hour','frozen'],mood: ['serene','calm'] },
  { kw: ['cozy','aurora','campfire_dark'],                         mood: ['cozy','calm'] },

  // Tone
  { kw: ['night','aurora','midnight','moonlit','campfire_dark','deep','frozen'],  tone: 'dark' },
  { kw: ['bright','morning','sunrise','rainbow','after_rain'],                    tone: 'bright' },
];

function inferMeta(filename) {
  const f = path.basename(filename, path.extname(filename)).toLowerCase();
  let mode = ['all'], theme = ['peace'], mood = ['calm'], tone = 'mid';
  for (const r of KEYWORD_META) {
    const hit = r.kw.some(k => f.includes(k));
    if (!hit) continue;
    if (r.mode)                           mode  = r.mode;
    if (r.theme && theme[0] === 'peace')  theme = r.theme;
    if (r.mood  && mood[0]  === 'calm')   mood  = r.mood;
    if (r.tone)                           tone  = r.tone;
  }
  return { mode, theme, mood, tone };
}

// ─── 재귀 파일 수집 ──────────────────────────────────────────────────────────

function collectImages(dir) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory())
      results.push(...collectImages(full));
    else if (/\.(jpg|jpeg|png)$/i.test(entry.name))
      results.push(full);
  }
  return results;
}

// ─── Firebase 초기화 ────────────────────────────────────────────────────────

const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
admin.initializeApp({
  credential:    admin.credential.cert(serviceAccount),
  storageBucket: `${PROJECT_ID}.firebasestorage.app`,
});
const db = admin.firestore(), bucket = admin.storage().bucket();

// ─── 메인 ────────────────────────────────────────────────────────────────────

async function main() {
  const allFiles = collectImages(IMAGES_DIR);
  console.log(`\n🖼️  발견된 이미지: ${allFiles.length}개\n`);

  const existingSnap  = await db.collection('images').get();
  const existingNames = new Set(existingSnap.docs.map(d => d.data().filename));
  const existingNums  = existingSnap.docs
    .map(d => parseInt((d.id || '').replace('img_', '')))
    .filter(n => !isNaN(n));
  let nextIdx = existingNums.length ? Math.max(...existingNums) + 1 : 1;

  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes:  ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  let uploaded = 0, skipped = 0, failed = 0;
  const newRows = [];

  for (const filePath of allFiles) {
    const filename = path.basename(filePath);
    if (existingNames.has(filename)) {
      console.log(`   ⏭️  ${filename}`);
      skipped++;
      continue;
    }

    const imageId = `img_${String(nextIdx).padStart(3, '0')}`;
    const meta    = inferMeta(filename);
    const ext     = path.extname(filename).toLowerCase();
    const ct      = ext === '.png' ? 'image/png' : 'image/jpeg';
    const dest    = `images/${filename}`;

    console.log(`\n📤 [${imageId}] ${filename}`);
    console.log(`   mode:${meta.mode}  theme:${meta.theme}  mood:${meta.mood}  tone:${meta.tone}`);

    try {
      await bucket.upload(filePath, {
        destination: dest,
        metadata: { contentType: ct, cacheControl: 'public, max-age=31536000' },
      });
      await bucket.file(dest).makePublic();
    } catch (e) {
      console.error(`   ❌ ${e.message}`);
      failed++;
      continue;
    }

    const url = `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${dest}`;
    console.log(`   ✅ ${url}`);

    await db.collection('images').doc(imageId).set({
      image_id: imageId, filename, storage_url: url,
      source: 'Custom', source_url: '', license: 'Commercial',
      mode: meta.mode, theme: meta.theme, mood: meta.mood,
      season: ['all'], weather: ['any'], tone: meta.tone,
      text_position: 'center', is_sacred_safe: true,
      avoid_themes: [], status: 'active', notes: '',
    }, { merge: true });

    newRows.push([
      filename, url, 'Custom', '', 'Commercial',
      meta.mode.join(','), meta.theme.join(','), meta.mood.join(','),
      'all', 'any', meta.tone, 'active', '', 'center', imageId, 'TRUE', '',
    ]);

    nextIdx++;
    uploaded++;
  }

  if (newRows.length > 0) {
    await sheets.spreadsheets.values.append({
      spreadsheetId: SHEET_ID,
      range: 'IMAGES!A1',
      valueInputOption: 'RAW',
      insertDataOption: 'INSERT_ROWS',
      requestBody: { values: newRows },
    });
    console.log(`\n📊 IMAGES 시트 ${newRows.length}행 추가`);
  }

  console.log('\n═══════════════════════════════════════');
  console.log(`✨ 완료!  신규: ${uploaded}  건너뜀: ${skipped}  실패: ${failed}`);
  console.log(`🔗 https://console.firebase.google.com/project/${PROJECT_ID}/storage`);
  console.log('═══════════════════════════════════════');
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
