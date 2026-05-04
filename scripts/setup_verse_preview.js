/**
 * setup_verse_preview.js
 *
 * Google Sheets에 VERSE_PREVIEW 탭을 생성하고
 * "적용하기" 버튼 + Apps Script를 설치합니다.
 *
 * 실행:
 *   cd scripts && NODE_TLS_REJECT_UNAUTHORIZED=0 node setup_verse_preview.js
 */

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const admin  = require('firebase-admin');
const { google } = require('googleapis');
const path   = require('path');

const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, './serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const PROJECT_ID = 'dailyverse-9260d';
const REGION     = 'asia-northeast3';

// Cloud Function URL (배포 후 자동 생성)
const BASE_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net`;
const GET_URL   = `${BASE_URL}/getVerseSchedule`;
const APPLY_URL = `${BASE_URL}/applyVerseOverrides`;

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function getSheets() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/script.projects',
    ],
  });
  return google.sheets({ version: 'v4', auth });
}

async function getScript() {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/script.projects'],
  });
  return google.script({ version: 'v1', auth });
}

// ─── 1. VERSE_PREVIEW 탭 생성 ─────────────────────────────────────────────

async function setupPreviewTab(sheets) {
  console.log('\n📋 VERSE_PREVIEW 탭 설정 중...');

  // 기존 탭 확인
  const meta = await sheets.spreadsheets.get({ spreadsheetId: SHEET_ID });
  const existing = meta.data.sheets.find(s => s.properties.title === 'VERSE_PREVIEW');

  let sheetId;
  if (existing) {
    console.log('   VERSE_PREVIEW 탭 이미 존재 — 내용 초기화');
    sheetId = existing.properties.sheetId;
  } else {
    // 탭 생성
    const resp = await sheets.spreadsheets.batchUpdate({
      spreadsheetId: SHEET_ID,
      requestBody: {
        requests: [{
          addSheet: {
            properties: {
              title: 'VERSE_PREVIEW',
              gridProperties: { rowCount: 20, columnCount: 18 },
              tabColor: { red: 0.2, green: 0.6, blue: 1.0 },
            },
          },
        }],
      },
    });
    sheetId = resp.data.replies[0].addSheet.properties.sheetId;
    console.log(`   VERSE_PREVIEW 탭 생성 완료 (sheetId: ${sheetId})`);
  }

  // ─── 헤더 행 작성 ─────────────────────────────────────────────────────
  const headers = [
    'date', 'day', '선택\n(1=auto\n2=alt1\n3=alt2\n4=alt3)',
    'verse_id', 'reference', 'verse_short', 'interpretation',
    'theme', 'show_count', 'last_shown', 'days_since',
    'cooldown_days', 'cooldown_ok',
    'alt_1 (id | 참조 | 노출수 | 최근노출)',
    'alt_2',
    'alt_3',
    'status', 'notes',
  ];

  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: 'VERSE_PREVIEW!A1:R1',
    valueInputOption: 'RAW',
    requestBody: { values: [headers] },
  });

  // 안내 행 (2~4행: D, D+1, D+2 자리표시자)
  const placeholder = [
    ['(로딩 중...)', 'D (오늘)', '1', '', '', '', '', '', '', '', '', '', '', '', '', '', 'scheduled', ''],
    ['(로딩 중...)', 'D+1',      '1', '', '', '', '', '', '', '', '', '', '', '', '', '', 'scheduled', ''],
    ['(로딩 중...)', 'D+2',      '1', '', '', '', '', '', '', '', '', '', '', '', '', '', 'scheduled', ''],
  ];

  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: 'VERSE_PREVIEW!A2:R4',
    valueInputOption: 'RAW',
    requestBody: { values: placeholder },
  });

  // ─── 서식 설정 ────────────────────────────────────────────────────────
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: {
      requests: [
        // 헤더 행 굵게 + 배경색
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 18 },
            cell: {
              userEnteredFormat: {
                backgroundColor: { red: 0.13, green: 0.39, blue: 0.83 },
                textFormat: { bold: true, foregroundColor: { red: 1, green: 1, blue: 1 }, fontSize: 10 },
                horizontalAlignment: 'CENTER',
                wrapStrategy: 'WRAP',
              },
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment,wrapStrategy)',
          },
        },
        // D 행 (2행) — 회색 잠금 배경 (이미 확정)
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 1, endRowIndex: 2, startColumnIndex: 0, endColumnIndex: 18 },
            cell: {
              userEnteredFormat: {
                backgroundColor: { red: 0.9, green: 0.9, blue: 0.9 },
                textFormat: { italic: true, foregroundColor: { red: 0.4, green: 0.4, blue: 0.4 } },
              },
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat)',
          },
        },
        // D+1, D+2 행 — 흰색 배경
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 2, endRowIndex: 4, startColumnIndex: 0, endColumnIndex: 18 },
            cell: {
              userEnteredFormat: {
                backgroundColor: { red: 1, green: 1, blue: 1 },
              },
            },
            fields: 'userEnteredFormat(backgroundColor)',
          },
        },
        // [선택] 컬럼(C) — 노란 배경 강조 (편집 가능한 컬럼)
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 2, endRowIndex: 4, startColumnIndex: 2, endColumnIndex: 3 },
            cell: {
              userEnteredFormat: {
                backgroundColor: { red: 1.0, green: 0.95, blue: 0.6 },
                textFormat: { bold: true, fontSize: 12 },
                horizontalAlignment: 'CENTER',
              },
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
          },
        },
        // [notes] 컬럼 — 연한 녹색
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 2, endRowIndex: 4, startColumnIndex: 17, endColumnIndex: 18 },
            cell: {
              userEnteredFormat: { backgroundColor: { red: 0.9, green: 1.0, blue: 0.9 } },
            },
            fields: 'userEnteredFormat(backgroundColor)',
          },
        },
        // 열 너비 조정
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 0,  endIndex: 1  }, properties: { pixelSize: 90  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 1,  endIndex: 2  }, properties: { pixelSize: 60  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 2,  endIndex: 3  }, properties: { pixelSize: 80  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 3,  endIndex: 4  }, properties: { pixelSize: 80  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 4,  endIndex: 5  }, properties: { pixelSize: 100 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 5,  endIndex: 6  }, properties: { pixelSize: 160 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 6,  endIndex: 7  }, properties: { pixelSize: 200 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 7,  endIndex: 8  }, properties: { pixelSize: 100 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 8,  endIndex: 9  }, properties: { pixelSize: 70  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 9,  endIndex: 10 }, properties: { pixelSize: 90  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 10, endIndex: 11 }, properties: { pixelSize: 70  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 11, endIndex: 12 }, properties: { pixelSize: 70  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 12, endIndex: 13 }, properties: { pixelSize: 70  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 13, endIndex: 14 }, properties: { pixelSize: 220 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 14, endIndex: 15 }, properties: { pixelSize: 220 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 15, endIndex: 16 }, properties: { pixelSize: 220 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 16, endIndex: 17 }, properties: { pixelSize: 80  }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: 17, endIndex: 18 }, properties: { pixelSize: 160 }, fields: 'pixelSize' } },
        // 행 높이
        { updateDimensionProperties: { range: { sheetId, dimension: 'ROWS', startIndex: 0, endIndex: 1 }, properties: { pixelSize: 50 }, fields: 'pixelSize' } },
        { updateDimensionProperties: { range: { sheetId, dimension: 'ROWS', startIndex: 1, endIndex: 4 }, properties: { pixelSize: 60 }, fields: 'pixelSize' } },
        // 행 4 이후 안내 텍스트 행
        { updateDimensionProperties: { range: { sheetId, dimension: 'ROWS', startIndex: 4, endIndex: 8 }, properties: { pixelSize: 30 }, fields: 'pixelSize' } },
        // 열 고정 (첫 2열)
        { updateSheetProperties: { properties: { sheetId, gridProperties: { frozenColumnCount: 2 } }, fields: 'gridProperties.frozenColumnCount' } },
      ],
    },
  });

  // ─── 안내 텍스트 (하단) ──────────────────────────────────────────────
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: 'VERSE_PREVIEW!A6:B12',
    valueInputOption: 'RAW',
    requestBody: {
      values: [
        [''],
        ['📌 사용 방법'],
        ['[선택] 값', '의미'],
        ['1 (또는 빈칸)', 'auto — 알고리즘 선정 그대로 진행'],
        ['2 / 3 / 4', 'alt_1 / alt_2 / alt_3 으로 변경'],
        ['v_xxx 직접 입력', '해당 verse_id로 변경'],
        ['변경 후 → 상단 메뉴 [🔮 말씀 관리] → [적용하기] 클릭', ''],
      ],
    },
  });

  console.log('   ✅ VERSE_PREVIEW 탭 서식 설정 완료');
  return sheetId;
}

// ─── 2. Apps Script 설치 ──────────────────────────────────────────────────

const APPS_SCRIPT_CODE = `
// morning manna — VERSE_PREVIEW 관리 스크립트
// Apps Script 편집기에서 실행됩니다.
// 자동 갱신: 매일 22:30 KST (previewDailyVerses 22:00 실행 후 30분)
// 관리자 검토 창: 22:30 ~ 23:59 KST (약 1.5시간)
// selectDailyVerse 확정: 매일 00:00 KST (자정)

