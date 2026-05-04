require('dotenv').config();
/**
 * generate_verses_50.js — 50개 신규 말씀 생성 및 VERSES 탭 추가
 *
 * 배분:
 *   recharge: 12개
 *   second_wind: 12개
 *   peak_mode: 10개
 *   deep_dark: 10개
 *   rise_ignite: 3개
 *   first_light: 3개
 *
 * 데이터 쓰기 원칙:
 *   Google Sheets = Single Source of Truth (읽기/쓰기)
 *   Firestore = 읽기 전용 — 직접 쓰기 금지
 */

const Anthropic = require('@anthropic-ai/sdk');
const { google } = require('googleapis');
const path = require('path');

const SHEET_ID  = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const KEY_FILE  = path.join(__dirname, 'serviceAccountKey.json');
const SHEET_TAB = 'VERSES';

// VERSES 탭 컬럼 순서 (기존 헤더 기준)
const COLUMN_ORDER = [
  'verse_id', 'verse_short_ko', 'verse_full_ko', 'reference',
  'book', 'chapter', 'verse', 'mode', 'theme', 'mood', 'season', 'weather',
  'interpretation', 'application', 'curated', 'status', 'notes',
  'usage_count', 'cooldown_days', 'last_shown', 'show_count',
  'alarm_top_ko', 'contemplation_ko', 'contemplation_reference',
  'contemplation_interpretation', 'contemplation_appliance', 'question',
];

