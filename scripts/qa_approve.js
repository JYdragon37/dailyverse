require('dotenv').config();
/**
 * qa_approve.js — 최종 승인 (ai_passed → approved, curated=TRUE)
 *
 * 사용법:
 *   node qa_approve.js                   # ai_passed 전체 승인
 *   node qa_approve.js --ids v_001,v_002 # 특정 ID만
 *   node qa_approve.js --dry-run
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');

const targetIds = (() => {
  const idx = args.indexOf('--ids');
  if (idx === -1) return null;
  return args[idx + 1].split(',').map(s => s.trim());
})();

async function main() {
  console.log(`=== qa_approve.js | dry-run: ${isDryRun} ===\n`);

  let docs = [];

  if (targetIds) {
    const snaps = await Promise.all(targetIds.map(id => db.collection('verses').doc(id).get()));
    docs = snaps.filter(s => s.exists).map(s => ({ id: s.id, ref: s.ref, data: s.data() }));
  } else {
    const snap = await db.collection('verses').where('qa_status', '==', 'ai_passed').get();
    snap.forEach(doc => docs.push({ id: doc.id, ref: doc.ref, data: doc.data() }));
  }

  if (docs.length === 0) {
    console.log('승인 대상 없음. (ai_passed 상태인 콘텐츠가 없습니다)');
    return;
  }

  console.log(`승인 대상: ${docs.length}개\n`);

  if (!isDryRun) {
    const BATCH_SIZE = 400;
    for (let i = 0; i < docs.length; i += BATCH_SIZE) {
      const batch = db.batch();
      docs.slice(i, i + BATCH_SIZE).forEach(({ ref }) => {
        batch.update(ref, {
          qa_status:   'approved',
          qa_issues:   [],
          curated:     true,
          qa_checked_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();
    }
    console.log(`✅ ${docs.length}개 승인 완료 (qa_status: approved, curated: true)`);
  } else {
    docs.forEach(d => console.log(`  [dry-run] ${d.id} (${d.data.reference}) → approved`));
    console.log(`\n[dry-run: DB 변경 없음]`);
  }
}

main().catch(console.error).finally(() => process.exit());
