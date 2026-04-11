const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function main() {
  const snapshot = await db.collection('alarm_verses').get();
  const verses = [];
  snapshot.forEach(doc => {
    verses.push({ id: doc.id, ...doc.data() });
  });

  console.log('총 알람 말씀 수:', verses.length);

  let issues = 0;
  verses.forEach(v => {
    const interp = v.interpretation || '';
    if (interp.includes('히브리어') || interp.includes('헬라어')) {
      console.log(`\n[${v.id}] ${v.reference}`);
      console.log('해석:', interp.substring(0, 200));
      console.log('적용:', (v.application || '').substring(0, 100));
      issues++;
    }
  });
  console.log('\n문제 있는 알람 말씀:', issues);
  process.exit(0);
}
main().catch(e => { console.error(e); process.exit(1); });
