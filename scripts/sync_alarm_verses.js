/**
 * DailyVerse — ALARM_VERSES 시트 → Firestore alarm_verses 컬렉션 동기화
 *
 * 알람탭 상단 헤더에 표시될 말씀 전용 컬렉션.
 * 테마: 계획, 준비, 기대, 기다림, 희망, 소망, 새날, 변화 등 알람 설정 맥락에 어울리는 구절.
 *
 * 동작 방식:
 *   1. 구글 시트 ALARM_VERSES 탭 읽기
 *   2. Firestore alarm_verses 컬렉션의 기존 문서 중 시트에 없는 것 삭제
 *   3. 시트의 모든 행을 Firestore에 upsert
 *
 * 사용법:
 *   node sync_alarm_verses.js
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

// ─── 설정 ──────────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID    = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME  = 'ALARM_VERSES';
const COLLECTION  = 'alarm_verses';
const ID_FIELD    = 'verse_id';

// ALARM_VERSES 전용 타입 매핑
const ARRAY_FIELDS    = ['theme', 'mood', 'alarm_context'];
const INT_FIELDS      = ['chapter', 'verse', 'usage_count', 'cooldown_days', 'show_count'];
const BOOL_FIELDS     = ['curated'];
const NULLABLE_FIELDS = ['last_shown', 'notes'];

// ─── 초기화 ────────────────────────────────────────────────────────────────

const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ─── Google Sheets 읽기 ────────────────────────────────────────────────────

async function getSheetData() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
  });
  const sheets = google.sheets({ version: 'v4', auth });
  const response = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:Z`,
  });
  return response.data.values || [];
}

// ─── 값 변환 ───────────────────────────────────────────────────────────────

function convertValue(key, raw) {
  const str = String(raw ?? '').trim();

  if (NULLABLE_FIELDS.includes(key) && str === '') return null;

  if (ARRAY_FIELDS.includes(key)) {
    const items = str.split(',').map(s => s.trim()).filter(Boolean);
    return items.length ? items : ['all'];
  }
  if (INT_FIELDS.includes(key)) {
    const n = parseInt(str, 10);
    return isNaN(n) ? 0 : n;
  }
  if (BOOL_FIELDS.includes(key)) {
    return ['true', '1', 'yes'].includes(str.toLowerCase());
  }
  return str;
}

// ─── 메인 ──────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n📊 Google Sheets ALARM_VERSES 탭 읽는 중...');
  const rows = await getSheetData();

  if (rows.length < 2) {
    console.error('❌ 데이터가 없습니다. (헤더 포함 최소 2행 필요)');
    console.error('   구글 시트에 ALARM_VERSES 탭이 있는지 확인하세요.');
    process.exit(1);
  }

  const headers  = rows[0].map(h => {
    const s = String(h).trim();
    const p = s.indexOf('(');
    return p > 0 ? s.substring(0, p).trim() : s;
  });
  const idIdx    = headers.indexOf(ID_FIELD);
  if (idIdx === -1) {
    console.error(`❌ '${ID_FIELD}' 컬럼 없음`);
    process.exit(1);
  }

  // 시트의 verse_id 목록 추출
  const sheetIds = new Set();
  const dataRows = [];

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const verseId = String(row[idIdx] || '').trim();
    if (!verseId || verseId === 'undefined') continue;
    sheetIds.add(verseId);
    dataRows.push({ verseId, row });
  }

  console.log(`✅ 시트에서 ${sheetIds.size}개 알람 말씀 확인\n`);

  // ── 1단계: Firestore 기존 문서 중 시트에 없는 것 삭제 ──────────────────
  console.log('🗑️  Firestore 기존 문서 확인 중...');
  const existingSnap = await db.collection(COLLECTION).get();
  const firestoreIds = existingSnap.docs.map(d => d.id);
  const toDelete     = firestoreIds.filter(id => !sheetIds.has(id));

  if (toDelete.length === 0) {
    console.log('   삭제할 문서 없음');
  } else {
    console.log(`   삭제 대상: ${toDelete.join(', ')}`);
    const deleteBatch = db.batch();
    toDelete.forEach(id => deleteBatch.delete(db.collection(COLLECTION).doc(id)));
    await deleteBatch.commit();
    console.log(`   ✅ ${toDelete.length}개 삭제 완료`);
  }

  // ── 2단계: 시트 데이터 업로드 ──────────────────────────────────────────
  console.log('\n📤 alarm_verses 컬렉션 업로드 중...');

  let success = 0, fail = 0;
  const BATCH_SIZE = 499;

  for (let bStart = 0; bStart < dataRows.length; bStart += BATCH_SIZE) {
    const chunk = dataRows.slice(bStart, bStart + BATCH_SIZE);
    const batch = db.batch();

    chunk.forEach(({ verseId, row }) => {
      const docData = {};
      headers.forEach((key, j) => {
        if (!key) return;
        const val = convertValue(key, row[j]);
        if (val !== null) docData[key] = val;
      });

      // 기본값 보장
      if (!docData.status)                   docData.status      = 'active';
      if (docData.curated === undefined)     docData.curated     = true;
      if (docData.usage_count === undefined) docData.usage_count = 0;
      if (docData.cooldown_days === undefined) docData.cooldown_days = 7;

      batch.set(db.collection(COLLECTION).doc(verseId), docData);
    });

    try {
      await batch.commit();
      console.log(`   ✅ ${chunk.map(d => d.verseId).join(', ')}`);
      success += chunk.length;
    } catch (e) {
      console.error(`   ❌ 배치 실패: ${e.message}`);
      fail += chunk.length;
    }
  }

  // ── 결과 ───────────────────────────────────────────────────────────────
  console.log('\n═══════════════════════════════════════');
  console.log(`✨ alarm_verses 동기화 완료!`);
  console.log(`   업로드: ${success}개`);
  if (toDelete.length) console.log(`   삭제:   ${toDelete.length}개`);
  if (fail)            console.log(`   실패:   ${fail}개`);
  console.log(`🔗 https://console.firebase.google.com/project/dailyverse-9260d/firestore`);
  console.log('═══════════════════════════════════════');
}

main().catch(e => {
  console.error('❌ 오류:', e.message);
  process.exit(1);
});
