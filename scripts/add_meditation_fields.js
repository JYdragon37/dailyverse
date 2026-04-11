/**
 * add_meditation_fields.js
 *
 * verses 컬렉션에 묵상 4개 필드를 추가합니다.
 *
 * 추가 필드:
 *   contemplation_ko          — 묵상 읽기 구절 (50-200자, Screen 2 읽기 섹션)
 *   contemplation_interpretation — 묵상 전용 해석 (Screen 2 해석 섹션)
 *   contemplation_appliance   — 묵상 일상 적용 (Screen 3 섹션 1)
 *   question                  — 묵상 질문 (Screen 3 섹션 2)
 *
 * 사용법:
 *   node add_meditation_fields.js
 *
 * 주의:
 *   - 이미 해당 필드가 있는 문서는 건드리지 않습니다.
 *   - 빈 필드만 기본값(null)으로 초기화합니다.
 *   - 커스텀 내용은 Firestore Console 또는 별도 스크립트로 채워주세요.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const db = admin.firestore();

const FIELDS = [
  'contemplation_ko',
  'contemplation_interpretation',
  'contemplation_appliance',
  'question',
];

const BATCH_SIZE = 400; // Firestore 배치 최대 500, 여유 두고 400

async function main() {
  console.log('verses 컬렉션 읽는 중...');
  const snapshot = await db.collection('verses').orderBy('__name__').get();
  const docs = snapshot.docs;
  console.log(`총 ${docs.length}개 말씀 발견\n`);

  let alreadyHas = 0;
  let updated = 0;
  let batches = [];
  let currentBatch = db.batch();
  let currentBatchCount = 0;

  for (const doc of docs) {
    const data = doc.data();
    const updates = {};

    for (const field of FIELDS) {
      if (data[field] === undefined || data[field] === null) {
        updates[field] = null; // 빈 슬롯으로 초기화
      }
    }

    const missingCount = Object.keys(updates).length;
    if (missingCount === 0) {
      alreadyHas++;
      continue;
    }

    currentBatch.update(doc.ref, updates);
    currentBatchCount++;
    updated++;

    if (currentBatchCount >= BATCH_SIZE) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      currentBatchCount = 0;
    }
  }

  if (currentBatchCount > 0) {
    batches.push(currentBatch);
  }

  console.log(`커밋 중... (배치 ${batches.length}개)`);
  for (let i = 0; i < batches.length; i++) {
    await batches[i].commit();
    console.log(`  배치 ${i + 1}/${batches.length} 완료`);
  }

  console.log('\n===== 완료 =====');
  console.log(`전체:           ${docs.length}개`);
  console.log(`이미 있음:      ${alreadyHas}개`);
  console.log(`초기화(null):   ${updated}개`);
  console.log('\n다음 단계: generate_meditation_content.js 로 AI 콘텐츠 생성');

  process.exit(0);
}

main().catch(e => {
  console.error('오류:', e);
  process.exit(1);
});
