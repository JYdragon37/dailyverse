const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// 패치 대상: 히브리어/헬라어 표현이 포함된 alarm_verses 5개
// av_001 (예레미야 29:11), av_006 (로마서 8:28), av_008 (이사야 40:31),
// av_009 (시편 143:8), av_013 (시편 37:5)

const patches = [
  {
    id: 'av_001',
    reference: '예레미야 29:11',
    interpretation:
      '이 말씀은 하나님이 바벨론 포로로 끌려간 이스라엘 백성에게 직접 보내신 편지 속 구절이야.\n' +
      '70년의 포로 생활을 앞두고도 하나님은 "재앙이 아니라 평안"을 계획하셨어.\n' +
      '지금 네가 알람을 맞추는 내일도, 이미 그분의 좋은 계획 안에 있어.',
    application:
      '내일이 불확실해도 괜찮아.\n그 끝을 설계하시는 분이 함께 계시거든. 이제 편히 자.',
  },
  {
    id: 'av_006',
    reference: '로마서 8:28',
    interpretation:
      '바울은 로마 교회에 보낸 편지에서 박해와 고난 한가운데서도 이 확신을 선포했어.\n' +
      '"합력하여 선을 이루다"는 건, 좋은 일만이 아니라 힘든 일도 하나님 손 안에서 방향을 잡는다는 뜻이야.\n' +
      '내일 알람이 울릴 때 어떤 하루가 펼쳐지든, 그 모든 게 네게 선으로 이어져.',
    application:
      '알람을 맞췄어. 내일 무슨 일이 생기든 하나님 손 안에 있다는 걸 기억해. 이제 편히 자.',
  },
  {
    id: 'av_008',
    reference: '이사야 40:31',
    interpretation:
      '이 말씀은 이스라엘이 바벨론 포로로 지쳐있을 때 주어진 위로야.\n' +
      '"앙망"은 단순한 기다림이 아니라, 소망을 하나님께 모아 고정하는 적극적 태도야.\n' +
      '독수리가 날개를 퍼덕이지 않고 기류를 타듯, 하나님을 바라볼 때 자연스럽게 힘이 채워지는 거야.',
    application:
      '내일 아침 이 알람 소리와 함께 새 힘이 올 거야. 독수리처럼 날아오를 하루가 기다리고 있어.',
  },
  {
    id: 'av_009',
    reference: '시편 143:8',
    interpretation:
      '시편 143편은 다윗이 원수에게 쫓기며 생사의 기로에서 드린 간절한 기도야.\n' +
      '그 절박한 상황에서도 다윗은 "아침에" 하나님의 인자하심을 듣겠다고 고백했어.\n' +
      '내일 아침 알람이 울릴 때 제일 먼저 말씀이 기다리고 있는 이유가 바로 이 기도 때문이야.',
    application:
      '내일 아침 알람이 울리면, 제일 먼저 말씀이 기다리고 있을 거야. 이미 그 하루를 기대해도 돼.',
  },
  {
    id: 'av_013',
    reference: '시편 37:5',
    interpretation:
      '시편 37편은 악인이 번성하는 세상을 보며 흔들리는 다윗의 신앙을 담은 시야.\n' +
      '그는 "맡기라"고 말해. 내일 계획을 짜되, 그 결과를 움켜쥐지 말라는 거야.\n' +
      '알람을 맞추는 이 순간, 내일을 기획하면서 동시에 내려놓는 신앙의 행동을 하는 거야.',
    application:
      '알람 맞추며 내일 계획도 하나님께 굴려 드려. 이루실 분은 따로 계시거든. 편히 자.',
  },
];

async function main() {
  console.log('alarm_verses 해석/적용 패치 시작...\n');

  let successCount = 0;
  let failCount = 0;

  for (const patch of patches) {
    try {
      await db.collection('alarm_verses').doc(patch.id).update({
        interpretation: patch.interpretation,
        application: patch.application,
      });
      console.log(`✅ [${patch.id}] ${patch.reference} — 패치 완료`);
      successCount++;
    } catch (e) {
      console.error(`❌ [${patch.id}] ${patch.reference} — 패치 실패:`, e.message);
      failCount++;
    }
  }

  console.log(`\n패치 완료: ${successCount}개 성공, ${failCount}개 실패`);

  // 검증: 패치 후 재확인
  console.log('\n--- 패치 후 검증 ---');
  const snapshot = await db.collection('alarm_verses').get();
  let remaining = 0;
  snapshot.forEach(doc => {
    const interp = doc.data().interpretation || '';
    if (interp.includes('히브리어') || interp.includes('헬라어')) {
      console.log(`여전히 문제 있음: [${doc.id}]`);
      remaining++;
    }
  });
  if (remaining === 0) {
    console.log('모든 원어 표현 제거 완료.');
  }

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
