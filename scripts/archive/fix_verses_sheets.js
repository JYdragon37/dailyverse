const { google } = require('googleapis');
const serviceAccount = require('./serviceAccountKey.json');

const auth = new google.auth.GoogleAuth({
  credentials: serviceAccount,
  scopes: ['https://www.googleapis.com/auth/spreadsheets']
});

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET = 'VERSES';

// 열 위치 (1-based)
// B=2: verse_short_ko
// C=3: verse_full_ko
// M=13: interpretation
// N=14: application
// AA=27: question (27번째 열)

// 행번호 (1-based, 헤더 포함)
const ROW = {
  v_007: 8,
  v_016: 17,
  v_032: 33,
  v_033: 34,
  v_046: 47,
  v_047: 48,
  v_054: 55,
  v_068: 69,
  v_119: 120,
  v_146: 147,
  v_147: 148,
  v_165: 166,
  v_180: 181
};

// 열 인덱스 → A1 표기 변환 (1-based)
function colLetter(n) {
  let s = '';
  while (n > 0) {
    const r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
}

// 수정할 데이터: { verse_id: { col번호: 값 } }
// B=2, C=3, M=13, N=14, AA=27
const updates = [
  // 1. verse_full_ko 단축 (C열=3)
  { id: 'v_016', col: 3, value: '무릇 여호와를 의뢰하며 여호와를 의지하는 그 사람은 복을 받을 것이라\n그는 물가에 심기운 나무가 그 뿌리를 강변에 뻗치고 더위가 올지라도 두려워 아니하며 그 잎이 청청하며 가무는 해에도 걱정이 없고' },
  { id: 'v_032', col: 3, value: '이러므로 우리에게 구름 같이 둘러싼 허다한 증인들이 있으니 모든 무거운 것과 얽매이기 쉬운 죄를 벗어 버리고 인내로써 우리 앞에 당한 경주를 경주하며' },
  { id: 'v_046', col: 3, value: '찬송하리로다 그는 우리 주 예수 그리스도의 하나님이시요 자비의 아버지시요 모든 위로의 하나님이시며 우리의 모든 환난 중에서 우리를 위로하사' },
  { id: 'v_047', col: 3, value: '내가 그리스도와 함께 십자가에 못 박혔나니 그런즉 이제는 내가 산 것이 아니요 오직 내 안에 그리스도께서 사신 것이라' },

  // 1. verse_short_ko (B열=2)
  { id: 'v_047', col: 2, value: '내가 그리스도와 함께 십자가에 못 박혔나니 이제는 내 안에 그리스도께서 사신 것이라' },

  // 2. verse_short_ko 수정 (v_007, B열=2)
  { id: 'v_007', col: 2, value: '항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라' },

  // 3. application 말투 수정 (N열=14)
  { id: 'v_033', col: 14, value: '지금 답을 기다리고 있는 게 있다면 "나 지금 기다리는 중이야"라고 인정하고 잠시 쉬어봐.' },
  { id: 'v_165', col: 14, value: '내일 알람이 울리면, "드디어 아침이야. 하나님이 기다리던 이 아침을 주셨어"라고 생각해봐.' },

  // 4. question 강요 표현 제거 (AA열=27)
  { id: 'v_119', col: 27, value: '지금 이 순간, 당신이 붙잡고 있는 것 중에 오늘 밤은 내려놓아도 될 것이 있다면 무엇인가요?' },
  { id: 'v_180', col: 27, value: '요즘 밤을 새우거나 무리하면서 지쳐간다는 걸 느낀 순간이 있다면, 그때 어떤 생각이 들었나요?' },

  // 4. interpretation에서 "반드시" 제거 (M열=13)
  { id: 'v_146', col: 13, value: '오늘 수고한 게 헛되지 않아. 지금 눈물로 뿌리는 씨앗이 기쁨의 수확으로 돌아올 거야.\n힘든 하루였어도 알람을 맞추며 내일을 기대할 수 있어 — 거두는 날이 올 거거든.' },

  // 5. question 글자수 보완 (AA열=27)
  { id: 'v_054', col: 27, value: '마음이 크게 흔들렸던 때를 떠올려봐. 그때 당신을 버티게 해준 것이 무엇이었나요?' },
  { id: 'v_068', col: 27, value: '지금 당신이 가장 기력이 떨어졌다고 느끼는 순간은 언제이고, 그때 무엇이 도움이 되었나요?' },
  { id: 'v_147', col: 27, value: '가장 힘들었던 순간, 당신은 무엇을 붙잡고 버텨왔나요? 지금도 그것이 여전히 힘이 되고 있나요?' },
];

async function updateSheets() {
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  const data = updates.map(u => {
    const row = ROW[u.id];
    const col = colLetter(u.col);
    const range = SHEET + '!' + col + row;
    return {
      range,
      values: [[u.value]]
    };
  });

  console.log('=== Sheets 업데이트 예정 범위 ===');
  data.forEach((d, i) => {
    const u = updates[i];
    console.log(d.range + ' [' + u.id + '] ' + u.value.substring(0, 40) + (u.value.length > 40 ? '...' : ''));
  });

  const res = await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SPREADSHEET_ID,
    requestBody: {
      valueInputOption: 'RAW',
      data
    }
  });

  console.log('\n=== 업데이트 완료 ===');
  console.log('총 ' + res.data.responses.length + '개 범위 업데이트됨');
  process.exit(0);
}

updateSheets().catch(e => {
  console.error(e.message);
  process.exit(1);
});
