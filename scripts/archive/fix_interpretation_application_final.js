/**
 * fix_interpretation_application_final.js
 *
 * 2차 재처리에서 남은 오류(1건) + 길이 미달 건(4건)을 최종 처리합니다.
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

// ── 최종 재처리 대상 ──────────────────────────────────────────
// JSON 파싱 오류 1건
const APPL_IDS = ['v_070', 'v_071', 'v_086', 'v_047', 'v_050'];
const ALL_IDS = APPL_IDS;

// ── 프롬프트 빌더 ──────────────────────────────────────────────
function buildPrompt(doc, currentAppl) {
  const ref = doc.reference || '';
  const textKo = doc.text_ko || doc.textKo || '';
  const textFullKo = doc.text_full_ko || doc.textFullKo || '';
  const theme = Array.isArray(doc.theme) ? doc.theme.join(', ') : (doc.theme || '');

  const system = `너는 DailyVerse 앱의 콘텐츠 편집자야.
크리스천 청년/성인 독자를 위해 성경 말씀 기반 묵상 텍스트를 개선해.
말투는 친근하고 따뜻하게, ~해봐, ~기억해, ~생각해봐 체를 사용해.
설교조나 훈계조는 금지야. 친구에게 말하듯 자연스럽게 써.
JSON 출력 시 문자열 안에 큰따옴표(")를 절대 사용하지 마. 작은따옴표(')나 다른 표현으로 대체해.`;

  const user = `다음 성경 말씀의 application 필드를 가이드라인에 맞게 개선해줘.

## 말씀 정보
- 성경 참조: ${ref}
- 핵심 구절(카드용): ${textKo}
- 전체 구절: ${textFullKo || textKo}
- 테마: ${theme}

## application (일상 적용) 개선 지침
- 분량: 반드시 49자 이상 73자 이하 (공백 포함). 글자수를 꼭 세어봐.
- 구조: 오늘 바로 할 수 있는 구체적 행동 1가지
- 말투: ~해봐, ~기억해, ~생각해봐
- 금지: ~해야 한다, ~해야 해, 설교조, 큰따옴표(") 사용 금지
- 현재 값 (길이 조정 필요): ${currentAppl}

## 출력 형식 (순수 JSON만, 마크다운 코드블록 없이)
{"application": "..."}`;

  return { system, user };
}

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateFix(doc, currentAppl) {
  const { system, user } = buildPrompt(doc, currentAppl);

  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 512,
    system,
    messages: [{ role: 'user', content: user }],
  });

  const raw = message.content[0].text.trim();

  // JSON 파싱 (코드 블록 래핑 제거 포함, 큰따옴표 이스케이프 정규화)
  let jsonStr = raw
    .replace(/^```json\n?/, '')
    .replace(/^```\n?/, '')
    .replace(/\n?```$/, '')
    .trim();

  try {
    return JSON.parse(jsonStr);
  } catch {
    // 유니코드 큰따옴표 → 작은따옴표로 치환 후 재시도
    const cleaned = jsonStr
      .replace(/\u201c|\u201d/g, "'")  // " " → '
      .replace(/(?<!\\)"/g, (m, offset, str) => {
        // JSON 구조 키/값 구분 부분(맨 앞뒤, 콜론 근처)이면 유지, 아니면 작은따옴표
        return m;
      });
    try {
      return JSON.parse(cleaned);
    } catch {
      throw new Error(`JSON 파싱 실패 (raw: ${raw.slice(0, 300)})`);
    }
  }
}

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('=== fix_interpretation_application_final.js ===');
  console.log(`처리 대상: ${ALL_IDS.join(', ')}\n`);

  const snapshots = await Promise.all(
    ALL_IDS.map(id => db.collection('verses').doc(id).get())
  );

  const docs = snapshots
    .filter(s => s.exists)
    .map(s => ({ id: s.id, data: s.data(), ref: s.ref }));

  let success = 0;
  let errors = 0;
  const errorLog = [];

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const refText = data.reference || id;
    const currentAppl = data.application || '';

    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) application 생성 중...`);

    try {
      const generated = await generateFix(data, currentAppl);

      if (generated.application) {
        const len = generated.application.length;
        if (len < 49 || len > 73) {
          process.stdout.write(` ⚠️ 길이 ${len}자`);
        }
        await ref.update({ application: generated.application });
        console.log(` 완료 (${len}자)`);
        success++;
      } else {
        console.log(' (application 필드 없음)');
      }
    } catch (e) {
      console.log(` 오류: ${e.message.slice(0, 150)}`);
      errors++;
      errorLog.push({ id, error: e.message });
    }

    if (i < docs.length - 1) {
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  console.log('\n===== 완료 =====');
  console.log(`성공: ${success}개 | 오류: ${errors}개`);

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
