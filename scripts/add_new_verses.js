require('dotenv').config();
/**
 * add_new_verses.js — 신규 말씀 39개 일괄 생성 및 Firestore 추가
 *
 * 생성 내용: verse_full_ko(개역한글), verse_short_ko, interpretation,
 *           application(Zone 반영), question
 * QA 초기 상태: status=active, qa_status=draft, curated=false
 *
 * 사용법:
 *   node add_new_verses.js --dry-run   # 미리보기만
 *   node add_new_verses.js             # 실제 생성
 */

const admin    = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) { console.error('ANTHROPIC_API_KEY 필요'); process.exit(1); }
const anthropic = new Anthropic({ apiKey });

const isDryRun = process.argv.includes('--dry-run');

// ── Zone별 유저 상황 (AI 생성 컨텍스트용) ──────────────────────────────────
const ZONE_CONTEXT = {
  deep_dark:   { time: '00~03', desc: '자정~새벽 3시. 잠 못 들고 불안·외로움 속에 깨어 있음', appCtx: '지금 뒤척이고 있는 이 밤, 깊은 어둠 속' },
  first_light: { time: '03~06', desc: '새벽 3~6시. 이른 기도·묵상을 위해 일어남. 하루 전의 고요', appCtx: '새벽의 고요함, 하루가 시작되기 전의 정적' },
  rise_ignite: { time: '06~09', desc: '오전 6~9시. 알람 끄고 이불 속. 나른함+부담+작은 설렘', appCtx: '알람 끄고 30초, 이불 속에서 폰 보는 순간' },
  peak_mode:   { time: '09~12', desc: '오전 9~12시. 업무·공부 집중. 스트레스·책임감', appCtx: '업무·공부 집중 시간, 성과 압박 속' },
  recharge:    { time: '12~15', desc: '오후 12~15시. 점심 후 잠깐 쉬는 시간. 나른함', appCtx: '점심 후 잠깐 쉬는 시간, 폰 보거나 짧은 산책' },
  second_wind: { time: '15~18', desc: '오후 15~18시. 오후 슬럼프. 피로+마무리 의지', appCtx: '오후 슬럼프, 하루 마무리를 앞둔 순간' },
  golden_hour: { time: '18~21', desc: '오후 18~21시. 퇴근·귀가 후. 수고함+감사', appCtx: '퇴근·귀가 중, 또는 저녁 식사를 마친 후' },
  wind_down:   { time: '21~24', desc: '오후 21~24시. 취침 전 마지막 폰. 피로+평안 욕구', appCtx: '취침 전 마지막 폰 확인, 잠자리 들기 직전' },
  all:         { time: '전체', desc: '특정 시간대 무관. 언제든 공감 가능', appCtx: '지금 이 순간 (시간대 무관)' },
};

