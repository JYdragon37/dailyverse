/**
 * setup_content_guide.js
 * 콘텐츠 생성 규칙 마스터 테이블을
 * Google Sheets(WRITING_GUIDE, ZONE_GUIDE 탭)와
 * Firestore(writing_guide, zone_guide 컬렉션)에 동기화
 *
 * v9.0 — 2026-04-14
 * - ZONE_GUIDE 탭/컬렉션 추가 (8개 Zone × 유저상황·감정·말씀역할)
 * - CONTENT_RULES 글자수 수정 (interpretation: 102~154자, application: 49~73자)
 * - LLM 프롬프트 업데이트 (Zone 컨텍스트 반영)
 */

const { google } = require('googleapis');
const admin = require('firebase-admin');
const key = require('./serviceAccountKey.json');

// Firebase 초기화
if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(key) });
}
const db = admin.firestore();

const sheetsAuth = new google.auth.GoogleAuth({
  credentials: key,
  scopes: ['https://www.googleapis.com/auth/spreadsheets'],
});

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';

// ─────────────────────────────────────────────
// 1. 콘텐츠 필드 규칙 (WRITING_GUIDE)
// ─────────────────────────────────────────────
const CONTENT_RULES = [
  {
    id: 'verse_full_ko',
    order: 1,
    field: 'verse_full_ko',
    tab: 'VERSES',
    length: '40~120자',
    display: '홈 메인 카드, 알람 Stage 2, 저장 썸네일',
    rules: [
      '⚠️ 앵커 — 항상 가장 먼저 작성. 나머지 필드는 이것에서 파생',
      '현대 한국어 자연스러운 의역 (고어체·직역·경어 금지)',
      '2문장 이상이면 쉼표(,) 또는 \\n으로 호흡 구분',
      '구두점 철저히 (마침표·쉼표·띄어쓰기 준수)',
      '역방향 작성 금지: short/interpretation 먼저 쓰고 full 채우기 금지',
    ],
    llm_prompt: `아래 구절을 현대 한국어로 의역해줘. 40~120자.
두 문장 이상이면 쉼표(,) 또는 \\n으로 호흡 구분. 마침표·쉼표 빠짐없이.
고어체("~지어다", "~하시니라") 금지. 경어("~합니다") 금지. 설명체("~말씀하셨습니다") 금지.

좋은 예: "두려워하지 말라, 내가 너와 함께 함이라.\\n내가 너를 굳세게 하리라."
나쁜 예: "두려워하지 말지어다. 주께서 함께 계시니라." → 고어체`,
    write_order: 1,
    auto_sync: false,
  },
  {
    id: 'verse_short_ko',
    order: 2,
    field: 'verse_short_ko',
    tab: 'VERSES',
    length: '20~60자',
    display: '알람 Stage 0·1, 알람 한마디, 묵상 카드',
    rules: [
      'verse_full_ko 확정 후 작성 — full의 핵심 문장 1개를 그대로 선택',
      'verse_full_ko가 60자 이하이면 그대로 사용',
      '복수 문장이고 60자 초과이면 핵심 1문장만 그대로 (축약·합성·재창작 금지)',
      '마침표(.), 쉼표(,) 철저히 준수',
    ],
    llm_prompt: `위 verse_full_ko에서 가장 임팩트 있는 핵심 문장 1개를 그대로 선택해줘. 20~60자.
합성·축약·재창작 금지 — 원문에 있는 문장을 그대로.
verse_full_ko가 60자 이하이면 그대로 사용.

좋은 예 (full에서 추출): "두려워하지 말라, 내가 너와 함께 함이라."
나쁜 예: "내가 항상 너 곁에 있을 거야." → 재창작`,
    write_order: 2,
    auto_sync: false,
  },
  {
    id: 'interpretation',
    order: 3,
    field: 'interpretation',
    tab: 'VERSES',
    length: '102~154자 (기준 128자)',
    display: '홈 바텀시트, 저장 상세, 묵상 S2 해석',
    rules: [
      '3단계 구조: ① 저자·화자 처한 구체적 상황 → ② 구절 핵심 의미 → ③ 오늘 유저 연결',
      '⚠️ 원어(히브리어·헬라어) 단어 직접 표기 절대 금지 — 뜻은 한국어로만',
      '2~3문장마다 \\n 삽입',
      '말투 허용: ~야, ~이야, ~거야, ~있어, ~계셔',
      '말투 금지: ~이다, ~합니다, ~입니다, 설교조, 신학 용어',
    ],
    llm_prompt: `아래 구절의 interpretation을 작성해줘. 102~154자. 2~3문장마다 \\n 삽입.

구조 (반드시 이 순서):
① 저자·화자가 처한 구체적 상황 1문장 ("~가 ~한 상황에서 쓴 말씀이야" 형태)
② 이 구절의 핵심 의미 1~2문장 (히브리어·헬라어 단어 직접 표기 절대 금지. 뜻은 한국어로만 풀어서)
③ 지금 유저에게 연결되는 말 1문장 ("지금 네가...", "이 말씀은 오늘 너에게..." 형태)

말투: ~야, ~이야, ~거야, ~있어 / 금지: ~이다, ~합니다, 설교조

좋은 예:
"이사야가 바벨론 포로로 끌려가 절망에 빠진 이스라엘 백성에게 전한 말씀이야.\\n'두려워하지 말라'는 상황이 바뀌기 전에 먼저 임재를 선언하는 거야. 조건이 없어.\\n지금 네 앞의 두려움보다 그분이 크다는 걸 기억해."

나쁜 예:
"히브리어 '야레'는 두려움을 뜻해..." → 원어 단어 직접 표기
"이 말씀은 우리에게 큰 위로를 줍니다." → 설교조·경어`,
    write_order: 3,
    auto_sync: true,
    auto_sync_note: 'contemplation_interpretation ← 수식 자동 참조',
  },
  {
    id: 'application',
    order: 4,
    field: 'application',
    tab: 'VERSES',
    length: '49~73자 (기준 61자)',
    display: '홈 바텀시트, 저장 상세, 묵상 S3 적용',
    rules: [
      '오늘 바로 실천 가능한 구체적 행동 1가지',
      '⚠️ Zone 시간대와 유저 상황이 문장 안에 자연스럽게 녹아 있어야 함 (ZONE_GUIDE 탭 참고)',
      '말투: ~해봐, ~기억해, ~말해봐, ~생각해봐, ~내려놔',
      '금지: 반드시, 꼭 ~해야, ~하십시오, ~해야 한다',
      '금지: 해당 Zone 시간대와 맞지 않는 상황 언급',
    ],
    llm_prompt: `이 말씀을 아래 Zone 상황의 유저에게 맞는 오늘의 적용 1가지를 49~73자로 작성해줘.

Zone: {zone_id}
유저 상황: {ZONE_GUIDE 탭 → 해당 Zone의 "유저 상황" 항목}
application 컨텍스트: {ZONE_GUIDE 탭 → "application 컨텍스트" 항목}

⚠️ 유저 상황·시간대·장소감이 문장 배경에 느껴져야 함.
말투: ~해봐, ~기억해, ~말해봐 / 금지: 반드시, 꼭, ~해야 한다

좋은 예 (rise_ignite): "알람 끄고 30초만 눈 감아봐. 오늘도 혼자가 아님을 기억하며 시작해."
좋은 예 (wind_down): "알람을 맞추며 기억해. 내일 무슨 일이 생겨도 그분 손 안에 있어. 이제 편히 자."
나쁜 예: "저녁에 오늘 하루를 돌아보며 감사해봐." → rise_ignite에 저녁 언급`,
    write_order: 4,
    auto_sync: true,
    auto_sync_note: 'contemplation_appliance ← 수식 자동 참조',
  },
  {
    id: 'question',
    order: 5,
    field: 'question',
    tab: 'VERSES',
    length: '40~80자',
    display: '묵상 S3 질문 (앞에 닉네임 자동 합성)',
    rules: [
      '말씀 핵심을 일상 삶과 연결하는 질문 1개',
      '닉네임 직접 포함 금지 — 앱이 "{name}님, " 자동 합성',
      '형태: 선택형("A와 B 중") / 회상형("~했던 경험") / 상상형("~라면") 중 1가지',
      '종교 어조 금지, 일상 언어. 신앙 유무와 무관하게 공감 가능해야 함',
      '금지: "기도했나요?", "말씀을 읽었나요?", "~해야 합니까?", 닉네임 직접 포함',
    ],
    llm_prompt: `아래 말씀의 핵심을 일상 삶에 연결하는 질문 1개를 40~80자로 작성해줘.

verse_full_ko: {verse_full_ko}
interpretation 핵심: {interpretation에서 핵심 메시지 1줄}

형태 (3가지 중 1가지):
- 선택형: "A와 B 중 어느 쪽에 더 가까운가요?"
- 회상형: "최근 ~했던 경험이 있나요?"
- 상상형: "만약 ~라면 어떨까요?"

닉네임 없이 (앱이 "{name}님, " 자동 합성). 종교 어조 금지. 신앙 유무와 무관하게 공감 가능해야 함.

좋은 예:
"요즘 가장 두렵게 느껴지는 것은 무엇인가요?" (회상형)
"두려움보다 더 크다고 느껴지는 것이 있나요?" (선택형)

나쁜 예:
"오늘 하나님께 기도하셨나요?" → 신앙 행위 점검
"두려움이 찾아올 때 어떻게 해야 합니까?" → 경어·강요`,
    write_order: 5,
    auto_sync: false,
  },
  {
    id: 'alarm_top_ko',
    order: 6,
    field: 'alarm_top_ko',
    tab: 'ALARM_VERSES',
    length: '15~35자',
    display: '알람 탭 상단 오늘의 말씀 카드',
    rules: [
      'verse_short_ko에서 더 압축한 핵심 1문장',
      'verse_short_ko가 35자 이하이면 생략 가능 (verse_short_ko로 대체 표시됨)',
      '알람 확인하는 순간 눈에 꽂히는 강도 — 짧고 강렬하게',
    ],
    llm_prompt: `verse_short_ko를 15~35자로 더 압축한 핵심 한 문장을 써줘.
알람을 맞추거나 끄는 순간 눈에 꽂히는 강도로.
verse_short_ko가 35자 이하이면 그대로 사용하고 null 표기.

좋은 예: "두려워하지 말라, 내가 함께해."
나쁜 예: "하나님께서는 항상 우리와 함께하십니다." → 경어·길이 초과`,
    write_order: 6,
    auto_sync: false,
  },
  {
    id: 'greeting_text',
    order: 7,
    field: 'text',
    tab: 'greeting',
    length: 'ko: ~15자 / en: ~30자',
    display: '홈화면·알람 Zone별 인사말',
    rules: [
      'Zone 유저 상황·감성에 맞는 따뜻한 한 문장 (ZONE_GUIDE 탭 참고 필수)',
      '설교조 금지, 동반자 언어 — "~예요", "~해요" 어투',
      '유저가 그 순간 무엇을 하고 있는지 느껴지는 문장',
    ],
    llm_prompt: `아래 Zone의 유저 상황에 맞는 짧은 인사말 N개를 작성해줘.

Zone: {zone_id}
시간대: {시간대}
유저 상황: {ZONE_GUIDE 탭 → "유저 상황" 항목}

한국어 15자 이내 / 영어 30자 이내.
설교조 금지. 동반자 언어("~예요", "~해요" 어투). 유저 상황이 느껴져야 함.

좋은 예 (rise_ignite): "좋은 아침이에요, 오늘도 파이팅!" / "Good Morning, let's go!"
나쁜 예: "하나님의 은혜로 아침을 시작하십시오." → 설교조·경어`,
    write_order: null,
    auto_sync: false,
  },
];

