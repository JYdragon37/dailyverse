/**
 * fix_contemplation_interp_appl.js
 *
 * contemplation_interpretation (80자 미달 50건)과
 * contemplation_appliance (40자 미달 6건)을 가이드라인에 맞게 재생성합니다.
 *
 * 필드 규격:
 *   contemplation_interpretation: 80~150자, ~야/~이야/~거야, 구절배경→핵심의미→묵상연결
 *   contemplation_appliance:      40~80자,  ~해봐/~기억해/~생각해봐, 오늘 실천 행동/태도 1가지
 *
 * 사용법:
 *   ANTHROPIC_API_KEY="..." node fix_contemplation_interp_appl.js
 */

const admin = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const serviceAccount = require('./serviceAccountKey.json');

// ── 초기화 ──────────────────────────────────────────────────────
if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
  console.error('오류: ANTHROPIC_API_KEY 환경 변수가 설정되지 않았습니다.');
  process.exit(1);
}
const anthropic = new Anthropic({ apiKey });

// ── 수정 대상 ID ─────────────────────────────────────────────────
const INTERP_IDS = [
  'v_035','v_050',
  'v_004','v_009','v_076','v_089',
];

const APPL_IDS = [];

// ── 프롬프트 빌더 ─────────────────────────────────────────────────
function buildPrompt(doc, mode) {
  const ref       = doc.reference || '';
  const textKo    = doc.text_ko || doc.textKo || '';
  const textFullKo= doc.text_full_ko || doc.textFullKo || '';
  const contKo    = doc.contemplation_ko || '';
  const theme     = Array.isArray(doc.theme) ? doc.theme.join(', ') : (doc.theme || '');
  const existInterp = doc.contemplation_interpretation || '';
  const existAppl   = doc.contemplation_appliance || '';

  const system = `너는 DailyVerse 앱의 묵상 콘텐츠 작성자야.
크리스천 청년/성인 독자를 위해 성경 말씀 기반의 묵상 텍스트를 작성해.
말투는 친근하고 따뜻하게, 반드시 ~야, ~이야, ~거야 체를 사용해 (contemplation_interpretation).
원어 표기(히브리어, 헬라어)는 절대 사용하지 마.
설교조나 훈계조도 금지야. 친구에게 말하듯 자연스럽게 써.`;

  const fieldInstructions = [];

  if (mode === 'both' || mode === 'interpretation') {
    fieldInstructions.push(`
## contemplation_interpretation (묵상 해석)
- 분량: 반드시 80자 이상 150자 이하 (공백 포함, 150자를 절대 넘지 마)
- 150자 넘으면 실패야. 반드시 150자 안에 끝내.
- 구조: ① 구절이 쓰인 상황/배경 1문장(짧게) → ② 핵심 의미 1문장 → ③ 묵상 연결 1문장
- 말투: ~야, ~이야, ~거야
- 금지: 원어 표기, 설교조, ~해야 한다
- 기존 내용(참고용): ${existInterp}`);
  }

  if (mode === 'both' || mode === 'appliance') {
    fieldInstructions.push(`
## contemplation_appliance (묵상 일상 적용)
- 분량: 반드시 40자 이상 80자 이하 (공백 포함, 글자 수를 꼭 지켜)
- 구조: 오늘 바로 실천할 수 있는 구체적 행동 또는 태도 1가지
- 말투: ~해봐, ~기억해, ~생각해봐
- 금지: ~해야 한다, ~해야 해, 설교조
- 기존 내용(참고용): ${existAppl}`);
  }

  const user = `다음 성경 말씀에 대한 묵상 콘텐츠를 작성해줘.

## 말씀 정보
- 성경 참조: ${ref}
- 핵심 구절(카드용): ${textKo}
- 전체 구절: ${textFullKo || textKo}
- 묵상 읽기 구절(contemplation_ko): ${contKo || textKo}
- 테마: ${theme}

## 작성 필드
${fieldInstructions.join('\n')}

## 출력 형식 (JSON만 출력, 다른 텍스트 없이)
${mode === 'both' ? `{
  "contemplation_interpretation": "...",
  "contemplation_appliance": "..."
}` : mode === 'interpretation' ? `{
  "contemplation_interpretation": "..."
}` : `{
  "contemplation_appliance": "..."
}`}`;

  return { system, user };
}

