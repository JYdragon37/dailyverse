/**
 * DailyVerse — Google Sheets → Firestore 업로드 스크립트
 *
 * 사용 방법:
 *   1. Google Sheets 메뉴 → 확장 프로그램 → Apps Script
 *   2. 이 파일 내용을 붙여넣기
 *   3. FIREBASE_PROJECT_ID 상수를 실제 프로젝트 ID로 교체
 *   4. 실행 전 Firestore 보안 규칙을 임시로 allow write: if true; 로 변경
 *   5. uploadVersesToFirestore() 함수 선택 후 실행
 */

// ─── 설정 ─────────────────────────────────────────────────────────────────────
var FIREBASE_PROJECT_ID = "dailyverse-9260d";
var FIRESTORE_BASE_URL =
  "https://firestore.googleapis.com/v1/projects/" +
  FIREBASE_PROJECT_ID +
  "/databases/(default)/documents/";

// 배열 필드로 처리할 컬럼 목록 (쉼표 구분 문자열 → 배열)
var ARRAY_FIELDS = ["mode", "theme", "mood", "season", "weather", "avoid_themes"];

// 정수 필드로 처리할 컬럼 목록
var INT_FIELDS = ["chapter", "verse", "usage_count", "cooldown_days", "show_count"];

// 불리언 필드로 처리할 컬럼 목록
var BOOL_FIELDS = ["curated", "is_sacred_safe"];

// 비어있으면 Firestore에 기록하지 않을 선택적 필드 목록 (null 처리)
var NULLABLE_FIELDS = ["alarm_text_ko", "last_shown", "notes", "source_url"];

// ─── 메인 함수 ────────────────────────────────────────────────────────────────

/**
 * Sheets의 모든 행을 Firestore verses 컬렉션에 업로드합니다.
 * verse_id 컬럼 값이 문서 ID로 사용됩니다.
 */
