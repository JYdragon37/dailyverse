require('dotenv').config();
/**
 * patch_application_length.js
 *
 * application 필드가 49~73자 범위를 벗어난 것을 Claude API로 재작성합니다.
 * 범용 원칙 유지 (시간대 언급 없이).
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

const MIN = 49, MAX = 73;

async function rewriteApplication(verseFullKo, reference, current) {
  const len = current ? current.length : 0;
  const direction = len > MAX ? `너무 길어 (${len}자). ${MAX}자 이하로 줄여` : `너무 짧아 (${len}자). ${MIN}자 이상으로 늘려`;

  const prompt = `너는 morning manna 앱의 말씀 콘텐츠 작가야.
아래 application 필드가 ${direction}.

말씀: "${verseFullKo}"
참조: ${reference}
현재: "${current}"

${MIN}~${MAX}자로 다시 써줘.

규칙:
- 오늘 바로 실천 가능한 구체적 행동 1가지
- 시간대 언급 없이 범용 (아침/낮/밤 언제 읽어도 자연스럽게)
- 말투: ~해봐, ~기억해, ~말해봐, ~생각해봐, ~내려놔
- 금지: 반드시, 꼭, ~해야 한다, 알람 끄고, 퇴근, 이제 편히 자 등

JSON만 출력:
{"application": "재작성 텍스트"}`;

  const response = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 200,
    messages: [{ role: 'user', content: prompt }],
  });

  const text = response.content[0].text.trim();
  const match = text.match(/"application"\s*:\s*"([^"]+)"/);
  return match ? match[1] : null;
}

async function main() {
  console.log(`=== patch_application_length.js ===`);
  console.log(`dry-run: ${isDryRun}\n`);

  const snap = await db.collection('verses').where('status', '==', 'active').get();
  const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));

  const targets = docs.filter(d => {
    const len = (d.application || '').length;
    return len < MIN || len > MAX;
  });
  console.log(`범위 이탈 탐지: ${targets.length}개\n`);

  if (isDryRun) {
    targets.slice(0, 20).forEach(d => {
      const len = (d.application || '').length;
      console.log(`  ${d.id} (${len}자): "${(d.application||'').substring(0,50)}"`);
    });
    if (targets.length > 20) console.log(`  ... 외 ${targets.length - 20}개`);
    return;
  }

  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const hRes = await sheets.spreadsheets.values.get({ spreadsheetId: SHEET_ID, range: 'VERSES!A1:AZ1' });
  const headers = hRes.data.values[0];
  const appIdx = headers.indexOf('application');
  const col = appIdx < 26 ? String.fromCharCode(65 + appIdx) : 'A' + String.fromCharCode(65 + (appIdx - 26));

  const idRes = await sheets.spreadsheets.values.get({ spreadsheetId: SHEET_ID, range: 'VERSES!A2:A2000' });
  const rowMap = {};
  (idRes.data.values || []).forEach((r, i) => { if (r[0]) rowMap[r[0]] = i + 2; });

  let success = 0, fail = 0;
  for (let i = 0; i < targets.length; i++) {
    const d = targets[i];
    const len = (d.application || '').length;
    process.stdout.write(`[${i+1}/${targets.length}] ${d.id} (${len}자) 재작성 중... `);
    try {
      const newApp = await rewriteApplication(d.verse_full_ko || d.verseFullKo, d.reference, d.application);
      if (!newApp) throw new Error('생성 실패');
      const newLen = newApp.length;
      const warn = newLen < MIN || newLen > MAX ? ` ⚠️ ${newLen}자` : ` (${newLen}자)`;
      await sheets.spreadsheets.values.update({
        spreadsheetId: SHEET_ID,
        range: `VERSES!${col}${rowMap[d.id]}`,
        valueInputOption: 'RAW',
        requestBody: { values: [[newApp]] },
      });
      console.log(`✅${warn} → "${newApp.substring(0, 40)}..."`);
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
