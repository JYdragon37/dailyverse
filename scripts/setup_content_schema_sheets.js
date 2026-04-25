/**
 * setup_content_schema_sheets.js
 *
 * Google Spreadsheet에 콘텐츠 스키마 문서 탭 3개를 생성합니다.
 *   1. CONTENT_MAP   — 콘텐츠 타입별 개요 (타입·Sheets탭·DB컬렉션·현황·동기화 스크립트)
 *   2. SCREEN_MAP    — 화면별 표시 필드 매핑 (어떤 화면에서 어떤 필드가 쓰이는지)
 *   3. IMAGE_ASSETS  — 앱에서 사용하는 모든 이미지 에셋 목록
 *
 * 사용법:
 *   node setup_content_schema_sheets.js
 *
 * 주의: 기존 탭이 있으면 내용을 덮어씁니다 (탭 재생성).
 */

const { google } = require('googleapis');
const key = require('./serviceAccountKey.json');

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';

// ─── 색상 헬퍼 ────────────────────────────────────────────────────────────────

const rgb = (r, g, b) => ({ red: r / 255, green: g / 255, blue: b / 255 });

const COLORS = {
  headerBg:    rgb(30, 30, 40),
  headerFg:    rgb(255, 255, 255),
  sectionBg:   rgb(45, 45, 60),
  altRowBg:    rgb(245, 245, 252),
  accent:      rgb(100, 140, 255),
  green:       rgb(52, 168, 83),
  orange:      rgb(251, 140, 0),
  red:         rgb(220, 60, 60),
  hcBg:        rgb(255, 248, 230),   // 하드코딩 행 배경
  dbBg:        rgb(230, 245, 255),   // DB 연동 행 배경
  white:       rgb(255, 255, 255),
};

// ─── 탭 1: CONTENT_MAP ────────────────────────────────────────────────────────

const CONTENT_MAP_ROWS = [
  // 헤더
  ['콘텐츠 타입', 'Sheets 탭', 'Firestore 컬렉션', '쓰기 방향', '동기화 스크립트', '현황', '설명', '주요 필드'],

  // 텍스트 콘텐츠
  ['말씀 (VERSES)', 'VERSES', 'verses/', 'Sheets → DB', 'sync_verses.js', 'active 417개 (v_001~v_431)', '홈·알람·묵상 전 화면에서 사용하는 성경 말씀', 'verse_short_ko, verse_full_ko, reference, interpretation, application, alarm_top_ko, question, theme'],
  ['홈 인사말', 'HOME_GREETINGS', 'greetings/', 'Sheets → DB', 'sync_home_greetings.js', '134개', '홈 탭 상단 시간대별 인사말', 'zone_id, language, text, gr_id'],
  ['알람 인사말', 'ALARM_GREETINGS', 'alarm_greetings/', 'Sheets → DB', 'upload_alarm_greetings.js', '35개', '알람 Stage 2 웰컴 스크린 인사말', 'zone_id, language, text, gr_id'],
  ['절기 편성', 'DAILY_CARDS', 'daily_cards/', 'Sheets → DB', '(수동)', '12개 (2026년)', '크리스마스·부활절 등 특정 날짜 전체 유저 강제 적용', 'verse_id, image_id, greeting_ko, greeting_en, event_name'],
  ['', '', '', '', '', '', '', ''],

  // 이미지 콘텐츠
  ['감성 이미지', 'VERSE_IMAGES', 'images/', 'Sheets → DB', 'sync_verse_images.js', 'active 49개', '알람 Stage 1 카드 배경 + Stage 2 풀스크린 배경 + 저장 스냅샷', 'storage_url, mode, theme, mood, tone, status'],
  ['Zone 고정 배경', 'BACKGROUND_IMAGES', 'background_images/', 'Sheets → DB', 'sync_zone_backgrounds.js', '8개 (Zone별 1장)', '홈 탭 풀스크린 배경 (Zone 1:1 고정)', 'storage_url, zone, mode, tone'],
  ['저장 스냅샷', '—', 'saved_verses/{uid}/verses/', '앱 내부 저장', '(앱 자동 저장)', '유저별 동적', '말씀 저장 시점의 이미지 URL 스냅샷', 'image_url, verse_full_ko, saved_at, weather_*'],
  ['', '', '', '', '', '', '', ''],

  // 정적 에셋
  ['앱 아이콘', 'Assets.xcassets', '—', '하드코딩', '—', '1개', '알림 센터·홈 화면 아이콘. 교체 시 앱 재설치 필요', 'AppIcon.appiconset/AppIcon.png'],
  ['스플래시 배경', 'Assets.xcassets', '—', '하드코딩', '—', '1개', '앱 시작 화면 배경', 'SplashBackground'],
  ['로그인 배경', 'Assets.xcassets', '—', '하드코딩', '—', '1개', '로그인(AuthWelcome) 화면 배경', 'AuthWelcomeBG'],
  ['브랜드 로고', 'Assets.xcassets', '—', '하드코딩', '—', '3개 (Color/Black/White)', '로그인·저장·설정·알람 Stage 2 등 다수 화면', 'LogoMMColor / LogoMMBlack / LogoMMWhite'],
  ['온보딩 배경 1', 'Assets.xcassets', '—', '하드코딩', '—', '1개', '온보딩 인트로 화면 배경', 'onb_bg_first_light'],
  ['온보딩 배경 2', 'Assets.xcassets', '—', '하드코딩', '—', '1개', '온보딩 알람 체험 화면 배경 (폴백)', 'onb_alarm_bg'],
  ['알람 Stage 1 배경', 'Assets.xcassets', '—', '하드코딩', '—', '1개', 'Legacy iOS(15-25) 알람 전체화면 배경', 'AlarmStage1BG'],
  ['', '', '', '', '', '', '', ''],

  // 데이터 정책
  ['⚠️ 데이터 정책', 'Google Sheets = 읽기/쓰기 (Single Source of Truth)', 'Firestore = 읽기 전용 (직접 쓰기 금지)', '콘텐츠 생성·수정은 Sheets 먼저 → sync 스크립트로 Firestore 반영', '', '', '', ''],
];