function uploadVersesToFirestore() {
  // 활성 탭이 아닌 "VERSES" 탭을 명시적으로 지정
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("VERSES");
  if (!sheet) {
    SpreadsheetApp.getUi().alert("오류", '"VERSES" 시트를 찾을 수 없습니다.', SpreadsheetApp.getUi().ButtonSet.OK);
    return;
  }
  var data = sheet.getDataRange().getValues();

  if (data.length < 2) {
    Logger.log("데이터가 없습니다. 헤더 행 포함 최소 2행이 필요합니다.");
    return;
  }

  // 첫 번째 행을 헤더로 사용
  var headers = data[0].map(function (h) {
    return String(h).trim();
  });

  Logger.log("감지된 컬럼: " + headers.join(", "));

  var successCount = 0;
  var failCount = 0;
  var failedRows = [];

  // 2번째 행부터 데이터 처리
  for (var i = 1; i < data.length; i++) {
    var row = data[i];

    // verse_id가 없으면 스킵
    var verseIdIndex = headers.indexOf("verse_id");
    if (verseIdIndex === -1) {
      Logger.log("오류: 'verse_id' 컬럼이 없습니다. 스크립트를 종료합니다.");
      return;
    }

    var verseId = String(row[verseIdIndex]).trim();
    if (verseId === "" || verseId === "undefined") {
      Logger.log("행 " + (i + 1) + " 스킵: verse_id가 비어있음");
      continue;
    }

    // 행 데이터를 Firestore 문서 형식으로 변환
    var firestoreDoc = buildFirestoreDocument(headers, row);

    // Firestore REST API로 업로드
    var success = upsertDocument("verses", verseId, firestoreDoc);

    if (success) {
      successCount++;
      Logger.log("성공 [" + (i + 1) + "/" + (data.length - 1) + "]: " + verseId);
    } else {
      failCount++;
      failedRows.push("행 " + (i + 1) + " (" + verseId + ")");
      Logger.log("실패 [" + (i + 1) + "]: " + verseId);
    }

    // API 레이트 리밋 방지 (100ms 대기)
    Utilities.sleep(100);
  }

  var summary =
    "업로드 완료: " + successCount + "개 성공, " + failCount + "개 실패";
  Logger.log(summary);

  if (failedRows.length > 0) {
    Logger.log("실패한 행 목록:\n" + failedRows.join("\n"));
  }

  // 결과를 알림으로 표시
  SpreadsheetApp.getUi().alert(
    "업로드 결과",
    summary +
      (failedRows.length > 0
        ? "\n\n실패한 항목:\n" + failedRows.join("\n")
        : ""),
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

// ─── Firestore 문서 빌더 ──────────────────────────────────────────────────────

/**
 * 헤더와 행 데이터를 Firestore REST API 형식의 fields 객체로 변환합니다.
 *
 * Firestore REST API 필드 타입:
 *   문자열  → { stringValue: "..." }
 *   정수    → { integerValue: "숫자" }  ← 문자열로 전송해야 함
 *   불리언  → { booleanValue: true/false }
 *   배열    → { arrayValue: { values: [...] } }
 */
function buildFirestoreDocument(headers, row) {
  var fields = {};

  for (var j = 0; j < headers.length; j++) {
    var key = headers[j];
    var rawValue = row[j];

    if (key === "" || key === undefined) continue;

    var converted = convertToFirestoreValue(key, rawValue);
    // null 반환 = 비어있는 nullable 필드 → Firestore에 기록하지 않음
    if (converted !== null) {
      fields[key] = converted;
    }
  }

  // 기본값 처리: Sheets에 없는 필드들
  if (!fields.hasOwnProperty("status") || isEmptyFirestoreValue(fields.status)) {
    fields["status"] = { stringValue: "active" };
  }

  if (!fields.hasOwnProperty("curated") || isEmptyFirestoreValue(fields.curated)) {
    fields["curated"] = { booleanValue: true };
  }

  if (!fields.hasOwnProperty("usage_count") || isEmptyFirestoreValue(fields.usage_count)) {
    fields["usage_count"] = { integerValue: "0" };
  }

  return { fields: fields };
}

/**
 * 필드 키와 원시 값을 Firestore 타입 객체로 변환합니다.
 */
function convertToFirestoreValue(key, rawValue) {
  var strValue = String(rawValue).trim();

  // nullable 필드: 비어있으면 null 반환 (Firestore에 기록 안 함)
  if (NULLABLE_FIELDS.indexOf(key) !== -1 && strValue === "") {
    return null;
  }

  // 배열 필드 처리 (쉼표 구분 문자열 → arrayValue)
  if (ARRAY_FIELDS.indexOf(key) !== -1) {
    var items = strValue
      .split(",")
      .map(function (s) { return s.trim(); })
      .filter(function (s) { return s !== ""; });

    if (items.length === 0) {
      items = ["all"]; // 배열이 비어있으면 "all"로 폴백
    }

    return {
      arrayValue: {
        values: items.map(function (item) {
          return { stringValue: item };
        })
      }
    };
  }

  // 정수 필드 처리
  if (INT_FIELDS.indexOf(key) !== -1) {
    var intVal = parseInt(strValue, 10);
    return { integerValue: String(isNaN(intVal) ? 0 : intVal) };
  }

  // 불리언 필드 처리
  if (BOOL_FIELDS.indexOf(key) !== -1) {
    var boolVal =
      strValue.toLowerCase() === "true" ||
      strValue === "1" ||
      strValue.toLowerCase() === "yes";
    return { booleanValue: boolVal };
  }

  // 기본: 문자열 필드
  return { stringValue: strValue };
}

/**
 * Firestore 필드 값이 비어있는지 확인합니다.
 */
function isEmptyFirestoreValue(fieldObj) {
  if (!fieldObj) return true;
  if (fieldObj.stringValue !== undefined) return fieldObj.stringValue.trim() === "";
  if (fieldObj.integerValue !== undefined) return false;
  if (fieldObj.booleanValue !== undefined) return false;
  if (fieldObj.arrayValue !== undefined) {
    return !fieldObj.arrayValue.values || fieldObj.arrayValue.values.length === 0;
  }
  return true;
}

// ─── Firestore REST API ───────────────────────────────────────────────────────

/**
 * Firestore에 문서를 생성하거나 덮어씁니다 (PATCH = upsert).
 *
 * @param {string} collection  컬렉션 이름 (예: "verses")
 * @param {string} documentId  문서 ID (예: "v_001")
 * @param {Object} docBody     Firestore 문서 객체 { fields: {...} }
 * @returns {boolean}          성공 여부
 */
function upsertDocument(collection, documentId, docBody) {
  var url = FIRESTORE_BASE_URL + collection + "/" + documentId;

  var options = {
    method: "PATCH",
    contentType: "application/json",
    payload: JSON.stringify(docBody),
    headers: {
      Authorization: "Bearer " + ScriptApp.getOAuthToken()
    },
    muteHttpExceptions: true // HTTP 오류도 예외 없이 반환
  };

  try {
    var response = UrlFetchApp.fetch(url, options);
    var statusCode = response.getResponseCode();

    if (statusCode === 200) {
      return true;
    } else {
      Logger.log(
        "HTTP 오류 " + statusCode + " for " + documentId + ": " +
        response.getContentText()
      );
      return false;
    }
  } catch (e) {
    Logger.log("예외 발생 for " + documentId + ": " + e.toString());
    return false;
  }
}

// ─── 유틸리티 함수 ────────────────────────────────────────────────────────────

/**
 * 현재 Sheets 데이터의 컬럼 구조를 로그로 출력합니다.
 * 업로드 전 매핑 확인용으로 사용하세요.
 */
function previewSheetStructure() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("VERSES") ||
              SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = sheet.getDataRange().getValues();

  if (data.length === 0) {
    Logger.log("시트가 비어있습니다.");
    return;
  }

  var headers = data[0].map(function (h) { return String(h).trim(); });
  Logger.log("=== 컬럼 구조 ===");
  Logger.log("총 컬럼 수: " + headers.length);
  Logger.log("컬럼 목록: " + headers.join(" | "));
  Logger.log("총 데이터 행 수: " + (data.length - 1));

  if (data.length >= 2) {
    Logger.log("\n=== 첫 번째 데이터 행 미리보기 ===");
    for (var i = 0; i < headers.length; i++) {
      Logger.log(headers[i] + ": " + String(data[1][i]));
    }
  }

  // 필수 컬럼 존재 여부 확인
  var requiredColumns = [
    "verse_id", "text_ko", "text_full_ko", "reference",
    "book", "chapter", "verse", "mode", "theme", "mood",
    "season", "weather", "interpretation", "application",
    "curated", "status", "usage_count", "cooldown_days"
  ];

  Logger.log("\n=== 필수 컬럼 확인 ===");
  requiredColumns.forEach(function (col) {
    var exists = headers.indexOf(col) !== -1;
    Logger.log((exists ? "OK" : "MISSING") + ": " + col);
  });
}

/**
 * 특정 verse_id 하나만 테스트 업로드합니다.
 * 전체 업로드 전에 단일 항목으로 동작을 검증하세요.
 */
function testUploadFirstRow() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("VERSES") ||
              SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = sheet.getDataRange().getValues();

  if (data.length < 2) {
    Logger.log("데이터가 없습니다.");
    return;
  }

  var headers = data[0].map(function (h) { return String(h).trim(); });
  var row = data[1];

  var verseIdIndex = headers.indexOf("verse_id");
  var verseId = String(row[verseIdIndex]).trim();
  var firestoreDoc = buildFirestoreDocument(headers, row);

  Logger.log("=== 테스트 업로드: " + verseId + " ===");
  Logger.log("Firestore 문서 페이로드:");
  Logger.log(JSON.stringify(firestoreDoc, null, 2));

  var success = upsertDocument("verses", verseId, firestoreDoc);
  Logger.log(success ? "테스트 성공" : "테스트 실패 — 로그를 확인하세요");
}

