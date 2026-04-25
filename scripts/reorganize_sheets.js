/**
 * reorganize_sheets.js — 스프레드시트 전체 구조 정비
 *
 * 실행 항목:
 *  1. OVERVIEW 탭 신규 생성 (맨 왼쪽)
 *  2. ZONE_GUIDE 탭 신규 생성 (TAG_GUIDE에서 분리)
 *  3. 탭 순서 재배치 (그룹별: 개요·데이터·분석·가이드·로그)
 *  4. 탭 색상 적용 (그룹별)
 *  5. 전체 폰트·크기 규칙 적용 (Google Sans, 헤더 11pt bold, 데이터 10pt)
 *  6. 이미지 미리보기 열 추가 (VERSE_IMAGES·BACKGROUND_IMAGES·DAILY_CARDS_IMAGES)
 *  7. 행 높이 조정 (이미지 탭 120px, 일반 탭 22px)
 *  8. STATS 수식 자동화
 *
 * 사용법:
 *   node reorganize_sheets.js
 */

require('dotenv').config();
const { google } = require('googleapis');
const key = require('./serviceAccountKey.json');

const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';

// ─── 색상 상수 ────────────────────────────────────────────────────────────────

const rgb = (hex) => ({
  red:   parseInt(hex.slice(1,3), 16) / 255,
  green: parseInt(hex.slice(3,5), 16) / 255,
  blue:  parseInt(hex.slice(5,7), 16) / 255,
});

const TAB_COLORS = {
  overview: rgb('#90A4AE'),
  data:     rgb('#81C784'),
  analysis: rgb('#FFB74D'),
  guide:    rgb('#64B5F6'),
  log:      rgb('#E57373'),
};

const HEADER_BG = {
  overview: rgb('#37474F'),
  data:     rgb('#1B5E20'),
  analysis: rgb('#BF360C'),
  guide:    rgb('#0D47A1'),
  log:      rgb('#880E4F'),
};

const WHITE  = rgb('#FFFFFF');
const NEAR_BLACK = rgb('#212121');
const LIGHT_GRAY = rgb('#F8F9FA');
const MID_GRAY   = rgb('#ECEFF1');

// ─── 탭 정의 (최종 순서) ─────────────────────────────────────────────────────

const TAB_ORDER = [
  // [탭명, 그룹, 이미지탭여부]
  ['OVERVIEW',           'overview',  false],
  ['VERSES',             'data',      false],
  ['HOME_GREETINGS',     'data',      false],
  ['ALARM_GREETINGS',    'data',      false],
  ['DAILY_CARDS',        'data',      false],
  ['VERSE_IMAGES',       'data',      true ],
  ['BACKGROUND_IMAGES',  'data',      true ],
  ['DAILY_CARDS_IMAGES', 'data',      true ],
  ['STATS',              'analysis',  false],
  ['IMAGE_ASSETS',       'analysis',  false],
  ['CONTENT_MAP',        'analysis',  false],
  ['SCREEN_MAP',         'analysis',  false],
  ['LLM_GUIDE',          'guide',     false],
  ['TAG_GUIDE',          'guide',     false],
  ['ZONE_GUIDE',         'guide',     false],
  ['GREETING_GUIDE',     'guide',     false],
  ['IMAGE_GUIDE',        'guide',     false],
  ['DAILY_CARDS_GUIDE',  'guide',     false],
  ['QA_LOG',             'log',       false],
  ['CHANGELOG',          'log',       false],
];

// 이미지 탭별 storage_url 열 (A=0 기준 0-indexed)
const IMAGE_URL_COL = {
  'VERSE_IMAGES':       1,  // B열 = storage_url
  'BACKGROUND_IMAGES':  2,  // C열 = storage_url
  'DAILY_CARDS_IMAGES': 3,  // D열 = storage_url
};

// ─── 초기화 ───────────────────────────────────────────────────────────────────

async function initSheets() {
  const auth = new google.auth.GoogleAuth({
    credentials: key,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  return google.sheets({ version: 'v4', auth: await auth.getClient() });
}

async function getMeta(sheets) {
  const res = await sheets.spreadsheets.get({ spreadsheetId: SHEET_ID });
  const map = {};
  res.data.sheets.forEach(s => {
    map[s.properties.title] = s.properties.sheetId;
  });
  return map;
}

async function batch(sheets, requests) {
  if (!requests.length) return;
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: { requests },
  });
}

