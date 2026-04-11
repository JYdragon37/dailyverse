/**
 * generate_contemplation_fields.js
 *
 * Firestore verses 컬렉션에서 contemplation_interpretation 또는
 * contemplation_appliance 필드가 비어 있는 문서를 찾아,
 * Claude API로 콘텐츠를 생성한 뒤 업로드합니다.
 *
 * ── 필드 규격 ──────────────────────────────────────────────────
 * contemplation_interpretation
 *   분량: 80~150자
 *   구조: ① 구절 배경 1문장 → ② 핵심 의미 1~2문장 → ③ 묵상 연결 1문장
 *   말투: ~야, ~이야, ~거야
 *   금지: 원어 표기, 설교조
 *
 * contemplation_appliance
 *   분량: 40~80자
 *   구조: 오늘 바로 할 수 있는 구체적 행동/태도 1가지
 *   말투: ~해봐, ~기억해, ~생각해봐
 *   금지: ~해야 한다, 설교조
 * ────────────────────────────────────────────────────────────────
 *
 * 사용법:
 *   # 빈 필드가 있는 전체 말씀 처리 (dry-run 미리보기)
 *   node generate_contemplation_fields.js --dry-run
 *
 *   # 실제 업로드
 *   node generate_contemplation_fields.js
 *
 *   # 특정 verse ID만 재생성 (쉼표 구분)
 *   node generate_contemplation_fields.js --ids v_010,v_025,v_030
 *
 *   # 둘 다 비어있는 말씀만 처리 (기본값)
 *   node generate_contemplation_fields.js --mode both
 *
 *   # interpretation만 비어있는 것만 처리
 *   node generate_contemplation_fields.js --mode interpretation
 *
 *   # appliance만 비어있는 것만 처리
 *   node generate_contemplation_fields.js --mode appliance
 *
 * 환경 변수:
 *   ANTHROPIC_API_KEY — Claude API 키 (필수)
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
  console.error('  export ANTHROPIC_API_KEY="sk-ant-..."');
  process.exit(1);
}
const anthropic = new Anthropic({ apiKey });

// ── CLI 인수 파싱 ──────────────────────────────────────────────
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const modeArg = (() => {
  const idx = args.indexOf('--mode');
  return idx !== -1 ? args[idx + 1] : 'both';
})();
const targetIds = (() => {
  const idx = args.indexOf('--ids');
  if (idx === -1) return null;
  return args[idx + 1].split(',').map(s => s.trim()).filter(Boolean);
})();

// ── 프롬프트 빌더 ──────────────────────────────────────────────
/**
 * @param {object} doc Firestore 문서 데이터
 * @param {'both'|'interpretation'|'appliance'} mode
 * @returns {string} Claude에게 보낼 시스템+유저 프롬프트
 */
