/**
 * DailyVerse — golden_hour Zone 구절 추가 스크립트
 * v_380 ~ v_399 (20개)
 * Zone: golden_hour (저녁 18-21시, 하루 수고 인정·감사·관계 회복·저녁 평안)
 *
 * 사용법:
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 node upload_golden_hour_v380_v399.js
 */

const { google } = require('googleapis');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

// ─── 콘텐츠 데이터 ────────────────────────────────────────────────────────────
// 번역본: 개역한글 (대한성서공회, 1961)
// Zone: golden_hour — 감사, 관계, 저녁 평안, 돌아봄
// 기존 중복 제외: 시편 37:4, 고전 13:4-5, 시편 91:4, 요 14:27, 시편 23:5-6,
//   시편 27:13-14, 시편 118:24, 롬 12:1, 시편 23:1-2, 벧전 5:7, 시편 145:8,
//   요 15:5, 고후 4:17, 엡 6:10-11, 시편 103:2, 시편 100:4, 엡 4:32

const verses = [
  {
    verse_id: 'v_380',
    verse_full_ko: '여호와께 감사하라 그는 선하시며 그 인자하심이 영원함이로다.',
    verse_short_ko: '여호와께 감사하라, 그 인자하심이 영원함이로다.',
    reference: '시편 136:1',
    book: '시편',
    chapter: 136,
    verse: 1,
    theme: ['gratitude', 'reflection'],
    mood: ['warm', 'calm'],
    interpretation: '시편 136편은 이스라엘이 하나님의 구원 역사를 돌아보며 감사로 응답하는 노래야.\n"인자하심이 영원함이로다"는 오늘 하루도, 힘들었던 순간도 그분의 사랑 안에 있었다는 고백이야.\n저녁 노을 아래, 오늘 하루를 그 인자하심으로 돌아보는 시간이야.',
    application: '오늘 하루 중 감사한 일 하나를 떠올리며 그분께 감사를 전해봐.',
    alarm_top_ko: '여호와께 감사하라, 그 인자하심이 영원함이로다.',
  },
  {
    verse_id: 'v_381',
    verse_full_ko: '룻이 가로되 당신이 죽는 곳에서 나도 죽어 거기 장사될 것이라 만일 내가 죽는 일 외에 당신을 떠나면 여호와께서 내게 벌을 내리시고 더 내리시기를 원하나이다 하는지라.',
    verse_short_ko: '당신이 죽는 곳에서 나도 죽어 거기 장사될 것이라.',
    reference: '룻기 1:17',
    book: '룻기',
    chapter: 1,
    verse: 17,
    theme: ['comfort', 'reflection'],
    mood: ['warm', 'calm'],
    interpretation: '룻이 시어머니 나오미를 따라 낯선 땅으로 향하며 한 고백 — 떠나도 이해받을 상황에서도 함께하기로 선택한 사랑이야.\n이 헌신은 의무가 아니라 진심에서 나온 거야.\n저녁 식탁에서 함께하는 사람에게, 오늘 나는 어떤 선택을 했는지 돌아봐봐.',
    application: '오늘 저녁, 곁에 있는 사람에게 감사 한 마디를 건네봐.',
  },
  {
    verse_id: 'v_382',
    verse_full_ko: '보아스가 룻에게 이르되 내 딸아 들으라 다른 밭으로 이삭을 주우러 가지 말며 여기서 떠나지 말고 나의 소녀들과 함께 있으라.',
    verse_short_ko: '이 밭에서 떠나지 말고 나의 소녀들과 함께 있으라.',
    reference: '룻기 2:8',
    book: '룻기',
    chapter: 2,
    verse: 8,
    theme: ['comfort', 'peace'],
    mood: ['warm', 'calm'],
    interpretation: '보아스가 이방인 룻에게 내 밭에 머물러도 된다고 말하는 장면이야.\n낯선 이에게 보인 배려와 환대 — "머물러도 돼"라는 말 한마디가 룻의 두려움을 쉬게 했어.\n오늘 저녁, 누군가에게 따뜻한 자리를 내어주는 사람이 되어봐봐.',
    application: '오늘 저녁 누군가를 따뜻하게 맞이해봐. 그 환대가 기적을 시작하게 해.',
  },
  {
    verse_id: 'v_383',
    verse_full_ko: '사랑은 오래 참고 사랑은 온유하며 투기하는 자가 되지 아니하며 사랑은 자랑하지 아니하며 교만하지 아니하며.',
    verse_short_ko: '사랑은 오래 참고 온유하며 자랑하지 아니하느니라.',
    reference: '고린도전서 13:4',
    book: '고린도전서',
    chapter: 13,
    verse: 4,
    theme: ['reflection', 'peace'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 고린도 공동체에게 진짜 사랑이 무엇인지 가르치는 구절이야.\n"오래 참고 온유하며"는 관계 속에서 날마다 연습해야 하는 구체적인 모습이야.\n오늘 저녁, 가족이나 가까운 사람과의 관계에서 내가 이 사랑에 얼마나 닮아있는지 조용히 돌아봐봐.',
    application: '오늘 저녁 가장 가까운 사람에게 더 온유하게 대해봐. 그게 사랑이야.',
    alarm_top_ko: '사랑은 오래 참고 온유하며 교만하지 않느니라.',
  },
  {
    verse_id: 'v_384',
    verse_full_ko: '형제를 사랑하여 서로 우애하고 존경하기를 서로 먼저 하며.',
    verse_short_ko: '서로 우애하고 존경하기를 서로 먼저 하라.',
    reference: '로마서 12:10',
    book: '로마서',
    chapter: 12,
    verse: 10,
    theme: ['reflection', 'gratitude'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 믿음의 공동체 안에서 어떻게 서로를 대해야 하는지 가르치는 구절이야.\n"먼저 하며"는 상대방이 먼저 하길 기다리지 않는 자세 — 작은 선도가 관계를 바꿔.\n오늘 저녁, 내 주변 사람에게 내가 먼저 존경과 사랑을 표현해봐봐.',
    application: '오늘 저녁 가까운 사람에게 내가 먼저 다가가 따뜻한 말 한마디 건네봐.',
    alarm_top_ko: '서로 우애하고 존경하기를 서로 먼저 하라.',
  },
  {
    verse_id: 'v_385',
    verse_full_ko: '온유한 대답은 분노를 쉬게 하여도 과격한 말은 노를 격동하느니라.',
    verse_short_ko: '온유한 대답은 분노를 쉬게 하느니라.',
    reference: '잠언 15:1',
    book: '잠언',
    chapter: 15,
    verse: 1,
    theme: ['peace', 'reflection'],
    mood: ['calm', 'warm'],
    interpretation: '잠언 기자가 말의 방식이 관계를 살리기도 죽이기도 한다고 가르치는 구절이야.\n"온유한 대답"은 내용이 아니라 태도에 관한 것 — 같은 말도 어떻게 하느냐가 달라.\n오늘 저녁, 가족이나 가까운 이와의 대화에서 한 박자 더 느리게 말해봐봐.',
    application: '오늘 저녁 누군가와 이야기할 때 한 박자 느리게, 더 온유하게 말해봐.',
    alarm_top_ko: '온유한 대답은 분노를 쉬게 하느니라.',
  },
  {
    verse_id: 'v_386',
    verse_full_ko: '여호와여, 주의 자비와 인자하심이 영원부터 있었사오니 주여 이것을 내게 기억하옵소서.',
    verse_short_ko: '주의 자비와 인자하심이 영원부터 있었나이다.',
    reference: '시편 25:6',
    book: '시편',
    chapter: 25,
    verse: 6,
    theme: ['gratitude', 'comfort'],
    mood: ['calm', 'warm'],
    interpretation: '다윗이 기도 중에 하나님의 오래된 사랑을 기억하며 의탁하는 구절이야.\n"영원부터"는 나의 실패나 오늘의 부족함과 상관없이 그 사랑은 이미 거기 있었다는 뜻이야.\n오늘 저녁, 오래된 그 사랑이 지금도 나를 향해 있다는 걸 기억해봐봐.',
    application: '오늘 저녁 그분의 오래된 사랑을 한 번 묵상해봐. 그 사랑이 오늘도 여기 있어.',
    alarm_top_ko: '주의 자비와 인자하심이 영원부터 있었나이다.',
  },
  {
    verse_id: 'v_387',
    verse_full_ko: '너는 마음을 다하여 여호와를 의뢰하고 네 명철을 의지하지 말라.',
    verse_short_ko: '마음을 다하여 여호와를 의뢰하고 네 명철을 의지하지 말라.',
    reference: '잠언 3:5',
    book: '잠언',
    chapter: 3,
    verse: 5,
    theme: ['reflection', 'peace'],
    mood: ['calm', 'warm'],
    interpretation: '잠언 기자가 삶의 방향을 잡는 원칙으로 제시한 구절이야.\n"네 명철을 의지하지 말라"는 내 판단을 완전히 버리라는 게 아니라, 그분의 인도를 먼저 구하라는 말이야.\n오늘 하루 내 뜻대로 결정했던 순간들을 저녁에 조용히 내려놓아봐봐.',
    application: '오늘 하루 내가 내 힘으로 붙들었던 것들을 저녁에 그분께 내려놓아봐.',
    alarm_top_ko: '마음을 다하여 여호와를 의뢰하고 명철을 의지하지 말라.',
  },
  {
    verse_id: 'v_388',
    verse_full_ko: '그러므로 우리가 기회 있는 대로 모든 이에게 착한 일을 하되 더욱 믿음의 가정들에게 할찌니라.',
    verse_short_ko: '기회 있는 대로 모든 이에게 착한 일을 하라.',
    reference: '갈라디아서 6:10',
    book: '갈라디아서',
    chapter: 6,
    verse: 10,
    theme: ['gratitude', 'reflection'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 성령을 따라 사는 삶의 열매로 선행을 제시하는 구절이야.\n"기회 있는 대로"는 특별한 순간을 기다리지 말고 지금 이 순간을 살라는 말이야.\n오늘 저녁, 돌아오는 길에 혹은 식탁에서 착한 일 하나를 실천할 기회가 있어.',
    application: '오늘 저녁 집에 돌아오면 가족에게 먼저 따뜻한 행동 하나를 해봐.',
    alarm_top_ko: '기회 있는 대로 모든 이에게 착한 일을 하라.',
  },
  {
    verse_id: 'v_389',
    verse_full_ko: '마음의 즐거움은 양약이라도 심령의 근심은 뼈로 마르게 하느니라.',
    verse_short_ko: '마음의 즐거움은 양약이요 심령의 근심은 뼈를 마르게 하느니라.',
    reference: '잠언 17:22',
    book: '잠언',
    chapter: 17,
    verse: 22,
    theme: ['comfort', 'peace'],
    mood: ['warm', 'calm'],
    interpretation: '잠언 기자가 마음의 상태가 몸에 직접 영향을 준다는 지혜를 가르치는 구절이야.\n"양약"은 오늘날 말로 최고의 치료제 — 즐거움이 근심보다 더 강하다는 거야.\n오늘 저녁 마음속 근심을 잠시 내려놓고 작은 기쁨 하나를 찾아봐봐.',
    application: '오늘 저녁 작은 기쁨 하나를 찾아봐. 그 즐거움이 몸과 마음을 낫게 해줘.',
    alarm_top_ko: '마음의 즐거움은 양약이라.',
  },
  {
    verse_id: 'v_390',
    verse_full_ko: '두 사람이 한 사람보다 나음은 저희가 수고함으로 좋은 상을 얻을 것임이라.',
    verse_short_ko: '두 사람이 한 사람보다 나음은 좋은 상을 함께 얻기 때문이라.',
    reference: '전도서 4:9',
    book: '전도서',
    chapter: 4,
    verse: 9,
    theme: ['gratitude', 'reflection'],
    mood: ['warm', 'calm'],
    interpretation: '전도자가 혼자가 아닌 함께하는 삶의 지혜를 이야기하는 구절이야.\n"함께 수고함"은 결과만이 아니라 과정을 나누는 관계의 소중함을 말해.\n오늘 저녁, 하루를 함께 버텨준 사람을 떠올리며 감사해봐봐.',
    application: '오늘 하루를 함께한 사람에게 "고마워"라고 말해봐. 그 한마디가 충분해.',
    alarm_top_ko: '두 사람이 한 사람보다 나음은 함께 상을 얻기 때문이라.',
  },
  {
    verse_id: 'v_391',
    verse_full_ko: '그가 넘어지는 때에는 아주 엎드러지지 아니함은 여호와께서 그 손으로 붙드심이로다.',
    verse_short_ko: '넘어지는 때에도 여호와께서 손으로 붙드시느니라.',
    reference: '시편 37:24',
    book: '시편',
    chapter: 37,
    verse: 24,
    theme: ['comfort', 'peace'],
    mood: ['calm', 'warm'],
    interpretation: '다윗이 의인의 삶을 노래하는 시 — 넘어질 수 있어도 완전히 쓰러지지 않는 이유가 있다는 거야.\n"손으로 붙드심"은 그분이 팔짱 끼고 지켜보는 게 아니라 직접 잡아주신다는 뜻이야.\n오늘 저녁 힘들었던 순간을 돌아보면, 그 순간에도 붙들어 주신 분이 계셨어.',
    application: '오늘 하루 힘들었던 순간 하나를 떠올려봐. 그 순간에도 붙들고 계셨어.',
    alarm_top_ko: '넘어지는 때에도 여호와께서 손으로 붙드시느니라.',
  },
  {
    verse_id: 'v_392',
    verse_full_ko: '이것이 나의 위로라 내 곤고 중에 주의 말씀이 나를 살리셨음이니이다.',
    verse_short_ko: '주의 말씀이 나를 살리셨으니 이것이 나의 위로니이다.',
    reference: '시편 119:50',
    book: '시편',
    chapter: 119,
    verse: 50,
    theme: ['comfort', 'reflection'],
    mood: ['calm', 'warm'],
    interpretation: '시편 기자가 극심한 고난 속에서도 버텨낸 힘이 하나님의 말씀이었다고 고백하는 구절이야.\n"살리셨음이니이다"는 육체적 생존이 아니라 영혼이 다시 일어섰다는 뜻이야.\n오늘 저녁 돌아오는 길, 오늘 하루를 버티게 한 위로가 무엇인지 생각해봐봐.',
    application: '오늘 하루 나를 버티게 한 위로 하나를 떠올리며 감사해봐. 그게 살리심이야.',
    alarm_top_ko: '주의 말씀이 나를 살리셨으니 이것이 나의 위로니이다.',
  },
  {
    verse_id: 'v_393',
    verse_full_ko: '내 하나님이 그 풍성한 대로 그리스도 예수 안에서 영광 가운데 그 쓸 것을 채우시리라.',
    verse_short_ko: '하나님이 그 풍성한 대로 그 쓸 것을 채우시리라.',
    reference: '빌립보서 4:19',
    book: '빌립보서',
    chapter: 4,
    verse: 19,
    theme: ['gratitude', 'peace'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 빌립보 교인들의 헌신에 감사하며 약속한 말씀 — 주신 분이 필요도 아신다는 신뢰야.\n"풍성한 대로"는 내 기준이 아닌 그분의 풍성함이 기준이야.\n오늘 저녁 부족한 것들보다 채워주신 것들을 먼저 떠올려봐봐.',
    application: '오늘 저녁 부족한 것 말고, 이미 채워주신 것들을 적어봐. 하나씩.',
    alarm_top_ko: '하나님이 그 풍성한 대로 쓸 것을 채우시리라.',
  },
  {
    verse_id: 'v_394',
    verse_full_ko: '화평케 하는 자는 복이 있나니 저희가 하나님의 아들이라 일컬음을 받을 것임이요.',
    verse_short_ko: '화평케 하는 자는 복이 있나니 하나님의 아들이라 일컬음을 받으리',
    reference: '마태복음 5:9',
    book: '마태복음',
    chapter: 5,
    verse: 9,
    theme: ['peace', 'reflection'],
    mood: ['calm', 'warm'],
    interpretation: '예수님의 산상수훈 팔복 중 하나 — 화평케 하는 자란 갈등을 피하는 사람이 아니라 적극적으로 화목을 만드는 사람이야.\n"하나님의 아들"은 하나님이 화평을 만드시는 분이기 때문에 그를 닮은 자라는 의미야.\n오늘 저녁, 내 주변에 화목을 심을 수 있는 작은 기회가 있어.',
    application: '오늘 저녁 관계가 어긋난 사람에게 먼저 연락하거나 따뜻한 말 한마디 해봐.',
    alarm_top_ko: '화평케 하는 자는 복이 있나니 하나님의 아들이라 일컬음을 받으리',
  },
  {
    verse_id: 'v_395',
    verse_full_ko: '사람이 무엇으로 심든지 그대로 거두리라.',
    verse_short_ko: '사람이 무엇으로 심든지 그대로 거두리라.',
    reference: '갈라디아서 6:7',
    book: '갈라디아서',
    chapter: 6,
    verse: 7,
    theme: ['reflection', 'gratitude'],
    mood: ['calm', 'warm'],
    interpretation: '바울이 성령을 따라 씨 뿌리는 삶을 가르치는 구절 — 오늘의 선택이 내일의 열매가 돼.\n"그대로 거두리라"는 심판이 아니라 삶의 원리를 말해 — 오늘 뿌린 것이 쌓인다는 거야.\n오늘 저녁, 하루 동안 내가 심은 것이 무엇인지 조용히 돌아봐봐.',
    application: '오늘 하루 내가 무엇을 심었는지 저녁에 돌아봐. 내일의 씨앗이 되어.',
    alarm_top_ko: '무엇으로 심든지 그대로 거두리라.',
  },
  {
    verse_id: 'v_396',
    verse_full_ko: '형제들아 무엇에든지 참되며 무엇에든지 경건하며 무엇에든지 옳으며 무엇에든지 정결하며 무엇에든지 사랑할만하며 무엇에든지 칭찬할만하며 무슨 덕이 있든지 무슨 기림이 있든지 이것들을 생각하라.',
    verse_short_ko: '참되고 경건하고 옳고 정결한 것을 생각하라.',
    reference: '빌립보서 4:8',
    book: '빌립보서',
    chapter: 4,
    verse: 8,
    theme: ['reflection', 'peace'],
    mood: ['calm', 'warm'],
    interpretation: '바울이 감옥에서 썼음에도 긍정적이고 아름다운 것들을 생각하라고 권면하는 구절이야.\n"생각하라"는 한 번이 아니라 반복적으로 마음에 담으라는 뜻이야.\n오늘 저녁, 하루 중 아름답고 감사한 장면 하나를 마음에 담아봐봐.',
    application: '오늘 하루 중 참되고 사랑할 만한 것 하나를 떠올리며 저녁을 마무리해봐.',
    alarm_top_ko: '참되고 경건하고 사랑할만한 것을 생각하라.',
  },
  {
    verse_id: 'v_397',
    verse_full_ko: '주의 얼굴을 찾으라 하셨으므로 내 마음이 주를 찾았나이다.',
    verse_short_ko: '주를 찾으라 하셨으므로 내 마음이 주를 찾나이다.',
    reference: '시편 27:8',
    book: '시편',
    chapter: 27,
    verse: 8,
    theme: ['reflection', 'peace'],
    mood: ['calm', 'warm'],
    interpretation: '다윗이 두려운 상황 속에서 그분의 얼굴을 구하는 고백이야.\n"얼굴을 찾으라"는 그분과 관계를 이어가는 것을 포기하지 말라는 권유야.\n오늘 저녁, 하루의 분주함을 내려놓고 조용히 그분의 얼굴을 향해 마음을 돌려봐봐.',
    application: '오늘 저녁 잠깐 조용히 앉아 그분의 얼굴을 바라보는 시간을 가져봐.',
    alarm_top_ko: '주를 찾으라 하셨으므로 내 마음이 주를 찾나이다.',
  },
  {
    verse_id: 'v_398',
    verse_full_ko: '네 이웃을 네 몸과 같이 사랑하라.',
    verse_short_ko: '네 이웃을 네 몸과 같이 사랑하라.',
    reference: '레위기 19:18',
    book: '레위기',
    chapter: 19,
    verse: 18,
    theme: ['reflection', 'gratitude'],
    mood: ['warm', 'calm'],
    interpretation: '율법의 정수로 예수님도 인용하신 구절 — 이웃 사랑은 스스로를 사랑하는 것에서 출발해.\n"네 몸과 같이"는 자기 자신을 먼저 귀히 여길 줄 알아야 이웃도 귀히 여길 수 있다는 뜻이야.\n오늘 저녁, 내 주변 이웃에게 내가 받고 싶은 것을 먼저 해줄 수 있어.',
    application: '오늘 저녁 옆에 있는 사람에게 내가 받고 싶은 따뜻함을 먼저 표현해봐.',
    alarm_top_ko: '네 이웃을 네 몸과 같이 사랑하라.',
  },
  {
    verse_id: 'v_399',
    verse_full_ko: '그는 사랑과 화평의 하나님이시니라.',
    verse_short_ko: '그는 사랑과 화평의 하나님이시니라.',
    reference: '고린도후서 13:11',
    book: '고린도후서',
    chapter: 13,
    verse: 11,
    theme: ['peace', 'gratitude'],
    mood: ['warm', 'calm'],
    interpretation: '바울이 편지를 마치며 공동체에게 남긴 마지막 권면의 끝에 붙인 선포야.\n"사랑과 화평의 하나님"은 하나님의 본질이 사랑이며 그분이 있는 곳에 화평이 온다는 뜻이야.\n오늘 저녁을 마무리하며, 그 사랑과 화평이 이 시간 내 안에 있음을 기억해봐봐.',
    application: '오늘 저녁 하루를 닫으며 사랑과 화평의 하나님께 조용히 인사드려봐.',
    alarm_top_ko: '그는 사랑과 화평의 하나님이시니라.',
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
  console.log('Headers:', headers.slice(0, 22).join(', '));

  // 컬럼 순서:
  // A:verse_id, B:verse_short_ko, C:verse_full_ko, D:reference, E:book,
  // F:chapter, G:verse, H:mode, I:theme, J:mood, K:season, L:weather,
  // M:interpretation, N:application, O:curated, P:status, Q:notes,
  // R:usage_count, S:cooldown_days, T:last_shown, U:show_count,
  // V:alarm_top_ko
  // W~AG: 수식 자동 — 비워둠

  const rows = verses.map(v => [
    v.verse_id,                          // A: verse_id
    v.verse_short_ko,                    // B: verse_short_ko
    v.verse_full_ko,                     // C: verse_full_ko
    v.reference,                         // D: reference
    v.book,                              // E: book
    v.chapter,                           // F: chapter
    v.verse,                             // G: verse
    'golden_hour',                       // H: mode
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
    v.alarm_top_ko || '',                // V: alarm_top_ko
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
    const shortPreview = v.verse_short_ko.slice(0, 20);
    console.log(`  ${v.verse_id} | ${v.reference} | ${shortPreview}...`);
  });
}

main().catch(err => {
  console.error('오류:', err.message);
  process.exit(1);
});