async function writeValues(sheets, range, values) {
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID, range,
    valueInputOption: 'USER_ENTERED',
    requestBody: { values },
  });
}

async function clearRange(sheets, range) {
  await sheets.spreadsheets.values.clear({ spreadsheetId: SHEET_ID, range });
}

// ─── Step 1: OVERVIEW 탭 생성 + 내용 작성 ────────────────────────────────────

const OVERVIEW_CONTENT = [
  ['morning manna 스프레드시트 가이드'],
  ['Single Source of Truth — 모든 콘텐츠 편집은 Sheets에서. Firestore는 읽기 전용.'],
  [],
  ['📦 데이터 탭 (초록)','실제 콘텐츠 원본. 이 탭들을 편집합니다.'],
  ['  VERSES','홈·알람·묵상 말씀 (417개 active)'],
  ['  HOME_GREETINGS','홈 화면 Zone 인사말 (134개)'],
  ['  ALARM_GREETINGS','알람 Stage2 인사말 (35개)'],
  ['  DAILY_CARDS','절기 편성 — 날짜별 특별 말씀+이미지'],
  ['  VERSE_IMAGES','감성 이미지 메타데이터 (95개, img_001~095)'],
  ['  BACKGROUND_IMAGES','Zone 고정 배경 (20개, Zone당 다중+날씨별)'],
  ['  DAILY_CARDS_IMAGES','절기 이미지 에셋 (dc_img_*)'],
  [],
  ['📊 분석 탭 (주황)','통계 및 현황 요약. 데이터 탭 변경 시 자동 반영.'],
  ['  STATS','콘텐츠 현황 대시보드 (수식 자동화)'],
  ['  IMAGE_ASSETS','전체 이미지 에셋 목록'],
  ['  CONTENT_MAP','콘텐츠 타입별 개요 (스크립트 갱신)'],
  ['  SCREEN_MAP','화면×필드 매핑 (스크립트 갱신)'],
  [],
  ['📚 가이드 탭 (파랑)','작성 규칙 및 기준. 콘텐츠 생성 시 참조.'],
  ['  LLM_GUIDE','Claude 프롬프트 공식 가이드 (v9.1)'],
  ['  TAG_GUIDE','theme·mood·tone 태그 기준 (v1.2)'],
  ['  ZONE_GUIDE','8-Zone 컨텍스트 (시간대·감성·역할)'],
  ['  GREETING_GUIDE','홈·알람 인사말 작성 기준'],
  ['  IMAGE_GUIDE','Zone 배경·말씀 배경 이미지 생성 가이드'],
  ['  DAILY_CARDS_GUIDE','절기 편성 시스템 운영 가이드'],
  [],
  ['📋 로그 탭 (빨강)','변경 이력 및 QA 기록. 직접 편집 금지.'],
  ['  QA_LOG','콘텐츠 QA 자동 기록'],
  ['  CHANGELOG','DB·스키마·가이드 버전 이력'],
  [],
  ['━━━ 데이터 정책 ━━━'],
  ['Sheets = 읽기/쓰기','모든 콘텐츠 편집은 여기서'],
  ['Firestore = 읽기 전용','sync 스크립트로만 반영'],
  [],
  ['━━━ Firestore 동기화 스크립트 ━━━'],
  ['말씀','node scripts/sync_verses.js'],
  ['홈 인사말','node scripts/sync_home_greetings.js'],
  ['알람 인사말','node scripts/upload_alarm_greetings.js'],
  ['이미지 (design_test/)','🖼️ 이미지 업로드.command 더블클릭'],
  ['Zone 배경 (zone-backgrounds/)','🌅 배경이미지 업로드.command 더블클릭'],
  ['분석탭 재생성','node scripts/setup_content_schema_sheets.js'],
];

async function createOrGetTab(sheets, title) {
  const meta = await getMeta(sheets);
  if (meta[title]) return meta[title];
  const res = await sheets.spreadsheets.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: { requests: [{ addSheet: { properties: { title } } }] },
  });
  return res.data.replies[0].addSheet.properties.sheetId;
}

// ─── Step 2: TAG_GUIDE 분리 → ZONE_GUIDE ─────────────────────────────────────

