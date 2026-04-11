const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function main() {
  const snapshot = await db.collection('verses').get();
  const verses = [];
  snapshot.forEach(doc => {
    verses.push({ id: doc.id, ...doc.data() });
  });

  // interpretation에서 패턴 분석
  let withHebrew = 0;
  let withGreek = 0;
  const problemVerses = [];

  verses.forEach(v => {
    const interp = v.interpretation || '';
    const hasHebrew = interp.includes('히브리어') || interp.includes('히브리');
    const hasGreek = interp.includes('헬라어') || interp.includes('그리스어');
    if (hasHebrew) withHebrew++;
    if (hasGreek) withGreek++;
    if (hasHebrew || hasGreek) problemVerses.push(v);
  });

  console.log('총 말씀 수:', verses.length);
  console.log('히브리어 포함:', withHebrew);
  console.log('헬라어 포함:', withGreek);
  console.log('');

  // 전체 verse 목록 출력 (id, reference, interpretation 전체)
  console.log('===== 전체 말씀 목록 =====');
  verses.sort((a, b) => a.id.localeCompare(b.id));
  verses.forEach(v => {
    const interp = v.interpretation || '';
    const app = v.application || '';
    const hasHebrew = interp.includes('히브리어') || interp.includes('히브리');
    const hasGreek = interp.includes('헬라어') || interp.includes('그리스어');
    const flag = (hasHebrew || hasGreek) ? ' ⚠️ 원어 포함' : '';
    console.log(`\n[${v.id}] ${v.reference}${flag}`);
    console.log('interpretation:', interp);
    console.log('application:', app);
  });

  console.log('\n\n===== 문제 있는 말씀 (원어 포함) =====');
  problemVerses.forEach(v => {
    const interp = v.interpretation || '';
    const app = v.application || '';
    console.log(`\n[${v.id}] ${v.reference}`);
    console.log('interpretation:', interp);
    console.log('application:', app);
  });

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
