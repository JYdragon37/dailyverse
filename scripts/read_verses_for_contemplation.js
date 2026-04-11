/**
 * read_verses_for_contemplation.js
 * verses 컬렉션에서 contemploation_ko가 비어있는 말씀들을 읽어서 JSON으로 출력
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const fs = require('fs');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function main() {
  const snapshot = await db.collection('verses').orderBy('__name__').get();
  const result = [];

  snapshot.forEach(doc => {
    const d = doc.data();
    // contemplation_ko가 null이거나 없는 것만
    if (!d.contemplation_ko) {
      result.push({
        id: doc.id,
        reference: d.reference,
        verse_short_ko: d.verse_short_ko,
        verse_full_ko: d.verse_full_ko,
        mode: d.mode,
        theme: d.theme,
        interpretation: d.interpretation,
      });
    }
  });

  fs.writeFileSync('./verses_need_contemplation.json', JSON.stringify(result, null, 2));
  console.log(`✅ ${result.length}개 말씀을 verses_need_contemplation.json 에 저장`);
  process.exit(0);
}
main();