async function splitZoneGuide(sheets) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: 'TAG_GUIDE!A1:Z200',
  });
  const rows = res.data.values || [];
  const splitIdx = rows.findIndex((r, i) => i > 0 && r[0] && r[0].includes('ZONE_GUIDE'));
  if (splitIdx === -1) {
    console.log('  TAG_GUIDE에 ZONE_GUIDE 섹션 없음 — 건너뜀');
    return;
  }
  const tagRows  = rows.slice(0, splitIdx);
  const zoneRows = rows.slice(splitIdx);
  // TAG_GUIDE 덮어쓰기 (TAG 내용만)
  await clearRange(sheets, 'TAG_GUIDE!A1:Z200');
  if (tagRows.length) await writeValues(sheets, 'TAG_GUIDE!A1', tagRows);
  // ZONE_GUIDE 탭 생성 후 내용 이동
  await createOrGetTab(sheets, 'ZONE_GUIDE');
  await clearRange(sheets, 'ZONE_GUIDE!A1:Z200');
  if (zoneRows.length) await writeValues(sheets, 'ZONE_GUIDE!A1', zoneRows);
  console.log(`  TAG_GUIDE(${tagRows.length}행) + ZONE_GUIDE(${zoneRows.length}행) 분리 완료`);
}

// ─── Step 3: 탭 순서 재배치 ──────────────────────────────────────────────────

async function reorderTabs(sheets) {
  for (let targetIdx = 0; targetIdx < TAB_ORDER.length; targetIdx++) {
    const [title] = TAB_ORDER[targetIdx];
    const meta = await getMeta(sheets);
    if (!meta[title]) { console.log(`  [건너뜀] ${title} 없음`); continue; }
    const sheetId = meta[title];
    await batch(sheets, [{
      updateSheetProperties: {
        properties: { sheetId, index: targetIdx },
        fields: 'index',
      },
    }]);
    process.stdout.write(`  ${targetIdx + 1}. ${title}\n`);
  }
}

// ─── Step 4: 탭 색상 + 폰트 전체 적용 ───────────────────────────────────────

function headerFormatReq(sheetId, group, numCols) {
  return {
    repeatCell: {
      range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: numCols },
      cell: {
        userEnteredFormat: {
          backgroundColor: HEADER_BG[group],
          textFormat: {
            fontFamily: 'Google Sans',
            fontSize: 11,
            bold: true,
            foregroundColor: WHITE,
          },
          verticalAlignment: 'MIDDLE',
          wrapStrategy: 'CLIP',
        },
      },
      fields: 'userEnteredFormat(backgroundColor,textFormat,verticalAlignment,wrapStrategy)',
    },
  };
}

function dataFormatReq(sheetId, maxRows = 1000, maxCols = 26) {
  return {
    repeatCell: {
      range: { sheetId, startRowIndex: 1, endRowIndex: maxRows, startColumnIndex: 0, endColumnIndex: maxCols },
      cell: {
        userEnteredFormat: {
          textFormat: {
            fontFamily: 'Google Sans',
            fontSize: 10,
            bold: false,
            foregroundColor: NEAR_BLACK,
          },
          verticalAlignment: 'MIDDLE',
          wrapStrategy: 'WRAP',
        },
      },
      fields: 'userEnteredFormat(textFormat,verticalAlignment,wrapStrategy)',
    },
  };
}

function bandingReq(sheetId, numCols, group) {
  return {
    addBanding: {
      bandedRange: {
        range: { sheetId, startRowIndex: 0, endRowIndex: 1000, startColumnIndex: 0, endColumnIndex: numCols },
        rowProperties: {
          headerColor:      HEADER_BG[group],
          firstBandColor:   WHITE,
          secondBandColor:  LIGHT_GRAY,
        },
      },
    },
  };
}

function freezeReq(sheetId, rows = 1, cols = 0) {
  return {
    updateSheetProperties: {
      properties: { sheetId, gridProperties: { frozenRowCount: rows, frozenColumnCount: cols } },
      fields: 'gridProperties.frozenRowCount,gridProperties.frozenColumnCount',
    },
  };
}

function tabColorReq(sheetId, group) {
  return {
    updateSheetProperties: {
      properties: { sheetId, tabColor: TAB_COLORS[group] },
      fields: 'tabColor',
    },
  };
}

function rowHeightReq(sheetId, pixelSize, startRow = 1, endRow = 1000) {
  return {
    updateDimensionProperties: {
      range: { sheetId, dimension: 'ROWS', startIndex: startRow, endIndex: endRow },
      properties: { pixelSize },
      fields: 'pixelSize',
    },
  };
}

