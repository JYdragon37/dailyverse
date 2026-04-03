/**
 * DailyVerse — 이미지 일괄 업로드 스크립트
 *
 * 사용법:
 *   1. Genspark에서 이미지 다운로드 → scripts/images_to_upload/ 폴더에 넣기
 *   2. 각 이미지 파일명을 메타데이터와 매핑 (아래 IMAGE_METADATA 수정)
 *   3. node upload_images.js 실행
 *
 * 필요 파일: serviceAccountKey.json (Firebase Console > 프로젝트 설정 > 서비스 계정 > 키 생성)
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ─── 설정 ─────────────────────────────────────────────────────────────────────

const PROJECT_ID = 'dailyverse-9260d';
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const IMAGES_DIR = './images_to_upload';  // 업로드할 이미지 폴더

// ─── 이미지 메타데이터 정의 ───────────────────────────────────────────────────
// 파일명 → Firestore 메타데이터 매핑
// 파일명만 추가하면 자동으로 Firebase Storage 업로드 + Firestore 등록

const IMAGE_METADATA = [
  // 예시: 실제 파일명으로 교체하세요
  {
    filename: "morning_hope_01.jpg",
    mode: ["morning"],
    theme: ["hope", "courage"],
    mood: ["bright", "dramatic"],
    season: ["all"],
    weather: ["any"],
    tone: "bright",
    text_position: "bottom",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    source: "Genspark Pro",
    license: "Commercial",
  },
  {
    filename: "evening_peace_01.jpg",
    mode: ["evening"],
    theme: ["peace", "comfort"],
    mood: ["serene", "calm"],
    season: ["all"],
    weather: ["any"],
    tone: "dark",
    text_position: "center",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    source: "Genspark Pro",
    license: "Commercial",
  },
  // 이 패턴으로 계속 추가...
  // {
  //   filename: "파일명.jpg",
  //   mode: ["morning", "afternoon"],  // morning/afternoon/evening/dawn/all
  //   theme: ["hope"],                 // 12가지 테마 중 선택
  //   mood: ["bright"],               // bright/calm/warm/serene/dramatic/cozy
  //   season: ["all"],                // spring/summer/autumn/winter/all
  //   weather: ["any"],               // sunny/cloudy/rainy/snowy/any
  //   tone: "bright",                 // bright/mid/dark
  //   text_position: "bottom",        // top/center/bottom
  //   text_color: "light",            // light/dark
  //   is_sacred_safe: true,
  //   source: "Genspark Pro",
  //   license: "Commercial",
  // },
];

// ─── TAG 가이드 ────────────────────────────────────────────────────────────────
// MODE:    morning(06-12) / afternoon(12-18) / evening(18-00) / dawn(00-06) / all
// THEME:   morning → hope/courage/strength/renewal
//          afternoon → wisdom/focus/patience/gratitude
//          evening → peace/comfort/reflection/rest
//          dawn → stillness/surrender/faith/grace
// MOOD:    bright / calm / warm / serene / dramatic / cozy
// TONE:    bright(아침) / mid(중립) / dark(저녁·새벽)
// TEXT_POSITION: top(상단30%) / center(중앙) / bottom(하단30%)
// IS_SACRED_SAFE: true = 홈 배경 사용 가능 (자연/하늘/산/바다 계열)
//                 false = Gallery만 표시, 홈 배경 불가 (인물/도시 등)

// ─── Firebase Admin 초기화 ────────────────────────────────────────────────────

function initFirebase() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`❌ ${SERVICE_ACCOUNT_PATH} 파일이 없습니다.`);
    console.error('   Firebase Console > 프로젝트 설정 > 서비스 계정 > 새 비공개 키 생성');
    process.exit(1);
  }

  const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: `${PROJECT_ID}.appspot.com`,
  });
  return {
    db: admin.firestore(),
    bucket: admin.storage().bucket(),
  };
}

// ─── 이미지 업로드 ────────────────────────────────────────────────────────────

async function uploadImage(bucket, db, metadata, index) {
  const { filename, ...firestoreFields } = metadata;
  const localPath = path.join(IMAGES_DIR, filename);

  if (!fs.existsSync(localPath)) {
    console.warn(`⚠️  파일 없음, 건너뜀: ${filename}`);
    return null;
  }

  // Storage 경로: images/파일명
  const storagePath = `images/${filename}`;
  const imageId = `img_${String(index + 1).padStart(3, '0')}`;

  console.log(`📤 업로드 중: ${filename} → ${storagePath}`);

  // Firebase Storage 업로드
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType: filename.endsWith('.png') ? 'image/png' : 'image/jpeg',
      cacheControl: 'public, max-age=31536000',  // 1년 캐시
    },
  });

  // 공개 다운로드 URL 생성
  const file = bucket.file(storagePath);
  await file.makePublic();
  const storageUrl = `https://storage.googleapis.com/${PROJECT_ID}.appspot.com/${storagePath}`;

  // Firestore 등록
  const docData = {
    image_id: imageId,
    filename,
    storage_url: storageUrl,
    ...firestoreFields,
    status: 'active',
  };

  await db.collection('images').doc(imageId).set(docData, { merge: true });

  console.log(`✅ 완료: ${imageId} | ${storageUrl}`);
  return { imageId, storageUrl };
}

// ─── 메인 ─────────────────────────────────────────────────────────────────────

async function main() {
  // 폴더 확인
  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
    console.log(`📁 폴더 생성: ${IMAGES_DIR}`);
    console.log('   이미지 파일을 이 폴더에 넣고 IMAGE_METADATA를 업데이트한 후 다시 실행하세요.');
    process.exit(0);
  }

  const files = fs.readdirSync(IMAGES_DIR).filter(f => /\.(jpg|jpeg|png)$/i.test(f));
  if (files.length === 0) {
    console.log(`📁 ${IMAGES_DIR}/ 폴더가 비어있습니다. 이미지를 넣어주세요.`);
    process.exit(0);
  }

  console.log(`\n🚀 DailyVerse 이미지 업로드 시작 (${IMAGE_METADATA.length}개)\n`);
  console.log(`📁 이미지 폴더: ${IMAGES_DIR}/`);
  console.log(`📂 발견된 파일: ${files.join(', ')}\n`);

  const { db, bucket } = initFirebase();

  let success = 0, failed = 0;
  for (let i = 0; i < IMAGE_METADATA.length; i++) {
    try {
      const result = await uploadImage(bucket, db, IMAGE_METADATA[i], i);
      if (result) success++;
      else failed++;
    } catch (err) {
      console.error(`❌ 실패: ${IMAGE_METADATA[i].filename} — ${err.message}`);
      failed++;
    }
  }

  console.log(`\n✨ 완료! 성공: ${success}개, 실패: ${failed}개`);
  console.log(`🔗 Firebase Console: https://console.firebase.google.com/project/${PROJECT_ID}/storage`);
  console.log(`🔗 Firestore: https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
  process.exit(0);
}

main().catch(err => {
  console.error('❌ 오류:', err.message);
  process.exit(1);
});
