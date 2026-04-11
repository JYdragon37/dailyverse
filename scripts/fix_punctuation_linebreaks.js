// 마침표, 줄바꿈, 쉼표 기계적 수정 스크립트
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// text_ko: 마침표 없으면 추가
function fixTextKo(text) {
  if (!text) return text;
  const t = text.trim();
  if (/[.!?。]$/.test(t)) return t;
  return t + '.';
}

// text_full_ko: 긴 구절에 줄바꿈 추가
// 한국어 절 구분 패턴: 니라., 이라., 도다., 이다., 하며,, 이며,, 이요, 하여 등
function fixTextFullKo(text) {
  if (!text || text.includes('\n')) return text;
  const t = text.trim();
  if (t.replace(/\n/g,'').length <= 40) return t;

  // 절 구분점 찾기: "니라 " "이라 " "도다 " "이다 " "이요 " 뒤에 \n 삽입
  let result = t
    .replace(/(니라[.。])\s+/g, '$1\n')
    .replace(/(이라[.。])\s+/g, '$1\n')
    .replace(/(도다[.。])\s+/g, '$1\n')
    .replace(/(이다[.。])\s+/g, '$1\n')
    .replace(/(이요[.,])\s+/g, '$1\n')
    .replace(/(하며[,.])\s+/g, '$1\n')
    .replace(/(이며[,.])\s+/g, '$1\n');

  // 줄바꿈이 생겼으면 반환, 없으면 중간에 강제 삽입
  if (result.includes('\n')) return result;

  // 중간점 찾아서 삽입
  const mid = Math.floor(t.length / 2);
  const spaceNear = t.indexOf(' ', mid);
  if (spaceNear > 0) {
    return t.slice(0, spaceNear) + '\n' + t.slice(spaceNear + 1);
  }
  return t;
}

// interpretation/application: \n 없으면 문장 뒤에 추가
function addLineBreaks(text) {
  if (!text || text.includes('\n')) return text;
  const t = text.trim();
  // 문장 끝 패턴: 야. 거야. 거든. 해. 봐. 이야. 등 뒤에 \n
  return t.replace(/([야봐어해거든이요]\.)\s+/g, '$1\n')
           .replace(/([다]\.)\s+/g, '$1\n');
}

async function fixCollection(colName) {
  const snap = await db.collection(colName).get();
  let updated = 0, errors = 0;
  const batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const updates = {};
    let needsUpdate = false;

    // text_ko 마침표
    const newTk = fixTextKo(d.text_ko);
    if (newTk && newTk !== d.text_ko) { updates.text_ko = newTk; needsUpdate = true; }

    // text_full_ko 줄바꿈
    const newTf = fixTextFullKo(d.text_full_ko);
    if (newTf && newTf !== d.text_full_ko) { updates.text_full_ko = newTf; needsUpdate = true; }

    // interpretation 줄바꿈
    const newInterp = addLineBreaks(d.interpretation);
    if (newInterp && newInterp !== d.interpretation) { updates.interpretation = newInterp; needsUpdate = true; }

    // application 줄바꿈
    const newApp = addLineBreaks(d.application);
    if (newApp && newApp !== d.application) { updates.application = newApp; needsUpdate = true; }

    if (needsUpdate) {
      batch.update(doc.ref, updates);
      batchCount++;
      updated++;

      // Firestore batch limit: 500
      if (batchCount >= 400) {
        await batch.commit();
        batchCount = 0;
      }
    }
  }

  if (batchCount > 0) await batch.commit();
  console.log(`[${colName}] 수정: ${updated}개`);
  return updated;
}

async function main() {
  console.log('=== 마침표·줄바꿈 수정 시작 ===');
  const v = await fixCollection('verses');
  const av = await fixCollection('alarm_verses');

  // 검증
  console.log('\n=== 검증 ===');
  for (const col of ['verses', 'alarm_verses']) {
    const snap = await db.collection(col).get();
    let noEndPunct = 0, noLbFull = 0, noLbInterp = 0, noLbApp = 0;
    snap.forEach(doc => {
      const d = doc.data();
      if (d.text_ko && !/[.!?。]$/.test(d.text_ko.trim())) noEndPunct++;
      if (d.text_full_ko && d.text_full_ko.replace(/\n/g,'').length > 40 && !d.text_full_ko.includes('\n')) noLbFull++;
      if (d.interpretation && d.interpretation.replace(/\n/g,'').length > 100 && !d.interpretation.includes('\n')) noLbInterp++;
      if (d.application && d.application.replace(/\n/g,'').length > 50 && !d.application.includes('\n')) noLbApp++;
    });
    console.log(`[${col}] text_ko 마침표 없음: ${noEndPunct} | text_full_ko 줄바꿈 없음: ${noLbFull} | 해석 줄바꿈 없음: ${noLbInterp} | 적용 줄바꿈 없음: ${noLbApp}`);
  }

  console.log('\n완료');
  process.exit(0);
}

main().catch(e => { console.error(e.message); process.exit(1); });
