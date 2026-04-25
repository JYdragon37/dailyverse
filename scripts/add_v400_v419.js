/**
 * add_v400_v419.js — v_400~v_419 신규 말씀 20개 Google Sheets VERSES 탭 추가
 *
 * Zone 배분:
 *   v_400~v_404: first_light  (새벽 3-6시)
 *   v_405~v_409: rise_ignite  (아침 6-9시)
 *   v_410~v_414: wind_down    (밤 9-12시)
 *   v_415~v_419: golden_hour  (저녁 6-9시)
 *
 * 번역본: 개역한글 (대한성서공회 1961, 퍼블릭 도메인)
 * 사용법: NODE_TLS_REJECT_UNAUTHORIZED=0 node add_v400_v419.js
 */

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const path = require('path');

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME     = 'VERSES';
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

// ── 헤더 순서 (2026-04-24 확인) ─────────────────────────────────────────────
// A: verse_id, B: verse_short_ko, C: verse_full_ko, D: reference, E: book,
// F: chapter, G: verse, H: mode, I: theme, J: mood, K: season, L: weather,
// M: interpretation, N: application, O: curated, P: status, Q: notes,
// R: usage_count, S: cooldown_days, T: last_shown, U: show_count,
// V: alarm_top_ko, W: contemplation_ko(수식), X: contemplation_reference(수식),
// Y: contemplation_interpretation(수식), Z: contemplation_appliance(수식),
// AA: question, AB~AG: len_* (수식)
//
// 직접 입력: A~V + AA (question)
// 수식 자동: W, X, Y, Z, AB~AG

