/**
 * add_daily_cards_2027.js
 * 2027년 기독교 절기별 특별 콘텐츠 생성 및 Google Sheets 업로드
 *
 * 작업 순서:
 *  1. VERSES 탭에 절기 전용 말씀 12개 추가 (v_420~v_431)
 *  2. DAILY_CARDS 탭에 날짜·verse_id·인사말·이미지프롬프트 12행 추가
 *
 * 사용: node add_daily_cards_2027.js [--dry-run]
 */

require('dotenv').config();
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');

const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SERVICE_ACCOUNT = '/Users/jeongyong/workspace/dailyverse/scripts/serviceAccountKey.json';
const DRY_RUN = process.argv.includes('--dry-run');

// ─── 절기별 콘텐츠 (12개) ─────────────────────────────────────────────────
// verse_id: v_420~v_431 (현재 최대 v_419 기준)
const FESTIVAL_VERSES = [
  {
    verse_id: 'v_420',
    // ── 신년 2027-01-01 ─────────────────────────────────────────────────
    date: '2027-01-01',
    event_name: '신년',
    verse_short_ko: '보라 내가 새 일을 행하리니',
    verse_full_ko: '보라 내가 새 일을 행하리니 이제 나타낼 것이라 너희가 그것을 알지 못하겠느냐 정녕히 내가 광야에 길과 사막에 강을 내리니',
    reference: '이사야 43:19',
    book: '이사야',
    chapter: 43,
    verse_num: 19,
    mode: ['all'],
    theme: ['renewal', 'hope'],
    mood: ['bright'],
    season: ['winter'],
    weather: ['any'],
    interpretation: '이스라엘이 바벨론 포로로 절망에 빠졌을 때 하나님이 선언하신 말씀이야. 출애굽의 기적보다 더 놀라운 일을 예비하신다는 약속이지. 지난해의 상처와 실패가 아무리 커도, 새해의 첫 페이지는 하나님이 직접 쓰신 약속으로 시작돼. 새날 아침, 이 선언이 네 마음에 닿기를.',
    application: '올 한 해 가장 기대하는 한 가지를 마음속으로 하나님께 말해봐.',
    greeting_ko: '새해가 시작됐어요!',
    greeting_en: 'Happy New Year! New chapter begins.',
    image_prompt: 'golden sunrise over misty mountains with first light breaking through clouds, no text no letters no watermark, 9:16 vertical, documentary DSLR realism, soft rays of dawn light, horizon glow',
  },
  {
    verse_id: 'v_421',
    // ── 재의 수요일 2027-02-10 ─────────────────────────────────────────
    date: '2027-02-10',
    event_name: '재의 수요일',
    verse_short_ko: '너희는 이제라도 금식하며 내게로 돌아오라',
    verse_full_ko: '여호와의 말씀에 너희는 이제라도 금식하고 울며 애통하며 마음을 다하여 내게로 돌아오라 하셨나니',
    reference: '요엘 2:12',
    book: '요엘',
    chapter: 2,
    verse_num: 12,
    mode: ['all'],
    theme: ['stillness', 'faith'],
    mood: ['serene'],
    season: ['winter'],
    weather: ['any'],
    interpretation: '요엘 선지자가 메뚜기 재앙으로 황폐해진 이스라엘에게 전한 말씀이야. 재의 수요일은 사순절의 시작, 우리가 흙에서 왔음을 기억하며 하나님 앞에 낮아지는 날이지. 겉으로만 흉내 내는 게 아니라 마음 깊은 곳에서부터 돌이키는 것, 그게 진정한 회개야.',
    application: '오늘 하루, 평소보다 말 한 마디를 줄이고 마음속으로 조용히 하나님 앞에 앉아봐.',
    greeting_ko: '사순절이 시작됐어요.',
    greeting_en: 'Ash Wednesday — a quiet return.',
    image_prompt: 'single candle flame in dark room with ash and dried leaves on wooden surface, no text no letters no watermark, 9:16 vertical, documentary DSLR realism, moody dim light',
  },
  {
    verse_id: 'v_422',
    // ── 종려주일 2027-03-21 ─────────────────────────────────────────────
    date: '2027-03-21',
    event_name: '종려주일',
    verse_short_ko: '호산나 다윗의 자손이여 찬송하리로다',
    verse_full_ko: '앞에서 가고 뒤에서 따르는 무리가 소리질러 가로되 호산나 다윗의 자손이여 찬송하리로다 주의 이름으로 오시는 이여 가장 높은 곳에서 호산나 하더라',
    reference: '마태복음 21:9',
    book: '마태복음',
    chapter: 21,
    verse_num: 9,
    mode: ['all'],
    theme: ['hope', 'renewal'],
    mood: ['bright', 'dramatic'],
    season: ['spring'],
    weather: ['sunny'],
    interpretation: '예수님이 나귀를 타고 예루살렘에 입성하실 때 군중이 종려나무 가지를 흔들며 외친 환호야. 겸손한 나귀 위의 왕, 그것이 이 세상과 다른 하나님 나라의 방식이야. 어떤 권력도 아닌 사랑으로 오신 왕을 맞이하는 날, 네 마음에도 그 환호가 울려 퍼지길.',
    application: '오늘 예배나 기도 중에 마음으로 "호산나!"라고 외쳐봐.',
    greeting_ko: '종려주일을 함께 맞이해요!',
    greeting_en: 'Palm Sunday — hosanna to the King.',
    image_prompt: 'green palm branches in bright spring sunlight with stone pathway, no text no letters no watermark, 9:16 vertical, documentary DSLR realism, golden hour warm tone',
  },
  {
    verse_id: 'v_423',
    // ── 성 금요일 2027-03-26 ─────────────────────────────────────────
    date: '2027-03-26',
    event_name: '성 금요일',
    verse_short_ko: '그가 찔림은 우리의 허물을 인함이요',
    verse_full_ko: '그가 찔림은 우리의 허물을 인함이요 그가 상함은 우리의 죄악을 인함이라 그가 징계를 받으므로 우리가 평화를 누리고 그가 채찍에 맞으므로 우리가 나음을 입었도다',
    reference: '이사야 53:5',
    book: '이사야',
    chapter: 53,
    verse_num: 5,
    mode: ['all'],
    theme: ['grace', 'faith'],
    mood: ['serene', 'calm'],
    season: ['spring'],
    weather: ['any'],
    interpretation: '십자가 사건보다 700년 앞서 이사야가 남긴 예언이야. 찔리고 상하고 채찍 맞은 그 고통이 우리의 것이었는데, 그가 대신 짊어진 거야. 오늘 성 금요일에 그 무게를 잠시 묵상해봐. 그 사랑이 얼마나 깊은지.',
    application: '오늘 하루 십자가를 바라보며 "이것이 나를 위한 것이었구나" 하고 잠시 멈춰봐.',
    greeting_ko: '십자가의 사랑을 기억해요.',
    greeting_en: 'Good Friday — love on the cross.',
    image_prompt: 'wooden cross silhouette against dramatic sunset sky with dark clouds and single ray of light, no text no letters no watermark, 9:16 vertical, documentary DSLR realism',
  },
  {
    verse_id: 'v_424',
    // ── 부활절 2027-03-28 ─────────────────────────────────────────────
    date: '2027-03-28',
    event_name: '부활절',
    verse_short_ko: '나는 부활이요 생명이니',
    verse_full_ko: '예수께서 가라사대 나는 부활이요 생명이니 나를 믿는 자는 죽어도 살겠고 무릇 살아서 나를 믿는 자는 영원히 죽지 아니하리니 이것을 네가 믿느냐',
    reference: '요한복음 11:25-26',
    book: '요한복음',
    chapter: 11,
    verse_num: 25,
    mode: ['all'],
    theme: ['hope', 'faith'],
    mood: ['bright', 'dramatic'],
    season: ['spring'],
    weather: ['sunny'],
    interpretation: '나사로의 무덤 앞에서 마르다에게 하신 말씀이야. 죽음 앞에서 흔들리던 마르다에게, 부활은 먼 훗날 이야기가 아니라 지금 그녀 앞에 서 계신 분이라고 선언하셨지. 빈 무덤은 끝이 아니라 시작이야. 오늘 부활절, 그 새벽빛이 네 삶에도 닿길.',
    application: '오늘 가장 소중한 사람에게 "그리스도가 부활하셨어요"라고 전해봐.',
    greeting_ko: '예수님이 부활하셨어요!',
    greeting_en: 'He is risen! Happy Easter!',
    image_prompt: 'empty stone tomb entrance at dawn with wildflowers and soft morning mist, no text no letters no watermark, 9:16 vertical, documentary DSLR realism, golden sunrise light',
  },
  {
    verse_id: 'v_425',
    // ── 어린이주일 2027-05-02 ─────────────────────────────────────────
    date: '2027-05-02',
    event_name: '어린이주일',
    verse_short_ko: '어린아이들이 내게 오는 것을 금하지 말라',
    verse_full_ko: '예수께서 보시고 노하시어 이르시되 어린아이들이 내게 오는 것을 용납하고 금하지 말라 하나님의 나라가 이런 자의 것이니라',
    reference: '마가복음 10:14',
    book: '마가복음',
    chapter: 10,
    verse_num: 14,
    mode: ['all'],
    theme: ['hope', 'grace'],
    mood: ['bright', 'warm'],
    season: ['spring'],
    weather: ['sunny'],
    interpretation: '제자들이 아이들을 예수님께 데려오는 부모를 막았을 때, 예수님이 노하시며 하신 말씀이야. 아이의 마음처럼 조건 없이 나아가는 것, 그게 하나님 나라의 자격이야. 오늘 어린이주일, 어른이 된 우리도 그 순수한 마음으로 나아가볼 수 있어.',
    application: '오늘 주변 아이에게 진심 어린 관심을 기울여봐, 아니면 네 안의 어린 마음을 꺼내봐.',
    greeting_ko: '어린이주일을 함께 기뻐해요!',
    greeting_en: "Children's Sunday — come freely.",
    image_prompt: 'small hands holding spring flowers in sunlit green meadow, no text no letters no watermark, 9:16 vertical, documentary DSLR realism, soft warm natural light',
  },
  {
    verse_id: 'v_426',
    // ── 어버이주일 2027-05-09 ─────────────────────────────────────────
    date: '2027-05-09',
    event_name: '어버이주일',
    verse_short_ko: '네 부모를 공경하라',
    verse_full_ko: '네 부모를 공경하라 그리하면 너의 하나님 나 여호와가 네게 준 땅에서 네 생명이 길리라',
    reference: '출애굽기 20:12',
    book: '출애굽기',
    chapter: 20,
    verse_num: 12,
    mode: ['all'],
    theme: ['gratitude', 'peace'],
    mood: ['warm'],
    season: ['spring'],
    weather: ['any'],
    interpretation: '십계명 중에서 사람과의 관계를 다루는 첫 번째 계명이야. 부모 공경은 단순한 효도를 넘어, 생명을 이어받은 모든 관계를 귀하게 여기는 삶의 방향이야. 오늘 어버이주일, 먼저 주어진 사랑에 감사하는 마음을 품어봐.',
    application: '오늘 부모님께 짧은 한 마디라도, 감사하다는 말을 전해봐.',
    greeting_ko: '어버이의 사랑에 감사해요!',
    greeting_en: "Parents' Sunday — honor them today.",
    image_prompt: 'two aged hands gently clasped together with warm afternoon light through window, no text no letters no watermark, 9:16 vertical, documentary DSLR realism',
  },
  {
    verse_id: 'v_427',
    // ── 성령강림절 2027-05-16 ─────────────────────────────────────────
    date: '2027-05-16',
    event_name: '성령강림절',
    verse_short_ko: '홀연히 하늘로서 급하고 강한 바람 같은 소리가 있어',
    verse_full_ko: '오순절 날이 이미 이르매 저희가 다같이 한 곳에 모였더니 홀연히 하늘로서 급하고 강한 바람 같은 소리가 있어 저희 앉은 온 집에 가득하며',
    reference: '사도행전 2:1-2',
    book: '사도행전',
    chapter: 2,
    verse_num: 1,
    mode: ['all'],
    theme: ['renewal', 'strength'],
    mood: ['bright', 'dramatic'],
    season: ['spring'],
    weather: ['any'],
    interpretation: '예수님의 약속대로 성령이 임하신 오순절 현장이야. 바람 소리와 불의 혀처럼 갈라지는 형상, 전혀 예상 못 한 방식으로 찾아오신 성령님이지. 우리 힘으로 되는 게 없다고 느낄 때, 하나님의 영이 채우신다는 약속이야.',
    application: '오늘 "성령님, 오늘 나와 함께해 주세요"라고 짧게 기도해봐.',
    greeting_ko: '성령강림절을 함께 경험해요!',
    greeting_en: 'Pentecost — the Spirit moves today.',
    image_prompt: 'bright flames of fire reflected on calm water surface with rays of light breaking through dark sky, no text no letters no watermark, 9:16 vertical, documentary DSLR realism',
  },
  {
    verse_id: 'v_428',
    // ── 추수감사주일 2027-11-21 ───────────────────────────────────────
    date: '2027-11-21',
    event_name: '추수감사주일',
    verse_short_ko: '범사에 감사하라 이것이 하나님의 뜻이니라',
    verse_full_ko: '범사에 감사하라 이는 그리스도 예수 안에서 너희를 향하신 하나님의 뜻이니라',
    reference: '데살로니가전서 5:18',
    book: '데살로니가전서',
    chapter: 5,
    verse_num: 18,
    mode: ['all'],
    theme: ['gratitude', 'peace'],
    mood: ['warm', 'serene'],
    season: ['autumn'],
    weather: ['any'],
    interpretation: '바울이 박해 속에서도 데살로니가 교회에 쓴 편지야. 좋은 일이 있을 때만 감사하라는 게 아니라 "범사에", 즉 모든 상황에서 감사하라는 거야. 감사는 상황에 따라 달라지는 감정이 아니라 하나님을 향한 신뢰에서 나오는 태도거든. 오늘 수확의 계절, 놓쳤던 감사를 찾아봐.',
    application: '오늘 감사 제목 딱 하나, 어떤 작은 것이라도 적어봐.',
    greeting_ko: '추수감사절을 함께 나눠요!',
    greeting_en: 'Thanksgiving — give thanks always.',
    image_prompt: 'golden autumn wheat field at harvest time with warm afternoon sunlight and soft bokeh, no text no letters no watermark, 9:16 vertical, documentary DSLR realism',
  },
  {
    verse_id: 'v_429',
    // ── 대림절 첫째 주 2027-11-28 ─────────────────────────────────────
    date: '2027-11-28',
    event_name: '대림절 첫째 주',
    verse_short_ko: '이제는 자다가 깰 때가 되었으니',
    verse_full_ko: '또한 너희가 이 시기를 알거니와 자다가 깰 때가 벌써 되었으니 이는 이제 우리의 구원이 처음 믿을 때보다 가까웠음이니라',
    reference: '로마서 13:11',
    book: '로마서',
    chapter: 13,
    verse_num: 11,
    mode: ['all'],
    theme: ['hope', 'renewal'],
    mood: ['serene', 'calm'],
    season: ['winter'],
    weather: ['any'],
    interpretation: '바울이 로마 교회에게 주님의 재림을 기다리며 깨어 있으라고 당부한 말씀이야. 대림절은 오실 주님을 기다리며 마음을 준비하는 계절이야. 바쁜 12월의 시작에, 잠시 멈추고 무엇을 기다리고 있는지 살펴보는 시간이 돼.',
    application: '이번 주 대림절 촛불 하나를 켜거나, 기다림의 마음으로 하루를 시작해봐.',
    greeting_ko: '대림절이 시작됐어요.',
    greeting_en: 'Advent begins — wait for the King.',
    image_prompt: 'single advent candle flame in the darkness with blurred bokeh lights in background, no text no letters no watermark, 9:16 vertical, documentary DSLR realism, deep dark atmosphere',
  },
  {
    verse_id: 'v_430',
    // ── 성탄절 2027-12-25 ─────────────────────────────────────────────
    date: '2027-12-25',
    event_name: '성탄절',
    verse_short_ko: '오늘날 다윗의 동네에 너희를 위하여 구주가 나셨으니',
    verse_full_ko: '오늘날 다윗의 동네에 너희를 위하여 구주가 나셨으니 곧 그리스도 주시니라',
    reference: '누가복음 2:11',
    book: '누가복음',
    chapter: 2,
    verse_num: 11,
    mode: ['all'],
    theme: ['hope', 'grace'],
    mood: ['bright', 'warm'],
    season: ['winter'],
    weather: ['any'],
    interpretation: '천사가 목자들에게 아기 예수의 탄생을 전한 말씀이야. 세상에서 가장 보잘것없는 이들에게, 가장 위대한 소식이 가장 먼저 전해진 거야. 빛이 가장 어두운 곳부터 비추듯, 오늘 성탄의 기쁨이 가장 필요한 곳에 닿기를.',
    application: '오늘 주변에서 소외되거나 외로울 수 있는 사람에게 안부를 전해봐.',
    greeting_ko: '예수님의 탄생을 기뻐해요!',
    greeting_en: 'Merry Christmas! He is born for us.',
    image_prompt: 'rustic wooden manger with soft straw and warm candlelight glow in dark stable, star of light from above, no text no letters no watermark, 9:16 vertical, documentary DSLR realism',
  },
  {
    verse_id: 'v_431',
    // ── 연말 2027-12-31 ─────────────────────────────────────────────
    date: '2027-12-31',
    event_name: '연말',
    verse_short_ko: '우리에게 우리 날 계수함을 가르치사',
    verse_full_ko: '우리에게 우리 날 계수함을 가르치사 지혜의 마음을 얻게 하소서',
    reference: '시편 90:12',
    book: '시편',
    chapter: 90,
    verse_num: 12,
    mode: ['all'],
    theme: ['reflection', 'wisdom'],
    mood: ['serene', 'calm'],
    season: ['winter'],
    weather: ['any'],
    interpretation: '모세의 기도로, 하나님의 영원함 앞에 인간의 시간이 얼마나 짧은지 묵상한 시편이야. 날을 센다는 건 매 순간이 선물임을 기억하는 거야. 한 해의 마지막 날, 스쳐 지나간 하루하루를 감사함으로 돌아볼 수 있어.',
    application: '올 한 해 가장 감사한 순간 하나를 떠올리며, 하나님께 마음속으로 감사를 전해봐.',
    greeting_ko: '한 해의 마지막 날이에요.',
    greeting_en: "Year's end — grateful for each day.",
    image_prompt: 'snow-covered pathway at dusk with last light of day on horizon and bare tree silhouettes, no text no letters no watermark, 9:16 vertical, documentary DSLR realism, twilight blue tone',
  },
];

