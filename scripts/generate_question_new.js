require('dotenv').config();
/**
 * generate_question_new.js
 *
 * Firestore verses 컬렉션에서 question 필드가 null/비어있는 문서를 찾아,
 * Claude API로 콘텐츠를 생성한 뒤 업로드합니다.
 *
 * ── 필드 규격 ──────────────────────────────────────────────────
 * question
 *   분량: 40~80자
 *   형식: 질문형 1~2문장
 *   톤: 따뜻하고 개인적, 말씀 핵심과 일상 연결
 *   금지: 닉네임 직접 포함, 설교조, 부담스러운 신앙 점검
 *   예시: "오늘 이 말씀이 가장 필요한 순간은 언제일까요?"
 * ────────────────────────────────────────────────────────────────
 *
 * 사용법:
 *   # 빈 필드가 있는 전체 말씀 처리 (dry-run 미리보기)
 *   node generate_question_new.js --dry-run
 *
 *   # 실제 업로드
 *   node generate_question_new.js
 *
 *   # 특정 verse ID만 처리 (쉼표 구분)
 *   node generate_question_new.js --ids v_102,v_103,v_104
 *
 *   # 특정 범위 처리
 *   node generate_question_new.js --range v_102,v_180
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

const targetIds = (() => {
  const idx = args.indexOf('--ids');
  if (idx === -1) return null;
  return args[idx + 1].split(',').map(s => s.trim()).filter(Boolean);
})();

// --range v_102,v_180 형식으로 범위 지정 가능
const rangeFilter = (() => {
  const idx = args.indexOf('--range');
  if (idx === -1) return null;
  const parts = args[idx + 1].split(',').map(s => s.trim());
  if (parts.length !== 2) return null;
  return { start: parts[0], end: parts[1] };
})();

// ── 필드 누락 여부 확인 ──────────────────────────────────────────
function isMissing(value) {
  return value === undefined || value === null || value === '';
}

// ── ID 정렬용 숫자 추출 ──────────────────────────────────────────
function extractNumber(id) {
  const match = id.match(/(\d+)$/);
  return match ? parseInt(match[1], 10) : 0;
}

// ── 프롬프트 빌더 ──────────────────────────────────────────────
function buildPrompt(doc) {
  const ref = doc.reference || '';
  const verseText = doc.verse_short_ko || doc.text_ko || doc.verseShortKo || doc.textKo || '';
  const interpretation = doc.interpretation || '';
  const application = doc.application || '';

  const system = `너는 DailyVerse 앱의 콘텐츠 작성자야.
성경 말씀을 읽은 사용자에게 보여줄 묵상 질문을 한 문장으로 작성해.
질문은 따뜻하고 개인적인 톤으로, 말씀의 핵심을 일상과 연결해야 해.
닉네임은 포함하지 마. 설교조나 신앙 점검 형태는 금지야.`;

  const user = `다음 성경 말씀에 대한 question을 작성해줘.

말씀: ${verseText}
출처: ${ref}
${interpretation ? `해석: ${interpretation}` : ''}
${application ? `적용: ${application}` : ''}

규칙:
- 40~80자 이내 (공백 포함)
- 질문형 1~2문장
- 따뜻하고 개인적인 톤
- 말씀 핵심과 독자의 일상을 자연스럽게 연결
- 닉네임 직접 포함 금지 ("당신", "오늘" 등 일반 호칭만 사용)
- 설교조, 훈계조, 신앙 점검 형태 금지
- 원어 표기(히브리어, 헬라어) 금지
- 예시 스타일: "오늘 이 말씀이 가장 필요한 순간은 언제일까요?"

출력은 JSON만: {"question": "..."}`;

  return { system, user };
}

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateQuestion(doc) {
  const { system, user } = buildPrompt(doc);

  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 256,
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

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('=== generate_question_new.js ===');
  console.log(`dry-run: ${isDryRun} | 대상: ${targetIds ? targetIds.join(', ') : rangeFilter ? `${rangeFilter.start}~${rangeFilter.end}` : '자동 감지 (question null/빈값)'}\n`);

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
      .filter(s => {
        const data = s.data();
        if (!isMissing(data.question)) return false; // 이미 있으면 스킵

        // 범위 필터 적용
        if (rangeFilter) {
          const num = extractNumber(s.id);
          const startNum = extractNumber(rangeFilter.start);
          const endNum = extractNumber(rangeFilter.end);
          return num >= startNum && num <= endNum;
        }
        return true;
      })
      .map(s => ({ id: s.id, data: s.data(), ref: s.ref }));
  }

  if (docs.length === 0) {
    console.log('처리할 말씀이 없습니다. 모든 question 필드가 이미 채워져 있어요.');
    process.exit(0);
  }

  // ID 순서대로 정렬
  docs.sort((a, b) => extractNumber(a.id) - extractNumber(b.id));

  console.log(`처리 대상: ${docs.length}개 말씀\n`);

  // 2) 생성 및 업로드
  let success = 0;
  let errors = 0;
  const errorLog = [];

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const refText = data.reference || id;
    const verseText = data.verse_short_ko || data.text_ko || '';
    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) 생성 중...`);

    try {
      const generated = await generateQuestion(data);
      const question = generated.question || '';

      // 분량 검증 (경고만, 업로드는 진행)
      const len = question.length;
      if (len < 40) {
        process.stdout.write(` ⚠️ 너무 짧음 ${len}자`);
      } else if (len > 80) {
        process.stdout.write(` ⚠️ 너무 김 ${len}자`);
      }

      if (isDryRun) {
        console.log(' [dry-run 미리보기]');
        console.log(`  verse: ${verseText.slice(0, 30)}...`);
        console.log(`  question: ${question} (${len}자)`);
      } else {
        await ref.update({ question });
        console.log(` 완료 → "${question}" (${len}자)`);
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
