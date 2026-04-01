# DailyVerse — Google Sheets to Firestore 업로드 가이드

## 전제 조건

- Firebase 프로젝트: `dailyverse-9260d`
- Firestore 컬렉션: `verses`
- Google Sheets 스프레드시트가 본인 Google 계정으로 열려 있어야 함

---

## Step 1 — Firestore 보안 규칙 임시 설정

업로드 중에는 외부 쓰기가 허용되어야 합니다.
업로드가 끝나면 반드시 원래 규칙으로 복원하세요.

**Firebase Console 접근 경로**:
`https://console.firebase.google.com/project/dailyverse-9260d/firestore/rules`

**임시 규칙 (업로드 전 적용)**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

> 주의: 이 규칙은 인증 없이 누구나 읽기/쓰기가 가능합니다.
> 업로드 완료 즉시 Step 4의 운영 규칙으로 복원해야 합니다.

---

## Step 2 — Apps Script 실행 방법

### 2-1. Apps Script 열기

1. Google Sheets 스프레드시트를 열어주세요.
   URL: `https://docs.google.com/spreadsheets/d/1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig`
2. 상단 메뉴 → **확장 프로그램** → **Apps Script** 클릭

### 2-2. 스크립트 붙여넣기

1. Apps Script 편집기가 열리면 기존 코드를 모두 삭제합니다.
2. `/Users/jeongyong/workspace/dailyverse/scripts/upload_to_firestore.gs` 파일의
   전체 내용을 복사해서 붙여넣습니다.
3. 상단 저장 버튼(디스크 아이콘) 또는 `Cmd + S`로 저장합니다.

### 2-3. Firestore 서비스 연결

Apps Script에서 Firestore REST API를 사용하려면
Google Cloud 프로젝트의 Cloud Firestore API가 활성화되어 있어야 합니다.

1. Apps Script 편집기 좌측 → **서비스(+)** 클릭
2. 목록에서 **Cloud Firestore API** 검색 후 추가
   (목록에 없으면 `https://console.cloud.google.com/apis/library` 에서
   `Cloud Firestore API`를 검색하여 사용 설정)

### 2-4. 업로드 전 구조 확인 (권장)

1. 함수 드롭다운에서 `previewSheetStructure` 선택
2. **실행** 버튼 클릭
3. **실행 로그**를 열어 컬럼 목록과 "MISSING" 항목이 없는지 확인

### 2-5. 단일 행 테스트 업로드 (권장)

1. 함수 드롭다운에서 `testUploadFirstRow` 선택
2. **실행** 버튼 클릭
3. 실행 로그에서 "테스트 성공" 메시지 확인
4. Firebase Console → Firestore → verses 컬렉션에 첫 번째 문서가 생성되었는지 확인

### 2-6. 전체 업로드 실행

1. 함수 드롭다운에서 `uploadVersesToFirestore` 선택
2. **실행** 버튼 클릭
3. 첫 실행 시 Google 계정 권한 허용 팝업이 나타납니다.
   "고급" → "안전하지 않음(계속)" → "허용" 클릭
4. 실행이 완료되면 다이얼로그로 결과가 표시됩니다.
   예시: `"업로드 완료: 8개 성공, 0개 실패"`

---

## Step 3 — 업로드 결과 확인 (Firebase Console)

1. Firebase Console 접근:
   `https://console.firebase.google.com/project/dailyverse-9260d/firestore`
2. **Firestore Database** → **Data** 탭 클릭
3. `verses` 컬렉션 클릭
4. 각 문서가 올바른 필드를 가지고 있는지 확인:
   - `status`: `"active"`
   - `curated`: `true`
   - `mode`: 배열 형태 (예: `["morning"]`)
   - `theme`: 배열 형태 (예: `["hope", "courage"]`)
   - `usage_count`: `0`

### 앱에서 로드되는 쿼리 조건 확인

`FirestoreService.fetchVerses()`는 다음 조건으로 쿼리합니다:

```swift
.whereField("status", isEqualTo: "active")
.whereField("curated", isEqualTo: true)
```