// ─── Sheets 인증 및 API 클라이언트 ────────────────────────────────────────
async function getSheets() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const client = await auth.getClient();
  return google.sheets({ version: 'v4', auth: client });
}

// ─── 자체 검증 ────────────────────────────────────────────────────────────
function validate(items) {
  const issues = [];
  items.forEach(v => {
    const id = v.verse_id;
    if (v.verse_short_ko.length < 10 || v.verse_short_ko.length > 50)
      issues.push(`${id}: verse_short_ko 글자수 이상 (${v.verse_short_ko.length}자)`);
    if (v.verse_full_ko.length < 20 || v.verse_full_ko.length > 200)
      issues.push(`${id}: verse_full_ko 글자수 이상 (${v.verse_full_ko.length}자)`);
    if (v.interpretation.length < 80 || v.interpretation.length > 200)
      issues.push(`${id}: interpretation 글자수 이상 (${v.interpretation.length}자)`);
    if (v.application.length < 30 || v.application.length > 100)
      issues.push(`${id}: application 글자수 이상 (${v.application.length}자)`);
    if (v.greeting_ko.length < 10 || v.greeting_ko.length > 20)
      issues.push(`${id}: greeting_ko 글자수 이상 (${v.greeting_ko.length}자)`);
    if (v.greeting_en.length < 15 || v.greeting_en.length > 35)
      issues.push(`${id}: greeting_en 글자수 이상 (${v.greeting_en.length}자)`);
    // 금지 어투 체크
    ['해야 합니다', '하십시오', '반드시', '명심', '해야 한다'].forEach(bad => {
      if (v.interpretation.includes(bad) || v.application.includes(bad))
        issues.push(`${id}: 금지 어투 "${bad}" 포함`);
    });
    // 원어 표기 금지
    ['히브리어', '헬라어', '그리스어'].forEach(bad => {
      if (v.interpretation.includes(bad))
        issues.push(`${id}: 원어 표기 금지 단어 포함: ${bad}`);
    });
  });
  return issues;
}

