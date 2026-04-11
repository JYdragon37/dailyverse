# DailyVerse 데이터 파이프라인 가이드

> 말씀(Verse)과 이미지(Image)를 Firebase에 업로드하고 관리하는 방법을 정리한 문서입니다.
> 최종 업데이트: 2026-04-04

---

## 1. Firebase 구조 이해 (스프레드시트 비유)

Firebase는 두 가지 서비스로 나뉩니다.

```
Firebase Firestore (DB)              Firebase Storage (파일 서버)
────────────────────────────────     ──────────────────────────────
verses 컬렉션  ← "말씀 시트"           images/ 폴더
  └── v_001 문서                         └── beach_sunrise.jpg
  └── v_002 문서                         └── petra_morning.jpg
  └── v_003 문서

images 컬렉션  ← "이미지 메타데이터 시트"
  └── img_001 문서 (URL + 태그)
  └── img_002 문서
```

| Firebase 용어 | 스프레드시트 용어 |
|--------------|----------------|
| 컬렉션 (Collection) | 시트 (Sheet) |
| 문서 (Document) | 행 (Row) |
| 필드 (Field) | 열 (Column) |

---

## 2. 말씀(Verse) 칼럼 전체 정의

### 칼럼 목록

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `verse_id` | string | ✅ | 고유 ID, 기존 마지막+1 | `"v_011"` |
| `text_ko` | string | ✅ | **카드에 표시되는 요약 구절** | `"두려워하지 말라 내가 너와 함께 함이라"` |
| `text_full_ko` | string | ✅ | 바텀시트에 표시되는 전체 구절 | `"두려워하지 말라 ... 도와주리라"` |
| `alarm_text_ko` | string | ❌ | 알람 탭 전용 텍스트 (없으면 null) | `"오늘도 함께하시는 하나님"` |
| `reference` | string | ✅ | 성경 참조 | `"이사야 41:10"` |
| `book` | string | ✅ | 성경책 이름 | `"이사야"` |
| `chapter` | number | ✅ | 장 | `41` |
| `verse` | number | ✅ | 절 | `10` |
| `mode` | array | ✅ | 표시 시간대 (아래 목록 참고) | `["morning"]` |
| `theme` | array | ✅ | 테마 태그 (아래 목록 참고) | `["hope", "courage"]` |
| `mood` | array | ✅ | 분위기 태그 | `["bright", "dramatic"]` |
| `season` | array | ✅ | 계절 | `["all"]` |
| `weather` | array | ✅ | 날씨 조건 | `["any"]` |
| `interpretation` | string | ✅ | 말씀 해석 (바텀시트) | `"하나님이 직접 함께하겠다는 약속"` |
| `application` | string | ✅ | 일상 적용 (바텀시트) | `"오늘 걱정된다면 혼자가 아님을 기억해"` |
| `notes` | string | ❌ | 신학 메모, 원어 설명 | `"히브리어 알 티라 — ..."` |
| `translations.ko_nkrv` | string | ❌ | 개역개정 원문 | `"두려워하지 말라..."` |
| `curated` | boolean | ✅ | 검수 완료 여부 (항상 true) | `true` |
| `status` | string | ✅ | 공개 여부 | `"active"` |
| `usage_count` | number | ✅ | 사용 횟수 (항상 0으로 시작) | `0` |
| `cooldown_days` | number | ✅ | 재표시까지 최소 일수 | `7` |
| `last_shown` | string | ✅ | 마지막 표시일 (null로 시작) | `null` |
| `show_count` | number | ✅ | 표시 횟수 (0으로 시작) | `0` |

### 태그 규칙

**mode** (시간대 — v6.0 8 Zone)
```
deep_dark    00:00 ~ 03:00  🌑 Deep Dark   — 극야, 고요, 솔직함
first_light  03:00 ~ 06:00  🌒 First Light — 여명, 준비, 예열
rise_ignite  06:00 ~ 09:00  🌅 Rise & Ignite — 아침, 점화, 모멘텀
peak_mode    09:00 ~ 12:00  ⚡ Peak Mode   — 집중, 판단, 성과
recharge     12:00 ~ 15:00  ☀️ Recharge   — 정오, 리셋, 회복
second_wind  15:00 ~ 18:00  🌤 Second Wind — 오후 재점화, 마무리
golden_hour  18:00 ~ 21:00  🌇 Golden Hour — 저녁, 감사, 수확
wind_down    21:00 ~ 24:00  🌙 Wind Down   — 밤, 마무리, 안식
all          모든 시간대 적용 가능
```

**theme** (테마, zone별 권장)
```
deep_dark    → stillness / surrender / grace / faith
first_light  → faith / renewal / stillness / hope
rise_ignite  → hope / courage / strength / renewal
peak_mode    → wisdom / focus / courage / strength
recharge     → rest / patience / gratitude / comfort
second_wind  → strength / focus / patience / wisdom
golden_hour  → gratitude / reflection / comfort / peace
wind_down    → peace / rest / comfort / stillness
all          → 모든 Zone에서 표시 가능 (Zone 무관 범용 말씀)
```

