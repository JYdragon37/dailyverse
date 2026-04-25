/**
 * add_recharge_verses.js — recharge Zone 말씀 20개 Google Sheets 추가
 * v_220 ~ v_239
 * Zone: recharge (오후 12-15시)
 *
 * 사용법:
 *   node add_recharge_verses.js --dry-run   # 미리보기
 *   node add_recharge_verses.js             # 실제 업로드
 */

require('dotenv').config();
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, './serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

const isDryRun = process.argv.includes('--dry-run');

// ── Sheets 헤더 순서 (조회된 실제 헤더 기준) ───────────────────────────────
// ["verse_id","verse_short_ko","verse_full_ko","reference","book","chapter","verse",
//  "mode","theme","mood","season","weather","interpretation","application","curated",
//  "status","notes","usage_count","cooldown_days","last_shown","show_count",
//  "alarm_top_ko","contemplation_ko","contemplation_reference",
//  "contemplation_interpretation","contemplation_appliance","question",
//  "len_verse_full_ko","len_verse_short_ko","len_interpretation","len_application",
//  "len_alarm_top_ko","len_question"]

// ── 20개 recharge Zone 말씀 데이터 ────────────────────────────────────────
const RECHARGE_VERSES = [
  {
    verse_id: 'v_220',
    verse_short_ko: '수고하고 무거운 짐 진 자들아, 다 내게로 오라.',
    verse_full_ko: '수고하고 무거운 짐 진 자들아, 다 내게로 오라.\n내가 너희를 쉬게 하리라.',
    reference: '마태복음 11:28',
    book: '마태복음',
    chapter: 11,
    verse: 28,
    mode: 'recharge',
    theme: 'rest,comfort',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '예수님이 율법의 무게에 짓눌린 사람들에게 직접 하신 말씀이야.\n"쉬게 하리라"는 일시적 휴식이 아니라 영혼이 숨 쉬는 진짜 안식이야.\n오후의 무거움 속에서 지금 네가 다 하지 않아도 된다는 허락이야.',
    application: '지금 점심 자리에서 잠깐 폰 내려놓고 눈 감아봐. 내가 쉬게 해줄게, 라는 말 하나 떠올리며.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '수고하고 무거운 짐 진 자들아, 내게 오라.',
    question: '요즘 가장 무겁게 느껴지는 짐은 무엇인가요?',
  },
  {
    verse_id: 'v_221',
    verse_short_ko: '여호와는 나의 목자시니 내게 부족함이 없으리로다.',
    verse_full_ko: '여호와는 나의 목자시니 내게 부족함이 없으리로다.\n그가 나를 푸른 초장에 누이시며 쉴만한 물가로 인도하시는도다.',
    reference: '시편 23:1-2',
    book: '시편',
    chapter: 23,
    verse: 1,
    mode: 'recharge',
    theme: 'rest,peace',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 목자 생활을 하며 체험한 하나님의 돌봄을 시로 담았어.\n"쉴만한 물가"는 양이 지쳐 쓰러지기 전에 먼저 이끄는 목자의 세심함이야.\n오후의 나른함 속에서 그분이 먼저 쉬어가게 하신다는 걸 기억해.',
    application: '잠깐 자리에서 일어나 창밖 한 번 바라봐. 양을 먼저 쉬게 이끄신 그분이 오늘도 네 목자야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '여호와는 나의 목자시니 내게 부족함이 없으리로다.',
    question: '오늘 하루 중 진짜 숨 고를 수 있었던 순간이 있었나요?',
  },
  {
    verse_id: 'v_222',
    verse_short_ko: '오직 여호와를 앙망하는 자는 새 힘을 얻으리니.',
    verse_full_ko: '오직 여호와를 앙망하는 자는 새 힘을 얻으리니,\n독수리가 날개치며 올라감 같을 것이요,\n달음박질하여도 곤비하지 아니하겠고 걸어가도 피곤하지 아니하리로다.',
    reference: '이사야 40:31',
    book: '이사야',
    chapter: 40,
    verse: 31,
    mode: 'recharge',
    theme: 'strength,patience',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '바벨론 포로로 지쳐버린 이스라엘에게 선지자 이사야가 전한 말씀이야.\n"앙망하다"는 기다리면서 시선을 고정한다는 뜻이야. 억지로 버티는 게 아니야.\n오후의 피로 속에서 잠깐 시선을 올려보면 다시 힘이 채워지는 거야.',
    application: '오후에 지친다면 억지로 힘내려 하지 말고, 잠깐 숨 고르며 눈 들어 그분을 바라봐. 힘은 거기서 와.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '여호와를 앙망하는 자는 새 힘을 얻으리니.',
    question: '지쳐 있을 때 당신의 시선은 어디를 향하나요?',
  },
  {
    verse_id: 'v_223',
    verse_short_ko: '내 영혼아, 잠잠히 하나님만 바라라.',
    verse_full_ko: '내 영혼아, 잠잠히 하나님만 바라라.\n무릇 나의 소망이 그로부터 나오는도다.',
    reference: '시편 62:5',
    book: '시편',
    chapter: 62,
    verse: 5,
    mode: 'recharge',
    theme: 'peace,rest',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 원수들의 공격 속에서 흔들리는 자기 영혼에게 직접 말 건네는 시야.\n"잠잠히 바라라"는 억지로 평안한 척이 아니라 소음을 멈추고 고정하는 태도야.\n오후의 분주함 속에서 영혼을 잠깐 잠잠하게 내려놓는 것도 힘이 될 수 있어.',
    application: '지금 하던 일 잠깐 멈추고 눈 감아봐. 내 영혼아, 잠잠히, 라는 말 한 번만 되뇌어봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '내 영혼아, 잠잠히 하나님만 바라라.',
    question: '요즘 마음이 가장 시끄러운 순간은 언제인가요?',
  },
  {
    verse_id: 'v_224',
    verse_short_ko: '아무것도 염려하지 말고 오직 기도와 간구로 구하라.',
    verse_full_ko: '아무것도 염려하지 말고, 오직 기도와 간구로,\n너희 구할 것을 감사함으로 하나님께 아뢰라.\n그리하면 모든 지각에 뛰어난 하나님의 평강이 너희 마음과 생각을 지키시리라.',
    reference: '빌립보서 4:6-7',
    book: '빌립보서',
    chapter: 4,
    verse: 6,
    mode: 'recharge',
    theme: 'peace,comfort',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '바울이 감옥에 갇혀 있으면서 빌립보 교회에 쓴 편지야. 그 상황에서 나온 말이야.\n"아무것도 염려하지 말고"는 감정을 억누르라는 게 아니라 걱정의 자리에 기도를 놓으라는 거야.\n오후에 쌓인 염려들, 억지로 해결하려 하지 말고 그냥 내려놓아도 돼.',
    application: '지금 마음에 걸리는 걱정 하나 떠올려봐. 그걸 억지로 해결하려 하지 말고, 잠깐 내려놔봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '아무것도 염려하지 말고 감사함으로 아뢰라.',
    question: '지금 가장 내려놓고 싶은 걱정은 무엇인가요?',
  },
  {
    verse_id: 'v_225',
    verse_short_ko: '나의 영혼아, 잠잠히 하나님만 바라라. 나의 구원이 그에게서 나는도다.',
    verse_full_ko: '나의 영혼아, 잠잠히 하나님만 바라라. 나의 구원이 그에게서 나는도다.\n오직 그만이 나의 반석이시요 나의 구원이시요 나의 산성이시니, 내가 크게 요동하지 아니하리로다.',
    reference: '시편 62:1-2',
    book: '시편',
    chapter: 62,
    verse: 1,
    mode: 'recharge',
    theme: 'rest,peace',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 모든 것이 흔들리는 상황에서도 흔들리지 않는 중심을 고백한 시야.\n"반석과 산성"은 피난처이자 움직이지 않는 기반을 뜻해. 상황이 아닌 그분이 내 기준이야.\n오후에 마음이 흔들릴 때, 내가 크게 요동치 않을 수 있는 이유가 있다는 거야.',
    application: '지금 흔들리는 느낌이 든다면, 잠깐 눈 감아봐. 내가 서 있는 반석이 흔들리지 않는다는 걸 기억해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '흔들리는 상황에서 당신을 붙잡아준 것은 무엇인가요?',
  },
  {
    verse_id: 'v_226',
    verse_short_ko: '내가 너에게 평강을 주노라, 세상이 주는 것과 같지 아니하니라.',
    verse_full_ko: '평안을 너희에게 끼치노니 곧 나의 평안을 너희에게 주노라.\n내가 너희에게 주는 것은 세상이 주는 것과 같지 아니하니라.\n너희는 마음에 근심하지도 말고 두려워하지도 말라.',
    reference: '요한복음 14:27',
    book: '요한복음',
    chapter: 14,
    verse: 27,
    mode: 'recharge',
    theme: 'peace,comfort',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '예수님이 제자들과 마지막 식사를 마치고 이별을 앞두고 하신 말씀이야.\n세상의 평안은 조건이 갖춰져야 오지만, 그분의 평안은 상황과 무관하게 주어져.\n오후의 불안함이나 근심이 있어도, 그 평안은 이미 네 것으로 주어졌어.',
    application: '오후에 근심이 생겼다면 잠깐 멈춰봐. 세상이 줄 수 없는 평안이 이미 네 것으로 주어졌어.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '세상이 주는 것과 같지 아니한 평안을 너에게 주노라.',
    question: '진짜 평안함을 느꼈던 순간이 언제였나요?',
  },
  {
    verse_id: 'v_227',
    verse_short_ko: '여호와여, 나를 인도하사 평탄한 길로 가게 하소서.',
    verse_full_ko: '여호와여, 주의 의로 나를 인도하시고,\n나의 원수들로 말미암아 주의 길을 내 목전에 곧게 하소서.',
    reference: '시편 5:8',
    book: '시편',
    chapter: 5,
    verse: 8,
    mode: 'recharge',
    theme: 'patience,peace',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 아침 기도에서 하루를 의탁하며 드린 간구야.\n"길을 곧게 하소서"는 내가 앞을 볼 수 없을 때 그분이 방향을 잡아달라는 고백이야.\n오후에 방향을 잃은 것 같을 때, 내가 아닌 그분께 인도를 맡겨도 돼.',
    application: '지금 어느 방향으로 가야 할지 막막하다면, 잠깐 멈추고 내 걸음을 인도해달라 부탁해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '요즘 어떤 방향으로 가야 할지 가장 막막한 부분이 있나요?',
  },
  {
    verse_id: 'v_228',
    verse_short_ko: '하나님이 우리의 피난처시요 힘이시니, 환난 중에 만날 큰 도움이시라.',
    verse_full_ko: '하나님은 우리의 피난처시요 힘이시니,\n환난 중에 만날 큰 도움이시라.',
    reference: '시편 46:1',
    book: '시편',
    chapter: 46,
    verse: 1,
    mode: 'recharge',
    theme: 'comfort,strength',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '고라 자손이 전쟁과 혼란의 시대에 하나님의 임재를 선포한 시야.\n"피난처"는 도망가는 곳이 아니라 거기 있으면 안전한 공간이야. 그분 자체가 안전이야.\n오후에 뭔가 두렵거나 흔들릴 때, 피난처가 이미 있다는 걸 기억해.',
    application: '잠깐 쉬는 이 시간, 이 말씀 한 줄만 떠올려봐. 나는 지금 피난처 안에 있어, 라고.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '하나님은 우리의 피난처시요 힘이시라.',
    question: '힘든 순간 당신이 가장 먼저 찾게 되는 것은 무엇인가요?',
  },
  {
    verse_id: 'v_229',
    verse_short_ko: '그는 실로 우리의 질고를 지고 우리의 슬픔을 당하였거늘.',
    verse_full_ko: '그는 실로 우리의 질고를 지고 우리의 슬픔을 당하였거늘,\n우리는 그를 징벌 받아 하나님께 맞으며 고난 당하는 자로 여겼노라.',
    reference: '이사야 53:4',
    book: '이사야',
    chapter: 53,
    verse: 4,
    mode: 'recharge',
    theme: 'comfort,grace',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '이사야가 수백 년 전에 예언한 고난받는 종의 모습이야. 예수님을 가리키는 말이야.\n"질고를 지고"는 대신 짐을 들어준다는 뜻이야. 내가 안고 가는 게 아니야.\n오후에 피곤하고 지칠 때, 그 짐이 이미 지어진 짐이라는 걸 기억해봐.',
    application: '지금 무겁게 짊어진 것 하나 떠올려봐. 혼자 안고 있지 않아도 돼, 라고 말해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '요즘 혼자 안고 있는 것처럼 느껴지는 것이 있나요?',
  },
  {
    verse_id: 'v_230',
    verse_short_ko: '사람이 마음으로 자기의 길을 계획할지라도 그 걸음을 인도하는 자는 여호와시니라.',
    verse_full_ko: '사람이 마음으로 자기의 길을 계획할지라도,\n그 걸음을 인도하는 자는 여호와시니라.',
    reference: '잠언 16:9',
    book: '잠언',
    chapter: 16,
    verse: 9,
    mode: 'recharge',
    theme: 'patience,wisdom',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '지혜서인 잠언에서 인간의 계획과 하나님의 인도를 함께 말한 구절이야.\n계획을 금지하는 게 아니야. 내가 계획해도, 걸음은 그분이 이끄신다는 거야.\n오후에 계획대로 안 풀려도 그 걸음에 다른 인도가 있을 수 있어.',
    application: '오늘 계획이 어긋난 게 있다면, 그 걸음도 인도받고 있을 수 있다는 걸 생각해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '걸음을 인도하는 자는 여호와시니라.',
    question: '계획이 어긋났을 때 어떤 감정이 드나요?',
  },
  {
    verse_id: 'v_231',
    verse_short_ko: '주 안에서 기뻐하라, 내가 다시 말하노니 기뻐하라.',
    verse_full_ko: '주 안에서 항상 기뻐하라.\n내가 다시 말하노니 기뻐하라.\n너희 관용을 모든 사람에게 알게 하라. 주께서 가까우시니라.',
    reference: '빌립보서 4:4-5',
    book: '빌립보서',
    chapter: 4,
    verse: 4,
    mode: 'recharge',
    theme: 'gratitude,peace',
    mood: 'warm,calm',
    season: 'all',
    weather: 'any',
    interpretation: '바울이 감옥 안에서 빌립보 교회에 쓴 편지야. 불행한 상황에서 기뻐하라는 역설이야.\n"주 안에서"가 핵심이야. 상황이 아닌 그분 안에 있을 때 나오는 기쁨이야.\n오후에 기쁨이 사라졌을 때, 그 기쁨의 근거가 상황이 아님을 기억해봐.',
    application: '지금 이 쉬는 시간, 억지로 기쁠 필요 없어. 그냥 그분이 가까이 계신다는 것만 느껴봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '주 안에서 항상 기뻐하라.',
    question: '최근에 조건 없이 기뻤던 순간이 있었나요?',
  },
  {
    verse_id: 'v_232',
    verse_short_ko: '너희 짐을 여호와께 맡기라, 그가 너를 붙드시리로다.',
    verse_full_ko: '네 짐을 여호와께 맡기라.\n그가 너를 붙드시리로다.\n그가 의인의 요동함을 영원히 허락하지 아니하시리로다.',
    reference: '시편 55:22',
    book: '시편',
    chapter: 55,
    verse: 22,
    mode: 'recharge',
    theme: 'rest,comfort',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 친구에게 배신당하는 고통 속에서 하나님께 호소한 시야.\n"맡기라"는 던져놓으라는 강한 표현이야. 조심스럽게 드리는 게 아니라 그냥 넘기는 거야.\n오후에 지쳐서 더 이상 붙잡기 어렵다면 그냥 던져놔도 돼.',
    application: '지금 지쳐서 내려놓고 싶은 게 있다면 억지로 붙잡지 않아도 돼. 잠깐 그분께 그냥 던져봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '네 짐을 여호와께 맡기라, 그가 붙드시리로다.',
    question: '요즘 무엇을 오랫동안 혼자 붙잡고 있나요?',
  },
  {
    verse_id: 'v_233',
    verse_short_ko: '하나님이 나를 사랑하시되 자기 독생자를 주셨으니.',
    verse_full_ko: '하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니,\n이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라.',
    reference: '요한복음 3:16',
    book: '요한복음',
    chapter: 3,
    verse: 16,
    mode: 'recharge',
    theme: 'gratitude,comfort',
    mood: 'warm,calm',
    season: 'all',
    weather: 'any',
    interpretation: '예수님이 밤에 니고데모에게 직접 하신 말씀이야.\n"이처럼"이라는 표현이 사랑의 크기를 담아. 측정할 수 없는 사랑이야.\n오후에 스스로가 작게 느껴질 때, 이 크기의 사랑을 받는 사람이라는 걸 기억해.',
    application: '지금 이 쉬는 자리에서 이 구절 한 줄만 마음에 담아봐. 나는 이처럼 사랑받고 있어.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '당신은 사랑받고 있다는 걸 언제 가장 실감하나요?',
  },
  {
    verse_id: 'v_234',
    verse_short_ko: '모든 것이 합력하여 선을 이루느니라.',
    verse_full_ko: '우리가 알거니와 하나님을 사랑하는 자,\n곧 그의 뜻대로 부르심을 받은 자들에게는\n모든 것이 합력하여 선을 이루느니라.',
    reference: '로마서 8:28',
    book: '로마서',
    chapter: 8,
    verse: 28,
    mode: 'recharge',
    theme: 'patience,gratitude',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '바울이 로마 교회에 보낸 편지에서 하나님의 섭리를 설명한 구절이야.\n"합력하여"는 따로따로가 아니라 함께 엮여 결국 선으로 간다는 뜻이야.\n오후에 안 풀리는 것들이 있어도, 그 조각들이 연결되고 있다는 걸 기억해.',
    application: '오후에 잘 안 풀린 일 하나 떠올려봐. 그 조각도 지금 어딘가와 연결되고 있을 수 있어.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '모든 것이 합력하여 선을 이루느니라.',
    question: '지나고 나서야 좋았다고 느낀 경험이 있나요?',
  },
  {
    verse_id: 'v_235',
    verse_short_ko: '내가 자족하기를 배웠노라.',
    verse_full_ko: '내가 어떠한 형편에 있든지 자족하기를 배웠노라.\n비천에 처할 줄도 알고 풍부에 처할 줄도 알아,\n모든 일에 배부르며 배고픔과 풍부와 궁핍에도 일체의 비결을 배웠노라.',
    reference: '빌립보서 4:11-12',
    book: '빌립보서',
    chapter: 4,
    verse: 11,
    mode: 'recharge',
    theme: 'gratitude,patience',
    mood: 'calm,warm',
    season: 'all',
    weather: 'any',
    interpretation: '바울이 감옥 안에서 쓴 말이야. 처음부터 자족한 게 아니라 배웠다고 했어.\n자족은 타고나는 것이 아니라 훈련되는 거야. 지금 이 순간도 그 배움의 자리야.\n오후의 나른함과 부족함 속에서 지금 이 자리를 받아들여봐.',
    application: '지금 이 쉬는 자리, 부족하게 느껴져도 괜찮아. 지금 여기가 자족을 배우는 자리야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '지금 이 순간에 만족하기 어렵게 만드는 것이 무엇인가요?',
  },
  {
    verse_id: 'v_236',
    verse_short_ko: '여호와의 인자하심이 무궁하고 그 긍휼이 다함이 없도다.',
    verse_full_ko: '여호와의 인자하심이 무궁하고 그 긍휼이 다함이 없도다.\n아침마다 새로우니 주의 성실하심이 크시도소이다.',
    reference: '예레미야애가 3:22-23',
    book: '예레미야애가',
    chapter: 3,
    verse: 22,
    mode: 'recharge',
    theme: 'comfort,gratitude',
    mood: 'warm,calm',
    season: 'all',
    weather: 'any',
    interpretation: '예루살렘이 멸망한 직후 예레미야가 폐허 속에서 쓴 애가야.\n절망의 끝에서 무궁한 인자하심을 발견한 고백이야. 다함이 없어.\n오후에 지치고 기운이 빠져도, 그 긍휼은 아직 마르지 않았어.',
    application: '오늘 내가 잘 못한 것들 생각나도 괜찮아. 그 긍휼은 다함이 없으니까, 이미 새 거야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '여호와의 인자하심이 무궁하고 긍휼이 다함이 없도다.',
    question: '요즘 스스로를 용서하기 어려운 것이 있나요?',
  },
  {
    verse_id: 'v_237',
    verse_short_ko: '여호와는 마음이 상한 자에게 가까이 하시는도다.',
    verse_full_ko: '여호와는 마음이 상한 자에게 가까이 하시고,\n통회하는 자를 구원하시는도다.',
    reference: '시편 34:18',
    book: '시편',
    chapter: 34,
    verse: 18,
    mode: 'recharge',
    theme: 'comfort,peace',
    mood: 'warm,calm',
    season: 'all',
    weather: 'any',
    interpretation: '다윗이 아비멜렉 앞에서 미친 척 도망친 후 쓴 시야. 초라했던 순간에 쓴 고백이야.\n"가까이 하시고"는 마음이 상한 사람이 먼저 찾아가야 하는 게 아님을 뜻해.\n오후에 마음이 지쳐 있을 때, 그분이 먼저 가까이 오신다는 걸 기억해.',
    application: '지금 마음이 무겁다면 억지로 떨쳐내지 않아도 돼. 그 상태 그대로 가까이 오시는 분이 계셔.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '마음이 상했을 때 당신은 어디로 가나요?',
  },
  {
    verse_id: 'v_238',
    verse_short_ko: '나의 도움이 천지를 지으신 여호와에게서로다.',
    verse_full_ko: '나는 눈을 들어 산을 향하여 보리로다.\n나의 도움이 어디서 올꼬.\n나의 도움은 천지를 지으신 여호와에게서로다.',
    reference: '시편 121:1-2',
    book: '시편',
    chapter: 121,
    verse: 1,
    mode: 'recharge',
    theme: 'peace,strength',
    mood: 'calm,serene',
    season: 'all',
    weather: 'any',
    interpretation: '예루살렘 순례자가 올라가는 길에 부른 시야. 먼 산을 바라보며 도움을 구하는 노래야.\n천지를 지으신 분이 나의 도움이라는 건, 우주를 만든 능력이 내 편이라는 뜻이야.\n오후에 도움이 필요할 때, 그 도움의 출처가 어디인지 기억해봐.',
    application: '지금 잠깐 창밖이나 하늘 한 번 올려봐. 저 하늘을 만드신 분이 오늘 내 도움이 되신다는 거야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '나의 도움은 천지를 지으신 여호와에게서로다.',
    question: '도움이 필요할 때 당신은 가장 먼저 어디에 손을 내미나요?',
  },
  {
    verse_id: 'v_239',
    verse_short_ko: '선한 일을 행하되 낙심하지 말지니 포기하지 아니하면 때가 이르매 거두리로다.',
    verse_full_ko: '우리가 선을 행하되 낙심하지 말지니,\n포기하지 아니하면 때가 이르매 거두리로다.',
    reference: '갈라디아서 6:9',
    book: '갈라디아서',
    chapter: 6,
    verse: 9,
    mode: 'recharge',
    theme: 'patience,strength',
    mood: 'warm,calm',
    season: 'all',
    weather: 'any',
    interpretation: '바울이 갈라디아 교회 성도들에게 선한 삶의 피로감을 알아주며 격려한 말씀이야.\n"때가 이르매"는 아직 오지 않은 때를 기다리는 말이야. 지금 아직이라도 괜찮아.\n오후에 지쳐서 잘 하고 있는 건지 의심될 때, 아직 때가 안 된 것뿐이야.',
    application: '지금 힘들어도 포기하지 않은 것들이 있잖아. 그 자체가 이미 잘 하고 있는 거야.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: null,
    question: '지금 포기하고 싶지만 아직 버티고 있는 것이 있나요?',
  },
];