// ─── VERSES 탭 추가 ────────────────────────────────────────────────────────
async function appendToVerses(sheets, items) {
  // 헤더 순서: A:verse_id B:verse_short_ko C:verse_full_ko D:reference E:book
  // F:chapter G:verse H:mode I:theme J:mood K:season L:weather
  // M:interpretation N:application O:curated P:status Q:notes
  const rows = items.map(v => [
    v.verse_id,
    v.verse_short_ko,
    v.verse_full_ko,
    v.reference,
    v.book,
    v.chapter,
    v.verse_num,
    v.mode.join(','),
    v.theme.join(','),
    v.mood.join(','),
    v.season.join(','),
    v.weather.join(','),
    v.interpretation,
    v.application,
    'TRUE',    // curated
    'active',  // status
    `절기:${v.event_name}`, // notes
  ]);

  if (DRY_RUN) {
    console.log('\n[DRY-RUN] VERSES 탭 추가 예정 행:');
    rows.forEach(r => console.log(JSON.stringify(r.slice(0, 5)), '...'));
    return;
  }

  await sheets.spreadsheets.values.append({
    spreadsheetId: SHEET_ID,
    range: 'VERSES!A:Q',
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });
  console.log(`✓ VERSES 탭에 ${rows.length}행 추가 완료`);
}