// ─────────────────────────────────────────────
// 2. Zone 기준표 (ZONE_GUIDE) — v9.0 신규
// ─────────────────────────────────────────────
const ZONE_GUIDE = [
  {
    id: 'deep_dark',
    order: 1,
    emoji: '🌑',
    name: 'Deep Dark',
    time: '00~03',
    keyword: '고요·침묵',
    user_situation: '잠이 안 와 뒤척이거나, 걱정·불안으로 혼자 깨어 있음. 야간 근무 중이기도 함. 세상이 고요하고 유독 혼자인 느낌',
    emotion: '외로움 · 불안 · 조용한 갈망',
    verse_role: '조용한 동반자. "너 혼자가 아니야"라는 안심. 설교 아닌 나직한 위로',
    application_context: '지금 뒤척이고 있는 그 순간, 깊은 밤의 고요 속',
    application_good: '지금 뒤척이고 있다면, 숨 한 번 천천히 내쉬어봐. 이 밤도 혼자가 아니야.',
    application_bad: '오늘 하루 감사한 마음으로 시작해봐. (새벽에 아침 언급)',
    themes: ['stillness', 'surrender', 'grace', 'faith'],
    moods: ['serene', 'calm'],
    tone_preferred: 'dark',
  },
  {
    id: 'first_light',
    order: 2,
    emoji: '🌒',
    name: 'First Light',
    time: '03~06',
    keyword: '여명·준비',
    user_situation: '이른 새벽 기도·묵상을 위해 일어남. 아직 가족도 깨지 않은 고요함 속. 하루가 시작되기 전 마지막 정적',
    emotion: '고요한 기대 · 영적 준비 · 하루 전의 정적',
    verse_role: '하루를 시작하기 전 영적 호흡. 새 날에 대한 조용한 기대감 부여',
    application_context: '새벽의 고요함, 하루가 시작되기 전의 정적 속',
    application_good: '이 새벽의 고요함 속에서 오늘 하루를 먼저 하나님께 드려봐.',
    application_bad: '퇴근 후 오늘 하루를 돌아보며 감사해봐. (저녁 상황 언급)',
    themes: ['faith', 'renewal', 'stillness', 'hope'],
    moods: ['serene', 'calm'],
    tone_preferred: 'dark',
  },
  {
    id: 'rise_ignite',
    order: 3,
    emoji: '🌅',
    name: 'Rise & Ignite',
    time: '06~09',
    keyword: '각성·시작',
    user_situation: '알람이 울려 잠에서 깨는 순간. 이불 속에서 폰을 보고 있음. 오늘 해야 할 것들이 머릿속에 스침',
    emotion: '나른함 50% + 부담 30% + 작은 설렘 20%',
    verse_role: '가볍게 밀어주는 격려. 무겁지 않고 "오늘도 할 수 있어"라는 짧은 에너지',
    application_context: '알람 끄고 30초, 이불 속에서 폰 보는 순간',
    application_good: '알람 끄고 30초만 눈 감아봐. 오늘도 혼자가 아님을 기억하며 시작해.',
    application_bad: '저녁에 오늘 하루를 돌아보며 감사의 기도를 드려봐. (저녁 상황 언급)',
    themes: ['hope', 'courage', 'strength', 'renewal'],
    moods: ['bright', 'dramatic'],
    tone_preferred: 'bright',
  },
  {
    id: 'peak_mode',
    order: 4,
    emoji: '⚡',
    name: 'Peak Mode',
    time: '09~12',
    keyword: '집중·성과',
    user_situation: '업무·공부에 집중하는 시간. 회의·과제·프로젝트 한창. 성과 압박이 있음',
    emotion: '집중 · 스트레스 · 책임감',
    verse_role: '지혜와 용기. 지금 하는 일에 의미를 부여하고 흔들리지 않게',
    application_context: '업무·공부 집중 시간, 성과 압박이 있는 순간',
    application_good: '막히는 일이 있다면 잠깐 멈춰봐. 지혜는 조급함이 아닌 고요함에서 나와.',
    application_bad: '알람이 울리면 감사하며 하루를 시작해봐. (아침 상황 언급)',
    themes: ['wisdom', 'focus', 'courage', 'strength'],
    moods: ['bright', 'dramatic'],
    tone_preferred: 'bright',
  },
  {
    id: 'recharge',
    order: 5,
    emoji: '☀️',
    name: 'Recharge',
    time: '12~15',
    keyword: '휴식·재충전',
    user_situation: '점심 식사 후 잠깐 쉬는 시간. 스마트폰 보거나 짧은 산책 중. 오후가 살짝 두렵기도 함',
    emotion: '나른함 · 작은 허탈감 · 재충전 필요',
    verse_role: '잠깐의 쉼에서 내면 충전. 서두르지 않아도 된다는 안도감',
    application_context: '점심 후 잠깐 쉬는 시간, 폰 보거나 잠깐 산책하는 순간',
    application_good: '지금 이 쉬는 시간, 억지로 생산적이려 하지 않아도 돼. 그냥 쉬어.',
    application_bad: '매일 아침 새로운 마음으로 일어나봐. (아침 상황 언급)',
    themes: ['rest', 'patience', 'gratitude', 'comfort'],
    moods: ['calm', 'warm'],
    tone_preferred: 'mid',
  },
  {
    id: 'second_wind',
    order: 6,
    emoji: '🌤',
    name: 'Second Wind',
    time: '15~18',
    keyword: '오후·재점화',
    user_situation: '오후 슬럼프. 하루의 후반부를 마무리해야 하는 타이밍. "조금만 더"가 필요한 순간',
    emotion: '피로감 · 마무리 의지 · 희미한 집중',
    verse_role: '후반전을 뛸 힘 재점화. 포기하지 않고 마무리하게',
    application_context: '오후 슬럼프, 하루 마무리를 앞둔 순간',
    application_good: '오늘 오후, 한 가지만 더 해보자. 그것으로 충분해.',
    application_bad: '아침에 일어나며 감사의 말씀을 읽어봐. (아침 상황 언급)',
    themes: ['strength', 'focus', 'patience', 'wisdom'],
    moods: ['warm', 'calm'],
    tone_preferred: 'mid',
  },
  {
    id: 'golden_hour',
    order: 7,
    emoji: '🌇',
    name: 'Golden Hour',
    time: '18~21',
    keyword: '저녁·수확',
    user_situation: '퇴근·귀가 중이거나 저녁을 마친 상태. 하루를 자연스럽게 돌아보는 시간',
    emotion: '수고함 · 감사 · 때로는 아쉬움이나 허무',
    verse_role: '오늘 하루에 의미를 부여하는 감사. 수고했음을 인정해주는 따뜻함',
    application_context: '퇴근·귀가 중, 또는 저녁 식사를 마친 후',
    application_good: '오늘 하루 수고했어. 잘 한 것 하나를 떠올리며 감사해봐.',
    application_bad: '알람을 맞추며 내일 아침을 기대해봐. (아침 알람 언급)',
    themes: ['gratitude', 'reflection', 'comfort', 'peace'],
    moods: ['warm', 'serene'],
    tone_preferred: 'mid',
  },
  {
    id: 'wind_down',
    order: 8,
    emoji: '🌙',
    name: 'Wind Down',
    time: '21~24',
    keyword: '마무리·안식',
    user_situation: '씻고 잠자리에 들기 전. 마지막 폰 스크롤 또는 취침 알람 맞추는 시간',
    emotion: '피로 · 평안 욕구 · 내일에 대한 은은한 기대 또는 불안',
    verse_role: '오늘의 짐을 내려놓게 하는 고요한 위로. 편히 쉬어도 된다는 허락',
    application_context: '취침 전 마지막 폰 확인, 잠자리 들기 직전',
    application_good: '알람을 맞추며 기억해. 내일 무슨 일이 생겨도 그분 손 안에 있어. 이제 편히 자.',
    application_bad: '오늘 아침 알람을 끄며 감사해봐. (아침 상황 언급)',
    themes: ['peace', 'rest', 'comfort', 'stillness'],
    moods: ['cozy', 'calm'],
    tone_preferred: 'dark',
  },
];

