require('dotenv').config();
/**
 * patch_application_universal.js
 *
 * application 필드에서 Zone 시간대 언급을 제거하고 범용 표현으로 재작성합니다.
 * 탐지 패턴에 해당하는 것만 처리 (전체 재작성 아님).
 *
 * 사용법:
 *   node patch_application_universal.js --dry-run   # 대상 목록만 확인
 *   node patch_application_universal.js             # 실제 수정
 */

const admin = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
}
const db = admin.firestore();
db.settings({ preferRest: true });

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const isDryRun = process.argv.includes('--dry-run');

// ── 시간대 언급 탐지 패턴 ──────────────────────────────────────
const TIME_PATTERNS = [
  '알람 끄고', '알람을 끄', '알람을 맞추', '이불 속', '눈 감아봐', '눈을 떠',
  '퇴근', '출근', '퇴근길', '출근길',
  '이제 편히 자', '편히 자', '잠들어봐', '잠자리',
  '점심', '점심 시간', '저녁에', '저녁을',
  '아침을 시작', '아침에 일어나', '오늘 아침을',
  '취침', '기지개', '밥 먹기 전',
];

function hasTimeReference(text) {
  return TIME_PATTERNS.some(p => text.includes(p));
}

// ── Claude API 재작성 ──────────────────────────────────────────
async function rewriteApplication(verseFullKo, reference, currentApplication) {
  const prompt = `너는 morning manna 앱의 말씀 콘텐츠 작가야.
아래 application 필드에 특정 시간대 언급이 있어서 범용 표현으로 다시 써야 해.

말씀: "${verseFullKo}"
참조: ${reference}
현재 application: "${currentApplication}"

규칙:
- 49~73자
- 시간대 언급 완전 제거 (알람 끄고, 퇴근하며, 이제 편히 자, 점심, 아침에 일어나 등)
- 아침이든 낮이든 밤이든 언제 읽어도 자연스럽게
- 내면 태도·시선 변화 중심
- 말투: ~해봐, ~기억해, ~말해봐, ~생각해봐, ~내려놔
- 금지: 반드시, 꼭, ~해야 한다

좋은 예:
"오늘 두렵거나 막히는 게 있다면, 잠깐 멈추고 기억해봐. 혼자가 아니야."
"지금 이 순간, 그분이 함께한다는 걸 한 번만 마음속으로 말해봐."

JSON만 출력:
{"application": "새로운 범용 application 텍스트"}`;

  const response = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 200,
    messages: [{ role: 'user', content: prompt }],
  });

  const text = response.content[0].text.trim();
  const match = text.match(/"application"\s*:\s*"([^"]+)"/);
  return match ? match[1] : null;
}

// ── Sheets 업데이트 ───────────────────────────────────────────
async function updateSheet(auth, verseId, newApplication, headers, rowMap) {
  const sheets = google.sheets({ version: 'v4', auth });
  const appIdx = headers.indexOf('application');
  if (appIdx < 0) throw new Error('application 컬럼 없음');

  const col = appIdx < 26
    ? String.fromCharCode(65 + appIdx)
    : 'A' + String.fromCharCode(65 + (appIdx - 26));
  const row = rowMap[verseId];
  if (!row) throw new Error(`verse_id 행 없음: ${verseId}`);

  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!${col}${row}`,
    valueInputOption: 'RAW',
    requestBody: { values: [[newApplication]] },
  });
}

// ── 메인 ─────────────────────────────────────────────────────
async function main() {
  console.log(`=== patch_application_universal.js ===`);
  console.log(`dry-run: ${isDryRun}\n`);

  // Firestore에서 전체 말씀 로드
  console.log('verses 컬렉션 읽는 중...');
  const snap = await db.collection('verses').where('status', '==', 'active').get();
  const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));

  // 시간대 언급 있는 것만 필터링
  const targets = docs.filter(d => d.application && hasTimeReference(d.application));
  console.log(`시간대 언급 탐지: ${targets.length}개 (전체 ${docs.length}개 중)\n`);

  if (isDryRun) {
    targets.forEach(d => console.log(`  ${d.id}: "${d.application}"`));
    return;
  }

  // Google Sheets 인증 + 행 매핑
  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const hRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID, range: `${SHEET_NAME}!A1:AZ1`,
  });
  const headers = hRes.data.values[0];

  const idRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID, range: `${SHEET_NAME}!A2:A2000`,
  });
  const rowMap = {};
  (idRes.data.values || []).forEach((r, i) => { if (r[0]) rowMap[r[0]] = i + 2; });

  // 재작성 + Sheets 업데이트
  let success = 0, fail = 0;
  for (let i = 0; i < targets.length; i++) {
    const d = targets[i];
    process.stdout.write(`[${i+1}/${targets.length}] ${d.id} 재작성 중... `);
    try {
      const newApp = await rewriteApplication(d.verse_full_ko || d.verseFullKo, d.reference, d.application);
      if (!newApp) throw new Error('생성 실패');

      const len = newApp.length;
      const warn = len < 49 || len > 73 ? ` ⚠️ ${len}자` : ` (${len}자)`;
      await updateSheet(auth, d.id, newApp, headers, rowMap);
      console.log(`✅${warn} → "${newApp}"`);
      success++;
    } catch (e) {
      console.log(`❌ ${e.message}`);
      fail++;
    }
    // API rate limit 방지
    await new Promise(r => setTimeout(r, 200));
  }

  console.log(`\n===== 완료 =====`);
  console.log(`성공: ${success}개 | 오류: ${fail}개`);
  console.log(`\n다음 단계: npm run sync 으로 Firestore 반영`);
}

main().catch(e => { console.error('오류:', e.message); process.exit(1); });