// ── Sheets 헤더 순서에 맞게 행 변환 ────────────────────────────────────────
// 헤더: verse_id, verse_short_ko, verse_full_ko, reference, book, chapter, verse,
//       mode, theme, mood, season, weather, interpretation, application, curated,
//       status, notes, usage_count, cooldown_days, last_shown, show_count,
//       alarm_top_ko, contemplation_ko, contemplation_reference,
//       contemplation_interpretation, contemplation_appliance, question,
//       len_verse_full_ko, len_verse_short_ko, len_interpretation, len_application,
//       len_alarm_top_ko, len_question

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
    // len_ 컬럼들은 수식 자동이므로 생략
  ];
}

async function main() {
  console.log(`=== add_recharge_verses.js | dry-run: ${isDryRun} | 대상: ${RECHARGE_VERSES.length}개 ===\n`);

  // 자체 검증
  let hasError = false;
  for (const v of RECHARGE_VERSES) {
    const issues = [];
    if (v.verse_short_ko.length > 60) issues.push(`verse_short_ko 초과: ${v.verse_short_ko.length}자`);
    if (v.verse_short_ko.length < 10) issues.push(`verse_short_ko 부족: ${v.verse_short_ko.length}자`);
    if (v.verse_full_ko.length > 200) issues.push(`verse_full_ko 초과: ${v.verse_full_ko.length}자`);
    if (v.interpretation.length > 200) issues.push(`interpretation 초과: ${v.interpretation.length}자`);
    if (v.interpretation.length < 80) issues.push(`interpretation 부족: ${v.interpretation.length}자`);
    if (v.application.length > 100) issues.push(`application 초과: ${v.application.length}자`);
    if (v.application.length < 40) issues.push(`application 부족: ${v.application.length}자 (권장 49자+)`);
    if (issues.length > 0) {
      console.error(`[오류] ${v.verse_id} (${v.reference}):`);
      issues.forEach(i => console.error(`  - ${i}`));
      hasError = true;
    }
  }

  if (hasError) {
    console.error('\n검증 실패 — 업로드 중단');
    process.exit(1);
  }

  console.log('자체 검증 통과\n');

  if (isDryRun) {
    RECHARGE_VERSES.forEach(v => {
      console.log(`[${v.verse_id}] ${v.reference}`);
      console.log(`  short(${v.verse_short_ko.length}자): ${v.verse_short_ko}`);
      console.log(`  full(${v.verse_full_ko.length}자): ${v.verse_full_ko.slice(0,50)}...`);
      console.log(`  interp(${v.interpretation.length}자): ${v.interpretation.slice(0,50)}...`);
      console.log(`  app(${v.application.length}자): ${v.application}`);
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

  const rows = RECHARGE_VERSES.map(toRow);

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
    console.log('  node apply_formula_fields.js    # 수식 필드 재적용');
    console.log('  node sync_sheets_to_firestore.js # Firestore 동기화');
  } catch (e) {
    console.error('업로드 실패:', e.message);
    process.exit(1);
  }
}

main().catch(console.error);