// ─── ALARM_VERSES 업로드 ──────────────────────────────────────────────────────

/**
 * 구글 시트 ALARM_VERSES 탭 → Firestore alarm_verses 컬렉션 업로드.
 * 알람탭 상단 헤더에 표시될 말씀 전용.
 * verse_id 컬럼 값이 문서 ID로 사용됩니다 (av_001 형식).
 */
function uploadAlarmVersesToFirestore() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("ALARM_VERSES");
  if (!sheet) {
    SpreadsheetApp.getUi().alert("오류", '"ALARM_VERSES" 시트를 찾을 수 없습니다.\n구글 시트에서 ALARM_VERSES 탭을 먼저 만들어주세요.', SpreadsheetApp.getUi().ButtonSet.OK);
    return;
  }
  var data = sheet.getDataRange().getValues();
  if (data.length < 2) {
    Logger.log("ALARM_VERSES: 데이터가 없습니다.");
    return;
  }

  // ALARM_VERSES 전용 배열/정수/불리언 필드
  var AV_ARRAY_FIELDS    = ["theme", "mood", "alarm_context"];
  var AV_INT_FIELDS      = ["chapter", "verse", "usage_count", "cooldown_days", "show_count"];
  var AV_BOOL_FIELDS     = ["curated"];
  var AV_NULLABLE_FIELDS = ["last_shown", "notes"];

  var headers = data[0].map(function(h) { return String(h).trim(); });
  var verseIdIndex = headers.indexOf("verse_id");
  if (verseIdIndex === -1) {
    SpreadsheetApp.getUi().alert("오류", "verse_id 컬럼이 없습니다.", SpreadsheetApp.getUi().ButtonSet.OK);
    return;
  }

  Logger.log("ALARM_VERSES 컬럼: " + headers.join(", "));

  var successCount = 0, failCount = 0, failedRows = [];

  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    var verseId = String(row[verseIdIndex]).trim();
    if (verseId === "" || verseId === "undefined") continue;

    // ALARM_VERSES 전용 필드 타입으로 Firestore 문서 빌드
    var fields = {};
    for (var j = 0; j < headers.length; j++) {
      var key = headers[j];
      var rawValue = row[j];
      if (!key) continue;

      var strValue = String(rawValue).trim();

      if (AV_NULLABLE_FIELDS.indexOf(key) !== -1 && strValue === "") continue;

      if (AV_ARRAY_FIELDS.indexOf(key) !== -1) {
        var items = strValue.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s !== ""; });
        if (items.length === 0) items = ["all"];
        fields[key] = { arrayValue: { values: items.map(function(item){ return { stringValue: item }; }) } };
      } else if (AV_INT_FIELDS.indexOf(key) !== -1) {
        var intVal = parseInt(strValue, 10);
        fields[key] = { integerValue: String(isNaN(intVal) ? 0 : intVal) };
      } else if (AV_BOOL_FIELDS.indexOf(key) !== -1) {
        fields[key] = { booleanValue: ["true","1","yes"].indexOf(strValue.toLowerCase()) !== -1 };
      } else {
        fields[key] = { stringValue: strValue };
      }
    }

    // 기본값 보장
    if (!fields.status)       fields.status       = { stringValue: "active" };
    if (!fields.curated)      fields.curated      = { booleanValue: true };
    if (!fields.usage_count)  fields.usage_count  = { integerValue: "0" };
    if (!fields.cooldown_days) fields.cooldown_days = { integerValue: "7" };

    var success = upsertDocument("alarm_verses", verseId, { fields: fields });
    if (success) {
      successCount++;
      Logger.log("성공 [" + (i) + "/" + (data.length - 1) + "]: " + verseId);
    } else {
      failCount++;
      failedRows.push(verseId);
    }
    Utilities.sleep(100);
  }

  var summary = "alarm_verses 업로드: " + successCount + "개 성공, " + failCount + "개 실패";
  Logger.log(summary);
  SpreadsheetApp.getUi().alert("업로드 결과", summary + (failedRows.length ? "\n\n실패: " + failedRows.join(", ") : ""), SpreadsheetApp.getUi().ButtonSet.OK);
}

