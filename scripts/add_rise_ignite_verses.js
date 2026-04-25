/**
 * add_rise_ignite_verses.js
 * rise_ignite Zone 말씀 20개 (v_340 ~ v_359) Google Sheets VERSES 탭에 추가
 */

const { google } = require('googleapis');
const path = require('path');

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, 'serviceAccountKey.json');
const SHEET_NAME = 'VERSES';

// ──────────────────────────────────────────────
// 콘텐츠 데이터 (v_340 ~ v_359, rise_ignite)
// ──────────────────────────────────────────────
// 컬럼 순서:
// A: verse_id, B: verse_short_ko, C: verse_full_ko, D: reference,
// E: book, F: chapter, G: verse, H: mode, I: theme, J: mood,
// K: season, L: weather, M: interpretation, N: application,
// O: curated, P: status, Q: notes, R: usage_count, S: cooldown_days,
// T: last_shown, U: show_count, V: alarm_top_ko,
// W: contemplation_ko (수식), X: contemplation_reference (수식),
// Y: contemplation_interpretation (수식), Z: contemplation_appliance (수식),
// AA: question (비워둠), AB~AG: len_* (수식)

const verses = [
  {
    verse_id: 'v_340',
    verse_short_ko: '오늘도 주와 함께 일어나 힘차게 달려가자.',
    verse_full_ko: '여호와여 아침에 주께서 나의 소리를 들으시리니 아침에 내가 주께 기도하고 바라리이다',
    reference: '시편 5:3',
    book: '시편',
    chapter: 5,
    verse_num: 3,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '시편 기자는 매일 아침 하루의 첫 목소리를 하나님께 드렸어. 아침 기도는 하루 계획이 아니라 하나님을 향한 방향 설정이야. 그 소리를 주님이 들으신다는 확신이 이 구절의 핵심이야. 오늘 아침, 첫 말이 하나님께 향할 때 하루 전체가 달라지거든.',
    application: '오늘 아침 커피 한 잔 마시기 전에 딱 한 문장이라도 주님께 말 걸어봐.',
    alarm_top_ko: '아침에 주께 기도하고 바라리이다',
  },
  {
    verse_id: 'v_341',
    verse_short_ko: '강하고 담대하게, 두려워하지 말고 나아가자.',
    verse_full_ko: '내가 네게 명한 것이 아니냐 마음을 강하게 하고 담대히 하라 두려워 말며 놀라지 말라 네가 어디로 가든지 네 하나님 여호와가 너와 함께 하느니라',
    reference: '여호수아 1:9',
    book: '여호수아',
    chapter: 1,
    verse_num: 9,
    theme: '["courage","strength"]',
    mood: '["bright","dramatic"]',
    interpretation: '여호와는 이 말씀을 여호수아가 광야 40년을 마치고 가나안 땅을 앞에 두었을 때 주셨어. "명한 것이 아니냐"라는 표현은 이미 선포된 약속임을 강조하는 거야. 두려움이 아닌 담대함이 우리의 기본값이라는 선언이지. 오늘 아침 네가 무슨 도전을 앞두든, 주님이 함께하신다는 사실이 출발 신호야.',
    application: '오늘 가장 부담스러운 일을 맨 먼저 시작해봐. 주님이 함께하시거든.',
    alarm_top_ko: '마음을 강하게 하고 담대히 하라',
  },
  {
    verse_id: 'v_342',
    verse_short_ko: '주를 앙망하는 자는 새 힘을 얻으리니',
    verse_full_ko: '오직 여호와를 앙망하는 자는 새 힘을 얻으리니 독수리의 날개 치며 올라감 같을 것이요 달음박질하여도 곤비치 아니하겠고 걸어가도 피곤치 아니하리로다',
    reference: '이사야 40:31',
    book: '이사야',
    chapter: 40,
    verse_num: 31,
    theme: '["strength","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '이사야는 바벨론 포로 앞에 선 백성에게 이 말씀을 전했어. "앙망"은 단순한 바라봄이 아니라 온 힘을 다해 기대고 기다리는 태도야. 독수리가 기류를 타듯, 내 힘이 아닌 하나님의 에너지로 솟구치는 거지. 아침에 피곤함으로 시작해도, 주님을 향해 고개를 드는 순간 새 힘이 시작돼.',
    application: '오늘 아침 눈을 뜨며 "주님, 오늘 하루 주님 힘으로 달립니다"라고 한 번 말해봐.',
    alarm_top_ko: '',
  },
  {
    verse_id: 'v_343',
    verse_short_ko: '새 마음을 주시니 오늘을 새롭게 시작하자.',
    verse_full_ko: '또 새 영을 너희 속에 두고 새 마음을 너희에게 주되 너희 육신에서 굳은 마음을 제하고 부드러운 마음을 줄 것이며',
    reference: '에스겔 36:26',
    book: '에스겔',
    chapter: 36,
    verse_num: 26,
    theme: '["renewal","hope"]',
    mood: '["bright","dramatic"]',
    interpretation: '하나님이 돌 같이 굳어버린 마음을 살 마음으로 바꾸신다는 약속이야. 에스겔이 포로된 이스라엘 백성에게 선포한 회복의 말씀이지. 굳은 마음은 상처와 습관으로 굳어진 우리 안의 상태인데, 하나님은 그걸 부드럽게 만드시는 분이야. 새 아침은 어제의 굳음이 풀리는 시간이야.',
    application: '어제 마음이 닫혔던 누군가에게 오늘 먼저 웃으며 인사해봐.',
    alarm_top_ko: '새 마음을 너희에게 주되',
  },
  {
    verse_id: 'v_344',
    verse_short_ko: '담대히 일어나 하나님이 주신 일을 하자.',
    verse_full_ko: '일어나 일하라 여호와 하나님이 너와 함께 하시느니라 두려워 말고 놀라지 말라',
    reference: '역대상 28:20',
    book: '역대상',
    chapter: 28,
    verse_num: 20,
    theme: '["courage","strength"]',
    mood: '["bright","dramatic"]',
    interpretation: '다윗이 아들 솔로몬에게 성전 건축을 맡기며 한 말이야. 새로운 사명을 앞에 둔 이에게 "일어나 일하라"고 선포했어. 두려움은 자연스러운 감정이지만, 함께하시는 하나님이 더 크다는 거야. 오늘 아침 네가 해야 할 일이 크고 버거워 보여도, 일어나는 것 자체가 신앙의 첫 발걸음이야.',
    application: '오늘 아침 이불을 걷어내고 일어나는 그 순간, "주님이 함께하신다"고 말해봐.',
    alarm_top_ko: '일어나 일하라 여호와 하나님이 함께하시느니라',
  },
  {
    verse_id: 'v_345',
    verse_short_ko: '주 안에서 기뻐하라, 오늘 하루를 주님과 함께.',
    verse_full_ko: '주 안에서 항상 기뻐하라 내가 다시 말하노니 기뻐하라',
    reference: '빌립보서 4:4',
    book: '빌립보서',
    chapter: 4,
    verse_num: 4,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '바울이 감옥에서 쓴 편지야. 환경이 최악이었는데도 기뻐하라고 선포했어. "주 안에서"라는 전제가 핵심인데, 상황이 아니라 주님과의 관계가 기쁨의 근거라는 뜻이야. 아침에 감사할 게 안 보여도 괜찮아. 주님 안에 있다는 사실 하나로 충분히 기뻐할 수 있거든.',
    application: '오늘 아침 밥 먹으면서 "이게 감사하네" 하는 것 하나만 찾아봐.',
    alarm_top_ko: '주 안에서 항상 기뻐하라',
  },
  {
    verse_id: 'v_346',
    verse_short_ko: '선을 행하다가 낙심치 말라, 때가 오리니.',
    verse_full_ko: '우리가 선을 행하되 낙심하지 말지니 피곤하지 아니하면 때가 이르매 거두리로다',
    reference: '갈라디아서 6:9',
    book: '갈라디아서',
    chapter: 6,
    verse_num: 9,
    theme: '["courage","hope"]',
    mood: '["bright","dramatic"]',
    interpretation: '갈라디아서는 힘든 상황에서도 선한 일을 계속하라고 권면해. "피곤하지 아니하면"은 포기하지 않으면이라는 뜻이야. 선한 일의 결과가 눈에 보이지 않아도, 때가 되면 반드시 거둔다는 약속이야. 오늘 아침 작은 선함을 포기하고 싶다면, 아직 때가 안 된 것뿐이야. 계속 가봐.',
    application: '오늘 하루 내가 하기 싫어도 해야 할 선한 일 하나를 먼저 실천해봐.',
    alarm_top_ko: '선을 행하되 낙심하지 말지니',
  },
  {
    verse_id: 'v_347',
    verse_short_ko: '일하는 자를 하나님이 보신다, 마음을 다해.',
    verse_full_ko: '무슨 일을 하든지 마음을 다하여 주께 하듯 하고 사람에게 하듯 하지 말라',
    reference: '골로새서 3:23',
    book: '골로새서',
    chapter: 3,
    verse_num: 23,
    theme: '["strength","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '골로새서는 일상의 모든 일이 신앙적 행위가 될 수 있다고 가르쳐. "주께 하듯"은 작은 일도 하나님 앞에서 하는 예배처럼 여기라는 뜻이야. 누가 보든 보지 않든 마음을 다하는 태도가 크리스천의 삶이지. 오늘 아침, 오늘 하루의 일이 곧 주께 드리는 선물이야.',
    application: '오늘 맡은 첫 번째 일을 "주께 드리는 것"처럼 정성껏 시작해봐.',
    alarm_top_ko: '마음을 다하여 주께 하듯 하고',
  },
  {
    verse_id: 'v_348',
    verse_short_ko: '하나님이 빛을 비추시니 오늘을 담대히.',
    verse_full_ko: '일어나라 빛을 발하라 이는 네 빛이 이르렀고 여호와의 영광이 네 위에 임하였음이니라',
    reference: '이사야 60:1',
    book: '이사야',
    chapter: 60,
    verse_num: 1,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '이사야 60장은 회복된 시온을 향한 선포야. "일어나라 빛을 발하라"는 수동적 상태에서 능동적 삶으로의 전환 명령이야. 이미 빛이 이르렀고 영광이 임했기 때문에 빛을 발할 수 있다는 거지. 아침에 일어나는 행위 자체가 이 선포를 몸으로 사는 것이야.',
    application: '오늘 아침 거울을 보며 "나는 빛을 발하러 나간다"고 한 번 말해봐.',
    alarm_top_ko: '일어나라 빛을 발하라',
  },
  {
    verse_id: 'v_349',
    verse_short_ko: '나를 향한 주의 뜻은 선하고 아름답다.',
    verse_full_ko: '여호와의 말씀이니라 너희를 향한 나의 생각은 내가 아나니 재앙이 아니라 곧 평안이요 너희 장래에 소망을 주려하는 생각이라',
    reference: '예레미야 29:11',
    book: '예레미야',
    chapter: 29,
    verse_num: 11,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '예레미야 29장은 70년 포로 생활 중에 쓰인 편지야. 최악의 상황에서도 하나님은 "평안과 소망"을 계획하신다고 선포하셨어. 내 생각이 아닌 하나님의 생각이 기준이라는 게 핵심이야. 오늘 아침 앞날이 불확실해도, 주님의 생각은 이미 좋은 쪽으로 향해 있어.',
    application: '오늘 걱정되는 일 하나를 "주님 뜻에 맡깁니다"라고 말로 놓아봐.',
    alarm_top_ko: '',
  },
  {
    verse_id: 'v_350',
    verse_short_ko: '주님의 이름으로 나아가니 이길 수 있어.',
    verse_full_ko: '여호와의 이름으로 나아가노라 그 이름이 높임을 받으시기를 바라노라',
    reference: '시편 20:7',
    book: '시편',
    chapter: 20,
    verse_num: 7,
    theme: '["courage","strength"]',
    mood: '["bright","dramatic"]',
    interpretation: '시편 20편은 전쟁 전날 드리는 기도야. 어떤 이는 말과 병거를 믿지만 우리는 여호와의 이름을 믿는다는 신앙 선언이야. 인간의 힘이 아닌 하나님의 이름을 기대는 것이 진짜 담대함이야. 오늘 아침 무기가 없어도, 주님 이름이 있으면 충분해.',
    application: '오늘 하루 시작 전 "주님의 이름으로 나아갑니다"라고 짧게 선포해봐.',
    alarm_top_ko: '여호와의 이름으로 나아가노라',
  },
  {
    verse_id: 'v_351',
    verse_short_ko: '하나님이 세우신 나, 오늘도 흔들리지 않아.',
    verse_full_ko: '여호와는 나의 빛이요 나의 구원이시니 내가 누구를 두려워하리요 여호와는 내 생명의 능력이시니 내가 누구를 무서워하리요',
    reference: '시편 27:1',
    book: '시편',
    chapter: 27,
    verse_num: 1,
    theme: '["courage","strength"]',
    mood: '["bright","dramatic"]',
    interpretation: '다윗은 적군에 둘러싸인 상황에서 이 시편을 썼어. "빛"과 "구원"은 방향과 안전을 뜻하고, "생명의 능력"은 내 존재를 지탱하시는 분이라는 뜻이야. 두려움의 원인보다 하나님의 크기를 보는 게 핵심이야. 오늘 아침 무서운 게 있어도, 그보다 주님이 크다는 걸 기억해봐.',
    application: '오늘 아침 "누구를 두려워하리요"를 한 번 소리 내어 읽어봐.',
    alarm_top_ko: '여호와는 나의 빛이요 나의 구원이시니',
  },
  {
    verse_id: 'v_352',
    verse_short_ko: '새날을 주신 주께 감사하며 힘차게 출발.',
    verse_full_ko: '이것이 여호와의 정하신 날이라 이날에 우리가 기뻐하고 즐거워하리로다',
    reference: '시편 118:24',
    book: '시편',
    chapter: 118,
    verse_num: 24,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '시편 118편은 승리를 감사하는 시야. "여호와의 정하신 날"은 하나님이 설계하고 허락하신 오늘이라는 뜻이야. 우리가 기뻐하는 것이 적절한 반응이라고 선포해. 오늘이 어렵고 평범해 보여도, 주님이 허락하신 날이라는 사실 하나로 기쁠 이유가 충분해.',
    application: '아침에 일어나자마자 "오늘 이날을 주님이 주셨구나"라고 한 번 생각해봐.',
    alarm_top_ko: '이날에 우리가 기뻐하고 즐거워하리로다',
  },
  {
    verse_id: 'v_353',
    verse_short_ko: '오직 여호와만 바라보며 오늘을 걸어가자.',
    verse_full_ko: '여호와를 의뢰하고 선을 행하라 땅에 머무는 동안 그의 성실로 식물을 삼을지어다',
    reference: '시편 37:3',
    book: '시편',
    chapter: 37,
    verse_num: 3,
    theme: '["hope","courage"]',
    mood: '["bright","dramatic"]',
    interpretation: '시편 37편은 악인의 번성에 흔들리지 말라는 메시지야. "여호와를 의뢰하고 선을 행하라"는 순서가 중요해 — 먼저 믿고, 그다음 행동이야. 성실이 식물이 된다는 건 하나님의 신실하심을 매일의 양식으로 삼으라는 말이야. 오늘 하루 먼저 믿고, 그 믿음으로 선한 일을 해봐.',
    application: '오늘 하루 불안한 생각이 올 때마다 "주를 의뢰하자"라고 되뇌어봐.',
    alarm_top_ko: '여호와를 의뢰하고 선을 행하라',
  },
  {
    verse_id: 'v_354',
    verse_short_ko: '감사함으로 그 문에 들어가 오늘을 시작해.',
    verse_full_ko: '감사함으로 그 문에 들어가며 찬송함으로 그 궁정에 들어가서 그에게 감사하며 그 이름을 송축할지어다',
    reference: '시편 100:4',
    book: '시편',
    chapter: 100,
    verse_num: 4,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '시편 100편은 온 땅이 여호와께 즐거운 소리를 발하라는 초청이야. 문에 들어가는 것이 "감사함으로"라는 점이 핵심이야. 하루를 시작하는 문 앞에서 감사가 먼저라는 뜻이지. 오늘 아침 눈을 뜨는 것 자체가 그 문 앞에 선 순간이야. 감사를 먼저 꺼내봐.',
    application: '오늘 아침 가장 먼저 감사한 것 하나를 종이에 적거나 말로 해봐.',
    alarm_top_ko: '감사함으로 그 문에 들어가며',
  },
  {
    verse_id: 'v_355',
    verse_short_ko: '능력 주시는 자 안에서 무엇이든 할 수 있어.',
    verse_full_ko: '내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라',
    reference: '빌립보서 4:13',
    book: '빌립보서',
    chapter: 4,
    verse_num: 13,
    theme: '["strength","courage"]',
    mood: '["bright","dramatic"]',
    interpretation: '바울이 어떤 형편에서도 자족하는 비결을 고백하며 한 말이야. "능력 주시는 자 안에서"가 핵심이야 — 내 능력이 아니라 주님이 주시는 능력으로 한다는 뜻이지. 오늘 아침 내 힘만으로 하루가 벅차도, 능력의 원천이 달라질 때 한계도 달라져. 주님 안에서 오늘을 시작해봐.',
    application: '오늘 가장 힘든 일 앞에서 "나는 능력 주시는 분 안에 있다"고 되뇌어봐.',
    alarm_top_ko: '',
  },
  {
    verse_id: 'v_356',
    verse_short_ko: '말씀을 묵상하며 형통한 하루를 걸어가자.',
    verse_full_ko: '이 율법책을 네 입에서 떠나지 말게 하며 주야로 그것을 묵상하여 그 가운데 기록한 대로 다 지켜 행하라 그리하면 네 길이 평탄하게 될 것이라 네가 형통하리라',
    reference: '여호수아 1:8',
    book: '여호수아',
    chapter: 1,
    verse_num: 8,
    theme: '["strength","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '하나님이 여호수아에게 가나안 정복의 핵심 원칙을 주신 말씀이야. 말씀이 입에서 떠나지 않는다는 건 언제나 말씀을 기준으로 살아간다는 뜻이야. 형통의 비결은 전략이나 능력보다 말씀과의 동행이야. 오늘 아침 이 앱에서 읽은 말씀이 그 시작이 될 수 있어.',
    application: '오늘 아침 이 말씀을 캡처하거나 적어서 하루 중 한 번 더 꺼내봐.',
    alarm_top_ko: '말씀을 묵상하면 네 길이 평탄하리라',
  },
  {
    verse_id: 'v_357',
    verse_short_ko: '힘차게 달려가는 오늘, 하나님이 함께하신다.',
    verse_full_ko: '그런즉 이 일에 대하여 우리가 무슨 말 하리요 만일 하나님이 우리를 위하시면 누가 우리를 대적하리요',
    reference: '로마서 8:31',
    book: '로마서',
    chapter: 8,
    verse_num: 31,
    theme: '["courage","hope"]',
    mood: '["bright","dramatic"]',
    interpretation: '로마서 8장은 어떤 것도 하나님의 사랑에서 끊을 수 없다고 선포해. "하나님이 우리를 위하시면"은 이미 확정된 사실이야. 대적이 있어도 두려울 게 없는 이유가 여기에 있어. 오늘 아침 누가 날 막으려 해도, 하나님이 내 편이시라는 게 변함없는 사실이야.',
    application: '오늘 아침 출발하기 전에 "하나님이 내 편이시다"라고 한 번 선포해봐.',
    alarm_top_ko: '하나님이 우리를 위하시면 누가 대적하리요',
  },
  {
    verse_id: 'v_358',
    verse_short_ko: '정의와 공의로 행하는 자에게 아침 빛 같이.',
    verse_full_ko: '의인의 길은 돋는 햇빛 같아서 점점 빛나 원만한 광명에 이르거니와',
    reference: '잠언 4:18',
    book: '잠언',
    chapter: 4,
    verse_num: 18,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '잠언 4장은 지혜로운 삶의 방향을 이야기해. 의인의 길은 돋는 햇빛처럼 갈수록 밝아진다는 게 핵심이야. 처음엔 희미하고 작아 보여도 방향이 옳으면 점점 밝아지는 거야. 오늘 아침의 작은 선택 하나가 내 삶을 조금 더 밝은 쪽으로 향하게 해.',
    application: '오늘 아침 딱 하나, 옳은 방향의 선택을 먼저 해봐.',
    alarm_top_ko: '의인의 길은 돋는 햇빛 같아서',
  },
  {
    verse_id: 'v_359',
    verse_short_ko: '아침마다 새로워지는 주의 사랑을 기억해봐.',
    verse_full_ko: '여호와의 인자와 긍휼이 무궁하시므로 우리가 진멸되지 아니함이니이다 이것이 아침마다 새로우니 주의 성실하심이 크도소이다',
    reference: '예레미야애가 3:22-23',
    book: '예레미야애가',
    chapter: 3,
    verse_num: 22,
    theme: '["hope","renewal"]',
    mood: '["bright","dramatic"]',
    interpretation: '예레미야애가는 예루살렘 멸망의 고통 한복판에서 쓰인 글이야. 그 극심한 고통 중에서도 아침마다 새로운 하나님의 사랑을 발견한 거야. "아침마다 새로우니"는 어제의 실패나 상처가 오늘을 막지 못한다는 뜻이야. 오늘 아침은 새로운 인자와 긍휼이 기다리는 시간이야.',
    application: '오늘 아침 "어제는 어제, 오늘은 새 날"이라고 스스로에게 말해봐.',
    alarm_top_ko: '아침마다 새로우니 주의 성실하심이 크도소이다',
  },
];

