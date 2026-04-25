/**
 * DailyVerse — second_wind Zone 구절 추가 스크립트
 * v_240 ~ v_259 (20개)
 * Zone: second_wind (오후 15-18시, 재도전·인내·완주·힘내)
 *
 * 사용법:
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 node upload_second_wind_v240_v259.js
 */

const { google } = require('googleapis');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

// ─── 콘텐츠 데이터 ────────────────────────────────────────────────────────────
// 컬럼 순서: A-Q (notes까지), R-U는 숫자/날짜 필드, V=alarm_top_ko
// 업로드 순서: verse_id, verse_short_ko, verse_full_ko, reference, book, chapter, verse,
//             mode, theme, mood, season, weather, interpretation, application,
//             curated, status, notes, usage_count, cooldown_days, last_shown, show_count,
//             alarm_top_ko

const verses = [
  {
    verse_id: 'v_240',
    verse_full_ko: '내가 달려갈 길과 주 예수께 받은 사명 곧 하나님의 은혜의 복음 증거하는 일을 마치려 함에는 나의 생명을 조금도 귀한 것으로 여기지 아니하노라.',
    verse_short_ko: '달려갈 길을 마치려 함에 생명도 아끼지 않노라.',
    reference: '사도행전 20:24',
    book: '사도행전',
    chapter: 20,
    verse: 24,
    theme: ['strength', 'courage', 'focus'],
    mood: ['warm', 'dramatic'],
    interpretation: '바울이 예루살렘으로 가는 길, 위험을 알면서도 멈추지 않던 순간의 고백이야.\n"마친다"는 말은 중간에 포기하지 않고 끝까지 완주한다는 뜻이야.\n오늘 오후, 지치더라도 시작한 일을 마무리하는 것 자체가 믿음의 표현이야.',
    application: '오늘 오후 남은 일 하나, 포기하지 말고 끝까지 마무리해봐.',
    alarm_top_ko: '달려갈 길을 마치려 생명도 아끼지 않노라.',
  },
  {
    verse_id: 'v_241',
    verse_full_ko: '너희 중에 지혜와 총명이 있는 자가 누구뇨. 그는 선행으로 말미암아 지혜의 온유함으로 그 행위를 보일찌니라.',
    verse_short_ko: '지혜 있는 자는 온유함으로 그 행위를 보이느니라.',
    reference: '야고보서 3:13',
    book: '야고보서',
    chapter: 3,
    verse: 13,
    theme: ['wisdom', 'patience', 'focus'],
    mood: ['calm', 'warm'],
    interpretation: '야고보가 참된 지혜는 말이 아니라 삶으로 드러난다고 가르치는 구절이야.\n"온유함으로"는 조급하지 않고 부드럽게 마무리하는 성품을 말해.\n오후 마무리 시간, 서두르지 않고 온유하게 하나씩 마치는 것이 진짜 지혜야.',
    application: '오늘 오후 남은 일, 서두르지 말고 온유하게 하나씩 마쳐봐. 그게 진짜 지혜야.',
    alarm_top_ko: '지혜 있는 자는 온유함으로 그 행위를 보이느니라.',
  },
  {
    verse_id: 'v_242',
    verse_full_ko: '형제들아, 나는 아직 내가 잡은 줄로 여기지 아니하고 오직 한 일 즉 뒤에 있는 것은 잊어버리고 앞에 있는 것을 잡으려고 푯대를 향하여 그리스도 예수 안에서 하나님이 위에서 부르신 부름의 상을 위하여 좇아가노라.',
    verse_short_ko: '뒤에 있는 것은 잊고 앞을 향하여 좇아가노라.',
    reference: '빌립보서 3:13-14',
    book: '빌립보서',
    chapter: 3,
    verse: 13,
    theme: ['focus', 'courage', 'strength'],
    mood: ['warm', 'dramatic'],
    interpretation: '바울이 감옥 안에서 쓴 편지 — 과거의 실패나 성공에 묶이지 않고 앞을 향하는 자세야.\n"푯대를 향하여"는 목표를 시야에서 잃지 않겠다는 의지의 표현이야.\n오후 슬럼프가 와도, 오늘 하루 남은 목표를 다시 한 번 시야에 담아봐.',
    application: '오후 남은 시간, 오늘 목표 하나만 시야에 담고 다시 시작해봐.',
    alarm_top_ko: '뒤에 있는 것은 잊고 앞을 향하여.',
  },
  {
    verse_id: 'v_243',
    verse_full_ko: '부지런한 자의 손은 사람을 다스리게 되어도 게으른 자는 부림을 받느니라.',
    verse_short_ko: '부지런한 자의 손은 다스리게 되느니라.',
    reference: '잠언 12:24',
    book: '잠언',
    chapter: 12,
    verse: 24,
    theme: ['wisdom', 'focus', 'strength'],
    mood: ['warm', 'calm'],
    interpretation: '잠언 기자가 부지런함을 열매로 연결하는 지혜를 가르치는 구절이야.\n"손"은 구체적 행동과 수고를 상징하며, 지금의 수고가 미래의 영향력으로 이어진다는 거야.\n오후 마지막 집중력이 흔들릴 때, 지금 이 손길이 결국 차이를 만들어.',
    application: '오늘 오후 남은 시간, 지금 이 손길이 결국 차이를 만들어. 끝까지 해봐.',
    alarm_top_ko: '부지런한 자의 손은 다스리게 되느니라.',
  },
  {
    verse_id: 'v_244',
    verse_full_ko: '피곤한 자에게는 능력을 주시며 무능한 자에게는 힘을 더하시나니.',
    verse_short_ko: '피곤한 자에게 능력을, 무능한 자에게 힘을 더하시나니.',
    reference: '이사야 40:29',
    book: '이사야',
    chapter: 40,
    verse: 29,
    theme: ['strength', 'patience', 'courage'],
    mood: ['warm', 'dramatic'],
    interpretation: '이사야가 기진한 이스라엘에게 하나님의 성품을 소개하는 구절이야.\n"능력을 주시며"는 없던 것이 생긴다는 뜻 — 내 안에서 나오는 힘이 아니라 위에서 채워지는 거야.\n오후에 힘이 바닥났다고 느낄 때가 사실 채움을 받는 순간이야.',
    application: '지금 힘이 다 떨어진 것 같아도 괜찮아. 그분이 채우실 차례야.',
    alarm_top_ko: '피곤한 자에게 능력을, 무능한 자에게 힘을 더하시나니.',
  },
  {
    verse_id: 'v_245',
    verse_full_ko: '내가 두려워하는 날에는 주를 의지하리이다.',
    verse_short_ko: '내가 두려워하는 날에는 주를 의지하리이다.',
    reference: '시편 56:3',
    book: '시편',
    chapter: 56,
    verse: 3,
    theme: ['courage', 'strength', 'focus'],
    mood: ['warm', 'calm'],
    interpretation: '다윗이 블레셋에게 붙잡혔을 때 쓴 시 — 두렵다는 감정을 부정하지 않고 인정하면서 그분께로 향하는 고백이야.\n"두려워하는 날에는"은 매일이 아닌 가장 힘든 그 순간을 말해.\n오늘 오후 두렵거나 막막한 그 순간, 의지해도 된다는 허락이야.',
    application: '지금 두렵거나 막막하다면 그냥 주를 의지해봐. 그게 믿음이야.',
    alarm_top_ko: '두려워하는 날에는 주를 의지하리이다.',
  },
  {
    verse_id: 'v_246',
    verse_full_ko: '고난 받는 것이 내게 유익이라. 이로 인하여 내가 주의 율례를 배우게 되었나이다.',
    verse_short_ko: '고난이 내게 유익이라, 그로 인해 배우게 되었나이다.',
    reference: '시편 119:71',
    book: '시편',
    chapter: 119,
    verse: 71,
    theme: ['patience', 'wisdom', 'strength'],
    mood: ['calm', 'warm'],
    interpretation: '시편 기자가 어려운 시간 뒤에 돌아보며 쓴 고백 — 힘든 경험이 결국 성숙의 재료가 되었다는 거야.\n"배우게 되었나이다"는 고통이 스승이 될 수 있다는 놀라운 역설이야.\n오늘 오후 버겁다 느껴지는 것들이 사실 내 안에 무언가를 새기고 있어.',
    application: '오늘 힘든 이 순간이 내 안에 무언가를 새기고 있어. 그냥 버텨봐.',
    alarm_top_ko: '고난이 내게 유익이라.',
  },
  {
    verse_id: 'v_247',
    verse_full_ko: '우리가 사방으로 우겨쌈을 당하여도 싸이지 아니하며 답답한 일을 당하여도 낙심하지 아니하며.',
    verse_short_ko: '사방으로 우겨쌈을 당하여도 낙심하지 아니하며.',
    reference: '고린도후서 4:8',
    book: '고린도후서',
    chapter: 4,
    verse: 8,
    theme: ['strength', 'patience', 'courage'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 복음을 위해 감당한 고난의 목록 — 눌려도 무너지지 않는 이유는 내 힘이 아니야.\n"낙심하지 아니하며"는 상황이 아닌 내면의 상태를 말하는 거야.\n오후가 사방에서 압박해도, 네 중심은 흔들리지 않을 수 있어.',
    application: '지금 사방이 막막해도 낙심하지 않아도 돼. 네 중심은 흔들리지 않아.',
    alarm_top_ko: '사방으로 우겨쌈을 당해도 낙심하지 않노라.',
  },
  {
    verse_id: 'v_248',
    verse_full_ko: '나를 강하게 하신 그리스도 예수 우리 주께 내가 감사함은 나를 충성되이 여겨 내게 직분을 맡기심이니.',
    verse_short_ko: '나를 강하게 하신 그리스도께 감사하며 충성으로 맡은 바를.',
    reference: '디모데전서 1:12',
    book: '디모데전서',
    chapter: 1,
    verse: 12,
    theme: ['strength', 'courage', 'focus'],
    mood: ['warm', 'dramatic'],
    interpretation: '바울이 자신의 과거를 돌아보며 지금 이 자리에 있는 것이 은혜임을 고백하는 구절이야.\n"충성되이 여겨"는 부족해도 신뢰받았다는 뜻 — 완벽해야 쓰임받는 게 아니야.\n오늘 오후 지쳐도, 그분이 나를 신뢰하고 이 자리에 세우셨음을 기억해봐.',
    application: '오늘 오후 지치더라도, 그분이 이미 너를 신뢰하고 여기 세우셨어. 기억해봐.',
    alarm_top_ko: '나를 강하게 하신 그리스도께 감사하노라.',
  },
  {
    verse_id: 'v_249',
    verse_full_ko: '여호와는 나의 힘이요 노래시며 나의 구원이시로다.',
    verse_short_ko: '여호와는 나의 힘이요 노래시며 나의 구원이시로다.',
    reference: '출애굽기 15:2',
    book: '출애굽기',
    chapter: 15,
    verse: 2,
    theme: ['strength', 'courage', 'wisdom'],
    mood: ['warm', 'dramatic'],
    interpretation: '이스라엘이 홍해를 건넌 뒤 지쳐 쓰러질 만한 상황에서 터져 나온 노래야.\n"힘이요 노래시며"는 단순한 에너지가 아니라 기쁨의 원천이 되신다는 고백이야.\n지쳐가는 오후, 그분이 힘이 되신다는 사실 자체가 노래가 될 수 있어.',
    application: '지금 지쳐가고 있다면, 그분이 네 힘이심을 소리 내어 한 번 말해봐.',
    alarm_top_ko: '여호와는 나의 힘이요 나의 구원이시로다.',
  },
  {
    verse_id: 'v_250',
    verse_full_ko: '우리가 환난 중에도 즐거워하나니 이는 환난은 인내를, 인내는 연단을, 연단은 소망을 이루는 줄 앎이로다.',
    verse_short_ko: '환난은 인내를, 인내는 연단을, 연단은 소망을 이루느니라.',
    reference: '로마서 5:3-4',
    book: '로마서',
    chapter: 5,
    verse: 3,
    theme: ['patience', 'strength', 'wisdom'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 믿음 안에서 고난을 바라보는 시각 — 고통이 단순한 끝이 아니라 연결된 성장 과정이야.\n"인내→연단→소망"은 지금의 어려움이 결국 소망으로 이어진다는 확신이야.\n오늘 오후 버거운 이 시간이 내 안에 소망을 만들고 있어.',
    application: '오늘 오후가 힘들수록 그 안에서 소망이 자라고 있어. 그걸 믿어봐.',
    alarm_top_ko: '환난은 인내를, 인내는 소망을 이루느니라.',
  },
  {
    verse_id: 'v_251',
    verse_full_ko: '여호와여, 우리를 돌이켜 주소서. 그리하시면 우리가 돌아오겠나이다. 우리의 날을 다시 새롭게 하소서.',
    verse_short_ko: '우리를 돌이켜 주소서, 우리의 날을 새롭게 하소서.',
    reference: '예레미야애가 5:21',
    book: '예레미야애가',
    chapter: 5,
    verse: 21,
    theme: ['strength', 'patience', 'courage'],
    mood: ['calm', 'warm'],
    interpretation: '예루살렘이 무너진 후 쓴 슬픔의 기도 — 절망 끝에서도 포기하지 않고 하나님께 돌아가길 구하는 기도야.\n"새롭게 하소서"는 과거로 돌아가는 게 아니라 지금부터 다시 시작해달라는 요청이야.\n오늘 오후 지쳐 있다면, 지금 이 순간부터 새롭게 시작할 수 있다는 거야.',
    application: '오늘 오후가 무거워도 지금 이 순간부터 새롭게 시작할 수 있어. 그분께 구해봐.',
    alarm_top_ko: '우리의 날을 다시 새롭게 하소서.',
  },
  {
    verse_id: 'v_252',
    verse_full_ko: '인내를 온전히 이루라. 이는 너희로 온전하고 구비하여 조금도 부족함이 없게 하려 함이라.',
    verse_short_ko: '인내를 온전히 이루라, 조금도 부족함이 없게 하려 함이라.',
    reference: '야고보서 1:4',
    book: '야고보서',
    chapter: 1,
    verse: 4,
    theme: ['patience', 'wisdom', 'strength'],
    mood: ['calm', 'warm'],
    interpretation: '야고보가 시험을 기뻐하라 한 직후의 말씀 — 참는 것이 목적이 아니라 성숙해지는 것이 목적이야.\n"온전하고 구비하여"는 아무것도 부족하지 않은 완성된 사람을 가리켜.\n오늘 오후 마지막 인내가 나를 더 단단하게 만들어가고 있어.',
    application: '오늘 오후 이 인내가 헛된 게 아니야. 지금 너를 완성해가고 있어.',
    alarm_top_ko: '인내를 온전히 이루라.',
  },
  {
    verse_id: 'v_253',
    verse_full_ko: '평강의 하나님이 친히 너희로 온전히 거룩하게 하시고 또 너희 온 영과 혼과 몸이 우리 주 예수 그리스도 강림하실 때에 흠 없게 보전되기를 원하노라.',
    verse_short_ko: '평강의 하나님이 너희를 온전히 보전하시길 원하노라.',
    reference: '데살로니가전서 5:23',
    book: '데살로니가전서',
    chapter: 5,
    verse: 23,
    theme: ['patience', 'wisdom', 'strength'],
    mood: ['calm', 'warm'],
    interpretation: '바울이 편지를 마무리하며 공동체 전체를 위해 축복한 기도야.\n"온전히 보전되기를"은 지금 흔들리고 지쳐 있어도 하나님이 붙잡고 계신다는 약속이야.\n오후 마무리가 버거울 때, 그분이 먼저 나를 보전하고 계심을 기억해봐.',
    application: '오늘 오후 지치고 흔들려도 그분이 너를 붙잡고 계셔. 안심하고 마무리해봐.',
    alarm_top_ko: '평강의 하나님이 너를 온전히 보전하시리.',
  },
  {
    verse_id: 'v_254',
    verse_full_ko: '무슨 일을 하든지 마음을 다하여 주께 하듯 하고 사람에게 하듯 하지 말라.',
    verse_short_ko: '무슨 일이든 마음을 다해 주께 하듯 하라.',
    reference: '골로새서 3:23',
    book: '골로새서',
    chapter: 3,
    verse: 23,
    theme: ['focus', 'wisdom', 'strength'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 종들에게 쓴 말씀이지만 모든 일하는 이에게 적용되는 원칙이야.\n"주께 하듯"은 의미 없어 보이는 일에도 거룩한 의미를 부여하는 시각이야.\n오후 남은 업무가 의미 없어 보여도, 그분을 위해 하는 일로 다시 바라봐.',
    application: '지금 하는 일이 사소해 보여도 주께 하듯 마음 한 번 다잡아봐.',
    alarm_top_ko: '무슨 일이든 주께 하듯 하라.',
  },
  {
    verse_id: 'v_255',
    verse_full_ko: '지혜는 그 얻은 자에게 생명 나무라. 지혜를 가진 자는 복되도다.',
    verse_short_ko: '지혜는 생명 나무요, 지혜를 가진 자는 복되도다.',
    reference: '잠언 3:18',
    book: '잠언',
    chapter: 3,
    verse: 18,
    theme: ['wisdom', 'focus', 'strength'],
    mood: ['calm', 'warm'],
    interpretation: '잠언에서 지혜는 추상적 개념이 아니라 살아 있는 나무처럼 생명력이 있는 것으로 묘사돼.\n"생명 나무"는 창세기 에덴의 이미지 — 지혜가 삶을 풍요롭게 한다는 표현이야.\n오후 판단이 필요할 때, 지혜를 구하는 것 자체가 가장 강한 선택이야.',
    application: '오늘 오후 막히는 결정이 있다면 지혜를 구해봐. 그게 진짜 강한 거야.',
    alarm_top_ko: '지혜는 생명 나무요, 지혜 가진 자는 복되도다.',
  },
  {
    verse_id: 'v_256',
    verse_full_ko: '너희는 약한 손을 강하게 하며 떨리는 무릎을 굳게 하며, 두려운 마음을 가진 자에게 이르기를 굳세어라 두려워 말라 보라 너희 하나님이 오사 보복하시며 갚으시리니 하나님이 오사 너희를 구하시리라.',
    verse_short_ko: '굳세어라, 두려워 말라. 하나님이 오사 너희를 구하시리라.',
    reference: '이사야 35:3-4',
    book: '이사야',
    chapter: 35,
    verse: 3,
    theme: ['strength', 'courage', 'patience'],
    mood: ['warm', 'dramatic'],
    interpretation: '광야 복귀를 예언하며 지친 이스라엘에게 선포된 말씀 — 지금 당장 상황이 달라지지 않아도 하나님이 오신다는 약속이야.\n"굳세어라"는 상황이 아닌 그분의 오심을 믿고 버티라는 말이야.\n오후 마지막 힘이 빠질 때도, 혼자 버티는 게 아님을 기억해봐.',
    application: '지금 피곤해도 괜찮아. 혼자가 아니야. 그분이 오고 계셔.',
    alarm_top_ko: '굳세어라 두려워 말라, 하나님이 오사 구하시리라.',
  },
  {
    verse_id: 'v_257',
    verse_full_ko: '너희는 내게 부르짖으며 와서 내게 기도하면 내가 너희를 들을 것이요.',
    verse_short_ko: '내게 부르짖으며 와서 기도하면 내가 들으리라.',
    reference: '예레미야 29:12',
    book: '예레미야',
    chapter: 29,
    verse: 12,
    theme: ['patience', 'wisdom', 'focus'],
    mood: ['calm', 'warm'],
    interpretation: '바벨론 포로로 끌려간 이스라엘에게 하나님이 보내신 편지 중 한 구절이야.\n"부르짖으며"는 예의 바른 기도가 아니라 진심의 외침을 기다리신다는 뜻이야.\n오후 막막할 때 정중하게 아닌 솔직하게 그냥 불러봐. 그분이 들으셔.',
    application: '오늘 오후 막막하다면 형식 없이 그냥 불러봐. 그분이 듣고 계셔.',
    alarm_top_ko: '내게 부르짖으며 기도하면 내가 들으리라.',
  },
  {
    verse_id: 'v_258',
    verse_full_ko: '여호와께서 네 출입을 지금부터 영원까지 지키시리로다.',
    verse_short_ko: '여호와께서 네 출입을 지금부터 영원까지 지키시리로다.',
    reference: '시편 121:8',
    book: '시편',
    chapter: 121,
    verse: 8,
    theme: ['strength', 'courage', 'patience'],
    mood: ['warm', 'calm'],
    interpretation: '순례시 마지막 구절 — 하나님이 오고 가는 모든 것, 일상의 모든 움직임을 지키신다는 선포야.\n"출입"은 단순한 이동이 아니라 모든 삶의 활동을 포괄하는 표현이야.\n오늘 오후의 모든 걸음도 그분이 함께 지키시고 있어.',
    application: '오늘 오후 남은 시간, 네 모든 걸음을 그분이 지키고 계셔. 안심해봐.',
    alarm_top_ko: '여호와께서 네 출입을 영원히 지키시리로다.',
  },
  {
    verse_id: 'v_259',
    verse_full_ko: '사랑하는 자여, 네 영혼이 잘됨 같이 네가 범사에 잘되고 강건하기를 내가 간구하노라.',
    verse_short_ko: '네 영혼이 잘됨 같이 범사에 잘되고 강건하기를 간구하노라.',
    reference: '요한삼서 1:2',
    book: '요한삼서',
    chapter: 1,
    verse: 2,
    theme: ['strength', 'wisdom', 'focus'],
    mood: ['warm', 'calm'],
    interpretation: '사도 요한이 가이오에게 쓴 편지의 첫 인사 — 영적 건강이 삶 전체로 이어지길 바라는 진심이야.\n"강건하기를"은 몸과 마음 모두의 건강을 포괄하는 축복이야.\n오늘 오후 지쳐 있다면, 이 축복이 지금 이 순간 너에게도 향해 있어.',
    application: '지금 지쳐 있어도 이 축복이 오늘 너에게도 향해 있어. 그걸 받아봐.',
    alarm_top_ko: '네 영혼이 잘됨 같이 범사에 강건하기를.',
  },
];

// ─── 업로드 ─────────────────────────────────────────────────────────────────

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  // 헤더 확인
  const headerResp = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A1:AG1`,
  });
  const headers = headerResp.data.values?.[0] || [];
  console.log('Headers:', headers.join(', '));

  // 각 구절을 행으로 변환
  // A:verse_id, B:verse_short_ko, C:verse_full_ko, D:reference, E:book,
  // F:chapter, G:verse, H:mode, I:theme, J:mood, K:season, L:weather,
  // M:interpretation, N:application, O:curated, P:status, Q:notes,
  // R:usage_count, S:cooldown_days, T:last_shown, U:show_count,
  // V:alarm_top_ko
  // W~Z, AA~AG: 수식 자동 / 비워둠
  const rows = verses.map(v => [
    v.verse_id,                          // A: verse_id
    v.verse_short_ko,                    // B: verse_short_ko
    v.verse_full_ko,                     // C: verse_full_ko
    v.reference,                         // D: reference
    v.book,                              // E: book
    v.chapter,                           // F: chapter
    v.verse,                             // G: verse
    'second_wind',                       // H: mode
    v.theme.join(','),                   // I: theme
    v.mood.join(','),                    // J: mood
    'all',                               // K: season
    'any',                               // L: weather
    v.interpretation,                    // M: interpretation
    v.application,                       // N: application
    'TRUE',                              // O: curated
    'active',                            // P: status
    '',                                  // Q: notes
    '0',                                 // R: usage_count
    '7',                                 // S: cooldown_days
    '',                                  // T: last_shown
    '0',                                 // U: show_count
    v.alarm_top_ko,                      // V: alarm_top_ko
  ]);

  const resp = await sheets.spreadsheets.values.append({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:V`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });

  console.log(`\n추가 완료: ${resp.data.updates?.updatedRows}행`);
  console.log(`범위: ${resp.data.updates?.updatedRange}`);
  console.log('\n생성된 구절 목록:');
  verses.forEach(v => {
    console.log(`  ${v.verse_id} | ${v.reference} | ${v.verse_short_ko.slice(0, 25)}...`);
  });
}

main().catch(err => {
  console.error('오류:', err.message);
  process.exit(1);
});