const GET_URL   = '${GET_URL}';
const APPLY_URL = '${APPLY_URL}';

/**
 * 시트 데이터를 Cloud Function에서 새로고침
 * Apps Script 시간 기반 트리거 또는 버튼으로 실행
 */
function refreshVersePreview() {
  try {
    const resp     = UrlFetchApp.fetch(GET_URL, { method: 'get', muteHttpExceptions: true });
    const data     = JSON.parse(resp.getContentText());
    const schedules = data.schedules || [];

    const ss    = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName('VERSE_PREVIEW');
    if (!sheet) { SpreadsheetApp.getUi().alert('VERSE_PREVIEW 탭을 찾을 수 없습니다.'); return; }

    const dayLabels = ['D (오늘)', 'D+1', 'D+2'];

    for (let i = 0; i < Math.min(schedules.length, 3); i++) {
      const s   = schedules[i];
      const row = i + 2; // 2~4행

      // [선택] 컬럼은 기존 값 유지 (사용자가 입력한 값 덮어쓰지 않음)
      const currentSelection = sheet.getRange(row, 3).getValue();

      const values = [
        s.date          || '',
        dayLabels[i],
        currentSelection || 1,  // 기존 선택 유지
        s.verse_id      || '',
        s.reference     || '',
        s.verse_short   || '',
        s.interpretation|| '',
        s.theme         || '',
        s.show_count    != null ? s.show_count : '',
        s.last_shown    || '',
        s.days_since    != null ? s.days_since : '',
        s.cooldown_days != null ? s.cooldown_days : '',
        s.cooldown_ok === true ? '✅ OK' : (s.cooldown_ok === false ? '⚠️ 짧음' : ''),
        s.alt_1 || '',
        s.alt_2 || '',
        s.alt_3 || '',
        s.status || '',
        sheet.getRange(row, 18).getValue() || '',  // notes 기존 값 유지
      ];

      sheet.getRange(row, 1, 1, values.length).setValues([values]);
    }

    SpreadsheetApp.getUi().alert('✅ 말씀 미리보기 새로고침 완료 (' + new Date().toLocaleString('ko-KR') + ')');
  } catch (e) {
    SpreadsheetApp.getUi().alert('❌ 오류: ' + e.message);
  }
}

