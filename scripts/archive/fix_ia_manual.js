/**
 * fix_ia_manual.js
 *
 * 남은 5건을 직접 값을 추출하거나 강제로 처리합니다.
 * Claude 응답에서 JSON 부분만 정규식으로 추출합니다.
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

// ── 처리 대상 ──────────────────────────────────────────────────
const TARGETS = ['v_070', 'v_071', 'v_086', 'v_047', 'v_050'];

// ── 응답에서 application 값 추출 ──────────────────────────────
function extractApplication(raw) {
  // 1. 순수 JSON 파싱 시도
  const jsonStr = raw
    .replace(/^```json\n?/, '')
    .replace(/^```\n?/, '')
    .replace(/\n?```$/, '')
    .trim();

  // JSON 객체 패턴만 추출 (첫 번째 { ... } 블록)
  const jsonMatch = jsonStr.match(/\{[^{}]*"application"\s*:\s*"([^"]+)"[^{}]*\}/);
  if (jsonMatch) {
    return jsonMatch[1];
  }

  // 2. "application": "..." 패턴 직접 추출
  const directMatch = raw.match(/"application"\s*:\s*"([^"]+)"/);
  if (directMatch) {
    return directMatch[1];
  }

  // 3. 마지막 따옴표 묶음 추출 (긴 문장)
  const quoteMatches = raw.match(/"([^"]{20,}?)"/g);
  if (quoteMatches && quoteMatches.length > 0) {
    // application 관련 마지막 긴 문장 선택
    const candidates = quoteMatches
      .map(m => m.slice(1, -1))
      .filter(m => m.length >= 20 && !m.includes('application') && !m.includes('현재'));
    if (candidates.length > 0) {
      return candidates[candidates.length - 1];
    }
  }

  return null;
}

// ── 프롬프트 빌더 ──────────────────────────────────────────────
function buildPrompt(doc, currentAppl) {
  const ref = doc.reference || '';
  const textKo = doc.text_ko || doc.textKo || '';
  const textFullKo = doc.text_full_ko || doc.textFullKo || '';
  const theme = Array.isArray(doc.theme) ? doc.theme.join(', ') : (doc.theme || '');

  const system = `너는 DailyVerse 앱의 콘텐츠 편집자야.
반드시 JSON만 출력해. 설명이나 글자수 계산 등 다른 텍스트는 절대 출력하지 마.
출력 형식: {"application": "텍스트"}
문자열 안에 큰따옴표(")를 절대 쓰지 마. 작은따옴표(')를 써.`;

  const user = `성경 ${ref} 말씀의 application 필드를 개선해줘.
현재: ${currentAppl}
규격: 49~73자, ~해봐/~기억해/~생각해봐 말투, 오늘 할 수 있는 행동 1가지
JSON만 출력: {"application": "개선된 텍스트"}`;

  return { system, user };
}

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateFix(doc, currentAppl) {
  const { system, user } = buildPrompt(doc, currentAppl);

  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 256,
    system,
    messages: [{ role: 'user', content: user }],
  });

  const raw = message.content[0].text.trim();
  const value = extractApplication(raw);

  if (!value) {
    throw new Error(`값 추출 실패 (raw: ${raw.slice(0, 200)})`);
  }

  return value;
}

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('=== fix_ia_manual.js ===');
  console.log(`처리 대상: ${TARGETS.join(', ')}\n`);

  const snapshots = await Promise.all(
    TARGETS.map(id => db.collection('verses').doc(id).get())
  );

  const docs = snapshots
    .filter(s => s.exists)
    .map(s => ({ id: s.id, data: s.data(), ref: s.ref }));

  let success = 0;
  let errors = 0;

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const refText = data.reference || id;
    const currentAppl = data.application || '';

    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) 생성 중...`);

    try {
      const value = await generateFix(data, currentAppl);
      const len = value.length;

      if (len < 49 || len > 73) {
        process.stdout.write(` ⚠️ 길이 ${len}자`);
      }

      await ref.update({ application: value });
      console.log(` 완료 (${len}자): ${value}`);
      success++;
    } catch (e) {
      console.log(` 오류: ${e.message.slice(0, 150)}`);
      errors++;
    }

    if (i < docs.length - 1) {
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  console.log('\n===== 완료 =====');
  console.log(`성공: ${success}개 | 오류: ${errors}개`);
  process.exit(0);
}

main().catch(e => {
  console.error('예상치 못한 오류:', e);
  process.exit(1);
});
