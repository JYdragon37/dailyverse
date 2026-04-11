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
  return res.data.values || [];
}

async function main() {
  const sheets = await getSheets();

  console.log('=== VERSES 시트 읽기 ===');
  const versesData = await readSheet(sheets, 'VERSES!A:U');
  const versesHeader = versesData[0];
  console.log('헤더:', versesHeader.join(' | '));

  const vIdIdx = versesHeader.findIndex(h => h === 'verse_id');
  const vIntIdx = versesHeader.findIndex(h => h.startsWith('interpretation'));
  const vAppIdx = versesHeader.findIndex(h => h.startsWith('application'));
  console.log(`컬럼 인덱스 - id:${vIdIdx}, interpretation:${vIntIdx}(${String.fromCharCode(65+vIntIdx)}), application:${vAppIdx}(${String.fromCharCode(65+vAppIdx)})\n`);

  // v_012 ~ v_041 범위 찾기
  const targetVerses = [];
  for (let r = 1; r < versesData.length; r++) {
    const row = versesData[r];
    const id = row[vIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('v_', ''));
    if (num >= 12 && num <= 41) {
      targetVerses.push({
        id, rowNum: r + 1,
        interpretation: row[vIntIdx] || '',
        application: row[vAppIdx] || '',
      });
    }
  }

  console.log(`v_012~v_041 행 총 ${targetVerses.length}개:\n`);
  for (const v of targetVerses) {
    console.log(`[${v.id}] (행 ${v.rowNum})`);
    console.log(`  interpretation: ${v.interpretation}`);
    console.log(`  application: ${v.application}`);
    console.log('');
  }

  console.log('\n=== ALARM_VERSES 시트 읽기 ===');
  const alarmData = await readSheet(sheets, 'ALARM_VERSES!A:S');
  const alarmHeader = alarmData[0];
  console.log('헤더:', alarmHeader.join(' | '));

  const aIdIdx = alarmHeader.findIndex(h => h === 'verse_id');
  const aIntIdx = alarmHeader.findIndex(h => h === 'interpretation');
  const aAppIdx = alarmHeader.findIndex(h => h === 'application');
  console.log(`컬럼 인덱스 - id:${aIdIdx}, interpretation:${aIntIdx}(${String.fromCharCode(65+aIntIdx)}), application:${aAppIdx}(${String.fromCharCode(65+aAppIdx)})\n`);

  // av_016 ~ av_045 범위 찾기
  const targetAlarms = [];
  for (let r = 1; r < alarmData.length; r++) {
    const row = alarmData[r];
    const id = row[aIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('av_', ''));
    if (num >= 16 && num <= 45) {
      targetAlarms.push({
        id, rowNum: r + 1,
        interpretation: row[aIntIdx] || '',
        application: row[aAppIdx] || '',
      });
    }
  }

  console.log(`av_016~av_045 행 총 ${targetAlarms.length}개:\n`);
  for (const v of targetAlarms) {
    console.log(`[${v.id}] (행 ${v.rowNum})`);
    console.log(`  interpretation: ${v.interpretation}`);
    console.log(`  application: ${v.application}`);
    console.log('');
  }
}

main().catch(console.error);