/**
 * 변경사항을 Firestore에 적용
 * "적용하기" 버튼으로 실행
 */
function applyVerseOverrides() {
  const ss    = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName('VERSE_PREVIEW');
  if (!sheet) { SpreadsheetApp.getUi().alert('VERSE_PREVIEW 탭을 찾을 수 없습니다.'); return; }

  const ui = SpreadsheetApp.getUi();

  // D+1, D+2 행만 처리 (행 3~4, index 2~3)
  const overrides = [];
  for (let row = 3; row <= 4; row++) {
    const date      = sheet.getRange(row, 1).getValue();
    const selection = sheet.getRange(row, 3).getValue();
    const notes     = sheet.getRange(row, 18).getValue();
    if (!date) continue;
    overrides.push({
      date:      String(date).trim(),
      selection: selection || 1,
      notes:     String(notes || ''),
    });
  }

  if (overrides.length === 0) {
    ui.alert('적용할 변경사항이 없습니다.');
    return;
  }

  // 확인 메시지
  const preview = overrides.map(o =>
    o.selection == 1 || o.selection === '' ? \`\${o.date}: auto 유지\`
    : \`\${o.date}: 선택 \${o.selection} 적용\`
  ).join('\\n');

  const confirm = ui.alert('적용 확인', preview + '\\n\\n진행하시겠습니까?', ui.ButtonSet.YES_NO);
  if (confirm !== ui.Button.YES) return;

  try {
    const payload = JSON.stringify({ overrides });
    const resp = UrlFetchApp.fetch(APPLY_URL, {
      method: 'post',
      contentType: 'application/json',
      payload: payload,
      muteHttpExceptions: true,
    });

    const result  = JSON.parse(resp.getContentText());
    const results = result.results || [];
    const summary = results.map(r =>
      r.status === 'ok'
        ? \`✅ \${r.date}: \${r.reference} (\${r.is_override ? 'override' : 'auto 유지'})\`
        : \`❌ \${r.date}: \${r.message}\`
    ).join('\\n');

    // 시트 상태 업데이트
    for (const r of results) {
      if (r.status !== 'ok') continue;
      for (let row = 2; row <= 4; row++) {
        const rowDate = sheet.getRange(row, 1).getValue();
        if (String(rowDate).trim() === r.date) {
          sheet.getRange(row, 17).setValue(r.is_override ? 'override' : 'scheduled');
          sheet.getRange(row, 4).setValue(r.verse_id || '');
          sheet.getRange(row, 5).setValue(r.reference || '');
          break;
        }
      }
    }

    ui.alert('적용 완료', summary, ui.ButtonSet.OK);
  } catch (e) {
    ui.alert('❌ 오류: ' + e.message);
  }
}

/**
 * 메뉴에 등록
 */
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔮 말씀 관리')
    .addItem('새로고침 (미리보기 갱신)', 'refreshVersePreview')
    .addSeparator()
    .addItem('✅ 적용하기 (변경사항 저장)', 'applyVerseOverrides')
    .addToUi();
}

/**
 * 시간 기반 자동 트리거 설정 (매일 22:30 KST)
 * 최초 1회 수동 실행 필요
 */
function setupTimeTrigger() {
  // 기존 트리거 삭제
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(t => {
    if (t.getHandlerFunction() === 'refreshVersePreview') {
      ScriptApp.deleteTrigger(t);
    }
  });
  // 새 트리거 등록 (22:30 KST = 13:30 UTC)
  // previewDailyVerses(22:00 KST) 완료 후 30분 뒤 시트 갱신
  ScriptApp.newTrigger('refreshVersePreview')
    .timeBased()
    .atHour(22)
    .nearMinute(30)
    .everyDays(1)
    .inTimezone('Asia/Seoul')
    .create();
  SpreadsheetApp.getUi().alert('✅ 매일 22:30 KST 자동 갱신 트리거 설정 완료');
}
`;

async function setupAppsScript(sheets) {
  console.log('\n📝 Apps Script 코드 시트에 저장 중...');

  // Apps Script는 Google Apps Script API가 필요해서 직접 설치가 복잡함.
  // 대신 시트에 코드를 텍스트로 저장해두고 설치 가이드 제공.
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: 'VERSE_PREVIEW!A14:A14',
    valueInputOption: 'RAW',
    requestBody: {
      values: [['── Apps Script 설치 가이드 (아래 참조) ──']],
    },
  });

  // 별도 시트에 코드 저장
  const meta = await sheets.spreadsheets.get({ spreadsheetId: SHEET_ID });
  const codeSheet = meta.data.sheets.find(s => s.properties.title === 'VERSE_SCRIPT');
  if (!codeSheet) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: SHEET_ID,
      requestBody: {
        requests: [{
          addSheet: {
            properties: {
              title: 'VERSE_SCRIPT',
              gridProperties: { rowCount: 200, columnCount: 2 },
              tabColor: { red: 0.6, green: 0.8, blue: 0.4 },
            },
          },
        }],
      },
    });
  }

  const lines = APPS_SCRIPT_CODE.split('\n');
  const rows  = lines.map(l => [l]);
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: `VERSE_SCRIPT!A1:A${rows.length}`,
    valueInputOption: 'RAW',
    requestBody: { values: rows },
  });

  console.log('   ✅ Apps Script 코드 VERSE_SCRIPT 탭에 저장됨');
  console.log('\n   📋 Apps Script 설치 방법:');
  console.log('   1. Google Sheets 열기 → 확장 프로그램 → Apps Script');
  console.log('   2. VERSE_SCRIPT 탭의 코드를 복사하여 Apps Script 편집기에 붙여넣기');
  console.log('   3. 저장 → 실행 → onOpen (최초 1회 권한 허용)');
  console.log('   4. 시트로 돌아오면 상단에 [🔮 말씀 관리] 메뉴가 생성됨');
  console.log('   5. [🔮 말씀 관리] → setupTimeTrigger 실행 (매일 22:30 자동 갱신 등록)');
}

// ─── 메인 ──────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n🔧 VERSE_PREVIEW 설정 시작\n');

  const sheets = await getSheets();

  await setupPreviewTab(sheets);
  await setupAppsScript(sheets);

  console.log('\n✅ 설정 완료!');
  console.log('\n다음 단계:');
  console.log('  1. Firebase Functions 배포 (완료 후 자동 실행)');
  console.log('  2. Google Sheets → 확장 프로그램 → Apps Script → VERSE_SCRIPT 탭 코드 붙여넣기');
  console.log('  3. Apps Script에서 onOpen 실행 (최초 권한 허용)');
  console.log('  4. setupTimeTrigger 실행 (매일 22:30 자동 갱신 등록)');
  process.exit(0);
}

main().catch(e => {
  console.error('❌ 오류:', e.message);
  process.exit(1);
});
