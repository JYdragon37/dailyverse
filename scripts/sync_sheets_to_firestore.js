/**
 * DailyVerse — Google Sheets → Firestore 완전 동기화 스크립트
 *
 * 동작 방식:
 *   1. 구글 시트의 verse_id 목록을 읽음
 *   2. Firestore verses 컬렉션의 기존 문서 중 시트에 없는 것은 삭제
 *   3. 시트의 모든 행을 Firestore에 업로드 (upsert)
 *
 * → 시트가 "단일 진실 원본(Source of Truth)" 역할
 *
 * 사용법:
 *   node sync_sheets_to_firestore.js
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

// ─── 설정 ──────────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

const ARRAY_FIELDS    = ['mode', 'theme', 'mood', 'season', 'weather', 'avoid_themes'];
const INT_FIELDS      = ['chapter', 'verse', 'usage_count', 'cooldown_days', 'show_count'];
const BOOL_FIELDS     = ['curated', 'is_sacred_safe'];
const NULLABLE_FIELDS = ['alarm_text_ko', 'last_shown', 'notes', 'source_url'];

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
  console.log('\n📊 Google Sheets에서 데이터 읽는 중...');
  const rows = await getSheetData();

  if (rows.length < 2) {
    console.error('❌ 데이터가 없습니다. (헤더 포함 최소 2행 필요)');
    process.exit(1);
  }

  const headers = rows[0].map(h => String(h).trim());
  const verseIdIdx = headers.indexOf('verse_id');
  if (verseIdIdx === -1) {
    console.error('❌ verse_id 컬럼 없음');
    process.exit(1);
  }

  // 시트의 verse_id 목록 추출
  const sheetIds = new Set();
  const dataRows = [];

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const verseId = String(row[verseIdIdx] || '').trim();
    if (!verseId || verseId === 'undefined') continue;
    sheetIds.add(verseId);
    dataRows.push({ verseId, row });
  }

  console.log(`✅ 시트에서 ${sheetIds.size}개 말씀 확인\n`);

  // ── 1단계: Firestore 기존 문서 중 시트에 없는 것 삭제 ──────────────────
  console.log('🗑️  Firestore 기존 문서 확인 중...');
  const existingSnap = await db.collection('verses').get();
  const firestoreIds = existingSnap.docs.map(d => d.id);

  const toDelete = firestoreIds.filter(id => !sheetIds.has(id));

  if (toDelete.length === 0) {
    console.log('   삭제할 문서 없음');
  } else {
    console.log(`   삭제 대상: ${toDelete.join(', ')}`);
    // batch 삭제
    const deleteBatch = db.batch();
    toDelete.forEach(id => {
      deleteBatch.delete(db.collection('verses').doc(id));
    });
    await deleteBatch.commit();
    console.log(`   ✅ ${toDelete.length}개 삭제 완료`);
  }

  // ── 2단계: 시트 데이터 업로드 ──────────────────────────────────────────
  console.log('\n📤 시트 데이터 업로드 중...');

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
      if (!docData.status)                    docData.status      = 'active';
      if (docData.curated === undefined)      docData.curated     = true;
      if (docData.usage_count === undefined)  docData.usage_count = 0;

      batch.set(db.collection('verses').doc(verseId), docData);
    });

    try {
      await batch.commit();
      const ids = chunk.map(d => d.verseId).join(', ');
      console.log(`   ✅ ${chunk.length}개: ${ids}`);
      success += chunk.length;
    } catch (e) {
      console.error(`   ❌ 배치 실패: ${e.message}`);
      fail += chunk.length;
    }
  }

  // ── 결과 ───────────────────────────────────────────────────────────────
  console.log('\n═══════════════════════════════════════');
  console.log(`✨ 동기화 완료!`);
  console.log(`   업로드: ${success}개`);
  if (toDelete.length) console.log(`   삭제:   ${toDelete.length}개 (${toDelete.join(', ')})`);
  if (fail)            console.log(`   실패:   ${fail}개`);
  console.log(`🔗 https://console.firebase.google.com/project/dailyverse-9260d/firestore`);
  console.log('═══════════════════════════════════════');
}

main().catch(e => {
  console.error('❌ 오류:', e.message);
  process.exit(1);
});
