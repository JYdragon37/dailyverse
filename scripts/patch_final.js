const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const patches = {
  'av_001': {
    // evening/all / 예레미야 29:11 / a=54 → 목표 70자+
    application: '알람을 맞추며 기억해봐.\n내일 하루도 하나님의 계획 안에 있어.\n두려울 것 없어. 그 계획을 믿으며 편히 눈을 감아봐.'
  },
  'av_006': {
    // morning / 로마서 8:28 / a=53 → 목표 70자+
    application: '알람 맞추고 기억해.\n내일 무슨 일이 생기든 하나님 손 안에 있어.\n그 확신 하나로 충분해. 이제 편히 자봐.'
  },
  'av_012': {
    // morning / 여호수아 1:9 / a=57 → 목표 70자+
    application: '내일 알람이 울리면 그게 출발 신호야.\n강하고 담대하게 시작해봐.\n하나님이 함께하시니까 어떤 하루도 충분히 감당할 수 있어.'
  },
  'av_020': {
    // morning / 욥기 11:17 / a=57 → 목표 70자+
    application: '알람을 맞추며 기억해.\n어떤 어두운 밤도 아침을 막을 수 없어.\n하나님이 빛을 들고 내일 아침을 먼저 열어주실 거야.'
  },
  'av_022': {
    // all / 에스겔 36:26 / a=59 → 목표 70자+
    application: '오늘 알람을 맞춘 건 변화를 원한다는 신호야.\n하나님께 그 새 마음을 구해봐.\n변화는 혼자 하는 게 아니야. 하나님이 함께하셔.'
  },
  'av_027': {
    // evening / 요한복음 16:20 / i=145 → 목표 170자+
    interpretation: '예수님이 십자가를 앞두고 제자들에게 하신 말씀이야.\n지금은 슬픔이 있어도, 그 슬픔이 반드시 기쁨으로 바뀐다는 약속이야.\n오늘이 힘든 날이었어도 괜찮아. 하나님이 일하고 계시니까.\n오늘 밤 알람을 맞추는 건 내일의 기쁨을 기대하며 잠드는 거야. 슬픔이 끝이 아니라 기쁨으로 가는 길이야.'
  },
  'av_028': {
    // morning / 이사야 40:31 / a=58 → 목표 70자+
    application: '내일 알람이 울릴 때 피곤해도 괜찮아.\n하나님이 새 힘을 주시거든.\n독수리처럼 날아오를 힘이 이미 너를 기다리고 있어.'
  },
  'av_036': {
    // all / 로마서 15:13 / i=145 → 목표 170자+
    interpretation: '바울이 로마 교인들을 위해 드린 축복 기도야.\n"소망의 하나님"은 소망을 주시는 분이 아니라, 그분 자신이 소망 그 자체라는 뜻이야.\n알람을 맞추는 건 내일을 기대한다는 증거야.\n그 기대감 안에 하나님의 기쁨과 평강이 이미 함께 있어. 기대하는 것 자체가 믿음이고, 그 믿음을 하나님이 기쁨으로 채워주셔.'
  },
  'av_038': {
    // evening / 미가 7:8 / a=59 → 목표 70자+
    application: '오늘이 힘들었다면 알람을 맞추며 선언해봐.\n"나는 내일 다시 일어날 거야."\n엎드러져도 일어나는 것, 그게 하나님이 기뻐하시는 믿음이야.'
  },
  'av_040': {
    // morning / 시편 139:9-10 / i=147 → 목표 170자+
    interpretation: '시편 139편은 하나님이 어디에나 계신다는 고백이야.\n새벽 날개를 타고 바다 끝까지 가도, 하나님의 손이 거기 있다는 거야.\n내일 어디를 가든, 무슨 일을 하든, 하나님이 인도하신다는 약속이야.\n아침 알람이 울릴 때 그 손을 붙잡고 나가봐. 어떤 하루도 혼자가 아니야. 그 손이 닿지 않는 곳은 없어.'
  },
  'av_054': {
    // morning / 요한복음 14:29 / a=58 → 목표 70자+
    application: '내일 아침 알람이 울리면 생각해봐.\n하나님이 이 하루를 이미 준비해두셨어.\n그 준비된 하루 안으로 담대하게 들어가봐.'
  },
  'av_057': {
    // all / 시편 46:1 / a=54 → 목표 70자+
    application: '오늘 밤 알람 맞추며 생각해봐.\n내일 힘든 일이 있어도, 피할 곳이 있어.\n하나님 품이 그 피난처야. 어떤 때도 열려 있거든.'
  },
  'av_058': {
    // morning / 에스겔 36:26 / a=59 → 목표 70자+
    application: '내일 아침 알람이 울리면 믿어봐.\n하나님이 오늘과 다른 새 마음을 주실 수 있어.\n변화를 기대하며 눈을 떠봐. 돌 같은 마음이 살 같은 마음으로 바뀔 거야.'
  }
};

async function main() {
  const updates = [];
  for (const [id, patch] of Object.entries(patches)) {
    const update = {};
    if (patch.interpretation) update.interpretation = patch.interpretation;
    if (patch.application) update.application = patch.application;
    updates.push({ id, update });
  }

  console.log(`총 ${updates.length}건 업데이트`);
  for (const { id, update } of updates) {
    await db.collection('alarm_verses').doc(id).update(update);
    const parts = [];
    if (update.interpretation) parts.push(`i(${update.interpretation.replace(/\n/g,'').length}자)`);
    if (update.application) parts.push(`a(${update.application.replace(/\n/g,'').length}자)`);
    console.log(`✅ ${id}: ${parts.join(', ')}`);
  }

  // 최종 검증
  console.log('\n--- 최종 검증 ---');
  const snap = await db.collection('alarm_verses').get();
  let totalI = 0, totalA = 0, count = 0;
  const stillShort = [];
  snap.forEach(doc => {
    const d = doc.data();
    const iLen = (d.interpretation||'').replace(/\n/g,'').length;
    const aLen = (d.application||'').replace(/\n/g,'').length;
    totalI += iLen;
    totalA += aLen;
    count++;
    if (iLen < 150 || aLen < 60) {
      stillShort.push({ id: doc.id, iLen, aLen });
    }
  });
  console.log(`\n전체 ${count}건`);
  console.log(`평균 interpretation: ${Math.round(totalI/count)}자`);
  console.log(`평균 application: ${Math.round(totalA/count)}자`);
  if (stillShort.length > 0) {
    console.log(`\n여전히 기준 미달: ${stillShort.length}건`);
    stillShort.forEach(x => console.log(`  ${x.id}: i=${x.iLen}, a=${x.aLen}`));
  } else {
    console.log('\n✅ 모든 항목이 기준을 충족합니다!');
  }

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
