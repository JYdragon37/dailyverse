require('dotenv').config();
/**
 * update_to_korv.js
 * Firestore verses/의 verse_full_ko, verse_short_ko를
 * 개역한글(1961, 퍼블릭 도메인) 원문으로 업데이트
 *
 * 사용법:
 *   node update_to_korv.js --dry-run           # 미리보기 (DB 변경 없음)
 *   node update_to_korv.js --range v_001,v_010 # 특정 범위만
 *   node update_to_korv.js                     # 전체 실행
 */

const admin = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) { console.error('ANTHROPIC_API_KEY 필요'); process.exit(1); }
const anthropic = new Anthropic({ apiKey });

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');

const rangeFilter = (() => {
  const idx = args.indexOf('--range');
  if (idx === -1) return null;
  const parts = args[idx + 1].split(',').map(s => s.trim());
  if (parts.length !== 2) return null;
  return { start: parseInt(parts[0].replace(/\D/g, '')), end: parseInt(parts[1].replace(/\D/g, '')) };
})();

// ── 개역한글 원문 조회 ──────────────────────────────────────────────────────
async function getKorvText(reference) {
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',   // 정확도를 위해 Sonnet 사용
    max_tokens: 512,
    system: `너는 성경 전문가야.
개역한글 성경(1961년판, 대한성서공회 발행, 현재 퍼블릭 도메인) 원문을 정확히 제공해.
반드시 개역한글 원문 텍스트 그대로 제공해야 해. 임의로 바꾸지 마.`,
    messages: [{
      role: 'user',
      content: `아래 성경 구절의 개역한글 원문을 JSON으로 반환해줘.

구절: ${reference}

규칙:
1. verse_full_ko: 개역한글 원문 (40~120자)
   - 너무 길면 핵심 부분만 포함 (핵심 메시지 보존)
   - 복수 절이면 \\n으로 구분
   - 원문 그대로 — 임의 수정 금지
2. verse_short_ko: verse_full_ko에서 가장 임팩트 있는 한 절/문장 (20~60자)
   - 원문에 있는 문장을 그대로 선택 (재창작·합성 금지)
   - verse_full_ko가 60자 이하이면 그대로 사용

출력: JSON만 (다른 텍스트 없이)
{"verse_full_ko": "...", "verse_short_ko": "..."}`
    }]
  });

  const raw = message.content[0].text.trim();
  const jsonStr = raw.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  return JSON.parse(jsonStr);
}

// ── 메인 ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log(`=== 개역한글 업데이트 | dry-run: ${isDryRun} ===\n`);

  const snap = await db.collection('verses').orderBy('__name__').get();
  const verses = [];
  snap.forEach(doc => {
    const d = doc.data();
    if (d.status !== 'active') return;
    const num = parseInt(doc.id.replace(/\D/g, ''));
    if (rangeFilter && (num < rangeFilter.start || num > rangeFilter.end)) return;
    verses.push({ id: doc.id, ref: doc.ref, reference: d.reference });
  });

  console.log(`대상: ${verses.length}개\n`);

  let success = 0, errors = 0;
  const errorLog = [];

  for (let i = 0; i < verses.length; i++) {
    const { id, ref, reference } = verses[i];
    process.stdout.write(`[${i+1}/${verses.length}] ${id} (${reference}) ... `);

    try {
      const result = await getKorvText(reference);
      const { verse_full_ko, verse_short_ko } = result;

      if (isDryRun) {
        console.log('\n  full : ' + verse_full_ko.replace(/\n/g, ' / ').slice(0, 60));
        console.log('  short: ' + verse_short_ko);
      } else {
        await ref.update({ verse_full_ko, verse_short_ko });
        console.log(`완료 (full ${verse_full_ko.length}자, short ${verse_short_ko.length}자)`);
        success++;
      }
    } catch (e) {
      console.log(`오류: ${e.message}`);
      errors++;
      errorLog.push({ id, error: e.message });
    }

    if (i < verses.length - 1) await new Promise(r => setTimeout(r, 600));
  }

  console.log(`\n===== 완료 =====`);
  if (isDryRun) {
    console.log(`dry-run: ${verses.length}개 미리보기 (실제 업데이트 없음)`);
  } else {
    console.log(`성공: ${success}개 | 오류: ${errors}개`);
    if (errorLog.length) {
      console.log('\n오류 목록:');
      errorLog.forEach(e => console.log(` - ${e.id}: ${e.error}`));
    }
    console.log('\n다음 단계: node sync_firestore_to_sheet.js');
  }
}

main().catch(console.error).finally(() => process.exit());