const VERSES = [
  // ─────────────────────────────────────────────────────────────────────────
  // first_light (v_400~v_404) — 새벽 3-6시, 소선지서/역대서 위주
  // 유저: 이른 새벽 기도·묵상을 위해 일어남. 하루 전의 고요. 영적 준비.
  // application 컨텍스트: 새벽의 고요함, 하루가 시작되기 전의 정적
  // ─────────────────────────────────────────────────────────────────────────
  {
    verse_id:       'v_400',
    verse_short_ko: '내 백성이 스스로 겸비하고 기도하여 내 얼굴을 구하면, 내가 저희 죄를 사하고 그 땅을 고칠지라.',
    verse_full_ko:  '내 이름으로 일컫는 내 백성이 스스로 겸비하고 기도하여 내 얼굴을 구하면,\n내가 하늘에서 듣고 그 죄를 사하고 그 땅을 고칠지라.',
    reference:      '역대하 7:14',
    book:           '역대하',
    chapter:        7,
    verse:          14,
    mode:           'first_light',
    theme:          'faith,renewal',
    mood:           'serene,calm',
    season:         'all',
    weather:        'any',
    interpretation: '솔로몬이 성전을 완공한 날 밤, 하나님이 직접 나타나 하신 약속이야.\n"겸비하고 기도하여 구하면"은 조건이 아닌 자세야. 새벽에 무릎 꿇는 그 태도 자체가 이미 응답의 시작이야.',
    application:    '지금 이 새벽, 아무도 모르는 이 시간에 조용히 무릎 꿇어봐. 그 작은 몸짓을 그분은 하늘에서 듣고 계셔.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '요즘 가장 솔직하게 내려놓고 싶은 것이 있다면 무엇인가요?',
  },
  {
    verse_id:       'v_401',
    verse_short_ko: '여호와를 알자, 힘써 여호와를 알자. 그의 나오심은 새벽빛같이 일정하니.',
    verse_full_ko:  '우리가 여호와를 알자, 힘써 여호와를 알자.\n그의 나오심은 새벽빛같이 일정하니,\n비와 같이, 땅을 적시는 늦은 비와 같이 우리에게 임하시리라.',
    reference:      '호세아 6:3',
    book:           '호세아',
    chapter:        6,
    verse:          3,
    mode:           'first_light',
    theme:          'faith,renewal',
    mood:           'serene,calm',
    season:         'all',
    weather:        'any',
    interpretation: '호세아가 방황하던 이스라엘을 향해 전한 귀환의 선언이야.\n"새벽빛같이 일정하니"는 매일 어김없이 뜨는 새벽처럼 하나님이 흔들리지 않는다는 거야.\n이 새벽, 그분이 이미 너를 향해 오고 계셔.',
    application:    '창을 통해 들어오는 새벽빛을 한번 바라봐. 저 빛처럼 어김없이 너를 찾아오시는 분이 계셔.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '새벽에 홀로 조용히 있어본 경험이 있나요? 그 순간 어떤 느낌이었나요?',
  },
  {
    verse_id:       'v_402',
    verse_short_ko: '보라, 산들을 지으며 바람을 창조하며 그 뜻을 사람에게 보이며, 새벽빛을 만드시는 이가 여호와니라.',
    verse_full_ko:  '보라, 산들을 지으며 바람을 창조하며 그 뜻을 사람에게 보이며,\n새벽빛을 만드시며 땅의 높은 데를 밟으시는 이가 그 이름이 만군의 여호와니라.',
    reference:      '아모스 4:13',
    book:           '아모스',
    chapter:        4,
    verse:          13,
    mode:           'first_light',
    theme:          'faith,stillness',
    mood:           'serene',
    season:         'all',
    weather:        'any',
    interpretation: '아모스가 이스라엘의 교만을 꾸짖으며 선포한 창조주의 위엄이야.\n"새벽빛을 만드시는" 분이 바로 지금 이 새벽의 주인이야.\n눈앞의 캄캄함은 잠시고, 이 새벽을 설계하신 분이 너를 알고 계셔.',
    application:    '지금 이 새벽빛 하나도 그냥 뜨는 게 아니야. 오늘 이 하루를 빚으신 분이 계심을 기억해봐.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   '새벽빛을 만드시는 이가 여호와니라.',
    question:       '지금 이 순간, 당신 삶에서 "새벽빛"처럼 느껴지는 것이 있나요?',
  },
  {
    verse_id:       'v_403',
    verse_short_ko: '여호와는 의로우시므로 불의를 행치 아니하시니라. 새벽마다 어김없이 자기의 공의를 나타내시는도다.',
    verse_full_ko:  '여호와는 그 중에 계시니 의로우시므로 불의를 행치 아니하시고,\n새벽마다 어김없이 자기의 공의를 나타내시거늘.',
    reference:      '스바냐 3:5',
    book:           '스바냐',
    chapter:        3,
    verse:          5,
    mode:           'first_light',
    theme:          'faith,renewal',
    mood:           'serene',
    season:         'all',
    weather:        'any',
    interpretation: '스바냐가 패역한 예루살렘 한가운데서도 하나님은 여전히 계신다고 선언하는 말씀이야.\n"새벽마다 어김없이"는 단 하루도 빠짐없이 성실하게 임하신다는 뜻이야.\n어제가 무너졌어도, 이 새벽 그분은 다시 여기 계셔.',
    application:    '어제 어떤 하루였든 상관없어. 이 새벽에도 그분은 어김없이 여기 계시다는 것, 기억해봐.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '어제 하루 중 아쉬웠던 한 가지가 있다면 무엇인가요?',
  },
  {
    verse_id:       'v_404',
    verse_short_ko: '나는 여호와를 바라보며 구원의 하나님을 기다리리니, 내 하나님이 나를 들으시리로다.',
    verse_full_ko:  '나는 여호와를 바라보며 나의 구원의 하나님을 기다리리니,\n내 하나님이 나를 들으시리로다.\n나의 대적이여, 나로 인하여 기뻐하지 말지어다.\n나는 엎드러질지라도 일어날 것이요, 어둠에 앉을지라도 여호와께서 나의 빛이 되실 것임이로다.',
    reference:      '미가 7:7-8',
    book:           '미가',
    chapter:        7,
    verse:          7,
    mode:           'first_light',
    theme:          'hope,faith',
    mood:           'serene,calm',
    season:         'all',
    weather:        'any',
    interpretation: '미가가 사회 지도층의 배신 속에서도 하나님 한 분을 붙드는 고백이야.\n"어둠에 앉을지라도"는 지금 이 새벽의 어둠도 품고 있어. 엎드러졌다 해도 일어남이 약속되어 있어.\n이 새벽은 넘어진 자리가 아니라 일어서는 자리야.',
    application:    '지금 이 새벽 어두워도 괜찮아. 그분이 빛이 되신다는 걸 붙들고 조용히 기다려봐.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '최근 "어둠 속에 앉아있다"는 느낌이 들었던 때가 있었나요?',
  },

  // ─────────────────────────────────────────────────────────────────────────
  // rise_ignite (v_405~v_409) — 아침 6-9시, 사무엘상/왕상/야고보서/베드로전서
  // 유저: 알람 끄고 이불 속. 나른함+부담+작은 설렘
  // application 컨텍스트: 알람 끄고 30초, 이불 속에서 폰 보는 순간
  // ─────────────────────────────────────────────────────────────────────────
  {
    verse_id:       'v_405',
    verse_short_ko: '여호와께서 그 명예를 위하여 자기 백성을 버리지 아니하실 것이라.',
    verse_full_ko:  '여호와께서는 자기의 크신 이름을 위하여 자기 백성을 버리지 아니하실 것이라.\n여호와께서 기꺼이 너희로 자기 백성을 삼으셨음이니라.',
    reference:      '사무엘상 12:22',
    book:           '사무엘상',
    chapter:        12,
    verse:          22,
    mode:           'rise_ignite',
    theme:          'hope,courage',
    mood:           'bright,dramatic',
    season:         'all',
    weather:        'any',
    interpretation: '사무엘이 왕을 달라 요구한 이스라엘 백성에게, 실망하면서도 포기하지 않는 하나님을 선포하는 말씀이야.\n"기꺼이 너희로 자기 백성을 삼으셨음"은 선택이 취소되지 않는다는 선언이야.\n오늘 하루를 나갈 자격, 그분이 이미 주셨어.',
    application:    '알람 끄고 눈 떠봐. 오늘도 하나님이 버리지 않으신 하루야. 그거 하나면 충분해.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '오늘 하루를 시작하면서 가장 걱정되는 것이 있다면 무엇인가요?',
  },
  {
    verse_id:       'v_406',
    verse_short_ko: '너희 염려를 다 주께 맡겨 버리라. 이는 저가 너희를 돌아보심이니라.',
    verse_full_ko:  '너희 염려를 다 주께 맡겨 버리라. 이는 저가 너희를 돌아보심이니라.',
    reference:      '베드로전서 5:7',
    book:           '베드로전서',
    chapter:        5,
    verse:          7,
    mode:           'rise_ignite',
    theme:          'courage,strength',
    mood:           'bright',
    season:         'all',
    weather:        'any',
    interpretation: '베드로가 박해받는 초대 교회 성도들에게 쓴 편지야.\n"맡겨 버리라"는 이미 다 아는 분께 내려놓는 행위야. 돌보심이 근거가 되어서 염려를 내려놓을 수 있어.\n오늘 아침의 오만 가지 걱정, 일어나기 전에 먼저 드려봐.',
    application:    '이불 속에서 오늘 걱정 하나 떠올려봐. 그걸 먼저 드리고 일어서봐. 그분이 이미 알고 계셔.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   '너희 염려를 다 주께 맡겨 버리라.',
    question:       '요즘 아침에 눈 뜨자마자 떠오르는 걱정이 있다면 무엇인가요?',
  },
  {
    verse_id:       'v_407',
    verse_short_ko: '하나님께 가까이 하라, 그리하면 너희에게 가까이 하시리라.',
    verse_full_ko:  '하나님께 가까이 하라, 그리하면 너희에게 가까이 하시리라.\n죄인들아, 손을 깨끗이 하라. 두 마음을 품은 자들아, 마음을 성결케 하라.',
    reference:      '야고보서 4:8',
    book:           '야고보서',
    chapter:        4,
    verse:          8,
    mode:           'rise_ignite',
    theme:          'renewal,hope',
    mood:           'bright',
    season:         'all',
    weather:        'any',
    interpretation: '야고보서는 말만 있고 실천 없는 신앙에 도전하는 서신이야.\n"가까이 하라"는 거리 싸움에서 한 발 먼저 내딛는 행동이야. 그분이 먼저 오시는 게 아닌 것 같지만, 실은 이미 기다리고 계셔.\n오늘 아침 단 한 발 내딛는 것이 하루를 바꿔.',
    application:    '알람 소리 들리면 폰 들고 잠깐 멈춰봐. 지금 이 자리에서 한 발이면 돼. 그분이 다가오셔.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '요즘 한 발 더 가까이 가고 싶은 것 또는 사람이 있나요?',
  },
  {
    verse_id:       'v_408',
    verse_short_ko: '여호와의 사자가 어루만지며 이르되, 일어나 먹으라. 네가 갈 길이 멀다 하는지라.',
    verse_full_ko:  '천사가 다시 두 번째 어루만지며 이르되, 일어나 먹으라.\n네가 갈 길이 멀다 하는지라.\n이에 일어나 먹고 마시고 그 음식물의 힘을 의지하여 사십 일 사십 야를 행하여.',
    reference:      '열왕기상 19:7',
    book:           '열왕기상',
    chapter:        19,
    verse:          7,
    mode:           'rise_ignite',
    theme:          'strength,courage',
    mood:           'bright,dramatic',
    season:         'all',
    weather:        'any',
    interpretation: '엘리야가 이세벨에게 쫓겨 광야에서 "이제 죽겠다"고 쓰러진 날 밤의 장면이야.\n하나님은 책망 대신 "일어나 먹으라"고 하셨어. 그리고 이유를 말씀하셨어, "네가 갈 길이 멀다"고.\n쓰러졌어도 아직 갈 길이 있다는 게 이 아침의 위로야.',
    application:    '어제 지쳐서 쓰러진 것 같아도 괜찮아. 오늘 이 아침, 일어나 먹고 마셔. 갈 길이 남아 있어.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   '일어나 먹으라. 네가 갈 길이 멀다.',
    question:       '지금 당신에게 "일어나 먹으라" 한마디가 필요했던 순간이 있었나요?',
  },
  {
    verse_id:       'v_409',
    verse_short_ko: '하나님이 그 풍성하신 긍휼을 따라 우리를 거듭나게 하사 산 소망이 있게 하셨도다.',
    verse_full_ko:  '우리 주 예수 그리스도의 아버지 하나님을 찬송하리로다.\n그의 많으신 긍휼대로 예수 그리스도의 죽은 자 가운데서 부활하심으로 말미암아\n우리를 거듭나게 하사 산 소망이 있게 하시며.',
    reference:      '베드로전서 1:3',
    book:           '베드로전서',
    chapter:        1,
    verse:          3,
    mode:           'rise_ignite',
    theme:          'hope,renewal',
    mood:           'bright,dramatic',
    season:         'all',
    weather:        'any',
    interpretation: '베드로가 흩어진 성도들에게 보낸 편지의 첫 찬양이야.\n"산 소망"은 살아있는 희망이야. 죽지 않고 살아 숨 쉬는 기대야.\n오늘 아침 눈을 뜬 이 순간, 그 살아있는 소망이 너에게도 있어.',
    application:    '눈 뜨는 이 순간이 산 소망의 시작이야. 오늘 하루도 그 소망 하나 붙들고 나아가봐.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '요즘 당신에게 "살아있는 기대"를 주는 것이 있다면 무엇인가요?',
  },

  // ─────────────────────────────────────────────────────────────────────────
  // wind_down (v_410~v_414) — 밤 9-12시, 시편/잠언/민수기/고린도후서
  // 유저: 씻고 잠자리에 들기 전. 피로+평안 욕구+내일에 대한 은은한 불안
  // application 컨텍스트: 취침 전 마지막 폰 확인, 잠자리 들기 직전
  // ─────────────────────────────────────────────────────────────────────────
  {
    verse_id:       'v_410',
    verse_short_ko: '내 은혜가 네게 족하도다. 이는 내 능력이 약한 데서 온전하여짐이라.',
    verse_full_ko:  '나의 여러 번 주께 간구하매 이르시기를, 내 은혜가 네게 족하도다.\n이는 내 능력이 약한 데서 온전하여짐이라 하신지라.\n이러므로 도리어 크게 기뻐함으로 나의 여러 약한 것들에 대하여 자랑하리니,\n이는 그리스도의 능력으로 내게 머물게 하려 함이라.',
    reference:      '고린도후서 12:9',
    book:           '고린도후서',
    chapter:        12,
    verse:          9,
    mode:           'wind_down',
    theme:          'peace,comfort',
    mood:           'cozy,calm',
    season:         'all',
    weather:        'any',
    interpretation: '바울이 "육체의 가시"를 떼어달라고 세 번이나 간구했을 때, 하나님이 주신 응답이야.\n"족하도다"는 충분하다는 선언이야. 부족한 채로도 은혜 안에 있을 수 있어.\n오늘 내가 부족했던 것들, 그것도 그분 안에서 괜찮아.',
    application:    '자기 전에 오늘 부족했던 것 하나 떠올려봐. 그래도 은혜가 충분하다는 말, 받아봐.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   '내 은혜가 네게 족하도다.',
    question:       '오늘 하루 "이게 부족했다"고 느낀 것이 있다면 무엇인가요?',
  },
  {
    verse_id:       'v_411',
    verse_short_ko: '여호와는 네게 복을 주시고 너를 지키시기를 원하노라.',
    verse_full_ko:  '여호와는 네게 복을 주시고 너를 지키시기를 원하노라.\n여호와는 그 얼굴로 네게 비취사 은혜 베푸시기를 원하노라.\n여호와는 그 얼굴을 네게로 향하여 드사 평강 주시기를 원하노라.',
    reference:      '민수기 6:24-26',
    book:           '민수기',
    chapter:        6,
    verse:          24,
    mode:           'wind_down',
    theme:          'peace,rest',
    mood:           'cozy,calm',
    season:         'all',
    weather:        'any',
    interpretation: '광야에서 아론과 제사장들이 이스라엘 백성에게 선포하도록 하나님이 직접 명하신 축복이야.\n"그 얼굴을 향하여 드사"는 고개를 돌려 너를 정면으로 바라보신다는 거야.\n오늘 밤, 그 시선 아래서 쉬어도 돼.',
    application:    '이 기도가 오늘 밤 너를 위한 말씀이야. 그 얼굴빛이 네게 비추는 중이야. 편히 쉬어봐.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   '여호와는 네게 복을 주시고 너를 지키시기를 원하노라.',
    question:       '오늘 밤 당신을 가장 편안하게 해주는 것은 무엇인가요?',
  },
  {
    verse_id:       'v_412',
    verse_short_ko: '여호와께서 너의 의지하는 바가 되시며, 네 발을 지켜 걸리지 않게 하시리라.',
    verse_full_ko:  '대저 여호와는 너의 의지하는 바가 되시며, 네 발을 지켜 걸리지 않게 하시리라.',
    reference:      '잠언 3:26',
    book:           '잠언',
    chapter:        3,
    verse:          26,
    mode:           'wind_down',
    theme:          'stillness,peace',
    mood:           'calm',
    season:         'all',
    weather:        'any',
    interpretation: '잠언 3장은 지혜로운 삶의 기초로 하나님 신뢰를 선언해.\n"발을 지켜 걸리지 않게"는 어두운 밤길에서도 넘어지지 않도록 붙드신다는 거야.\n오늘 하루 어디서 걸렸든, 오늘 밤 그분이 너의 발을 잡고 계셔.',
    application:    '잠자리에 들면서 오늘 넘어질 뻔했던 순간을 그분께 맡겨봐. 그 발을 지키신다고 하셨어.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '오늘 하루 가장 아슬아슬했던 순간이 있었다면 어떤 때였나요?',
  },
  {
    verse_id:       'v_413',
    verse_short_ko: '내가 밤에 노래를 기억하며, 마음속으로 묵상하며 심령으로 간절히 구하기를.',
    verse_full_ko:  '내가 밤에 노래를 기억하며, 마음으로 묵상하며 심령으로 간절히 구하기를.',
    reference:      '시편 77:6',
    book:           '시편',
    chapter:        77,
    verse:          6,
    mode:           'wind_down',
    theme:          'reflection,stillness',
    mood:           'cozy',
    season:         'all',
    weather:        'any',
    interpretation: '아삽이 극도의 고통 속에서 밤새 잠 못 이루던 기도야.\n"노래를 기억하며"는 과거에 하나님이 어떠하셨는지를 고통 중에 소환하는 거야.\n이 밤, 기억 속 그분의 손길 하나를 꺼내봐.',
    application:    '잠들기 전, 하나님이 도우셨던 기억 하나를 조용히 꺼내봐. 그게 오늘 밤의 노래야.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '힘들었던 시간을 버티게 해준 기억이 있다면 무엇인가요?',
  },
  {
    verse_id:       'v_414',
    verse_short_ko: '우리의 잠시 받는 환난의 경한 것이 지극히 크고 영원한 영광의 중한 것을 우리에게 이루게 함이니.',
    verse_full_ko:  '우리의 잠시 받는 환난의 경한 것이 지극히 크고 영원한 영광의 중한 것을 우리에게 이루게 함이니,\n우리의 돌아보는 것은 보이는 것이 아니요, 보이지 않는 것이니.',
    reference:      '고린도후서 4:17',
    book:           '고린도후서',
    chapter:        4,
    verse:          17,
    mode:           'wind_down',
    theme:          'comfort,peace',
    mood:           'calm',
    season:         'all',
    weather:        'any',
    interpretation: '바울이 온갖 고난 속에서도 낙심하지 않는 이유를 설명하는 말씀이야.\n"잠시 받는 환난"은 시간의 관점에서 오늘의 무게를 다시 재는 거야.\n오늘이 무거워도, 이 밤이 지나면 뭔가 이루어지고 있는 거야.',
    application:    '오늘 하루 무거웠던 것, 잠깐이야. 그 무게가 빚어내고 있는 것이 있어. 오늘 밤은 내려놔.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '오늘 당신이 가장 무겁게 느낀 것은 무엇이었나요?',
  },

  // ─────────────────────────────────────────────────────────────────────────
  // golden_hour (v_415~v_419) — 저녁 6-9시, 요한복음17/빌레몬서/에베소서/아가서
  // 유저: 퇴근·귀가 후. 수고함+감사+때로는 아쉬움이나 허무
  // application 컨텍스트: 퇴근·귀가 중, 또는 저녁 식사를 마친 후
  // ─────────────────────────────────────────────────────────────────────────
  {
    verse_id:       'v_415',
    verse_short_ko: '아버지여, 아버지께서 내 안에, 내가 아버지 안에 있는 것같이 저희도 다 하나가 되어.',
    verse_full_ko:  '아버지여, 아버지께서 내 안에, 내가 아버지 안에 있는 것같이\n저희도 다 하나가 되어 우리 안에 있게 하사\n세상으로 아버지께서 나를 보내신 것을 믿게 하옵소서.',
    reference:      '요한복음 17:21',
    book:           '요한복음',
    chapter:        17,
    verse:          21,
    mode:           'golden_hour',
    theme:          'reflection,gratitude',
    mood:           'warm,serene',
    season:         'all',
    weather:        'any',
    interpretation: '예수님이 체포되시기 전날 밤, 제자들을 위해 드리신 대제사장적 기도의 핵심이야.\n"하나가 되어"는 관계의 회복을 소망하는 기도야. 오늘 하루 어긋난 관계가 있다면, 그것도 이 기도 안에 있어.',
    application:    '오늘 함께한 사람들을 떠올려봐. 그 관계 하나가 오늘 하루의 선물이었을 수 있어. 감사해봐.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '오늘 당신 곁에 있어줘서 감사한 사람이 있다면 누구인가요?',
  },
  {
    verse_id:       'v_416',
    verse_short_ko: '형제여, 나로 주 안에서 너를 인하여 기쁨을 얻게 하라.',
    verse_full_ko:  '형제여, 나로 주 안에서 너를 인하여 기쁨을 얻게 하고\n내 마음이 그리스도 안에서 평안하게 하라.',
    reference:      '빌레몬서 1:20',
    book:           '빌레몬서',
    chapter:        1,
    verse:          20,
    mode:           'golden_hour',
    theme:          'gratitude,comfort',
    mood:           'warm',
    season:         'all',
    weather:        'any',
    interpretation: '바울이 오네시모를 위해 빌레몬에게 쓴 짧지만 강한 편지야.\n"주 안에서 기쁨을 얻게 하라"는 관계 회복이 누군가에게 기쁨이 된다는 거야.\n오늘 내가 누군가에게 기쁨이 됐을 수도, 그리고 받았을 수도 있어.',
    application:    '오늘 나로 인해 기뻐한 사람이 있을지 생각해봐. 그 작은 기쁨이 오늘 하루의 열매야.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '오늘 누군가를 미소 짓게 한 순간이 있었다면 언제였나요?',
  },
  {
    verse_id:       'v_417',
    verse_short_ko: '범사에 우리 주 예수 그리스도의 이름으로 항상 아버지 하나님께 감사하며.',
    verse_full_ko:  '범사에 우리 주 예수 그리스도의 이름으로 항상 아버지 하나님께 감사하며.',
    reference:      '에베소서 5:20',
    book:           '에베소서',
    chapter:        5,
    verse:          20,
    mode:           'golden_hour',
    theme:          'gratitude,reflection',
    mood:           'warm',
    season:         'all',
    weather:        'any',
    interpretation: '에베소서 5장은 성령 충만한 삶의 열매로 감사를 말해.\n"범사에"는 좋은 일만이 아니야. 힘들었던 오늘도 포함해서야.\n오늘 하루의 수고와 실패까지 감사의 재료가 될 수 있어.',
    application:    '오늘 힘들었던 것 하나, 그래도 감사할 수 있는 이유 하나 찾아봐. 범사가 그거야.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   '범사에 항상 아버지 하나님께 감사하며.',
    question:       '오늘 하루 중 기대하지 않았는데 감사했던 순간이 있었나요?',
  },
  {
    verse_id:       'v_418',
    verse_short_ko: '내 사랑하는 자는 내 것이요, 나는 그의 것이로구나.',
    verse_full_ko:  '나의 사랑하는 자는 내 것이요, 나는 그의 것이로구나.\n그가 백합화 가운데서 양 떼를 먹이는구나.',
    reference:      '아가서 2:16',
    book:           '아가서',
    chapter:        2,
    verse:          16,
    mode:           'golden_hour',
    theme:          'reflection,peace',
    mood:           'warm,serene',
    season:         'all',
    weather:        'any',
    interpretation: '아가서는 사랑의 노래야. 신학자들은 이 책을 하나님과 인간의 사랑 관계의 상징으로 읽어왔어.\n"내 것이요, 나는 그의 것"은 상호적인 소속의 선언이야.\n오늘 하루가 끝나는 이 저녁, 나는 그분의 것이야.',
    application:    '오늘 하루 수고했어. 그 모든 수고가 그분의 것인 너의 하루야. 그게 오늘의 이유야.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '오늘 당신에게 가장 소중하게 느껴진 것은 무엇인가요?',
  },
  {
    verse_id:       'v_419',
    verse_short_ko: '영생은 곧 유일하신 참 하나님과 그의 보내신 자 예수 그리스도를 아는 것이니이다.',
    verse_full_ko:  '영생은 곧 유일하신 참 하나님과 그의 보내신 자 예수 그리스도를 아는 것이니이다.',
    reference:      '요한복음 17:3',
    book:           '요한복음',
    chapter:        17,
    verse:          3,
    mode:           'golden_hour',
    theme:          'reflection,gratitude',
    mood:           'warm',
    season:         'all',
    weather:        'any',
    interpretation: '예수님이 십자가 전날 밤 드리신 기도에서 영생을 정의하시는 말씀이야.\n영생은 먼 훗날의 것이 아니야. 지금 하나님을 알아가는 이 과정 자체가 영원한 생명이야.\n오늘 하루, 그분을 조금이라도 더 알아간 날이야.',
    application:    '오늘 하루 그분을 조금이라도 느낀 순간이 있었어? 그 순간이 영생의 하루야.',
    curated:        'TRUE',
    status:         'active',
    alarm_top_ko:   null,
    question:       '오늘 하루 중 하나님이 가장 가깝게 느껴진 순간이 있었다면 언제였나요?',
  },
];

