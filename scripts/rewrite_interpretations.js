/**
 * DailyVerse — interpretation 필드 재작성 스크립트
 * 10개 구절의 interpretation을 4단계 구조로 재작성하고 Google Sheets M열 업데이트
 */

const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

// 4단계 구조로 재작성된 interpretation (200자 이내)
const NEW_INTERPRETATIONS = {
  v_121: "잠언은 '일을 주께 맡기라'고 권한다. 이 '맡김'은 신뢰의 행위이지 성공 보장이 아니야. 당시 지혜 전통에서 '맡기다'는 단순한 부탁이 아니라 전적인 위탁을 의미했어. 내 계획을 내려놓을 때 오히려 하나님의 길이 열려. 하루를 시작하기 전, 오늘의 일을 그분 손에 먼저 올려놓자.",
  v_129: "겟세마네, 예수님이 체포되기 전날 밤 지친 제자들에게 하신 말씀이야. 위기의 순간에 기도가 절실한 이유를 아시면서도 '깨어 기도하라' 하셨어. 여기서 '육체의 연약함'은 실패가 아니라 솔직한 현실이야. 오늘도 지쳐 눈이 감길 때, 그 자리에서 짧게라도 드리는 기도면 충분해. 저녁 끝자락, 마음을 그분께 열어두자.",
  v_148: "바울은 로마서 8장에서 고난 중에도 성령과 함께하는 삶을 선포해. '하나님이 우리를 위하시면'은 소망 사항이 아니라 이미 확인된 사실이야. 이 '위하심'은 고난이 없다는 말이 아니라, 고난 속에서도 하나님이 우리 편이라는 선언이지. 오늘 삶이 흔들려도 이 사실은 변하지 않아. 잠들기 전, 그 든든함을 붙잡자.",
  v_147: "시편 119편은 하나님의 말씀을 향한 가장 긴 찬양시야. '새벽 전에 부르짖는다'는 표현은 극한의 간절함, 해 뜨기도 전에 이미 하나님을 향해 있는 마음이지. 이 '기다림'은 소극적인 기대가 아니라 말씀을 붙잡고 버티는 능동적 신뢰야. 오늘 아침, 알람이 울리기 전부터 그분이 먼저 기다리고 계셔.",
  v_154: "초기 교회에서 세례받는 이들에게 불렀던 찬송으로 알려진 구절이야. '잠자는 자여 깨어라'는 영적인 각성의 선언이지, 단순한 아침 기상이 아니야. 당시 세례는 죽음에서 새 생명으로 건너가는 상징이었어. 매일 아침 눈 뜨는 것 자체가 그 새 생명을 다시 선택하는 순간이야. 오늘 하루, 그 빛 안으로 일어서 보자.",
  v_113: "예루살렘이 바벨론에 무너진 직후, 예레미야가 잿더미 위에서 쓴 노래야. 그 절망의 한가운데서 '아침마다 새롭다'고 고백한 거야. 이 '새로움'은 상황이 바뀌었다는 게 아니라, 하나님의 신실하심이 매일 다시 시작된다는 뜻이지. 어제 어떤 밤을 보냈든, 오늘 아침은 새로운 신실하심으로 시작돼. 그 고백으로 하루를 열자.",
  v_115: "이사야 56-66장은 바벨론 포로에서 돌아온 이스라엘을 향한 선포야. '일어나 빛을 발하라'는 말은 여전히 폐허 속에 있는 백성에게 주어진 말씀이지. 이 '빛'은 이스라엘 스스로 만든 게 아니라 하나님의 영광이 먼저 임한 거야. 내 상황이 아직 회복되지 않아도, 그분의 빛은 지금 여기서 시작돼. 오늘 아침, 그 빛 안에서 일어서자.",
  v_172: "바울은 로마서 8장에서 성령 안의 삶과 고난을 함께 다뤄. '하나님이 우리를 위하시면'은 소망이 아니라 이미 증명된 사실이야. 이 선언은 고난이 사라진다는 약속이 아니라, 그 모든 것 위에 하나님이 계신다는 고백이지. 오늘 하루 내 편에 계셨던 그분을 기억하며 저녁을 마무리할 수 있어. 그 든든함이 오늘의 감사야.",
  v_124: "시편 92편은 안식일 예배용 찬양시야. '아침에 주의 인자하심'과 '밤마다 주의 성실하심'을 대비하며 하루 전체가 찬양의 공간임을 노래해. 이 '인자하심'은 단순한 친절이 아니라 언약에 근거한 변함없는 사랑이야. 하루가 시작되는 지금, 그 사랑이 오늘도 새롭게 임하고 있어. 아침을 그 고백으로 열자.",
  v_176: "시편 121편은 성전을 향해 올라가는 순례 도중 부른 노래야. 광야 길의 위험과 피로 속에서 '지키시는 분'을 고백했어. '주무시지 않는다'는 표현은 고대 근동에서 신상이 잠든 사이 재앙이 온다는 두려움을 배경으로 해. 우리 하나님은 결코 주무시지 않아. 오늘 밤 내가 쉬어도 그분은 깨어 지키셔."
};

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  // 1. 헤더 행 읽기
  console.log('헤더 행 읽는 중...');
  const headerRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!1:1`,
  });
  const headers = headerRes.data.values[0];
  console.log('헤더 총 컬럼 수:', headers.length);

  // 컬럼 인덱스 찾기
  const verseIdCol = headers.indexOf('verse_id');
  const referenceCol = headers.indexOf('reference');
  const modeCol = headers.indexOf('mode');
  const interpretationCol = headers.indexOf('interpretation');
  const shortKoCol = headers.indexOf('short_ko');

  console.log(`verse_id 컬럼: ${verseIdCol} (${columnLetter(verseIdCol)})`);
  console.log(`reference 컬럼: ${referenceCol} (${columnLetter(referenceCol)})`);
  console.log(`mode 컬럼: ${modeCol} (${columnLetter(modeCol)})`);
  console.log(`interpretation 컬럼: ${interpretationCol} (${columnLetter(interpretationCol)})`);
  console.log(`short_ko 컬럼: ${shortKoCol} (${columnLetter(shortKoCol)})`);

  // 2. 전체 데이터 읽기 (verse_id, reference, mode, interpretation)
  console.log('\n전체 데이터 읽는 중...');
  const dataRes = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:Z`,
  });
  const rows = dataRes.data.values;

  // 3. 대상 verse_id 행 번호 찾기
  const targetIds = Object.keys(NEW_INTERPRETATIONS);
  const rowMap = {}; // verse_id -> row index (0-based)

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const vid = row[verseIdCol];
    if (vid && targetIds.includes(vid)) {
      rowMap[vid] = i + 1; // 1-based row number for Sheets API
    }
  }

  console.log('\n찾은 행 번호:');
  for (const [vid, rowNum] of Object.entries(rowMap)) {
    const row = rows[rowNum - 1];
    const ref = row[referenceCol] || '';
    const mode = row[modeCol] || '';
    const currentInterp = row[interpretationCol] || '';
    console.log(`  ${vid} (행 ${rowNum}): ${ref} | mode: ${mode}`);
    console.log(`    현재 interpretation: ${currentInterp.substring(0, 60)}...`);
  }

  // 4. 글자수 확인
  console.log('\n새 interpretation 글자수 확인:');
  for (const [vid, text] of Object.entries(NEW_INTERPRETATIONS)) {
    const len = text.length;
    const status = len <= 200 ? '✅' : '❌ 초과';
    console.log(`  ${vid}: ${len}자 ${status}`);
    if (len > 200) {
      console.log(`    텍스트: ${text}`);
    }
  }

  // 5. 업데이트 실행
  console.log('\nGoogle Sheets 업데이트 시작...');
  const interpColLetter = columnLetter(interpretationCol);

  const results = [];

  for (const [vid, newText] of Object.entries(NEW_INTERPRETATIONS)) {
    const rowNum = rowMap[vid];
    if (!rowNum) {
      console.log(`  ⚠️  ${vid}: 행을 찾지 못함`);
      results.push({ vid, status: '행 없음', rowNum: null });
      continue;
    }

    const range = `${SHEET_NAME}!${interpColLetter}${rowNum}`;
    try {
      await sheets.spreadsheets.values.update({
        spreadsheetId: SHEET_ID,
        range,
        valueInputOption: 'RAW',
        requestBody: { values: [[newText]] },
      });
      console.log(`  ✅ ${vid} (행 ${rowNum}): 업데이트 완료 (${newText.length}자)`);
      results.push({ vid, status: '완료', rowNum, chars: newText.length });
    } catch (err) {
      console.error(`  ❌ ${vid}: 업데이트 실패 — ${err.message}`);
      results.push({ vid, status: '실패', rowNum, error: err.message });
    }
  }

  // 6. 결과 요약
  console.log('\n=== 업데이트 결과 요약 ===');
  console.log(`완료: ${results.filter(r => r.status === '완료').length}개`);
  console.log(`실패: ${results.filter(r => r.status === '실패').length}개`);
  console.log(`행 없음: ${results.filter(r => r.status === '행 없음').length}개`);
}

function columnLetter(idx) {
  let letter = '';
  let n = idx + 1;
  while (n > 0) {
    const rem = (n - 1) % 26;
    letter = String.fromCharCode(65 + rem) + letter;
    n = Math.floor((n - 1) / 26);
  }
  return letter;
}

main().catch(console.error);