// ─────────────────────────────────────────────
// Sheets 헬퍼: 탭 확보
// ─────────────────────────────────────────────
async function ensureTab(sheets, tabName, meta) {
  const exists = meta.data.sheets.some(s => s.properties.title === tabName);
  if (!exists) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: SPREADSHEET_ID,
      requestBody: {
        requests: [{
          addSheet: {
            properties: { title: tabName, gridProperties: { rowCount: 30, columnCount: 12 } },
          },
        }],
      },
    });
    console.log(`✅ ${tabName} 탭 생성`);
  }
}

async function getSheetId(sheets, tabName) {
  const meta = await sheets.spreadsheets.get({ spreadsheetId: SPREADSHEET_ID });
  return meta.data.sheets.find(s => s.properties.title === tabName)?.properties.sheetId;
}

async function applyHeaderStyle(sheets, sheetId, colCount) {
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId: SPREADSHEET_ID,
    requestBody: {
      requests: [
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: colCount },
            cell: {
              userEnteredFormat: {
                backgroundColor: { red: 0.13, green: 0.13, blue: 0.2 },
                textFormat: { bold: true, foregroundColor: { red: 1, green: 1, blue: 1 } },
              },
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat)',
          },
        },
        {
          autoResizeDimensions: {
            dimensions: { sheetId, dimension: 'COLUMNS', startIndex: 0, endIndex: colCount },
          },
        },
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 1, endRowIndex: 30, startColumnIndex: 0, endColumnIndex: colCount },
            cell: {
              userEnteredFormat: { wrapStrategy: 'WRAP', verticalAlignment: 'TOP' },
            },
            fields: 'userEnteredFormat(wrapStrategy,verticalAlignment)',
          },
        },
      ],
    },
  });
}

