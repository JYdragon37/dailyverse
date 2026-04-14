/**
 * fetch_verses.js
 * 표준 데이터 수집 스크립트 — content QA 파이프라인의 진입점
 *
 * Usage:
 *   node scripts/fetch_verses.js                  → /tmp/verses_check.json
 *   node scripts/fetch_verses.js --out ./my.json   → 지정 경로
 *   node scripts/fetch_verses.js --tab ALARM_VERSES → 다른 탭
 */

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');
const rules = require('./content-rules.json');

const key = require('./serviceAccountKey.json');
const auth = new google.auth.GoogleAuth({
  credentials: key,
  scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
});

async function fetchVerses(options = {}) {
  const {
    tab = rules.spreadsheet.tabs.verses,   // 기본: VERSES
    outPath = '/tmp/verses_check.json',
    includeAll = false,                     // false: active만 / true: 전체
  } = options;

  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });
  const spreadsheetId = rules.spreadsheet.id;

  const range = `${tab}!A2:Q300`;
  const response = await sheets.spreadsheets.values.get({ spreadsheetId, range });
  const rows = response.data.values || [];

  const cols = rules.spreadsheet.verses_columns;
  const colIndex = Object.fromEntries(
    Object.entries(cols).map(([letter, name]) => [name, letter.charCodeAt(0) - 65])
  );

  // 중복 ID 추적
  const seenIds = new Set();
  const data = [];

  rows.forEach((row, i) => {
    const id = row[colIndex.verse_id];
    if (!id) return;

    // 중복 스킵
    if (seenIds.has(id)) return;
    seenIds.add(id);

    const status = row[colIndex.status] || 'active';
    if (!includeAll && status === 'inactive') return;

    data.push({
      _row: i + 2,
      verse_id:       id,
      verse_short_ko: row[colIndex.verse_short_ko]  || '',
      verse_full_ko:  row[colIndex.verse_full_ko]   || '',
      reference:      row[colIndex.reference]        || '',
      mode:           row[colIndex.mode]             || '',
      theme:          row[colIndex.theme]            || '',
      mood:           row[colIndex.mood]             || '',
      interpretation: row[colIndex.interpretation]   || '',
      application:    row[colIndex.application]      || '',
      curated:        row[colIndex.curated]          || '',
      status:         status,
      notes:          row[colIndex.notes]            || '',
    });
  });

  const outputPath = path.resolve(outPath);
  fs.writeFileSync(outputPath, JSON.stringify(data, null, 2), 'utf8');

  console.log(`✅ ${tab} 탭 → ${data.length}개 구절 → ${outputPath}`);
  return data;
}

// CLI 실행
if (require.main === module) {
  const args = process.argv.slice(2);
  const outIdx = args.indexOf('--out');
  const tabIdx = args.indexOf('--tab');

  const options = {
    tab:       tabIdx >= 0 ? args[tabIdx + 1] : undefined,
    outPath:   outIdx >= 0 ? args[outIdx + 1] : undefined,
    includeAll: args.includes('--all'),
  };

  fetchVerses(options).catch(err => {
    console.error('오류:', err.message);
    process.exit(1);
  });
}

module.exports = { fetchVerses };
