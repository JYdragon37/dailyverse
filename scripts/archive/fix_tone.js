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

// ─── 수정된 텍스트 정의 ──────────────────────────────────────────────────────
// VERSES
const VERSES_FIXES = {
  v_001: {
    // 기존: "~고백이다." 체 → 따뜻한 마무리 추가
    interpretation:
      '바울이 로마 감옥에서 빌립보 교인들에게 보낸 편지의 한 구절이야. 이 말씀은 흔히 오해받는데, "무엇이든 해낼 수 있다"는 자신감의 선언이 아니야. 바울은 풍요와 궁핍을 모두 겪으며 어떤 상황에서도 평정을 유지하는 법을 배워왔다고 고백해. 핵심은 "능력 주시는 자 안에서"야. 내 힘으로 버티는 게 아니라 하나님과의 연결 안에 머물 때 어떤 상황도 통과할 수 있다는 말이거든.',
    // APP는 이미 좋음 — 수정 불필요
  },
  v_002: {
    interpretation:
      '목자가 양을 한 마리씩 돌보듯 하나님이 나의 모든 필요를 채우신다는 신뢰의 고백이야. 히브리어 "라아"는 단순한 돌봄이 아니라, 풍성하게 먹이고 이끄는 적극적인 보살핌을 뜻해. 오늘 내가 부족하다고 느끼는 그 자리에서도 목자는 일하고 계셔.',
    // APP 이미 좋음
  },
  v_003: {
    interpretation:
      '예수님이 십자가 앞에서 제자들에게 선언하신 말씀이야. 헬라어 "케코스미카"는 완료형으로, 이미 완전히 이겼다는 뜻이야. 우리가 싸우는 싸움은 결과가 이미 정해진 싸움이고, 우리는 그 승리 안에 서 있어.',
    // APP 이미 좋음
  },
  v_004: {
    interpretation:
      '히브리어 "네르"는 발 하나 앞을 비추는 작은 손등 같은 빛이야. 길 전체를 밝히는 조명이 아니라, 한 걸음씩 내딛을 때마다 발 앞을 비춰주는 인도하심이거든. 오늘 모든 게 불분명해도, 다음 한 걸음을 위한 빛은 이미 켜져 있어.',
    // APP 이미 좋음
  },
  v_005: {
    interpretation:
      '헬라어 "에피립토"는 가만히 맡기는 게 아니라 힘껏 던져버리는 행위야. 염려를 손에 쥐고 조용히 내려놓는 게 아니라, 하나님을 향해 과감하게 던지는 적극적 믿음의 행동이야. 돌보심은 그 이후에 따라와.',
    // APP 이미 좋음
  },
  v_006: {
    interpretation:
      '바울이 감옥에서 쓴 편지에 담긴 선언이야. 헬라어 "엔뒤나무운티"는 현재진행형으로, 능력을 계속 불어넣고 계신다는 뜻이야. 내 힘이 아닌 그리스도 안에서 흘러오는 힘으로 사는 삶을 말하는 거야.',
    // APP 이미 좋음
  },
  v_007: {
    interpretation:
      '세 가지 명령은 모두 헬라어 현재 명령형으로, 한 번이 아닌 지속적인 삶의 태도를 가리켜. 기쁨, 기도, 감사는 감정이 아니라 훈련이야. 상황이 어떻든 선택할 수 있는 의지적 행위이기에 "항상"이 가능한 거거든.',
    // APP 이미 좋음
  },
  v_008: {
    interpretation:
      '히브리어 "에노그 알 야훼"는 하나님 안에서 즐거움을 찾으라는 뜻이야. 소원을 이루는 방법이 하나님을 기쁘게 하는 것이 아니라, 하나님 안에서 기쁨을 찾는 것이라는 역설적인 구조가 담겨 있어.',
    // APP 이미 좋음
  },
  v_009: {
    interpretation:
      '"새벽 날개"는 이른 새벽 동이 틀 때 빛이 사방으로 퍼지는 모습을 날개에 비유한 표현이야. 어디에 있든, 어떤 시간이든 하나님의 손이 함께한다는 확신의 고백이야. 새벽 3시의 어둠도 예외가 없어.',
    // APP 이미 좋음
  },
  v_010: {
    interpretation:
      '다윗의 이 고백은 도피가 아닌 항복이야. 어디도 하나님을 피할 수 없다는 걸 깨달을 때, 그건 공포가 아닌 위안이 돼. 깊은 밤, 아무도 없는 그 자리에도 하나님은 계셔.',
    // APP 이미 좋음
  },
  v_011: {
    interpretation:
      '히브리어 "카바"는 단순히 기다리는 것이 아니라 새끼줄처럼 꼬이며 강해진다는 뜻이야. 여호와를 앙망하는 것은 수동적 기다림이 아니라, 그분께 연결되어 힘을 공급받는 적극적 행위야. 오후의 지침도 이 연결을 통해 회복될 수 있어.',
    // APP 이미 좋음
  },
};

