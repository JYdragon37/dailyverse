/**
 * fix_interpretation_application.js
 *
 * Firestore verses 컬렉션의 interpretation(9건)과 application(43건) 필드를
 * 가이드라인에 맞게 배치 수정합니다.
 *
 * ── 필드 규격 ─────────────────────────────────────────────────────
 * interpretation
 *   분량: 102~154자
 *   구조: ① 성경배경 → ② 핵심의미 → ③ 오늘연결
 *   말투: ~야/~이야/~거야
 *   금지: 원어표기, 설교조
 *
 * application
 *   분량: 49~73자
 *   구조: 오늘 바로 할 수 있는 행동 1가지
 *   말투: ~해봐/~기억해/~생각해봐
 *   금지: ~해야 한다, 설교조
 * ─────────────────────────────────────────────────────────────────
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

// ── 수정 대상 ID 목록 ──────────────────────────────────────────
const INTERPRETATION_IDS = [
  'v_001', 'v_010', 'v_029', 'v_031', 'v_033',
  'v_034', 'v_036', 'v_038', 'v_085'
];

const APPLICATION_IDS = [
  'v_018', 'v_019', 'v_020', 'v_021', 'v_022',
  'v_025', 'v_028', 'v_029', 'v_030', 'v_031',
  'v_034', 'v_036', 'v_037', 'v_038', 'v_039',
  'v_040', 'v_043', 'v_044', 'v_045', 'v_046',
  'v_047', 'v_050', 'v_051', 'v_052', 'v_053',
  'v_054', 'v_055', 'v_056', 'v_057', 'v_058',
  'v_060', 'v_061', 'v_062', 'v_064', 'v_065',
  'v_066', 'v_067', 'v_068', 'v_069', 'v_070',
  'v_071', 'v_086', 'v_098'
];

// 두 목록 합쳐서 유니크한 ID 목록
const ALL_IDS = [...new Set([...INTERPRETATION_IDS, ...APPLICATION_IDS])];

// ── 프롬프트 빌더 ──────────────────────────────────────────────
function buildPrompt(doc, needsInterp, needsAppl) {
  const ref = doc.reference || '';
  const textKo = doc.text_ko || doc.textKo || '';
  const textFullKo = doc.text_full_ko || doc.textFullKo || '';
  const currentInterp = doc.interpretation || '';
  const currentAppl = doc.application || '';
  const theme = Array.isArray(doc.theme) ? doc.theme.join(', ') : (doc.theme || '');

  const system = `너는 DailyVerse 앱의 콘텐츠 편집자야.
크리스천 청년/성인 독자를 위해 성경 말씀 기반의 묵상 텍스트를 개선해.
말투는 친근하고 따뜻하게, 반드시 ~야, ~이야, ~거야 체를 사용해.
원어 표기(히브리어, 헬라어)는 절대 사용하지 마.
설교조나 훈계조도 금지야. 친구에게 말하듯 자연스럽게 써.
기존 내용을 완전히 새로 쓰는 게 아니라, 핵심 메시지를 유지하면서 길이와 말투만 조정해.`;

  const fieldInstructions = [];

  if (needsInterp) {
    fieldInstructions.push(`
## interpretation (말씀 해석)
- 분량: 102~154자 (공백 포함, 반드시 지킬 것)
- 구조: ① 성경 배경/상황 1문장 → ② 핵심 의미 1~2문장 → ③ 오늘 우리 삶과의 연결 1문장
- 말투: ~야, ~이야, ~거야
- 금지: 원어 표기, 설교조, ~해야 한다
- 현재 값 (개선 필요): "${currentInterp}"
- 핵심 메시지는 유지하면서 위 규격에 맞게 조정해줘`);
  }

  if (needsAppl) {
    fieldInstructions.push(`
## application (일상 적용)
- 분량: 49~73자 (공백 포함, 반드시 지킬 것)
- 구조: 오늘 바로 할 수 있는 구체적 행동 1가지
- 말투: ~해봐, ~기억해, ~생각해봐
- 금지: ~해야 한다, ~해야 해, 설교조
- 현재 값 (개선 필요): "${currentAppl}"
- 핵심 메시지는 유지하면서 위 규격에 맞게 조정해줘`);
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

## 출력 형식 (JSON만 출력, 다른 텍스트 없이)
${JSON.stringify(outputFields, null, 2)}`;

  return { system, user };
}

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateFix(doc, needsInterp, needsAppl) {
  const { system, user } = buildPrompt(doc, needsInterp, needsAppl);

  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 1024,
    system,
    messages: [{ role: 'user', content: user }],
  });

  const raw = message.content[0].text.trim();

  // JSON 파싱 (코드 블록 래핑 제거 포함)
  const jsonStr = raw.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  try {
    return JSON.parse(jsonStr);
  } catch {
    throw new Error(`JSON 파싱 실패 (raw: ${raw.slice(0, 200)})`);
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
  console.log('=== fix_interpretation_application.js ===');
  console.log(`interpretation 수정 대상: ${INTERPRETATION_IDS.length}개`);
  console.log(`application 수정 대상: ${APPLICATION_IDS.length}개`);
  console.log(`총 처리 문서: ${ALL_IDS.length}개 (중복 제외)\n`);

  // 1) Firestore에서 대상 문서 수집
  console.log('Firestore에서 문서 읽는 중...');
  const snapshots = await Promise.all(
    ALL_IDS.map(id => db.collection('verses').doc(id).get())
  );

  const docs = [];
  const missingIds = [];
  for (const snap of snapshots) {
    if (snap.exists) {
      docs.push({ id: snap.id, data: snap.data(), ref: snap.ref });
    } else {
      missingIds.push(snap.id);
    }
  }

  if (missingIds.length) {
    console.warn(`경고: 존재하지 않는 ID: ${missingIds.join(', ')}`);
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

    const needsInterp = INTERPRETATION_IDS.includes(id);
    const needsAppl = APPLICATION_IDS.includes(id);

    const fieldDesc = [
      needsInterp ? 'interpretation' : null,
      needsAppl ? 'application' : null
    ].filter(Boolean).join('+');

    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) [${fieldDesc}] 생성 중...`);

    try {
      const generated = await generateFix(data, needsInterp, needsAppl);

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
      console.log(` 오류: ${e.message}`);
      errors++;
      errorLog.push({ id, error: e.message });
    }

    // API rate limit 방지: 요청 간 400ms 대기
    if (i < docs.length - 1) {
      await new Promise(r => setTimeout(r, 400));
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
    errorLog.forEach(({ id, error }) => console.log(`  ${id}: ${error}`));
  }

  process.exit(0);
}

main().catch(e => {
  console.error('예상치 못한 오류:', e);
  process.exit(1);
});
