require('dotenv').config();
/**
 * qa_ai_check.js — AI 품질 검증 (Claude API 기반)
 *
 * 검증 항목:
 *   - interpretation: ①저자상황→②핵심의미→③오늘연결 구조 + Zone 맥락
 *   - application: 해당 Zone 시간대·유저 상황 반영 여부
 *   - question: verse_full_ko와 맥락 연결 + 비종교적 어조
 *   - 전반적 톤·스타일 일관성
 *
 * 사전 조건: qa_auto_check.js로 auto_passed 상태가 되어 있어야 함
 *
 * 사용법:
 *   node qa_ai_check.js              # auto_passed 전체
 *   node qa_ai_check.js --range v_001,v_050
 *   node qa_ai_check.js --all        # auto_passed + ai_failed 재검증
 *   node qa_ai_check.js --dry-run
 */

const admin    = require('firebase-admin');
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
const isAll    = args.includes('--all');
// --deep: Sonnet으로 2차 정밀 검증 (기본: Haiku 1차)
const isDeep   = args.includes('--deep');
const MODEL    = isDeep ? 'claude-sonnet-4-6' : 'claude-haiku-4-5-20251001';

const rangeFilter = (() => {
  const idx = args.indexOf('--range');
  if (idx === -1) return null;
  const parts = args[idx + 1].split(',').map(s => s.trim());
  return { start: parseInt(parts[0].replace(/\D/g, '')), end: parseInt(parts[1].replace(/\D/g, '')) };
})();

// Zone별 유저 상황 요약 (AI 검증 컨텍스트용)
const ZONE_CONTEXT = {
  deep_dark:   '자정~새벽 3시. 잠 못 들고 불안·외로움 속에 깨어 있음',
  first_light: '새벽 3~6시. 이른 기도·묵상을 위해 일어남. 하루 전의 고요',
  rise_ignite: '오전 6~9시. 알람 끄고 이불 속. 나른함+부담+작은 설렘',
  peak_mode:   '오전 9~12시. 업무·공부 집중. 스트레스·책임감',
  recharge:    '오후 12~15시. 점심 후 잠깐 쉬는 시간. 나른함',
  second_wind: '오후 15~18시. 오후 슬럼프. 피로+마무리 의지',
  golden_hour: '오후 18~21시. 퇴근·귀가 후. 수고함+감사',
  wind_down:   '오후 21~24시. 취침 전 마지막 폰. 피로+평안 욕구',
  all:         '특정 시간대 무관',
};

async function aiCheck(doc) {
  const d = doc.data;
  const modes = Array.isArray(d.mode) ? d.mode : [d.mode || 'all'];
  const zoneDesc = modes.map(m => ZONE_CONTEXT[m] || ZONE_CONTEXT.all).join(' / ');

  const prompt = `아래 DailyVerse 콘텐츠를 v9.0 가이드라인으로 점검해줘.

[입력]
verse_id: ${doc.id}
reference: ${d.reference}
mode: ${modes.join(', ')} → 유저 상황: ${zoneDesc}
verse_full_ko: ${d.verse_full_ko || '(없음)'}
interpretation: ${d.interpretation || '(없음)'}
application: ${d.application || '(없음)'}
question: ${d.question || '(없음)'}

[점검 기준]

1. interpretation (이 중 하나라도 위반이면 실패):
   - ①저자·화자가 처한 구체적 상황 1문장 존재?
   - ②구절 핵심 의미 설명 존재?
   - ③오늘 유저에게 연결 1문장 존재?
   - 히브리어·헬라어 단어 직접 표기 없음?
   - ~야/~이야/~거야 어투 (합니다/이다 금지)?

2. application:
   - 해당 mode(${modes.join(', ')}) 시간대·유저 상황이 문장 배경에 느껴지는가?
   - 강요 표현(반드시/꼭/~해야 한다) 없음?
   - 시간대와 맞지 않는 상황 언급 없음? (예: rise_ignite인데 "저녁에")

3. question:
   - verse_full_ko의 핵심 메시지와 맥락이 연결되는가?
   - 신앙 행위 점검 형태 아님? ("기도했나요?", "말씀을 읽었나요?" 등)
   - 경어체 없음? (~하셨나요, ~해야 합니까 금지)

[중요] 개역한글 원문(~니라, ~이로다 등 고어체)은 verse_full_ko에서 정상 — 지적하지 마.

출력: JSON만 (다른 텍스트 없이)
{"pass": true, "issues": []}
또는
{"pass": false, "issues": ["interpretation: ③오늘연결 문장 없음", "application: mode(rise_ignite) 대비 저녁 언급"]}`;

  const message = await anthropic.messages.create({
    model: MODEL,
    max_tokens: 256,
    messages: [{ role: 'user', content: prompt }],
  });

  const raw = message.content[0].text.trim();
  const jsonStr = raw.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  return JSON.parse(jsonStr);
}

