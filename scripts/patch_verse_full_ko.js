/**
 * DailyVerse — verse_full_ko 일괄 패치 스크립트
 *
 * 처리 대상:
 *   - Firestore verses/ 컬렉션 → verse_full_ko 필드 업데이트
 *   - Google Sheets VERSES 탭 → C열(verse_full_ko) 업데이트
 *
 * 사용법:
 *   node patch_verse_full_ko.js
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

// ─── 설정 ──────────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, 'serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

// ─── 수정 데이터 ────────────────────────────────────────────────────────────
const PATCHES = {
  v_001: "나는 비천함과 풍요로움 모두 경험했고, 배고픔과 배부름, 궁핍과 풍성함 안에서도 평온을 누리는 비결을 배웠다.\n나에게 힘을 주시는 분 안에서, 나는 모든 것을 해낼 수 있다.",
  v_002: "여호와는 나의 목자, 내게 부족함이 없다.\n그분은 나를 푸른 풀밭에 눕히시고, 잔잔한 물가로 이끄신다.\n내 영혼을 새롭게 회복시키신다.",
  v_003: "세상에서는 너희가 환난을 당하겠지만 담대하라.\n내가 세상을 이겼다. 이것을 너희에게 이르는 것은 너희가 내 안에서 평안을 누리게 하려 함이다.",
  v_004: "주의 말씀은 내 발의 등불, 내 길의 빛이다.\n주의 의로운 규례들을 지키기로 맹세하고 굳게 다짐했다.",
  v_006: "나는 비천함과 풍요로움 모두 경험했고, 배고픔과 배부름, 궁핍과 풍성함 안에서도 평온을 누리는 비결을 배웠다.\n나에게 힘을 주시는 분 안에서, 나는 모든 것을 해낼 수 있다.",
  v_008: "여호와를 기뻐하라. 그분이 네 마음의 소원을 이루어 주실 것이다.\n네 길을 여호와께 맡기라, 그를 의지하면 그분이 이루신다.",
  v_009: "내가 새벽 날개를 타고 바다 끝에 자리를 잡아도, 거기서도 주의 손이 나를 이끄시고 주의 오른손이 나를 붙잡으신다.",
  v_010: "내가 주의 영을 피해 어디로 갈 수 있을까.\n하늘로 올라가도 거기 계시고, 스올에 자리를 펼쳐도 거기 계신다.",
  v_011: "오직 여호와를 기다리며 바라는 자는 새 힘을 얻는다.\n독수리처럼 날아오르고, 달려도 지치지 않으며, 걸어도 피곤하지 않다.",
  v_015: "조용히 있어라, 내가 하나님임을 알라.\n나는 모든 나라에서, 온 세상에서 높임을 받을 것이다.",
  v_016: "복이 있는 사람은 여호와를 신뢰하고 의지하는 자다.\n그는 물가에 심긴 나무처럼 가뭄에도 잎이 푸르고, 더위가 와도 두려워하지 않으며 끊임없이 열매를 맺는다.",
  v_019: "우리 안에서 역사하시는 능력대로, 우리가 구하거나 생각하는 모든 것보다 훨씬 더 넘치도록 이루실 수 있는 분께 영광이 있다.",
  v_021: "내가 눈을 들어 산을 바라본다.\n나의 도움은 어디서 오는가. 나의 도움은 하늘과 땅을 만드신 여호와에게서 온다.",
  v_023: "그러므로 우리는 긍휼을 받고 필요한 때에 도움의 은혜를 얻기 위해 은혜의 보좌 앞에 담대히 나아가자.",
  v_024: "사랑 안에는 두려움이 없다. 온전한 사랑이 두려움을 내쫓는다.\n두려움에는 형벌이 따르며, 두려워하는 자는 아직 사랑 안에서 온전함에 이르지 못한 것이다.",
  v_025: "소망의 하나님이 믿음 안에서 모든 기쁨과 평강으로 너희를 충만하게 하시고, 성령의 능력으로 소망이 넘치게 하시기를 바란다.",
  v_027: "여호와는 마음이 상한 자를 가까이 하시고, 통회하는 자를 구원하신다.",
  v_030: "그분은 자신의 깃으로 너를 덮으시고, 그 날개 아래 너는 피할 수 있다.\n그분의 신실하심은 방패가 되신다.",
  v_037: "이 하나님이 힘으로 나를 강하게 하시고, 내 길을 완전하게 하신다.",
  v_038: "우리가 잠시 받는 가벼운 환난이, 비할 수 없이 크고 영원한 영광을 우리에게 이루어 준다.",
  v_042: "나의 영혼아, 잠잠히 하나님만 바라라.\n나의 모든 소망은 오직 그분에게서 온다.",
  v_043: "작은 무리여, 두려워하지 말라.\n너희 아버지께서는 그 나라를 너희에게 주시기를 기뻐하신다.",
  v_044: "도둑이 오는 것은 훔치고, 죽이고, 멸망시키려는 것이다.\n내가 온 것은 양들이 생명을 얻고 더욱 풍성히 누리게 하려 함이다.",
  v_046: "찬송받으실 분이시다. 그분은 자비의 아버지, 모든 위로의 하나님이시다.\n우리의 모든 환난 중에서 우리를 위로하셔서, 우리도 다른 이들을 위로할 수 있게 하신다.",
  v_051: "내가 언제나 여호와를 내 앞에 모신다.\n그분이 내 오른쪽에 계시니 나는 흔들리지 않는다.",
  v_055: "의인은 일곱 번 넘어져도 다시 일어난다.\n그러나 악인은 재앙으로 쓰러진다.",
  v_057: "여호와는 은혜로우시고 자비로우시며, 노하기를 더디 하시고 인자하심이 크시다.",
  v_058: "그분은 갈망하는 영혼에게 만족을 주시고, 주린 영혼을 좋은 것으로 채워 주신다.",
  v_062: "너희 마음의 눈을 밝혀, 그분의 부르심이 품은 소망이 무엇이며, 성도 안에서 주어진 기업의 영광이 얼마나 풍성한지 알게 하시기를 바란다.",
  v_067: "나의 영혼아, 잠잠히 하나님만 바라라.\n나의 모든 소망은 오직 그분에게서 온다.",
  v_072: "사랑하는 자들아, 스스로 원수를 갚으려 하지 말고 하나님의 진노에 맡기라.\n'원수 갚는 것은 내게 있다, 내가 갚겠다'고 주께서 말씀하신다.",
  v_077: "여호와를 의지하고 선을 행하라. 이 땅에 사는 동안 그분의 신실하심을 의지하라.\n여호와를 기뻐하라, 그분이 네 마음의 소원을 이루어 주실 것이다.",
  v_078: "여호와께 감사하라, 그는 선하시고 그 인자하심은 영원하다.\n여호와께 구원받은 자들아, 이 말을 전하라.",
  v_080: "내 침상에서 주를 기억하며, 밤중에 주를 묵상한다.",
  v_087: "낮에는 여호와께서 인자하심을 베푸시고, 밤에는 그분을 향한 찬송이 내 안에 있어 생명의 하나님께 기도한다.",
  v_088: "나의 반석, 나의 구속자이신 여호와여, 내 입의 말과 마음의 묵상이 주님 앞에 받으실 만한 것이 되기를 원합니다.",
  v_091: "나는 너희를 향한 내 계획을 안다. 평안을 주려는 것이요 재앙이 아니다.\n너희에게 미래와 희망을 주려 함이다.",
  v_096: "여호와는 나의 목자, 내게 부족함이 없다.\n그분은 나를 푸른 풀밭에 눕히시고 잔잔한 물가로 이끄신다.",
  v_097: "비파야, 수금아, 깨어라. 내가 새벽을 깨우리라.\n여호와여, 내가 모든 민족 가운데서 주께 감사하고 뭇 나라 가운데서 주를 찬송하리라.",
  v_098: "오직 여호와를 기다리며 바라는 자는 새 힘을 얻는다.\n독수리처럼 날아오르고, 달려도 지치지 않으며, 걸어도 피곤하지 않다.",
  v_106: "우리가 알거니와, 하나님을 사랑하는 자 곧 그의 뜻대로 부르심을 입은 자들에게는 모든 것이 합력하여 선을 이룬다.",
  v_107: "아무것도 염려하지 말고, 모든 일에 기도와 간구로,\n감사함으로 하나님께 아뢰라.",
  v_108: "아침마다 주의 인자한 말씀을 듣게 하소서. 내가 주를 의지합니다.\n내가 걸어갈 길을 알게 하소서. 내 영혼이 주를 향해 올려드립니다.",
  v_109: "여호와께서 네 앞에서 가시며 너와 함께 하신다.\n결코 너를 떠나지도, 버리지도 않으실 것이다. 두려워하지 말라, 놀라지 말라.",
  v_110: "네 길을 여호와께 맡기라. 그를 의지하면 그분이 이루신다.",
  v_111: "이 묵시는 정한 때가 있다. 그 끝이 속히 이를 것이며 결코 거짓이 없다.\n비록 더딜지라도 기다리라. 반드시 이루어진다.",
  v_112: "이것이 여호와께서 만드신 날이다. 우리 함께 기뻐하고 즐거워하자.",
};

// ─── Firebase 초기화 ────────────────────────────────────────────────────────
const serviceAccount = require(SERVICE_ACCOUNT_PATH);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ─── Firestore 패치 ─────────────────────────────────────────────────────────
async function patchFirestore() {
  console.log('\n[Firestore] verse_full_ko 패치 시작...');
  const results = [];

  for (const [verseId, verseFullKo] of Object.entries(PATCHES)) {
    try {
      const ref = db.collection('verses').doc(verseId);
      const snap = await ref.get();
      if (!snap.exists) {
        console.warn(`  SKIP ${verseId} — Firestore에 문서 없음`);
        results.push({ verseId, status: 'skipped' });
        continue;
      }
      await ref.update({ verse_full_ko: verseFullKo });
      console.log(`  OK   ${verseId}`);
      results.push({ verseId, status: 'ok' });
    } catch (err) {
      console.error(`  ERR  ${verseId}: ${err.message}`);
      results.push({ verseId, status: 'error', error: err.message });
    }
  }

  const ok = results.filter(r => r.status === 'ok').length;
  const skip = results.filter(r => r.status === 'skipped').length;
  const err = results.filter(r => r.status === 'error').length;
  console.log(`\n[Firestore] 완료 — 성공: ${ok}, 스킵: ${skip}, 오류: ${err}`);
  return results;
}

// ─── Google Sheets 패치 ─────────────────────────────────────────────────────
async function patchSheets() {
  console.log('\n[Sheets] verse_full_ko 패치 시작...');

  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  // 전체 A열(verse_id) + C열(verse_full_ko) 읽기
  const response = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:C`,
  });
  const rows = response.data.values || [];
  const headerRow = rows[0];
  const verseIdColIdx = headerRow.indexOf('verse_id');      // A=0
  const verseFullKoColIdx = headerRow.indexOf('verse_full_ko'); // C=2

  if (verseIdColIdx === -1 || verseFullKoColIdx === -1) {
    throw new Error('헤더에서 verse_id 또는 verse_full_ko 컬럼을 찾을 수 없습니다.');
  }

  // verse_id → 행 번호(1-based) 맵핑
  const rowMap = {};
  rows.forEach((row, idx) => {
    if (idx === 0) return; // 헤더 스킵
    const vid = row[verseIdColIdx];
    if (vid) rowMap[vid] = idx + 1; // 1-based
  });

  // 개별 셀 업데이트
  const data = [];
  const results = [];

  for (const [verseId, verseFullKo] of Object.entries(PATCHES)) {
    const rowNum = rowMap[verseId];
    if (!rowNum) {
      console.warn(`  SKIP ${verseId} — Sheets에 행 없음`);
      results.push({ verseId, status: 'skipped' });
      continue;
    }
    // C열 = column index 3 (1-based) → A1 notation: C{rowNum}
    const range = `${SHEET_NAME}!C${rowNum}`;
    data.push({
      range,
      values: [[verseFullKo]],
    });
    console.log(`  QUEUE ${verseId} → 행 ${rowNum}`);
    results.push({ verseId, rowNum, status: 'queued' });
  }

  if (data.length === 0) {
    console.log('[Sheets] 업데이트할 항목 없음');
    return results;
  }

  // batchUpdate 실행
  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: {
      valueInputOption: 'RAW',
      data,
    },
  });

  results.forEach(r => {
    if (r.status === 'queued') r.status = 'ok';
  });

  const ok = results.filter(r => r.status === 'ok').length;
  const skip = results.filter(r => r.status === 'skipped').length;
  console.log(`\n[Sheets] 완료 — 성공: ${ok}, 스킵: ${skip}`);
  return results;
}

// ─── 메인 ───────────────────────────────────────────────────────────────────
async function main() {
  console.log('=== verse_full_ko 일괄 패치 시작 ===');
  console.log(`대상 verse 수: ${Object.keys(PATCHES).length}개`);

  const fsResults = await patchFirestore();
  const shResults = await patchSheets();

  console.log('\n=== 최종 결과 요약 ===');
  console.log('\n[ Firestore ]');
  fsResults.forEach(r => {
    const mark = r.status === 'ok' ? 'OK  ' : r.status === 'skipped' ? 'SKIP' : 'ERR ';
    console.log(`  ${mark}  ${r.verseId}`);
  });

  console.log('\n[ Google Sheets ]');
  shResults.forEach(r => {
    const mark = r.status === 'ok' ? 'OK  ' : r.status === 'skipped' ? 'SKIP' : 'ERR ';
    const rowInfo = r.rowNum ? ` (행 ${r.rowNum})` : '';
    console.log(`  ${mark}  ${r.verseId}${rowInfo}`);
  });

  const fsOk = fsResults.filter(r => r.status === 'ok').length;
  const shOk = shResults.filter(r => r.status === 'ok').length;
  console.log(`\nFirestore: ${fsOk}/${Object.keys(PATCHES).length}건 적용`);
  console.log(`Sheets:    ${shOk}/${Object.keys(PATCHES).length}건 적용`);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
