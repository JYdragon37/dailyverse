/**
 * fix_checker_results_20260424.js
 * content-checker 검수 결과 일괄 수정
 *
 * 작업:
 *   1. 중복/번영신학 → status="inactive"
 *   2. 번역 오류 → verse_full_ko 교체
 *   3. verse_short_ko → 원문 발췌로 교체
 *   4. verse_short_ko 50자 초과 → 단축
 */

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const serviceAccount = require('./serviceAccountKey.json');

const auth = new google.auth.GoogleAuth({
  credentials: serviceAccount,
  scopes: ['https://www.googleapis.com/auth/spreadsheets']
});

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET = 'VERSES';

// 열 인덱스 → A1 표기 (1-based)
function colLetter(n) {
  let s = '';
  while (n > 0) {
    const r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
}

// 컬럼 위치 (1-based)
// A=1 verse_id, B=2 verse_short_ko, C=3 verse_full_ko
// P=16 status

const COL = {
  verse_id:       1,  // A
  verse_short_ko: 2,  // B
  verse_full_ko:  3,  // C
  status:        16,  // P
};

// ──────────────────────────────────────────────
// 수정 명세 (verse_id 기준)
// ──────────────────────────────────────────────

// 1. inactive 처리 대상 (status=P열)
const INACTIVE_IDS = [
  'v_342', // 이사야 40:31 — 6중 중복
  'v_326', // 이사야 40:31 — 내부 중복
  'v_346', // 갈라디아서 6:9 — 5중 중복 + 번영신학 경계
  'v_341', // 여호수아 1:9 — 3중 중복
  'v_347', // 골로새서 3:23 — 3중 중복
  'v_355', // 빌립보서 4:13 — 3중 중복
  'v_357', // 로마서 8:31 — 4중 중복
];

// 2. verse_full_ko 번역 오류 수정 (C열)
const FULL_KO_FIXES = [
  {
    id: 'v_408',
    ref: '열왕기상 19:7',
    value: '여호와의 사자가 다시 두 번째 와서 어루만지며 이르되 일어나 먹으라 네가 갈 길이 너무 멀다 하는지라',
  },
  {
    id: 'v_409',
    ref: '베드로전서 1:3',
    value: '우리 주 예수 그리스도의 아버지 하나님을 찬송하리로다 그의 많으신 긍휼대로 예수 그리스도의 죽은 자 가운데서 부활하심으로 말미암아 우리를 거듭나게 하사 산 소망이 있게 하시며',
  },
];

// 3. verse_short_ko 원문 발췌 교체 (B열)
// inactive 처리된 항목(v_341, v_346, v_347, v_355, v_357)은 제외
const SHORT_KO_FIXES = [
  { id: 'v_340', ref: '시편 5:3',          value: '여호와여 아침에 나의 소리를 들으시리니' },
  { id: 'v_343', ref: '에스겔 36:26',      value: '새 마음을 너희에게 주되' },
  { id: 'v_344', ref: '역대상 28:20',      value: '일어나 일하라 여호와 하나님이 함께하시느니라' },
  { id: 'v_345', ref: '빌립보서 4:4',      value: '주 안에서 항상 기뻐하라' },
  { id: 'v_348', ref: '이사야 60:1',       value: '일어나라 빛을 발하라' },
  { id: 'v_349', ref: '예레미야 29:11',    value: '평안이요 재앙이 아니라 너희 장래에 소망을 주는 것이니라' },
  { id: 'v_350', ref: '시편 20:7',         value: '우리는 여호와 우리 하나님의 이름을 자랑하리로다' },
  { id: 'v_351', ref: '시편 27:1',         value: '여호와는 나의 빛이요 나의 구원이시니' },
  { id: 'v_352', ref: '시편 118:24',       value: '이것이 여호와의 정하신 날이라' },
  { id: 'v_353', ref: '시편 37:3',         value: '여호와를 의뢰하고 선을 행하라' },
  { id: 'v_354', ref: '시편 100:4',        value: '감사함으로 그 문에 들어가며' },
  { id: 'v_356', ref: '여호수아 1:8',      value: '주야로 그것을 묵상하여 기록한 대로 다 지켜 행하라' },
  { id: 'v_358', ref: '잠언 4:18',         value: '의인의 길은 돋는 햇빛 같아서' },
  { id: 'v_359', ref: '예레미야애가 3:22-23', value: '아침마다 새로우니 주의 성실하심이 크도소이다' },
  { id: 'v_382', ref: '룻기 2:8',          value: '내 밭에서 떠나지 말고 나의 소녀들과 함께 있으라' },
  { id: 'v_391', ref: '시편 37:24',        value: '넘어지는 때에도 여호와께서 손으로 붙드시느니라' },
  { id: 'v_396', ref: '빌립보서 4:8',      value: '참되고 경건하고 옳고 정결한 것을 생각하라' },
  { id: 'v_397', ref: '시편 27:8',         value: '주를 찾으라 하셨으므로 내 마음이 주를 찾나이다' },
  { id: 'v_403', ref: '스바냐 3:5',        value: '의로우신 여호와께서 그 가운데 계시니' },
  { id: 'v_405', ref: '사무엘상 12:22',    value: '여호와께서 자기 백성을 버리지 아니하시리니' },
  { id: 'v_412', ref: '잠언 3:26',         value: '여호와께서 네 발을 지키지 아니하시겠느냐' },
  { id: 'v_413', ref: '시편 77:6',         value: '밤에 나의 노래를 기억하며 마음으로 묵상하고' },
  // 4. 50자 초과 단축
  { id: 'v_402', ref: '아모스 4:13',       value: '산을 지으시며 바람을 창조하시는 여호와시라' },
  { id: 'v_400', ref: '역대하 7:14',       value: '스스로 겸비하고 기도하여 내 얼굴을 구하면' },
  { id: 'v_414', ref: '고린도후서 4:17',   value: '잠시 받는 환난이 영원한 영광을 이루리라' },
];

// ──────────────────────────────────────────────
async function main() {
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  // 1) VERSES 탭 A열 전체 읽어서 verse_id → 행번호 맵 구성
  console.log('VERSES 탭 A열 조회 중...');
  const colARes = await sheets.spreadsheets.values.get({
    spreadsheetId: SPREADSHEET_ID,
    range: `${SHEET}!A:A`,
  });
  const colAValues = colARes.data.values || [];

  const rowMap = {}; // verse_id → row number (1-based)
  colAValues.forEach((row, i) => {
    const id = row[0] && row[0].trim();
    if (id) rowMap[id] = i + 1;
  });

  console.log(`총 ${Object.keys(rowMap).length}개 verse_id 매핑 완료`);

  // 필요한 ID 존재 여부 확인
  const allIds = [
    ...INACTIVE_IDS,
    ...FULL_KO_FIXES.map(f => f.id),
    ...SHORT_KO_FIXES.map(f => f.id),
  ];
  const missingIds = allIds.filter(id => !rowMap[id]);
  if (missingIds.length > 0) {
    console.warn(`경고: 시트에서 찾을 수 없는 ID: ${missingIds.join(', ')}`);
  }

  // 2) batchUpdate 데이터 구성
  const batchData = [];
  const log = []; // 결과 보고용

  // ── 작업 1: inactive 처리 ──────────────────
  for (const id of INACTIVE_IDS) {
    const row = rowMap[id];
    if (!row) { log.push({ id, task: 'inactive', result: 'SKIP (행 없음)' }); continue; }
    batchData.push({
      range: `${SHEET}!${colLetter(COL.status)}${row}`,
      values: [['inactive']],
    });
    log.push({ id, task: 'inactive', result: 'OK', range: `P${row}` });
  }

  // ── 작업 2: verse_full_ko 번역 오류 수정 ──
  for (const fix of FULL_KO_FIXES) {
    const row = rowMap[fix.id];
    if (!row) { log.push({ id: fix.id, task: 'verse_full_ko', result: 'SKIP (행 없음)' }); continue; }
    batchData.push({
      range: `${SHEET}!${colLetter(COL.verse_full_ko)}${row}`,
      values: [[fix.value]],
    });
    log.push({ id: fix.id, ref: fix.ref, task: 'verse_full_ko', result: 'OK', range: `C${row}` });
  }

  // ── 작업 3 & 4: verse_short_ko 교체 ───────
  for (const fix of SHORT_KO_FIXES) {
    const row = rowMap[fix.id];
    if (!row) { log.push({ id: fix.id, task: 'verse_short_ko', result: 'SKIP (행 없음)' }); continue; }
    batchData.push({
      range: `${SHEET}!${colLetter(COL.verse_short_ko)}${row}`,
      values: [[fix.value]],
    });
    log.push({ id: fix.id, ref: fix.ref, task: 'verse_short_ko', result: 'OK', range: `B${row}`, value: fix.value });
  }

  if (batchData.length === 0) {
    console.log('업데이트할 데이터 없음');
    return;
  }

  // 3) Sheets API batchUpdate 실행
  console.log(`\n총 ${batchData.length}개 셀 업데이트 요청 중...`);

  const res = await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SPREADSHEET_ID,
    requestBody: {
      valueInputOption: 'RAW',
      data: batchData,
    },
  });

  console.log(`Sheets API 응답: ${res.data.totalUpdatedCells}개 셀 업데이트됨`);

  // 4) 결과 보고
  console.log('\n======================================================');
  console.log('수정 결과 보고');
  console.log('======================================================');

  const tasks = {
    inactive:       { label: '① inactive 처리',         items: [] },
    verse_full_ko:  { label: '② verse_full_ko 수정',    items: [] },
    verse_short_ko: { label: '③/④ verse_short_ko 교체', items: [] },
  };

  log.forEach(entry => {
    if (tasks[entry.task]) tasks[entry.task].items.push(entry);
  });

  for (const [, group] of Object.entries(tasks)) {
    console.log(`\n${group.label}`);
    group.items.forEach(entry => {
      if (entry.task === 'verse_short_ko') {
        console.log(`  ${entry.result === 'OK' ? '✓' : '!'} ${entry.id} (${entry.ref}) [${entry.range}] → "${entry.value}"`);
      } else {
        console.log(`  ${entry.result === 'OK' ? '✓' : '!'} ${entry.id} ${entry.ref ? `(${entry.ref})` : ''} [${entry.range || '–'}] ${entry.result}`);
      }
    });
  }

  const successCount = log.filter(e => e.result === 'OK').length;
  console.log(`\n총 ${successCount}/${log.length}건 수정 완료`);
  console.log('\nFirestore 동기화 필요 시: node scripts/sync_sheets_to_firestore.js');
}

main().catch(e => {
  console.error('오류:', e.message);
  process.exit(1);
});