// ── 39개 신규 구절 목록 ────────────────────────────────────────────────────
const NEW_VERSES = [
  // deep_dark (3개) — 고요·침묵·외로움
  { ref: '시편 3:3',      mode: ['deep_dark'],   theme: ['faith', 'stillness'], mood: ['serene'] },
  { ref: '시편 56:3-4',   mode: ['deep_dark', 'all'], theme: ['faith', 'courage'], mood: ['serene', 'calm'] },
  { ref: '이사야 43:4',   mode: ['deep_dark', 'all'], theme: ['grace', 'faith'],   mood: ['serene', 'warm'] },

  // first_light (4개) — 여명·준비
  { ref: '시편 8:1',      mode: ['first_light', 'rise_ignite'], theme: ['hope', 'renewal'],  mood: ['serene', 'bright'] },
  { ref: '시편 51:10',    mode: ['first_light'], theme: ['renewal', 'faith'],  mood: ['serene', 'calm'] },
  { ref: '요한복음 1:1',  mode: ['first_light'], theme: ['faith', 'stillness'], mood: ['serene'] },
  { ref: '요한복음 11:25-26', mode: ['first_light'], theme: ['hope', 'faith'], mood: ['serene', 'calm'] },

  // rise_ignite (6개) — 각성·시작
  { ref: '시편 19:1',     mode: ['rise_ignite'], theme: ['hope', 'renewal'], mood: ['bright', 'dramatic'] },
  { ref: '시편 32:8',     mode: ['rise_ignite', 'first_light'], theme: ['wisdom', 'hope'], mood: ['bright'] },
  { ref: '시편 84:11',    mode: ['rise_ignite'], theme: ['hope', 'strength'], mood: ['bright', 'dramatic'] },
  { ref: '마태복음 7:7',  mode: ['rise_ignite', 'peak_mode'],   theme: ['hope', 'courage'], mood: ['bright'] },
  { ref: '로마서 8:1',    mode: ['rise_ignite'], theme: ['renewal', 'grace'],  mood: ['bright'] },
  { ref: '요한복음 8:36', mode: ['rise_ignite'], theme: ['renewal', 'strength'], mood: ['bright', 'dramatic'] },

  // peak_mode (5개) — 집중·성과
  { ref: '시편 24:1',     mode: ['peak_mode', 'all'],   theme: ['wisdom', 'gratitude'], mood: ['bright'] },
  { ref: '잠언 31:25',    mode: ['peak_mode', 'second_wind'], theme: ['courage', 'strength'], mood: ['bright', 'dramatic'] },
  { ref: '누가복음 1:37', mode: ['peak_mode', 'all'], theme: ['faith', 'hope'],   mood: ['bright'] },
  { ref: '로마서 5:1',    mode: ['peak_mode'], theme: ['peace', 'grace'],  mood: ['calm', 'bright'] },
  { ref: '빌립보서 1:6',  mode: ['peak_mode', 'all'], theme: ['hope', 'patience'], mood: ['bright', 'warm'] },

  // recharge (4개) — 휴식·재충전
  { ref: '시편 131:2',    mode: ['recharge', 'wind_down'], theme: ['rest', 'stillness'], mood: ['calm', 'serene'] },
  { ref: '시편 86:5',     mode: ['recharge', 'wind_down'], theme: ['grace', 'comfort'], mood: ['warm', 'calm'] },
  { ref: '시편 36:7',     mode: ['recharge', 'all'],  theme: ['grace', 'rest'], mood: ['warm', 'calm'] },
  { ref: '마태복음 18:20', mode: ['recharge', 'all'], theme: ['comfort', 'faith'], mood: ['warm'] },

  // second_wind (4개) — 오후·재점화
  { ref: '시편 40:1-2',   mode: ['second_wind', 'all'], theme: ['patience', 'hope'], mood: ['warm', 'calm'] },
  { ref: '이사야 48:10',  mode: ['second_wind', 'all'], theme: ['strength', 'patience'], mood: ['calm', 'warm'] },
  { ref: '사도행전 2:28', mode: ['second_wind', 'rise_ignite'], theme: ['hope', 'renewal'], mood: ['warm', 'bright'] },
  { ref: '마태복음 28:20', mode: ['second_wind', 'all'], theme: ['faith', 'strength'], mood: ['warm'] },

  // golden_hour (5개) — 저녁·수확
  { ref: '시편 103:2',    mode: ['golden_hour'], theme: ['gratitude', 'reflection'], mood: ['warm', 'serene'] },
  { ref: '시편 100:4',    mode: ['golden_hour'], theme: ['gratitude', 'peace'], mood: ['warm', 'serene'] },
  { ref: '시편 116:1',    mode: ['golden_hour', 'wind_down'], theme: ['gratitude', 'comfort'], mood: ['warm'] },
  { ref: '에베소서 4:32', mode: ['golden_hour'], theme: ['comfort', 'reflection', 'gratitude'], mood: ['warm', 'serene'] },
  { ref: '이사야 44:22',  mode: ['golden_hour', 'wind_down'], theme: ['grace', 'rest'], mood: ['warm', 'serene'] },

  // wind_down (5개) — 마무리·안식
  { ref: '시편 112:1',    mode: ['wind_down', 'first_light'], theme: ['faith', 'stillness'], mood: ['cozy', 'calm'] },
  { ref: '창세기 28:15',  mode: ['wind_down', 'all'], theme: ['peace', 'stillness'], mood: ['cozy', 'calm'] },
  { ref: '예레미야 31:3', mode: ['wind_down', 'all'], theme: ['rest', 'grace'], mood: ['cozy', 'serene'] },
  { ref: '시편 31:3',     mode: ['wind_down', 'all'], theme: ['stillness', 'faith'], mood: ['cozy', 'calm'] },
  { ref: '누가복음 15:4', mode: ['wind_down', 'all'], theme: ['comfort', 'grace'], mood: ['cozy', 'warm'] },

  // all (3개) — 범용
  { ref: '이사야 9:6',    mode: ['all'], theme: ['hope', 'faith'],   mood: ['calm', 'warm'] },
  { ref: '마태복음 5:3',  mode: ['all', 'deep_dark'], theme: ['stillness', 'grace'], mood: ['serene', 'calm'] },
  { ref: '마태복음 5:8',  mode: ['all', 'first_light'], theme: ['faith', 'stillness'], mood: ['serene'] },
];

