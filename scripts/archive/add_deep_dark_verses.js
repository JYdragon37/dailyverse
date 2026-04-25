/**
 * add_deep_dark_verses.js — deep_dark Zone 말씀 20개 Google Sheets 추가
 * v_260 ~ v_279
 * Zone: deep_dark (자정~새벽 3시, 잠 못 드는 새벽)
 *
 * 사용법:
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 node add_deep_dark_verses.js --dry-run   # 미리보기
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 node add_deep_dark_verses.js             # 실제 업로드
 */

require('dotenv').config();
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, './serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

const isDryRun = process.argv.includes('--dry-run');

// ── 20개 deep_dark Zone 말씀 데이터 (개역한글 기준) ───────────────────────
const DEEP_DARK_VERSES = [
  {
    verse_id: 'v_260',
    verse_short_ko: '내가 새벽 날개를 치며 바다 끝에 거할지라도 거기서도 주의 손이 나를 인도하리이다.',
    verse_full_ko: '내가 새벽 날개를 치며 바다 끝에 거할지라도,\n거기서도 주의 손이 나를 인도하시며,\n주의 오른손이 나를 붙드시리이다.',
    reference: '시편 139:9-10',
    book: '시편',
    chapter: 139,
    verse: 9,
    mode: 'deep_dark',
    theme: 'stillness,grace',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 어디로 도망가도 하나님을 피할 수 없다는 걸 고백한 시야.\n"새벽 날개"는 이 시간, 이 어두운 새벽을 말하는 거야. 바다 끝이라도 혼자가 아니야.\n지금 이 적막한 새벽에도 그 손이 너를 붙들고 있어.',
    application: '지금 뒤척이고 있다면, 손 한 번 펼쳐봐. 그 손을 잡고 있는 손이 있어.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '새벽 날개를 치며 바다 끝에 있어도 주의 손이 나를 붙드시리이다.',
    question: '이 새벽, 가장 혼자라고 느껴지는 순간이 언제인가요?',
  },
  {
    verse_id: 'v_261',
    verse_short_ko: '여호와는 나의 빛이요 나의 구원이시니 내가 누구를 두려워하리요.',
    verse_full_ko: '여호와는 나의 빛이요 나의 구원이시니, 내가 누구를 두려워하리요.\n여호와는 내 생명의 능력이시니, 내가 누구를 무서워하리요.',
    reference: '시편 27:1',
    book: '시편',
    chapter: 27,
    verse: 1,
    mode: 'deep_dark',
    theme: 'faith,stillness',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 원수들에게 둘러싸인 상황에서도 두려움 없음을 선언한 시야.\n"빛"은 이 어두운 새벽에 더 강렬하게 느껴지는 단어야. 어둠이 짙을수록 빛이 선명해.\n이 새벽의 두려움이 있어도, 그분이 먼저 빛이 되신다는 선포야.',
    application: '지금 무서운 생각이 찾아온다면, 이 한 마디 천천히 읽어봐. 여호와는 나의 빛이야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '여호와는 나의 빛이요 나의 구원이시니, 내가 누구를 두려워하리요.',
    question: '지금 이 새벽, 가장 두려운 것은 무엇인가요?',
  },
  {
    verse_id: 'v_262',
    verse_short_ko: '내가 잠자리에 들면서도 평안히 자고 깨리니 나를 안전히 살게 하심이니이다.',
    verse_full_ko: '내가 평안히 눕고 자기도 하리니,\n나를 안전히 거하게 하시는 이는 오직 여호와이시니이다.',
    reference: '시편 4:8',
    book: '시편',
    chapter: 4,
    verse: 8,
    mode: 'deep_dark',
    theme: 'rest,stillness',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 많은 원수들과 불안한 밤에도 평안히 누웠다고 고백한 시야.\n안전함의 이유가 상황이 아닌 그분이라는 게 핵심이야. 조건이 없어.\n이 밤에 잠 못 드는 너에게, 누워도 괜찮다고 말해주는 구절이야.',
    application: '지금 누워서 눈 감아봐. 이 어둠 속에서 나를 안전하게 하시는 분이 여기 계셔.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '나를 안전히 거하게 하시는 이는 오직 여호와이시니이다.',
    question: '요즘 마음 편히 잠들기 어렵게 만드는 것이 있나요?',
  },
  {
    verse_id: 'v_263',
    verse_short_ko: '두려워하지 말라, 내가 너와 함께 함이니라.',
    verse_full_ko: '두려워하지 말라, 내가 너와 함께 함이니라.\n놀라지 말라, 나는 네 하나님이 됨이니라.\n내가 너를 굳세게 하리라, 참으로 너를 도와주리라.',
    reference: '이사야 41:10',
    book: '이사야',
    chapter: 41,
    verse: 10,
    mode: 'deep_dark',
    theme: 'faith,grace',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '바벨론 포로가 된 이스라엘에게 하나님이 직접 하신 말씀이야.\n"함께 함이니라"는 상황이 바뀌기 전에 먼저 임재가 선언되는 거야. 조건이 없어.\n이 새벽의 두려움이 아무리 커도, 그분이 네 옆에 먼저 와 계신 거야.',
    application: '지금 가슴이 두근거린다면 숨 한 번 천천히 내쉬어봐. 내가 너와 함께 있어, 라는 말 들어봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '두려워하지 말라, 내가 너와 함께 함이니라.',
    question: '이 새벽, 혼자라는 느낌이 가장 강하게 드는 때가 언제인가요?',
  },
  {
    verse_id: 'v_264',
    verse_short_ko: '하나님이 우리 편이시면 누가 우리를 대적하리요.',
    verse_full_ko: '그런즉 이 일에 대하여 우리가 무슨 말 하리요.\n만일 하나님이 우리를 위하시면, 누가 우리를 대적하리요.',
    reference: '로마서 8:31',
    book: '로마서',
    chapter: 8,
    verse: 31,
    mode: 'deep_dark',
    theme: 'faith,surrender',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '바울이 온갖 고난을 나열한 뒤에 한 선포야. 환경이 아닌 편에 서신 분에 대한 확신이야.\n"대적"은 두려움의 대상이야. 그 대상들이 아무리 많아도 편이 되신 그분이 더 크다는 거야.\n이 새벽에 머릿속에서 나를 공격하는 생각들에게 이 질문을 던져봐.',
    application: '지금 나를 압박하는 걱정이 있다면, 그것보다 큰 편이 이미 있다는 걸 떠올려봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '하나님이 우리를 위하시면 누가 우리를 대적하리요.',
    question: '요즘 가장 많이 나를 공격하는 생각은 어떤 것인가요?',
  },
  {
    verse_id: 'v_265',
    verse_short_ko: '내가 사망의 음침한 골짜기로 다닐지라도 해를 두려워하지 않음은 주께서 나와 함께 하심이라.',
    verse_full_ko: '내가 사망의 음침한 골짜기로 다닐지라도 해를 두려워하지 않을 것은,\n주께서 나와 함께 하심이라.\n주의 지팡이와 막대기가 나를 안위하시나이다.',
    reference: '시편 23:4',
    book: '시편',
    chapter: 23,
    verse: 4,
    mode: 'deep_dark',
    theme: 'stillness,grace',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 목자의 언어로 그분의 동반을 고백한 시야. 골짜기를 피하는 게 아니야.\n"함께 하심이라"가 두려움이 없는 이유야. 안전한 환경이 아닌 임재가 답이야.\n이 어두운 새벽 골짜기 같은 시간에도 그 지팡이가 네 곁에 있어.',
    application: '지금 이 어두운 시간을 혼자 걷는 것 같다면, 네 곁을 걷는 발걸음 소리에 귀 기울여봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '사망의 음침한 골짜기를 다닐지라도 해를 두려워하지 않음은 주께서 함께하심이라.',
    question: '지금 걷고 있는 가장 어두운 골짜기는 어디인가요?',
  },
  {
    verse_id: 'v_266',
    verse_short_ko: '여호와여, 나의 부르짖음이 주의 귀에 들리게 하옵소서.',
    verse_full_ko: '여호와여, 내가 깊은 곳에서 주께 부르짖었나이다.\n주여, 내 소리를 들으시며,\n나의 간구하는 소리에 귀를 기울이소서.',
    reference: '시편 130:1-2',
    book: '시편',
    chapter: 130,
    verse: 1,
    mode: 'deep_dark',
    theme: 'surrender,grace',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '성전에 올라가는 순례 시편이야. "깊은 곳"은 절망의 바닥을 말해.\n이 시편의 힘은 그 바닥에서도 주를 향해 소리 지른다는 거야. 포기가 아니야.\n이 새벽 바닥 같은 느낌에서, 소리 내지 않아도 부르짖어도 들리신다는 거야.',
    application: '지금 말로 표현하기 힘든 것이 있어도 괜찮아. 그냥 마음속으로 깊은 곳에서 불러봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '깊은 곳에서 주께 부르짖었나이다, 나의 소리를 들으소서.',
    question: '지금 가장 꺼내기 힘든 말이 있다면 무엇인가요?',
  },
  {
    verse_id: 'v_267',
    verse_short_ko: '주의 말씀은 내 발에 등이요 내 길에 빛이니이다.',
    verse_full_ko: '주의 말씀은 내 발에 등이요, 내 길에 빛이니이다.',
    reference: '시편 119:105',
    book: '시편',
    chapter: 119,
    verse: 105,
    mode: 'deep_dark',
    theme: 'faith,stillness',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '긴 시편 119편에서 말씀의 가치를 고백한 구절이야. 밤길의 등불이야.\n"발에 등"은 멀리 다 비추는 게 아니라 딱 한 발자국 앞을 비추는 빛이야.\n이 새벽에 다 보이지 않아도 괜찮아. 지금 한 발자국만 비춰줘도 충분해.',
    application: '이 새벽에 앞이 안 보이는 것 같아도 괜찮아. 지금 이 말씀 한 줄이 한 발자국 앞을 비추고 있어.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '지금 가장 앞이 안 보이는 것은 어떤 부분인가요?',
  },
  {
    verse_id: 'v_268',
    verse_short_ko: '그가 이르시되 내 임재가 친히 가리라, 내가 너를 쉬게 하리라.',
    verse_full_ko: '여호와께서 가라사대, 내가 친히 가리라.\n내가 너를 쉬게 하리라.',
    reference: '출애굽기 33:14',
    book: '출애굽기',
    chapter: 33,
    verse: 14,
    mode: 'deep_dark',
    theme: 'grace,rest',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '모세가 이스라엘을 이끌며 지쳐있을 때 하나님이 직접 하신 약속이야.\n"친히 가리라"는 대리인이 아닌 그분이 직접 동행하신다는 뜻이야. 임재 자체야.\n이 새벽에 지쳐 잠 못 드는 너에게, 친히 함께 가신다는 말씀이야.',
    application: '지금 너무 지쳐 있다면, 혼자 해결하려 하지 않아도 돼. 친히 가시는 분이 이미 여기 계셔.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '내가 친히 가리라, 내가 너를 쉬게 하리라.',
    question: '지금 가장 지쳐있는 부분이 어디인가요?',
  },
  {
    verse_id: 'v_269',
    verse_short_ko: '하나님이여, 내 마음이 정함이여, 내 마음이 정하였나이다.',
    verse_full_ko: '하나님이여, 내 마음이 정함이여, 내 마음이 정하였나이다.\n내가 노래하고 찬송하리이다.',
    reference: '시편 108:1',
    book: '시편',
    chapter: 108,
    verse: 1,
    mode: 'deep_dark',
    theme: 'faith,surrender',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 새벽을 깨우는 다짐으로 시작하는 시야. 감정이 아닌 의지의 고백이야.\n"마음이 정함이여"는 기분이 좋아서가 아니야. 상황과 무관하게 그분을 향하는 결단이야.\n이 새벽 흔들리는 마음에도 작은 정함 하나를 품어도 돼.',
    application: '지금 마음이 어지럽더라도 괜찮아. 이 밤이 지나도 그분을 향한다, 하나만 정해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '지금 이 순간 하나만 결심한다면 무엇이 되었으면 하나요?',
  },
  {
    verse_id: 'v_270',
    verse_short_ko: '너희 마음에 근심하지 말라, 하나님을 믿으니 또 나를 믿으라.',
    verse_full_ko: '너희는 마음에 근심하지 말라.\n하나님을 믿으니 또 나를 믿으라.',
    reference: '요한복음 14:1',
    book: '요한복음',
    chapter: 14,
    verse: 1,
    mode: 'deep_dark',
    theme: 'faith,stillness',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '예수님이 십자가를 앞두고 두려워하는 제자들에게 하신 말씀이야.\n근심을 없애라는 명령이 아니야. 그 근심 속에서 신뢰를 붙들라는 초대야.\n이 새벽 근심이 가득할 때, 그 자리에서 믿음을 선택해도 돼.',
    application: '지금 걱정이 꼬리를 물고 있다면, 잠깐 멈추고 그냥 이 말씀 한 줄만 읽어봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '너희는 마음에 근심하지 말라, 하나님을 믿으니 또 나를 믿으라.',
    question: '요즘 가장 근심이 되는 것은 무엇인가요?',
  },
  {
    verse_id: 'v_271',
    verse_short_ko: '나의 영혼아, 잠잠히 하나님만 바라라, 나의 소망이 그로부터 나오는도다.',
    verse_full_ko: '나의 영혼아, 잠잠히 하나님만 바라라.\n무릇 나의 소망이 그로부터 나오는도다.\n그는 나의 반석이시요 나의 구원이시요 나의 산성이시니 내가 흔들리지 아니하리로다.',
    reference: '시편 62:5-6',
    book: '시편',
    chapter: 62,
    verse: 5,
    mode: 'deep_dark',
    theme: 'stillness,surrender',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 모든 것이 무너지는 상황에서 자기 영혼에게 직접 말 건네는 시야.\n"잠잠히 바라라"는 소음을 끄고 오직 그분께 시선을 고정하는 태도야.\n이 새벽 머릿속이 시끄러울 때, 영혼을 잠잠하게 내려놓는 것도 깊은 신뢰야.',
    application: '지금 머릿속이 너무 시끄럽다면, 눈 감고 천천히 숨 쉬며 이 말씀 한 번만 되뇌어봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '이 새벽 마음이 가장 시끄럽게 느껴지는 것은 무엇인가요?',
  },
  {
    verse_id: 'v_272',
    verse_short_ko: '보라, 이스라엘을 지키시는 자는 졸지도 아니하시고 주무시지도 아니하시리로다.',
    verse_full_ko: '보라, 이스라엘을 지키시는 이는 졸지도 아니하시고 주무시지도 아니하시리로다.',
    reference: '시편 121:4',
    book: '시편',
    chapter: 121,
    verse: 4,
    mode: 'deep_dark',
    theme: 'faith,grace',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '순례자들이 예루살렘 길에서 부른 시야. 밤길을 걷는 위험 속에서 지켜주심을 고백했어.\n"졸지도 아니하시고"가 핵심이야. 네가 잠 못 드는 이 새벽에도 그분은 깨어 계셔.\n지키는 분이 이 새벽에 깨어 있으니, 네가 조금은 쉬어도 돼.',
    application: '지금 온 세상이 자는 것 같은 이 새벽에도, 너를 지키시는 분이 깨어 계셔. 조금 놓아봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '이스라엘을 지키시는 이는 졸지도 아니하시고 주무시지도 아니하시리로다.',
    question: '이 밤 누가 나를 지켜보고 있다는 느낌이 든다면 어떤 기분일까요?',
  },
  {
    verse_id: 'v_273',
    verse_short_ko: '내가 너를 버리지 아니하고 너를 떠나지 아니하리라.',
    verse_full_ko: '내가 너를 버리지 아니하고 너를 떠나지 아니하리라.',
    reference: '여호수아 1:5',
    book: '여호수아',
    chapter: 1,
    verse: 5,
    mode: 'deep_dark',
    theme: 'grace,faith',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '모세가 죽고 여호수아가 두려움 속에서 큰 임무를 앞두었을 때 하나님이 하신 말씀이야.\n"버리지 아니하리라"는 이중 부정이야. 절대로 떠나지 않겠다는 강한 확언이야.\n이 새벽에 버려진 것 같은 느낌이 들어도, 그건 실제가 아니야.',
    application: '지금 혼자라는 생각이 든다면 이 말씀을 한 번만 천천히 읽어봐. 버리지 아니하리라.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '내가 너를 버리지 아니하고 너를 떠나지 아니하리라.',
    question: '버려진 것처럼 느껴졌던 경험이 있나요?',
  },
  {
    verse_id: 'v_274',
    verse_short_ko: '나의 힘이 되신 여호와여, 내가 주를 사랑하나이다.',
    verse_full_ko: '나의 힘이 되신 여호와여, 내가 주를 사랑하나이다.\n여호와는 나의 반석이시요 나의 요새시요 나를 건지시는 이시요.',
    reference: '시편 18:1-2',
    book: '시편',
    chapter: 18,
    verse: 1,
    mode: 'deep_dark',
    theme: 'faith,stillness',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 사울에게 쫓기다 구원받은 뒤 감사로 드린 긴 시의 시작이야.\n"반석, 요새, 건지시는 이"는 모두 내가 피할 수 있는 안전한 곳이야. 하나님이 그 자체야.\n이 새벽에 아무 데도 피할 곳이 없는 것 같을 때, 피할 곳이 사람이 아닌 그분이야.',
    application: '지금 아무도 없는 것 같은 이 새벽에, 나의 반석이 되신 그분께 마음을 기대봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '힘든 순간 마음을 기댈 수 있는 곳이 있나요?',
  },
  {
    verse_id: 'v_275',
    verse_short_ko: '주께서 나를 살펴보사 아셨나이다. 내가 앉고 일어섬을 아시며 나의 모든 길을 아시나이다.',
    verse_full_ko: '여호와여, 주께서 나를 감찰하시고 아셨나이다.\n나의 앉고 일어섬을 아시고, 멀리서도 나의 생각을 통촉하시며,\n나의 모든 길과 눕는 것을 살펴보셨으므로 나의 모든 행위를 익히 아시나이다.',
    reference: '시편 139:1-3',
    book: '시편',
    chapter: 139,
    verse: 1,
    mode: 'deep_dark',
    theme: 'stillness,grace',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 하나님의 전지함을 묵상한 시야. 아무리 숨어도 알고 계신다는 고백이야.\n"살펴보사 아셨나이다"는 나쁜 걸 들켰다는 게 아니야. 내가 완전히 알려진 존재라는 뜻이야.\n이 새벽 지금의 상태 그대로, 완전히 알고 계신다는 것이 위로가 될 수 있어.',
    application: '지금 이 새벽의 너의 상태를 완전히 알고 계신 분이 계셔. 숨기지 않아도 돼.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '주께서 나를 살펴보사 아셨나이다, 나의 모든 것을 아시나이다.',
    question: '가장 알려지고 싶지 않은 모습이 있나요?',
  },
  {
    verse_id: 'v_276',
    verse_short_ko: '내가 환난 날에 주께 부르짖으리니 주께서 내게 응답하시리이다.',
    verse_full_ko: '내가 환난 날에 주께 부르짖으리니,\n주께서 내게 응답하시리이다.',
    reference: '시편 86:7',
    book: '시편',
    chapter: 86,
    verse: 7,
    mode: 'deep_dark',
    theme: 'faith,surrender',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 어려운 처지에서 하나님께 직접 드린 기도야. 이미 응답을 선포하고 있어.\n부르짖음 자체가 믿음의 행동이야. 들으신다는 확신이 있어야 부를 수 있어.\n이 새벽에 소리 내지 않아도 괜찮아. 마음속 부르짖음도 들리신다는 거야.',
    application: '지금 말로 표현하기 어려운 마음이 있다면, 그냥 그 상태 그대로 그분께 꺼내봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '환난 날에 주께 부르짖으리니, 주께서 내게 응답하시리이다.',
    question: '지금 가장 응답받고 싶은 기도가 있다면 무엇인가요?',
  },
  {
    verse_id: 'v_277',
    verse_short_ko: '너희가 나를 찾으리라. 네 마음을 다하여 나를 찾으면 나를 만나리라.',
    verse_full_ko: '너희가 온 마음으로 나를 찾으면 나를 찾겠고 나를 만나리라.',
    reference: '예레미야 29:13',
    book: '예레미야',
    chapter: 29,
    verse: 13,
    mode: 'deep_dark',
    theme: 'faith,surrender',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '예레미야가 바벨론에 포로로 끌려간 사람들에게 전한 편지에 담긴 말씀이야.\n가장 멀리 있을 때, 온 마음으로 찾으면 만난다는 약속이야. 거리가 문제가 아니야.\n이 새벽 하나님과 멀어진 것 같은 느낌이 있어도, 찾는 행위가 이미 만남의 시작이야.',
    application: '지금 하나님과 멀어진 것 같다면 억지로 가까워지려 할 필요 없어. 그냥 찾아봐, 이 자리에서.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '온 마음으로 나를 찾으면 나를 만나리라.',
    question: '하나님과 가장 가깝게 느껴졌던 순간이 언제였나요?',
  },
  {
    verse_id: 'v_278',
    verse_short_ko: '내가 여기 있나니 내게 오라.',
    verse_full_ko: '수고하고 무거운 짐 진 자들아, 다 내게로 오라.\n내가 너희를 쉬게 하리라.\n나는 마음이 온유하고 겸손하니 나의 멍에를 메고 내게 배우라.',
    reference: '마태복음 11:28-29',
    book: '마태복음',
    chapter: 11,
    verse: 28,
    mode: 'deep_dark',
    theme: 'rest,grace',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '예수님이 율법의 무거움에 지친 사람들을 부르신 말씀이야.\n"다 내게로 오라"는 준비되면 오라는 게 아니야. 지금 이 상태 그대로 오라는 거야.\n이 새벽에 지쳐서 아무것도 할 수 없는 그 상태가 바로 갈 수 있는 자격이야.',
    application: '지금 너무 지쳐서 아무것도 못 하겠다면, 그 상태 그대로 그냥 와도 된다는 말이야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '수고하고 무거운 짐 진 자들아, 다 내게로 오라.',
    question: '지금 가장 내려놓고 싶은 짐은 무엇인가요?',
  },
  {
    verse_id: 'v_279',
    verse_short_ko: '내 백성이 평안한 집과 안전한 거처와 조용한 쉴 곳에 있으리라.',
    verse_full_ko: '내 백성이 평안한 집에 있으며, 안전한 거처와 조용한 쉴 곳에 있으리라.',
    reference: '이사야 32:18',
    book: '이사야',
    chapter: 32,
    verse: 18,
    mode: 'deep_dark',
    theme: 'rest,stillness',
    mood: 'serene,calm',
    season: 'all',
    weather: 'any',
    interpretation: '이사야가 하나님의 통치가 이루어질 때의 평화를 예언한 구절이야.\n"평안한 집, 안전한 거처, 조용한 쉴 곳"은 밤에 두려움 없이 쉬는 상태야.\n이 새벽 뒤척이는 너에게, 그 고요한 쉼이 이미 약속되어 있다는 거야.',
    application: '지금 이 새벽, 몸을 최대한 편하게 눕혀봐. 평안한 집, 안전한 거처가 여기야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '마음이 가장 평안하고 안전하다고 느껴지는 공간은 어디인가요?',
  },
];

