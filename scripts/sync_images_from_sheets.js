/**
 * DailyVerse — IMAGES 시트 + 로컬 파일 → Firebase Storage + Firestore 동기화
 *
 * 동작 방식:
 *   A. 외부 공개 URL (Unsplash, Pexels, Genspark 공개공유 등) → 직접 다운로드 → 업로드
 *   B. 로컬 파일 (images_to_upload/ 폴더) → 업로드
 *      우선순위: storage_url이 http로 시작하면 A, 아니면 B 시도
 *
 *   - storage_url이 이미 Firebase URL이면 건너뜀 (중복 방지)
 *   - 업로드 완료 후 시트의 storage_url을 Firebase URL로 자동 업데이트
 *   - Firestore images 컬렉션에 메타데이터 저장
 *   - JS 코드 수정 없이 시트 + 파일만 관리하면 됨
 *
 * 시트 컬럼:
 *   filename | storage_url | source | source_url | license |
 *   mode | theme | mood | season | weather | tone | status |
 *   notes | text_position | image_id | is_sacred_safe | avoid_themes
 *
 * 사용법:
 *   1. IMAGES 시트에 메타데이터 입력
 *      - 공개 URL이 있으면 storage_url에 입력
 *      - 로컬 파일이면 filename 입력 후 images_to_upload/ 폴더에 파일 넣기
 *   2. node sync_images_from_sheets.js
 */

const admin  = require('firebase-admin');
const { google } = require('googleapis');
const https  = require('https');
const http   = require('http');
const path   = require('path');
const fs     = require('fs');

// ─── 설정 ──────────────────────────────────────────────────────────────────
const PROJECT_ID          = 'dailyverse-9260d';
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID            = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME          = 'IMAGES';
const FIREBASE_URL_PREFIX = 'https://storage.googleapis.com';
const LOCAL_IMAGES_DIR    = './images_to_upload';

// ─── 초기화 ────────────────────────────────────────────────────────────────

const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
admin.initializeApp({
  credential:    admin.credential.cert(serviceAccount),
  storageBucket: `${PROJECT_ID}.firebasestorage.app`,
});
const db     = admin.firestore();
const bucket = admin.storage().bucket();

// ─── Google Sheets 읽기 ────────────────────────────────────────────────────

async function getSheetData() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes:  ['https://www.googleapis.com/auth/spreadsheets'],
  });
  return google.sheets({ version: 'v4', auth });
}

// ─── 이미지 다운로드 (URL → Buffer) ────────────────────────────────────────

