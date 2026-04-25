/**
 * rename_dailyverse_to_mm.js
 *
 * Google Sheets에서 "DailyVerse" 텍스트를 "morning manna"로 일괄 교체합니다.
 *
 * 교체 대상:
 *   - TAG_GUIDE, LLM_GUIDE, GREETING_GUIDE, IMAGE_GUIDE 탭 헤더/내용
 *   - CONTENT_MAP, SCREEN_MAP, IMAGE_ASSETS 탭 내용
 *
 * 제외 대상 (변경 불가):
 *   - Firebase Storage URL의 "dailyverse-9260d" — 인프라 프로젝트 ID
 *   - Firebase Storage URL 전체 (이미지 URL 깨짐 방지)
 */

const { google } = require('googleapis');
const key = require('./serviceAccountKey.json');

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';

// 교체 규칙: [검색 패턴, 대체 텍스트]
// URL은 제외하고 설명 텍스트만 교체
const REPLACEMENTS = [
  ['# DailyVerse TAG_GUIDE',     '# morning manna TAG_GUIDE'],
  ['# DailyVerse ZONE_GUIDE',    '# morning manna ZONE_GUIDE'],
  ['# DailyVerse LLM_GUIDE',     '# morning manna LLM_GUIDE'],
  ['# DailyVerse GREETING_GUIDE','# morning manna GREETING_GUIDE'],
  ['# DailyVerse IMAGE_GUIDE',   '# morning manna IMAGE_GUIDE'],
  ['# DailyVerse DAILY_CARDS_GUIDE', '# morning manna DAILY_CARDS_GUIDE'],
  // LLM_GUIDE 내 앱 이름 필드
  ['DailyVerse\t',               'morning manna\t'],  // 탭 구분 셀
];

// URL인지 확인 — http로 시작하거나 storage.googleapis.com 포함이면 건드리지 않음
function isUrl(str) {
  return typeof str === 'string' && (
    str.startsWith('http://') ||
    str.startsWith('https://') ||
    str.includes('storage.googleapis.com') ||
    str.includes('dailyverse-9260d')
  );
}

// 셀 값에서 DailyVerse 교체 (URL 제외)
function replaceInCell(cell) {
  if (typeof cell !== 'string') return { changed: false, value: cell };
  if (isUrl(cell)) return { changed: false, value: cell };

  let result = cell;
  // 패턴별 교체
  for (const [from, to] of REPLACEMENTS) {
    if (result.includes(from)) {
      result = result.split(from).join(to);
    }
  }
  // 나머지 "DailyVerse" (URL 아닌 경우) → "morning manna"
  if (result.includes('DailyVerse') && !isUrl(result)) {
    result = result.split('DailyVerse').join('morning manna');
  }
  return { changed: result !== cell, value: result };
}

async function processTab(sheets, tabName) {
  // 전체 데이터 읽기 (최대 200행)
  let res;
  try {
    res = await sheets.spreadsheets.values.get({
      spreadsheetId: SPREADSHEET_ID,
      range: `${tabName}!A1:Z200`,
    });
  } catch (e) {
    console.log(`  [${tabName}] 읽기 실패: ${e.message}`);
    return 0;
  }

  const rows = res.data.values || [];
  if (rows.length === 0) return 0;

  let changed = 0;
  const updatedRows = rows.map(row =>
    row.map(cell => {
      const r = replaceInCell(cell);
      if (r.changed) changed++;
      return r.value;
    })
  );

  if (changed === 0) return 0;

  // 변경된 경우만 업데이트
  await sheets.spreadsheets.values.update({
    spreadsheetId: SPREADSHEET_ID,
    range: `${tabName}!A1`,
    valueInputOption: 'RAW',
    requestBody: { values: updatedRows },
  });

  return changed;
}

async function main() {
  const auth = new google.auth.GoogleAuth({
    credentials: key,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  // 전체 탭 목록 가져오기
  const meta = await sheets.spreadsheets.get({ spreadsheetId: SPREADSHEET_ID });
  const allTabs = meta.data.sheets.map(s => ({
    title: s.properties.title,
    id: s.properties.sheetId,
  }));

  console.log(`\n총 ${allTabs.length}개 탭 검사 중...\n`);

  let totalChanged = 0;

  // URL 포함 탭은 내용 교체에서 제외 (storage_url 열 있는 탭)
  // 가이드/메타 탭만 교체
  const SKIP_DATA_TABS = new Set([
    'VERSES', 'VERSE_IMAGES', 'BACKGROUND_IMAGES',
    'HOME_GREETINGS', 'ALARM_GREETINGS', 'DAILY_CARDS',
    'QA_LOG', 'STATS', 'CHANGELOG',
  ]);

  for (const tab of allTabs) {
    if (SKIP_DATA_TABS.has(tab.title)) {
      process.stdout.write(`  [${tab.title}] 건너뜀 (데이터 탭)\n`);
      continue;
    }

    const n = await processTab(sheets, tab.title);
    if (n > 0) {
      console.log(`  [${tab.title}] ✅ ${n}개 셀 교체 완료`);
      totalChanged += n;
    } else {
      console.log(`  [${tab.title}] — 변경 없음`);
    }
  }

  console.log(`\n✨ 완료! 총 ${totalChanged}개 셀 교체됨`);
  console.log(`\n⚠️  변경하지 않은 것:`);
  console.log(`   - Firebase Storage URL (dailyverse-9260d.firebasestorage.app) — 인프라 프로젝트 ID, 변경 불가`);
  console.log(`   - 데이터 탭 (VERSES, VERSE_IMAGES 등) — 콘텐츠 데이터, 앱 이름 미포함`);
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