function buildPrompt(doc, mode) {
  const ref = doc.reference || '';
  const textKo = doc.text_ko || doc.textKo || '';
  const textFullKo = doc.text_full_ko || doc.textFullKo || '';
  const contemplationKo = doc.contemplation_ko || '';
  const theme = Array.isArray(doc.theme) ? doc.theme.join(', ') : (doc.theme || '');

  const system = `너는 DailyVerse 앱의 묵상 콘텐츠 작성자야.
크리스천 청년/성인 독자를 위해 성경 말씀 기반의 묵상 텍스트를 작성해.
말투는 친근하고 따뜻하게, 반드시 ~야, ~이야, ~거야 체를 사용해.
원어 표기(히브리어, 헬라어)는 절대 사용하지 마.
설교조나 훈계조도 금지야. 친구에게 말하듯 자연스럽게 써.`;

  const fieldInstructions = [];

  if (mode === 'both' || mode === 'interpretation') {
    fieldInstructions.push(`
## contemplation_interpretation (묵상 해석)
- 분량: 80~150자 (공백 포함)
- 구조: ① 구절이 쓰인 상황/배경 1문장 → ② 이 구절이 전하는 핵심 의미 1~2문장 → ③ 오늘 이 말씀이 묵상과 어떻게 연결되는지 1문장
- 말투: ~야, ~이야, ~거야
- 금지: 원어 표기, 설교조, ~해야 한다`);
  }

  if (mode === 'both' || mode === 'appliance') {
    fieldInstructions.push(`
## contemplation_appliance (묵상 일상 적용)
- 분량: 40~80자 (공백 포함)
- 구조: 오늘 바로 실천할 수 있는 구체적 행동 또는 태도 1가지
- 말투: ~해봐, ~기억해, ~생각해봐
- 금지: ~해야 한다, ~해야 해, 설교조`);
  }

  const user = `다음 성경 말씀에 대한 묵상 콘텐츠를 작성해줘.

## 말씀 정보
- 성경 참조: ${ref}
- 핵심 구절(카드용): ${textKo}
- 전체 구절: ${textFullKo || textKo}
- 묵상 읽기 구절(contemplation_ko): ${contemplationKo || textKo}
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

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateFields(doc, mode) {
  const { system, user } = buildPrompt(doc, mode);

  const message = await anthropic.messages.create({
    model: 'claude-opus-4-5',
    max_tokens: 512,
    system,
    messages: [{ role: 'user', content: user }],
  });

  const raw = message.content[0].text.trim();

  // JSON 파싱 (코드 블록 래핑 제거 포함)
  const jsonStr = raw.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  try {
    return JSON.parse(jsonStr);
  } catch {
    // 파싱 실패 시 원본 텍스트와 함께 오류 throw
    throw new Error(`JSON 파싱 실패 (raw: ${raw.slice(0, 200)})`);
  }
}

// ── 필드 누락 여부 확인 ──────────────────────────────────────────
function isMissing(value) {
  return value === undefined || value === null || value === '';
}

function needsUpdate(data, mode) {
  if (mode === 'both') {
    return isMissing(data.contemplation_interpretation) || isMissing(data.contemplation_appliance);
  }
  if (mode === 'interpretation') return isMissing(data.contemplation_interpretation);
  if (mode === 'appliance') return isMissing(data.contemplation_appliance);
  return false;
}

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('=== generate_contemplation_fields.js ===');
  console.log(`모드: ${modeArg} | dry-run: ${isDryRun} | 대상: ${targetIds ? targetIds.join(', ') : '자동 감지'}\n`);

  // 1) Firestore에서 대상 문서 수집
  let docs;
  if (targetIds) {
    const snapshots = await Promise.all(
      targetIds.map(id => db.collection('verses').doc(id).get())
    );
    docs = snapshots.filter(s => s.exists).map(s => ({ id: s.id, data: s.data(), ref: s.ref }));
    const missing = targetIds.filter(id => !snapshots.find(s => s.id === id && s.exists));
    if (missing.length) console.warn(`경고: 존재하지 않는 ID: ${missing.join(', ')}`);
  } else {
    console.log('verses 컬렉션 읽는 중...');
    const snapshot = await db.collection('verses').orderBy('__name__').get();
    docs = snapshot.docs
      .filter(s => needsUpdate(s.data(), modeArg))
      .map(s => ({ id: s.id, data: s.data(), ref: s.ref }));
  }

  if (docs.length === 0) {
    console.log('처리할 말씀이 없습니다. 모든 필드가 이미 채워져 있어요.');
    process.exit(0);
  }

  console.log(`처리 대상: ${docs.length}개 말씀\n`);

  // 2) 생성 및 업로드
  let success = 0;
  let errors = 0;
  const errorLog = [];

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const ref_text = data.reference || data.ref || id;
    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${ref_text}) 생성 중...`);

    // 이 문서에서 실제로 비어있는 필드만 타겟
    let effectiveMode = modeArg;
    if (modeArg === 'both') {
      const needsInterp = isMissing(data.contemplation_interpretation);
      const needsAppl = isMissing(data.contemplation_appliance);
      if (!needsInterp && needsAppl) effectiveMode = 'appliance';
      else if (needsInterp && !needsAppl) effectiveMode = 'interpretation';
      else effectiveMode = 'both';
    }

    try {
      const generated = await generateFields(data, effectiveMode);

      // 분량 검증 (경고만, 업로드는 진행)
      if (generated.contemplation_interpretation) {
        const len = generated.contemplation_interpretation.length;
        if (len < 80 || len > 150) {
          process.stdout.write(` ⚠️ interpretation 길이 ${len}자`);
        }
      }
      if (generated.contemplation_appliance) {
        const len = generated.contemplation_appliance.length;
        if (len < 40 || len > 80) {
          process.stdout.write(` ⚠️ appliance 길이 ${len}자`);
        }
      }

      if (isDryRun) {
        console.log(' [dry-run 미리보기]');
        console.log(`  interpretation: ${generated.contemplation_interpretation || '(유지)'}`);
        console.log(`  appliance:      ${generated.contemplation_appliance || '(유지)'}`);
      } else {
        await ref.update(generated);
        console.log(' 완료');
        success++;
      }
    } catch (e) {
      console.log(` 오류: ${e.message}`);
      errors++;
      errorLog.push({ id, error: e.message });
    }

    // API rate limit 방지: 요청 간 300ms 대기
    if (i < docs.length - 1) {
      await new Promise(r => setTimeout(r, 300));
    }
  }

  // 3) 결과 요약
  console.log('\n===== 완료 =====');
  if (isDryRun) {
    console.log(`dry-run 미리보기: ${docs.length}개 (실제 업로드 없음)`);
  } else {
    console.log(`성공: ${success}개 | 오류: ${errors}개`);
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
