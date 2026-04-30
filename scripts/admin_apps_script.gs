// ============================================================
// morning manna — Google Sheets Apps Script v3.1
// 전체 관리 기능 통합 (VERSE_PREVIEW + 말씀/이미지 동기화)
// ============================================================
// 설치: 확장 프로그램 → Apps Script → 이 코드 전체 붙여넣기 → 저장
// onOpen 실행 → 권한 허용 → 시트에 [🔮 말씀 관리] 메뉴 생성
// setupTimeTrigger 실행 → 매일 01:30 자동 갱신 등록
// ============================================================
// Script Properties 설정 필요 (말씀/이미지 동기화 버튼 사용 시):
//   FIREBASE_PRIVATE_KEY  : serviceAccountKey.json의 private_key
//   FIREBASE_CLIENT_EMAIL : serviceAccountKey.json의 client_email
// ============================================================

var GET_URL    = 'https://asia-northeast3-dailyverse-9260d.cloudfunctions.net/getVerseSchedule';
var APPLY_URL  = 'https://asia-northeast3-dailyverse-9260d.cloudfunctions.net/applyVerseOverrides';
var PREVIEW_URL= 'https://asia-northeast3-dailyverse-9260d.cloudfunctions.net/triggerPreview';
var SHEET_ID   = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
var PROJECT_ID = 'dailyverse-9260d';
var FS_BASE    = 'https://firestore.googleapis.com/v1/projects/' + PROJECT_ID + '/databases/(default)/documents';

// Firestore 필드 타입 정의
var ARRAY_FIELDS = ['mode', 'theme', 'mood', 'season', 'weather'];
var INT_FIELDS   = ['chapter', 'verse', 'usage_count', 'cooldown_days', 'show_count'];
var BOOL_FIELDS  = ['curated'];

// ── 메뉴 등록 ──────────────────────────────────────────────
function onOpen() {
  var ui = SpreadsheetApp.getUi();
  ui.createMenu('🔮 말씀 관리')
    .addSubMenu(ui.createMenu('📖 말씀')
      .addItem('말씀 → Firestore 동기화', 'syncVersesToFirestore')
      .addSeparator()
      .addItem('이미지 상태 동기화', 'syncImageStatus')
      .addItem('배경 이미지 상태 동기화', 'syncBackgroundImageStatus'))
    .addSeparator()
    .addSubMenu(ui.createMenu('🔮 말씀 미리보기')
      .addItem('미리보기 새로고침', 'refreshVersePreview')
      .addItem('✅ 적용하기 (변경사항 저장)', 'applyVerseOverrides'))
    .addSeparator()
    .addSubMenu(ui.createMenu('📅 오늘의 말씀')
      .addItem('오늘 말씀 강제 갱신', 'triggerDailyVerse'))
    .addSeparator()
    .addItem('⚙️ 자동 갱신 트리거 설정', 'setupTimeTrigger')
    .addToUi();
}

// ── 1. 말씀 → Firestore 동기화 ─────────────────────────────
function syncVersesToFirestore() {
  var ui = SpreadsheetApp.getUi();
  var confirm = ui.alert(
    '말씀 동기화',
    'VERSES 탭 전체를 Firestore에 동기화합니다.\n시간이 걸릴 수 있습니다.\n진행하시겠습니까?',
    ui.ButtonSet.YES_NO
  );
  if (confirm !== ui.Button.YES) return;

  var ss = SpreadsheetApp.openById(SHEET_ID);
  var sheet = ss.getSheetByName('VERSES');
  if (!sheet) { ui.alert('VERSES 탭을 찾을 수 없습니다.'); return; }

  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  var data = sheet.getRange(2, 1, sheet.getLastRow() - 1, sheet.getLastColumn()).getValues();

  var token = getFirebaseToken_();
  var synced = 0;
  var errors = 0;

  for (var i = 0; i < data.length; i++) {
    var row = data[i];
    var obj = {};
    for (var j = 0; j < headers.length; j++) {
      if (headers[j]) obj[headers[j]] = row[j];
    }
    if (!obj.verse_id || obj.status !== 'active') continue;

    var docData = buildVerseDocument_(obj);
    var fieldPaths = Object.keys(docData.fields).map(function(k) {
      return 'updateMask.fieldPaths=' + k;
    }).join('&');
    var url = FS_BASE + '/verses/' + obj.verse_id + '?' + fieldPaths;

    try {
      var resp = UrlFetchApp.fetch(url, {
        method: 'PATCH',
        headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
        payload: JSON.stringify(docData),
        muteHttpExceptions: true
      });
      if (resp.getResponseCode() === 200) { synced++; } else { errors++; }
    } catch (e) { errors++; }

    if ((synced + errors) % 50 === 0) {
      SpreadsheetApp.flush();
    }
  }

  ui.alert('동기화 완료', '성공: ' + synced + '개 | 오류: ' + errors + '개', ui.ButtonSet.OK);
}

