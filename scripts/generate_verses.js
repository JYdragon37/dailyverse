require('dotenv').config();
/**
 * generate_verses.js — 신규 말씀 생성 및 VERSES 탭 추가 (v2.0)
 *
 * v2.0 개선 사항:
 *   - 모델: claude-sonnet-4-6 → claude-haiku-4-5-20251001 (5-10배 빠름)
 *   - 처리: 순차 1개씩 → 배치 5개 병렬 (60분 → 10분 이내)
 *   - ID: 사전 전체 채번 → 병렬 처리 시 verse_id 중복 완전 방지
 *   - 쓰기: append 개별 호출 → 배치 단위 일괄 write (API 호출 80% 절감)
 *
 * 사용법:
 *   node generate_verses.js              # 실제 생성
 *   node generate_verses.js --dry-run    # 미리보기만
 *   node generate_verses.js --batch 10  # 배치 크기 지정 (기본: 5)
 *
 * 데이터 쓰기 원칙:
 *   Google Sheets = Single Source of Truth (읽기/쓰기)
 *   Firestore = 읽기 전용 — 직접 쓰기 금지
 *   생성 후 반드시: node sync_verses.js (Firestore 동기화)
 */

const Anthropic = require('@anthropic-ai/sdk');
const { google } = require('googleapis');
const path = require('path');

const SHEET_ID   = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const KEY_FILE   = path.join(__dirname, 'serviceAccountKey.json');
const SHEET_TAB  = 'VERSES';
const BATCH_SIZE = parseInt(process.argv.find(a => a.startsWith('--batch='))?.split('=')[1] || '5', 10);
const isDryRun   = process.argv.includes('--dry-run');

// VERSES 탭 컬럼 순서 (기존 헤더 기준)
const COLUMN_ORDER = [
  'verse_id', 'verse_short_ko', 'verse_full_ko', 'reference',
  'book', 'chapter', 'verse', 'mode', 'theme', 'mood', 'season', 'weather',
  'interpretation', 'application', 'curated', 'status', 'notes',
  'usage_count', 'cooldown_days', 'last_shown', 'show_count',
  'alarm_top_ko', 'contemplation_ko', 'contemplation_reference',
  'contemplation_interpretation', 'contemplation_appliance', 'question',
];

// ─── Google Sheets 클라이언트 ──────────────────────────────────────────────

let _sheetsClient = null;
async function getSheetsClient() {
  if (_sheetsClient) return _sheetsClient;
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  _sheetsClient = google.sheets({ version: 'v4', auth });
  return _sheetsClient;
}

function docToRow(verseId, data) {
  return COLUMN_ORDER.map(col => {
    if (col === 'verse_id') return verseId;
    const val = data[col];
    if (val === undefined || val === null) return '';
    if (Array.isArray(val)) return val.join(', ');
    return String(val);
  });
}

