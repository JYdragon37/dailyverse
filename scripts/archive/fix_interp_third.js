require('dotenv').config();
const admin    = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const TARGET_IDS = [
  'v_021','v_023','v_027','v_029','v_040','v_044','v_050','v_053','v_054','v_065',
  'v_075','v_085','v_092','v_096','v_099','v_102','v_104','v_108','v_124','v_127',
  'v_128','v_137','v_144','v_148','v_153','v_156','v_161','v_163','v_164','v_178','v_185',
];

async function addThird(interp, verseFullKo) {
  const msg = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 80,
    messages: [{
      role: 'user',
      content: [
        '아래 interpretation 끝에 붙일 ③오늘 유저 연결 문장 1개만 써줘.',
        '규칙: ~야/~거야/~있어 어투. 20~35자. "지금 네..." 또는 "오늘 ..." 형태로 시작.',
        '말씀: ' + verseFullKo,
        '기존 끝부분: ' + interp.slice(-50),
        '출력: 문장만 (따옴표 없이)',
      ].join('\n'),
    }],
  });
  return msg.content[0].text.trim();
}

async function main() {
  for (const id of TARGET_IDS) {
    const d = (await db.collection('verses').doc(id).get()).data();
    const interp = (d.interpretation || '').trim();
    const lastLine = interp.split('\n').slice(-1)[0] || '';

    // 이미 오늘/지금/너 연결 있으면 스킵
    if (/오늘|지금|네가|네 /.test(lastLine)) {
      console.log(id, '[스킵 — 이미 ③ 있음]');
      continue;
    }

    process.stdout.write(id + ' (' + (d.reference||'') + ') ... ');
    try {
      const third  = await addThird(interp, d.verse_full_ko || '');
      const newInterp = interp + '\n' + third;
      if (newInterp.length <= 160) {
        await db.collection('verses').doc(id).update({ interpretation: newInterp });
        console.log('완료 (' + newInterp.length + '자)');
      } else {
        // 앞 줄 하나 제거 후 추가 시도
        const lines = interp.split('\n');
        const shorter = lines.slice(0, -1).join('\n').trim() + '\n' + third;
        if (shorter.length <= 160) {
          await db.collection('verses').doc(id).update({ interpretation: shorter });
          console.log('단축 후 완료 (' + shorter.length + '자)');
        } else {
          console.log('초과 (' + newInterp.length + '자) — 스킵');
        }
      }
    } catch (e) {
      console.log('오류:', e.message);
    }
    await new Promise(r => setTimeout(r, 600));
  }
  console.log('\n✅ 완료');
}

main().catch(console.error).finally(() => process.exit());