function downloadImage(url) {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    const request  = protocol.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
        'Accept':     'image/*,*/*',
      },
    }, (res) => {
      // 리다이렉트 처리 (최대 5회)
      if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
        resolve(downloadImage(res.headers.location));
        return;
      }
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}: ${url}`));
        return;
      }
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end',  () => resolve({
        buffer:      Buffer.concat(chunks),
        contentType: res.headers['content-type'] || 'image/jpeg',
      }));
      res.on('error', reject);
    });
    request.on('error', reject);
    request.setTimeout(30000, () => {
      request.destroy();
      reject(new Error(`타임아웃: ${url}`));
    });
  });
}

// ─── 파일명 결정 ────────────────────────────────────────────────────────────

function resolveFilename(row, headers) {
  const get = (col) => String(row[headers.indexOf(col)] || '').trim();
  let filename = get('filename');

  // 확장자 없으면 .jpg 추가
  if (filename && !/\.(jpg|jpeg|png|webp)$/i.test(filename)) {
    filename += '.jpg';
  }

  // filename 컬럼이 비어있으면 image_id 기반으로 생성
  if (!filename) {
    const imageId = get('image_id');
    filename = imageId ? `${imageId}.jpg` : null;
  }

  return filename;
}

// ─── Content-Type → 확장자 ─────────────────────────────────────────────────

function extFromContentType(ct) {
  if (ct.includes('png'))  return '.png';
  if (ct.includes('webp')) return '.webp';
  return '.jpg';
}

// ─── 값 변환 ───────────────────────────────────────────────────────────────

const ARRAY_FIELDS = ['mode', 'theme', 'mood', 'season', 'weather', 'avoid_themes'];
const BOOL_FIELDS  = ['is_sacred_safe'];

function convertValue(key, raw) {
  const str = String(raw || '').trim();
  if (ARRAY_FIELDS.includes(key)) {
    const items = str.split(',').map(s => s.trim()).filter(Boolean);
    return items.length ? items : ['all'];
  }
  if (BOOL_FIELDS.includes(key)) {
    return ['true', '1', 'yes'].includes(str.toLowerCase());
  }
  return str;
}

// ─── 메인 ──────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n📊 Google Sheets IMAGES 탭 읽는 중...');

  const sheets = await getSheetData();
  const res    = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range:         `${SHEET_NAME}!A:Z`,
  });

  const rows    = res.data.values || [];
  if (rows.length < 2) {
    console.error('❌ 데이터 없음 (헤더 포함 최소 2행 필요)');
    process.exit(1);
  }

  const headers = rows[0].map(h => String(h).trim());
  console.log(`✅ 총 ${rows.length - 1}개 행 확인\n`);

  // storage_url 컬럼 인덱스
  const storageUrlIdx = headers.indexOf('storage_url');
  const imageIdIdx    = headers.indexOf('image_id');
  const filenameIdx   = headers.indexOf('filename');
  if (storageUrlIdx === -1) {
    console.error('❌ storage_url 컬럼 없음');
    process.exit(1);
  }

  let uploaded = 0, skipped = 0, failed = 0;

  for (let i = 1; i < rows.length; i++) {
    const row        = rows[i];
    const sourceUrl  = String(row[storageUrlIdx] || '').trim();
    const rowNum     = i + 1; // 시트 행 번호 (1-indexed, 헤더 제외)

    if (!sourceUrl) {
      console.log(`   행${rowNum}: storage_url 비어있음 — 건너뜀`);
      skipped++;
      continue;
    }

    // 이미 Firebase Storage URL이면 건너뜀
    if (sourceUrl.startsWith(FIREBASE_URL_PREFIX)) {
      const imageId = String(row[imageIdIdx] || '').trim() || `행${rowNum}`;
      console.log(`   ⏭️  ${imageId}: 이미 업로드됨 — 건너뜀`);
      skipped++;
      continue;
    }

    // image_id 결정 (없으면 자동 생성)
    let imageId = String(row[imageIdIdx] || '').trim();
    if (!imageId) {
      imageId = `img_${String(i).padStart(3, '0')}`;
    }

    // 1. 이미지 소스 결정: 외부 공개 URL vs 로컬 파일
    let imgData;
    const isExternalUrl = sourceUrl.startsWith('http');

    if (isExternalUrl) {
      // A. 외부 URL 다운로드 시도
      console.log(`\n📤 [${imageId}] URL 다운로드 중: ${sourceUrl}`);
      try {
        imgData = await downloadImage(sourceUrl);
        console.log(`   다운로드 완료 (${Math.round(imgData.buffer.length / 1024)}KB)`);
      } catch (err) {
        if (err.message.includes('403') || err.message.includes('401')) {
          console.error(`   ❌ 접근 거부 (${err.message})`);
          console.error(`      → 이미지를 PC에 직접 다운로드 후 images_to_upload/ 폴더에 넣어주세요`);
          console.error(`      → 그 다음 시트의 storage_url을 비우고 filename만 입력하세요`);
        } else {
          console.error(`   ❌ 다운로드 실패: ${err.message}`);
        }
        failed++;
        continue;
      }
    } else {
      // B. 로컬 파일에서 읽기
      const filename = resolveFilename(row, headers);
      if (!filename) {
        console.error(`\n   ❌ [행${rowNum}]: filename과 storage_url 모두 비어있음 — 건너뜀`);
        skipped++;
        continue;
      }
      const localPath = path.join(LOCAL_IMAGES_DIR, filename);
      console.log(`\n📤 [${imageId}] 로컬 파일 읽는 중: ${localPath}`);
      if (!fs.existsSync(localPath)) {
        console.error(`   ❌ 파일 없음: ${localPath}`);
        console.error(`      → images_to_upload/ 폴더에 ${filename} 파일을 넣어주세요`);
        failed++;
        continue;
      }
      const ext = path.extname(filename).toLowerCase();
      const contentType = ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg';
      imgData = { buffer: fs.readFileSync(localPath), contentType };
      console.log(`   로컬 파일 읽기 완료 (${Math.round(imgData.buffer.length / 1024)}KB)`);
    }

    // 2. 파일명 결정
    let filename = resolveFilename(row, headers);
    if (!filename) {
      const ext = extFromContentType(imgData.contentType);
      filename  = `${imageId}${ext}`;
    }
    // 확장자가 실제 content-type과 다르면 교정
    if (imgData.contentType.includes('png') && !filename.endsWith('.png')) {
      filename = filename.replace(/\.(jpg|jpeg|webp)$/i, '.png');
    }

    // 3. Firebase Storage 업로드
    const storagePath = `images/${filename}`;
    try {
      const tempPath = `/tmp/dv_${filename}`;
      fs.writeFileSync(tempPath, imgData.buffer);

      await bucket.upload(tempPath, {
        destination: storagePath,
        metadata: {
          contentType:  imgData.contentType,
          cacheControl: 'public, max-age=31536000',
        },
      });

      await bucket.file(storagePath).makePublic();
      fs.unlinkSync(tempPath);
    } catch (err) {
      console.error(`   ❌ Storage 업로드 실패: ${err.message}`);
      failed++;
      continue;
    }

    const firebaseUrl = `${FIREBASE_URL_PREFIX}/${PROJECT_ID}.firebasestorage.app/${storagePath}`;
    console.log(`   ✅ Storage 업로드 완료: ${firebaseUrl}`);

    // 4. Firestore images 컬렉션 저장
    const docData = { image_id: imageId, filename, storage_url: firebaseUrl };
    headers.forEach((key, j) => {
      if (!key || key === 'storage_url' || key === 'image_id' || key === 'filename') return;
      const val = convertValue(key, row[j]);
      if (val !== '' && val !== null && val !== undefined) docData[key] = val;
    });
    docData.status = docData.status || 'active';

    await db.collection('images').doc(imageId).set(docData, { merge: true });
    console.log(`   ✅ Firestore 저장 완료: images/${imageId}`);

    // 5. 시트의 storage_url을 Firebase URL로 업데이트
    const cellAddress = `${SHEET_NAME}!${columnLetter(storageUrlIdx)}${rowNum + 1}`;
    await sheets.spreadsheets.values.update({
      spreadsheetId:   SHEET_ID,
      range:           cellAddress,
      valueInputOption: 'RAW',
      requestBody:     { values: [[firebaseUrl]] },
    });

    // image_id도 업데이트 (없었던 경우)
    if (!String(row[imageIdIdx] || '').trim()) {
      const idCell = `${SHEET_NAME}!${columnLetter(imageIdIdx)}${rowNum + 1}`;
      await sheets.spreadsheets.values.update({
        spreadsheetId:   SHEET_ID,
        range:           idCell,
        valueInputOption: 'RAW',
        requestBody:     { values: [[imageId]] },
      });
    }

    console.log(`   ✅ 시트 storage_url 업데이트 완료`);
    uploaded++;
  }

  // ── 결과 ─────────────────────────────────────────────────────────────────
  console.log('\n═══════════════════════════════════════');
  console.log('✨ 이미지 동기화 완료!');
  console.log(`   신규 업로드: ${uploaded}개`);
  console.log(`   건너뜀:      ${skipped}개 (이미 업로드됨 또는 URL 없음)`);
  if (failed) console.log(`   실패:        ${failed}개`);
  console.log(`🔗 Storage:   https://console.firebase.google.com/project/${PROJECT_ID}/storage`);
  console.log(`🔗 Firestore: https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
  console.log('═══════════════════════════════════════');
}

// A=0, B=1, ... → 'A', 'B', ...
function columnLetter(idx) {
  let s = '';
  let n = idx;
  do {
    s = String.fromCharCode(65 + (n % 26)) + s;
    n = Math.floor(n / 26) - 1;
  } while (n >= 0);
  return s;
}

main().catch(e => {
  console.error('❌ 오류:', e.message);
  process.exit(1);
});