// ── 콘텐츠 생성 ────────────────────────────────────────────────────────────
async function generateContent(verse) {
  const primaryMode = verse.mode[0];
  const zone = ZONE_CONTEXT[primaryMode] || ZONE_CONTEXT.all;

  const prompt = `[역할]
너는 DailyVerse 앱의 말씀 콘텐츠 작가야.
설교자가 아닌 유저의 신앙 친구. 교회 강단 언어 아님.

[입력]
성경 구절: ${verse.ref}
Zone: ${primaryMode} (${zone.time})
유저 상황: ${zone.desc}
application 컨텍스트: ${zone.appCtx}

[생성 순서]
① verse_full_ko (10~120자) — 개역한글 원문 그대로
② verse_short_ko (10~60자) — full에서 핵심 문장 추출 (합성 금지)
③ interpretation (100~155자) — ①저자상황→②핵심의미→③오늘연결. 원어 표기 절대 금지. ~야/~이야 어투.
④ application (45~78자) — Zone 시간대·유저 상황이 문장에 녹아야 함. ~봐/~기억해 어투. 강요 금지.
⑤ question (32~80자) — verse_full_ko 맥락 연결. 닉네임 없이. 일반 어투. 신앙 행위 점검 금지.

[중요]
- verse_full_ko: 개역한글 원문 (~니라, ~이로다 고어체 정상)
- interpretation: 반드시 ①저자가 처한 구체적 상황 1문장으로 시작
- application: "${zone.appCtx}" 상황이 느껴지게
- question: "~나요?" 아닌 "~있었어?" "~해봤어?" 일반 어투 권장

[출력: JSON만]
{
  "verse_full_ko": "...",
  "verse_short_ko": "...",
  "interpretation": "...",
  "application": "...",
  "question": "..."
}`;

  const msg = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 600,
    messages: [{ role: 'user', content: prompt }],
  });

  const raw = msg.content[0].text.trim()
    .replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  return JSON.parse(raw);
}

// ── 다음 verse_id 결정 ────────────────────────────────────────────────────
async function getNextId() {
  const snap = await db.collection('verses').get();
  if (snap.empty) return 'v_162';
  const nums = [];
  snap.forEach(d => {
    const n = parseInt(d.id.replace(/\D/g, ''));
    if (!isNaN(n)) nums.push(n);
  });
  const maxNum = Math.max(...nums);
  return `v_${String(maxNum + 1).padStart(3, '0')}`;
}

// ── 메인 ─────────────────────────────────────────────────────────────────
async function main() {
  console.log(`=== add_new_verses.js | dry-run: ${isDryRun} | 대상: ${NEW_VERSES.length}개 ===\n`);

  let startNum = parseInt((await getNextId()).replace(/\D/g, ''));
  let success = 0, errors = 0;

  for (let i = 0; i < NEW_VERSES.length; i++) {
    const verse = NEW_VERSES[i];
    const verseId = `v_${String(startNum + i).padStart(3, '0')}`;
    process.stdout.write(`[${i+1}/${NEW_VERSES.length}] ${verseId} (${verse.ref}) ... `);

    try {
      const content = await generateContent(verse);

      if (isDryRun) {
        console.log('\n  full:', content.verse_full_ko.slice(0, 40));
        console.log('  interp:', content.interpretation.slice(0, 50));
        console.log('  app:', content.application.slice(0, 50));
        console.log('  q:', content.question.slice(0, 50));
      } else {
        await db.collection('verses').doc(verseId).set({
          verse_id:              verseId,
          verse_full_ko:         content.verse_full_ko,
          verse_short_ko:        content.verse_short_ko,
          interpretation:        content.interpretation,
          application:           content.application,
          question:              content.question,
          reference:             verse.ref,
          mode:                  verse.mode,
          theme:                 verse.theme,
          mood:                  verse.mood,
          season:                ['all'],
          weather:               ['any'],
          status:                'active',
          curated:               false,
          usage_count:           0,
          cooldown_days:         7,
          qa_status:             'draft',
          qa_issues:             [],
          qa_guideline_version:  'v9.0',
          qa_checked_at:         null,
        });
        console.log(`완료 (${content.verse_full_ko.length}자)`);
        success++;
      }
    } catch (e) {
      console.log(`오류: ${e.message}`);
      errors++;
    }

    if (i < NEW_VERSES.length - 1) await new Promise(r => setTimeout(r, 800));
  }

  console.log(`\n===== 완료 =====`);
  if (isDryRun) console.log(`dry-run: ${NEW_VERSES.length}개 미리보기`);
  else console.log(`성공: ${success}개 | 오류: ${errors}개`);
  console.log('\n다음 단계:');
  console.log('  node qa_auto_check.js');
  console.log('  node qa_ai_check.js          # 1차: Haiku');
  console.log('  node qa_ai_check.js --deep   # 2차: Sonnet');
  console.log('  node qa_approve.js');
}

main().catch(console.error).finally(() => process.exit());
