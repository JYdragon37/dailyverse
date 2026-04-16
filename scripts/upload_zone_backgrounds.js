/**
 * DailyVerse — Zone 배경 이미지 업로드 스크립트
 *
 * 사용법:
 *   node upload_zone_backgrounds.js           # 실제 업로드
 *   node upload_zone_backgrounds.js --dry-run # 대상 파일 목록만 출력
 *
 * 필요: scripts/serviceAccountKey.json
 *
 * Firestore 컬렉션: background_images
 * 문서 ID: {concept}_{filename_without_ext}  예) seoul_zone1_banpo_all_night
 * Storage 경로: background_images/{concept}/{filename}
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ── 설정 ──────────────────────────────────────────────────────────────────────
const PROJECT_ID = 'dailyverse-9260d';
const STORAGE_BUCKET = 'dailyverse-9260d.firebasestorage.app';
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const ZONE_BACKGROUNDS_DIR = './zone-backgrounds';

// zone_number → zone rawValue 매핑
const ZONE_MAP = {
  1: 'deep_dark',
  2: 'first_light',
  3: 'rise_ignite',
  4: 'peak_mode',
  5: 'recharge',
  6: 'second_wind',
  7: 'golden_hour',
  8: 'wind_down',
};

// overlay_intensity → overlay_opacity 수치 매핑
const OVERLAY_OPACITY_MAP = {
  light: 0.25,
  medium: 0.45,
  heavy: 0.65,
};

// ── 날씨 추출 ──────────────────────────────────────────────────────────────────
/**
 * 파일명에서 weather 필드를 추출합니다.
 * metadata.json에 명시된 weather 값을 우선 사용하고, 없으면 파일명 파싱으로 폴백합니다.
 */
function extractWeatherFromFilename(filename) {
  const lower = filename.toLowerCase();
  if (lower.includes('_rainy_'))  return 'rainy';
  if (lower.includes('_snowy_'))  return 'snowy';
  if (lower.includes('_misty_'))  return 'misty';
  if (lower.includes('_cloudy_')) return 'cloudy';
  if (lower.includes('_sunny_'))  return 'sunny';
  if (lower.includes('_clear_'))  return 'clear';
  return 'all';
}

// ── Firebase 초기화 ────────────────────────────────────────────────────────────
function initFirebase() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`❌ ${SERVICE_ACCOUNT_PATH} 파일이 없습니다.`);
    process.exit(1);
  }
  const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: STORAGE_BUCKET,
  });
  return { db: admin.firestore(), bucket: admin.storage().bucket() };
}

// ── 대상 파일 수집 ─────────────────────────────────────────────────────────────
/**
 * zone-backgrounds/ 하위 각 concept 폴더를 순회하며 업로드 대상 항목을 수집합니다.
 * delete_recommended 상태는 제외합니다.
 *
 * @returns {Array<{
 *   concept: string,
 *   filename: string,
 *   localPath: string,
 *   bgId: string,
 *   zone: string,
 *   zoneNumber: number,
 *   weather: string,
 *   needsOverlay: boolean,
 *   overlayIntensity: string|null,
 *   overlayOpacity: number,
 *   issues: string[],
 * }>}
 */
function collectTargets() {
  const targets = [];

  const conceptFolders = fs.readdirSync(ZONE_BACKGROUNDS_DIR).filter(name => {
    const fullPath = path.join(ZONE_BACKGROUNDS_DIR, name);
    return fs.statSync(fullPath).isDirectory();
  });

  for (const concept of conceptFolders) {
    const folderPath = path.join(ZONE_BACKGROUNDS_DIR, concept);
    const metaPath = path.join(folderPath, 'metadata.json');

    if (!fs.existsSync(metaPath)) {
      console.warn(`⚠️  ${concept}/metadata.json 없음 — 건너뜀`);
      continue;
    }

    const meta = JSON.parse(fs.readFileSync(metaPath, 'utf8'));

    for (const img of meta.images) {
      // delete_recommended 상태는 제외
      if (img.status === 'delete_recommended') {
        console.log(`  🗑  ${concept}/${img.filename} — delete_recommended, 건너뜀`);
        continue;
      }

      const localPath = path.join(folderPath, img.filename);
      if (!fs.existsSync(localPath)) {
        console.warn(`  ⚠️  ${concept}/${img.filename} — 파일 없음, 건너뜀`);
        continue;
      }

      const zoneNumber = img.zone;
      const zone = ZONE_MAP[zoneNumber];
      if (!zone) {
        console.warn(`  ⚠️  ${concept}/${img.filename} — 알 수 없는 zone 번호 ${zoneNumber}, 건너뜀`);
        continue;
      }

      // 파일명에서 확장자 제거 후 bg_id 생성
      const filenameWithoutExt = path.basename(img.filename, path.extname(img.filename));
      const bgId = `${concept}_${filenameWithoutExt}`;

      // weather: metadata > 파일명 파싱 순으로 사용
      const weather = img.weather || extractWeatherFromFilename(img.filename);

      // overlay 설정
      const needsOverlay = img.needs_overlay || false;
      const overlayIntensity = img.overlay_intensity || null;
      const overlayOpacity = needsOverlay
        ? (OVERLAY_OPACITY_MAP[overlayIntensity] ?? 0.45)
        : 0.0;

      targets.push({
        concept,
        filename: img.filename,
        localPath,
        bgId,
        zone,
        zoneNumber,
        weather,
        needsOverlay,
        overlayIntensity,
        overlayOpacity,
        issues: img.issues || [],
      });
    }
  }

  return targets;
}