function buildVerseDocument_(obj) {
  var fields = {};
  var skip = ['verse_id'];

  for (var k in obj) {
    if (!k || skip.indexOf(k) >= 0) continue;
    var v = obj[k];
    if (v === '' || v === null || v === undefined) continue;

    var str = String(v).trim();
    if (str === '') continue;

    if (BOOL_FIELDS.indexOf(k) >= 0) {
      fields[k] = { booleanValue: str === 'true' || str === 'TRUE' || str === '1' };
    } else if (INT_FIELDS.indexOf(k) >= 0) {
      var intVal = parseInt(str, 10);
      fields[k] = { integerValue: String(isNaN(intVal) ? 0 : intVal) };
    } else if (ARRAY_FIELDS.indexOf(k) >= 0) {
      var items = str.split(',').map(function(s) { return s.trim(); }).filter(function(s) { return s !== ''; });
      if (items.length === 0) items = ['all'];
      fields[k] = { arrayValue: { values: items.map(function(s) { return { stringValue: s }; }) } };
    } else if (v === true || str === 'TRUE' || str === 'true') {
      fields[k] = { booleanValue: true };
    } else if (v === false || str === 'FALSE' || str === 'false') {
      fields[k] = { booleanValue: false };
    } else {
      fields[k] = { stringValue: str };
    }
  }
  return { fields: fields };
}

// ── 2. 이미지 상태 동기화 ────────────────────────────────────
function syncImageStatus() {
  syncSheetStatusToFirestore_('VERSE_IMAGES', 'image_id', 'images');
}

function syncBackgroundImageStatus() {
  syncSheetStatusToFirestore_('BACKGROUND_IMAGES', 'image_id', 'background_images');
}

function syncSheetStatusToFirestore_(tabName, idColName, collection) {
  var ui = SpreadsheetApp.getUi();
  var ss = SpreadsheetApp.openById(SHEET_ID);
  var sheet = ss.getSheetByName(tabName);
  if (!sheet) { ui.alert(tabName + ' 탭을 찾을 수 없습니다.'); return; }

  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  var data = sheet.getRange(2, 1, sheet.getLastRow() - 1, sheet.getLastColumn()).getValues();

  var idIdx = headers.indexOf(idColName);
  var statusIdx = headers.indexOf('status');
  if (idIdx < 0 || statusIdx < 0) {
    ui.alert('image_id 또는 status 컬럼을 찾을 수 없습니다.');
    return;
  }

  var token = getFirebaseToken_();
  var synced = 0;

  for (var i = 0; i < data.length; i++) {
    var id = data[i][idIdx];
    var status = data[i][statusIdx];
    if (!id || !status) continue;

    var url = FS_BASE + '/' + collection + '/' + id + '?updateMask.fieldPaths=status';
    UrlFetchApp.fetch(url, {
      method: 'PATCH',
      headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
      payload: JSON.stringify({ fields: { status: { stringValue: String(status) } } }),
      muteHttpExceptions: true
    });
    synced++;
  }

  ui.alert(tabName + ' 상태 동기화 완료', synced + '개 처리됨', ui.ButtonSet.OK);
}

// ── 3. VERSE_PREVIEW 새로고침 ────────────────────────────────
// VERSE_PREVIEW 컬럼 레이아웃 (A~S, 19컬럼):
//   A=date, B=day, C=선택, D=verse_id, E=reference, F=verse_short,
//   G=verse_full_ko, H=interpretation, I=theme, J=show_count,
//   K=last_shown, L=days_since, M=cooldown_days, N=cooldown_ok,
//   O=alt_1, P=alt_2, Q=alt_3, R=status, S=notes
function refreshVersePreview() {
  try {
    var resp = UrlFetchApp.fetch(GET_URL, { method: 'get', muteHttpExceptions: true });
    var data = JSON.parse(resp.getContentText());
    var schedules = data.schedules || [];
    var ss = SpreadsheetApp.openById(SHEET_ID);
    var sheet = ss.getSheetByName('VERSE_PREVIEW');
    if (!sheet) { SpreadsheetApp.getUi().alert('VERSE_PREVIEW 탭 없음'); return; }

    var dayLabels = ['D (오늘)', 'D+1', 'D+2'];
    for (var i = 0; i < Math.min(schedules.length, 3); i++) {
      var s = schedules[i];
      var row = i + 2;
      var currentSel  = sheet.getRange(row, 3).getValue();
      var currentNote = sheet.getRange(row, 19).getValue(); // S열 = notes

      sheet.getRange(row, 1, 1, 19).setValues([[
        s.date            || '',
        dayLabels[i],
        currentSel        || 1,
        s.verse_id        || '',
        s.reference       || '',
        s.verse_short     || '',
        s.verse_full      || '',
        s.interpretation  || '',
        s.theme           || '',
        s.show_count      != null ? s.show_count : '',
        s.last_shown      || '',
        s.days_since      != null ? s.days_since : '',
        s.cooldown_days   != null ? s.cooldown_days : '',
        s.cooldown_ok === true ? '✅ OK' : (s.cooldown_ok === false ? '⚠️ 짧음' : ''),
        s.alt_1           || '',
        s.alt_2           || '',
        s.alt_3           || '',
        s.status          || '',
        currentNote       || ''
      ]]);
    }
    SpreadsheetApp.getUi().alert('✅ 미리보기 새로고침 완료 (' + new Date().toLocaleString('ko-KR') + ')');
  } catch (e) {
    SpreadsheetApp.getUi().alert('오류: ' + e.message);
  }
}

