/**
 * qa_logger.js
 * QA 점검 결과를 Google Sheets QA_LOG 탭에 기록
 *
 * Usage:
 *   const { logResults } = require('./qa_logger');
 *   await logResults(runId, issues);
 */

const { google } = require('googleapis');
const rules = require('./content-rules.json');

const key = require('./serviceAccountKey.json');
const auth = new google.auth.GoogleAuth({
  credentials: key,
  scopes: ['https://www.googleapis.com/auth/spreadsheets'],
});

/**
 * 점검 결과 배열을 QA_LOG 탭에 추가
 *
 * @param {string} runId - 실행 ID (예: "2026-04-14-001")
 * @param {Array<Object>} issues - 점검 결과 목록
 *   각 항목: { verse_id, reference, check_type, status, severity, issue, fixed, fixed_by, notes }
 */
async function logResults(runId, issues) {
  if (!issues || issues.length === 0) {
    console.log('기록할 이슈 없음');
    return;
  }

  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });
  const spreadsheetId = rules.spreadsheet.id;
  const tab = rules.spreadsheet.tabs.qa_log;

  const runDate = new Date().toISOString().slice(0, 10);

  const rows = issues.map(issue => [
    runId,
    runDate,
    issue.verse_id     || '',
    issue.reference    || '',
    issue.check_type   || '',
    issue.status       || 'fail',
    issue.severity     || 'medium',
    issue.issue        || '',
    issue.fixed        || 'N',
    issue.fixed_date   || '',
    issue.fixed_by     || '',
    issue.notes        || '',
  ]);

  await sheets.spreadsheets.values.append({
    spreadsheetId,
    range: `${tab}!A:L`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });

  console.log(`✅ QA_LOG에 ${rows.length}건 기록 완료 (run_id: ${runId})`);
}

/**
 * 특정 verse_id의 fixed 상태 업데이트
 */
async function markFixed(runId, verseIds, fixedBy = 'agent') {
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });
  const spreadsheetId = rules.spreadsheet.id;
  const tab = rules.spreadsheet.tabs.qa_log;

  const today = new Date().toISOString().slice(0, 10);

  // QA_LOG 전체 읽기
  const r = await sheets.spreadsheets.values.get({ spreadsheetId, range: `${tab}!A:L` });
  const rows = r.data.values || [];

  const updates = [];
  rows.forEach((row, i) => {
    if (i === 0) return; // 헤더 스킵
    if (row[0] === runId && verseIds.includes(row[2]) && row[8] !== 'Y') {
      updates.push({
        range: `${tab}!I${i+1}:K${i+1}`,
        values: [['Y', today, fixedBy]],
      });
    }
  });

  if (updates.length > 0) {
    await sheets.spreadsheets.values.batchUpdate({
      spreadsheetId,
      requestBody: { valueInputOption: 'RAW', data: updates },
    });
    console.log(`✅ ${updates.length}건 fixed 처리 완료`);
  }
}

/**
 * 최근 N번 실행의 통계 조회
 */
async function getStats(lastN = 5) {
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });
  const spreadsheetId = rules.spreadsheet.id;
  const tab = rules.spreadsheet.tabs.qa_log;

  const r = await sheets.spreadsheets.values.get({ spreadsheetId, range: `${tab}!A:L` });
  const rows = (r.data.values || []).slice(1); // 헤더 제외

  // 실행 ID별 그룹화
  const runs = {};
  rows.forEach(row => {
    const runId = row[0];
    if (!runId) return;
    if (!runs[runId]) runs[runId] = { date: row[1], total: 0, fixed: 0, byType: {} };
    runs[runId].total++;
    if (row[8] === 'Y') runs[runId].fixed++;
    const type = row[4] || 'unknown';
    runs[runId].byType[type] = (runs[runId].byType[type] || 0) + 1;
  });

  const sortedRuns = Object.entries(runs)
    .sort(([,a],[,b]) => b.date.localeCompare(a.date))
    .slice(0, lastN);

  console.log(`\n📊 QA 실행 통계 (최근 ${lastN}회)\n${'─'.repeat(50)}`);
  sortedRuns.forEach(([runId, stat]) => {
    const fixRate = stat.total > 0 ? Math.round(stat.fixed / stat.total * 100) : 0;
    console.log(`[${runId}] ${stat.date} | 총 ${stat.total}건 | 수정 ${stat.fixed}건 (${fixRate}%)`);
    Object.entries(stat.byType).forEach(([type, count]) =>
      console.log(`  - ${type}: ${count}건`)
    );
  });

  return sortedRuns;
}

if (require.main === module) {
  getStats().catch(console.error);
}

module.exports = { logResults, markFixed, getStats };
