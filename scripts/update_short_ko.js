require('dotenv').config();
/**
 * update_short_ko.js
 *
 * verse_short_ko 결정 규칙 적용:
 *   1. verse_full_ko ≤ 60자  → short_ko = full_ko
 *   2. verse_full_ko 단일 문장 (마침표 ≤1개) → short_ko = full_ko
 *   3. verse_full_ko > 60자 + 복수 문장 → Claude Haiku로 핵심 문장 추출
 *
 * 사용법:
 *   node update_short_ko.js            # 전체 (AI 포함, ANTHROPIC_API_KEY 필요)
 *   node update_short_ko.js --no-ai    # AI 불필요한 138개만 처리
 *   node update_short_ko.js --dry-run  # 미리보기 (DB 변경 없음)
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const noAI = args.includes('--no-ai');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
}
const db = admin.firestore();

// ── 규칙 판단 ────────────────────────────────────────────────────
function isSingleSentence(text) {
  return (text.match(/[.。]/g) || []).length <= 1;
}

function canUseFullAsShort(fullKo) {
  if (!fullKo) return false;
  const clean = fullKo.replace(/\n/g, '').trim();
  return clean.length <= 60 || isSingleSentence(clean);
}

// ── Claude API 추출 (AI 필요 케이스) ────────────────────────────
async function extractWithClaude(verseId, fullKo, reference) {
  const Anthropic = require('@anthropic-ai/sdk');
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error('ANTHROPIC_API_KEY 미설정');
  const client = new Anthropic({ apiKey });

  const prompt = `다음 성경 구절에서 핵심 문장 하나를 추출해주세요.

구절: "${fullKo}"
참조: ${reference}

규칙:
- 20~60자 사이
- 원문에 있는 문장 그대로 선택 (축약·합성·변형 금지)
- 말씀의 핵심 메시지가 가장 잘 담긴 한 문장
- 마침표로 끝나야 함
- JSON 형식으로만 응답: {"short_ko": "추출된 문장"}`;

  const msg = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 100,
    messages: [{ role: 'user', content: prompt }]
  });

  const raw = msg.content[0].text.trim();
  const match = raw.match(/"short_ko"\s*:\s*"([^"]+)"/);
  if (!match) throw new Error(`파싱 실패: ${raw}`);
  return match[1];
}

// ── Google Sheets 업데이트 ────────────────────────────────────────
async function updateSheet(updates) {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(__dirname, SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  // 헤더 읽기
  const hRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID, range: `${SHEET_NAME}!1:1`
  });
  const headers = hRes.data.values[0];
  const idCol   = headers.indexOf('verse_id');
  const shortCol = headers.indexOf('verse_short_ko');

  // 전체 데이터 읽기
  const dRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID, range: `${SHEET_NAME}!A:B`
  });
  const rows = dRes.data.values || [];

  const colLetter = n => {
    let s = ''; let x = n + 1;
    while (x > 0) { s = String.fromCharCode(65 + ((x - 1) % 26)) + s; x = Math.floor((x - 1) / 26); }
    return s;
  };
  const shortColLetter = colLetter(shortCol);

  // 업데이트 맵 생성
  const updateMap = {};
  updates.forEach(u => { updateMap[u.verseId] = u.shortKo; });

  const batchData = [];
  for (let i = 1; i < rows.length; i++) {
    const rowId = (rows[i] || [])[0];
    if (rowId && updateMap[rowId]) {
      batchData.push({
        range: `${SHEET_NAME}!${shortColLetter}${i + 1}`,
        values: [[updateMap[rowId]]]
      });
    }
  }

  if (batchData.length === 0) { console.log('  시트: 업데이트 없음'); return; }

  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: { valueInputOption: 'RAW', data: batchData }
  });
  console.log(`  ✅ 시트 ${batchData.length}개 행 업데이트`);
}

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log(`\n📖 Firestore 말씀 로딩...`);
  const snap = await db.collection('verses').get();
  const verses = [];
  snap.forEach(doc => verses.push({ id: doc.id, ...doc.data() }));
  console.log(`   총 ${verses.length}개 말씀\n`);

  const updates = [];
  let autoCount = 0, aiCount = 0, skipCount = 0;

  for (const v of verses) {
    const full = (v.verse_full_ko || '').trim();
    const currentShort = (v.verse_short_ko || '').trim();

    if (!full) { skipCount++; continue; }

    let newShort;
    if (canUseFullAsShort(full)) {
      newShort = full;
      autoCount++;
    } else {
      if (noAI) {
        // --no-ai 모드: AI 필요한 것은 건너뜀
        skipCount++;
        continue;
      }
      try {
        newShort = await extractWithClaude(v.id, full, v.reference || '');
        aiCount++;
        // API 과부하 방지
        await new Promise(r => setTimeout(r, 300));
      } catch(e) {
        console.warn(`  ⚠️  ${v.id} AI 실패: ${e.message}`);
        skipCount++;
        continue;
      }
    }

    if (newShort === currentShort) { skipCount++; continue; }

    updates.push({ verseId: v.id, shortKo: newShort, oldShort: currentShort });
    const changed = currentShort !== newShort;
    console.log(`  ${changed ? '✏️ ' : '✓ '} ${v.id}`);
    console.log(`    이전: ${currentShort.substring(0, 50)}${currentShort.length > 50 ? '...' : ''}`);
    console.log(`    이후: ${newShort.substring(0, 50)}${newShort.length > 50 ? '...' : ''}`);
  }

  console.log(`\n📊 집계:`);
  console.log(`   자동(full=short): ${autoCount}개`);
  console.log(`   AI 추출: ${aiCount}개`);
  console.log(`   변경 없음/스킵: ${skipCount}개`);
  console.log(`   실제 업데이트: ${updates.length}개`);

  if (isDryRun) { console.log('\n🔍 Dry-run 완료 (DB/시트 변경 없음)'); process.exit(0); }
  if (updates.length === 0) { console.log('\n변경 없음'); process.exit(0); }

  console.log('\n🔥 Firestore 업데이트 중...');
  const batch = db.batch();
  updates.forEach(u => {
    batch.update(db.collection('verses').doc(u.verseId), { verse_short_ko: u.shortKo });
  });
  await batch.commit();
  console.log(`  ✅ Firestore ${updates.length}개 업데이트`);

  console.log('\n📊 Google Sheets 업데이트 중...');
  await updateSheet(updates);

  console.log('\n✨ 완료!');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
