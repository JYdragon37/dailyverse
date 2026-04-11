/**
 * fix_tone_v3.js
 * VERSES v_042~v_071, ALARM_VERSES av_046~av_075
 * interpretation / application 말투 점검 & 수정
 *
 * 말투 기준:
 *   좋음: ~야, ~이야, ~거야, ~느껴, ~일 거야, ~봐, ~해도 돼
 *   나쁨: ~이다, ~합니다, ~입니다, 반드시 ~해야, 설교조
 *
 * 분석 결과 (v_042~v_071, av_046~av_075):
 *   전체적으로 이미 친근 대화체로 잘 작성되어 있음.
 *
 *   [VERSES v_042~v_071 검토]
 *   v_042: "지금 이 순간이 바로 그 시간이야." — OK
 *   v_043: "열려 있는 거야." — OK
 *   v_044: "그건 예수님이 원하시는 네 모습이 아니야." — OK
 *   v_045: "네가 아직 그 높이를 못 본 거야." — OK
 *   v_046: "고통도 의미가 돼." — OK
 *   v_047: "다른 존재가 되는 거야." — OK
 *   v_048: "그 연결을 잃지 마." — OK
 *   v_049: "그분은 더 확실하게 거기 계셔." — OK
 *   v_050: application "이게 정말 나답나?" → 어색. "이게 정말 나다운 건지" 로 수정
 *   v_051: "새벽 어둠 속에서도 그분이 오른쪽에 계셔." — OK
 *   v_052: "그건 사실이 아니야." — OK
 *   v_053: "To-do 리스트의 1번이 뭔지 생각해봐." — OK
 *   v_054: "이해할 수 없는 상황에서도 마음이 지켜지는 거야." — OK
 *   v_055: "다시 일어나는 것이 네 정체성이야." — OK
 *   v_056: "하나님의 능력 앞에선 달라." — OK
 *   v_057: interpretation "헤세드의 흔적이 보일 거야." — OK
 *   v_058: "그 빈자리가 하나님을 향한 갈망이 될 수 있어." — OK
 *   v_059: "완벽한 기도를 해야 한다는 부담 내려놔." — OK
 *   v_060: "무엇이 너를 묶고 있는지 생각해봐." — OK
 *   v_061: "임재가 나의 안전이 되는 거야." — OK
 *   v_062: "겸손하게 열려 있어봐." — OK
 *   v_063: "지금 주변을 다시 살펴봐." — OK
 *   v_064: "계속 심어." — OK
 *   v_065: "예배가 돼." — OK
 *   v_066: "말이 치유가 돼." — OK
 *   v_067: "지금 이 순간이 그 시간이야." — OK
 *   v_068: "오늘 피곤함으로 시작해도 괜찮아." — OK
 *   v_069: interpretation "하나님의 약속은 반드시 이루어져." — "반드시"는 신학적 약속 강조 맥락, 내용 변경 금지 원칙상 유지
 *   v_070: "오늘 네 삶에서 제자리에 있지 않은 것이 있다면 하나씩 바르게 세워봐." — OK
 *   v_071: "분명 넘칠 거야." — OK
 *
 *   → v_050 application: "이게 정말 나답나?" → "이게 정말 나다운 건지" 로 수정
 *
 *   [ALARM_VERSES av_046~av_075 검토]
 *   av_046: interpretation - "알람을 맞추며 내일 아침 이 은혜를 기대해봐" — 길이 118자 OK
 *   av_047: "넌 그냥 쉬면 돼." — OK
 *   av_048: "더 좋은 길로 인도하실 거야." — OK
 *   av_049: interpretation 86자 (min 150자 기준은 VERSES 기준이고 ALARM_VERSES는 별도 — 현재 데이터 확인 필요)
 *     실제 시트 데이터상 av_049 interpretation이 86자로 짧음. 말투 기준으로는 OK
 *   av_050: "알람을 맞추며 그 담대함을 준비해봐." — OK
 *   av_051: "알람을 맞추고 눈을 감아봐" — OK
 *   av_052: "그 믿음 위에서 하루가 시작되거나 마무리될 때 진짜 평안이 오거든." — OK
 *   av_053: "알람을 맞추며 내일 아침 그 손의 인도를 기대해봐." — OK
 *   av_054: "알람이 울릴 때 그 준비된 하루로 걸어 들어가는 거야." — OK
 *   av_055: "그 고요함이 내일 아침을 더 맑게 열어줄 거야." — OK
 *   av_056: "그 약속을 붙잡으면서 눈을 감아봐." — OK
 *   av_057: "하나님이 바로 그 피난처야." — OK
 *   av_058: "그 새로움을 기대하며 알람을 설정해봐." — OK
 *   av_059: "하나님의 뜻에 맡겨봐." — OK
 *   av_060: "그게 하루의 방향을 바꿔." — OK
 *   av_061: "알람이 울릴 때 '내 속사람은 새로워지고 있어'라고 말해봐." — OK
 *   av_062: "거두는 날이 반드시 오거든." — "반드시"는 성경적 약속 맥락, 신학 내용 유지 원칙상 유지
 *   av_063: "내일 아침, 하나님의 말씀이 하루의 첫 빛이 되게 해봐." — OK
 *   av_064: "그거면 충분해." — OK
 *   av_065: "오늘보다 내일이 더 빛날 거야." — OK
 *   av_066: "그 평안 속에 쉬어봐." — OK
 *   av_067: "오늘은 진짜 새로운 시작이야." — OK
 *   av_068: "반드시 만날 수 있어." — 신학적 약속 맥락, 유지
 *   av_069: "나도 가져볼 수 있어." — OK
 *   av_070: application "내 판단보다 주님을 신뢰할게요" — 기도문 인용, OK
 *   av_071: "'일어나라, 그리스도가 빛을 비추신다'를 떠올리며 눈을 떠봐." — OK
 *   av_072: "그 계획을 믿으며 알람을 맞추고 쉬어봐." — OK
 *   av_073: "그 보호 아래서 하루를 시작한다는 기대를 가져봐." — OK
 *   av_074: "잠들기 전 이 기도를 하며 알람을 맞춰봐." — OK
 *   av_075: "내일 그 응답을 기대해봐." — OK
 *
 *   → ALARM_VERSES는 전체 OK
 *
 * 최종 수정 대상:
 *   v_050 application: "이게 정말 나답나?" → "이게 정말 나다운 건지" (어색한 표현 수정)
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
// v_050 application:
//   현재: "오늘 습관처럼 하는 일 하나를 의도적으로 멈추고 "이게 정말 나답나?" 물어봐."
//   문제: "나답나?" 는 구어체이긴 하나 문장 구성이 어색함
//   수정: "이게 정말 나다운 건지"로 자연스럽게

const VERSES_FIXES = {
  v_050: {
    // application: "이게 정말 나답나?" → "이게 정말 나다운 건지" 로 수정
    application:
      '오늘 습관처럼 하는 일 하나를 의도적으로 멈추고 "이게 정말 나다운 건지" 물어봐.',
  },
};

// ALARM_VERSES는 전체 OK — 수정 없음
const ALARM_FIXES = {};

function colToLetter(idx) {
  let letter = '';
  let n = idx;
  while (n >= 0) {
    letter = String.fromCharCode((n % 26) + 65) + letter;
    n = Math.floor(n / 26) - 1;
  }
  return letter;
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

  console.log(`VERSES   — id:[${vIdIdx}] interpretation:[${vIntIdx}] application:[${vAppIdx}]`);
  console.log(`ALARM    — id:[${aIdIdx}] interpretation:[${aIntIdx}] application:[${aAppIdx}]`);

  const updates = [];

  // VERSES 처리 (v_042~v_071)
  for (let r = 1; r < versesData.length; r++) {
    const row = versesData[r];
    const id = row[vIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('v_', ''));
    if (num < 42 || num > 71) continue;

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

  // ALARM_VERSES 처리 (av_046~av_075)
  for (let r = 1; r < alarmData.length; r++) {
    const row = alarmData[r];
    const id = row[aIdIdx];
    if (!id) continue;
    const num = parseInt(id.replace('av_', ''));
    if (num < 46 || num > 75) continue;

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

  // 수정 없는 항목
  const targetVerseIds = versesData.slice(1)
    .map(r => r[vIdIdx])
    .filter(id => id && parseInt(id.replace('v_','')) >= 42 && parseInt(id.replace('v_','')) <= 71);
  const targetAlarmIds = alarmData.slice(1)
    .map(r => r[aIdIdx])
    .filter(id => id && parseInt(id.replace('av_','')) >= 46 && parseInt(id.replace('av_','')) <= 75);

  const updatedIds = new Set(updates.map(u => u.id));
  const unchangedVerses = [...new Set(targetVerseIds)].filter(id => !updatedIds.has(id));
  const unchangedAlarms = [...new Set(targetAlarmIds)].filter(id => !updatedIds.has(id));

  console.log('\n### 수정 없음 (이미 양호 — VERSES)');
  console.log('  ' + unchangedVerses.join(', '));
  console.log('\n### 수정 없음 (이미 양호 — ALARM_VERSES)');
  console.log('  ' + unchangedAlarms.join(', '));
}

main().catch(console.error);