// ── 메인 업로드 로직 ─────────────────────────────────────────────────────────
async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes:  ['https://www.googleapis.com/auth/spreadsheets'],
  });

  const sheets = google.sheets({ version: 'v4', auth });

  console.log(`=== add_v400_v419.js | 총 ${VERSES.length}개 구절 추가 ===\n`);

  // 헤더 확인 (첫 행 읽기)
  const headerRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SPREADSHEET_ID,
    range:         `${SHEET_NAME}!A1:AG1`,
  });
  console.log('헤더 확인:', headerRes.data.values?.[0]?.slice(0, 5));

  // 현재 마지막 행 확인
  const allData = await sheets.spreadsheets.values.get({
    spreadsheetId: SPREADSHEET_ID,
    range:         `${SHEET_NAME}!A:A`,
  });
  const lastRow = (allData.data.values || []).length;
  console.log(`현재 마지막 행: ${lastRow} (데이터: ${lastRow - 1}개)`);

  // 각 구절을 행 배열로 변환
  // 컬럼 순서: A~V + AA (question)
  // A: verse_id, B: verse_short_ko, C: verse_full_ko, D: reference, E: book,
  // F: chapter, G: verse, H: mode, I: theme, J: mood, K: season, L: weather,
  // M: interpretation, N: application, O: curated, P: status, Q: notes,
  // R: usage_count, S: cooldown_days, T: last_shown, U: show_count,
  // V: alarm_top_ko
  // W: contemplation_ko (수식 — 빈값으로 놔두면 수식으로 채워짐)
  // X: contemplation_reference (수식)
  // Y: contemplation_interpretation (수식)
  // Z: contemplation_appliance (수식)
  // AA: question
  // AB~AG: len_* (수식)

  const rows = VERSES.map(v => [
    v.verse_id,                          // A
    v.verse_short_ko,                    // B
    v.verse_full_ko,                     // C
    v.reference,                         // D
    v.book,                              // E
    v.chapter,                           // F
    v.verse,                             // G
    v.mode,                              // H
    v.theme,                             // I
    v.mood,                              // J
    v.season,                            // K
    v.weather,                           // L
    v.interpretation,                    // M
    v.application,                       // N
    v.curated,                           // O
    v.status,                            // P
    '',                                  // Q: notes
    0,                                   // R: usage_count
    7,                                   // S: cooldown_days
    '',                                  // T: last_shown
    0,                                   // U: show_count
    v.alarm_top_ko || '',                // V: alarm_top_ko
    '', '', '', '',                      // W, X, Y, Z: 수식 컬럼 (비워둠)
    v.question,                          // AA
  ]);

  // Append
  const appendRes = await sheets.spreadsheets.values.append({
    spreadsheetId:    SPREADSHEET_ID,
    range:            `${SHEET_NAME}!A:AA`,
    valueInputOption: 'USER_ENTERED',
    requestBody:      { values: rows },
  });

  const updatedRange = appendRes.data.updates?.updatedRange;
  const updatedRows  = appendRes.data.updates?.updatedRows;
  console.log(`\n추가 완료: ${updatedRows}행 / 범위: ${updatedRange}`);

  // 검증 출력
  console.log('\n─── 추가된 구절 목록 ───');
  VERSES.forEach((v, i) => {
    const shortLen   = v.verse_short_ko.length;
    const interpLen  = v.interpretation.length;
    const appLen     = v.application.length;
    const qLen       = v.question.length;
    const alarmLen   = v.alarm_top_ko ? v.alarm_top_ko.length : 0;

    let warns = [];
    if (shortLen < 10 || shortLen > 60) warns.push(`verse_short_ko ${shortLen}자`);
    if (interpLen < 80 || interpLen > 200) warns.push(`interpretation ${interpLen}자`);
    if (appLen < 30 || appLen > 100) warns.push(`application ${appLen}자`);
    if (qLen < 20 || qLen > 80) warns.push(`question ${qLen}자`);
    if (v.alarm_top_ko && (alarmLen < 10 || alarmLen > 50)) warns.push(`alarm_top_ko ${alarmLen}자`);

    const status = warns.length > 0 ? `[경고: ${warns.join(', ')}]` : '[OK]';
    console.log(`${v.verse_id} | ${v.reference} | ${v.mode} | short:${shortLen}자 interp:${interpLen}자 app:${appLen}자 q:${qLen}자 ${status}`);
  });

  console.log('\n다음 단계:');
  console.log('  node apply_formula_fields.js    # contemplation_* 수식 재적용');
  console.log('  node sync_sheets_to_firestore.js # Firestore 동기화');
}

main().catch(e => {
  console.error('오류:', e.message);
  process.exit(1);
});
