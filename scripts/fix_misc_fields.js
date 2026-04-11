/**
 * fix_misc_fields.js
 *
 * Firestore verses 컬렉션의 4가지 필드를 가이드라인에 맞게 수정합니다.
 *
 * 수정 대상:
 *   alarm_top_ko (15자 미달 → 15~35자로 확장): 15건
 *   question (40자 미달 → 40~80자로 확장): 12건
 *   verse_short_ko (40자 초과 → 40자 이하로 단축): 12건
 *   verse_full_ko (120자 초과 → 120자 이하로 단축): 3건
 *
 * 사용법:
 *   ANTHROPIC_API_KEY="sk-ant-..." node fix_misc_fields.js
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
  process.exit(1);
}
const anthropic = new Anthropic({ apiKey });

// ── 수정 대상 정의 ──────────────────────────────────────────────

const ALARM_TOP_KO_TARGETS = [
  // 이미 완료 — 재실행 방지를 위해 비움
];

const QUESTION_TARGETS = [
  // 재처리 대상만 (rate limit으로 실패한 4건)
  'v_040', 'v_066', 'v_078', 'v_097',
];

const VERSE_SHORT_KO_TARGETS = [
  // 재처리 대상만 (rate limit으로 실패한 1건)
  'v_040',
];

const VERSE_FULL_KO_TARGETS = [
  // 이미 완료 — 재실행 방지를 위해 비움
];

// 전체 처리 대상 verse_id (중복 제거)
const ALL_TARGET_IDS = [
  ...new Set([
    ...ALARM_TOP_KO_TARGETS,
    ...QUESTION_TARGETS,
    ...VERSE_SHORT_KO_TARGETS,
    ...VERSE_FULL_KO_TARGETS,
  ]),
];

// ── Claude API 호출 ──────────────────────────────────────────────

async function callClaude(systemPrompt, userPrompt) {
  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 512,
    system: systemPrompt,
    messages: [{ role: 'user', content: userPrompt }],
  });
  const raw = message.content[0].text.trim();
  const jsonStr = raw.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  try {
    return JSON.parse(jsonStr);
  } catch {
    throw new Error(`JSON 파싱 실패 (raw: ${raw.slice(0, 300)})`);
  }
}

// ── 필드별 프롬프트 ──────────────────────────────────────────────

function buildAlarmTopKoPrompt(doc) {
  const system = `너는 DailyVerse 앱의 콘텐츠 작성자야.
알람 탭 상단에 표시되는 짧고 강렬한 말씀 한 줄을 수정해.
말투: 성경 인용체 또는 친근체(~야, ~이야) 둘 다 가능.
원어 표기(히브리어, 헬라어)는 절대 사용하지 마.
설교조나 훈계조 금지.`;

  const user = `다음 alarm_top_ko가 너무 짧아서 15~35자로 확장해줘.
현재 값: "${doc.alarm_top_ko}"
말씀 요약: ${doc.verse_short_ko || ''}
출처: ${doc.reference || ''}

규칙:
- 반드시 15~35자 (공백 포함)
- 기존 의미를 유지하면서 좀 더 풍성하게 확장
- 성경 인용체 또는 친근체
- 출력은 JSON만: {"alarm_top_ko": "..."}`;

  return { system, user };
}

function buildQuestionPrompt(doc) {
  const system = `너는 DailyVerse 앱의 콘텐츠 작성자야.
말씀을 읽은 사용자에게 건네는 따뜻한 질문을 수정해.
말투: 따뜻하고 개인적인 질문형, 1~2문장.
원어 표기(히브리어, 헬라어) 절대 사용 금지.
설교조나 훈계조 금지.`;

  const user = `다음 question이 너무 짧아서 40~80자로 확장해줘.
현재 값: "${doc.question}"
말씀 요약: ${doc.verse_short_ko || ''}
해석: ${doc.interpretation || ''}
출처: ${doc.reference || ''}

규칙:
- 반드시 40~80자 (공백 포함)
- 기존 질문 의미를 유지하면서 더 구체적이고 따뜻하게 확장
- 말씀 핵심 의미와 일상을 연결하는 질문
- 질문형 1~2문장
- 출력은 JSON만: {"question": "..."}`;

  return { system, user };
}

function buildVerseShortKoPrompt(doc) {
  const system = `너는 DailyVerse 앱의 콘텐츠 작성자야.
말씀 카드에 표시되는 짧은 구절을 수정해.
말투: 현대어 의역, 친근체 또는 성경 인용체.
원어 표기(히브리어, 헬라어) 절대 사용 금지.`;

  const user = `다음 verse_short_ko가 너무 길어서 40자 이하로 줄여줘.
현재 값: "${doc.verse_short_ko}"
전체 구절: ${doc.verse_full_ko || ''}
출처: ${doc.reference || ''}

규칙:
- 반드시 40자 이하 (공백 포함), 최소 15자 이상
- 핵심 메시지만 남기고 간결하게 단축
- 의미는 반드시 유지
- 출력은 JSON만: {"verse_short_ko": "..."}`;

  return { system, user };
}

function buildVerseFullKoPrompt(doc) {
  const system = `너는 DailyVerse 앱의 콘텐츠 작성자야.
말씀 전체 구절 의역을 수정해.
말투: 현대어 의역, 자연스러운 문어체 또는 친근체.
원어 표기(히브리어, 헬라어) 절대 사용 금지.`;

  const user = `다음 verse_full_ko가 너무 길어서 120자 이하로 줄여줘.
현재 값: "${doc.verse_full_ko}"
출처: ${doc.reference || ''}

규칙:
- 반드시 120자 이하 (공백 포함), 최소 40자 이상
- 구절의 핵심 내용 유지, 불필요한 반복 제거
- 의미 훼손 없이 간결하게
- 출력은 JSON만: {"verse_full_ko": "..."}`;

  return { system, user };
}

// ── 메인 ────────────────────────────────────────────────────────

async function main() {
  console.log('=== fix_misc_fields.js ===');
  console.log(`처리 대상 verse_id: ${ALL_TARGET_IDS.length}개 (중복 제거)\n`);

  // 1) Firestore에서 대상 문서 수집
  console.log('Firestore에서 문서 읽는 중...');
  const snapshots = await Promise.all(
    ALL_TARGET_IDS.map(id => db.collection('verses').doc(id).get())
  );

  const docMap = {};
  for (const snap of snapshots) {
    if (snap.exists) {
      docMap[snap.id] = { id: snap.id, data: snap.data(), ref: snap.ref };
    } else {
      console.warn(`경고: 존재하지 않는 ID: ${snap.id}`);
    }
  }
  console.log(`문서 로드 완료: ${Object.keys(docMap).length}개\n`);

  // 2) 필드별 처리 결과 추적
  const results = {
    alarm_top_ko: { success: 0, error: 0, errors: [] },
    question: { success: 0, error: 0, errors: [] },
    verse_short_ko: { success: 0, error: 0, errors: [] },
    verse_full_ko: { success: 0, error: 0, errors: [] },
  };

  // 처리할 작업 목록 생성 (id + field)
  const tasks = [];
  for (const id of ALARM_TOP_KO_TARGETS) {
    if (docMap[id]) tasks.push({ id, field: 'alarm_top_ko' });
  }
  for (const id of QUESTION_TARGETS) {
    if (docMap[id]) tasks.push({ id, field: 'question' });
  }
  for (const id of VERSE_SHORT_KO_TARGETS) {
    if (docMap[id]) tasks.push({ id, field: 'verse_short_ko' });
  }
  for (const id of VERSE_FULL_KO_TARGETS) {
    if (docMap[id]) tasks.push({ id, field: 'verse_full_ko' });
  }

  console.log(`총 ${tasks.length}개 필드 수정 시작\n`);
  console.log('─'.repeat(60));

  for (let i = 0; i < tasks.length; i++) {
    const { id, field } = tasks[i];
    const { data, ref } = docMap[id];

    process.stdout.write(`[${i + 1}/${tasks.length}] ${id}.${field} ... `);

    try {
      let prompt;
      if (field === 'alarm_top_ko') prompt = buildAlarmTopKoPrompt(data);
      else if (field === 'question') prompt = buildQuestionPrompt(data);
      else if (field === 'verse_short_ko') prompt = buildVerseShortKoPrompt(data);
      else if (field === 'verse_full_ko') prompt = buildVerseFullKoPrompt(data);

      const generated = await callClaude(prompt.system, prompt.user);
      const newValue = generated[field];

      if (!newValue) {
        throw new Error(`빈 값 반환 (generated: ${JSON.stringify(generated)})`);
      }

      const len = newValue.length;
      const oldValue = data[field] || '';

      // 분량 검증
      let warning = '';
      if (field === 'alarm_top_ko') {
        if (len < 15 || len > 35) warning = ` ⚠️ ${len}자 (15~35 범위 벗어남)`;
      } else if (field === 'question') {
        if (len < 40 || len > 80) warning = ` ⚠️ ${len}자 (40~80 범위 벗어남)`;
      } else if (field === 'verse_short_ko') {
        if (len > 40 || len < 15) warning = ` ⚠️ ${len}자 (15~40 범위 벗어남)`;
      } else if (field === 'verse_full_ko') {
        if (len > 120 || len < 40) warning = ` ⚠️ ${len}자 (40~120 범위 벗어남)`;
      }

      await ref.update({ [field]: newValue });
      console.log(`완료 (${oldValue.length}자→${len}자)${warning}`);
      console.log(`  이전: ${oldValue}`);
      console.log(`  이후: ${newValue}`);

      results[field].success++;
    } catch (e) {
      console.log(`오류: ${e.message}`);
      results[field].error++;
      results[field].errors.push({ id, error: e.message });
    }

    // 요청 간 300ms 대기
    if (i < tasks.length - 1) {
      await new Promise(r => setTimeout(r, 300));
    }
  }

  // 3) 결과 보고
  console.log('\n' + '═'.repeat(60));
  console.log('## 수정 완료 보고\n');

  const fieldLabels = {
    alarm_top_ko: 'alarm_top_ko (15~35자, 미달→확장)',
    question: 'question (40~80자, 미달→확장)',
    verse_short_ko: 'verse_short_ko (15~40자, 초과→단축)',
    verse_full_ko: 'verse_full_ko (40~120자, 초과→단축)',
  };

  let totalSuccess = 0;
  let totalError = 0;

  for (const [field, stat] of Object.entries(results)) {
    console.log(`### ${fieldLabels[field]}`);
    console.log(`   성공: ${stat.success}건 | 오류: ${stat.error}건`);
    if (stat.errors.length) {
      for (const { id, error } of stat.errors) {
        console.log(`   오류 상세: ${id} — ${error}`);
      }
    }
    totalSuccess += stat.success;
    totalError += stat.error;
  }

  console.log('\n' + '─'.repeat(60));
  console.log(`전체 합계: 성공 ${totalSuccess}건 / 오류 ${totalError}건 / 총 ${tasks.length}건`);

  process.exit(0);
}

main().catch(e => {
  console.error('예상치 못한 오류:', e);
  process.exit(1);
});
