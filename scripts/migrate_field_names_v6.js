/**
 * migrate_field_names_v6.js
 *
 * v6.0 필드명 마이그레이션 스크립트
 *
 * 변경 내역:
 *   verses        : text_ko → verse_short_ko
 *                   text_full_ko → verse_full_ko
 *                   alarm_text_ko → alarm_top_ko
 *                   + contemplation_ko (null), contemplation_reference (null) 신규 추가
 *   alarm_verses  : text_ko → verse_short_ko
 *                   text_full_ko → verse_full_ko
 *   saved_verses  : verse_text_short → verse_full_ko
 *                   (saved_verses/{uid}/verses/{saved_id} 구조)
 *
 * 실행 방법:
 *   1. DRY RUN (실제 변경 없이 미리보기):
 *      node migrate_field_names_v6.js --dry-run
 *
 *   2. 실제 마이그레이션:
 *      node migrate_field_names_v6.js
 *
 *   3. 특정 컬렉션만:
 *      node migrate_field_names_v6.js --collection verses
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ─── CLI 옵션 파싱 ────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const DRY_RUN = args.includes('--dry-run');
const collectionFlag = args.find(a => a.startsWith('--collection='));
const collectionIdx = args.indexOf('--collection');
const TARGET_COLLECTION = collectionFlag
  ? collectionFlag.split('=')[1]
  : (collectionIdx !== -1 ? args[collectionIdx + 1] : null);

if (DRY_RUN) {
  console.log('🔍 DRY RUN 모드 — Firestore 변경 없음\n');
} else {
  console.log('⚠️  실제 마이그레이션 모드 — Firestore 데이터가 변경됩니다\n');
}

// ─── 통계 ────────────────────────────────────────────────────────────────────
const stats = { updated: 0, skipped: 0, errors: 0 };

// ─── 헬퍼: 단일 컬렉션 마이그레이션 ───────────────────────────────────────────
async function migrateCollection(collectionRef, label, renameMap, addFields = {}) {
  const snapshot = await collectionRef.get();
  console.log(`\n[${label}] ${snapshot.size}개 문서 처리 중...`);

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const update = {};
    let needsUpdate = false;

    // 1. 기존 필드 rename
    for (const [oldKey, newKey] of Object.entries(renameMap)) {
      if (Object.prototype.hasOwnProperty.call(data, oldKey)) {
        update[newKey] = data[oldKey];      // 새 키에 기존 값 복사
        update[oldKey] = FieldValue.delete(); // 기존 키 삭제
        needsUpdate = true;
        console.log(`  ${doc.id}: ${oldKey} → ${newKey} = "${String(data[oldKey]).slice(0, 30)}..."`);
      }
    }

    // 2. 신규 필드 추가 (아직 없는 경우만)
    for (const [key, val] of Object.entries(addFields)) {
      if (!Object.prototype.hasOwnProperty.call(data, key)) {
        update[key] = val;
        needsUpdate = true;
      }
    }

    if (!needsUpdate) {
      stats.skipped++;
      continue;
    }

    if (DRY_RUN) {
      stats.updated++;
      continue;
    }

    try {
      await doc.ref.update(update);
      stats.updated++;
    } catch (e) {
      console.error(`  ❌ ${doc.id}: ${e.message}`);
      stats.errors++;
    }
  }
}

// ─── 헬퍼: saved_verses 서브컬렉션 (모든 유저) ───────────────────────────────
async function migrateSavedVerses() {
  console.log('\n[saved_verses] 유저별 서브컬렉션 처리 중...');

  // 모든 유저 문서 목록
  const usersSnapshot = await db.collection('saved_verses').get();
  console.log(`  유저 수: ${usersSnapshot.size}명`);

  for (const userDoc of usersSnapshot.docs) {
    const versesRef = db.collection('saved_verses').doc(userDoc.id).collection('verses');
    await migrateCollection(
      versesRef,
      `saved_verses/${userDoc.id}/verses`,
      { verse_text_short: 'verse_full_ko' },  // rename
      {}                                        // 신규 필드 없음
    );
  }
}

// ─── 메인 ────────────────────────────────────────────────────────────────────
async function main() {
  const startTime = Date.now();

  try {
    const shouldRun = (name) => !TARGET_COLLECTION || TARGET_COLLECTION === name;

    // 1. verses 컬렉션
    if (shouldRun('verses')) {
      await migrateCollection(
        db.collection('verses'),
        'verses',
        {
          text_ko:      'verse_short_ko',   // textKo → verseShortKo
          text_full_ko: 'verse_full_ko',    // textFullKo → verseFullKo
          alarm_text_ko: 'alarm_top_ko',    // alarmTextKo → alarmTopKo
        },
        {
          contemplation_ko:        null,    // 신규 필드 (빈값)
          contemplation_reference: null,    // 신규 필드 (빈값)
        }
      );
    }

    // 2. alarm_verses 컬렉션
    if (shouldRun('alarm_verses')) {
      await migrateCollection(
        db.collection('alarm_verses'),
        'alarm_verses',
        {
          text_ko:      'verse_short_ko',
          text_full_ko: 'verse_full_ko',
        }
      );
    }

    // 3. saved_verses 서브컬렉션
    if (shouldRun('saved_verses')) {
      await migrateSavedVerses();
    }

  } catch (e) {
    console.error('\n🚨 마이그레이션 중 오류:', e.message);
    process.exit(1);
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 완료 (${elapsed}초)
   업데이트: ${stats.updated}개
   스킵:     ${stats.skipped}개 (이미 마이그레이션됨)
   오류:     ${stats.errors}개
${DRY_RUN ? '\n🔍 DRY RUN — 실제 변경 없음. 실행하려면 --dry-run 제거' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);

  process.exit(0);
}

main();