// ── Claude API 호출 ───────────────────────────────────────────────
async function generateFields(doc, mode) {
  const { system, user } = buildPrompt(doc, mode);

  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 512,
    system,
    messages: [{ role: 'user', content: user }],
  });

  const raw = message.content[0].text.trim();
  const jsonStr = raw.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  try {
    return JSON.parse(jsonStr);
  } catch {
    throw new Error(`JSON 파싱 실패 (raw: ${raw.slice(0, 200)})`);
  }
}

// ── sleep 헬퍼 ────────────────────────────────────────────────────
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// ── 메인 ─────────────────────────────────────────────────────────
async function main() {
  console.log('=== fix_contemplation_interp_appl.js ===');

  // 처리 대상 맵 구성: id → 필요한 mode
  const targetMap = new Map(); // id → 'interpretation' | 'appliance' | 'both'

  for (const id of INTERP_IDS) {
    targetMap.set(id, 'interpretation');
  }
  for (const id of APPL_IDS) {
    if (targetMap.has(id)) {
      targetMap.set(id, 'both'); // 두 필드 모두 수정 필요
    } else {
      targetMap.set(id, 'appliance');
    }
  }

  const allIds = [...targetMap.keys()];
  console.log(`처리 대상: ${allIds.length}개 (interpretation: ${INTERP_IDS.length}건, appliance: ${APPL_IDS.length}건, 중복: ${INTERP_IDS.filter(id => APPL_IDS.includes(id)).length}건)\n`);

  // Firestore에서 문서 일괄 조회
  console.log('Firestore 문서 로딩 중...');
  const snapshots = await Promise.all(
    allIds.map(id => db.collection('verses').doc(id).get())
  );

  const docs = [];
  for (const snap of snapshots) {
    if (!snap.exists) {
      console.warn(`⚠️  문서 없음: ${snap.id}`);
    } else {
      docs.push({ id: snap.id, data: snap.data(), ref: snap.ref });
    }
  }
  console.log(`로딩 완료: ${docs.length}개\n`);

  let success = 0;
  let errors  = 0;
  const errorLog = [];
  const warnings = [];

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const mode = targetMap.get(id);
    const refText = data.reference || id;

    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) [${mode}] 생성 중...`);

    try {
      const generated = await generateFields(data, mode);

      // 분량 검증
      let warn = '';
      if (generated.contemplation_interpretation) {
        const len = generated.contemplation_interpretation.length;
        if (len < 80 || len > 150) {
          warn += ` ⚠️ interp ${len}자`;
          warnings.push({ id, field: 'interpretation', len });
        }
      }
      if (generated.contemplation_appliance) {
        const len = generated.contemplation_appliance.length;
        if (len < 40 || len > 80) {
          warn += ` ⚠️ appl ${len}자`;
          warnings.push({ id, field: 'appliance', len });
        }
      }

      await ref.update(generated);
      console.log(` ✓${warn}`);
      success++;
    } catch (e) {
      console.log(` ✗ 오류: ${e.message}`);
      errors++;
      errorLog.push({ id, error: e.message });
    }

    // 요청 간 1500ms 대기 (rate limit 방지)
    if (i < docs.length - 1) {
      await sleep(1500);
    }
  }

  // ── 결과 요약 ────────────────────────────────────────────────────
  console.log('\n===== 완료 =====');
  console.log(`성공: ${success}개 | 오류: ${errors}개`);

  if (warnings.length) {
    console.log(`\n길이 경고 (업로드는 완료됨):`);
    warnings.forEach(({ id, field, len }) =>
      console.log(`  ${id} [${field}]: ${len}자`)
    );
  }

  if (errorLog.length) {
    console.log('\n오류 목록:');
    errorLog.forEach(({ id, error }) => console.log(`  ${id}: ${error}`));
  }

  process.exit(0);
}

main().catch(e => {
  console.error('예상치 못한 오류:', e);
  process.exit(1);
});
