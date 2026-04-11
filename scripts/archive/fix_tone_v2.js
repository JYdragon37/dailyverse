/**
 * fix_tone_v2.js
 * VERSES v_012~v_041, ALARM_VERSES av_016~av_045
 * interpretation / application 말투 점검 & 수정
 *
 * 말투 기준:
 *   좋음: ~야, ~이야, ~거야, ~느껴, ~일 거야, ~봐, ~해도 돼
 *   나쁨: ~이다, ~합니다, ~입니다, 반드시, 꼭 ~해야, 설교조
 *
 * 분석 결과 (v_012~v_041, av_016~av_045):
 *   - 전체적으로 이미 친근 대화체로 잘 작성되어 있음
 *   - 수정 대상: 아래 항목들만
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

async function updateCell(sheets, range, value) {
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range,
    valueInputOption: 'RAW',
    requestBody: { values: [[value]] },
  });
}

// ─── 수정 필요 항목 정의 ──────────────────────────────────────────────────────
//
// [분석 결과 요약]
// v_012~v_030: 이미 친근 대화체 — 유지
//   * v_022/v_029/v_030 application의 "합니다"는 기도문 인용("감사합니다라고 말해봐") → 문제 없음
// v_031: interpretation 마지막 "내놔봐" → 자연스럽게 "꺼내봐" 로
// v_032~v_034: 이미 친근체 — 유지
//   * v_033 application의 "중입니다" → 인용문 표현("기다리는 중입니다라고 말해봐") → 문제 없음
// v_035: interpretation 마지막 "하나님의 능력 안에서." 단절 → 문장 연결 수정
// v_036~v_037: 이미 친근체 — 유지
// v_038: interpretation 마지막 "이 관점을 한 번 써봐" → 어색, "바라봐" 로
// v_039~v_041: 이미 친근체 — 유지
//
// [ALARM_VERSES av_016~av_045]
// av_016~av_031: 이미 친근체 — 유지
// av_032: interpretation의 "반드시" → 성경 약속 인용 맥락, 신학 내용 유지 원칙상 유지
// av_033: interpretation "아침을 찬양으로 여는 것이 가장 좋다는 말이야" → 더 친근하게
// av_034~av_044: 이미 친근체 — 유지
// av_045: application "오늘 아침 너를 기다려" → 저녁에 알람 맞추는 시점 기준으로 시제 수정

const VERSES_FIXES = {
  v_031: {
    // "내놔봐" → 더 자연스러운 표현으로
    interpretation:
      '"명철을 의지하지 말라"는 건 생각하지 말라는 게 아니야. 내 판단이 전부인 것처럼 살지 말라는 거야. 오늘 어떤 결정을 앞두고 있다면, 그 판단을 먼저 그분 앞에 꺼내봐.',
    // application: 이미 좋음 — 유지
  },

  v_035: {
    // "하나님의 능력 안에서." — 마지막 문장이 단절되어 있음 → 이어서 수정
    interpretation:
      '전신 갑주는 방어 장비야. 하루 끝에 새로 입는 게 아니라, 하루를 마칠 때 어디가 틈이 있었는지 점검하는 거야. 오늘 무엇이 나를 흔들었는지 돌아보고, 내일은 하나님의 능력 안에서 더 단단하게 설 수 있어.',
    // application: 이미 좋음 — 유지
  },

  v_038: {
    // "노을을 바라볼 때 이 관점을 한 번 써봐" → "써봐" 어색, "바라봐"로 수정
    interpretation:
      '바울은 끊임없이 박해받던 중에 이 글을 썼어. "잠시"라는 단어가 핵심이야. 영원의 관점에서 보면 지금의 고통도 잠시야. 오늘 힘들었다면, 그 무게를 이 관점으로 한 번 바라봐.',
    // application: 이미 좋음 — 유지
  },
};

// ─── [ALARM_VERSES av_016~av_045] ─────────────────────────────────────────
const ALARM_FIXES = {
  av_033: {
    // "아침을 찬양으로 여는 것이 가장 좋다는 말이야" → 더 따뜻하고 친근하게
    interpretation:
      '아침을 찬양으로 여는 게 최고야. 핸드폰 뉴스보다, 걱정보다 먼저 하나님의 인자하심을 기억하는 거야. 알람이 울리는 그 순간부터 하루를 감사로 시작할 수 있어.',
    // application: 이미 좋음 — 유지
  },

  av_045: {
    // "오늘 아침 너를 기다려" → 저녁에 알람 맞추는 시점 기준으로 "내일 아침"이 정확
    application:
      '내일 알람이 울리면 기억해. 오늘과 다른 새 자비가 내일 아침 너를 기다리고 있어.',
    // interpretation: 이미 좋음 — 유지
  },
};

function colToLetter(idx) {
  let letter = '';
  let n = idx;
  while (n >= 0) {
    letter = String.fromCharCode((n % 26) + 65) + letter;
    n = Math.floor(n / 26) - 1;
  }
  return letter;
}

async function main() {
  const sheets = await getSheets();

  console.log('읽는 중: VERSES!A:U');
  const versesData = await readSheet(sheets, 'VERSES!A:U');
  console.log('읽는 중: ALARM_VERSES!A:S');
  const alarmData = await readSheet(sheets, 'ALARM_VERSES!A:S');

  const versesHeader = versesData[0];
  const alarmHeader = alarmData[0];

  const vIdIdx = versesHeader.findIndex(h => h === 'verse_id');
  const vIntIdx = versesHeader.findIndex(h => h.startsWith('interpretation'));
  const vAppIdx = versesHeader.findIndex(h => h.startsWith('application'));
  const aIdIdx = alarmHeader.findIndex(h => h === 'verse_id');
  const aIntIdx = alarmHeader.findIndex(h => h === 'interpretation');
  const aAppIdx = alarmHeader.findIndex(h => h === 'application');

  console.log(`VERSES   — id:[${vIdIdx}] interpretation:[${vIntIdx}] application:[${vAppIdx}]`);
  console.log(`ALARM    — id:[${aIdIdx}] interpretation:[${aIntIdx}] application:[${aAppIdx}]`);

  const updates = [];

  // VERSES 처리 (v_012~v_041)
  for (let r = 1; r < versesData.length; r++) {
    const row = versesData[r];
    const id = row[vIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('v_', ''));
    if (num < 12 || num > 41) continue;

    const fix = VERSES_FIXES[id];
    if (!fix) continue;

    if (fix.interpretation) {
      const colLetter = colToLetter(vIntIdx);
      updates.push({
        sheet: 'VERSES', id, field: 'interpretation',
        range: `VERSES!${colLetter}${r + 1}`,
        old: (row[vIntIdx] || '').slice(0, 60),
        value: fix.interpretation,
      });
    }
    if (fix.application) {
      const colLetter = colToLetter(vAppIdx);
      updates.push({
        sheet: 'VERSES', id, field: 'application',
        range: `VERSES!${colLetter}${r + 1}`,
        old: (row[vAppIdx] || '').slice(0, 60),
        value: fix.application,
      });
    }
  }

  // ALARM_VERSES 처리 (av_016~av_045)
  for (let r = 1; r < alarmData.length; r++) {
    const row = alarmData[r];
    const id = row[aIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('av_', ''));
    if (num < 16 || num > 45) continue;

    const fix = ALARM_FIXES[id];
    if (!fix) continue;

    if (fix.interpretation) {
      const colLetter = colToLetter(aIntIdx);
      updates.push({
        sheet: 'ALARM_VERSES', id, field: 'interpretation',
        range: `ALARM_VERSES!${colLetter}${r + 1}`,
        old: (row[aIntIdx] || '').slice(0, 60),
        value: fix.interpretation,
      });
    }
    if (fix.application) {
      const colLetter = colToLetter(aAppIdx);
      updates.push({
        sheet: 'ALARM_VERSES', id, field: 'application',
        range: `ALARM_VERSES!${colLetter}${r + 1}`,
        old: (row[aAppIdx] || '').slice(0, 60),
        value: fix.application,
      });
    }
  }

  console.log(`\n총 ${updates.length}개 셀 업데이트 예정\n`);

  for (const u of updates) {
    process.stdout.write(`  업데이트: ${u.range} [${u.id} ${u.field}]... `);
    await updateCell(sheets, u.range, u.value);
    console.log('완료');
  }

  // ─── 보고 ─────────────────────────────────────────────────────────────────
  console.log('\n\n══════════════════════════════════════════════════════════');
  console.log('## 수정 완료 보고\n');

  const versesReport = updates.filter(u => u.sheet === 'VERSES');
  const alarmReport = updates.filter(u => u.sheet === 'ALARM_VERSES');

  console.log('### VERSES 수정 항목');
  if (versesReport.length === 0) {
    console.log('  (없음)');
  } else {
    for (const u of versesReport) {
      console.log(`  - ${u.id} (${u.field}): "${u.old.replace(/\n/g,' ')}..." → 말투 친근하게 수정`);
    }
  }

  console.log('\n### ALARM_VERSES 수정 항목');
  if (alarmReport.length === 0) {
    console.log('  (없음)');
  } else {
    for (const u of alarmReport) {
      console.log(`  - ${u.id} (${u.field}): "${u.old.replace(/\n/g,' ')}..." → 말투 친근하게 수정`);
    }
  }

  // 수정 없는 항목 (v_012~v_041, av_016~av_045 범위)
  const targetVerseIds = versesData.slice(1)
    .map(r => r[vIdIdx])
    .filter(id => id && parseInt(id.replace('v_','')) >= 12 && parseInt(id.replace('v_','')) <= 41);
  const targetAlarmIds = alarmData.slice(1)
    .map(r => r[aIdIdx])
    .filter(id => id && parseInt(id.replace('av_','')) >= 16 && parseInt(id.replace('av_','')) <= 45);

  const updatedIds = new Set(updates.map(u => u.id));
  const unchangedVerses = targetVerseIds.filter(id => !updatedIds.has(id));
  const unchangedAlarms = targetAlarmIds.filter(id => !updatedIds.has(id));

  console.log('\n### 수정 없음 (이미 양호 — VERSES)');
  console.log('  ' + unchangedVerses.join(', '));
  console.log('\n### 수정 없음 (이미 양호 — ALARM_VERSES)');
  console.log('  ' + unchangedAlarms.join(', '));
}

main().catch(console.error);