// ── 4. VERSE_PREVIEW 적용하기 ────────────────────────────────
function applyVerseOverrides() {
  var ui = SpreadsheetApp.getUi();
  var ss = SpreadsheetApp.openById(SHEET_ID);
  var sheet = ss.getSheetByName('VERSE_PREVIEW');
  if (!sheet) { ui.alert('VERSE_PREVIEW 탭 없음'); return; }

  var overrides = [];
  for (var row = 3; row <= 4; row++) { // D+1, D+2만 처리 (D=오늘은 이미 확정)
    var date      = sheet.getRange(row, 1).getValue();
    var selection = sheet.getRange(row, 3).getValue();
    var notes     = sheet.getRange(row, 19).getValue(); // S열 = notes
    if (!date) continue;
    overrides.push({
      date:      String(date).trim(),
      selection: selection || 1,
      notes:     String(notes || '')
    });
  }

  if (!overrides.length) { ui.alert('적용할 항목이 없습니다.'); return; }

  var preview = overrides.map(function(o) {
    return (o.selection == 1 || o.selection === '') ? o.date + ': auto 유지' : o.date + ': 선택 ' + o.selection + ' 적용';
  }).join('\n');

  if (ui.alert('적용 확인', preview + '\n\n진행하시겠습니까?', ui.ButtonSet.YES_NO) !== ui.Button.YES) return;

  try {
    var resp = UrlFetchApp.fetch(APPLY_URL, {
      method: 'post',
      contentType: 'application/json',
      payload: JSON.stringify({ overrides: overrides }),
      muteHttpExceptions: true
    });
    var result = JSON.parse(resp.getContentText());
    var summary = (result.results || []).map(function(r) {
      return r.status === 'ok' ? '✅ ' + r.date + ': ' + r.reference : '❌ ' + r.date + ': ' + r.message;
    }).join('\n');
    ui.alert('적용 완료', summary, ui.ButtonSet.OK);
  } catch (e) {
    ui.alert('오류: ' + e.message);
  }
}

// ── 5. 오늘 말씀 강제 갱신 ──────────────────────────────────
function triggerDailyVerse() {
  var ui = SpreadsheetApp.getUi();
  try {
    var resp = UrlFetchApp.fetch(PREVIEW_URL, { method: 'get', muteHttpExceptions: true });
    var data = JSON.parse(resp.getContentText());
    ui.alert('✅ 오늘 말씀 갱신 완료', (data.dates || []).join('\n'), ui.ButtonSet.OK);
  } catch (e) {
    ui.alert('오류: ' + e.message);
  }
}

// ── 6. 자동 트리거 설정 ─────────────────────────────────────
function setupTimeTrigger() {
  var triggers = ScriptApp.getProjectTriggers();
  for (var i = 0; i < triggers.length; i++) {
    if (triggers[i].getHandlerFunction() === 'refreshVersePreview') {
      ScriptApp.deleteTrigger(triggers[i]);
    }
  }
  ScriptApp.newTrigger('refreshVersePreview')
    .timeBased()
    .atHour(1)
    .nearMinute(30)
    .everyDays(1)
    .inTimezone('Asia/Seoul')
    .create();
  SpreadsheetApp.getUi().alert('✅ 매일 01:30 KST 자동 갱신 트리거 설정 완료');
}

// ── Firebase 인증 토큰 (Service Account JWT) ─────────────────
function getFirebaseToken_() {
  var props = PropertiesService.getScriptProperties();
  var privateKey = props.getProperty('FIREBASE_PRIVATE_KEY');
  var clientEmail = props.getProperty('FIREBASE_CLIENT_EMAIL');

  if (privateKey) {
    privateKey = privateKey.replace(/\\n/g, '\n');
  }

  if (!privateKey || !clientEmail) {
    throw new Error(
      'Script Properties 설정 필요:\n' +
      '1. Apps Script → 프로젝트 설정 → 스크립트 속성\n' +
      '2. FIREBASE_PRIVATE_KEY: serviceAccountKey.json의 private_key 값\n' +
      '3. FIREBASE_CLIENT_EMAIL: serviceAccountKey.json의 client_email 값'
    );
  }

  var now = Math.floor(Date.now() / 1000);
  var header = Utilities.base64EncodeWebSafe(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  var claim = Utilities.base64EncodeWebSafe(JSON.stringify({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/spreadsheets',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  }));

  var toSign = header + '.' + claim;
  var signature = Utilities.computeRsaSha256Signature(toSign, privateKey);
  var jwt = toSign + '.' + Utilities.base64EncodeWebSafe(signature);

  var tokenResp = UrlFetchApp.fetch('https://oauth2.googleapis.com/token', {
    method: 'post',
    payload: {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    }
  });
  return JSON.parse(tokenResp.getContentText()).access_token;
}