// ── Sheets 헤더 순서에 맞게 행 변환 ────────────────────────────────────────
function toRow(v) {
  return [
    v.verse_id,           // A: verse_id
    v.verse_short_ko,     // B: verse_short_ko
    v.verse_full_ko,      // C: verse_full_ko
    v.reference,          // D: reference
    v.book,               // E: book
    v.chapter,            // F: chapter
    v.verse,              // G: verse
    v.mode,               // H: mode
    v.theme,              // I: theme
    v.mood,               // J: mood
    v.season,             // K: season
    v.weather,            // L: weather
    v.interpretation,     // M: interpretation
    v.application,        // N: application
    v.curated,            // O: curated
    v.status,             // P: status
    '',                   // Q: notes
    0,                    // R: usage_count
    7,                    // S: cooldown_days
    '',                   // T: last_shown
    0,                    // U: show_count
    v.alarm_top_ko || '', // V: alarm_top_ko
    '',                   // W: contemplation_ko (수식으로 자동)
    '',                   // X: contemplation_reference (수식으로 자동)
    '',                   // Y: contemplation_interpretation (수식으로 자동)
    '',                   // Z: contemplation_appliance (수식으로 자동)
    v.question,           // AA: question
  ];
}

async function main() {
  console.log(`=== add_deep_dark_verses.js | dry-run: ${isDryRun} | 대상: ${DEEP_DARK_VERSES.length}개 ===\n`);

  // 자체 검증
  let hasError = false;
  for (const v of DEEP_DARK_VERSES) {
    const issues = [];
    const shortLen = v.verse_short_ko.length;
    const fullLen = v.verse_full_ko.length;
    const interpLen = v.interpretation.length;
    const appLen = v.application.length;

    if (shortLen > 60) issues.push(`verse_short_ko 초과: ${shortLen}자`);
    if (shortLen < 10) issues.push(`verse_short_ko 부족: ${shortLen}자`);
    if (fullLen > 200) issues.push(`verse_full_ko 초과: ${fullLen}자`);
    if (fullLen < 20) issues.push(`verse_full_ko 부족: ${fullLen}자`);
    if (interpLen > 200) issues.push(`interpretation 초과: ${interpLen}자`);
    if (interpLen < 80) issues.push(`interpretation 부족: ${interpLen}자`);
    if (appLen > 100) issues.push(`application 초과: ${appLen}자`);
    if (appLen < 30) issues.push(`application 부족: ${appLen}자`);

    // 원어 표기 감지
    const forbiddenWords = ['히브리어', '헬라어', '그리스어', '헤세드', '샬롬', '야웨'];
    for (const w of forbiddenWords) {
      if (v.interpretation.includes(w)) issues.push(`원어 표기 의심: "${w}" in interpretation`);
    }

    if (issues.length > 0) {
      console.error(`[오류] ${v.verse_id} (${v.reference}):`);
      issues.forEach(i => console.error(`  - ${i}`));
      hasError = true;
    } else {
      console.log(`[OK] ${v.verse_id} | ${v.reference} | short:${shortLen}자 full:${fullLen}자 interp:${interpLen}자 app:${appLen}자`);
    }
  }

  if (hasError) {
    console.error('\n검증 실패 — 업로드 중단');
    process.exit(1);
  }

  console.log('\n자체 검증 통과\n');

  if (isDryRun) {
    DEEP_DARK_VERSES.forEach(v => {
      console.log(`[${v.verse_id}] ${v.reference}`);
      console.log(`  short(${v.verse_short_ko.length}자): ${v.verse_short_ko}`);
      console.log(`  full(${v.verse_full_ko.length}자): ${v.verse_full_ko.replace(/\n/g, ' / ')}`);
      console.log(`  interp(${v.interpretation.length}자): ${v.interpretation.replace(/\n/g, ' / ').slice(0, 60)}...`);
      console.log(`  app(${v.application.length}자): ${v.application}`);
      console.log(`  alarm_top_ko: ${v.alarm_top_ko || '(생략)'}`);
      console.log();
    });
    console.log('dry-run 완료 — 실제 업로드하려면 --dry-run 없이 실행하세요.');
    return;
  }

  // 실제 Sheets 업로드
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const rows = DEEP_DARK_VERSES.map(toRow);

  try {
    const res = await sheets.spreadsheets.values.append({
      spreadsheetId: SHEET_ID,
      range: `${SHEET_NAME}!A:AA`,
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
      requestBody: { values: rows },
    });

    console.log(`업로드 완료: ${res.data.updates.updatedRows}행 추가됨`);
    console.log(`범위: ${res.data.updates.updatedRange}`);
    console.log('\n다음 단계:');
    console.log('  NODE_TLS_REJECT_UNAUTHORIZED=0 node apply_formula_fields.js');
    console.log('  node sync_sheets_to_firestore.js');
  } catch (e) {
    console.error('업로드 실패:', e.message);
    process.exit(1);
  }
}

main().catch(console.error);
