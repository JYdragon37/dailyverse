/**
 * DailyVerse — Google Sheets → Firestore 자동 동기화 스크립트
 *
 * Apps Script의 OAuth 스코프 문제를 우회:
 * 서비스 계정 키(serviceAccountKey.json)로 Sheets + Firestore 모두 직접 인증
 *
 * 사용법:
 *   node sync_sheets_to_firestore.js
 *
 * 전제 조건:
 *   - scripts/serviceAccountKey.json 존재
 *   - 구글 시트에 서비스 계정(firebase-adminsdk-...)이 편집자로 추가됨 (이미 완료)
 *   - Firestore 보안 규칙: allow write: if true; (업로드 중만)
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

// ─── 설정 ──────────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';  // 탭 이름

// 배열 필드 (쉼표 구분 문자열 → 배열)
const ARRAY_FIELDS = ['mode', 'theme', 'mood', 'season', 'weather', 'avoid_themes'];
// 정수 필드
const INT_FIELDS   = ['chapter', 'verse', 'usage_count', 'cooldown_days', 'show_count'];
// 불리언 필드
const BOOL_FIELDS  = ['curated', 'is_sacred_safe'];
// 비어있으면 저장 안 할 선택적 필드
const NULLABLE_FIELDS = ['alarm_text_ko', 'last_shown', 'notes', 'source_url'];

// ─── Firebase Admin 초기화 ─────────────────────────────────────────────────

const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─── Google Sheets 인증 ────────────────────────────────────────────────────

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
  const str = String(raw).trim();

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
    console.error('❌ 데이터가 없습니다.');
    process.exit(1);
  }

  const headers = rows[0].map(h => String(h).trim());
  const verseIdIdx = headers.indexOf('verse_id');

  if (verseIdIdx === -1) {
    console.error('❌ verse_id 컬럼을 찾을 수 없습니다.');
    process.exit(1);
  }

  console.log(`✅ ${rows.length - 1}개 행 발견`);
  console.log(`📋 컬럼: ${headers.join(', ')}\n`);

  let success = 0, skip = 0, fail = 0;
  const batch = db.batch();
  const batchDocs = [];

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const verseId = String(row[verseIdIdx] || '').trim();

    if (!verseId || verseId === 'undefined') {
      skip++;
      continue;
    }

    // 문서 데이터 빌드
    const docData = {};
    headers.forEach((key, j) => {
      if (!key) return;
      const val = convertValue(key, row[j] ?? '');
      if (val !== null) docData[key] = val;
    });

    // 기본값 보장
    if (!docData.status)      docData.status = 'active';
    if (docData.curated === undefined) docData.curated = true;
    if (docData.usage_count === undefined) docData.usage_count = 0;

    const ref = db.collection('verses').doc(verseId);
    batch.set(ref, docData, { merge: true });
    batchDocs.push(verseId);

    // Firestore batch 최대 500개 제한
    if (batchDocs.length === 499) {
      await commitBatch(batch, batchDocs);
      success += batchDocs.length;
      batchDocs.length = 0;
    }
  }

  // 남은 배치 커밋
  if (batchDocs.length > 0) {
    try {
      await batch.commit();
      console.log(`✅ 업로드: ${batchDocs.join(', ')}`);
      success += batchDocs.length;
    } catch (e) {
      console.error(`❌ 배치 업로드 실패: ${e.message}`);
      fail += batchDocs.length;
    }
  }

  console.log(`\n✨ 완료! 성공: ${success}개 | 스킵: ${skip}개 | 실패: ${fail}개`);
  console.log(`🔗 Firestore 확인: https://console.firebase.google.com/project/dailyverse-9260d/firestore`);
}

async function commitBatch(batch, ids) {
  try {
    await batch.commit();
    console.log(`✅ 배치 업로드: ${ids.length}개`);
  } catch (e) {
    console.error(`❌ 배치 실패: ${e.message}`);
  }
}

main().catch(e => {
  console.error('❌ 오류:', e.message);
  process.exit(1);
});
