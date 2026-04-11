/**
 * fix_interpretation_application_retry.js
 *
 * 1차 실행에서 오류가 난 건들(오류 7건) + 길이 미달/초과 건들(20건)을 재처리합니다.
 * Rate limit 방지를 위해 요청 간 간격을 2초로 늘립니다.
 */

const admin = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const serviceAccount = require('./serviceAccountKey.json');

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

// ── 재처리 대상 ──────────────────────────────────────────────────
// 오류 건 (7건)
const ERROR_INTERP_IDS = ['v_033'];
const ERROR_APPL_IDS = ['v_064', 'v_067', 'v_070', 'v_071', 'v_086', 'v_098'];

// 길이 경고 건 (20건) - interpretation 초과: v_001 / application 미달 또는 초과
const WARN_INTERP_IDS = ['v_001'];  // 209자 → 102~154자
const WARN_APPL_IDS = [
  'v_038',  // 43자
  'v_019',  // 40자
  'v_025',  // 48자
  'v_028',  // 48자
  'v_030',  // 45자
  'v_039',  // 44자
  'v_040',  // 47자
  'v_043',  // 44자
  'v_047',  // 44자
  'v_050',  // 41자
  'v_052',  // 41자
  'v_056',  // 42자
  'v_057',  // 41자
  'v_060',  // 42자
  'v_061',  // 48자
  'v_062',  // 41자
  'v_065',  // 85자 (초과)
  'v_068',  // 36자
  'v_069',  // 47자
];

// 처리할 모든 ID 수집 (interpretation, application별로)
const INTERP_IDS = [...new Set([...ERROR_INTERP_IDS, ...WARN_INTERP_IDS])];
const APPL_IDS = [...new Set([...ERROR_APPL_IDS, ...WARN_APPL_IDS])];
const ALL_IDS = [...new Set([...INTERP_IDS, ...APPL_IDS])];