// ─── 탭 2: SCREEN_MAP ─────────────────────────────────────────────────────────

// 화면 목록 (열)
const SCREENS = [
  'Sheets 탭 / Firestore 필드',
  '스플래시',
  'ONB\n인트로',
  'ONB\n체험',
  'ONB\n닉네임',
  'ONB\n알람',
  '로그인',
  '홈',
  '홈\n바텀시트',
  '알람\n목록',
  '알람\n추가',
  'Stage1\n(Legacy)',
  'Stage2\n웰컴',
  '저장\n목록',
  '저장\n상세',
  '묵상\n읽기',
  '묵상\n응답',
  '설정',
];

// ✅ = DB/Sheets 연동 · HC = 하드코딩 · * = 저장 스냅샷 · — = 미사용
const SCREEN_MAP_DATA = [
  // [필드명, 스플래시, ONB인트로, ONB체험, ONB닉네임, ONB알람, 로그인, 홈, 홈바텀시트, 알람목록, 알람추가, Stage1, Stage2, 저장목록, 저장상세, 묵상읽기, 묵상응답, 설정]
  // ─── 말씀 필드 ───────────────────────────────────────────────────────────────
  ['[VERSES] verse_short_ko',    '—', '—',  'HC',  '—', '—', '—', '✅', '—',  '✅폴백', '✅', '✅', '—',  '—',    '—',  '✅', '—',  '—'],
  ['[VERSES] verse_full_ko',     '—', '—',  'HC',  '—', '—', '—', '—',  '✅', '—',    '—',  '—',  '✅', '✅*',  '✅', '✅', '—',  '—'],
  ['[VERSES] reference',         '—', '—',  'HC',  '—', '—', '—', '✅', '✅', '✅',   '—',  '✅', '✅', '—',    '✅', '✅', '—',  '—'],
  ['[VERSES] interpretation',    '—', '—',  'HC',  '—', '—', '—', '—',  '✅', '—',    '—',  '—',  '—',  '—',    '✅', '✅', '—',  '—'],
  ['[VERSES] application',       '—', '—',  'HC',  '—', '—', '—', '—',  '✅', '—',    '—',  '—',  '—',  '—',    '✅', '—',  '✅', '—'],
  ['[VERSES] alarm_top_ko',      '—', '—',  '—',   '—', '—', '—', '—',  '—',  '✅',   '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['[VERSES] question',          '—', '—',  '—',   '—', '—', '—', '—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '✅', '—'],
  ['[VERSES] theme',             '—', '—',  '—',   '—', '—', '—', '✅', '—',  '✅',   '✅', '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  // ─── 인사말 ─────────────────────────────────────────────────────────────────
  ['[HOME_GREETINGS] text',      '—', '—',  '—',   '—', '—', '—', '✅', '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['[ALARM_GREETINGS] text',     '—', '—',  '—',   '—', '—', '—', '—',  '—',  '—',    '—',  '—',  '✅', '—',    '—',  '—',  '—',  '—'],
  ['[DAILY_CARDS] greeting_ko',  '—', '—',  '—',   '—', '—', '—', '✅절기','—','—',    '—',  '—',  '✅절기','—', '—',  '—',  '—',  '—'],
  // ─── 이미지 ─────────────────────────────────────────────────────────────────
  ['[VERSE_IMAGES] storage_url', '—', '—',  '—',   '—', '—', '—', '—',  '—',  '—',    '—',  '✅카드', '✅전체', '✅*', '✅*', '—', '—', '—'],
  ['[BACKGROUND_IMAGES] storage_url','—','—','—',   '—', '—', '—', '✅', '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['[saved_verses] image_url *', '—', '—',  '—',   '—', '—', '—', '—',  '—',  '—',    '—',  '—',  '—',  '✅*',  '✅*', '—',  '—',  '—'],
  // ─── 정적 에셋 ───────────────────────────────────────────────────────────────
  ['SplashBackground (Asset)',    'HC','—',  '—',   '—', '—', '—', '—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['onb_bg_first_light (Asset)', '—', 'HC', '—',   '—', '—', '—', '—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['onb_alarm_bg (Asset)',        '—', '—',  'HC폴백','—','—', '—', '—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['AuthWelcomeBG (Asset)',       '—', '—',  '—',   '—', '—', 'HC','—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['LogoMMColor (Asset)',         '—', '—',  '—',   '—', '—', 'HC','—',  '—',  '—',    '—',  '—',  'HC', '✅*',  '✅*', '—',  '—',  'HC'],
  ['AlarmStage1BG (Asset)',       '—', '—',  '—',   '—', '—', '—', '—',  '—',  '—',    '—',  'HC전체','—','—',   '—',  '—',  '—',  '—'],
  // ─── 온보딩 하드코딩 콘텐츠 ────────────────────────────────────────────────
  ['온보딩 슬로건/문구 (HC)',      '—', 'HC', 'HC',  'HC','HC','HC','—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['체험 말씀 시편143:8 (HC)',     '—', '—',  'HC',  '—', '—', '—', '—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
  ['체험 해석/적용 (HC)',          '—', '—',  'HC',  '—', '—', '—', '—',  '—',  '—',    '—',  '—',  '—',  '—',    '—',  '—',  '—',  '—'],
];

// ─── 탭 3: IMAGE_ASSETS ──────────────────────────────────────────────────────

const IMAGE_ASSETS_ROWS = [
  // 헤더
  ['에셋명', '유형', 'Sheets 탭', 'Firestore 컬렉션·필드', '사용 화면', '선택 방식', '교체 방법', '비고'],

  // 정적 에셋
  ['AppIcon', '정적 에셋', '—', '—', '알림 센터·홈 화면·App Store', '고정', 'Assets.xcassets/AppIcon.appiconset 교체 후 앱 재설치', '1024×1024 PNG. 알림 아이콘은 iOS 캐시 → 재설치 필요'],
  ['SplashBackground', '정적 에셋', '—', '—', '스플래시', '고정', 'Assets.xcassets 교체', '앱 시작 0.8초 표시'],
  ['AuthWelcomeBG', '정적 에셋', '—', '—', '로그인(AuthWelcomeView)', '고정', 'Assets.xcassets 교체', '로그인 배경 전체'],
  ['LogoMMColor', '정적 에셋', '—', '—', '로그인·저장·설정·알람Stage2', '고정', 'Assets.xcassets 교체', '브랜드 로고 컬러버전. 1024×1024 실제콘텐츠는 중앙 16%'],
  ['LogoMMBlack', '정적 에셋', '—', '—', '(예비)', '고정', 'Assets.xcassets 교체', '브랜드 로고 검정버전'],
  ['LogoMMWhite', '정적 에셋', '—', '—', '(예비)', '고정', 'Assets.xcassets 교체', '브랜드 로고 흰색버전'],
  ['onb_bg_first_light', '정적 에셋', '—', '—', '온보딩 1화면 (ONBIntroView)', '고정', 'Assets.xcassets 교체', '온보딩 인트로 배경'],
  ['onb_alarm_bg', '정적 에셋', '—', '—', '온보딩 2화면 (ONBExperienceView)', '고정 (폴백)', 'Assets.xcassets 교체', '없으면 zoneBgImage 폴백'],
  ['AlarmStage1BG', '정적 에셋', '—', '—', '알람 Stage 1 (Legacy iOS 15-25 전용)', '고정', 'Assets.xcassets 교체', '전체 배경. iOS 26+는 Stage2 직행으로 사용 안 함'],
  ['', '', '', '', '', '', '', ''],

  // 원격 이미지
  ['VERSE_IMAGES', '원격 이미지 (Firebase Storage)', 'VERSE_IMAGES', 'images/ · storage_url', '알람 Stage1 말씀카드 배경 · Stage2 풀스크린 · 저장 목록/상세', 'Zone + theme + mood + weather 스코어링 알고리즘', 'VERSE_IMAGES 시트 편집 → sync_verse_images.js', 'active 49개. 부족 Zone: peak_mode/recharge/second_wind/golden_hour'],
  ['BACKGROUND_IMAGES (Zone 고정)', '원격 이미지 (Firebase Storage)', 'BACKGROUND_IMAGES', 'background_images/ · storage_url', '홈 탭 풀스크린 배경', 'Zone과 1:1 고정 매핑 (8개)', 'zone-backgrounds/ 폴더 → sync_zone_backgrounds.js', 'bg_deep_dark ~ bg_wind_down. Zone별 1장씩 필수'],
  ['저장 스냅샷 (image_url)', '저장 스냅샷 (Firebase Storage)', '—', 'saved_verses/{uid}/verses/ · image_url', '저장 탭 목록·상세', '말씀 저장 시점 VERSE_IMAGES URL 고정', '자동 (앱이 저장 시 캡처)', '저장 후 원본 이미지 삭제되어도 유지됨'],
  ['', '', '', '', '', '', '', ''],

  // Zone × 이미지 현황
  ['Zone', '시간대', '권장 최소', '현재 active', '상태', '부족 수', '', ''],
  ['deep_dark', '00–03시', '10개+', '충분', '✅', '—', '', ''],
  ['first_light', '03–06시', '10개+', '충분', '✅', '—', '', ''],
  ['rise_ignite', '06–09시', '10개+', '충분', '✅', '—', '', ''],
  ['peak_mode', '09–12시', '10개+', '부족', '⚠️', '7개+', '', ''],
  ['recharge', '12–15시', '10개+', '부족', '⚠️', '6개+', '', ''],
  ['second_wind', '15–18시', '10개+', '부족', '⚠️', '6개+', '', ''],
  ['golden_hour', '18–21시', '10개+', '부족', '⚠️', '2개+', '', ''],
  ['wind_down', '21–24시', '10개+', '충분', '✅', '—', '', ''],
];

// ─── Sheets API 헬퍼 ─────────────────────────────────────────────────────────

async function getOrCreateSheet(sheets, title) {
  const meta = await sheets.spreadsheets.get({ spreadsheetId: SPREADSHEET_ID });
  const existing = meta.data.sheets.find(s => s.properties.title === title);
  if (existing) {
    return existing.properties.sheetId;
  }
  const res = await sheets.spreadsheets.batchUpdate({
    spreadsheetId: SPREADSHEET_ID,
    requestBody: {
      requests: [{ addSheet: { properties: { title } } }],
    },
  });
  return res.data.replies[0].addSheet.properties.sheetId;
}

async function clearAndWrite(sheets, sheetName, rows) {
  await sheets.spreadsheets.values.clear({
    spreadsheetId: SPREADSHEET_ID,
    range: `${sheetName}!A1:Z1000`,
  });
  await sheets.spreadsheets.values.update({
    spreadsheetId: SPREADSHEET_ID,
    range: `${sheetName}!A1`,
    valueInputOption: 'RAW',
    requestBody: { values: rows },
  });
}

async function formatHeader(sheets, sheetId, numCols) {
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId: SPREADSHEET_ID,
    requestBody: {
      requests: [
        // 헤더 행 배경색 + 굵은 텍스트
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: numCols },
            cell: {
              userEnteredFormat: {
                backgroundColor: COLORS.headerBg,
                textFormat: { bold: true, foregroundColor: COLORS.headerFg, fontSize: 10 },
                verticalAlignment: 'MIDDLE',
                wrapStrategy: 'WRAP',
              },
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat,verticalAlignment,wrapStrategy)',
          },
        },
        // 행 고정
        { updateSheetProperties: { properties: { sheetId, gridProperties: { frozenRowCount: 1, frozenColumnCount: 1 } }, fields: 'gridProperties.frozenRowCount,gridProperties.frozenColumnCount' } },
        // 열 너비 자동
        { autoResizeDimensions: { dimensions: { sheetId, dimension: 'COLUMNS', startIndex: 0, endIndex: numCols } } },
      ],
    },
  });
}

// ─── SCREEN_MAP 전용 포맷: ✅ 는 파란색, HC는 주황색, * 는 회색 ──────────────

async function formatScreenMap(sheets, sheetId) {
  const requests = [];

  // 1행 헤더
  requests.push({
    repeatCell: {
      range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: SCREENS.length },
      cell: { userEnteredFormat: { backgroundColor: COLORS.headerBg, textFormat: { bold: true, foregroundColor: COLORS.headerFg, fontSize: 9 }, wrapStrategy: 'WRAP', horizontalAlignment: 'CENTER' } },
      fields: 'userEnteredFormat',
    },
  });

  // 1열 필드명 고정
  requests.push({
    repeatCell: {
      range: { sheetId, startRowIndex: 1, endRowIndex: SCREEN_MAP_DATA.length + 1, startColumnIndex: 0, endColumnIndex: 1 },
      cell: { userEnteredFormat: { backgroundColor: COLORS.sectionBg, textFormat: { bold: true, foregroundColor: COLORS.headerFg, fontSize: 9 }, wrapStrategy: 'WRAP' } },
      fields: 'userEnteredFormat',
    },
  });

  // 행 고정
  requests.push({
    updateSheetProperties: {
      properties: { sheetId, gridProperties: { frozenRowCount: 1, frozenColumnCount: 1 } },
      fields: 'gridProperties.frozenRowCount,gridProperties.frozenColumnCount',
    },
  });

  // 열 너비 조정
  requests.push({
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: 0, endIndex: 1 },
      properties: { pixelSize: 220 },
      fields: 'pixelSize',
    },
  });
  requests.push({
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: 1, endIndex: SCREENS.length },
      properties: { pixelSize: 72 },
      fields: 'pixelSize',
    },
  });

  await sheets.spreadsheets.batchUpdate({ spreadsheetId: SPREADSHEET_ID, requestBody: { requests } });
}