// ─────────────────────────────────────────────
// A. WRITING_GUIDE 탭
// ─────────────────────────────────────────────
async function setupWritingGuideSheet(sheets, meta) {
  const TAB = 'WRITING_GUIDE';
  await ensureTab(sheets, TAB, meta);

  const header = ['#', '필드', '탭', '길이', '노출 위치', '생성 규칙', 'LLM 프롬프트', '자동처리'];
  const rows = CONTENT_RULES.map(r => [
    r.order,
    r.field,
    r.tab,
    r.length,
    r.display,
    r.rules.join('\n'),
    r.llm_prompt,
    r.auto_sync ? (r.auto_sync_note || '수식 자동 참조') : '-',
  ]);

  await sheets.spreadsheets.values.update({
    spreadsheetId: SPREADSHEET_ID,
    range: `${TAB}!A1:H${rows.length + 1}`,
    valueInputOption: 'RAW',
    requestBody: { values: [header, ...rows] },
  });

  const sheetId = await getSheetId(sheets, TAB);
  if (sheetId !== undefined) await applyHeaderStyle(sheets, sheetId, 8);
  console.log(`✅ Sheets ${TAB} — ${rows.length}개 항목 저장 완료`);
}

// ─────────────────────────────────────────────
// B. ZONE_GUIDE 탭 (v9.0 신규)
// ─────────────────────────────────────────────
async function setupZoneGuideSheet(sheets, meta) {
  const TAB = 'ZONE_GUIDE';
  await ensureTab(sheets, TAB, meta);

  const header = [
    '#', 'Zone', '시간대', '키워드',
    '유저 상황', '감정 상태', '말씀 역할',
    'application 컨텍스트', '좋은 예', '나쁜 예 (시간대 무시)',
    'theme 풀', 'mood 풀',
  ];
  const rows = ZONE_GUIDE.map(z => [
    z.order,
    `${z.emoji} ${z.name} (${z.id})`,
    z.time,
    z.keyword,
    z.user_situation,
    z.emotion,
    z.verse_role,
    z.application_context,
    z.application_good,
    z.application_bad,
    z.themes.join(', '),
    z.moods.join(', '),
  ]);

  await sheets.spreadsheets.values.update({
    spreadsheetId: SPREADSHEET_ID,
    range: `${TAB}!A1:L${rows.length + 1}`,
    valueInputOption: 'RAW',
    requestBody: { values: [header, ...rows] },
  });

  const sheetId = await getSheetId(sheets, TAB);
  if (sheetId !== undefined) await applyHeaderStyle(sheets, sheetId, 12);
  console.log(`✅ Sheets ${TAB} — ${rows.length}개 Zone 저장 완료`);
}