/** 배치 단위 일괄 append (여러 행을 한 번의 API 호출로) */
async function appendBatchToSheets(rows) {
  const sheets = await getSheetsClient();
  const result = await sheets.spreadsheets.values.append({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_TAB}!A:AB`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });
  return result.data.updates?.updatedRange || '?';
}

// ─── Claude API ────────────────────────────────────────────────────────────

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) { console.error('ANTHROPIC_API_KEY 필요'); process.exit(1); }
const anthropic = new Anthropic({ apiKey });

// ─── Zone 컨텍스트 ─────────────────────────────────────────────────────────

const ZONE_CONTEXT = {
  deep_dark:   { time: '00:00-03:00', desc: '자정~새벽 3시. 잠 못 들고 불안·외로움 속에 깨어 있음', appCtx: '지금 뒤척이고 있는 이 밤, 깊은 어둠 속에서' },
  first_light: { time: '03:00-06:00', desc: '새벽 3~6시. 이른 기도·묵상을 위해 일어남. 하루 전의 고요', appCtx: '새벽의 고요함, 하루가 시작되기 전의 정적 속에서' },
  rise_ignite: { time: '06:00-09:00', desc: '오전 6~9시. 알람 끄고 이불 속. 나른함+부담+작은 설렘', appCtx: '알람 끄고 30초, 이불 속에서 폰 보는 순간' },
  peak_mode:   { time: '09:00-12:00', desc: '오전 9~12시. 업무·공부 집중. 스트레스·책임감', appCtx: '업무·공부 집중 시간, 성과 압박 속에서' },
  recharge:    { time: '12:00-15:00', desc: '오후 12~15시. 점심 후 잠깐 쉬는 시간. 나른함', appCtx: '점심 후 잠깐 숨 고르는 시간, 폰 보거나 짧은 산책 중에' },
  second_wind: { time: '15:00-18:00', desc: '오후 15~18시. 오후 슬럼프. 피로+마무리 의지', appCtx: '오후 슬럼프, 하루 마무리를 앞둔 순간에' },
  golden_hour: { time: '18:00-21:00', desc: '저녁 18~21시. 하루를 마무리하며 돌아보는 시간', appCtx: '하루를 마무리하는 저녁, 잠시 멈추고 돌아보는 순간에' },
  wind_down:   { time: '21:00-24:00', desc: '밤 21~24시. 잠들기 전 마음을 내려놓는 시간', appCtx: '잠들기 전, 하루의 무게를 내려놓는 이 시간에' },
};

// ─── 프롬프트 ─────────────────────────────────────────────────────────────

function buildPrompt(verse) {
  const primaryMode = verse.mode[0];
  const zoneCtx = ZONE_CONTEXT[primaryMode] || ZONE_CONTEXT['recharge'];
  return `너는 morning manna 앱의 말씀 콘텐츠 작가야. 설교자가 아닌 유저의 신앙 친구. 교회 강단 언어 아님.

[성경 구절] ${verse.ref}
[Zone] ${primaryMode} (${zoneCtx.time})
[유저 상황] ${zoneCtx.desc}
[application 배경] ${zoneCtx.appCtx}

[생성 항목 — 글자수 엄수]

① verse_full_ko: 개역한글 원문 그대로 (20자 이상 200자 이하)
   - 절대 창작 금지, 실제 개역한글 성경 원문만 사용

② verse_short_ko: 35자 이하 (10자 이상)
   - verse_full_ko에서 핵심 문장만 발췌 (창작·합성 금지)
   - 완결된 문장, 줄임표 금지

③ interpretation: 80자 이상 200자 이하
   구조: ①저자가 처한 구체적 상황 → ②핵심 의미(원어 단어 직접 표기 절대 금지) → ③오늘날 유저와 연결 → ④${primaryMode} Zone 시간대 맥락 연결
   말투: ~야, ~이야, ~거야, ~있어 (금지: ~이다, ~합니다, 설교조, 훈계조)

④ application: 40자 이상 100자 이하
   - "${zoneCtx.appCtx}" 이 상황이 배경에 느껴지도록
   - 말투: ~해봐, ~해도 돼, ~해도 괜찮아, ~인 거 알아? (금지: 반드시, ~해야 한다, 명령형)
   - 실천 가능한 것 1가지만

⑤ question: 20자 이상 80자 이하
   - verse_full_ko 맥락 연결, 닉네임 없이
   - 일반 어투(~있었어?, ~해봤어?, ~어때?)
   - 신앙 행위 점검 금지

[자기검증] 각 필드 글자수를 직접 세어. 범위 벗어나면 즉시 다시 작성해.

[출력: JSON만, 다른 텍스트 없이]
{"verse_full_ko":"...","verse_short_ko":"...","interpretation":"...","application":"...","question":"..."}`;
}

// ─── 글자수 검증 ──────────────────────────────────────────────────────────

function checkLimits(content) {
  const fails = [];
  if (!content.verse_full_ko || content.verse_full_ko.length < 20)  fails.push(`verse_full_ko: ${(content.verse_full_ko||'').length}자 (최소 20)`);
  if (content.verse_full_ko  && content.verse_full_ko.length > 200) fails.push(`verse_full_ko: ${content.verse_full_ko.length}자 (최대 200)`);
  if (!content.verse_short_ko|| content.verse_short_ko.length < 10) fails.push(`verse_short_ko: ${(content.verse_short_ko||'').length}자 (최소 10)`);
  if (content.verse_short_ko && content.verse_short_ko.length > 50)  fails.push(`verse_short_ko: ${content.verse_short_ko.length}자 (최대 50)`);
  if (!content.interpretation || content.interpretation.length < 80)  fails.push(`interpretation: ${(content.interpretation||'').length}자 (최소 80)`);
  if (content.interpretation  && content.interpretation.length > 200) fails.push(`interpretation: ${content.interpretation.length}자 (최대 200)`);
  if (!content.application   || content.application.length < 40)    fails.push(`application: ${(content.application||'').length}자 (최소 40)`);
  if (content.application    && content.application.length > 100)   fails.push(`application: ${content.application.length}자 (최대 100)`);
  if (!content.question      || content.question.length < 20)       fails.push(`question: ${(content.question||'').length}자 (최소 20)`);
  if (content.question       && content.question.length > 80)       fails.push(`question: ${content.question.length}자 (최대 80)`);
  return fails;
}

// ─── 단건 생성 (Haiku 모델) ───────────────────────────────────────────────

async function generateOne(verse, verseId) {
  const prompt = buildPrompt(verse);

  const call = async () => {
    const msg = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',   // Haiku: Sonnet 대비 5-10배 빠름
      max_tokens: 800,
      messages: [{ role: 'user', content: prompt }],
    });
    const raw = msg.content[0].text.trim()
      .replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
    return JSON.parse(raw);
  };

  let result = await call();
  let fails = checkLimits(result);

  if (fails.length > 0) {
    const retryPrompt = prompt +
      `\n\n[재생성 요청] 아래 필드가 글자수 범위를 벗어났어. 수정해줘:\n` +
      fails.map(f => `- ${f}`).join('\n') +
      `\n[출력: JSON만]\n{"verse_full_ko":"...","verse_short_ko":"...","interpretation":"...","application":"...","question":"..."}`;
    const retry = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 800,
      messages: [{ role: 'user', content: retryPrompt }],
    });
    const retryRaw = retry.content[0].text.trim()
      .replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
    const retried = JSON.parse(retryRaw);
    const limits = { verse_full_ko:[20,200], verse_short_ko:[10,50], interpretation:[80,200], application:[40,100], question:[20,80] };
    for (const [field, [min, max]] of Object.entries(limits)) {
      const len = (result[field]||'').length;
      if (len < min || len > max) result[field] = retried[field];
    }
  }

  return { verseId, verse, content: result };
}

// ─── 메인 ────────────────────────────────────────────────────────────────

async function main() {
  console.log(`=== generate_verses.js v2.0 | dry-run: ${isDryRun} | batch: ${BATCH_SIZE} ===\n`);

  // 생성할 구절 목록 — 필요 시 이 배열만 수정
  // mode: zone rawValue 배열, theme/mood: 태그 배열
  const TARGET_VERSES = [
    // ── peak_mode (15개) — 오전 집중·지혜·성과 ──────────────────────────
    { ref: '잠언 8:34',        mode: ['peak_mode'], theme: ['wisdom','focus'],    mood: ['bright'],           book: '잠언',      chapter: 8,  verse: 34 },
    { ref: '시편 90:17',       mode: ['peak_mode'], theme: ['strength','focus'],  mood: ['bright'],           book: '시편',      chapter: 90, verse: 17 },
    { ref: '잠언 14:23',       mode: ['peak_mode'], theme: ['focus','strength'],  mood: ['bright'],           book: '잠언',      chapter: 14, verse: 23 },
    { ref: '잠언 22:29',       mode: ['peak_mode'], theme: ['wisdom','focus'],    mood: ['bright'],           book: '잠언',      chapter: 22, verse: 29 },
    { ref: '에베소서 2:10',    mode: ['peak_mode'], theme: ['focus','renewal'],   mood: ['bright','warm'],    book: '에베소서',  chapter: 2,  verse: 10 },
    { ref: '이사야 50:4',      mode: ['peak_mode'], theme: ['wisdom','focus'],    mood: ['bright'],           book: '이사야',    chapter: 50, verse: 4  },
    { ref: '느헤미야 6:3',     mode: ['peak_mode'], theme: ['focus','courage'],   mood: ['bright','dramatic'],book: '느헤미야',  chapter: 6,  verse: 3  },
    { ref: '출애굽기 35:31',   mode: ['peak_mode'], theme: ['wisdom','focus'],    mood: ['bright'],           book: '출애굽기',  chapter: 35, verse: 31 },
    { ref: '고린도전서 3:9',   mode: ['peak_mode'], theme: ['focus','strength'],  mood: ['bright','warm'],    book: '고린도전서',chapter: 3,  verse: 9  },
    { ref: '이사야 48:17',     mode: ['peak_mode'], theme: ['wisdom','focus'],    mood: ['bright'],           book: '이사야',    chapter: 48, verse: 17 },
    { ref: '로마서 12:6',      mode: ['peak_mode'], theme: ['wisdom','renewal'],  mood: ['bright','warm'],    book: '로마서',    chapter: 12, verse: 6  },
    { ref: '시편 104:23',      mode: ['peak_mode'], theme: ['focus','strength'],  mood: ['bright'],           book: '시편',      chapter: 104,verse: 23 },
    { ref: '다니엘 6:10',      mode: ['peak_mode'], theme: ['focus','faith'],     mood: ['bright','dramatic'],book: '다니엘',    chapter: 6,  verse: 10 },
    { ref: '잠언 6:6',         mode: ['peak_mode'], theme: ['wisdom','focus'],    mood: ['bright'],           book: '잠언',      chapter: 6,  verse: 6  },
    { ref: '고린도후서 9:8',   mode: ['peak_mode'], theme: ['strength','gratitude'],mood: ['bright','warm'],  book: '고린도후서',chapter: 9,  verse: 8  },

    // ── deep_dark (15개) — 자정~새벽 3시, 불안·외로움 ──────────────────
    { ref: '시편 139:18',      mode: ['deep_dark'], theme: ['faith','stillness'], mood: ['serene','calm'],    book: '시편',      chapter: 139,verse: 18 },
    { ref: '시편 77:2',        mode: ['deep_dark'], theme: ['faith','stillness'], mood: ['serene'],           book: '시편',      chapter: 77, verse: 2  },
    { ref: '이사야 26:20',     mode: ['deep_dark'], theme: ['stillness','faith'], mood: ['serene','calm'],    book: '이사야',    chapter: 26, verse: 20 },
    { ref: '욥기 35:10',       mode: ['deep_dark'], theme: ['faith','stillness'], mood: ['serene'],           book: '욥기',      chapter: 35, verse: 10 },
    { ref: '시편 31:15',       mode: ['deep_dark'], theme: ['faith','surrender'], mood: ['serene','calm'],    book: '시편',      chapter: 31, verse: 15 },
    { ref: '마태복음 14:27',   mode: ['deep_dark'], theme: ['faith','courage'],   mood: ['serene','calm'],    book: '마태복음',  chapter: 14, verse: 27 },
    { ref: '이사야 57:15',     mode: ['deep_dark'], theme: ['faith','grace'],     mood: ['serene'],           book: '이사야',    chapter: 57, verse: 15 },
    { ref: '창세기 28:16',     mode: ['deep_dark'], theme: ['faith','stillness'], mood: ['serene','calm'],    book: '창세기',    chapter: 28, verse: 16 },
    { ref: '시편 68:19',       mode: ['deep_dark'], theme: ['grace','faith'],     mood: ['serene','warm'],    book: '시편',      chapter: 68, verse: 19 },
    { ref: '호세아 11:4',      mode: ['deep_dark'], theme: ['grace','faith'],     mood: ['serene','warm'],    book: '호세아',    chapter: 11, verse: 4  },
    { ref: '시편 42:3',        mode: ['deep_dark'], theme: ['faith','stillness'], mood: ['serene'],           book: '시편',      chapter: 42, verse: 3  },
    { ref: '시편 130:1',       mode: ['deep_dark'], theme: ['faith','stillness'], mood: ['serene','calm'],    book: '시편',      chapter: 130,verse: 1  },
    { ref: '요한복음 8:12',    mode: ['deep_dark'], theme: ['faith','hope'],      mood: ['serene','calm'],    book: '요한복음',  chapter: 8,  verse: 12 },
    { ref: '신명기 1:30',      mode: ['deep_dark'], theme: ['faith','courage'],   mood: ['serene','calm'],    book: '신명기',    chapter: 1,  verse: 30 },
    { ref: '이사야 43:5',      mode: ['deep_dark'], theme: ['faith','stillness'], mood: ['serene','calm'],    book: '이사야',    chapter: 43, verse: 5  },

    // ── recharge (10개) — 점심 후 쉼·재충전 ────────────────────────────
    { ref: '마가복음 6:31',    mode: ['recharge'],  theme: ['rest','renewal'],   mood: ['calm','warm'],      book: '마가복음',  chapter: 6,  verse: 31 },
    { ref: '시편 23:2',        mode: ['recharge'],  theme: ['rest','peace'],     mood: ['calm','serene'],    book: '시편',      chapter: 23, verse: 2  },
    { ref: '이사야 30:18',     mode: ['recharge'],  theme: ['patience','rest'],  mood: ['calm'],             book: '이사야',    chapter: 30, verse: 18 },
    { ref: '빌립보서 4:12',    mode: ['recharge'],  theme: ['gratitude','rest'], mood: ['warm','calm'],      book: '빌립보서',  chapter: 4,  verse: 12 },
    { ref: '예레미야 6:16',    mode: ['recharge'],  theme: ['rest','wisdom'],    mood: ['calm'],             book: '예레미야',  chapter: 6,  verse: 16 },
    { ref: '이사야 40:1',      mode: ['recharge'],  theme: ['comfort','rest'],   mood: ['warm','calm'],      book: '이사야',    chapter: 40, verse: 1  },
    { ref: '출애굽기 33:14',   mode: ['recharge'],  theme: ['rest','faith'],     mood: ['calm','warm'],      book: '출애굽기',  chapter: 33, verse: 14 },
    { ref: '마태복음 11:30',   mode: ['recharge'],  theme: ['rest','faith'],     mood: ['calm','warm'],      book: '마태복음',  chapter: 11, verse: 30 },
    { ref: '시편 116:7',       mode: ['recharge'],  theme: ['rest','gratitude'], mood: ['warm','calm'],      book: '시편',      chapter: 116,verse: 7  },
    { ref: '잠언 17:1',        mode: ['recharge'],  theme: ['rest','peace'],     mood: ['calm'],             book: '잠언',      chapter: 17, verse: 1  },

    // ── second_wind (10개) — 오후 슬럼프 재점화 ──────────────────────────
    { ref: '히브리서 12:12',   mode: ['second_wind'],theme: ['strength','courage'],mood: ['warm','dramatic'],book: '히브리서',  chapter: 12, verse: 12 },
    { ref: '고린도후서 4:1',   mode: ['second_wind'],theme: ['strength','patience'],mood: ['warm','calm'],   book: '고린도후서',chapter: 4,  verse: 1  },
    { ref: '이사야 43:18',     mode: ['second_wind'],theme: ['renewal','hope'],   mood: ['warm','bright'],   book: '이사야',    chapter: 43, verse: 18 },
    { ref: '여호수아 14:11',   mode: ['second_wind'],theme: ['strength','courage'],mood: ['warm','dramatic'],book: '여호수아',  chapter: 14, verse: 11 },
    { ref: '역대상 29:14',     mode: ['second_wind'],theme: ['gratitude','strength'],mood: ['warm'],         book: '역대상',    chapter: 29, verse: 14 },
    { ref: '시편 138:8',       mode: ['second_wind'],theme: ['faith','patience'], mood: ['warm','calm'],     book: '시편',      chapter: 138,verse: 8  },
    { ref: '로마서 15:5',      mode: ['second_wind'],theme: ['patience','strength'],mood: ['warm','calm'],   book: '로마서',    chapter: 15, verse: 5  },
    { ref: '에베소서 6:13',    mode: ['second_wind'],theme: ['strength','courage'],mood: ['warm','dramatic'],book: '에베소서',  chapter: 6,  verse: 13 },
    { ref: '잠언 24:16',       mode: ['second_wind'],theme: ['patience','courage'],mood: ['warm'],           book: '잠언',      chapter: 24, verse: 16 },
    { ref: '이사야 40:30',     mode: ['second_wind'],theme: ['strength','renewal'],mood: ['warm','dramatic'],book: '이사야',    chapter: 40, verse: 30 },
  ];

  if (TARGET_VERSES.length === 0) {
    console.log('⚠️  TARGET_VERSES가 비어있습니다. 구절을 추가해주세요.');
    process.exit(0);
  }

  // ── 1. ID 사전 채번 (병렬 처리 전 중복 방지) ──────────────────────────
  const sheets = await getSheetsClient();
  const r = await sheets.spreadsheets.values.get({ spreadsheetId: SHEET_ID, range: 'VERSES!A:A' });
  const allIds = (r.data.values || []).map(row => row[0]).filter(id => /^v_\d+$/.test(id));
  const maxNum = allIds.length > 0 ? Math.max(...allIds.map(id => parseInt(id.replace('v_', '')))) : 431;
  console.log(`현재 마지막 verse_id: v_${String(maxNum).padStart(3,'0')} | 신규 시작: v_${String(maxNum+1).padStart(3,'0')}`);
  console.log(`생성 대상: ${TARGET_VERSES.length}개 | 배치 크기: ${BATCH_SIZE}\n`);

  // ID 전체 사전 할당 (race condition 완전 방지)
  const assignments = TARGET_VERSES.map((verse, i) => ({
    verse,
    verseId: `v_${String(maxNum + 1 + i).padStart(3, '0')}`,
  }));

  if (isDryRun) {
    console.log('--- dry-run: ID 채번 결과 ---');
    assignments.forEach(a => console.log(`  ${a.verseId} → ${a.verse.ref} [${a.verse.mode[0]}]`));
    process.exit(0);
  }

  // ── 2. 배치 병렬 생성 ──────────────────────────────────────────────────
  let success = 0;
  let errors  = 0;
  const allResults = [];
  const startTime = Date.now();

  for (let batchStart = 0; batchStart < assignments.length; batchStart += BATCH_SIZE) {
    const batch = assignments.slice(batchStart, batchStart + BATCH_SIZE);
    const batchNum = Math.floor(batchStart / BATCH_SIZE) + 1;
    const totalBatches = Math.ceil(assignments.length / BATCH_SIZE);

    process.stdout.write(`[배치 ${batchNum}/${totalBatches}] ${batch.map(a => a.verseId).join(', ')} 생성 중... `);

    // 배치 내 병렬 실행
    const batchResults = await Promise.allSettled(
      batch.map(({ verse, verseId }) => generateOne(verse, verseId))
    );

    // 성공/실패 집계
    const successRows = [];
    for (const result of batchResults) {
      if (result.status === 'fulfilled') {
        const { verseId, verse, content } = result.value;
        const docData = {
          verse_short_ko: content.verse_short_ko,
          verse_full_ko:  content.verse_full_ko,
          reference:      verse.ref,
          book:           verse.book,
          chapter:        verse.chapter,
          verse:          verse.verse,
          mode:           verse.mode,
          theme:          verse.theme,
          mood:           verse.mood,
          season:         ['all'],
          weather:        ['any'],
          interpretation: content.interpretation,
          application:    content.application,
          curated:        'TRUE',
          status:         'active',
          notes:          '',
          usage_count:    0,
          cooldown_days:  7,
          last_shown:     '',
          show_count:     0,
          alarm_top_ko:   '',
          contemplation_ko: '',
          contemplation_reference: '',
          contemplation_interpretation: '',
          contemplation_appliance: '',
          question:       content.question,
        };
        successRows.push({ verseId, verse, row: docToRow(verseId, docData) });
        allResults.push({ verseId, ref: verse.ref, mode: verse.mode[0] });
        success++;
      } else {
        console.log(`\n  ❌ 오류: ${result.reason?.message}`);
        errors++;
      }
    }

    // 배치 단위 일괄 Sheets write (1번 API 호출)
    if (successRows.length > 0) {
      const range = await appendBatchToSheets(successRows.map(r => r.row));
      console.log(`완료 → ${range}`);
      successRows.forEach(r =>
        console.log(`   ${r.verseId} | ${r.verse.mode[0].padEnd(12)} | ${r.verse.ref}`)
      );
    }

    // 배치 간 딜레이 (마지막 배치 제외)
    if (batchStart + BATCH_SIZE < assignments.length) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`\n${'='.repeat(50)}`);
  console.log(`✅ 완료 | 성공: ${success}개 | 오류: ${errors}개 | 소요: ${elapsed}초`);
  console.log(`\n다음 단계: NODE_TLS_REJECT_UNAUTHORIZED=0 node sync_verses.js`);
}

main().catch(console.error).finally(() => process.exit());
