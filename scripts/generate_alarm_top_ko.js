require('dotenv').config();
/**
 * generate_alarm_top_ko.js
 *
 * Firestore verses 컬렉션에서 alarm_top_ko 필드가 비어있는 문서를 찾아,
 * Claude API로 콘텐츠를 생성한 뒤 업로드합니다.
 *
 * ── 필드 규격 ──────────────────────────────────────────────────
 * alarm_top_ko
 *   분량: 15~35자
 *   형식: 짧고 강렬한 핵심 문장. 말씀의 핵심 메시지만 압축
 *   말투: 성경 인용체 또는 친근체 (~야, ~이야 둘 다 가능)
 *   주의: verse_short_ko(15~40자)와 달라도 됨. 더 짧고 강렬하게
 * ────────────────────────────────────────────────────────────────
 *
 * 사용법:
 *   # 빈 필드가 있는 전체 말씀 처리 (dry-run 미리보기)
 *   node generate_alarm_top_ko.js --dry-run
 *
 *   # 실제 업로드
 *   node generate_alarm_top_ko.js
 *
 *   # 특정 verse ID만 처리 (쉼표 구분)
 *   node generate_alarm_top_ko.js --ids v_010,v_025,v_030
 *
 *   # dry-run + 특정 ID
 *   node generate_alarm_top_ko.js --dry-run --ids v_001,v_002,v_003
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

// ── 필드 누락 여부 확인 ──────────────────────────────────────────
function isMissing(value) {
  return value === undefined || value === null || value === '';
}

// ── 프롬프트 빌더 ──────────────────────────────────────────────
/**
 * @param {object} doc Firestore 문서 데이터
 * @returns {{ system: string, user: string }}
 */
function buildPrompt(doc) {
  const ref = doc.reference || '';
  const verseShortKo = doc.verse_short_ko || doc.verseShortKo || doc.text_ko || doc.textKo || '';

  const system = `너는 DailyVerse 앱의 콘텐츠 작성자야.
알람 탭 상단에 표시되는 짧고 강렬한 말씀 한 줄을 작성해.
말투는 성경 인용체 또는 친근체(~야, ~이야) 둘 다 가능해.
원어 표기(히브리어, 헬라어)는 절대 사용하지 마.
설교조나 훈계조도 금지야.`;

  const user = `다음 성경 말씀의 alarm_top_ko를 작성해줘.
말씀: ${verseShortKo}
출처: ${ref}

규칙:
- 15~35자 이내 (공백 포함)
- 말씀의 핵심 한 문장만
- 성경 인용체 또는 친근체 (~야, ~이야)
- verse_short_ko보다 더 짧고 강렬하게 압축해도 됨
- 출력은 JSON만: {"alarm_top_ko": "..."}`;

  return { system, user };
}

// ── Claude API 호출 ──────────────────────────────────────────────
async function generateAlarmTopKo(doc) {
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
  console.log('=== generate_alarm_top_ko.js ===');
  console.log(`dry-run: ${isDryRun} | 대상: ${targetIds ? targetIds.join(', ') : '자동 감지'}\n`);

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
      .filter(s => isMissing(s.data().alarm_top_ko))
      .map(s => ({ id: s.id, data: s.data(), ref: s.ref }));
  }

  if (docs.length === 0) {
    console.log('처리할 말씀이 없습니다. 모든 alarm_top_ko 필드가 이미 채워져 있어요.');
    process.exit(0);
  }

  console.log(`처리 대상: ${docs.length}개 말씀\n`);

  // 2) 생성 및 업로드
  let success = 0;
  let errors = 0;
  const errorLog = [];

  for (let i = 0; i < docs.length; i++) {
    const { id, data, ref } = docs[i];
    const refText = data.reference || id;
    const verseShortKo = data.verse_short_ko || data.verseShortKo || data.text_ko || '';
    process.stdout.write(`[${i + 1}/${docs.length}] ${id} (${refText}) 생성 중...`);

    try {
      const generated = await generateAlarmTopKo(data);
      const alarmTopKo = generated.alarm_top_ko || '';

      // 분량 검증 (경고만, 업로드는 진행)
      const len = alarmTopKo.length;
      if (len < 15) {
        process.stdout.write(` ⚠️ 너무 짧음 ${len}자`);
      } else if (len > 35) {
        process.stdout.write(` ⚠️ 너무 김 ${len}자`);
      }

      if (isDryRun) {
        console.log(' [dry-run 미리보기]');
        console.log(`  verse_short_ko: ${verseShortKo}`);
        console.log(`  alarm_top_ko:   ${alarmTopKo} (${len}자)`);
      } else {
        await ref.update({ alarm_top_ko: alarmTopKo });
        console.log(` 완료 → "${alarmTopKo}" (${len}자)`);
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
