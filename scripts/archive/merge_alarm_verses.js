/**
 * merge_alarm_verses.js
 * alarm_verses(av_*) → verses(v_*) 통합
 * 1. 중복(same reference) 제외
 * 2. 79개 신규를 v_102~v_180으로 추가
 * 3. alarm_context → mode 매핑
 */
const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const isDryRun = process.argv.includes('--dry-run');

// alarm_context → mode 매핑
function mapMode(alarmContext) {
  const ctx = Array.isArray(alarmContext) ? alarmContext[0] : alarmContext;
  switch (ctx) {
    case 'morning': return ['first_light', 'rise_ignite'];
    case 'evening': return ['golden_hour', 'wind_down'];
    default:        return ['all'];
  }
}

async function main() {
  console.log('=== alarm_verses → verses 통합 ===');
  console.log('dry-run:', isDryRun, '\n');

  // 1) verses 기존 reference 수집 + 마지막 ID 번호 파악
  const vSnap = await db.collection('verses').orderBy('__name__').get();
  const verseRefs = new Set();
  let maxNum = 0;
  vSnap.forEach(d => {
    verseRefs.add((d.data().reference || '').trim());
    const n = parseInt(d.id.replace('v_', ''));
    if (!isNaN(n) && n > maxNum) maxNum = n;
  });
  console.log('현재 verses 수:', vSnap.size, '/ 최대 ID 번호:', maxNum);

  // 2) alarm_verses에서 신규(중복 없는) 것만 추출
  const avSnap = await db.collection('alarm_verses').get();
  const newDocs = [];
  const duplicates = [];
  avSnap.forEach(d => {
    const data = d.data();
    const ref = (data.reference || '').trim();
    if (verseRefs.has(ref)) duplicates.push({ id: d.id, ref });
    else newDocs.push({ id: d.id, data });
  });
  console.log('alarm_verses 전체:', avSnap.size, '/ 중복(스킵):', duplicates.length, '/ 신규 추가:', newDocs.length, '\n');

  if (newDocs.length === 0) { console.log('추가할 문서 없음.'); return; }

  // 3) 새 문서 구성
  let nextNum = maxNum + 1;
  const toUpload = newDocs.map(({ id: avId, data }) => {
    const newId = `v_${String(nextNum).padStart(3, '0')}`;
    nextNum++;

    return {
      newId,
      originalId: avId,
      payload: {
        verse_id:       newId,
        verse_short_ko: data.verse_short_ko || data.text_ko || '',
        verse_full_ko:  data.verse_full_ko  || data.text_full_ko || '',
        reference:      data.reference || '',
        book:           data.book || '',
        chapter:        data.chapter || 0,
        verse:          data.verse || 0,
        mode:           mapMode(data.alarm_context),
        theme:          data.theme || [],
        mood:           data.mood  || [],
        season:         ['all'],
        weather:        ['any'],
        interpretation: data.interpretation || '',
        application:    data.application    || '',
        curated:        data.curated  ?? false,
        status:         data.status   || 'active',
        notes:          (data.notes ? data.notes + ' ' : '') + '[merged from ' + avId + ']',
        usage_count:    0,
        cooldown_days:  7,
        show_count:     0,
        last_shown:     null,
        // 비워둠 → 이후 generate 스크립트로 채움
        alarm_top_ko:                null,
        contemplation_ko:            null,
        contemplation_reference:     null,
        contemplation_interpretation:null,
        contemplation_appliance:     null,
        question:                    null,
      }
    };
  });

  // 미리보기
  console.log('샘플 (3개):');
  toUpload.slice(0, 3).forEach(d => {
    console.log(' ', d.newId, '←', d.originalId, '|', d.payload.reference);
    console.log('   mode:', JSON.stringify(d.payload.mode));
    console.log('   verse_short_ko:', d.payload.verse_short_ko.slice(0, 40));
  });

  if (isDryRun) { console.log('\n[dry-run] 실제 업로드 없음.'); return; }

  // 4) Firestore 배치 업로드 (500개 단위)
  const BATCH_SIZE = 400;
  for (let i = 0; i < toUpload.length; i += BATCH_SIZE) {
    const batch = db.batch();
    toUpload.slice(i, i + BATCH_SIZE).forEach(({ newId, payload }) => {
      batch.set(db.collection('verses').doc(newId), payload);
    });
    await batch.commit();
    console.log('업로드:', Math.min(i + BATCH_SIZE, toUpload.length), '/' , toUpload.length);
  }

  console.log('\n✅ 통합 완료:', toUpload.length, '개 추가');
  console.log('새 ID 범위: v_' + String(maxNum+1).padStart(3,'0'), '~', 'v_' + String(nextNum-1).padStart(3,'0'));
}

main().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