업로드된 문서에 두 필드가 올바르게 설정되어 있어야 앱에서 데이터가 로드됩니다.
Sheets에 해당 컬럼이 없거나 비어있는 경우 스크립트가 자동으로 기본값을 설정합니다:
- `status` → `"active"`
- `curated` → `true`
- `usage_count` → `0`

### Firestore 복합 인덱스

위 쿼리는 두 필드를 동시에 사용하므로 복합 인덱스가 필요합니다.
앱을 처음 실행할 때 Firestore가 인덱스 생성 링크를 Xcode 콘솔에 출력합니다.
해당 링크를 클릭하면 자동으로 인덱스가 생성됩니다.

---

## Step 4 — 업로드 완료 후 보안 규칙 복원

업로드가 완료되면 즉시 운영 보안 규칙으로 복원합니다.

**Firebase Console 접근 경로**:
`https://console.firebase.google.com/project/dailyverse-9260d/firestore/rules`

**운영 보안 규칙 (복원 후 적용)**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // verses, images — 모든 사용자 읽기 가능, 쓰기 불가
    match /verses/{verseId} {
      allow read: if true;
      allow write: if false;
    }

    match /images/{imageId} {
      allow read: if true;
      allow write: if false;
    }

    // users — 본인만 읽기/쓰기
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // saved_verses — 본인만 읽기/쓰기
    match /saved_verses/{userId}/verses/{savedId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**게시 방법**: 규칙 편집 후 우상단 **게시** 버튼 클릭

---

## 자주 묻는 질문

### "Exception: Request failed" 오류가 발생합니다

- 보안 규칙이 임시 설정으로 변경되었는지 확인하세요 (Step 1).
- Google 계정이 `dailyverse-9260d` 프로젝트의 편집자 이상 권한인지 확인하세요.
- Cloud Firestore API가 활성화되었는지 확인하세요.

### 배열 필드가 문자열로 저장됩니다

- Sheets의 배열 필드(mode, theme, mood, season, weather)는 쉼표로 구분되어야 합니다.
  예시: `morning` 또는 `morning,afternoon`

### 일부 행이 스킵됩니다

- `verse_id` 컬럼이 비어있는 행은 자동으로 스킵됩니다.
- 실행 로그에서 "스킵: verse_id가 비어있음" 메시지를 확인하세요.

### 데이터를 다시 업로드하면 어떻게 됩니까

- 스크립트는 PATCH(upsert) 방식으로 업로드합니다.
- 같은 `verse_id`의 문서가 이미 있으면 덮어씁니다. 새로운 문서라면 생성합니다.
- 기존에 앱에서 추가된 `usage_count` 값도 덮어쓰므로 주의하세요.

---

## Sheets 컬럼 → Firestore 필드 매핑 참조표

| Sheets 컬럼 | Firestore 필드 | 타입 | 비고 |
|---|---|---|---|
| `verse_id` | 문서 ID + `verse_id` 필드 | String | 예: `v_001` |
| `text_ko` | `text_ko` | String | 카드 표시용 요약 구절 |
| `text_full_ko` | `text_full_ko` | String | 바텀시트 전체 구절 |
| `reference` | `reference` | String | 예: `이사야 41:10` |
| `book` | `book` | String | 예: `이사야` |
| `chapter` | `chapter` | Integer | |
| `verse` | `verse` | Integer | |
| `mode` | `mode` | Array(String) | `morning,evening` → `["morning","evening"]` |
| `theme` | `theme` | Array(String) | `hope,courage` → `["hope","courage"]` |
| `mood` | `mood` | Array(String) | `bright,calm` → `["bright","calm"]` |
| `season` | `season` | Array(String) | `all` → `["all"]` |
| `weather` | `weather` | Array(String) | `any` → `["any"]` |
| `interpretation` | `interpretation` | String | |
| `application` | `application` | String | |
| `curated` | `curated` | Boolean | 없으면 기본값 `true` |
| `status` | `status` | String | 없으면 기본값 `"active"` |
| `usage_count` | `usage_count` | Integer | 없으면 기본값 `0` |
