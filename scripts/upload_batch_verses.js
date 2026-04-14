/**
 * batch_1/2/3_verses.json → Firestore 업로드 스크립트
 * 수정된 verse_short_ko, verse_full_ko를 Firestore에 PATCH 반영
 * 실행: node upload_batch_verses.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(KEY_FILE)) });
}
const db = admin.firestore();

// batch JSON 파일 읽기 및 병합
function loadBatchVerses() {
  const batchFiles = [
    path.join(__dirname, 'data', 'batch_1_verses.json'),
    path.join(__dirname, 'data', 'batch_2_verses.json'),
    path.join(__dirname, 'data', 'batch_3_verses.json')
  ];

  const allVerses = [];
  for (const filePath of batchFiles) {
    const raw = fs.readFileSync(filePath, 'utf8');
    const verses = JSON.parse(raw);
    allVerses.push(...verses);
    console.log(`📂 ${path.basename(filePath)}: ${verses.length}개 로드`);
  }
  return allVerses;
}

async function main() {
  console.log('\n📦 batch JSON 파일 로드 중...');
  const verses = loadBatchVerses();
  console.log(`\n총 ${verses.length}개 verse → Firestore PATCH 시작...\n`);

  let success = 0;
  let failed = 0;

  for (const verse of verses) {
    const verseId = verse.id; // batch JSON의 id 필드가 Firestore 문서 ID
    if (!verseId) {
      console.error(`⚠️  id 필드 없음, 건너뜀: ${JSON.stringify(verse).substring(0, 60)}`);
      continue;
    }

    const fields = {};
    if (verse.verse_short_ko !== undefined && verse.verse_short_ko !== null) {
      fields.verse_short_ko = verse.verse_short_ko;
    }
    if (verse.verse_full_ko !== undefined && verse.verse_full_ko !== null) {
      fields.verse_full_ko = verse.verse_full_ko;
    }

    if (Object.keys(fields).length === 0) {
      console.warn(`⚠️  ${verseId}: verse_short_ko, verse_full_ko 모두 없음, 건너뜀`);
      continue;
    }

    try {
      // merge: true로 PATCH (다른 필드 덮어쓰기 금지)
      await db.collection('verses').doc(verseId).set(fields, { merge: true });
      const shortPreview = (fields.verse_short_ko || '').substring(0, 20);
      console.log(`✅ ${verseId}: "${shortPreview}..."`);
      success++;
    } catch (err) {
      console.error(`❌ ${verseId} 실패: ${err.message.substring(0, 150)}`);
      failed++;
    }
  }

  console.log(`\n✨ 완료! 성공: ${success}개, 실패: ${failed}개`);
  console.log(`\n🔗 Firestore 확인:`);
  console.log(`   https://console.firebase.google.com/project/dailyverse-9260d/firestore`);

  process.exit(0);
}

main().catch(err => {
  console.error('치명적 오류:', err.message);
  process.exit(1);
});
