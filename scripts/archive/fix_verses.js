const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// 수정 전 검증용 원본 데이터 (참고)
// v_016 verse_full_ko: 127자
// v_032 verse_full_ko: 176자
// v_046 verse_full_ko: 131자
// v_047 verse_full_ko: 135자, verse_short_ko: 65자
// v_007 verse_short_ko: 7자
// v_033 application: "중입니다" 포함
// v_165 application: "이다." 포함
// v_119 question: "해야 한다" 포함
// v_146 interpretation: "반드시" 포함
// v_180 question: "해야 한다" 포함
// v_054 question: 27자
// v_068 question: 28자
// v_147 question: 28자

const updates = {
  // 1. verse_full_ko 단축 (120자 이내)
  'v_016': {
    // 127자 → 두 절 유지, 8절 뒷부분(결실 구절) 제거 → 110자
    verse_full_ko: '무릇 여호와를 의뢰하며 여호와를 의지하는 그 사람은 복을 받을 것이라\n그는 물가에 심기운 나무가 그 뿌리를 강변에 뻗치고 더위가 올지라도 두려워 아니하며 그 잎이 청청하며 가무는 해에도 걱정이 없고'
  },
  'v_032': {
    // 176자 → 1절만 선택 (74자)
    verse_full_ko: '이러므로 우리에게 구름 같이 둘러싼 허다한 증인들이 있으니 모든 무거운 것과 얽매이기 쉬운 죄를 벗어 버리고 인내로써 우리 앞에 당한 경주를 경주하며'
  },
  'v_046': {
    // 131자 → 핵심 구절만 선택 (68자)
    verse_full_ko: '찬송하리로다 그는 우리 주 예수 그리스도의 하나님이시요 자비의 아버지시요 모든 위로의 하나님이시며 우리의 모든 환난 중에서 우리를 위로하사'
  },
  'v_047': {
    // 135자 → 핵심 앞 절만 선택 (57자)
    verse_full_ko: '내가 그리스도와 함께 십자가에 못 박혔나니 그런즉 이제는 내가 산 것이 아니요 오직 내 안에 그리스도께서 사신 것이라',
    // 65자 → 60자 이내
    verse_short_ko: '내가 그리스도와 함께 십자가에 못 박혔나니 이제는 내 안에 그리스도께서 사신 것이라'
  },

  // 2. verse_short_ko 수정 (v_007: 7자 → 10자 이상)
  'v_007': {
    verse_short_ko: '항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라'
  },

  // 3. application 금지 말투 수정
  'v_033': {
    // "중입니다" → 대화체
    application: '지금 답을 기다리고 있는 게 있다면 "나 지금 기다리는 중이야"라고 인정하고 잠시 쉬어봐.'
  },
  'v_165': {
    // "이다." → 대화체
    application: '내일 알람이 울리면, "드디어 아침이야. 하나님이 기다리던 이 아침을 주셨어"라고 생각해봐.'
  },

  // 4. question 강요 표현 제거
  'v_119': {
    // "해야 한다" 제거
    question: '지금 이 순간, 당신이 붙잡고 있는 것 중에 오늘 밤은 내려놓아도 될 것이 있다면 무엇인가요?'
  },
  'v_146': {
    // interpretation에서 "반드시" 제거
    interpretation: '오늘 수고한 게 헛되지 않아. 지금 눈물로 뿌리는 씨앗이 기쁨의 수확으로 돌아올 거야.\n힘든 하루였어도 알람을 맞추며 내일을 기대할 수 있어 — 거두는 날이 올 거거든.'
  },
  'v_180': {
    // "해야 한다" 제거
    question: '요즘 밤을 새우거나 무리하면서 지쳐간다는 걸 느낀 순간이 있다면, 그때 어떤 생각이 들었나요?'
  },

  // 5. question 글자수 보완 (30자 미만 → 30자 이상)
  'v_054': {
    // 27자 → 30자 이상
    question: '마음이 크게 흔들렸던 때를 떠올려봐. 그때 당신을 버티게 해준 것이 무엇이었나요?'
  },
  'v_068': {
    // 28자 → 30자 이상
    question: '지금 당신이 가장 기력이 떨어졌다고 느끼는 순간은 언제이고, 그때 무엇이 도움이 되었나요?'
  },
  'v_147': {
    // 28자 → 30자 이상
    question: '가장 힘들었던 순간, 당신은 무엇을 붙잡고 버텨왔나요? 지금도 그것이 여전히 힘이 되고 있나요?'
  }
};

async function runFixes() {
  console.log('=== 수정 내용 검증 ===');
  for (const [id, fields] of Object.entries(updates)) {
    for (const [field, value] of Object.entries(fields)) {
      console.log(id + ' / ' + field + ': [' + value.length + '자] ' + value.substring(0, 60) + (value.length > 60 ? '...' : ''));
    }
  }

  console.log('\n=== Firestore 업데이트 시작 ===');
  for (const [id, fields] of Object.entries(updates)) {
    try {
      await db.collection('verses').doc(id).update(fields);
      console.log('[OK] ' + id + ' 업데이트 완료: ' + Object.keys(fields).join(', '));
    } catch (e) {
      console.error('[ERROR] ' + id + ': ' + e.message);
    }
  }

  console.log('\n=== 완료 ===');
  process.exit(0);
}

runFixes().catch(e => {
  console.error(e);
  process.exit(1);
});