// ─── 메인 ────────────────────────────────────────────────────────────────────

async function main() {
  const auth = new google.auth.GoogleAuth({
    credentials: key,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  // ── 1. CONTENT_MAP ─────────────────────────────────────────────────────────
  console.log('\n📊 CONTENT_MAP 탭 생성 중...');
  const contentMapId = await getOrCreateSheet(sheets, 'CONTENT_MAP');
  await clearAndWrite(sheets, 'CONTENT_MAP', CONTENT_MAP_ROWS);
  await formatHeader(sheets, contentMapId, 8);
  console.log(`   ✅ ${CONTENT_MAP_ROWS.length}행 작성`);

  // ── 2. SCREEN_MAP ──────────────────────────────────────────────────────────
  console.log('\n🗺️  SCREEN_MAP 탭 생성 중...');
  const screenMapId = await getOrCreateSheet(sheets, 'SCREEN_MAP');
  const screenMapRows = [SCREENS, ...SCREEN_MAP_DATA];
  await clearAndWrite(sheets, 'SCREEN_MAP', screenMapRows);
  await formatScreenMap(sheets, screenMapId);
  console.log(`   ✅ ${SCREEN_MAP_DATA.length}행 × ${SCREENS.length}열 작성`);

  // ── 3. IMAGE_ASSETS ────────────────────────────────────────────────────────
  console.log('\n🖼️  IMAGE_ASSETS 탭 생성 중...');
  const imageAssetsId = await getOrCreateSheet(sheets, 'IMAGE_ASSETS');
  await clearAndWrite(sheets, 'IMAGE_ASSETS', IMAGE_ASSETS_ROWS);
  await formatHeader(sheets, imageAssetsId, 8);
  console.log(`   ✅ ${IMAGE_ASSETS_ROWS.length}행 작성`);

  console.log('\n✨ 완료! Google Sheets에서 확인하세요:');
  console.log(`   https://docs.google.com/spreadsheets/d/${SPREADSHEET_ID}/edit`);
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
