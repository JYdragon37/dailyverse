require('dotenv').config();
/**
 * patch_interpretation_length.js
 *
 * interpretation 필드가 102~154자 범위를 벗어난 것을 Claude API로 재작성합니다.
 * - 154자 초과: 3단계 구조 유지하며 압축
 * - 102자 미만: 3단계 구조에 맞게 확장
 *
 * 사용법:
 *   node patch_interpretation_length.js --dry-run
 *   node patch_interpretation_length.js
 */

const admin = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
}
const db = admin.firestore();
db.settings({ preferRest: true });

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const isDryRun = process.argv.includes('--dry-run');

const MIN = 102, MAX = 154;

async function rewriteInterpretation(verseFullKo, reference, current) {
  const len = current ? current.length : 0;
  const direction = len > MAX ? `너무 길어 (${len}자). ${MAX}자 이하로 압축해` : `너무 짧아 (${len}자). ${MIN}자 이상으로 확장해`;

  const prompt = `너는 morning manna 앱의 말씀 콘텐츠 작가야.
아래 interpretation 필드가 ${direction}.

말씀: "${verseFullKo}"
참조: ${reference}
현재: "${current}"

3단계 구조를 유지하며 ${MIN}~${MAX}자로 다시 써줘:
① 저자/화자가 처한 상황 1문장 ("~가 ~한 상황에서 쓴 말씀이야" 형태)
② 핵심 의미 1~2문장 (원어 직접 표기 절대 금지, 한국어로만)
③ 지금 유저에게 연결 1문장 ("지금 네가...", "이 말씀은 오늘 너에게..." 형태)

총 ${MIN}~${MAX}자. 2~3문장마다 \\n 삽입.
말투: ~야, ~이야, ~거야, ~있어, ~계셔
금지: ~이다, ~합니다, ~입니다, 설교조, 원어 직접 표기

JSON만 출력:
{"interpretation": "재작성된 텍스트"}`;

  const response = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 300,
    messages: [{ role: 'user', content: prompt }],
  });

  const text = response.content[0].text.trim();
  const match = text.match(/"interpretation"\s*:\s*"([\s\S]+?)"\s*\}/);
  return match ? match[1].replace(/\\n/g, '\n') : null;
}

async function main() {
  console.log(`=== patch_interpretation_length.js ===`);
  console.log(`dry-run: ${isDryRun}\n`);

  const snap = await db.collection('verses').where('status', '==', 'active').get();
  const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));

  const targets = docs.filter(d => {
    const len = (d.interpretation || '').length;
    return len < MIN || len > MAX;
  });
  console.log(`범위 이탈 탐지: ${targets.length}개 (전체 ${docs.length}개 중)\n`);

  if (isDryRun) {
    targets.forEach(d => {
      const len = (d.interpretation || '').length;
      console.log(`  ${d.id} (${len}자): "${(d.interpretation||'').substring(0,40)}..."`);
    });
    return;
  }

  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const hRes = await sheets.spreadsheets.values.get({ spreadsheetId: SHEET_ID, range: 'VERSES!A1:AZ1' });
  const headers = hRes.data.values[0];
  const interpIdx = headers.indexOf('interpretation');
  const col = interpIdx < 26 ? String.fromCharCode(65 + interpIdx) : 'A' + String.fromCharCode(65 + (interpIdx - 26));

  const idRes = await sheets.spreadsheets.values.get({ spreadsheetId: SHEET_ID, range: 'VERSES!A2:A2000' });
  const rowMap = {};
  (idRes.data.values || []).forEach((r, i) => { if (r[0]) rowMap[r[0]] = i + 2; });

  let success = 0, fail = 0;
  for (let i = 0; i < targets.length; i++) {
    const d = targets[i];
    const len = (d.interpretation || '').length;
    process.stdout.write(`[${i+1}/${targets.length}] ${d.id} (${len}자) 재작성 중... `);
    try {
      const newInterp = await rewriteInterpretation(
        d.verse_full_ko || d.verseFullKo, d.reference, d.interpretation
      );
      if (!newInterp) throw new Error('생성 실패');
      const newLen = newInterp.replace(/\n/g, '').length;
      const warn = newLen < MIN || newLen > MAX ? ` ⚠️ ${newLen}자` : ` (${newLen}자)`;

      await sheets.spreadsheets.values.update({
        spreadsheetId: SHEET_ID,
        range: `VERSES!${col}${rowMap[d.id]}`,
        valueInputOption: 'RAW',
        requestBody: { values: [[newInterp]] },
      });
      console.log(`✅${warn}`);
      success++;
    } catch (e) {
      console.log(`❌ ${e.message}`);
      fail++;
    }
    await new Promise(r => setTimeout(r, 200));
  }

  console.log(`\n===== 완료 =====`);
  console.log(`성공: ${success}개 | 오류: ${fail}개`);
  console.log(`다음 단계: npm run sync`);
}

main().catch(e => { console.error('오류:', e.message); process.exit(1); });