async function main() {
  console.log(`=== qa_ai_check.js | dry-run: ${isDryRun} | model: ${MODEL} (${isDeep ? '2차 정밀' : '1차 기본'}) ===\n`);

  // --deep: Sonnet 2차 검증 — 1차(Haiku) 통과한 ai_passed 대상
  // --all:  1차 실패한 ai_failed도 포함하여 재검증
  // 기본:   auto_passed만
  const targetStatuses = isDeep
    ? ['ai_passed']
    : isAll
      ? ['auto_passed', 'ai_failed']
      : ['auto_passed'];

  const snap = await db.collection('verses').where('status', '==', 'active').orderBy('__name__').get();
  const docs = [];
  snap.forEach(docSnap => {
    const num = parseInt(docSnap.id.replace(/\D/g, ''));
    if (rangeFilter && (num < rangeFilter.start || num > rangeFilter.end)) return;
    const d = docSnap.data();
    if (!targetStatuses.includes(d.qa_status)) return;
    docs.push({ id: docSnap.id, ref: docSnap.ref, data: d });
  });

  console.log(`대상: ${docs.length}개 (${targetStatuses.join('/')} 상태)\n`);

  let passed = 0, failed = 0, errors = 0;
  const failLog = [];

  for (let i = 0; i < docs.length; i++) {
    const doc = docs[i];
    process.stdout.write(`[${i+1}/${docs.length}] ${doc.id} (${doc.data.reference}) ... `);

    try {
      const result = await aiCheck(doc);
      const status = result.pass ? 'ai_passed' : 'ai_failed';

      if (isDryRun) {
        console.log(result.pass ? '✅ PASS' : `❌ FAIL: ${result.issues.join(' / ').slice(0, 60)}`);
      } else {
        await doc.ref.update({
          qa_status:   status,
          qa_issues:   result.issues,
          qa_checked_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(result.pass ? '✅ PASS' : `❌ FAIL (${result.issues.length}건)`);
      }

      if (result.pass) { passed++; }
      else {
        failed++;
        failLog.push({ id: doc.id, ref: doc.data.reference, issues: result.issues });
      }
    } catch (e) {
      console.log(`⚠️ 오류: ${e.message}`);
      errors++;
    }

    if (i < docs.length - 1) await new Promise(r => setTimeout(r, 400));
  }

  console.log(`\n===== AI 검증 완료 =====`);
  console.log(`통과: ${passed}개 | 실패: ${failed}개 | 오류: ${errors}개`);

  if (failLog.length) {
    console.log(`\n실패 목록 (상위 20개):`);
    failLog.slice(0, 20).forEach(f => {
      console.log(`  ${f.id} (${f.ref})`);
      f.issues.forEach(issue => console.log(`    - ${issue}`));
    });
  }

  if (isDryRun) console.log('\n[dry-run: DB 변경 없음]');
  else console.log('\n다음 단계: node qa_report.js  →  node qa_approve.js');
}

main().catch(console.error).finally(() => process.exit());