**mood** (분위기)
```
bright   맑고 활기찬        (rise_ignite, peak_mode 권장)
calm     차분하고 안정된     (recharge, second_wind, wind_down 권장)
warm     따뜻하고 포근한     (recharge, second_wind, golden_hour 권장)
serene   고요하고 평화로운   (deep_dark, first_light, golden_hour 권장)
dramatic 웅장하고 강렬한     (rise_ignite, peak_mode 권장)
cozy     아늑하고 편안한     (wind_down 권장)
all      모든 분위기에서 표시 가능 (분위기 무관 범용)
```

**mood** (분위기)
```
bright   맑고 활기찬
calm     차분하고 안정된
warm     따뜻하고 포근한
serene   고요하고 평화로운
dramatic 웅장하고 강렬한
cozy     아늑하고 편안한
```

**season** (계절)
```
spring / summer / autumn / winter / all
```

**weather** (날씨)
```
sunny / cloudy / rainy / snowy / any
```

**status**
```
active   → 앱에 표시됨
draft    → 준비 중 (표시 안 됨)
inactive → 비활성 (표시 안 됨)
```

### 말씀 데이터 템플릿 (복사해서 사용)

```javascript
{
  verse_id: "v_011",             // ← 기존 마지막 번호 + 1
  text_ko: "여기에 요약 구절",
  text_full_ko: "여기에 전체 구절 (더 긴 버전)",
  alarm_text_ko: null,           // 알람 전용 텍스트 (없으면 null)
  reference: "성경책 장:절",
  book: "성경책명",
  chapter: 1,
  verse: 1,
  mode: ["morning"],             // 시간대
  theme: ["hope"],               // 테마
  mood: ["bright"],              // 분위기
  season: ["all"],
  weather: ["any"],
  interpretation: "말씀 의미 해석",
  application: "오늘 어떻게 적용할지",
  notes: null,                   // 원어 설명 등 (없으면 null)
  translations: { ko_nkrv: "개역개정 원문" },
  curated: true,
  status: "active",
  usage_count: 0,
  last_shown: null,
  show_count: 0,
  cooldown_days: 7
},
```

---

## 3. 이미지(Image) 칼럼 전체 정의

이미지는 **파일(Storage)** 과 **메타데이터(Firestore)** 두 곳에 저장됩니다.

### 칼럼 목록

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `image_id` | string | ✅ | 고유 ID (자동 생성) | `"img_010"` |
| `filename` | string | ✅ | 파일명 (Storage와 동일) | `"beach_sunrise.jpg"` |
| `storage_url` | string | ✅ | Firebase Storage 다운로드 URL (자동 생성) | `"https://storage.googleapis.com/..."` |
| `source` | string | ✅ | 이미지 출처 | `"Genspark Pro"` |
| `license` | string | ✅ | 라이선스 | `"Commercial"` |
| `mode` | array | ✅ | 표시 시간대 | `["morning", "afternoon"]` |
| `theme` | array | ✅ | 테마 태그 | `["hope", "peace"]` |
| `mood` | array | ✅ | 분위기 태그 | `["bright", "warm"]` |
| `season` | array | ✅ | 계절 | `["all"]` |
| `weather` | array | ✅ | 날씨 조건 | `["any"]` |
| `tone` | string | ✅ | 명도 (아래 참고) | `"bright"` |
| `text_position` | string | ✅ | 텍스트 안전 영역 | `"bottom"` |
| `is_sacred_safe` | boolean | ✅ | 홈 배경 사용 가능 여부 | `true` |
| `avoid_themes` | array | ❌ | 함께 쓰면 안 되는 테마 | `[]` |
| `status` | string | ✅ | 공개 여부 | `"active"` |

### 이미지 태그 규칙

**tone** (명도)
```
bright  → 아침/낮 이미지 (밝고 선명)
mid     → 중립 (어느 시간대나 사용 가능)
dark    → 저녁/새벽 이미지 (어둡고 무게감)
```

**text_position** (말씀 텍스트가 겹쳐도 되는 영역)
```
top     → 상단 30% 영역이 깔끔함
center  → 중앙이 깔끔함
bottom  → 하단 30% 영역이 깔끔함
```

**is_sacred_safe**
```
true  → 자연/풍경/하늘/바다/산 → 홈 배경 & Gallery 모두 사용
false → 인물/도시/인공물 → Gallery 전용, 홈 배경 사용 불가
```

### 이미지 메타데이터 템플릿 (복사해서 사용)

```javascript
{
  filename: "파일명.jpg",         // images_to_upload/ 폴더 안의 파일명과 정확히 일치
  mode: ["morning"],
  theme: ["hope"],
  mood: ["bright"],
  season: ["all"],
  weather: ["any"],
  tone: "bright",                // bright / mid / dark
  text_position: "bottom",       // top / center / bottom
  is_sacred_safe: true,
  avoid_themes: [],
  source: "Genspark Pro",
  license: "Commercial",
},
```