function colWidthReq(sheetId, startCol, endCol, pixelSize) {
  return {
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: startCol, endIndex: endCol },
      properties: { pixelSize },
      fields: 'pixelSize',
    },
  };
}

// ─── Step 5: 이미지 미리보기 열 ──────────────────────────────────────────────

const COL_LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

async function getDataRowCount(sheets, tabName) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${tabName}!A:A`,
  });
  return (res.data.values || []).length;
}

async function addImagePreview(sheets, tabName, sheetId, urlColIdx) {
  const rowCount = await getDataRowCount(sheets, tabName);
  const previewColLetter = COL_LETTERS[urlColIdx + 10]; // url col + offset to far right
  // 실제 마지막 유효 열 계산: 각 탭의 헤더 열 수 + 1
  const headerRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID, range: `${tabName}!1:1`,
  });
  const headerCount = (headerRes.data.values?.[0] || []).length;
  const previewColIdx = headerCount; // 0-indexed: 헤더 다음 열
  const previewColLet = previewColIdx < 26 ? COL_LETTERS[previewColIdx] : 'R';
  const urlColLet     = COL_LETTERS[urlColIdx];

  // 헤더 'preview' 추가
  await writeValues(sheets, `${tabName}!${previewColLet}1`, [['preview']]);

  // IMAGE() 수식 배열 작성 (행 2~rowCount)
  const formulaRows = [];
  for (let r = 2; r <= Math.max(rowCount, 2); r++) {
    formulaRows.push([`=IF(${urlColLet}${r}<>"",IMAGE(${urlColLet}${r}),"")`]);
  }
  if (formulaRows.length) {
    await writeValues(sheets, `${tabName}!${previewColLet}2`, formulaRows);
  }

  // 미리보기 열 포맷 (center align)
  const requests = [
    // preview 열 정렬
    {
      repeatCell: {
        range: { sheetId, startRowIndex: 1, endRowIndex: rowCount + 1, startColumnIndex: previewColIdx, endColumnIndex: previewColIdx + 1 },
        cell: { userEnteredFormat: { horizontalAlignment: 'CENTER', verticalAlignment: 'MIDDLE' } },
        fields: 'userEnteredFormat(horizontalAlignment,verticalAlignment)',
      },
    },
    // 미리보기 열 너비 120px
    colWidthReq(sheetId, previewColIdx, previewColIdx + 1, 120),
  ];
  await batch(sheets, requests);
  console.log(`  ${tabName}: preview 열(${previewColLet}) + IMAGE() 수식 ${formulaRows.length}행`);
}

// ─── Step 6: STATS 수식 자동화 ────────────────────────────────────────────────

const STATS_CONTENT = [
  ['📊 morning manna 콘텐츠 현황 대시보드'],
  ['업데이트: 자동 (데이터 탭 변경 시 실시간 반영)'],
  [],
  ['━━━ 📌 섹션 1. 전체 요약 ━━━'],
  ['항목', '전체', 'active', '비고'],
  ['말씀 (VERSES)', '=COUNTA(VERSES!A2:A)', '=COUNTIF(VERSES!P2:P,"active")', '홈·알람·묵상 공통'],
  ['홈 인사말', '=COUNTA(HOME_GREETINGS!A2:A)', '', 'Zone(8)×언어(ko/en)'],
  ['알람 인사말', '=COUNTA(ALARM_GREETINGS!A2:A)', '', 'Stage2 팝업'],
  ['절기 편성', '=COUNTA(DAILY_CARDS!A2:A)', '=COUNTIF(DAILY_CARDS!H2:H,"TRUE")', '날짜별 특별 말씀'],
  ['감성 이미지', '=COUNTA(VERSE_IMAGES!A2:A)', '=COUNTIF(VERSE_IMAGES!L2:L,"active")', 'img_001~095'],
  ['Zone 배경', '=COUNTA(BACKGROUND_IMAGES!A2:A)', '=COUNTIF(BACKGROUND_IMAGES!G2:G,"active")', 'Zone당 다중'],
  ['절기 이미지', '=COUNTA(DAILY_CARDS_IMAGES!A2:A)', '', 'dc_img_*'],
  [],
  ['━━━ 📌 섹션 2. Zone별 말씀 분포 ━━━'],
  ['Zone', 'ID', '말씀 수 (active)'],
  ['🌑 Deep Dark (00–03시)', 'deep_dark', '=SUMPRODUCT((ISNUMBER(SEARCH("deep_dark",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['🌒 First Light (03–06시)', 'first_light', '=SUMPRODUCT((ISNUMBER(SEARCH("first_light",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['🌅 Rise & Ignite (06–09시)', 'rise_ignite', '=SUMPRODUCT((ISNUMBER(SEARCH("rise_ignite",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['⚡ Peak Mode (09–12시)', 'peak_mode', '=SUMPRODUCT((ISNUMBER(SEARCH("peak_mode",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['☀️ Recharge (12–15시)', 'recharge', '=SUMPRODUCT((ISNUMBER(SEARCH("recharge",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['🌤 Second Wind (15–18시)', 'second_wind', '=SUMPRODUCT((ISNUMBER(SEARCH("second_wind",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['🌇 Golden Hour (18–21시)', 'golden_hour', '=SUMPRODUCT((ISNUMBER(SEARCH("golden_hour",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['🌙 Wind Down (21–24시)', 'wind_down', '=SUMPRODUCT((ISNUMBER(SEARCH("wind_down",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  ['(전 Zone 공통)', 'all', '=SUMPRODUCT((ISNUMBER(SEARCH("all",VERSES!H2:H500)))*(VERSES!P2:P500="active"))'],
  [],
  ['━━━ 📌 섹션 3. Zone별 이미지 분포 ━━━'],
  ['Zone', '감성 이미지 (VERSE_IMAGES)', 'Zone 배경 (BACKGROUND_IMAGES)'],
  ['deep_dark',   '=COUNTIF(VERSE_IMAGES!F2:F,"deep_dark")',   '=COUNTIF(BACKGROUND_IMAGES!D2:D,"deep_dark")'],
  ['first_light', '=COUNTIF(VERSE_IMAGES!F2:F,"first_light")', '=COUNTIF(BACKGROUND_IMAGES!D2:D,"first_light")'],
  ['rise_ignite', '=COUNTIF(VERSE_IMAGES!F2:F,"rise_ignite")', '=COUNTIF(BACKGROUND_IMAGES!D2:D,"rise_ignite")'],
  ['peak_mode',   '=COUNTIF(VERSE_IMAGES!F2:F,"peak_mode")',   '=COUNTIF(BACKGROUND_IMAGES!D2:D,"peak_mode")'],
  ['recharge',    '=COUNTIF(VERSE_IMAGES!F2:F,"recharge")',    '=COUNTIF(BACKGROUND_IMAGES!D2:D,"recharge")'],
  ['second_wind', '=COUNTIF(VERSE_IMAGES!F2:F,"second_wind")', '=COUNTIF(BACKGROUND_IMAGES!D2:D,"second_wind")'],
  ['golden_hour', '=COUNTIF(VERSE_IMAGES!F2:F,"golden_hour")', '=COUNTIF(BACKGROUND_IMAGES!D2:D,"golden_hour")'],
  ['wind_down',   '=COUNTIF(VERSE_IMAGES!F2:F,"wind_down")',   '=COUNTIF(BACKGROUND_IMAGES!D2:D,"wind_down")'],
];

// ─── 메인 ─────────────────────────────────────────────────────────────────────

async function main() {
  const sheets = await initSheets();
  console.log('\n🎨 morning manna 스프레드시트 구조 정비 시작\n');

  // ── 1. ZONE_GUIDE 분리 ────────────────────────────────────────────────────
  console.log('1️⃣  TAG_GUIDE → ZONE_GUIDE 분리');
  await splitZoneGuide(sheets);

  // ── 2. OVERVIEW 생성 + 내용 작성 ─────────────────────────────────────────
  console.log('\n2️⃣  OVERVIEW 탭 생성');
  await createOrGetTab(sheets, 'OVERVIEW');
  await clearRange(sheets, 'OVERVIEW!A1:D100');
  await writeValues(sheets, 'OVERVIEW!A1', OVERVIEW_CONTENT);
  console.log(`  OVERVIEW: ${OVERVIEW_CONTENT.length}행 작성`);

  // ── 3. STATS 수식 자동화 ─────────────────────────────────────────────────
  console.log('\n3️⃣  STATS 수식 자동화');
  await clearRange(sheets, 'STATS!A1:D100');
  await writeValues(sheets, 'STATS!A1', STATS_CONTENT);
  console.log(`  STATS: ${STATS_CONTENT.length}행 (수식 포함)`);

  // ── 4. 탭 순서 재배치 ────────────────────────────────────────────────────
  console.log('\n4️⃣  탭 순서 재배치');
  await reorderTabs(sheets);

  // ── 5. 탭 색상 + 포맷 일괄 적용 ──────────────────────────────────────────
  console.log('\n5️⃣  탭 색상 + 폰트 규칙 적용');
  const meta = await getMeta(sheets);

  const formatRequests = [];

  for (const [title, group, isImageTab] of TAB_ORDER) {
    const sheetId = meta[title];
    if (!sheetId && sheetId !== 0) { console.log(`  [건너뜀] ${title}`); continue; }

    const numCols = isImageTab ? 20 : 26;

    // 탭 색상
    formatRequests.push(tabColorReq(sheetId, group));
    // 헤더 행 포맷
    formatRequests.push(headerFormatReq(sheetId, group, numCols));
    // 데이터 영역 폰트
    formatRequests.push(dataFormatReq(sheetId, 1000, numCols));
    // 헤더 행 높이 28px
    formatRequests.push({ updateDimensionProperties: {
      range: { sheetId, dimension: 'ROWS', startIndex: 0, endIndex: 1 },
      properties: { pixelSize: 28 }, fields: 'pixelSize',
    }});
    // 데이터 행 높이: 이미지 탭 120px, 나머지 22px
    formatRequests.push(rowHeightReq(sheetId, isImageTab ? 120 : 22, 1, 200));
    // 행 고정
    formatRequests.push(freezeReq(sheetId, 1, 0));
    process.stdout.write(`  ${title} (${group})\n`);
  }

  // STATS 특별 처리: 섹션 헤더 행을 분석 그룹 색상으로
  const statsId = meta['STATS'];
  if (statsId) {
    // 섹션 헤더 행들 (row 4, 14, 29 → 0-indexed: 3, 13, 28)
    [3, 13, 28].forEach(rowIdx => {
      formatRequests.push({
        repeatCell: {
          range: { sheetId: statsId, startRowIndex: rowIdx, endRowIndex: rowIdx + 1, startColumnIndex: 0, endColumnIndex: 4 },
          cell: { userEnteredFormat: {
            backgroundColor: rgb('#E65100'),
            textFormat: { fontFamily: 'Google Sans', fontSize: 10, bold: true, foregroundColor: WHITE },
          }},
          fields: 'userEnteredFormat(backgroundColor,textFormat)',
        },
      });
    });
  }

  // OVERVIEW 특별 처리: 제목 행 크게
  const overviewId = meta['OVERVIEW'];
  if (overviewId) {
    formatRequests.push({
      repeatCell: {
        range: { sheetId: overviewId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 4 },
        cell: { userEnteredFormat: {
          backgroundColor: HEADER_BG['overview'],
          textFormat: { fontFamily: 'Google Sans', fontSize: 14, bold: true, foregroundColor: WHITE },
        }},
        fields: 'userEnteredFormat(backgroundColor,textFormat)',
      },
    });
    formatRequests.push({ updateDimensionProperties: {
      range: { sheetId: overviewId, dimension: 'ROWS', startIndex: 0, endIndex: 1 },
      properties: { pixelSize: 40 }, fields: 'pixelSize',
    }});
    // A열 너비 200px, B열 너비 400px
    formatRequests.push(colWidthReq(overviewId, 0, 1, 200));
    formatRequests.push(colWidthReq(overviewId, 1, 2, 400));
  }

  // SCREEN_MAP: 첫 열 고정 (가로 스크롤 많음)
  const screenMapId = meta['SCREEN_MAP'];
  if (screenMapId) formatRequests.push(freezeReq(screenMapId, 1, 1));

  await batch(sheets, formatRequests);
  console.log(`  ✅ ${formatRequests.length}개 포맷 요청 적용`);

  // ── 6. 이미지 미리보기 열 ─────────────────────────────────────────────────
  console.log('\n6️⃣  이미지 미리보기 열 추가');
  for (const [tabName, urlColIdx] of Object.entries(IMAGE_URL_COL)) {
    const sheetId = meta[tabName];
    if (!sheetId && sheetId !== 0) continue;
    await addImagePreview(sheets, tabName, sheetId, urlColIdx);
  }

  // ── 완료 ──────────────────────────────────────────────────────────────────
  console.log('\n✨ 완료!');
  console.log('   https://docs.google.com/spreadsheets/d/' + SHEET_ID + '/edit');
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
