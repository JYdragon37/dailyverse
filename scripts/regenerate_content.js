require('dotenv').config();
/**
 * regenerate_content.js
 * 기존 말씀의 interpretation, application, question을 Sonnet으로 재생성
 *
 * 대상: v_001~v_180 중 active 구절 (새 39개 v_181+ 제외)
 * 보존: verse_full_ko, verse_short_ko, reference, mode, theme 등 메타데이터
 * 재생성: interpretation, application, question
 *
 * 사용법:
 *   node regenerate_content.js --dry-run        # 미리보기
 *   node regenerate_content.js                  # 전체 실행
 *   node regenerate_content.js --range v_001,v_050
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

const args      = process.argv.slice(2);
const isDryRun  = args.includes('--dry-run');

const rangeFilter = (() => {
  const idx = args.indexOf('--range');
  if (idx === -1) return null;
  const parts = args[idx + 1].split(',').map(s => s.trim());
  return { start: parseInt(parts[0].replace(/\D/g, '')), end: parseInt(parts[1].replace(/\D/g, '')) };
})();

const ZONE_CONTEXT = {
  deep_dark:   { time: '00~03', appCtx: '잠 못 들고 혼자 깨어 있는 이 시간' },
  first_light: { time: '03~06', appCtx: '새벽의 고요함, 하루가 시작되기 전의 정적' },
  rise_ignite: { time: '06~09', appCtx: '알람 끄고 30초, 이불 속에서 폰 보는 순간' },
  peak_mode:   { time: '09~12', appCtx: '업무·공부 집중 시간, 성과 압박 속' },
  recharge:    { time: '12~15', appCtx: '점심 후 잠깐 쉬는 시간, 나른함' },
  second_wind: { time: '15~18', appCtx: '오후 슬럼프, 하루 마무리를 앞둔 순간' },
  golden_hour: { time: '18~21', appCtx: '퇴근·귀가 후, 수고함+감사' },
  wind_down:   { time: '21~24', appCtx: '취침 전 마지막 폰 확인' },
  all:         { time: '전체',  appCtx: '지금 이 순간 (시간대 무관)' },
};

const LIMITS = {
  interpretation: { min: 100, max: 155 },
  application:    { min: 45,  max: 78  },
  question:       { min: 32,  max: 80  },
};

function buildPrompt(d, zone, primary) {
  return `[역할]
너는 DailyVerse 앱의 말씀 콘텐츠 작가야.
설교자가 아닌 유저의 신앙 친구. 교회 강단 언어 아님.

[입력]
성경 구절: ${d.reference}
말씀 전문(개역한글): ${d.verse_full_ko}
Zone: ${primary} (${zone.time})
application 컨텍스트: ${zone.appCtx}

[생성 항목 — 글자수 엄수 필수]

③ interpretation: 100자 이상 155자 이하 (절대 초과 금지)
구조: ①저자·화자가 처한 구체적 상황 1문장 → ②구절 핵심 의미 1~2문장 → ③오늘 유저에게 연결 1문장
- 반드시 저자가 처한 실제 역사적·개인적 상황으로 시작 (성경 배경 기반)
- 원어(히브리어·헬라어) 단어 직접 표기 절대 금지
- 말투: ~야, ~이야, ~거야, ~있어 / 금지: ~이다, ~합니다, 설교조

④ application: 45자 이상 78자 이하 (절대 초과 금지)
- "${zone.appCtx}" 상황이 문장 배경에 자연스럽게 느껴져야 함
- 오늘 바로 실천 가능한 구체적 행동 1가지
- 말투: ~해봐, ~기억해, ~말해봐 / 금지: 반드시, 꼭, ~해야 한다

⑥ question: 32자 이상 80자 이하 (절대 초과 금지)
- verse_full_ko 핵심 메시지와 일상 삶 연결
- 닉네임 없이 (앱이 "{name}님, " 자동 합성)
- 일반 어투: ~있었어?, ~해봤어?, ~인 적 있어? (존댓말 금지)
- 신앙 행위 점검 형태 금지 ("기도했어?", "말씀 읽었어?" 등)

[자기검증 — 출력 전 반드시 확인]
작성 후 각 필드의 글자수를 직접 세어봐. 범위를 벗어나면 즉시 다시 작성해.
- interpretation: ${LIMITS.interpretation.min}~${LIMITS.interpretation.max}자
- application: ${LIMITS.application.min}~${LIMITS.application.max}자
- question: ${LIMITS.question.min}~${LIMITS.question.max}자

[출력: JSON만]
{"interpretation": "...", "application": "...", "question": "..."}`;
}

async function callSonnet(prompt) {
  const msg = await anthropic.messages.create({
    model: 'claude-sonnet-4-6', max_tokens: 600,
    messages: [{ role: 'user', content: prompt }],
  });
  const raw = msg.content[0].text.trim()
    .replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  return JSON.parse(raw);
}

function checkLimits(result) {
  const fails = [];
  for (const [field, { min, max }] of Object.entries(LIMITS)) {
    const len = (result[field] || '').length;
    if (len < min) fails.push(`${field}: ${len}자 (최소 ${min}자)`);
    if (len > max) fails.push(`${field}: ${len}자 (최대 ${max}자)`);
  }
  return fails;
}

async function regenerate(doc) {
  const d = doc.data;
  const modes   = Array.isArray(d.mode) ? d.mode : [d.mode || 'all'];
  const primary = modes[0];
  const zone    = ZONE_CONTEXT[primary] || ZONE_CONTEXT.all;

  // 1차 생성
  let result = await callSonnet(buildPrompt(d, zone, primary));
  let fails  = checkLimits(result);

  // 글자수 실패 시 1회 재생성 (초과 필드 명시)
  if (fails.length > 0) {
    const retryPrompt = buildPrompt(d, zone, primary) +
      `\n\n[재생성 요청] 아래 필드가 글자수 범위를 벗어났어. 해당 필드만 다시 작성해:\n` +
      fails.map(f => `- ${f}`).join('\n');
    const retry = await callSonnet(retryPrompt);
    // 실패 필드만 교체
    for (const [field, { min, max }] of Object.entries(LIMITS)) {
      const len = (result[field] || '').length;
      if (len < min || len > max) result[field] = retry[field];
    }
  }

  return result;
}

async function main() {
  console.log(`=== regenerate_content.js | dry-run: ${isDryRun} | Sonnet ===\n`);

  const snap = await db.collection('verses').where('status', '==', 'active').get();
  const docs = [];
  snap.forEach(docSnap => {
    const num = parseInt(docSnap.id.replace(/\D/g, ''));
    if (num >= 181) return;                                              // 새 39개 제외
    if (rangeFilter && (num < rangeFilter.start || num > rangeFilter.end)) return;
    docs.push({ id: docSnap.id, ref: docSnap.ref, data: docSnap.data() });
  });
  docs.sort((a, b) => parseInt(a.id.replace(/\D/g, '')) - parseInt(b.id.replace(/\D/g, '')));

  console.log(`대상: ${docs.length}개 (v_001~v_180 active)\n`);

  let success = 0, errors = 0;
  const errorLog = [];

  for (let i = 0; i < docs.length; i++) {
    const doc = docs[i];
    process.stdout.write(`[${i+1}/${docs.length}] ${doc.id} (${doc.data.reference}) ... `);

    try {
      const result = await regenerate(doc);

      if (isDryRun) {
        console.log('\n  interp:', result.interpretation.slice(0, 50));
        console.log('  app:   ', result.application.slice(0, 50));
        console.log('  q:     ', result.question.slice(0, 50));
      } else {
        await doc.ref.update({
          interpretation: result.interpretation,
          application:    result.application,
          question:       result.question,
          qa_status:      'draft',      // QA 재검증 필요
          qa_issues:      [],
          curated:        false,
        });
        console.log(`완료`);
        success++;
      }
    } catch (e) {
      console.log(`오류: ${e.message}`);
      errors++;
      errorLog.push({ id: doc.id, error: e.message });
    }

    if (i < docs.length - 1) await new Promise(r => setTimeout(r, 700));
  }

  console.log(`\n===== 완료 =====`);
  if (isDryRun) console.log(`dry-run: ${docs.length}개 미리보기`);
  else {
    console.log(`성공: ${success}개 | 오류: ${errors}개`);
    if (errorLog.length) errorLog.forEach(e => console.log(` - ${e.id}: ${e.error}`));
    console.log('\n다음 단계:');
    console.log('  node qa_auto_check.js');
    console.log('  node qa_ai_check.js');
    console.log('  node qa_approve.js');
  }
}

main().catch(console.error).finally(() => process.exit());
