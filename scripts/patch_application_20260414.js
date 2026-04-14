/**
 * patch_application_20260414.js
 *
 * application 필드 대량 수정 — 2026-04-14
 * Firestore verses/ + Google Sheets VERSES 탭 동시 업데이트
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
}
const db = admin.firestore();

// ── 수정 데이터 ───────────────────────────────────────────────────
const PATCHES = [
  { id: 'v_172', field: 'application', newValue: '오늘 밤 알람을 맞추며 하루를 천천히 돌아봐. 하나님이 어디서 너와 함께하셨는지, 작은 흔적 하나를 찾아봐.' },
  { id: 'v_177', field: 'application', newValue: "오늘 밤 알람을 맞추며, '오늘도 목자가 나를 이끌어주셨어'라고 조용히 인정하고 눈 감아봐." },
  { id: 'v_180', field: 'application', newValue: "오늘 밤 알람을 맞추고 화면을 닫아봐. '이제 쉬어도 돼. 하나님이 내일을 준비하신다'고 믿어봐." },
  { id: 'v_119', field: 'application', newValue: '알람 맞추고 핸드폰 엎어놔. 오늘 밤 내일 걱정은 하나님께 맡기는 거야. 잠드는 것도 믿음이야.' },
  { id: 'v_170', field: 'application', newValue: '오늘 밤 알람을 맞추며, 내일 걱정들을 하나씩 내려놓고 주님이 주시는 잠에 들어봐. 쉬는 것도 믿음이야.' },
  { id: 'v_120', field: 'application', newValue: '오늘 밤 잠들기 전에, 내일은 오늘보다 기쁜 날일 거라고 기대해봐. 그 기대를 품고 눈을 감아봐.' },
  { id: 'v_110', field: 'application', newValue: '알람 맞추며 내일 계획도 하나님께 넘겨드려. 이루실 분은 따로 계시거든. 그 믿음으로 편히 자봐.' },
  { id: 'v_147', field: 'application', newValue: '내일 알람이 울리면, 핸드폰 열기 전에 말씀 한 구절만 먼저 읽어봐. 그게 하루의 방향을 잡아줄 거야.' },
  { id: 'v_167', field: 'application', newValue: "내일 알람이 울리면, '오늘은 내 힘이 아니라 주의 힘으로 시작해'라고 떠올리며 일어나봐." },
  { id: 'v_121', field: 'application', newValue: "알람을 맞추면서 오늘의 계획을 하나님께 드려봐. '하나님, 이 하루 인도해주세요'라고 한 번만 말해봐." },
  { id: 'v_175', field: 'application', newValue: "오늘 밤 알람 맞추기 전에, 오늘 하루를 돌아보며 '그래도 하나님은 선하셨어'라고 한 번만 말해봐." },
  { id: 'v_112', field: 'application', newValue: "내일 이 알람이 울릴 때, 눈을 뜨자마자 '오늘은 하나님이 만드신 날이야'라고 한 번만 선언해봐." },
  { id: 'v_126', field: 'application', newValue: '내일 아침 작은 걸음부터 시작해봐. 해가 뜨듯 네 하루가 점점 밝아질 거야. 첫 걸음이면 충분해.' },
  { id: 'v_129', field: 'application', newValue: '오늘 밤 알람 맞추기 전에 딱 1분만 기도해봐. 길지 않아도 괜찮아. 내일을 위한 가장 좋은 준비야.' },
  { id: 'v_149', field: 'application', newValue: '내일 아침 알람이 울릴 때, 어제보다 조금 더 밝아진 하루를 기대하며 눈을 떠봐. 빛은 자라는 거야.' },
  { id: 'v_176', field: 'application', newValue: "오늘 밤 알람을 맞추고 눈을 감아봐. '주께서 밤새 지키신다'는 걸 믿고 그냥 편히 자도 돼, 괜찮아." },
  { id: 'v_156', field: 'application', newValue: "오늘 밤 알람을 맞추며 기도해봐. '내일 아침 주의 인자하심으로 나를 기쁘게 하소서' — 그 한 마디면 충분해." },
  { id: 'v_104', field: 'application', newValue: '내일 일정을 알람에 담아뒀다면, 이제 그 결과는 내려놔도 돼. 준비는 충분히 했어. 이제 쉬어봐.' },
  { id: 'v_173', field: 'application', newValue: '오늘 밤 알람을 맞추며, 오늘의 무거운 것 하나를 예수님 앞에 내려놔봐. 그 무게 없이 눈 감아봐.' },
  { id: 'v_127', field: 'application', newValue: '내일 알람이 울리면 이불을 박차고 일어나봐. 오늘은 믿음으로 깨어 사는 날이야. 그게 시작이야.' },
  { id: 'v_116', field: 'application', newValue: '내일 알람이 울릴 때를 생각해봐. 어떤 어두운 밤도 아침을 막을 수 없어. 그 아침이 오고야 마는 거야.' },
  { id: 'v_117', field: 'application', newValue: '알람을 맞추고 잠깐, 내일 하루를 하나님께 맡기는 기도 한 번 해봐. 길지 않아도 괜찮아.' },
  { id: 'v_123', field: 'application', newValue: '오늘 밤 알람을 맞추며 잠깐 생각해봐. 내일도 하나님이 만드신 날이야. 깨어있는 것, 그게 믿음이야.' },
  { id: 'v_122', field: 'application', newValue: '내일 알람이 울릴 때, 그게 하나님이 너에게 건네는 첫 인사라고 생각해봐. 그 인사에 응답해봐.' },
  { id: 'v_133', field: 'application', newValue: '알람을 맞추는 너는 이미 내일을 향한 소망을 붙잡고 있는 거야. 하나님은 신실하셔, 그 믿음 놓지 마봐.' },
  { id: 'v_171', field: 'application', newValue: '오늘 밤 알람 맞추기 전에, 오늘 하루 감사한 것 딱 하나만 떠올려봐. 아주 작아도 괜찮아, 있을 거야.' },
  { id: 'v_124', field: 'application', newValue: '내일 알람이 울리면, 눈을 뜨자마자 딱 한 가지만 감사해봐. 그 한 마디가 하루를 여는 찬양이 돼.' },
  { id: 'v_113', field: 'application', newValue: '알람을 맞추며 생각해봐. 내일 아침엔 어제의 무거움 없이 새롭게 시작할 수 있어. 하나님의 자비가 새로 와.' },
  { id: 'v_154', field: 'application', newValue: "내일 알람이 울릴 때, '일어나라, 그리스도가 빛을 비추신다'를 한 번 떠올리며 눈을 천천히 떠봐." },
  { id: 'v_137', field: 'application', newValue: '내일 알람이 울릴 때, 오늘 세운 계획을 하나님께 내어드려봐. 결과는 맡기고 걸음은 내딛는 거야.' },
  { id: 'v_115', field: 'application', newValue: "내일 이 알람이 울릴 때, 그게 하나님의 '일어나!'라는 부름이라고 생각해봐. 빛 가운데 서봐." },
  { id: 'v_125', field: 'application', newValue: '알람 맞추고 눈을 감아봐. 오늘 밤은 하나님이 지키셔. 내일 아침도 그분이 깨워주실 거야, 안심해봐.' },
  { id: 'v_145', field: 'application', newValue: '내일 알람이 울릴 때, 일어나자마자 딱 한 줄만 기도해봐. 짧아도 돼. 그 한 줄이 하루의 방향을 바꿔.' },
  { id: 'v_150', field: 'application', newValue: '오늘 밤 알람을 맞추며 천천히 눈을 감아봐. 하나님이 이 밤도, 내일 아침도 붙들어주실 거야, 안심해.' },
  { id: 'v_153', field: 'application', newValue: '내일 알람이 울리면, 예수님처럼 조용한 곳에서 딱 5분이라도 기도해봐. 커피보다 먼저여도 괜찮아.' },
  { id: 'v_179', field: 'application', newValue: '오늘 밤 알람 맞추기 전에, 오늘 하루 선하심의 흔적 하나를 천천히 찾아봐. 분명 있을 거야.' },
  { id: 'v_132', field: 'application', newValue: '알람 맞추기 전에 오늘 마음속 이야기를 하나님께 솔직하게 털어놔봐. 귀 기울이고 계셔, 들으셔.' },
  { id: 'v_157', field: 'application', newValue: "알람을 맞추며 기도해봐. '하나님, 내일도 제가 아직 모르는 놀라운 일을 하나 보여주세요'라고 말해봐." },
  { id: 'v_139', field: 'application', newValue: '오늘 밤 울고 싶으면 울어도 돼. 알람을 맞추며 내일 아침의 기쁨을 조용히 기대해봐. 아침이 올 거야.' },
  { id: 'v_148', field: 'application', newValue: '알람을 맞추며 천천히 생각해봐. 내일 무슨 일이 있어도 하나님이 내 편이야. 그 사실 하나면 충분해.' },
  { id: 'v_136', field: 'application', newValue: '오늘 밤 알람을 맞추며 내일 걱정을 하나님께 맡겨봐. 충분히 맡겼으면 넌 그냥 쉬면 돼, 쉬어봐.' },
  { id: 'v_174', field: 'application', newValue: "오늘 밤 알람을 맞추며, '내일 걱정은 내일 하기로 했어'라고 결정해봐. 그 결정 하나로 눈을 감아봐." },
  { id: 'v_105', field: 'application', newValue: '알람을 맞췄어. 이제 충분히 준비된 거야. 오늘 밤만큼은 내일 걱정 없이 그냥 푹 자도 돼, 괜찮아.' },
  { id: 'v_086', field: 'application', newValue: '저녁 산책이나 창밖을 잠깐 바라보면서, 오늘 하나님의 선하심이 보였던 순간 하나를 떠올려봐, 있을 거야.' },
  { id: 'v_109', field: 'application', newValue: '내일이 걱정돼? 하나님은 이미 내일에 가 계셔. 알람 맞추고 그냥 자도 돼. 먼저 가 계시거든.' },
  { id: 'v_143', field: 'application', newValue: '내일 아침 알람이 울릴 때, 오늘과 다른 새 마음으로 하루를 시작할 수 있다고 믿어봐. 하나님이 주셔.' },
  { id: 'v_131', field: 'application', newValue: '내일 알람이 울리면, 눌리는 게 아니라 네가 새벽을 깨우는 거야. 그 마음으로 일어나봐.' },
  { id: 'v_160', field: 'application', newValue: "내일 알람이 울리면 잠깐 생각해봐. '오늘 하나님이 나를 위해 어떤 새 일을 하실까?' 기대해봐." },
  { id: 'v_168', field: 'application', newValue: "내일 알람이 울리면, '오늘도 달린다'는 마음으로 일어나봐. 완주보다 오늘의 출발이 더 중요해." },
  { id: 'v_134', field: 'application', newValue: '내일 알람이 울리면, 오늘과 다른 새 자비가 아침에 이미 와 있다는 걸 떠올려봐. 새 자비가 기다려.' },
  { id: 'v_142', field: 'application', newValue: "오늘 밤 내일이 걱정된다면, 알람을 맞추며 '하나님이 내일도 함께하셔'라고 조용히 속삭여봐, 괜찮아." },
  { id: 'v_178', field: 'application', newValue: "오늘 밤 알람을 맞추며, '오늘의 눈물이 내일의 기쁨이 될 거야'라고 조용히 믿고 눈을 감아봐." },
  { id: 'v_111', field: 'application', newValue: '알람이 정해진 시간에 울리듯, 하나님도 정해진 때에 응답하셔. 그 기다림이 이미 믿음이야.' },
  { id: 'v_098', field: 'application', newValue: '오늘 아침 딱 5분만 핸드폰 없이 하나님을 바라봐. 그게 독수리가 기류를 찾는 시간이야, 날아오를 거야.' },
  { id: 'v_128', field: 'application', newValue: "오늘이 힘들었다면, 알람을 맞추며 조용히 선언해봐. '나는 내일 다시 일어날 거야.' 그 말이 힘이 돼." },
  { id: 'v_163', field: 'application', newValue: '내일 아침 알람이 울릴 때, 핸드폰을 열기 전에 잠깐 눈을 감고 \'하나님을 먼저 찾는 아침\'으로 시작해봐.' },
  { id: 'v_169', field: 'application', newValue: "내일 알람이 울릴 때, '밤새 주님이 지켜주셨어. 오늘도 함께야'라고 눈 뜨자마자 말해봐." },
  { id: 'v_162', field: 'application', newValue: "내일 알람이 울리면, '나는 하나님의 것이야'라고 한 번만 말해봐. 그 선언 하나로 하루가 달라져." },
  { id: 'v_166', field: 'application', newValue: "내일 알람이 울리면, '나는 하나님의 은혜로 오늘 여기 있어'라고 한 번만 떠올려봐. 그게 충분해." },
  { id: 'v_118', field: 'application', newValue: '오늘 알람을 맞춘 건 내일을 향한 변화의 신호야. 잠들기 전에 하나님께 그 새 마음을 구해봐, 주실 거야.' },
  { id: 'v_151', field: 'application', newValue: "내일 아침 알람이 울릴 때, '오늘은 새 출발이야'라고 한 번 말하며 일어나봐. 어제와 달라도 괜찮아." },
  { id: 'v_009', field: 'application', newValue: '잠 못 드는 이 새벽에도 하나님이 붙들고 계심을 떠올려봐. 새벽도 주의 영역이야, 혼자가 아니야.' },
  { id: 'v_106', field: 'application', newValue: '알람을 맞췄어. 내일 무슨 일이 생기든 하나님 손 안에 있다는 걸 떠올려봐. 이제 편히 자도 돼.' },
  { id: 'v_102', field: 'application', newValue: '내일 아침이 두렵게 느껴진다면, 알람이 울릴 때를 생각해봐. 새 날, 새 일이 시작되는 순간이야.' },
  { id: 'v_050', field: 'application', newValue: '오늘 하루 중 무심코 하는 습관 하나를 멈추고 \'이게 정말 필요한가\' 물어봐. 그 답을 적어두면 좋아.' },
  { id: 'v_003', field: 'application', newValue: '오늘 버거운 일이 있어도 떠올려봐. 네가 서 있는 그 자리는 이미 이긴 편이야. 담대하게 나아가봐.' },
  { id: 'v_045', field: 'application', newValue: '오늘 하루 중 이해 안 되는 상황 하나를 떠올리고, 그걸 주님께 맡겨봐. 주님의 생각이 더 높다는 걸 알아봐.' },
  { id: 'v_001', field: 'application', newValue: '오늘 버거운 일이 앞에 있다면 떠올려봐. 네 힘으로 다 감당하려 하지 않아도 돼. 붙들어주시는 분 안에 머무는 것, 그게 먼저야.' },
];

// ── Google Sheets 열 문자 변환 ─────────────────────────────────────
function colLetter(n) {
  let s = ''; let x = n + 1;
  while (x > 0) { s = String.fromCharCode(65 + ((x - 1) % 26)) + s; x = Math.floor((x - 1) / 26); }
  return s;
}

// ── Google Sheets 업데이트 ────────────────────────────────────────
async function updateSheet(patches, rowMap, headers) {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(__dirname, SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const appCol = headers.indexOf('application');
  if (appCol === -1) { console.error('application 컬럼을 찾을 수 없습니다.'); return; }

  const batchData = [];
  for (const p of patches) {
    const rowNum = rowMap[p.id];
    if (!rowNum) { console.warn(`  WARN  ${p.id} 행 번호 없음 — 스킵`); continue; }
    batchData.push({
      range: `${SHEET_NAME}!${colLetter(appCol)}${rowNum}`,
      values: [[p.newValue]]
    });
  }

  if (batchData.length === 0) { console.log('  시트: 업데이트 없음'); return; }

  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: { valueInputOption: 'RAW', data: batchData }
  });
  console.log(`  시트 ${batchData.length}개 셀 업데이트 완료`);
}

// ── 메인 ────────────────────────────────────────────────────────
async function main() {
  console.log('\n[1/3] Google Sheets 행 번호 조회 중...');

  const auth = new google.auth.GoogleAuth({
    keyFile: path.resolve(__dirname, SERVICE_ACCOUNT_PATH),
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:N`
  });
  const rows = res.data.values || [];
  const headers = rows[0];
  const idCol = headers.indexOf('verse_id');

  // verse_id → 행 번호(1-based) 맵 생성
  const rowMap = {};
  for (let i = 1; i < rows.length; i++) {
    const vid = (rows[i][idCol] || '').trim();
    if (vid) rowMap[vid] = i + 1;
  }

  const targetIds = [...new Set(PATCHES.map(p => p.id))];
  let notFound = [];
  for (const id of targetIds) {
    if (!rowMap[id]) notFound.push(id);
  }
  if (notFound.length > 0) {
    console.log(`  WARN: 시트에서 찾지 못한 verse_id: ${notFound.join(', ')}`);
  }
  console.log(`  총 ${targetIds.length}개 verse_id 확인 (미발견: ${notFound.length}개)`);

  console.log('\n[2/3] Firestore 업데이트 중...');
  const firestoreUpdates = {};
  for (const p of PATCHES) {
    if (!firestoreUpdates[p.id]) firestoreUpdates[p.id] = {};
    firestoreUpdates[p.id][p.field] = p.newValue;
  }

  // Firestore는 500건 단위 batch 제한
  const ids = Object.keys(firestoreUpdates);
  const BATCH_SIZE = 400;
  let processed = 0;
  for (let i = 0; i < ids.length; i += BATCH_SIZE) {
    const chunk = ids.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const id of chunk) {
      batch.update(db.collection('verses').doc(id), firestoreUpdates[id]);
    }
    await batch.commit();
    processed += chunk.length;
    console.log(`  Firestore ${processed}/${ids.length} 완료`);
  }
  console.log(`  Firestore 총 ${ids.length}개 문서 업데이트 완료`);

  console.log('\n[3/3] Google Sheets 업데이트 중...');
  await updateSheet(PATCHES, rowMap, headers);

  console.log('\n완료! 총 ' + ids.length + '개 verse 업데이트됨.');
  console.log('업데이트된 verse_id 목록:');
  ids.forEach(id => console.log('  ' + id));
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