async function getSheetsClient() {
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  return google.sheets({ version: 'v4', auth });
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

async function appendToSheets(verseId, docData) {
  const sheets = await getSheetsClient();
  const row = docToRow(verseId, docData);
  const result = await sheets.spreadsheets.values.append({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_TAB}!A:AB`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: [row] },
  });
  return result.data.updates;
}

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) { console.error('ANTHROPIC_API_KEY 필요'); process.exit(1); }
const anthropic = new Anthropic({ apiKey });

const isDryRun = process.argv.includes('--dry-run');

// Zone 컨텍스트
const ZONE_CONTEXT = {
  deep_dark:   { time: '00:00-03:00', desc: '자정~새벽 3시. 잠 못 들고 불안·외로움 속에 깨어 있음', appCtx: '지금 뒤척이고 있는 이 밤, 깊은 어둠 속에서' },
  first_light: { time: '03:00-06:00', desc: '새벽 3~6시. 이른 기도·묵상을 위해 일어남. 하루 전의 고요', appCtx: '새벽의 고요함, 하루가 시작되기 전의 정적 속에서' },
  rise_ignite: { time: '06:00-09:00', desc: '오전 6~9시. 알람 끄고 이불 속. 나른함+부담+작은 설렘', appCtx: '알람 끄고 30초, 이불 속에서 폰 보는 순간' },
  peak_mode:   { time: '09:00-12:00', desc: '오전 9~12시. 업무·공부 집중. 스트레스·책임감', appCtx: '업무·공부 집중 시간, 성과 압박 속에서' },
  recharge:    { time: '12:00-15:00', desc: '오후 12~15시. 점심 후 잠깐 쉬는 시간. 나른함', appCtx: '점심 후 잠깐 숨 고르는 시간, 폰 보거나 짧은 산책 중에' },
  second_wind: { time: '15:00-18:00', desc: '오후 15~18시. 오후 슬럼프. 피로+마무리 의지', appCtx: '오후 슬럼프, 하루 마무리를 앞둔 순간에' },
};

// 50개 신규 구절 목록 (기존 목록 중복 없는 것으로만)
const NEW_VERSES = [
  // ── recharge (12개) — 점심 후 쉼·재충전 ──────────────────────────────────
  { ref: '마태복음 11:29',     mode: ['recharge'],            theme: ['rest', 'comfort'],    mood: ['calm', 'warm'],   book: '마태복음',  chapter: 11, verse: 29 },
  { ref: '시편 62:8',          mode: ['recharge'],            theme: ['rest', 'faith'],      mood: ['calm', 'warm'],   book: '시편',      chapter: 62, verse: 8 },
  { ref: '시편 116:7',         mode: ['recharge'],            theme: ['rest', 'gratitude'],  mood: ['warm', 'calm'],   book: '시편',      chapter: 116, verse: 7 },
  { ref: '이사야 30:15',       mode: ['recharge'],            theme: ['rest', 'patience'],   mood: ['calm'],           book: '이사야',    chapter: 30, verse: 15 },
  { ref: '시편 55:6',           mode: ['recharge', 'wind_down'], theme: ['rest', 'stillness'], mood: ['calm', 'serene'], book: '시편',     chapter: 55, verse: 6 },
  { ref: '고린도전서 14:33',   mode: ['recharge'],            theme: ['peace', 'rest'],      mood: ['calm'],           book: '고린도전서', chapter: 14, verse: 33 },
  { ref: '시편 23:3',          mode: ['recharge'],            theme: ['rest', 'renewal'],    mood: ['warm', 'calm'],   book: '시편',      chapter: 23, verse: 3 },
  { ref: '잠언 11:25',         mode: ['recharge'],            theme: ['gratitude', 'rest'],  mood: ['warm'],           book: '잠언',      chapter: 11, verse: 25 },
  { ref: '이사야 28:12',       mode: ['recharge'],            theme: ['rest', 'patience'],   mood: ['calm'],           book: '이사야',    chapter: 28, verse: 12 },
  { ref: '시편 145:9',         mode: ['recharge'],            theme: ['comfort', 'gratitude'],mood: ['warm', 'calm'],  book: '시편',      chapter: 145, verse: 9 },
  { ref: '신명기 33:25',       mode: ['recharge'],            theme: ['strength', 'rest'],   mood: ['warm', 'calm'],   book: '신명기',    chapter: 33, verse: 25 },
  { ref: '베드로전서 5:10',    mode: ['recharge'],            theme: ['patience', 'comfort'], mood: ['warm', 'calm'],  book: '베드로전서', chapter: 5, verse: 10 },

  // ── second_wind (12개) — 오후 슬럼프 재점화 ────────────────────────────
  { ref: '디모데전서 6:12',    mode: ['second_wind'],         theme: ['strength', 'focus'],  mood: ['warm', 'calm'],  book: '디모데전서', chapter: 6, verse: 12 },
  { ref: '고린도전서 15:58',   mode: ['second_wind'],         theme: ['strength', 'focus'],  mood: ['warm', 'calm'],  book: '고린도전서', chapter: 15, verse: 58 },
  { ref: '잠언 24:10',         mode: ['second_wind'],         theme: ['strength', 'patience'],mood: ['calm'],          book: '잠언',      chapter: 24, verse: 10 },
  { ref: '스바냐 3:17',        mode: ['second_wind'],         theme: ['faith', 'strength'],  mood: ['warm', 'calm'],  book: '스바냐',    chapter: 3, verse: 17 },
  { ref: '야고보서 1:12',      mode: ['second_wind'],         theme: ['patience', 'wisdom'],  mood: ['warm', 'calm'],  book: '야고보서',  chapter: 1, verse: 12 },
  { ref: '시편 37:7',          mode: ['second_wind'],         theme: ['patience', 'focus'],  mood: ['calm'],          book: '시편',      chapter: 37, verse: 7 },
  { ref: '에베소서 3:16',      mode: ['second_wind'],         theme: ['strength', 'faith'],  mood: ['warm'],          book: '에베소서',  chapter: 3, verse: 16 },
  { ref: '고린도후서 12:10',   mode: ['second_wind'],         theme: ['strength', 'wisdom'], mood: ['calm', 'warm'],  book: '고린도후서', chapter: 12, verse: 10 },
  { ref: '로마서 5:4',         mode: ['second_wind'],         theme: ['patience', 'strength'], mood: ['warm'],        book: '로마서',    chapter: 5, verse: 4 },
  { ref: '히브리서 12:3',      mode: ['second_wind'],         theme: ['strength', 'focus'],  mood: ['calm', 'warm'],  book: '히브리서',  chapter: 12, verse: 3 },
  { ref: '골로새서 1:11',      mode: ['second_wind'],         theme: ['strength', 'patience'],mood: ['warm'],         book: '골로새서',  chapter: 1, verse: 11 },
  { ref: '잠언 3:11-12',       mode: ['second_wind'],         theme: ['wisdom', 'patience'], mood: ['warm', 'calm'],  book: '잠언',      chapter: 3, verse: 11 },

  // ── peak_mode (10개) — 오전 집중·성과 ──────────────────────────────────
  { ref: '잠언 2:6',           mode: ['peak_mode'],           theme: ['wisdom', 'focus'],    mood: ['bright'],        book: '잠언',      chapter: 2, verse: 6 },
  { ref: '잠언 21:5',          mode: ['peak_mode'],           theme: ['wisdom', 'focus'],    mood: ['bright'],        book: '잠언',      chapter: 21, verse: 5 },
  { ref: '고린도전서 9:24',    mode: ['peak_mode'],           theme: ['focus', 'strength'],  mood: ['bright', 'dramatic'], book: '고린도전서', chapter: 9, verse: 24 },
  { ref: '잠언 10:4',          mode: ['peak_mode'],           theme: ['focus', 'wisdom'],    mood: ['bright'],        book: '잠언',      chapter: 10, verse: 4 },
  { ref: '전도서 11:4',        mode: ['peak_mode'],           theme: ['courage', 'wisdom'],  mood: ['bright'],        book: '전도서',    chapter: 11, verse: 4 },
  { ref: '로마서 12:11',       mode: ['peak_mode'],           theme: ['strength', 'focus'],  mood: ['bright', 'dramatic'], book: '로마서',  chapter: 12, verse: 11 },
  { ref: '에베소서 5:15-16',   mode: ['peak_mode'],           theme: ['wisdom', 'focus'],    mood: ['bright'],        book: '에베소서',  chapter: 5, verse: 15 },
  { ref: '잠언 13:4',          mode: ['peak_mode'],           theme: ['focus', 'strength'],  mood: ['bright'],        book: '잠언',      chapter: 13, verse: 4 },
  { ref: '느헤미야 4:14',      mode: ['peak_mode'],           theme: ['courage', 'strength'],mood: ['bright', 'dramatic'], book: '느헤미야', chapter: 4, verse: 14 },
  { ref: '잠언 16:1',          mode: ['peak_mode'],           theme: ['wisdom', 'courage'],  mood: ['bright'],        book: '잠언',      chapter: 16, verse: 1 },

  // ── deep_dark (10개) — 자정~새벽 3시 ───────────────────────────────────
  { ref: '시편 22:24',         mode: ['deep_dark'],           theme: ['faith', 'grace'],     mood: ['serene', 'calm'],book: '시편',      chapter: 22, verse: 24 },
  { ref: '시편 91:11-12',      mode: ['deep_dark'],           theme: ['faith', 'stillness'], mood: ['serene'],        book: '시편',      chapter: 91, verse: 11 },
  { ref: '이사야 41:13',       mode: ['deep_dark'],           theme: ['faith', 'grace'],     mood: ['serene', 'calm'],book: '이사야',    chapter: 41, verse: 13 },
  { ref: '시편 139:11-12',     mode: ['deep_dark'],           theme: ['stillness', 'faith'], mood: ['serene'],        book: '시편',      chapter: 139, verse: 11 },
  { ref: '신명기 33:27',       mode: ['deep_dark'],           theme: ['surrender', 'faith'], mood: ['serene', 'calm'],book: '신명기',    chapter: 33, verse: 27 },
  { ref: '시편 94:18-19',      mode: ['deep_dark'],           theme: ['grace', 'stillness'], mood: ['serene', 'calm'],book: '시편',      chapter: 94, verse: 18 },
  { ref: '예레미야 31:25',     mode: ['deep_dark'],           theme: ['rest', 'grace'],      mood: ['calm', 'serene'],book: '예레미야',  chapter: 31, verse: 25 },
  { ref: '시편 4:3',           mode: ['deep_dark'],           theme: ['faith', 'stillness'], mood: ['serene'],        book: '시편',      chapter: 4, verse: 3 },
  { ref: '잠언 3:25-26',       mode: ['deep_dark'],           theme: ['faith', 'surrender'], mood: ['calm', 'serene'],book: '잠언',      chapter: 3, verse: 25 },
  { ref: '시편 16:9',          mode: ['deep_dark'],           theme: ['stillness', 'grace'], mood: ['serene', 'calm'],book: '시편',      chapter: 16, verse: 9 },

  // ── rise_ignite (3개) — 오전 6~9시 ─────────────────────────────────────
  { ref: '시편 118:5-6',       mode: ['rise_ignite'],         theme: ['courage', 'hope'],    mood: ['bright', 'dramatic'], book: '시편',   chapter: 118, verse: 5 },
  { ref: '미가 6:8',           mode: ['rise_ignite'],         theme: ['renewal', 'strength'],mood: ['bright'],        book: '미가',      chapter: 6, verse: 8 },
  { ref: '시편 57:1',          mode: ['rise_ignite'],         theme: ['hope', 'courage'],    mood: ['bright', 'dramatic'], book: '시편',   chapter: 57, verse: 1 },

  // ── first_light (3개) — 새벽 3~6시 ─────────────────────────────────────
  { ref: '시편 5:1-2',         mode: ['first_light'],         theme: ['faith', 'stillness'], mood: ['serene', 'calm'],book: '시편',      chapter: 5, verse: 1 },
  { ref: '애가 3:40',          mode: ['first_light'],         theme: ['renewal', 'faith'],   mood: ['serene'],        book: '애가',      chapter: 3, verse: 40 },
  { ref: '누가복음 21:36',     mode: ['first_light'],         theme: ['stillness', 'faith'], mood: ['serene', 'calm'],book: '누가복음',  chapter: 21, verse: 36 },
];

// 중복 제거 — 이미 시트에 있는 것 제외
const EXISTING_REFS = new Set([
  "야고보서 4:8","잠언 24:16","시편 27:14","잠언 4:18","잠언 16:9","시편 5:3","시편 143:8",
  "시편 139:7-8","데살로니가전서 5:16-18","마태복음 6:33","시편 121:4-5","시편 63:7","시편 118:24",
  "고린도전서 16:13","시편 63:1","시편 108:2-3","이사야 45:2-3","시편 92:2","로마서 8:28",
  "에베소서 6:10","이사야 58:8","예레미야 17:7-8","고린도전서 15:10","이사야 43:19",
  "마가복음 1:35","시편 57:8-9","시편 90:14","애가 3:21-23","로마서 6:4","이사야 43:2",
  "히브리서 10:23","이사야 55:8-9","빌립보서 4:7","잠언 16:24","잠언 19:21","마태복음 6:34",
  "시편 4:8","로마서 8:31","요한복음 14:27","빌립보서 4:13","시편 37:4","이사야 40:31",
  "시편 119:147","고린도전서 13:4-5","에베소서 1:18","갈라디아서 6:9","하박국 2:3",
  "출애굽기 20:8","시편 91:4","이사야 41:10","시편 37:5","시편 126:5-6","시편 30:5",
  "마태복음 24:42","시편 23:5-6","잠언 8:17","시편 127:2","빌립보서 4:6","데살로니가전서 5:18",
  "이사야 26:9","마태복음 26:41","시편 27:13-14","에스겔 36:26","시편 126:5","고린도후서 4:16",
  "시편 37:3-4","로마서 15:13","빌립보서 3:12","요한복음 8:32","누가복음 12:32",
  "히브리서 10:36","요한복음 10:10","잠언 3:5-6","디모데후서 4:7","잠언 18:10","로마서 12:12",
  "시편 27:1","시편 119:105","요한복음 16:33","신명기 31:6","에베소서 2:10","히브리서 12:1-2",
  "마태복음 5:4","시편 46:1","고린도후서 1:3-4","빌립보서 4:4","마태복음 11:28-29",
  "마가복음 10:27","요한일서 4:18","시편 62:5-6","시편 16:8","시편 23:1-2","로마서 12:2",
  "로마서 8:38-39","예레미야 33:3","시편 18:1-2","시편 19:14","시편 34:18","잠언 16:3",
  "시편 62:5","시편 37:34","로마서 12:19","디모데전서 4:4","시편 139:1-2","이사야 43:1",
  "이사야 60:1","이사야 40:29","애가 3:22-23","에베소서 5:14","시편 130:6","욥기 11:17",
  "시편 63:6","시편 139:9-10","시편 121:1-2","이사야 50:4","요한복음 1:16","히브리서 4:16",
  "히브리서 11:1","고린도전서 10:13","로마서 8:26","여호수아 1:9","갈라디아서 2:20",
  "요한복음 3:16","예레미야 29:11","골로새서 3:23-24","에베소서 3:20","시편 18:32",
  "잠언 4:5-6","이사야 32:17","로마서 12:1","마태복음 11:28","시편 107:1","시편 61:1",
  "시편 121:4","미가 7:8","베드로전서 5:7","신명기 31:8","시편 145:8","요한복음 15:5",
  "시편 23:6","고린도후서 4:17","에베소서 6:10-11","시편 23:1","시편 73:26",
  "이사야 40:28-29","시편 107:9","시편 46:10","시편 42:8","이사야 26:3","갈라디아서 5:22-23",
  "요한복음 14:29","히브리서 13:5","시편 3:3","시편 56:3-4","이사야 43:4","시편 8:1",
  "시편 51:10","요한복음 1:1","요한복음 11:25-26","시편 19:1","시편 32:8","시편 84:11",
  "마태복음 7:7","로마서 8:1","요한복음 8:36","시편 24:1","잠언 31:25","누가복음 1:37",
  "로마서 5:1","빌립보서 1:6","시편 131:2","시편 86:5","시편 36:7","마태복음 18:20",
  "시편 40:1-2","이사야 48:10","사도행전 2:28","마태복음 28:20","시편 103:2","시편 100:4",
  "시편 116:1","에베소서 4:32","이사야 44:22","시편 112:1","창세기 28:15","예레미야 31:3",
  "시편 31:3","누가복음 15:4","이사야 9:6","마태복음 5:3","마태복음 5:8","빌립보서 4:6-7",
  "시편 62:1-2","시편 5:8","이사야 53:4","빌립보서 4:4-5","시편 55:22","빌립보서 4:11-12",
  "예레미야애가 3:22-23","시편 130:1-2","출애굽기 33:14","시편 108:1","요한복음 14:1",
  "여호수아 1:5","시편 139:1-3","시편 86:7","예레미야 29:13","이사야 32:18","전도서 9:10",
  "잠언 4:7","야고보서 1:5","다니엘 1:8","느헤미야 8:10","골로새서 3:23","시편 8:3-4",
  "다니엘 12:3","잠언 22:1","빌립보서 2:3","시편 37:5-6","디모데후서 1:7","여호수아 1:8",
  "사도행전 20:24","야고보서 3:13","빌립보서 3:13-14","잠언 12:24","시편 56:3",
  "시편 119:71","고린도후서 4:8","디모데전서 1:12","출애굽기 15:2","로마서 5:3-4",
  "예레미야애가 5:21","야고보서 1:4","데살로니가전서 5:23","잠언 3:18","이사야 35:3-4",
  "예레미야 29:12","시편 121:8","요한삼서 1:2","창세기 2:18","시편 18:1","시편 18:2",
  "시편 30:11","시편 121:5-6","이사야 12:2","시편 103:1","이사야 25:1","고린도후서 9:8",
  "시편 119:137","예레미야 17:17","역대상 28:20","시편 20:7","시편 37:3","여호수아 1:8",
  "시편 91:1","시편 3:5","시편 62:1","마가복음 6:31","시편 134:1","에베소서 4:26",
  "잠언 3:24","요한1서 3:20","시편 121:7-8","골로새서 3:15","시편 131:1-2",
  "이사야 54:10","시편 16:7","룻기 2:12","히브리서 4:9-10","시편 29:11","시편 17:15",
  "시편 59:16","시편 88:13","시편 5:11-12","나훔 1:7","이사야 62:1","마가복음 16:2",
  "누가복음 24:1","시편 46:5","잠언 6:22","스가랴 14:7","말라기 4:2","시편 4:4",
  "시편 136:1","룻기 1:17","룻기 2:8","고린도전서 13:4","로마서 12:10","잠언 15:1",
  "시편 25:6","잠언 3:5","갈라디아서 6:10","잠언 17:22","전도서 4:9","시편 37:24",
  "시편 119:50","빌립보서 4:19","마태복음 5:9","갈라디아서 6:7","빌립보서 4:8","시편 27:8",
  "레위기 19:18","고린도후서 13:11","역대하 7:14","호세아 6:3","아모스 4:13","스바냐 3:5",
  "미가 7:7-8","사무엘상 12:22","열왕기상 19:7","베드로전서 1:3","고린도후서 12:9",
  "민수기 6:24-26","잠언 3:26","시편 77:6","요한복음 17:21","빌레몬서 1:20","에베소서 5:20",
  "아가서 2:16","요한복음 17:3","요엘 2:12","마태복음 21:9","이사야 53:5","마가복음 10:14",
  "출애굽기 20:12","사도행전 2:1-2","로마서 13:11","누가복음 2:11","시편 90:12",
  // 잠언 3:24 는 위에 recharge에 있지만 기존 목록에도 있으니 확인 필요
  "시편 56:3", // 기존에 있음
]);

// 실제 중복 필터링
const FILTERED_VERSES = NEW_VERSES.filter(v => {
  if (EXISTING_REFS.has(v.ref)) {
    console.log(`[SKIP] 중복 제거: ${v.ref}`);
    return false;
  }
  return true;
});

// interpretation/application 글자수 검증
function checkLimits(content) {
  const fails = [];
  if (content.verse_full_ko.length < 20)  fails.push(`verse_full_ko: ${content.verse_full_ko.length}자 (최소 20)`);
  if (content.verse_full_ko.length > 200) fails.push(`verse_full_ko: ${content.verse_full_ko.length}자 (최대 200)`);
  if (content.verse_short_ko.length < 10) fails.push(`verse_short_ko: ${content.verse_short_ko.length}자 (최소 10)`);
  if (content.verse_short_ko.length > 50) fails.push(`verse_short_ko: ${content.verse_short_ko.length}자 (최대 50, 35 권장)`);
  if (content.interpretation.length < 80)  fails.push(`interpretation: ${content.interpretation.length}자 (최소 80)`);
  if (content.interpretation.length > 200) fails.push(`interpretation: ${content.interpretation.length}자 (최대 200)`);
  if (content.application.length < 40)    fails.push(`application: ${content.application.length}자 (최소 40)`);
  if (content.application.length > 100)   fails.push(`application: ${content.application.length}자 (최대 100)`);
  if (content.question.length < 20)       fails.push(`question: ${content.question.length}자 (최소 20)`);
  if (content.question.length > 80)       fails.push(`question: ${content.question.length}자 (최대 80)`);
  return fails;
}

function buildPrompt(verse, zone) {
  const primaryMode = verse.mode[0];
  const zoneCtx = ZONE_CONTEXT[primaryMode];

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

async function callClaude(prompt) {
  const msg = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 800,
    messages: [{ role: 'user', content: prompt }],
  });
  const raw = msg.content[0].text.trim()
    .replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
  return JSON.parse(raw);
}

async function generateContent(verse) {
  const primaryMode = verse.mode[0];
  const zone = ZONE_CONTEXT[primaryMode];

  let result = await callClaude(buildPrompt(verse, zone));
  let fails = checkLimits(result);

  if (fails.length > 0) {
    const retryPrompt = buildPrompt(verse, zone) +
      `\n\n[재생성 요청] 아래 필드가 글자수 범위를 벗어났어. 수정해줘:\n` +
      fails.map(f => `- ${f}`).join('\n') +
      `\n[출력: JSON만]\n{"verse_full_ko":"...","verse_short_ko":"...","interpretation":"...","application":"...","question":"..."}`;
    const retry = await callClaude(retryPrompt);
    // 실패한 필드만 교체
    for (const field of ['verse_full_ko','verse_short_ko','interpretation','application','question']) {
      const len = (result[field] || '').length;
      const map = {
        verse_full_ko: [20, 200], verse_short_ko: [10, 50],
        interpretation: [80, 200], application: [40, 100], question: [20, 80]
      };
      const [min, max] = map[field];
      if (len < min || len > max) result[field] = retry[field];
    }
  }

  return result;
}

async function main() {
  console.log(`=== generate_verses_50.js | dry-run: ${isDryRun} ===`);
  console.log(`필터링 후 생성 대상: ${FILTERED_VERSES.length}개\n`);

  // 현재 시트의 마지막 verse_id 번호 확인
  const sheets = await getSheetsClient();
  const r = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: 'VERSES!A:A',
  });
  const allIds = (r.data.values || []).map(row => row[0]).filter(id => /^v_\d+$/.test(id));
  const maxNum = Math.max(...allIds.map(id => parseInt(id.replace('v_', ''))));
  console.log(`현재 마지막 verse_id: v_${String(maxNum).padStart(3,'0')} (row ${allIds.length + 1})`);
  console.log(`신규 시작 번호: v_${String(maxNum + 1).padStart(3,'0')}\n`);

  let startNum = maxNum + 1;
  let success = 0;
  let errors = 0;
  const results = [];

  for (let i = 0; i < FILTERED_VERSES.length; i++) {
    const verse = FILTERED_VERSES[i];
    const verseId = `v_${String(startNum + i).padStart(3, '0')}`;
    process.stdout.write(`[${i+1}/${FILTERED_VERSES.length}] ${verseId} (${verse.ref}) ... `);

    try {
      const content = await generateContent(verse);
      const fails = checkLimits(content);
      if (fails.length > 0) {
        console.log(`글자수 경고: ${fails.join(', ')}`);
      }

      if (isDryRun) {
        console.log('OK (dry-run)');
        console.log(`  short: "${content.verse_short_ko}" (${content.verse_short_ko.length}자)`);
        console.log(`  interp: "${content.interpretation.slice(0, 50)}..." (${content.interpretation.length}자)`);
        console.log(`  app: "${content.application}" (${content.application.length}자)`);
      } else {
        const docData = {
          verse_short_ko:  content.verse_short_ko,
          verse_full_ko:   content.verse_full_ko,
          reference:       verse.ref,
          book:            verse.book,
          chapter:         verse.chapter,
          verse:           verse.verse,
          mode:            verse.mode,
          theme:           verse.theme,
          mood:            verse.mood,
          season:          ['all'],
          weather:         ['any'],
          interpretation:  content.interpretation,
          application:     content.application,
          curated:         'TRUE',
          status:          'active',
          notes:           '',
          usage_count:     0,
          cooldown_days:   7,
          last_shown:      '',
          show_count:      0,
          alarm_top_ko:    '',
          contemplation_ko: '',
          contemplation_reference: '',
          contemplation_interpretation: '',
          contemplation_appliance: '',
          question:        content.question,
        };

        const updates = await appendToSheets(verseId, docData);
        const updatedRange = updates ? updates.updatedRange : '?';
        console.log(`완료 → ${updatedRange}`);
        results.push({ verseId, ref: verse.ref, mode: verse.mode[0], row: updatedRange });
        success++;
      }
    } catch(e) {
      console.log(`오류: ${e.message}`);
      errors++;
    }

    // API 레이트 리밋 방지
    if (i < FILTERED_VERSES.length - 1) {
      await new Promise(r => setTimeout(r, 1200));
    }
  }

  console.log(`\n===== 완료 =====`);
  if (isDryRun) {
    console.log(`dry-run: ${FILTERED_VERSES.length}개 미리보기 완료`);
  } else {
    console.log(`성공: ${success}개 | 오류: ${errors}개`);
    console.log('\n추가된 구절 목록:');
    results.forEach(r => console.log(`  ${r.verseId} | ${r.mode.padEnd(12)} | ${r.ref} → ${r.row}`));
    console.log('\n다음 단계: node sync_verses.js (Firestore 동기화)');
  }
}

main().catch(console.error).finally(() => process.exit());
