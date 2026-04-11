/**
 * fix_contemplation_ko.js
 *
 * contemplation_ko 필드가 50자 미달인 구절을 Firestore에서 읽어,
 * Claude API로 50~200자로 확장한 뒤 업데이트합니다.
 *
 * 필드 규격:
 *   - 분량: 50~200자
 *   - 용도: 묵상 S2 읽기 섹션에 표시되는 구절
 *   - 형식: 성경 구절 의역 (verse_full_ko와 달라도 됨, 더 확장된 구절 가능)
 *   - 말투: 성경 인용체 (의역 허용)
 *   - 톤: 천천히 읽을 수 있는 구절, verse_short_ko보다 깊이 있게
 *
 * 사용법:
 *   ANTHROPIC_API_KEY="..." node fix_contemplation_ko.js
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
const TARGET_IDS = [
  'v_038', 'v_039', 'v_055', 'v_057',
];

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateContemplationKo(data) {
  const ref = data.reference || '';
  const verseShortKo = data.verse_short_ko || data.text_ko || '';
  const verseFullKo = data.verse_full_ko || data.text_full_ko || '';
  const currentContemplationKo = data.contemplation_ko || '';

  const system = `너는 DailyVerse 앱의 묵상 구절 작성자야.
사용자가 묵상할 때 천천히 읽는 성경 구절을 의역 형태로 작성해.
말투는 성경 인용체 또는 친근한 의역체로, 읽는 사람이 말씀을 깊이 음미할 수 있게 써.
원어 표기(히브리어, 헬라어)는 절대 사용하지 마.
반드시 50자 이상 200자 이하로 작성해.`;

  const user = `다음 성경 말씀의 contemplation_ko를 50~200자로 확장해줘.

## 말씀 정보
- 성경 참조: ${ref}
- 핵심 구절(카드용): ${verseShortKo}
- 전체 구절: ${verseFullKo || verseShortKo}
- 현재 contemplation_ko (50자 미달): ${currentContemplationKo || '(없음)'}

## 작성 지침
- 현재 내용의 의미를 유지하면서 더 풍부하게 확장해
- 같은 성경 구절의 앞뒤 문맥을 포함하거나, 현재 의역을 더 완전하게 만들어
- 성경 인용체 또는 친근한 의역체로 작성
- 사용자가 묵상 시 천천히 읽을 수 있는 구절로 만들어
- verse_short_ko보다 깊이 있고, 묵상에 적합한 형태로
- 반드시 50자 이상 200자 이하

## 출력 형식 (JSON만 출력, 다른 텍스트 없이)
{"contemplation_ko": "..."}`;

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

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('=== fix_contemplation_ko.js ===');
  console.log(`대상: ${TARGET_IDS.length}개 구절\n`);

  // 1) Firestore에서 대상 문서 수집
  console.log('Firestore에서 문서 읽는 중...');
  const snapshots = await Promise.all(
    TARGET_IDS.map(id => db.collection('verses').doc(id).get())
  );

  const docs = [];
  const missingIds = [];
  for (let i = 0; i < TARGET_IDS.length; i++) {
    const snap = snapshots[i];
    if (!snap.exists) {
      missingIds.push(TARGET_IDS[i]);
    } else {
      docs.push({ id: snap.id, data: snap.data(), ref: snap.ref });
    }
  }

  if (missingIds.length) {
    console.warn(`경고: 존재하지 않는 ID: ${missingIds.join(', ')}`);
  }

  console.log(`처리 대상: ${docs.length}개 말씀\n`);

  // 2) 생성 및 업로드
  let success = 0;
  let errors = 0;
  const errorLog = [];

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const refText = data.reference || id;
    const currentLen = (data.contemplation_ko || '').length;
    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) | 현재 ${currentLen}자 → 생성 중...`);

    try {
      const generated = await generateContemplationKo(data);
      const newText = generated.contemplation_ko;

      if (!newText) {
        throw new Error('contemplation_ko 필드가 비어있음');
      }

      const newLen = newText.length;
      if (newLen < 50 || newLen > 200) {
        process.stdout.write(` ⚠️ 길이 ${newLen}자 (범위 외)`);
      }

      await ref.update({ contemplation_ko: newText });
      console.log(` 완료 (${newLen}자)`);
      success++;
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
  console.log(`성공: ${success}개 | 오류: ${errors}개`);

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
