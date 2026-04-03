/**
 * DailyVerse — 홈 배경 이미지 업로드 스크립트
 *
 * 사용법:
 *   1. background_images_to_upload/ 폴더에 4장 이미지 넣기
 *      파일명 규칙: bg_morning.jpg / bg_afternoon.jpg / bg_evening.jpg / bg_dawn.jpg
 *   2. node upload_backgrounds.js 실행
 *
 * 필요: scripts/serviceAccountKey.json
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'dailyverse-9260d';
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const IMAGES_DIR = './background_images_to_upload';

// 4개 모드 고정 설정
const BACKGROUND_MODES = [
  { bgId: 'bg_morning',   mode: 'morning',   label: '아침 (06-12시)' },
  { bgId: 'bg_afternoon', mode: 'afternoon', label: '낮 (12-18시)' },
  { bgId: 'bg_evening',   mode: 'evening',   label: '저녁 (18-00시)' },
  { bgId: 'bg_dawn',      mode: 'dawn',      label: '새벽 (00-06시)' },
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

async function uploadBackground(bucket, db, bgMode) {
  const { bgId, mode, label } = bgMode;

  // jpg / png 확장자 모두 지원
  const extensions = ['.jpg', '.jpeg', '.png'];
  let localPath = null;
  let filename = null;

  for (const ext of extensions) {
    const candidate = path.join(IMAGES_DIR, `bg_${mode}${ext}`);
    if (fs.existsSync(candidate)) {
      localPath = candidate;
      filename = `bg_${mode}${ext}`;
      break;
    }
  }

  if (!localPath) {
    console.warn(`⚠️  ${label} 이미지 없음 (bg_${mode}.jpg/.png) — 건너뜀`);
    return false;
  }

  const storagePath = `backgrounds/${filename}`;
  console.log(`📤 업로드 중: ${filename} (${label})`);

  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType: filename.endsWith('.png') ? 'image/png' : 'image/jpeg',
      cacheControl: 'public, max-age=31536000',
    },
  });

  const file = bucket.file(storagePath);
  await file.makePublic();
  const storageUrl = `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${storagePath}`;

  await db.collection('background_images').doc(bgId).set({
    bg_id: bgId,
    mode,
    filename,
    storage_url: storageUrl,
    source: 'Custom',
    license: 'Commercial',
    status: 'active',
  });

  console.log(`✅ ${bgId} | ${storageUrl}`);
  return true;
}

async function main() {
  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
    console.log(`📁 폴더 생성: ${IMAGES_DIR}`);
    console.log('   bg_morning.jpg / bg_afternoon.jpg / bg_evening.jpg / bg_dawn.jpg 을 넣고 다시 실행하세요');
    process.exit(0);
  }

  console.log('\n🌅 DailyVerse 배경 이미지 업로드\n');
  const { db, bucket } = initFirebase();

  let success = 0;
  for (const bgMode of BACKGROUND_MODES) {
    const ok = await uploadBackground(bucket, db, bgMode);
    if (ok) success++;
  }

  console.log(`\n✨ 완료! ${success}/4개 업로드`);
  console.log(`🔗 https://console.firebase.google.com/project/${PROJECT_ID}/storage`);
  process.exit(0);
}

main().catch(err => { console.error('❌', err.message); process.exit(1); });