// ALARM_VERSES — av_001~av_005는 이미 좋음, av_006~av_015 "합니다/입니다" 체 수정
const ALARM_FIXES = {
  // av_001~av_005: APP/INT 모두 이미 좋음, 수정 불필요

  av_006: {
    interpretation:
      '로마서 8:28은 바울이 로마 교회에 보낸 편지 중 가장 위로적인 구절 중 하나야. 헬라어 "쉬네르게이"(합력하다)는 여러 요소가 함께 작동하여 하나의 목적을 이룬다는 뜻이야. 내일 알람을 맞추는 지금 이 행위도 그 안에 있어. 내일 어떤 일이 펼쳐지든, 그 모든 게 당신에게 선으로 이어진다는 약속 위에 알람을 설정하는 거야.',
    // APP 이미 좋음
  },
  av_007: {
    interpretation:
      '빌립보서 4:6은 바울이 감옥 안에서 쓴 편지야. 그럼에도 "염려하지 말라"고 말할 수 있는 건 기도라는 통로가 있기 때문이야. 저녁에 알람을 맞추는 행위는 내일의 일정을 하나님께 맡기는 첫 번째 행동이야. 내일을 계획하는 것과 하나님께 내려놓는 것은 서로 반대가 아니라 함께 가는 일이야.',
    // APP 이미 좋음
  },
  av_008: {
    interpretation:
      '이사야 40:31의 "앙망하다"는 히브리어 "카와"로, 줄을 꼬듯 힘을 모아 기다린다는 뜻이야. 독수리는 스스로 날갯짓하지 않고 상승 기류를 타고 높이 올라. 내일 아침 알람이 울릴 때 혼자 일어나는 게 아니야. 하나님의 기류를 타고 새 날로 올라가는 거야. 알람을 맞추는 지금 이 순간이 바로 그 기다림의 시작이야.',
    // APP 이미 좋음
  },
  av_009: {
    interpretation:
      '시편 143편은 다윗이 위기 속에서 드린 기도야. 그는 아침을 가장 먼저 하나님의 말씀으로 시작하기를 갈망해. "아침에"라는 표현은 히브리어로 새벽빛이 트이는 시각을 뜻해. 내일 아침 알람을 맞추는 건 바로 이 기도를 현실로 만드는 준비야. 알람이 울릴 때 가장 먼저 하나님의 말씀과 만나고 싶다는 소망이 담긴 행동이거든.',
    // APP 이미 좋음
  },
  av_010: {
    interpretation:
      '잠언 3:5-6은 지혜 문학의 핵심이야. "명철을 의지하지 말라"는 내 계획만 믿지 말라는 거고, "범사에 그를 인정하라"는 일상의 모든 순간, 알람을 맞추는 이 순간에도 하나님을 인정하라는 뜻이야. 내일 일정을 계획하고 알람을 설정하는 행위 자체가 하나님을 인정하는 "범사" 중 하나야.',
    // APP 이미 좋음
  },
  av_011: {
    interpretation:
      '신명기 31:8은 모세가 가나안 땅 입성을 앞두고 두려워하는 여호수아에게 한 말이야. "앞에서 가신다"는 건 하나님이 먼저 내일로 들어가 계신다는 뜻이야. 저녁에 알람을 맞추며 내일을 준비할 때, 당신보다 먼저 내일에 가 계신 하나님을 떠올려봐. 내일의 자리는 이미 준비돼 있어.',
    // APP 이미 좋음
  },
  av_012: {
    interpretation:
      '여호수아 1:9는 하나님이 여호수아에게 직접 하신 명령이자 약속이야. "강하고 담대하라"는 감정적인 용기가 아니라, 함께하시는 하나님에 근거한 담대함이야. 내일 아침 알람이 울리면 새로운 도전의 문이 열려. 그 문을 향해 담대하게 걸어갈 수 있는 이유는 하나님이 함께하시기 때문이야.',
    // APP 이미 좋음
  },
  av_013: {
    interpretation:
      '시편 37:5의 "맡기라"는 히브리어 "골"로, 짐을 굴려서 내려놓는다는 뜻이야. 내일의 스케줄과 걱정을 하나님께 굴려 넘기는 거야. 저녁에 내일 알람을 맞추는 행위는 내일을 계획하는 동시에 그 결과를 하나님께 맡기는 신앙의 행동이야. 알람을 설정하고, 계획은 드리고, 결과는 맡기는 것.',
    // APP 이미 좋음
  },
  av_014: {
    interpretation:
      '하박국 선지자는 혼란스러운 세상을 보며 하나님께 언제 응답하시냐고 물었어. 하나님의 대답은 "때가 있다"는 거였어. 알람은 정해진 시간에 울려. 그 시간을 우리가 설정했지만, 하나님의 약속에도 정해진 때가 있어. 내일을 기다리며 알람을 맞추는 이 행위가 하나님의 때를 기다리는 믿음과 닮아 있어.',
    // APP 이미 좋음
  },
  av_015: {
    interpretation:
      '로마서 15:13은 바울의 축복 기도야. 하나님을 "소망의 하나님"으로 부른다는 건 그분 자신이 소망의 근원이라는 뜻이야. 하루를 마무리하며 내일 알람을 맞추는 저녁, 기쁨과 평강을 충만하게 하시는 하나님께 내일을 맡기는 시간이야. 내일이 기대되는 이유는 소망의 하나님이 그 하루를 채우실 거기 때문이야.',
    // APP 이미 좋음
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

  // 컬럼 인덱스
  const vIdIdx = versesHeader.findIndex(h => h === 'verse_id');
  const vIntIdx = versesHeader.findIndex(h => h.startsWith('interpretation'));
  const vAppIdx = versesHeader.findIndex(h => h.startsWith('application'));
  const aIdIdx = alarmHeader.findIndex(h => h === 'verse_id');
  const aIntIdx = alarmHeader.findIndex(h => h === 'interpretation');
  const aAppIdx = alarmHeader.findIndex(h => h === 'application');

  console.log(`VERSES   — id:[${vIdIdx}] interpretation:[${vIntIdx}] application:[${vAppIdx}]`);
  console.log(`ALARM    — id:[${aIdIdx}] interpretation:[${aIntIdx}] application:[${aAppIdx}]`);

  const updates = [];

  // VERSES 처리
  for (let r = 1; r < versesData.length; r++) {
    const row = versesData[r];
    const id = row[vIdIdx];
    if (!id) continue;
    const fix = VERSES_FIXES[id];
    if (!fix) continue;

    if (fix.interpretation) {
      const colLetter = colToLetter(vIntIdx);
      updates.push({
        sheet: 'VERSES', id, field: 'interpretation',
        range: `VERSES!${colLetter}${r + 1}`,
        old: (row[vIntIdx] || '').slice(0, 50),
        value: fix.interpretation,
      });
    }
    if (fix.application) {
      const colLetter = colToLetter(vAppIdx);
      updates.push({
        sheet: 'VERSES', id, field: 'application',
        range: `VERSES!${colLetter}${r + 1}`,
        old: (row[vAppIdx] || '').slice(0, 50),
        value: fix.application,
      });
    }
  }

  // ALARM_VERSES 처리
  for (let r = 1; r < alarmData.length; r++) {
    const row = alarmData[r];
    const id = row[aIdIdx];
    if (!id) continue;
    const fix = ALARM_FIXES[id];
    if (!fix) continue;

    if (fix.interpretation) {
      const colLetter = colToLetter(aIntIdx);
      updates.push({
        sheet: 'ALARM_VERSES', id, field: 'interpretation',
        range: `ALARM_VERSES!${colLetter}${r + 1}`,
        old: (row[aIntIdx] || '').slice(0, 50),
        value: fix.interpretation,
      });
    }
    if (fix.application) {
      const colLetter = colToLetter(aAppIdx);
      updates.push({
        sheet: 'ALARM_VERSES', id, field: 'application',
        range: `ALARM_VERSES!${colLetter}${r + 1}`,
        old: (row[aAppIdx] || '').slice(0, 50),
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
      console.log(`  - ${u.id} (${u.field}): "${u.old.replace(/\n/g,' ')}..." → 말투 친근하게 수정 ("~이다" → "~이야/~야")`);
    }
  }

  console.log('\n### ALARM_VERSES 수정 항목');
  if (alarmReport.length === 0) {
    console.log('  (없음)');
  } else {
    for (const u of alarmReport) {
      console.log(`  - ${u.id} (${u.field}): "${u.old.replace(/\n/g,' ')}..." → 합니다/입니다 → ~이야/야 체로 수정`);
    }
  }

  // 수정 없는 항목
  const allIds = [
    ...versesData.slice(1).map(r => r[vIdIdx]),
    ...alarmData.slice(1).map(r => r[aIdIdx]),
  ].filter(Boolean);
  const updatedIds = new Set(updates.map(u => u.id));
  const unchanged = allIds.filter(id => !updatedIds.has(id));

  console.log('\n### 수정 없음 (양호한 항목)');
  console.log('  ' + unchanged.join(', '));
}

main().catch(console.error);
