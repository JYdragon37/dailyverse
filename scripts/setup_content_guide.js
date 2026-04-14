/**
 * setup_content_guide.js
 * 콘텐츠 생성 규칙 마스터 테이블을
 * Google Sheets(WRITING_GUIDE 탭)와 Firestore(writing_guide 컬렉션)에 동기화
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
const TAB_NAME = 'WRITING_GUIDE';

// ─────────────────────────────────────────────
// 마스터 데이터
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
      '항상 먼저 작성 (verse_short_ko의 원본)',
      '현대 한국어 자연스러운 의역',
      '2문장 이상이면 \\n으로 호흡 구분',
      '구두점 철저히 (마침표/쉼표 준수)',
    ],
    llm_prompt: '[구절]을 현대 한국어로 의역해줘. 40~120자. 두 문장 이상이면 \\n으로 호흡 구분. 성경 인용체 또는 현대어 의역.',
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
      'verse_full_ko에서 핵심 문장 1개 추출 (합성·축약 금지)',
      'verse_full_ko가 60자 이하면 그대로 사용',
      '60자 초과 복수 문장이면 핵심 1문장만 추출',
      '줄임표(…) 금지',
    ],
    llm_prompt: '위 verse_full_ko에서 가장 임팩트 있는 핵심 문장 1개를 그대로 추출해줘. 20~60자. 축약·합성 금지.',
    write_order: 2,
    auto_sync: false,
  },
  {
    id: 'interpretation',
    order: 3,
    field: 'interpretation',
    tab: 'VERSES',
    length: '100~200자',
    display: '홈 바텀시트, 저장 상세, 묵상 S2 해석',
    rules: [
      '3단계 구조: ① 배경/맥락 → ② 핵심 의미 → ③ 오늘날 연결',
      '원어(히브리어·헬라어) 단어 직접 표기 절대 금지 — 한국어로만 풀어서',
      '어투: ~이야, ~거야, ~있어',
      '금지: ~이다, ~합니다, 설교조',
      'Zone 시간대 감성과 자연스럽게 연결',
    ],
    llm_prompt: '①[배경/상황 1문장] ②[핵심 의미 1~2문장, 원어 직접 표기 금지] ③[오늘 삶과 연결 1문장]. 총 100~200자. ~이야/~거야 어투.',
    write_order: 3,
    auto_sync: true,
    auto_sync_note: 'contemplation_interpretation ← 수식 자동 참조',
  },
  {
    id: 'application',
    order: 4,
    field: 'application',
    tab: 'VERSES',
    length: '50~100자',
    display: '홈 바텀시트, 저장 상세, 묵상 S3 적용',
    rules: [
      '오늘 바로 실천 가능한 구체적 행동 1가지',
      '어투: ~해봐, ~생각해봐, ~내려놔',
      'Zone 시간대 상황 반영 (아침/낮/저녁/밤)',
      '금지: 반드시, 꼭 ~해야, ~하십시오, ~해야 한다',
    ],
    llm_prompt: '이 말씀을 오늘 [Zone 시간대]에 실천하는 행동 1가지를 50~100자로. ~해봐/~생각해봐 어투. "반드시"/"꼭" 사용 금지.',
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
      '닉네임 직접 포함 금지 (앱이 "{name}님, " 자동 합성)',
      '종교 어조 금지, 일상 언어 사용',
      '선택형·회상형·상상형 중 1가지',
    ],
    llm_prompt: '이 말씀의 핵심을 일상 삶에 연결하는 질문 1개. 40~80자. 닉네임 없이. 종교 어조 금지, 일상 언어.',
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
      '짧고 강렬한 핵심 한 문장',
      '정서: 기대·소망·준비·새날·변화',
      '금지: 암울/고난 중심 구절, 심판 강조',
      'verse_short_ko가 35자 이하면 생략 가능',
    ],
    llm_prompt: '알람을 맞추는 순간 마음에 꽂히는 짧고 강한 한 문장. 15~35자. 기대·소망·준비 정서. 암울한 구절 금지.',
    write_order: 1,
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
      'Zone 감성(시간대·테마·톤)에 맞는 따뜻한 한 문장',
      '설교조 금지, 동반자 언어',
      'deep_dark(00-03시): 잠 못 드는 밤 위로',
      'rise_ignite(06-09시): 활기찬 아침 점화',
      'wind_down(21-24시): 포근한 하루 마무리',
    ],
    llm_prompt: '[Zone명]([시간대]) 감성에 맞는 짧은 인사말 N개. 한국어 15자 이내 / 영어 30자 이내. 설교조 금지, 따뜻한 동반자 언어.',
    write_order: null,
    auto_sync: false,
  },
];

// ─────────────────────────────────────────────
// 1. Google Sheets — WRITING_GUIDE 탭
// ─────────────────────────────────────────────
async function setupSheets() {
  const client = await sheetsAuth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  // 탭 존재 여부 확인
  const meta = await sheets.spreadsheets.get({ spreadsheetId: SPREADSHEET_ID });
  const exists = meta.data.sheets.some(s => s.properties.title === TAB_NAME);

  if (!exists) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: SPREADSHEET_ID,
      requestBody: { requests: [{
        addSheet: { properties: { title: TAB_NAME, gridProperties: { rowCount: 20, columnCount: 8 } } }
      }]},
    });
    console.log(`✅ ${TAB_NAME} 탭 생성`);
  }

  // 헤더
  const header = ['#', '필드', '탭', '길이', '노출 위치', '생성 규칙', 'LLM 프롬프트', '자동처리'];

  // 데이터 행
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
    range: `${TAB_NAME}!A1:H${rows.length + 1}`,
    valueInputOption: 'RAW',
    requestBody: { values: [header, ...rows] },
  });

  // 헤더 볼드 + 배경색
  const sheetId = meta.data.sheets.find(s => s.properties.title === TAB_NAME)?.properties.sheetId
    || (await sheets.spreadsheets.get({ spreadsheetId: SPREADSHEET_ID }))
        .data.sheets.find(s => s.properties.title === TAB_NAME)?.properties.sheetId;

  if (sheetId !== undefined) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: SPREADSHEET_ID,
      requestBody: { requests: [
        // 헤더 볼드
        { repeatCell: {
          range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 8 },
          cell: { userEnteredFormat: {
            backgroundColor: { red: 0.2, green: 0.2, blue: 0.3 },
            textFormat: { bold: true, foregroundColor: { red: 1, green: 1, blue: 1 } },
          }},
          fields: 'userEnteredFormat(backgroundColor,textFormat)',
        }},
        // 열 너비 자동 조정
        { autoResizeDimensions: {
          dimensions: { sheetId, dimension: 'COLUMNS', startIndex: 0, endIndex: 8 }
        }},
        // 줄바꿈 허용
        { repeatCell: {
          range: { sheetId, startRowIndex: 1, endRowIndex: rows.length + 1, startColumnIndex: 0, endColumnIndex: 8 },
          cell: { userEnteredFormat: { wrapStrategy: 'WRAP', verticalAlignment: 'TOP' } },
          fields: 'userEnteredFormat(wrapStrategy,verticalAlignment)',
        }},
      ]},
    });
  }

  console.log(`✅ Sheets ${TAB_NAME} 탭 — ${rows.length}개 항목 저장 완료`);
}

// ─────────────────────────────────────────────
// 2. Firestore — writing_guide 컬렉션
// ─────────────────────────────────────────────
async function setupFirestore() {
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
      updated_at:       admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log(`✅ Firestore writing_guide — ${CONTENT_RULES.length}개 문서 저장 완료`);
}

// ─────────────────────────────────────────────
// 실행
// ─────────────────────────────────────────────
async function main() {
  console.log('콘텐츠 생성 가이드 동기화 시작...\n');
  await Promise.all([setupSheets(), setupFirestore()]);
  console.log('\n✅ 완료 — Sheets(WRITING_GUIDE) + Firestore(writing_guide)');
}

main().catch(console.error);