---

## 4. 업로드 방법 (단계별)

### A. 말씀 추가

1. `scripts/upload_verses.js` 파일을 열어 `verses` 배열에 새 항목 추가
2. 터미널에서 실행:

```bash
cd /Users/jeongyong/workspace/dailyverse/scripts
node upload_verses.js
```

결과: Firestore `verses/v_011` 문서 생성

---

### B. 이미지 추가

**Step 1**: 이미지 파일을 `scripts/images_to_upload/` 폴더에 복사

```
scripts/
├── images_to_upload/
│   ├── beach_sunrise.jpg      ← 여기에 넣기
│   └── mountain_dawn.jpg
```

**Step 2**: `scripts/upload_images.js` 파일을 열어 `IMAGE_METADATA` 배열에 메타데이터 추가

```javascript
const IMAGE_METADATA = [
  {
    filename: "beach_sunrise.jpg",   // ← 파일명 정확히 일치
    mode: ["morning", "evening"],
    theme: ["hope", "peace"],
    mood: ["warm", "serene"],
    season: ["all"], weather: ["any"],
    tone: "mid",
    text_position: "bottom",
    is_sacred_safe: true,
    avoid_themes: [],
    source: "Genspark Pro", license: "Commercial",
  },
  // 추가 이미지...
];
```

**Step 3**: 터미널에서 실행:

```bash
cd /Users/jeongyong/workspace/dailyverse/scripts
node upload_images.js
```

결과:
- Firebase Storage `images/beach_sunrise.jpg` 업로드
- `storage_url` 자동 생성
- Firestore `images/img_010` 문서 등록

---

### C. 알람 전용 텍스트(alarm_text_ko) 추가

기존 구절에 알람 탭 전용 글귀를 추가하려면 `upload_verses.js`에서 해당 구절만 수정 후 재실행합니다. PATCH 방식이라 기존 데이터는 유지됩니다.

```javascript
// 기존 v_001에 alarm_text_ko만 추가하는 경우
{
  verse_id: "v_001",
  alarm_text_ko: "오늘도 두려워 말아요. 함께 하시는 분이 있으니",
  // 나머지 필드는 그대로 유지됨 (덮어쓰지 않음)
}
```

---

## 5. 전체 파이프라인 요약

```
[콘텐츠 제작]
Genspark Pro (이미지)  /  직접 작성 또는 신학 검수 (말씀)
          │
          ▼
[로컬 준비]
scripts/images_to_upload/   ← 이미지 파일 복사
scripts/upload_verses.js    ← 말씀 데이터 추가
scripts/upload_images.js    ← 이미지 메타데이터 추가
          │
          ▼  node upload_*.js
[Firebase]
Storage  → images/파일명.jpg         (원본 이미지 파일)
Firestore → verses/v_001 ~ v_XXX     (말씀 데이터)
Firestore → images/img_001 ~ img_XXX (이미지 메타데이터 + URL)
          │
          ▼
[iOS 앱]
FirestoreService.swift → 데이터 fetch
VerseSelector.swift    → 모드 / 날씨 / 테마 스코어링으로 자동 매칭
DailyCacheManager.swift → 30분 캐시, 05:00 기준 하루 고정
```

---

## 6. 스코어링 알고리즘 (참고)

앱이 자동으로 말씀과 이미지를 선택할 때 이 점수 공식을 사용합니다.

```
테마 일치 1개당   +3점
분위기 일치 1개당 +2점
날씨 일치         +2점
계절 일치         +1점
```

예: 아침(morning), 맑음(sunny), 봄(spring)일 때
- `theme: ["hope"]` + `weather: ["sunny"]` + `season: ["spring"]` → 3 + 2 + 1 = **6점**
- 최고 점수 구절들 중 랜덤 선택

---

## 7. Firebase Console 바로가기

- **Firestore** (말씀/이미지 데이터): https://console.firebase.google.com/project/dailyverse-9260d/firestore
- **Storage** (이미지 파일): https://console.firebase.google.com/project/dailyverse-9260d/storage

---

## 8. 주의사항 & 규칙

1. **verse_id / image_id는 절대 중복 금지** — 기존 최대 번호를 확인 후 +1
2. **status: "draft"** 로 올리면 앱에 표시되지 않음 — 검수 전 임시 저장 용도
3. **curated: true** 는 신학 검수가 완료된 구절에만 사용 — false면 앱에서 제외됨
4. **이미지 파일명** 은 영문/숫자/언더스코어만 사용 (한글, 공백 금지)
5. **alarm_text_ko** 를 비워두면 앱이 자동으로 `text_ko`를 대신 사용
6. **is_sacred_safe: false** 이미지는 Gallery 탭에만 표시, 홈 배경/알람 배경 불가
7. **재업로드** 는 안전함 — PATCH 방식이라 기존 데이터 덮어쓰지 않고 지정한 필드만 업데이트