/**
 * 누락된 컬럼을 헤더 행에 자동으로 추가합니다.
 * 기존 데이터는 건드리지 않고, 없는 컬럼만 우측에 추가합니다.
 * Apps Script 편집기에서 이 함수를 선택 후 실행하세요.
 */
function addMissingColumns() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var headerRow = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  var headers = headerRow.map(function(h) { return String(h).trim(); });

  // 추가할 컬럼 정의: [컬럼명, 기본값(신규 행 참고용)]
  var columnsToAdd = [
    ["alarm_text_ko", ""],          // 알람 탭 전용 텍스트 (비워두면 text_ko 사용)
    ["usage_count",   "0"],         // 사용 횟수 (항상 0으로 시작)
    ["cooldown_days", "7"],         // 재표시까지 최소 일수
    ["last_shown",    ""],          // 마지막 표시일 (비워두기)
    ["show_count",    "0"],         // 표시 횟수 (항상 0으로 시작)
  ];

  var added = [];
  var nextCol = headers.length + 1;

  columnsToAdd.forEach(function(colDef) {
    var colName = colDef[0];
    if (headers.indexOf(colName) === -1) {
      // 헤더 추가
      sheet.getRange(1, nextCol).setValue(colName);
      // 헤더 스타일 — 기존 헤더와 동일하게
      sheet.getRange(1, nextCol).setFontWeight("bold").setBackground("#d9ead3");
      added.push(colName + " (열 " + nextCol + ")");
      nextCol++;
    }
  });

  // 결과 출력
  if (added.length === 0) {
    Logger.log("✅ 누락된 컬럼 없음. 모든 컬럼이 이미 존재합니다.");
    SpreadsheetApp.getUi().alert("✅ 누락 컬럼 없음", "모든 필수 컬럼이 이미 존재합니다.", SpreadsheetApp.getUi().ButtonSet.OK);
  } else {
    var msg = "✅ 추가된 컬럼:\n" + added.join("\n");
    Logger.log(msg);
    SpreadsheetApp.getUi().alert("컬럼 추가 완료", msg, SpreadsheetApp.getUi().ButtonSet.OK);
  }
}