// ── 프롬프트 빌더 ──────────────────────────────────────────────
function buildPrompt(doc, needsInterp, needsAppl, currentInterp, currentAppl) {
  const ref = doc.reference || '';
  const textKo = doc.text_ko || doc.textKo || '';
  const textFullKo = doc.text_full_ko || doc.textFullKo || '';
  const theme = Array.isArray(doc.theme) ? doc.theme.join(', ') : (doc.theme || '');

  const system = `너는 DailyVerse 앱의 콘텐츠 편집자야.
크리스천 청년/성인 독자를 위해 성경 말씀 기반의 묵상 텍스트를 개선해.
말투는 친근하고 따뜻하게, 반드시 ~야, ~이야, ~거야 체를 사용해.
원어 표기(히브리어, 헬라어)는 절대 사용하지 마.
설교조나 훈계조도 금지야. 친구에게 말하듯 자연스럽게 써.
기존 내용의 핵심 메시지를 유지하면서 길이와 말투만 조정해.`;

  const fieldInstructions = [];

  if (needsInterp) {
    const currentLen = currentInterp ? currentInterp.length : 0;
    fieldInstructions.push(`
## interpretation (말씀 해석)
- 분량: 반드시 102자 이상 154자 이하 (공백 포함). 현재 ${currentLen}자이므로 길이를 조정해야 해.
- 구조: ① 성경 배경/상황 1문장 → ② 핵심 의미 1~2문장 → ③ 오늘 우리 삶과의 연결 1문장
- 말투: ~야, ~이야, ~거야
- 금지: 원어 표기, 설교조, ~해야 한다
- 현재 값 (길이 조정 필요): "${currentInterp}"
- 위 내용의 핵심 메시지를 살려서 102~154자 범위 안에 맞게 다시 써줘`);
  }

  if (needsAppl) {
    const currentLen = currentAppl ? currentAppl.length : 0;
    fieldInstructions.push(`
## application (일상 적용)
- 분량: 반드시 49자 이상 73자 이하 (공백 포함). 현재 ${currentLen}자이므로 길이를 조정해야 해.
- 구조: 오늘 바로 할 수 있는 구체적 행동 1가지
- 말투: ~해봐, ~기억해, ~생각해봐
- 금지: ~해야 한다, ~해야 해, 설교조
- 현재 값 (길이 조정 필요): "${currentAppl}"
- 위 내용의 핵심 메시지를 살려서 49~73자 범위 안에 맞게 다시 써줘`);
  }

  const outputFields = {};
  if (needsInterp) outputFields.interpretation = '...';
  if (needsAppl) outputFields.application = '...';

  const user = `다음 성경 말씀의 콘텐츠 필드를 가이드라인에 맞게 개선해줘.

## 말씀 정보
- 성경 참조: ${ref}
- 핵심 구절(카드용): ${textKo}
- 전체 구절: ${textFullKo || textKo}
- 테마: ${theme}

## 개선할 필드
${fieldInstructions.join('\n')}

## 출력 형식 (JSON만 출력, 마크다운 코드블록 없이 순수 JSON만)
${JSON.stringify(outputFields, null, 2)}`;

  return { system, user };
}

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateFix(doc, needsInterp, needsAppl, currentInterp, currentAppl) {
  const { system, user } = buildPrompt(doc, needsInterp, needsAppl, currentInterp, currentAppl);

  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 1024,
    system,
    messages: [{ role: 'user', content: user }],
  });

  const raw = message.content[0].text.trim();

  // JSON 파싱 (코드 블록 래핑 제거 포함)
  const jsonStr = raw
    .replace(/^```json\n?/, '')
    .replace(/^```\n?/, '')
    .replace(/\n?```$/, '')
    .trim();

  try {
    return JSON.parse(jsonStr);
  } catch {
    throw new Error(`JSON 파싱 실패 (raw: ${raw.slice(0, 300)})`);
  }
}

// ── 길이 검증 ──────────────────────────────────────────────────
function validateLengths(generated) {
  const warnings = [];
  if (generated.interpretation) {
    const len = generated.interpretation.length;
    if (len < 102 || len > 154) {
      warnings.push(`interpretation 길이 ${len}자 (기준: 102~154자)`);
    }
  }
  if (generated.application) {
    const len = generated.application.length;
    if (len < 49 || len > 73) {
      warnings.push(`application 길이 ${len}자 (기준: 49~73자)`);
    }
  }
  return warnings;
}

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('=== fix_interpretation_application_retry.js ===');
  console.log(`interpretation 재처리: ${INTERP_IDS.length}개`);
  console.log(`application 재처리: ${APPL_IDS.length}개`);
  console.log(`총 처리 문서: ${ALL_IDS.length}개 (중복 제외)\n`);

  // 1) Firestore에서 대상 문서 수집
  console.log('Firestore에서 문서 읽는 중...');
  const snapshots = await Promise.all(
    ALL_IDS.map(id => db.collection('verses').doc(id).get())
  );

  const docs = [];
  for (const snap of snapshots) {
    if (snap.exists) {
      docs.push({ id: snap.id, data: snap.data(), ref: snap.ref });
    } else {
      console.warn(`경고: 존재하지 않는 ID: ${snap.id}`);
    }
  }
  console.log(`읽기 완료: ${docs.length}개 문서\n`);

  // 2) 생성 및 업로드
  let success = 0;
  let errors = 0;
  const errorLog = [];
  const warningLog = [];

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const refText = data.reference || id;

    const needsInterp = INTERP_IDS.includes(id);
    const needsAppl = APPL_IDS.includes(id);

    const currentInterp = data.interpretation || '';
    const currentAppl = data.application || '';

    const fieldDesc = [
      needsInterp ? 'interpretation' : null,
      needsAppl ? 'application' : null
    ].filter(Boolean).join('+');

    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) [${fieldDesc}] 생성 중...`);

    try {
      const generated = await generateFix(data, needsInterp, needsAppl, currentInterp, currentAppl);

      // 길이 검증
      const warnings = validateLengths(generated);
      if (warnings.length) {
        process.stdout.write(` ⚠️ ${warnings.join(', ')}`);
        warningLog.push({ id, warnings });
      }

      // Firestore 업데이트
      const updateData = {};
      if (needsInterp && generated.interpretation) {
        updateData.interpretation = generated.interpretation;
      }
      if (needsAppl && generated.application) {
        updateData.application = generated.application;
      }

      if (Object.keys(updateData).length > 0) {
        await ref.update(updateData);
        console.log(' 완료');
        success++;
      } else {
        console.log(' (업데이트할 필드 없음)');
      }
    } catch (e) {
      console.log(` 오류: ${e.message.slice(0, 150)}`);
      errors++;
      errorLog.push({ id, error: e.message });
    }

    // Rate limit 방지: 요청 간 2초 대기
    if (i < docs.length - 1) {
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  // 3) 결과 요약
  console.log('\n===== 완료 =====');
  console.log(`성공: ${success}개 | 오류: ${errors}개 | 길이 경고: ${warningLog.length}개`);

  if (warningLog.length) {
    console.log('\n길이 경고 목록:');
    warningLog.forEach(({ id, warnings }) => console.log(`  ${id}: ${warnings.join(', ')}`));
  }

  if (errorLog.length) {
    console.log('\n오류 목록:');
    errorLog.forEach(({ id, error }) => console.log(`  ${id}: ${error.slice(0, 200)}`));
  }

  process.exit(0);
}

main().catch(e => {
  console.error('예상치 못한 오류:', e);
  process.exit(1);
});
