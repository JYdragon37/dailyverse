/**
 * DailyVerse — 홈 배경 이미지 업로드 스크립트 (v6.0 — 8 Zone)
 *
 * 사용법:
 *   1. zone-backgrounds/ 폴더에 이미지 파일 넣기
 *      파일명 규칙 (확장자 jpg / jpeg / png 모두 가능):
 *        bg_deep_dark.jpg     🌑 Zone 1: 00–03시
 *        bg_first_light.jpg   🌒 Zone 2: 03–06시
 *        bg_rise_ignite.jpg   🌅 Zone 3: 06–09시
 *        bg_peak_mode.jpg     ⚡ Zone 4: 09–12시
 *        bg_recharge.jpg      ☀️ Zone 5: 12–15시
 *        bg_second_wind.jpg   🌤 Zone 6: 15–18시
 *        bg_golden_hour.jpg   🌇 Zone 7: 18–21시
 *        bg_wind_down.jpg     🌙 Zone 8: 21–24시
 *
 *   2. node upload_backgrounds.js 실행
 *
 * 필요: scripts/serviceAccountKey.json
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'dailyverse-9260d';
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const IMAGES_DIR = './zone-backgrounds';

// 8 Zone 설정
const BACKGROUND_ZONES = [
  { bgId: 'bg_deep_dark',   zone: 'deep_dark',   label: '🌑 Deep Dark   (00–03시)' },
  { bgId: 'bg_first_light', zone: 'first_light', label: '🌒 First Light  (03–06시)' },
  { bgId: 'bg_rise_ignite', zone: 'rise_ignite', label: '🌅 Rise & Ignite(06–09시)' },
  { bgId: 'bg_peak_mode',   zone: 'peak_mode',   label: '⚡ Peak Mode    (09–12시)' },
  { bgId: 'bg_recharge',    zone: 'recharge',    label: '☀️ Recharge     (12–15시)' },
  { bgId: 'bg_second_wind', zone: 'second_wind', label: '🌤 Second Wind  (15–18시)' },
  { bgId: 'bg_golden_hour', zone: 'golden_hour', label: '🌇 Golden Hour  (18–21시)' },
  { bgId: 'bg_wind_down',   zone: 'wind_down',   label: '🌙 Wind Down    (21–24시)' },
];

function initFirebase() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`❌ ${SERVICE_ACCOUNT_PATH} 파일이 없습니다.`);
    process.exit(1);
  }
  const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: `${PROJECT_ID}.firebasestorage.app`,
  });
  return { db: admin.firestore(), bucket: admin.storage().bucket() };
}

async function uploadBackground(bucket, db, zone) {
  const { bgId, zone: zoneId, label } = zone;

  // jpg / jpeg / png 확장자 모두 지원
  const extensions = ['.jpg', '.jpeg', '.png'];
  let localPath = null;
  let filename = null;

  for (const ext of extensions) {
    const candidate = path.join(IMAGES_DIR, `bg_${zoneId}${ext}`);
    if (fs.existsSync(candidate)) {
      localPath = candidate;
      filename = `bg_${zoneId}${ext}`;
      break;
    }
  }

  if (!localPath) {
    console.warn(`⚠️  ${label} — 파일 없음 (bg_${zoneId}.jpg/.png) 건너뜀`);
    return false;
  }

  const storagePath = `backgrounds/${filename}`;
  console.log(`📤 업로드 중: ${filename}  (${label})`);

  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType: filename.endsWith('.png') ? 'image/png' : 'image/jpeg',
      cacheControl: 'public, max-age=31536000',  // 1년 캐시
    },
  });

  const file = bucket.file(storagePath);
  await file.makePublic();
  const storageUrl =
    `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${storagePath}`;

  // Firestore background_images/{bgId} 문서 저장
  // mode 필드 = zone rawValue (BackgroundImage 모델 CodingKey와 일치)
  await db.collection('background_images').doc(bgId).set({
    bg_id: bgId,
    mode: zoneId,      // 8 Zone rawValue — BackgroundImage.mode 필드로 디코딩됨
    filename,
    storage_url: storageUrl,
    source: 'Custom',
    license: 'Commercial',
    status: 'active',
  });

  console.log(`✅ ${bgId} → ${storageUrl}`);
  return true;
}

async function main() {
  // 폴더 없으면 자동 생성 후 안내
  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
    console.log(`\n📁 폴더 생성: ${IMAGES_DIR}/`);
    console.log('\n아래 파일명으로 이미지를 넣고 다시 실행하세요:\n');
    BACKGROUND_ZONES.forEach(z =>
      console.log(`  bg_${z.zone}.jpg   ← ${z.label}`)
    );
    process.exit(0);
  }

  console.log('\n🌅 DailyVerse 배경 이미지 업로드 (8 Zone)\n');

  // 현재 폴더에 있는 파일 목록 출력
  const files = fs.readdirSync(IMAGES_DIR).filter(f => /\.(jpg|jpeg|png)$/i.test(f));
  console.log(`📂 발견된 파일 (${files.length}개): ${files.join(', ') || '없음'}\n`);

  const { db, bucket } = initFirebase();

  let success = 0;
  let skipped = 0;
  for (const zone of BACKGROUND_ZONES) {
    const ok = await uploadBackground(bucket, db, zone);
    if (ok) success++; else skipped++;
  }

  console.log(`\n✨ 완료! 성공: ${success}개 / 건너뜀: ${skipped}개`);
  console.log(`🔗 Firebase Storage: https://console.firebase.google.com/project/${PROJECT_ID}/storage`);
  console.log(`🔗 Firestore:        https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
  process.exit(0);
}

main().catch(err => {
  console.error('❌ 오류:', err.message);
  process.exit(1);
});