// ── 단일 파일 업로드 ───────────────────────────────────────────────────────────
async function uploadOne(bucket, db, target) {
  const { concept, filename, localPath, bgId, zone, zoneNumber, weather,
          needsOverlay, overlayIntensity, overlayOpacity, issues } = target;

  // Firestore 문서 존재 여부 확인 → 이미 업로드된 파일 스킵
  const docRef = db.collection('background_images').doc(bgId);
  const existing = await docRef.get();
  if (existing.exists) {
    console.log(`  ⏭  ${bgId} — 이미 존재, 스킵`);
    return 'skipped';
  }

  const storagePath = `background_images/${concept}/${filename}`;
  const contentType = filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

  console.log(`  📤 업로드: ${bgId}`);
  console.log(`       경로: ${storagePath}`);

  // Firebase Storage 업로드
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType,
      cacheControl: 'public, max-age=31536000',
    },
  });

  // 공개 접근 URL 생성
  const file = bucket.file(storagePath);
  await file.makePublic();
  const storageUrl = `https://storage.googleapis.com/${STORAGE_BUCKET}/${storagePath}`;

  // Firestore 문서 저장
  const doc = {
    bg_id:             bgId,
    zone:              zone,
    mode:              zone,   // BackgroundImage Swift 모델 호환 (신형: zone, 레거시: mode)
    zone_number:       zoneNumber,
    concept:           concept,
    filename:          filename,
    storage_url:       storageUrl,
    weather:           weather,
    needs_overlay:     needsOverlay,
    overlay_intensity: overlayIntensity,
    overlay_opacity:   overlayOpacity,
    status:            'active',
    source:            'genspark',
    license:           'commercial',
  };

  if (issues.length > 0) {
    doc.issues = issues;
  }

  await docRef.set(doc);

  console.log(`  ✅ 완료: ${storageUrl}`);
  return 'uploaded';
}

// ── dry-run 출력 ───────────────────────────────────────────────────────────────
function printDryRun(targets) {
  console.log('\n🔍 DRY-RUN 모드 — 실제 업로드 없이 대상 파일 목록만 출력합니다.\n');
  console.log(`총 대상: ${targets.length}개\n`);

  // concept별 그룹화
  const byConceptZone = {};
  for (const t of targets) {
    const key = t.concept;
    if (!byConceptZone[key]) byConceptZone[key] = [];
    byConceptZone[key].push(t);
  }

  let idx = 1;
  for (const [concept, items] of Object.entries(byConceptZone)) {
    console.log(`📁 ${concept} (${items.length}개)`);
    // zone 번호 순 정렬
    items.sort((a, b) => a.zoneNumber - b.zoneNumber || a.filename.localeCompare(b.filename));
    for (const t of items) {
      const overlayStr = t.needsOverlay
        ? ` | overlay: ${t.overlayIntensity} (opacity ${t.overlayOpacity})`
        : '';
      const issueStr = t.issues.length > 0 ? ` [issues: ${t.issues.join(', ')}]` : '';
      console.log(
        `  ${String(idx).padStart(3, ' ')}. [Zone ${t.zoneNumber} ${t.zone.padEnd(12)}] ` +
        `weather:${t.weather.padEnd(7)} | ${t.filename}${overlayStr}${issueStr}`
      );
      console.log(`       bg_id: ${t.bgId}`);
      idx++;
    }
    console.log('');
  }

  console.log('──────────────────────────────────────────────────────────────────');
  console.log(`실제 업로드하려면 --dry-run 없이 실행하세요:`);
  console.log(`  cd scripts && node upload_zone_backgrounds.js`);
}

// ── main ───────────────────────────────────────────────────────────────────────
async function main() {
  const isDryRun = process.argv.includes('--dry-run');

  if (!fs.existsSync(ZONE_BACKGROUNDS_DIR)) {
    console.error(`❌ ${ZONE_BACKGROUNDS_DIR} 폴더가 없습니다.`);
    process.exit(1);
  }

  console.log('\n🌅 DailyVerse — Zone 배경 이미지 업로드 스크립트\n');

  const targets = collectTargets();

  if (targets.length === 0) {
    console.log('업로드할 파일이 없습니다.');
    process.exit(0);
  }

  if (isDryRun) {
    printDryRun(targets);
    process.exit(0);
  }

  // 실제 업로드
  const { db, bucket } = initFirebase();
  console.log(`\n총 ${targets.length}개 파일 업로드 시작...\n`);

  let uploaded = 0;
  let skipped = 0;
  let failed = 0;

  for (const target of targets) {
    try {
      const result = await uploadOne(bucket, db, target);
      if (result === 'uploaded') uploaded++;
      else skipped++;
    } catch (err) {
      console.error(`  ❌ ${target.bgId} 실패: ${err.message}`);
      failed++;
    }
  }

  console.log('\n──────────────────────────────────────────────────────────────────');
  console.log(`✨ 완료!  업로드: ${uploaded}개  /  스킵: ${skipped}개  /  실패: ${failed}개`);
  console.log(`🔗 Firebase Storage: https://console.firebase.google.com/project/${PROJECT_ID}/storage`);
  console.log(`🔗 Firestore:        https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
  process.exit(0);
}

main().catch(err => {
  console.error('❌ 치명적 오류:', err.message);
  process.exit(1);
});