// ─── DAILY_CARDS 탭 추가 ──────────────────────────────────────────────────
// 실제 헤더: date | event_name | verse_id | image_id | greeting_ko | greeting_en | all_zones | active | notes
async function appendToDailyCards(sheets, items) {
  const rows = items.map(v => [
    v.date,
    v.event_name,
    v.verse_id,
    '',         // image_id (추후 이미지 생성 후 채울 것)
    v.greeting_ko,
    v.greeting_en,
    'TRUE',     // all_zones
    'TRUE',     // active
    `image_prompt: ${v.image_prompt}`, // notes에 image_prompt 보관
  ]);

  if (DRY_RUN) {
    console.log('\n[DRY-RUN] DAILY_CARDS 탭 추가 예정 행:');
    rows.forEach(r => console.log(JSON.stringify(r)));
    return;
  }

  await sheets.spreadsheets.values.append({
    spreadsheetId: SHEET_ID,
    range: 'DAILY_CARDS!A:I',
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });
  console.log(`✓ DAILY_CARDS 탭에 ${rows.length}행 추가 완료`);
}

// ─── 메인 ─────────────────────────────────────────────────────────────────
async function main() {
  console.log(`=== 2027년 절기 콘텐츠 업로드 ${DRY_RUN ? '[DRY-RUN]' : '[실제 업로드]'} ===`);
  console.log(`대상: ${FESTIVAL_VERSES.length}개 절기`);

  // 1. 검증
  const issues = validate(FESTIVAL_VERSES);
  if (issues.length > 0) {
    console.error('\n[검증 실패] 아래 이슈를 수정 후 재실행하세요:');
    issues.forEach(i => console.error(' -', i));
    process.exit(1);
  }
  console.log('✓ 자체 검증 통과');

  // 2. 글자수 요약 출력
  console.log('\n[글자수 요약]');
  FESTIVAL_VERSES.forEach(v => {
    console.log(
      `${v.verse_id} ${v.event_name.padEnd(10)}` +
      ` short:${v.verse_short_ko.length}자` +
      ` full:${v.verse_full_ko.length}자` +
      ` interp:${v.interpretation.length}자` +
      ` app:${v.application.length}자` +
      ` grko:${v.greeting_ko.length}자` +
      `gren:${v.greeting_en.length}자`
    );
  });

  if (DRY_RUN) {
    console.log('\n[DRY-RUN] 실제 업로드는 --dry-run 없이 실행하세요.');
    appendToVerses(null, FESTIVAL_VERSES);
    appendToDailyCards(null, FESTIVAL_VERSES);
    return;
  }

  // 3. 업로드
  const sheets = await getSheets();
  await appendToVerses(sheets, FESTIVAL_VERSES);
  await appendToDailyCards(sheets, FESTIVAL_VERSES);

  console.log('\n=== 완료 ===');
  console.log('- VERSES 탭: v_420~v_431 (12개)');
  console.log('- DAILY_CARDS 탭: 2027년 절기 12개');
  console.log('- image_id는 notes 컬럼 image_prompt 기반으로 추후 이미지 생성 후 채워주세요.');
}

main().catch(e => { console.error('오류:', e.message); process.exit(1); });
