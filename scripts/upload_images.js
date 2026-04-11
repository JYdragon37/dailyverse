/**
 * DailyVerse — 이미지 일괄 업로드 스크립트
 *
 * 사용법:
 *   1. Genspark에서 이미지 다운로드 → scripts/verse-images/ 폴더에 넣기
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
const IMAGES_DIR = './verse-images';  // 업로드할 이미지 폴더

// ─── 이미지 메타데이터 정의 ───────────────────────────────────────────────────
// 파일명 → Firestore 메타데이터 매핑
// 파일명만 추가하면 자동으로 Firebase Storage 업로드 + Firestore 등록

const IMAGE_METADATA = [
  {
    // 예루살렘 성벽 골목 — 황혼, 어두운 돌길
    filename: "Photorealistic_Jerusalem_Old_City_ancient_stone_wa-1775193696155.png",
    mode: ["evening", "dawn"],
    theme: ["wisdom", "reflection", "stillness"],
    mood: ["serene", "calm"],
    season: ["all"], weather: ["cloudy", "any"],
    tone: "dark", text_position: "bottom", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 시나이 광야 새벽 길 — 어두운 산, 구름
    filename: "Photorealistic_Mount_Sinai_desert_landscape_at_daw-1775193657399.png",
    mode: ["dawn", "evening"],
    theme: ["stillness", "faith", "surrender"],
    mood: ["serene", "calm"],
    season: ["all"], weather: ["any"],
    tone: "dark", text_position: "center", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 페트라 신전 — 밝은 사암, 웅장함
    filename: "Photorealistic_Petra_Jordan_Treasury_ancient_carve-1775193673692.png",
    mode: ["morning", "afternoon"],
    theme: ["wisdom", "courage", "strength"],
    mood: ["dramatic", "calm"],
    season: ["all"], weather: ["sunny", "any"],
    tone: "bright", text_position: "bottom", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 새벽 안개 낀 고요한 호수
    filename: "Natural_photographic_scene_of_peaceful_lake_at_daw-1775193910947.png",
    mode: ["morning", "dawn"],
    theme: ["stillness", "peace", "renewal"],
    mood: ["serene", "calm"],
    season: ["spring", "summer", "all"], weather: ["cloudy", "any"],
    tone: "mid", text_position: "center", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 해변 일몰 — 파스텔 하늘, 잔잔한 파도
    filename: "Authentic_camera_photograph_of_tranquil_coastal_sc-1775193922802.png",
    mode: ["evening", "morning"],
    theme: ["peace", "comfort", "hope"],
    mood: ["warm", "serene"],
    season: ["summer", "all"], weather: ["any"],
    tone: "mid", text_position: "bottom", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 밝은 해변 일몰 — 황금빛, 혼자 걷는 사람
    filename: "Professional_natural_photograph_of_serene_ocean_be-1775193895561.png",
    mode: ["morning", "afternoon"],
    theme: ["hope", "renewal", "gratitude"],
    mood: ["bright", "warm"],
    season: ["summer", "all"], weather: ["sunny", "any"],
    tone: "bright", text_position: "bottom", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 앙코르와트 새벽 — 물 반영, 안개, 일출
    filename: "Authentic_camera_photograph_of_Angkor_Wat_Cambodia-1775194139198.png",
    mode: ["morning", "dawn"],
    theme: ["hope", "faith", "renewal"],
    mood: ["serene", "dramatic"],
    season: ["all"], weather: ["any"],
    tone: "mid", text_position: "bottom", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 몽생미셸 석양 — 황금빛 하늘, 반사
    filename: "Natural_photographic_scene_of_Mont_Saint-Michel_Fr-1775194153665.png",
    mode: ["evening", "morning"],
    theme: ["peace", "wisdom", "reflection"],
    mood: ["warm", "serene"],
    season: ["all"], weather: ["any"],
    tone: "mid", text_position: "bottom", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  {
    // 산토리니 석양 — 흰 건물, 황금빛, 바다
    filename: "Professional_natural_photograph_of_Santorini_Greec-1775194128185.png",
    mode: ["evening", "afternoon"],
    theme: ["gratitude", "peace", "comfort"],
    mood: ["warm", "bright"],
    season: ["summer", "all"], weather: ["sunny", "any"],
    tone: "mid", text_position: "bottom", text_color: "light",
    is_sacred_safe: true, avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
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
    storageBucket: `${PROJECT_ID}.firebasestorage.app`,
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
  const storageUrl = `https://storage.googleapis.com/${PROJECT_ID}.firebasestorage.app/${storagePath}`;

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
