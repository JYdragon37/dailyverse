/**
 * read_tone_check.js
 * v_042~v_071, av_046~av_075 의 interpretation/application 읽기
 */

const { google } = require('googleapis');
const path = require('path');

const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');

async function getSheets() {
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  return google.sheets({ version: 'v4', auth });
}

async function readSheet(sheets, range) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range,
  });
  return res.data.values;
}

function parseHeader(raw) {
  return raw.map(h => {
    const s = String(h).trim();
    const p = s.indexOf('(');
    return p > 0 ? s.substring(0, p).trim() : s;
  });
}

async function main() {
  const sheets = await getSheets();

  console.log('읽는 중: VERSES!A:U');
  const versesData = await readSheet(sheets, 'VERSES!A:U');
  console.log('읽는 중: ALARM_VERSES!A:S');
  const alarmData = await readSheet(sheets, 'ALARM_VERSES!A:S');

  const versesHeader = parseHeader(versesData[0]);
  const alarmHeader = parseHeader(alarmData[0]);

  const vIdIdx = versesHeader.findIndex(h => h === 'verse_id');
  const vIntIdx = versesHeader.findIndex(h => h === 'interpretation');
  const vAppIdx = versesHeader.findIndex(h => h === 'application');
  const aIdIdx = alarmHeader.findIndex(h => h === 'verse_id');
  const aIntIdx = alarmHeader.findIndex(h => h === 'interpretation');
  const aAppIdx = alarmHeader.findIndex(h => h === 'application');

  console.log(`\nVERSES headers: ${JSON.stringify(versesHeader)}`);
  console.log(`ALARM_VERSES headers: ${JSON.stringify(alarmHeader)}`);
  console.log(`\nVERSES   — id:[${vIdIdx}] interpretation:[${vIntIdx}] application:[${vAppIdx}]`);
  console.log(`ALARM    — id:[${aIdIdx}] interpretation:[${aIntIdx}] application:[${aAppIdx}]`);

  console.log('\n\n===== VERSES v_042~v_071 =====');
  for (let r = 1; r < versesData.length; r++) {
    const row = versesData[r];
    const id = row[vIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('v_', ''));
    if (num < 42 || num > 71) continue;

    const interp = row[vIntIdx] || '';
    const app = row[vAppIdx] || '';
    console.log(`\n[${id}]`);
    console.log(`  interpretation (${interp.length}자): ${interp}`);
    console.log(`  application   (${app.length}자): ${app}`);
  }

  console.log('\n\n===== ALARM_VERSES av_046~av_075 =====');
  for (let r = 1; r < alarmData.length; r++) {
    const row = alarmData[r];
    const id = row[aIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('av_', ''));
    if (num < 46 || num > 75) continue;

    const interp = row[aIntIdx] || '';
    const app = row[aAppIdx] || '';
    console.log(`\n[${id}]`);
    console.log(`  interpretation (${interp.length}자): ${interp}`);
    console.log(`  application   (${app.length}자): ${app}`);
  }
}

main().catch(console.error);
