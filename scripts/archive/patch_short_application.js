const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// application < 60자인 나머지 항목 보강
// 각 항목의 alarm_context와 reference를 기반으로 작성
const patches = {
  'av_001': {
    // ctx: all / ref: 예레미야 29:11 / 저녁 맥락
    application: '알람을 맞추며 기억해봐.\n내일 하루도 하나님의 계획 안에 있어.\n그 계획을 믿으며 편히 눈을 감아봐.'
  },
  'av_006': {
    // ctx: morning / ref: 로마서 8:28
    application: '알람 맞추고 기억해.\n내일 무슨 일이 생기든 하나님 손 안에 있어.\n그 확신을 품고 편안하게 자봐.'
  },
  'av_011': {
    // ctx: evening / ref: 신명기 31:8
    application: '내일이 걱정돼? 하나님은 이미 내일에 가 계셔.\n알람 맞추고 그냥 자도 돼.\n먼저 가신 분이 내일 자리를 준비해두셨거든.'
  },
  'av_012': {
    // ctx: morning / ref: 여호수아 1:9
    application: '내일 알람이 울리면 그게 출발 신호야.\n강하고 담대하게 시작해.\n하나님이 함께하시니까 충분히 할 수 있어.'
  },
  'av_020': {
    // ctx: morning / ref: 욥기 11:17
    application: '알람을 맞추며 기억해.\n어떤 어두운 밤도 아침을 막을 수 없어.\n내일 아침 하나님의 빛이 먼저 와줄 거야.'
  },
  'av_022': {
    // ctx: all / ref: 에스겔 36:26
    application: '오늘 알람을 맞춘 건 변화를 원한다는 신호야.\n하나님께 그 새 마음을 구해봐.\n변화는 혼자 하는 게 아니거든.'
  },
  'av_027': {
    // ctx: evening / ref: 요한복음 16:20 - interpretation 145자 FIX
    interpretation: '예수님이 십자가를 앞두고 제자들에게 하신 말씀이야.\n지금은 슬픔이 있어도, 그 슬픔이 반드시 기쁨으로 바뀐다는 약속이야.\n오늘이 힘든 날이었어도 괜찮아. 하나님이 일하고 계시니까.\n오늘 밤 알람을 맞추는 건 내일의 기쁨을 기대하며 잠드는 거야. 슬픔이 끝이 아니야.'
  },
  'av_028': {
    // ctx: morning / ref: 이사야 40:31
    application: '내일 알람이 울릴 때 피곤해도 괜찮아.\n하나님이 새 힘을 주시거든.\n독수리처럼 날아오를 힘이 이미 준비됐어.'
  },
  'av_029': {
    // ctx: all / ref: 잠언 16:3
    application: '알람 맞추면서 오늘의 계획을 하나님께 드려봐.\n"하나님, 이 하루 인도해주세요."\n맡기면 그분이 이루어 주실 거야.'
  },
  'av_036': {
    // ctx: all / ref: 로마서 15:13
    application: '알람을 맞추는 지금, 내일에 대한 기대감이 소망이야.\n하나님이 그걸 기쁨과 평강으로 채워주실 거야.\n소망의 하나님을 믿으며 자봐.'
  },
  'av_038': {
    // ctx: evening / ref: 미가 7:8
    application: '오늘이 힘들었다면 알람을 맞추며 선언해봐.\n"나는 내일 다시 일어날 거야."\n엎드러져도 일어나는 게 믿음이야.'
  },
  'av_040': {
    // ctx: morning / ref: 시편 139:9-10 - interpretation 147자 FIX 필요
    interpretation: '시편 139편은 하나님이 어디에나 계신다는 고백이야.\n새벽 날개를 타고 바다 끝까지 가도, 하나님의 손이 거기 있다는 거야.\n내일 어디를 가든, 무슨 일을 하든, 하나님이 인도하신다는 약속이야.\n아침 알람이 울릴 때 그 손을 붙잡고 나가봐. 어떤 하루도 혼자가 아니야.'
  },
  'av_047': {
    // ctx: evening / ref: 마태복음 6:34
    application: '오늘 밤 걱정이 생각난다면, 알람 맞추며 이렇게 해봐.\n걱정을 하나님께 넘기고 넌 그냥 쉬면 돼.\n내일 걱정은 내일에게 맡기는 게 믿음이야.'
  },
  'av_048': {
    // ctx: morning / ref: 잠언 16:9
    application: '오늘 밤 내일 계획을 세우고 알람을 맞췄다면,\n그 마지막에 "하나님, 인도해주세요"라고 한 마디 붙여봐.\n계획은 내가, 인도는 하나님이 하시거든.'
  },
  'av_049': {
    // ctx: evening / ref: 이사야 26:9
    application: '오늘 밤 알람을 맞추며 기대해봐.\n내일 새벽, 하나님이 먼저 기다리고 계실 거야.\n그 만남을 설레는 마음으로 기다려봐.'
  },
  'av_050': {
    // ctx: morning / ref: 여호수아 1:9
    application: '내일 이 알람이 울릴 때, 눈 뜨자마자 한 번만 말해봐.\n"하나님이 함께하셔." 그거면 충분해.\n두려워도 함께하시니까 충분히 갈 수 있어.'
  },
  'av_051': {
    // ctx: evening / ref: 시편 30:5
    application: '오늘 밤 울고 싶으면 울어도 괜찮아.\n알람을 맞추며 기억해. 아침에는 기쁨이 와.\n저녁의 울음이 아침의 기쁨으로 바뀌거든.'
  },
  'av_052': {
    // ctx: all / ref: 시편 18:1-2
    application: '알람 맞추기 전에 한 번만 말해봐.\n"여호와는 나의 피난처야." 그 고백이 오늘 밤 너를 지켜줄 거야.\n흔들리지 않는 반석이 함께하셔.'
  },
  'av_053': {
    // ctx: morning / ref: 시편 139:9-10
    application: '내일 알람이 울리면 기억해.\n어떤 하루가 오더라도, 하나님의 손이 이미 거기 있어.\n새벽 날개 끝까지도 그분은 계셔.'
  },
  'av_054': {
    // ctx: morning / ref: 요한복음 14:29
    application: '내일 아침 알람이 울리면 생각해봐.\n하나님이 이 하루를 이미 준비해두셨어.\n그 준비된 하루 안으로 들어가봐.'
  },
  'av_056': {
    // ctx: evening / ref: 이사야 41:10
    application: '내일이 걱정된다면, 알람 맞추며 이걸 기억해봐.\n"하나님이 함께하셔." 그 약속 하나로 충분해.\n두려움보다 큰 약속이 있거든.'
  },
  'av_057': {
    // ctx: all / ref: 시편 46:1
    application: '오늘 밤 알람 맞추며 생각해봐.\n내일 힘든 일이 있어도, 피할 곳이 있어.\n하나님 품이 그 피난처야.'
  },
  'av_058': {
    // ctx: morning / ref: 에스겔 36:26
    application: '내일 아침 알람이 울리면 믿어봐.\n하나님이 오늘과 다른 새 마음을 주실 수 있어.\n변화를 기대하며 눈을 떠봐.'
  },
  'av_059': {
    // ctx: evening / ref: 잠언 19:21
    application: '오늘 밤 내일 계획을 세우며 알람을 맞췄다면,\n그 마지막에 "그래도 하나님의 뜻대로"라고 내려놔봐.\n계획보다 하나님의 뜻이 더 좋거든.'
  },
  'av_060': {
    // ctx: morning / ref: 시편 5:3
    application: '내일 알람이 울리면, 일어나자마자 딱 한 마디만 기도해봐.\n그 한 마디가 하루의 방향을 잡아줄 거야.\n하루의 첫 대화를 하나님께 드려봐.'
  },
  'av_061': {
    // ctx: morning / ref: 고린도후서 4:16
    application: '내일 아침 몸이 무거워도 괜찮아.\n알람이 울릴 때 기억해. 내 속사람은 날마다 새로워지고 있어.\n겉은 낡아가도 속은 새로워지거든.'
  },
  'av_062': {
    // ctx: evening / ref: 시편 126:5
    application: '오늘 밤 힘들었다면, 알람 맞추며 기억해.\n지금 뿌리는 눈물이 언젠가 기쁨으로 돌아와.\n헛되지 않아. 반드시 거두는 날이 와.'
  },
  'av_063': {
    // ctx: morning / ref: 시편 119:147
    application: '내일 알람이 울리면, 말씀 한 구절만 먼저 읽어봐.\n그게 하루 전체의 방향을 잡아줄 거야.\n새벽빛보다 먼저 말씀이 너를 맞이할 거야.'
  },
  'av_064': {
    // ctx: all / ref: 로마서 8:31
    application: '오늘 밤 알람 맞추며 마음에 새겨봐.\n내일 무슨 일이 있어도, 하나님이 내 편이야.\n그거면 충분해. 든든하잖아.'
  },
  'av_066': {
    // ctx: evening / ref: 시편 4:8
    application: '오늘 밤 알람을 맞추며 눈을 감아봐.\n하나님이 이 밤도, 내일 아침도 붙들어주실 거야.\n붙드시는 분이 계시니까 편히 쉬어도 돼.'
  },
  'av_067': {
    // ctx: morning / ref: 로마서 6:4
    application: '내일 아침 알람이 울리면, 일어나며 말해봐.\n"오늘은 새 출발이야." 그리스도 안에서 정말 그래.\n어제가 어떠했든 오늘은 새로 시작할 수 있어.'
  },
  'av_068': {
    // ctx: evening / ref: 잠언 8:17
    application: '오늘 밤 알람 맞추며 생각해봐.\n내일 하루 중, 하나님을 찾는 시간을 언제 가질 수 있을까?\n찾는 사람이 반드시 만나거든.'
  },
  'av_069': {
    // ctx: morning / ref: 마가복음 1:35
    application: '내일 알람이 울리면, 예수님처럼 조용한 곳에서 딱 5분이라도 기도해봐.\n하루의 방향이 달라질 거야.\n바쁜 하루일수록 그 시간이 더 필요해.'
  },
  'av_070': {
    // ctx: all / ref: 잠언 3:5-6
    application: '알람 맞추며 이렇게 기도해봐.\n"하나님, 내 길을 인도해주세요. 내 판단보다 주님을 신뢰할게요."\n그 신뢰가 길을 평탄하게 해줄 거야.'
  },
  'av_071': {
    // ctx: morning / ref: 에베소서 5:14
    application: '내일 알람이 울리면 기억해.\n"일어나라, 그리스도가 빛을 비추신다." 그 빛 속으로 들어가봐.\n단순한 기상이 아니라 빛으로의 부름이야.'
  },
  'av_072': {
    // ctx: evening / ref: 예레미야 29:11
    application: '오늘 밤 내일이 걱정된다면, 알람 맞추며 기억해봐.\n하나님이 너를 향한 좋은 계획을 이미 갖고 계셔.\n재앙이 아닌 평안의 계획이야.'
  },
  'av_073': {
    // ctx: morning / ref: 시편 63:7
    application: '내일 아침 알람이 울릴 때 느껴봐.\n하나님의 날개 그늘 아래서 오늘 하루가 시작되는 거야.\n그 보호 안에서 기쁨이 솟아나거든.'
  },
  'av_074': {
    // ctx: evening / ref: 시편 143:8
    application: '오늘 밤 알람 맞추며 이 기도를 드려봐.\n"내일 아침 주의 인자하심으로 나를 기쁘게 하소서."\n그 기대가 오늘 밤을 평안하게 해줄 거야.'
  },
  'av_075': {
    // ctx: all / ref: 예레미야 33:3
    application: '오늘 밤 알람 맞추며 기도해봐.\n"하나님, 내일도 제가 알지 못하는 놀라운 일을 보여주세요."\n부르짖으면 반드시 응답하시는 분이야.'
  }
};

async function main() {
  const updates = [];
  for (const [id, patch] of Object.entries(patches)) {
    if (!patch.interpretation && !patch.application) continue;
    const update = {};
    if (patch.interpretation) update.interpretation = patch.interpretation;
    if (patch.application) update.application = patch.application;
    updates.push({ id, update });
  }

  console.log(`총 ${updates.length}건 업데이트 예정`);
  for (const { id, update } of updates) {
    await db.collection('alarm_verses').doc(id).update(update);
    const parts = [];
    if (update.interpretation) parts.push(`interpretation(${update.interpretation.replace(/\n/g,'').length}자)`);
    if (update.application) parts.push(`application(${update.application.replace(/\n/g,'').length}자)`);
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
    console.log('\n✅ 모든 항목이 기준을 충족합니다.');
  }

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