// ──────────────────────────────────────────────
// 헬퍼: 각 구절을 Sheets row 배열로 변환
// 컬럼: A~V (W~AG는 수식/자동이라 비워둠)
// ──────────────────────────────────────────────
function verseToRow(v) {
  // A: verse_id
  // B: verse_short_ko
  // C: verse_full_ko
  // D: reference
  // E: book
  // F: chapter
  // G: verse
  // H: mode
  // I: theme
  // J: mood
  // K: season
  // L: weather
  // M: interpretation
  // N: application
  // O: curated
  // P: status
  // Q: notes
  // R: usage_count
  // S: cooldown_days
  // T: last_shown
  // U: show_count
  // V: alarm_top_ko
  return [
    v.verse_id,           // A
    v.verse_short_ko,     // B
    v.verse_full_ko,      // C
    v.reference,          // D
    v.book,               // E
    v.chapter,            // F
    v.verse_num,          // G
    'rise_ignite',        // H - mode
    v.theme,              // I
    v.mood,               // J
    '["all"]',            // K - season
    '["any"]',            // L - weather
    v.interpretation,     // M
    v.application,        // N
    'TRUE',               // O - curated
    'active',             // P - status
    '',                   // Q - notes
    0,                    // R - usage_count
    '',                   // S - cooldown_days
    '',                   // T - last_shown
    0,                    // U - show_count
    v.alarm_top_ko,       // V
  ];
}

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  const rows = verses.map(verseToRow);

  console.log(`총 ${rows.length}개 구절 추가 시작...`);

  const res = await sheets.spreadsheets.values.append({
    spreadsheetId: SPREADSHEET_ID,
    range: `${SHEET_NAME}!A:V`,
    valueInputOption: 'USER_ENTERED',
    insertDataOption: 'INSERT_ROWS',
    requestBody: {
      values: rows,
    },
  });

  console.log('업로드 완료!');
  console.log('업데이트 범위:', res.data.updates.updatedRange);
  console.log('추가된 행 수:', res.data.updates.updatedRows);
  console.log('추가된 셀 수:', res.data.updates.updatedCells);

  // 간단한 검증 출력
  console.log('\n--- 추가된 구절 목록 ---');
  verses.forEach(v => {
    const shortLen = v.verse_short_ko.length;
    const interpLen = v.interpretation.length;
    const appLen = v.application.length;
    const shortOk = shortLen <= 35 ? 'OK' : 'OVER';
    const interpOk = (interpLen >= 80 && interpLen <= 200) ? 'OK' : 'CHECK';
    const appOk = (appLen >= 30 && appLen <= 100) ? 'OK' : 'CHECK';
    console.log(`${v.verse_id} | ${v.reference} | short:${shortLen}자[${shortOk}] | interp:${interpLen}자[${interpOk}] | app:${appLen}자[${appOk}]`);
  });
}

main().catch(err => {
  console.error('오류 발생:', err.message);
  process.exit(1);
});