// ─────────────────────────────────────────────
// C. Firestore writing_guide 컬렉션
// ─────────────────────────────────────────────
async function setupWritingGuideFirestore() {
  const batch = db.batch();
  CONTENT_RULES.forEach(rule => {
    const ref = db.collection('writing_guide').doc(rule.id);
    batch.set(ref, {
      order:            rule.order,
      field:            rule.field,
      tab:              rule.tab,
      length:           rule.length,
      display_location: rule.display,
      generation_rules: rule.rules,
      llm_prompt:       rule.llm_prompt,
      write_order:      rule.write_order,
      auto_sync:        rule.auto_sync,
      auto_sync_note:   rule.auto_sync_note || null,
      version:          'v9.0',
      updated_at:       admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
  console.log(`✅ Firestore writing_guide — ${CONTENT_RULES.length}개 문서 저장 완료`);
}

// ─────────────────────────────────────────────
// D. Firestore zone_guide 컬렉션 (v9.0 신규)
// ─────────────────────────────────────────────
async function setupZoneGuideFirestore() {
  const batch = db.batch();
  ZONE_GUIDE.forEach(zone => {
    const ref = db.collection('zone_guide').doc(zone.id);
    batch.set(ref, {
      order:               zone.order,
      emoji:               zone.emoji,
      name:                zone.name,
      time:                zone.time,
      keyword:             zone.keyword,
      user_situation:      zone.user_situation,
      emotion:             zone.emotion,
      verse_role:          zone.verse_role,
      application_context: zone.application_context,
      application_good:    zone.application_good,
      application_bad:     zone.application_bad,
      themes:              zone.themes,
      moods:               zone.moods,
      tone_preferred:      zone.tone_preferred,
      version:             'v9.0',
      updated_at:          admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
  console.log(`✅ Firestore zone_guide — ${ZONE_GUIDE.length}개 Zone 저장 완료`);
}

// ─────────────────────────────────────────────
// 실행
// ─────────────────────────────────────────────
async function main() {
  console.log('콘텐츠 가이드 동기화 시작... (v9.0)\n');

  const client = await sheetsAuth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });
  const meta = await sheets.spreadsheets.get({ spreadsheetId: SPREADSHEET_ID });

  await Promise.all([
    setupWritingGuideSheet(sheets, meta),
    setupZoneGuideSheet(sheets, meta),
    setupWritingGuideFirestore(),
    setupZoneGuideFirestore(),
  ]);

  console.log('\n✅ 완료');
  console.log('  Sheets: WRITING_GUIDE 탭, ZONE_GUIDE 탭');
  console.log('  Firestore: writing_guide 컬렉션, zone_guide 컬렉션');
}

main().catch(console.error);
