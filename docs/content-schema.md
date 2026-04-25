# morning manna — 콘텐츠 스키마 레퍼런스

> **대상**: 이 프로젝트를 처음 보는 개발자
> **목적**: 앱에서 사용되는 모든 생성형 콘텐츠(텍스트·이미지)의 구조를 한 파일에서 파악
> **원칙**: Google Sheets = Single Source of Truth (읽기/쓰기) | Firestore = 읽기 전용
> **최종 업데이트**: 2026-04-25

---

## 콘텐츠 타입 한눈에 보기

| 타입 | Sheets 탭 | Firestore 컬렉션 | 현황 | 동기화 스크립트 |
|------|----------|----------------|------|--------------|
| [말씀](#1-말씀-verses) | `VERSES` | `verses/` | 활성 417개 | `sync_verses.js` |
| [홈 인사말](#2-홈-인사말-home_greetings) | `HOME_GREETINGS` | `greetings/` | 134개 | `sync_home_greetings.js` |
| [알람 인사말](#3-알람-인사말-alarm_greetings) | `ALARM_GREETINGS` | `alarm_greetings/` | 35개 | `upload_alarm_greetings.js` |
| [감성 이미지](#4-감성-이미지-verse_images) | `VERSE_IMAGES` | `images/` | **95개** (img_001~095) | `sync_verse_images.js` · `upload_design_test.js` |
| [Zone 배경](#5-zone-배경-background_images) | `BACKGROUND_IMAGES` | `background_images/` | **20개** (Zone당 다중·날씨별) | `sync_zone_backgrounds.js` v7.0 |

---

## 1. 말씀 (VERSES)

### 앱 사용 위치

| 화면 | 섹션 | 표시 필드 |
|------|------|---------|
| 홈 탭 | 메인 말씀 카드 | `verse_short_ko`, `reference`, `theme[0]` |
| 홈 탭 | 바텀시트 전체 구절 | `verse_full_ko`, `reference` |
| 홈 탭 | 바텀시트 해석 | `interpretation` |
| 홈 탭 | 바텀시트 적용 | `application` |
| 알람 탭 | 오늘의 말씀 카드 | `alarm_top_ko` → (없으면) `verse_short_ko` 폴백 |
| 알람 Stage 1 | 전체화면 말씀 | `verse_short_ko`, `reference` |
| 알람 Stage 2 | 웰컴 말씀 | `verse_full_ko`, `reference` |
| 저장 탭 | 상세 화면 | `verse_full_ko`, `interpretation`, `application` |
| 묵상 탭 | 홈 말씀 | `verse_short_ko`, `reference` |
| 묵상 탭 | 읽기 섹션 | `verse_full_ko` |
| 묵상 탭 | 해석 | `interpretation` |
| 묵상 탭 | 적용 | `application` |
| 묵상 탭 | 응답 질문 | `question` |

### 스키마 전체 매핑

| # | Sheets 컬럼 | Firestore 필드 | Swift 프로퍼티 | 타입 | 필수 | 설명 | 예시 |
|---|------------|--------------|--------------|------|------|------|------|
| A | `verse_id` | `verse_id` (문서 ID) | `id` | String | ✅ | 고유 식별자, 절대 변경 금지 | `v_001` |
| B | `verse_short_ko` | `verse_short_ko` | `verseShortKo` | String | ✅ | 핵심 요약 구절, 35자 이내 | `"두려워하지 말라, 내가 너와 함께 함이라."` |
| C | `verse_full_ko` | `verse_full_ko` | `verseFullKo` | String | ✅ | 전체 구절 원문 (개역한글) | `"두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라..."` |
| D | `reference` | `reference` | `reference` | String | ✅ | 성경 참조 | `"이사야 41:10"` |
| E | `book` | `book` | `book` | String | ✅ | 성경 책 이름 | `"이사야"` |
| F | `chapter` | `chapter` | `chapter` | Int | ✅ | 장 | `41` |
| G | `verse` | `verse` | `verse` | Int | ✅ | 절 | `10` |
| H | `mode` | `mode` | `mode` | [String] | ✅ | Zone 시간대 (쉼표 구분) | `"rise_ignite,peak_mode"` |
| I | `theme` | `theme` | `theme` | [String] | ✅ | 감정 테마 (쉼표 구분, 1~3개) | `"hope,courage,strength"` |
| J | `mood` | `mood` | `mood` | [String] | ✅ | 분위기 (쉼표 구분) | `"bright,dramatic"` |
| K | `season` | `season` | `season` | [String] | ✅ | 계절 | `"all"` |
| L | `weather` | `weather` | `weather` | [String] | ✅ | 날씨 조건 | `"any"` |
| M | `interpretation` | `interpretation` | `interpretation` | String | ✅ | 말씀 해석 (80~150자, ~야/이야 말투) | `"이사야가 포로 상태의 이스라엘에게..."` |
| N | `application` | `application` | `application` | String | ✅ | 일상 적용 (40~80자, Zone 반영) | `"오늘 어려움이 있다면, 잠깐 멈춰봐..."` |
| O | `curated` | `curated` | `curated` | Bool | ✅ | 신학 검수 완료 여부 | `TRUE` |
| P | `status` | `status` | `status` | String | ✅ | 노출 상태 | `"active"` |
| Q | `notes` | `notes` | `notes` | String? | — | 내부 메모 | `"포로 귀환 맥락"` |
| R | `alarm_top_ko` | `alarm_top_ko` | `alarmTopKo` | String? | — | 알람 탭 전용 (35자 이내), 없으면 verse_short_ko 폴백 | `"두려워하지 말라, 내가 함께해."` |
| S | `question` | `question` | `question` | String? | — | 묵상 응답 질문 (40~80자) | `"지금 당신을 가장 두렵게 만드는 것은?"` |
| T | `usage_count` | `usage_count` | `usageCount` | Int | ✅ | 누적 노출 횟수 | `5` |
| U | `cooldown_days` | `cooldown_days` | `cooldownDays` | Int | ✅ | 동일 구절 재출현 방지 일수 (기본 7) | `7` |
| V | `last_shown` | `last_shown` | `lastShown` | String? | — | 마지막 표시일 `YYYY-MM-DD` | `"2026-04-20"` |
| W | `show_count` | `show_count` | `showCount` | Int? | — | 이번 주기 노출 횟수 | `3` |

> **저작권**: `verse_short_ko`, `verse_full_ko` — 개역한글 (대한성서공회, 1961, 퍼블릭 도메인). 앱 내 "성경 본문: 개역한글, 대한성서공회" 출처 표기 필수.

### 데이터 저장 순서

```
1. Sheets VERSES 탭 편집 (원본 작성/수정)
         ↓
2. node scripts/sync_verses.js
   ├── Sheets 전체 행 읽기
   ├── Firestore에 없는 verse_id → 삭제
   └── Sheets 전체 → Firestore upsert
```

### 전체 Verse 예시 (JSON)

```json
{
  "verse_id": "v_065",
  "verse_short_ko": "두려워하지 말라, 내가 너와 함께 함이라.",
  "verse_full_ko": "두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라, 나는 네 하나님이 됨이라.\n내가 너를 굳세게 하리라.",
  "reference": "이사야 41:10",
  "book": "이사야",
  "chapter": 41,
  "verse": 10,
  "mode": ["rise_ignite", "peak_mode"],
  "theme": ["hope", "courage", "strength"],
  "mood": ["bright", "dramatic"],
  "season": ["all"],
  "weather": ["any"],
  "interpretation": "이사야가 바벨론 포로로 끌려간 이스라엘 백성에게 전한 말씀이야. '두려워하지 말라'는 상황이 바뀌기 전에 먼저 임재를 선언하는 거야. 조건이 없어. 지금 네 앞의 두려움보다 그분이 크다는 걸 기억해.",
  "application": "오늘 업무나 공부에서 어려움이 있다면, 잠깐 멈춰봐. 그분이 함께한다는 거 기억하며 다시 시작해.",
  "alarm_top_ko": "두려워하지 말라, 내가 함께해.",
  "question": "지금 당신을 가장 두렵게 만드는 것은 무엇인가요?",
  "curated": true,
  "status": "active",
  "usage_count": 5,
  "cooldown_days": 7,
  "last_shown": "2026-04-20",
  "show_count": 3,
  "notes": null
}
```

### 말씀 선택 알고리즘 (스코어링)

```
1. mode가 현재 Zone과 일치하거나 "all"인 구절 필터링
2. status == "active" && curated == true 조건
3. 스코어 산정:
   - theme 겹침 1개당    +3점
   - mood 겹침 1개당     +2점
   - weather 일치 시     +2점
   - season 일치 시      +1점
4. 최고 점수 구절 중 랜덤 선택
5. Free 유저: 1개 고정 (DailyVerseCache 저장)
   Premium [다음 말씀]: 현재 구절 제외 후 재실행
```

---

## 2. 홈 인사말 (HOME_GREETINGS)

### 앱 사용 위치

| 화면 | 섹션 | 표시 필드 |
|------|------|---------|
| 홈 탭 | 상단 시간대 인사말 | `text` (Zone + 언어로 자동 선택) |

### 스키마 전체 매핑

| # | Sheets 컬럼 | Firestore 필드 | 타입 | 필수 | 설명 | 예시 |
|---|------------|--------------|------|------|------|------|
| A | `gr_id` | `gr_id` (문서 ID) | String | ✅ | 고유 ID | `"gr_ri_ko_001"` |
| B | `zone_id` | `zone_id` | String | ✅ | Zone 시간대 | `"rise_ignite"` |
| C | `language` | `language` | String | ✅ | 언어 코드 | `"ko"` / `"en"` |
| D | `text` | `text` | String | ✅ | 인사말 텍스트 | `"좋은 아침이에요, beloved!"` |
| E | `char_count` | `char_count` | Int | — | 글자 수 (자동 계산) | `16` |

### 데이터 저장 순서

```
1. Sheets HOME_GREETINGS 탭 편집
         ↓
2. node scripts/sync_home_greetings.js
   └── Firestore greetings/ 컬렉션 완전 동기화
```

### 예시

```json
{ "gr_id": "gr_ri_ko_001", "zone_id": "rise_ignite", "language": "ko", "text": "좋은 아침이에요, beloved!", "char_count": 16 }
{ "gr_id": "gr_ri_en_001", "zone_id": "rise_ignite", "language": "en", "text": "Good Morning ☀️", "char_count": 15 }
{ "gr_id": "gr_dd_ko_001", "zone_id": "deep_dark",   "language": "ko", "text": "아직 안 잤어요?", "char_count": 8 }
```

---

## 3. 알람 인사말 (ALARM_GREETINGS)

### 앱 사용 위치

| 화면 | 섹션 | 표시 필드 |
|------|------|---------|
| 알람 Stage 2 | 웰컴 스크린 상단 인사말 | `text` (Zone 기준 랜덤 선택) |

### 스키마 전체 매핑

| # | Sheets 컬럼 | Firestore 필드 | 타입 | 필수 | 설명 | 예시 |
|---|------------|--------------|------|------|------|------|
| A | `gr_id` | `gr_id` (문서 ID) | String | ✅ | 고유 ID | `"ag_ri_ko_001"` |
| B | `zone_id` | `zone_id` | String | ✅ | Zone 시간대 | `"rise_ignite"` |
| C | `language` | `language` | String | ✅ | 언어 코드 | `"ko"` |
| D | `text` | `text` | String | ✅ | 인사말 텍스트 | `"아침이 밝았어요, beloved!"` |
| E | `char_count` | `char_count` | Int | — | 글자 수 | `15` |

> **홈 인사말과의 차이**: 알람 인사말은 "알람이 울리는 순간"의 감성에 맞게 작성. 홈 인사말보다 에너지가 높고 짧음.

### 데이터 저장 순서

```
1. Sheets ALARM_GREETINGS 탭 편집
         ↓
2. node scripts/upload_alarm_greetings.js
   └── Firestore alarm_greetings/ 컬렉션 동기화
```

### 예시

```json
{ "gr_id": "ag_ri_ko_001", "zone_id": "rise_ignite", "language": "ko", "text": "아침이 밝았어요, beloved!", "char_count": 15 }
{ "gr_id": "ag_dd_ko_001", "zone_id": "deep_dark",   "language": "ko", "text": "아직 안 잤어요?", "char_count": 8 }
```

---

## 4. 감성 이미지 (VERSE_IMAGES)

### 앱 사용 위치

| 화면 | 섹션 | 선택 기준 |
|------|------|---------|
| 홈 탭 | ❌ 사용 안 함 — Zone 고정 배경(BACKGROUND_IMAGES)만 사용 | — |
| 알람 Stage 1 | **말씀 카드 내부** 배경 (전체 배경은 정적 에셋 `AlarmStage1BG`) | Zone + theme + mood + weather 스코어링 |
| 알람 Stage 2 | **풀스크린** 배경 | 동일 알고리즘 |
| 저장 목록·상세 | 저장 당시 스냅샷 (`saved_verses.image_url`) | 저장 시점 이미지 URL 고정 |

### 스키마 전체 매핑

| # | Sheets 컬럼 | Firestore 필드 | Swift 프로퍼티 | 타입 | 필수 | 설명 | 예시 |
|---|------------|--------------|--------------|------|------|------|------|
| A | `image_id` | `image_id` (문서 ID) | `id` | String | ✅ | 고유 ID | `"img_001"` |
| B | `filename` | `filename` | `filename` | String | ✅ | 파일명 또는 외부 URL | `"morning_mountain.jpg"` |
| C | `storage_url` | `storage_url` | `storageUrl` | String | ✅ | Firebase Storage 최종 URL (업로드 후 자동 채워짐) | `"https://storage.googleapis.com/..."` |
| D | `source` | `source` | `source` | String | ✅ | 이미지 출처 | `"Genspark Pro"` |
| E | `source_url` | `source_url` | `sourceUrl` | String? | — | 원본 링크 | `"https://www.genspark.ai/..."` |
| F | `license` | `license` | `license` | String | ✅ | 라이선스 | `"Commercial"` |
| G | `mode` | `mode` | `mode` | [String] | ✅ | 적합 Zone (쉼표 구분) | `"rise_ignite,peak_mode"` |
| H | `theme` | `theme` | `theme` | [String] | ✅ | 감정 테마 (쉼표 구분) | `"hope,renewal"` |
| I | `mood` | `mood` | `mood` | [String] | ✅ | 분위기 | `"bright,dramatic"` |
| J | `season` | `season` | `season` | [String] | ✅ | 계절 | `"spring,summer"` |
| K | `weather` | `weather` | `weather` | [String] | ✅ | 날씨 조건 | `"sunny"` |
| L | `tone` | `tone` | `tone` | String | ✅ | 밝기 톤 | `"bright"` / `"mid"` / `"dark"` |
| M | `status` | `status` | `status` | String | ✅ | 노출 상태 | `"active"` |
| N | `text_position` | `text_position` | `textPosition` | String | ✅ | 텍스트 올릴 위치 | `"bottom"` / `"top"` / `"center"` |
| O | `is_sacred_safe` | `is_sacred_safe` | `isSacredSafe` | Bool | ✅ | 홈/알람 배경 노출 적합 여부 | `TRUE` |
| P | `avoid_themes` | `avoid_themes` | `avoidThemes` | [String]? | — | 함께 쓰면 안 되는 테마 | `"sorrow"` |
| Q | `notes` | `notes` | `notes` | String? | — | 내부 메모 | `"일출 직후 산 풍경"` |

### 이미지 선택 알고리즘 (스코어링)

```
1. mode가 현재 Zone과 일치하거나 "all"인 이미지 필터링
2. status == "active" 조건
3. 스코어 산정:
   - theme 겹침 1개당  +3점
   - mood 겹침 1개당   +2점
   - weather 일치 시   +2점
   - season 일치 시    +1점
4. 최고 점수 이미지 중 랜덤 선택
5. 아침 Zone → bright/mid 톤 우선
   저녁 Zone → dark 톤 우선
```

### 데이터 저장 순서

```
[메인 방법 — design_test/ 워크플로우 (권장)]
1. 이미지를 design_test/ 폴더에 넣기
2. Claude Code: "design_test 검수해줘"
   → zone-image-inspector 에이전트 자동 실행
   → 시각 검수 (비율·밝기·Zone 감성) + 자동 리네임
3. 🖼️ 이미지 업로드.command 더블클릭
   ├── dry-run 미리보기
   ├── y 확인
   ├── Firebase Storage 업로드
   ├── VERSE_IMAGES 시트 추가 (먼저 — Single Source of Truth)
   ├── Firestore images/ 저장
   └── design_test/ 파일 자동 삭제

[보조 방법 — Sheets 메타데이터 기반 동기화]
1. Sheets VERSE_IMAGES 탭에 메타데이터 입력
2. node scripts/sync_verse_images.js
   ├── 외부 URL → Firebase Storage 업로드
   ├── Sheets storage_url 컬럼 자동 업데이트
   └── Firestore images/ 저장
```

### 현황 및 Zone별 분포

| Zone | 현황 | 권장 목표 |
|------|------|---------|
| deep_dark (00–03시) | ✅ 충분 | 10개 이상 |
| first_light (03–06시) | ✅ 충분 | 10개 이상 |
| rise_ignite (06–09시) | ✅ 충분 | 10개 이상 |
| peak_mode (09–12시) | ⚠️ 부족 | 10개 이상 |
| recharge (12–15시) | ⚠️ 부족 | 10개 이상 |
| second_wind (15–18시) | ⚠️ 부족 | 10개 이상 |
| golden_hour (18–21시) | ⚠️ 부족 | 10개 이상 |
| wind_down (21–24시) | ✅ 충분 | 10개 이상 |

### 예시 (JSON)

```json
{
  "image_id": "img_042",
  "filename": "mountain_sunrise_peace.jpg",
  "storage_url": "https://storage.googleapis.com/dailyverse-9260d.firebasestorage.app/images/mountain_sunrise_peace.jpg",
  "source": "Genspark Pro",
  "license": "Commercial",
  "mode": ["rise_ignite", "peak_mode"],
  "theme": ["peace", "hope"],
  "mood": ["bright", "serene"],
  "season": ["spring", "summer"],
  "weather": ["sunny"],
  "tone": "bright",
  "status": "active",
  "text_position": "bottom",
  "is_sacred_safe": true,
  "avoid_themes": [],
  "notes": "산 정상 일출, 고요하면서도 밝은 톤"
}
```

---

## 5. Zone 배경 (BACKGROUND_IMAGES)

> **v7.0 (2026-04-26)**: Zone당 다중 배경 + 날씨별 배경 지원.
> 앱 코드는 `zone` 필드로 전체 조회 후 `.randomElement()` 랜덤 선택 — 앱 수정 불필요.

### 앱 사용 위치

| 화면 | 섹션 | 선택 기준 |
|------|------|---------|
| 홈 탭 | **풀스크린 배경** | Zone 일치 전체 조회 → 날씨 필터링 → 랜덤 선택 |
| 알람 Stage 1 | 사용 안 함 (정적 에셋 `AlarmStage1BG`) | — |
| 알람 Stage 2 | 사용 안 함 (VERSE_IMAGES 사용) | — |

### 스키마 전체 매핑

| # | Sheets 컬럼 | Firestore 필드 | 타입 | 필수 | 설명 | 예시 |
|---|------------|--------------|------|------|------|------|
| A | `image_id` | `image_id` (문서 ID) | String | ✅ | `bg_{zone_id}_{설명}` 형태 | `"bg_deep_dark_banpo_hanriver"` |
| B | `filename` | `filename` | String | ✅ | 파일명 (image_id + 확장자) | `"bg_deep_dark_banpo_hanriver.jpg"` |
| C | `storage_url` | `storage_url` | String | ✅ | Firebase Storage URL | `"https://storage.googleapis.com/..."` |
| D | `zone` | `zone` | String | ✅ | Zone ID — Firestore 쿼리 기준 | `"deep_dark"` |
| E | `weather` | `weather` | String | ✅ | 날씨 조건 | `"all"` / `"rainy"` / `"snowy"` / `"sunny"` / `"misty"` / `"cloudy"` |
| F | `tone` | `tone` | String | ✅ | 밝기 톤 (Zone에서 자동 추론) | `"dark"` / `"mid"` / `"bright"` |
| G | `status` | `status` | String | ✅ | 활성 상태 | `"active"` |
| H | `source` | `source` | String | ✅ | 이미지 출처 | `"morning manna Design"` |
| I | `license` | `license` | String | ✅ | 라이선스 | `"Commercial"` |
| J | `notes` | `notes` | String? | — | 메모 | — |

> `mode` 필드 (Firestore only): `zone`과 동일값 — `BackgroundImage.mode` CodingKey 호환용

### 파일명 규칙 (sync_zone_backgrounds.js v7.0 자동 파싱)

```
bg_{zone_id}_{설명}.jpg             → weather: all  (모든 날씨)
bg_{zone_id}_{weather}_{설명}.jpg   → 해당 날씨에서만 선택

날씨 키워드 (파일명에 포함 시 자동 감지):
  rainy · snowy · cloudy · sunny · misty · foggy · stormy
```

### Zone별 tone 자동 추론

| Zone | tone |
|------|------|
| `deep_dark` · `first_light` · `wind_down` | `dark` |
| `rise_ignite` · `peak_mode` | `bright` |
| `recharge` · `second_wind` · `golden_hour` | `mid` |

### Zone별 현황 (2026-04-26 기준, 총 20개 active)

| Zone ID | 시간대 | 등록 수 | 날씨별 |
|---------|--------|--------|--------|
| `deep_dark` | 00–03시 | 2개 | all ×2 |
| `first_light` | 03–06시 | 3개 | all ×3 |
| `rise_ignite` | 06–09시 | 1개 | all ×1 |
| `peak_mode` | 09–12시 | 1개 | sunny ×1 |
| `recharge` | 12–15시 | 1개 | all ×1 |
| `second_wind` | 15–18시 | 1개 | all ×1 |
| `golden_hour` | 18–21시 | 1개 | all ×1 |
| `wind_down` | 21–24시 | 2개 | all ×2 |

### 데이터 저장 순서

```
1. scripts/zone-backgrounds/ 폴더에 파일 배치 (파일명 규칙 준수)
2. node scripts/sync_zone_backgrounds.js  (또는 🌅 배경이미지 업로드.command)
   ├── 파일명에서 zone_id · weather 자동 파싱
   ├── Firebase Storage backgrounds/ 업로드
   ├── Sheets BACKGROUND_IMAGES 탭 upsert (먼저 — Single Source of Truth)
   └── Firestore background_images/{image_id} 저장

또는 design_test/ 폴더 사용 시:
   node scripts/upload_design_test.js --dry-run   # 미리보기
   node scripts/upload_design_test.js             # 실행
```

---

## Zone 시스템

> 앱의 모든 콘텐츠는 이 8개 Zone을 기반으로 선택됩니다.

| Zone ID | 시간대 | 유저 상황 | 감정 상태 | 말씀 역할 | 권장 테마 |
|---------|--------|---------|---------|---------|---------|
| `deep_dark` | 00–03시 | 잠 못 드는 밤, 불안, 야간 근무 | 외로움·불안·갈망 | 나직한 위로 | comfort, peace, reflection |
| `first_light` | 03–06시 | 새벽 기도/묵상, 고요한 정적 | 고요한 기대·영적 준비 | 영적 호흡 | renewal, hope, peace |
| `rise_ignite` | 06–09시 | 알람 울린 순간, 이불 속 | 나른함·부담·설렘 | 가벼운 격려 | hope, courage, strength |
| `peak_mode` | 09–12시 | 업무·공부 집중, 프로젝트 | 집중·스트레스·책임감 | 지혜와 용기 | wisdom, focus, courage |
| `recharge` | 12–15시 | 점심 후 쉬는 시간 | 나른함·허탈감 | 내면 충전 | patience, gratitude, renewal |
| `second_wind` | 15–18시 | 오후 슬럼프, 마무리 필요 | 피로감·마무리 의지 | 후반전 힘 | strength, focus, patience |
| `golden_hour` | 18–21시 | 퇴근·저녁, 하루 돌아보기 | 수고함·감사·허무감 | 하루 의미 부여 | gratitude, rest, reflection |
| `wind_down` | 21–24시 | 씻고 취침 전 | 피로·평안 욕구 | 짐 내려놓기 | peace, comfort, rest |

**테마 풀 (12개)**: `hope` · `courage` · `strength` · `renewal` · `wisdom` · `focus` · `patience` · `gratitude` · `peace` · `comfort` · `reflection` · `rest`

**무드 풀 (6개)**: `bright` · `calm` · `warm` · `serene` · `dramatic` · `cozy`

---

## 콘텐츠 생성 규칙 (필드별 제약)

### 말씀 필드 글자수 기준

| 필드 | 최소 | 권장 | 최대 | 비고 |
|------|------|------|------|------|
| `verse_short_ko` | 10자 | 25자 | 50자 | 핵심 문장 1개, 줄임표 금지 |
| `verse_full_ko` | 20자 | 60자 | 200자 | 개역한글 원문, `\n`으로 줄 구분 |
| `interpretation` | 80자 | 120자 | 200자 | 4단계 구조 필수 |
| `application` | 40자 | 60자 | 100자 | 실천 1가지, Zone 시간대 반영 |
| `alarm_top_ko` | 10자 | 20자 | 35자 | 없으면 verse_short_ko 폴백 |
| `question` | 20자 | 50자 | 80자 | 질문형 1~2문장 |

### interpretation 4단계 구조

```
① 배경/맥락 (1~2문장) — 저자, 역사적 배경, 대상
② 핵심 의미 (1~2문장) — 핵심 단어 뜻 (원어 직접 표기 금지, 한국어로 풀어서)
③ 오늘날 연결 (1문장) — 현대 삶과의 접점
④ Zone 맥락 (1문장) — 이 시간대 유저 상황과 자연스럽게 연결
```

### 금지 사항

| 카테고리 | 금지 | 대체 |
|---------|------|------|
| **말투** | `~이다`, `~합니다`, `~입니다` | `~야`, `~거야`, `~이야` |
| **말투** | `반드시`, `꼭`, `해야 한다` | `~해봐`, `~해도 돼`, `~있을 거야` |
| **원어** | `헤세드`, `샬롬`, `아가페`, `파루시아` 등 직접 표기 | 한국어 의미로 풀어서 표현 |
| **신학** | 번영신학 (`믿으면 다 잘 된다` 류) | 정통 개신교 신학 범위 내 |
| **인사말** | 닉네임 직접 포함 (`beloved`) | 일반 2인칭 |

---

## 스크립트 전체 레퍼런스

### 동기화 스크립트

| 스크립트 | 입력 (Sheets 탭) | 출력 (Firestore) | 비고 |
|---------|----------------|----------------|------|
| `sync_verses.js` | `VERSES` | `verses/` | 완전 동기화 (upsert + 삭제) |
| `sync_home_greetings.js` | `HOME_GREETINGS` | `greetings/` | 완전 동기화 |
| `upload_alarm_greetings.js` | `ALARM_GREETINGS` | `alarm_greetings/` | upsert |
| `sync_verse_images.js` | `VERSE_IMAGES` | `images/` + Storage | 외부 URL → Storage 업로드 포함 |
| `sync_zone_backgrounds.js` | 로컬 파일 | `background_images/` + Storage | Sheets storage_url 자동 업데이트 |

### 콘텐츠 생성 스크립트

| 스크립트 | 역할 | 출력 대상 |
|---------|------|---------|
| `add_new_verses.js` | Claude API로 신규 말씀 생성 | Sheets VERSES 탭만 (Firestore 직접 쓰기 금지) |
| `generate_meditation_questions.js` | Claude API로 question 필드 생성 | Sheets VERSES 탭만 |

### 품질 검증 스크립트

| 스크립트 | 역할 |
|---------|------|
| `check_content_quality.js` | 글자수·말투·원어 자동 검증 |
| `run_content_qa.js` | 전체 QA 파이프라인 실행 |
| `qa_auto_check.js` | 규칙 기반 자동 체크 |
| `qa_ai_check.js` | Claude AI 기반 심층 체크 |
| `qa_approve.js` | QA 승인 처리 |

### 커맨드 파일 (더블클릭 실행)

| 파일 | 실행 스크립트 | 용도 |
|------|------------|------|
| `📖 말씀 업로드.command` | `sync_verses.js` | Sheets VERSES → Firestore 동기화 |
| `🔍 이미지 검수.command` | — (안내용) | design_test/ 목록 출력 + "검수해줘" 클립보드 복사 |
| `🖼️ 이미지 업로드.command` | `upload_design_test.js` | design_test/ → Storage + Sheets + Firestore + 삭제 |
| `🌅 배경이미지 업로드.command` | `sync_zone_backgrounds.js` | zone-backgrounds/ 폴더 → Zone 배경 업로드 |

### 이미지 업로드 워크플로우 (신규 표준)

```
젠스파크 이미지 생성
    ↓
design_test/ 폴더에 드롭
    ↓
🔍 이미지 검수.command 더블클릭
  → 클립보드에 "design_test 검수해줘" 복사
    ↓
Claude Code에 Cmd+V → zone-image-inspector 에이전트 자동 실행
  → 시각 검수 (비율·밝기·Zone 감성)
  → bg_* / img_* 파일명으로 자동 리네임
    ↓
🖼️ 이미지 업로드.command 더블클릭 → y
  → Storage + Sheets + Firestore 반영 + 파일 삭제
```

---

## 데이터 흐름 전체 다이어그램

```
[텍스트 콘텐츠]                     [이미지 콘텐츠]
content-writer / 운영자              젠스파크 생성 이미지
       │                                    │
       │ 편집                               │ design_test/ 폴더 드롭
       ▼                                    │
┌──────────────┐              🔍 이미지 검수.command
│Google Sheets │              → "검수해줘" 클립보드 복사
│(Single SoT)  │                    │
└──────┬───────┘           Claude Code 붙여넣기
       │                   zone-image-inspector 실행
       │ sync 스크립트       → 시각 검수 + 리네임 (bg_/img_)
       ▼                            │
┌──────────────────────────────────────────────────────────┐
│                    Google Sheets                          │
│  VERSES │ VERSE_IMAGES │ BACKGROUND_IMAGES │ ...         │
│                  (Single Source of Truth)                 │
└──────────────────────┬───────────────────────────────────┘
                       │ 🖼️ 이미지 업로드.command / sync 스크립트
                       ▼
            ┌──────────────────────┐
            │   Firebase Storage   │
            │  images/ · backgrounds/│
            │  (바이너리 파일 CDN)  │
            └──────────┬───────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                   Firestore (읽기 전용)                  │
│  verses/ │ greetings/ │ alarm_greetings/                 │
│  images/ (95개) │ background_images/ (20개) │ saved/     │
└──────────────────────────┬──────────────────────────────┘
                           │ 읽기
                           ▼
                    [iOS 앱 — SwiftUI]
                    홈 · 알람 · 저장 · 묵상 탭
```

---

---

## 이미지 에셋 전체 목록

> 앱에서 사용하는 모든 이미지를 유형별로 정리.

### 정적 에셋 (Xcode Assets.xcassets)

| 에셋명 | 사용 화면 | 용도 | 교체 방법 |
|--------|---------|------|---------|
| `SplashBackground` | 스플래시 | 앱 시작 배경 전체 | Assets.xcassets 교체 |
| `AuthWelcomeBG` | 로그인 화면 | 로그인 배경 전체 | Assets.xcassets 교체 |
| `LogoMMColor` | 로그인·저장·묵상·알람 Stage 2·설정 | 브랜드 로고 (컬러) | Assets.xcassets 교체 |
| `LogoMMBlack` | (예비) | 브랜드 로고 (검정) | Assets.xcassets 교체 |
| `LogoMMWhite` | (예비) | 브랜드 로고 (흰색) | Assets.xcassets 교체 |
| `AppLogo` | (예비) | 앱 아이콘 | Assets.xcassets 교체 |
| `onb_bg_first_light` | 온보딩 1화면 (ONBIntroView) | 온보딩 배경 | Assets.xcassets 교체 |
| `onb_alarm_bg` | 온보딩 2화면 (ONBExperienceView) | 알람 체험 배경 (폴백) | Assets.xcassets 교체 |
| `AlarmStage1BG` | 알람 Stage 1 (Legacy iOS 15-25) | 전체 배경 | Assets.xcassets 교체 |

### 원격 이미지 (Firebase Storage)

| 이미지 타입 | Sheets 탭 | Firestore 컬렉션 · 필드 | 사용 화면 | 선택 방식 | 현황 |
|-----------|---------|----------------------|---------|---------|------|
| 감성 이미지 | `VERSE_IMAGES` · `storage_url` | `images` · `storage_url` | 알람 Stage 1 (말씀 카드 배경) · Stage 2 (풀스크린) | Zone + theme + mood + weather 스코어링 | **95개** (img_001~img_095) |
| Zone 배경 (다중) | `BACKGROUND_IMAGES` · `storage_url` | `background_images` · `storage_url` | 홈 풀스크린 | Zone 일치 전체 조회 → 날씨 필터 → **랜덤 선택** | **20개** (Zone당 1~3개) |
| 저장 스냅샷 | — | `saved_verses` · `image_url` | 저장 목록·상세 | 저장 시점 URL 고정`*` | 유저별 동적 |

---

## 화면별 콘텐츠 표시 매핑

> 앱에 등장하는 모든 생성형 콘텐츠를 화면 단위로 정리.
> 각 UI 요소가 어떤 Sheets 컬럼 → Firestore 필드 → Swift 프로퍼티에서 오는지 한눈에 확인.
>
> **범례**: `—` = DB 없음 (기기 계산값·Core Data·하드코딩) · `*` = 저장 당시 스냅샷 · `HC` = 하드코딩

---

### 스플래시 (SplashView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore | Swift |
|----------|---------|----------------|-----------|-------|
| 전체 배경 | — | — `HC` | — | `"SplashBackground"` (Assets) |

---

### 온보딩 1화면 — 인트로 (ONBIntroView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore | Swift |
|----------|---------|----------------|-----------|-------|
| 전체 배경 | — | — `HC` | — | `"onb_bg_first_light"` (Assets) |
| 별점 | `★★★★★` | — `HC` | — | 하드코딩 |
| 앱 소개 문구 | `크리스천을 위한 최고의 알람 앱` | — `HC` | — | 하드코딩 |
| 슬로건 | `하루의 첫 순간, 주님과 함께` | — `HC` | — | 하드코딩 |
| 태그라인 | `Wake with the Word` | — `HC` | — | 하드코딩 |
| CTA 버튼 | `시작하기 →` | — `HC` | — | 하드코딩 |

---

### 온보딩 2화면 — 알람 체험 (ONBExperienceView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore | Swift |
|----------|---------|----------------|-----------|-------|
| 전체 배경 | — | — `HC` | — | `"onb_alarm_bg"` (Assets) → 폴백: `zoneBgImage` |
| **말씀 본문 (시뮬레이션)** | `아침에 나로 하여금 주의 인자한 말씀을 듣게 하소서` | — `HC` | — | 하드코딩 (시편 143:8) |
| **성경 참조 (시뮬레이션)** | `시편 143:8` | — `HC` | — | 하드코딩 |
| **해석 (시뮬레이션)** | `다윗이 원수들에게 쫓겨 영혼이 짓눌린 상황에서 드린 기도야...` | — `HC` | — | 하드코딩 |
| **일상 적용 (시뮬레이션)** | `오늘 아침 눈을 뜨자마자 "주님, 오늘도 말씀으로 시작할게요"라고 한 마디 건네봐.` | — `HC` | — | 하드코딩 |
| 알람 시간 표시 | `07:00` | — `HC` | — | 하드코딩 |
| 알람 배지 | `morning manna` | — `HC` | — | 하드코딩 |
| 날씨 예시 | `서울 18°C · 맑음` | — `HC` | — | 하드코딩 |
| 인사말 예시 | `잘 잤어요?` | — `HC` | — | 하드코딩 |
| CTA 버튼 | `다음 →` | — `HC` | — | 하드코딩 |

> ⚠️ 이 화면의 말씀·해석·적용은 **완전 하드코딩**. DB와 무관. 온보딩 전용 샘플 콘텐츠.

---

### 온보딩 3화면 — 닉네임 (ONBNicknameView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore | Swift |
|----------|---------|----------------|-----------|-------|
| 제목 | `처음 오셨군요! 매일 어떻게 불러드릴까요?` | — `HC` | — | 하드코딩 |
| 입력 placeholder | `beloved` | — `HC` | — | 하드코딩 |
| 힌트 | `탭해서 수정할 수 있어요` | — `HC` | — | 하드코딩 |
| CTA 버튼 | `기상 알람 보기 →` | — `HC` | — | 하드코딩 |

---

### 온보딩 4화면 — 알람 설정 (ONBAlarmPermissionView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore | Swift |
|----------|---------|----------------|-----------|-------|
| 타이틀 | `{닉네임}, 첫 알람을 설정해볼까요?` | — | — | `vm.nicknameDisplay` + HC |
| 설명 | `내일 아침, 이 시간에 말씀이 함께 울려요` | — `HC` | — | 하드코딩 |
| 반복 안내 | `매일 반복 · 반복 요일은 알람 탭에서 수정할 수 있어요` | — `HC` | — | 하드코딩 |
| 완료 버튼 | `알람 설정 완료` | — `HC` | — | 하드코딩 |
| 건너뛰기 | `나중에 하기` | — `HC` | — | 하드코딩 |
| 하단 안내 | `언제든 알람 탭에서 수정할 수 있어요` | — `HC` | — | 하드코딩 |
| 시간 피커 | `07:00` | — | — | `selectedTime` (Core Data) |

---

### 로그인 화면 (AuthWelcomeView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore | Swift |
|----------|---------|----------------|-----------|-------|
| 전체 배경 | — | — `HC` | — | `"AuthWelcomeBG"` (Assets) |
| 브랜드 로고 | mm | — `HC` | — | `"LogoMMColor"` (Assets) |
| 태그라인 | `Wake with the Word` | — `HC` | — | 하드코딩 |
| 슬로건 1 | `하나님 말씀으로` | — `HC` | — | 하드코딩 |
| 슬로건 2 | `하루를 맞이할 준비 되셨나요?` | — `HC` | — | 하드코딩 |
| Apple 로그인 | `Apple로 시작하기` | — `HC` | — | 하드코딩 |
| Google 로그인 | `Google로 시작하기` | — `HC` | — | 하드코딩 |
| 건너뛰기 | `로그인 없이 둘러보기` | — `HC` | — | 하드코딩 |
| 약관 | `시작하면 이용약관 및 개인정보처리방침에 동의하게 됩니다` | — `HC` | — | 하드코딩 |

---

### 홈 탭 (HomeView + VerseCardView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| 인사말 | `좋은 아침이에요, beloved!` | `HOME_GREETINGS` · `text` | `greetings` · `text` | `greetingText` |
| 날짜 | `4월 25일 금` | — | — | `currentDateString` |
| 시간 | `06:32 AM` | — | — | `currentTimeOnlyString` |
| 위치 · 온도 | `강남구 18°C` | — (WeatherKit/OWM) | — | `weather.cityName` · `weather.temperature` |
| 날씨 상태 | `흐림` | — | — | `weather.conditionKo` |
| **말씀 카드 본문** | `두려워하지 말라, 내가 너와 함께 함이라.` | `VERSES` · `verse_short_ko` | `verses` · `verse_short_ko` | `verse.verseShortKo` |
| **성경 참조** | `이사야 41:10` | `VERSES` · `reference` | `verses` · `reference` | `verse.reference` |
| **테마 태그** | `Hope` | `VERSES` · `theme` | `verses` · `theme` | `verse.theme.first` |
| **풀스크린 배경 (Zone 고정)** | — | `BACKGROUND_IMAGES` · `storage_url` | `background_images` · `storage_url` | `viewModel.currentBackground?.storageUrl` |
| 폴백 (이미지 로드 전) | — | — | — | `viewModel.currentMode.gradientColors` |

---

### 홈 바텀시트 (VerseDetailBottomSheet)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| **전체 구절** | `두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라...` | `VERSES` · `verse_full_ko` | `verses` · `verse_full_ko` | `verse.verseFullKo` |
| **성경 참조** | `이사야 41:10` | `VERSES` · `reference` | `verses` · `reference` | `verse.reference` |
| **해석** | `이사야가 포로 상태의 이스라엘에게 전한 말씀이야...` | `VERSES` · `interpretation` | `verses` · `interpretation` | `verse.interpretation` |
| **오늘의 적용** | `beloved, 오늘 어려움이 있다면 잠깐 멈춰봐...` | `VERSES` · `application` | `verses` · `application` | `verse.application` + `nicknameManager.nickname` |

---

### 알람 탭 목록 (AlarmListView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| **오늘의 말씀 카드 본문** | `두려워하지 말라, 내가 함께해.` | `VERSES` · `alarm_top_ko` | `verses` · `alarm_top_ko` | `verse.alarmTopKo` |
| (폴백) 말씀 본문 | `두려워하지 말라, 내가 너와 함께 함이라.` | `VERSES` · `verse_short_ko` | `verses` · `verse_short_ko` | `verse.verseShortKo` |
| **성경 참조** | `이사야 41:10` | `VERSES` · `reference` | `verses` · `reference` | `verse.reference` |
| 다음 알람 시간 | `06:00 AM` | — (Core Data) | — | `alarm.time` |
| 카운트다운 | `7시간 30분 후` | — | — | `countdownText(for:)` |
| 반복 요일 | `매일` / `주중` | — (Core Data) | — | `alarm.repeatSummary` |
| 테마 | `Hope` | — (Core Data) | — | `alarm.theme` |

---

### 알람 추가/수정 모달 (AlarmAddEditView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| **말씀 미리보기** | `"두려워하지 말라, 내가 너와 함께 함이라."` | `VERSES` · `verse_short_ko` | `verses` · `verse_short_ko` | `previewVerse.verseShortKo` |
| 시간 피커 | `07:00 AM` | — | — | `selectedTime` |
| 반복 요일 | `월 화 수 목 금 토 일` | — | — | `selectedDays` |
| 테마 선택 | `Hope / 소망` | — | — | `selectedTheme` |
| 알람음 | `Morning Song` | — | — | `soundId` |

---

### 알람 Stage 1 — 전체화면 (AlarmStage1View)

> **iOS 분기**: iOS 26+(AlarmKit) → 시스템 잠금화면에서 바로 Stage 2로 직행, Stage 1 건너뜀.
> iOS 15-25(Legacy) → UNNotification → Stage 1 → 종료 버튼 탭 → Stage 2 순서.
> Stage 1은 삭제된 게 아니며 Legacy 경로에서 여전히 사용됨.

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| 알람 시간 | `06:00` | — | — | `hourMinuteString` |
| AM/PM | `AM` | — | — | `amPmString` |
| 날짜 | `FRIDAY, APRIL 25` | — | — | `dateString` |
| **말씀 본문** | `두려워하지 말라, 내가 너와 함께 함이라.` | `VERSES` · `verse_short_ko` | `verses` · `verse_short_ko` | `verse.verseShortKo` |
| **성경 참조** | `이사야 41:10` | `VERSES` · `reference` | `verses` · `reference` | `verse.reference` |
| **말씀 카드 내부 배경** | — | `VERSE_IMAGES` · `storage_url` | `images` · `storage_url` | `coordinator.activeImage?.storageUrl` |
| 전체 배경 | — | — (정적 에셋) | — | `"AlarmStage1BG"` (Assets.xcassets) |

---

### 알람 Stage 2 — 웰컴 스크린 (AlarmStage2View)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| **알람 인사말** | `아침이 밝았어요, beloved!` | `ALARM_GREETINGS` · `text` | `alarm_greetings` · `text` | `greetingText` |
| 날짜 | `2026.04.25` | — | — | `alarmDateString` |
| 위치 · 온도 | `강남구 18°C` | — | — | `weather.cityName` · `weather.temperature` |
| 날씨 아이콘 | `☁️` | — | — | `weatherIcon(w.condition)` |
| 시간 (큰 숫자) | `06:00` | — | — | `alarmTimeString` |
| **말씀 본문** | `두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라...` | `VERSES` · `verse_full_ko` | `verses` · `verse_full_ko` | `verse.verseFullKo` |
| **성경 참조** | `이사야 41:10` | `VERSES` · `reference` | `verses` · `reference` | `verse.reference` |
| **풀스크린 배경** | — | `VERSE_IMAGES` · `storage_url` | `images` · `storage_url` | `coordinator.activeImage?.storageUrl` |

---

### 저장 탭 — 그리드 목록 (SavedView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| **카드 배경 이미지** `*` | — | — | `saved_verses/{uid}/verses` · `image_url` | `savedVerse.imageUrl` |
| **카드 말씀 텍스트** `*` | `두려워하지 말라, 내가 너와 함께 함이라.` | — | `saved_verses/{uid}/verses` · `verse_full_ko` | `savedVerse.verseFullKo` |
| 저장 날짜 | `2026.4.25` | — | `saved_verses` · `saved_at` | `savedVerse.savedAt` |
| 날씨 아이콘 · 온도 `*` | `☁️ 18°` | — | `saved_verses` · `weather_condition` · `weather_temp` | `savedVerse.weatherCondition` · `savedVerse.weatherTemp` |

---

### 저장 탭 — 상세 화면 (SavedDetailView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| **배경 이미지** `*` | — | — | `saved_verses/{uid}/verses` · `image_url` | `savedVerse.imageUrl` |
| **말씀 본문** | `두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라...` | `VERSES` · `verse_full_ko` | `verses` · `verse_full_ko` | `verseText` |
| **성경 참조** | `이사야 41:10` | `VERSES` · `reference` | `verses` · `reference` | `verseReference` |
| **해석** | `이사야가 포로 상태의 이스라엘에게 전한 말씀이야...` | `VERSES` · `interpretation` | `verses` · `interpretation` | `verseInterpretation` |
| **오늘의 적용** | `오늘 어려움이 있다면, 잠깐 멈춰봐...` | `VERSES` · `application` | `verses` · `application` | `verseApplication` |
| 저장 일시 `*` | `📅 2026.03.27  07:12  아침` | — | `saved_verses` · `saved_at` · `mode` | `savedVerse.savedAt` · `savedVerse.mode` |
| 날씨 스냅샷 `*` | `☁️ 18°C  💧 65%  📋 보통` | — | `saved_verses` · `weather_*` | `savedVerse.weatherTemp` · `savedVerse.weatherHumidity` · `savedVerse.weatherCondition` |
| 위치 `*` | `📍 서울 강남구` | — | `saved_verses` · `location_name` | `savedVerse.locationName` |

---

### 묵상 탭 — 말씀 읽기 (DevotionVerseView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| 섹션 제목 | `✏️ 말씀 읽기` | — (정적) | — | — |
| 오늘 날짜 | `4월 25일` | — | — | `formattedDate` |
| **말씀 요약 카드** | `두려워하지 말라, 내가 너와 함께 함이라.` | `VERSES` · `verse_short_ko` | `verses` · `verse_short_ko` | `verse.verseShortKo` |
| **전체 구절 읽기** | `두려워하지 말라, 내가 너와 함께 함이라.\n놀라지 말라...` | `VERSES` · `verse_full_ko` | `verses` · `verse_full_ko` | `readingTarget` (`verseFullKo` → 폴백 `verseShortKo`) |
| **성경 참조** | `— 이사야 41:10` | `VERSES` · `reference` | `verses` · `reference` | `verse.reference` |
| 번역 표기 | `개역한글` | — (정적) | — | — |
| **해석** | `이사야가 포로 상태의 이스라엘에게 전한 말씀이야...` | `VERSES` · `interpretation` | `verses` · `interpretation` | `verse.interpretation` |
| 묵상 텍스트 입력 | `이 말씀이 오늘 나에게...` | — (사용자 입력) | — | `readingText` |

---

### 묵상 탭 — 응답 작성 (DevotionResponseView)

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| 섹션 제목 | `🌱 오늘의 적용` | — (정적) | — | — |
| **일상 적용** | `beloved, 오늘 어려움이 있다면 잠깐 멈춰봐...` | `VERSES` · `application` | `verses` · `application` | `verse.application` + `nickname` |
| **묵상 질문** | `지금 당신을 가장 두렵게 만드는 것은?` | `VERSES` · `question` | `verses` · `question` | `verse.question` |
| 기도 입력 | `주님, ...` | — (사용자 입력) | — | `prayer` |
| 기도 글자 수 | `0 / 150자` | — | — | `prayer.count` |
| 감사 항목 1·2·3 | `오늘 좋은 날씨에 감사해요` | — (사용자 입력) | — | `gratitude1` · `gratitude2` · `gratitude3` |

---

### 절기 편성 (daily_cards + daily_card_images)

> 크리스마스·부활절 등 특정 날짜에 모든 유저에게 동일 콘텐츠를 강제 적용하는 시스템.
> 오늘 날짜의 `daily_cards/{date}` 문서가 없으면 → 일반 Zone 플로우.
> Zone 배경(`background_images/`)은 절기일에도 **변경되지 않음**.
>
> **설계 원칙**: 말씀(`verse_id`) = 편집자 확정 1개 (전체 유저 동일) · 이미지(`image_ids`) = 풀에서 랜덤 (유저마다 달라도 무방)

#### daily_cards — 날짜별 편성

| UI 표시명 | 표시 예시 | Sheets 탭 · 컬럼 | Firestore 컬렉션 · 필드 | Swift 프로퍼티 |
|----------|---------|----------------|----------------------|-------------|
| 절기 한국어 인사말 | `성탄을 축하해요!` | `DAILY_CARDS` · `greeting_ko` | `daily_cards` · `greeting_ko` | `DailyCard.greetingKo` |
| 절기 영어 인사말 | `Merry Christmas!` | `DAILY_CARDS` · `greeting_en` | `daily_cards` · `greeting_en` | `DailyCard.greetingEn` |
| 절기명 (내부) | `크리스마스` | `DAILY_CARDS` · `event_name` | `daily_cards` · `event_name` | `DailyCard.eventName` |
| **말씀** (확정 1개) | `v_025` | `DAILY_CARDS` · `verse_id` | `daily_cards` · `verse_id` | `DailyCard.verseId` |
| **이미지 풀** (랜덤 선택) | `["dc_img_001","dc_img_002"]` | `DAILY_CARDS` · `image_ids` | `daily_cards` · `image_ids` | `DailyCard.imageIds` |

#### daily_card_images — 절기 이미지 에셋

| 필드 | 설명 | 예시 |
|------|------|------|
| `dc_image_id` | 문서 ID, 파일명에서 자동 생성 | `dc_img_childrens_sunday_kids_joy` |
| `event_tag` | 절기 태그 (파일명 앞 2단어) | `childrens_sunday` |
| `filename` | 파일명 | `dc_img_childrens_sunday_kids_joy.jpg` |
| `storage_url` | Firebase Storage URL (`daily_card_images/` 폴더) | `https://...` |
| `source` / `license` | 출처 / 라이선스 | `morning manna Design` / `Commercial` |

**파일명 규칙**: `dc_img_{event_tag}_{설명}.jpg`
**업로드**: `design_test/`에 넣고 → `🖼️ 이미지 업로드.command` (자동으로 `DAILY_CARDS_IMAGES` 탭 + `daily_card_images/` 컬렉션 등록)

---

### 전체 화면 × 콘텐츠 빠른 참조

> ✅ = 해당 화면에서 표시됨 · `*` = 저장 당시 스냅샷 · `HC` = 하드코딩 (DB 없음)

#### DB/Sheets 연동 필드

| 필드 | 스플래시 | ONB인트로 | ONB체험 | ONB닉네임 | ONB알람 | 로그인 | 홈 | 홈시트 | 알람목록 | 알람추가 | Stage1 | Stage2 | 저장목록 | 저장상세 | 묵상읽기 | 묵상응답 |
|------|---------|---------|-------|---------|-------|------|---|------|-------|-------|------|------|------|------|------|------|
| `verse_short_ko` | | | | | | | ✅ | | ✅폴백 | ✅ | ✅ | | | | ✅ | |
| `verse_full_ko` | | | | | | | | ✅ | | | | ✅ | ✅`*` | ✅ | ✅ | |
| `reference` | | | | | | | ✅ | ✅ | ✅ | | ✅ | ✅ | | ✅ | ✅ | |
| `interpretation` | | | | | | | | ✅ | | | | | | ✅ | ✅ | |
| `application` | | | | | | | | ✅ | | | | | | ✅ | | ✅ |
| `alarm_top_ko` | | | | | | | | | ✅ | | | | | | | |
| `question` | | | | | | | | | | | | | | | | ✅ |
| `theme` | | | | | | | ✅ | | ✅ | ✅ | | | | | | |
| `greetings.text` | | | | | | | ✅ | | | | | | | | | |
| `alarm_greetings.text` | | | | | | | | | | | | ✅ | | | | |
| `daily_cards.greeting_ko` | | | | | | | ✅절기 | | | | | ✅절기 | | | | |
| `images.storage_url` | | | | | | | | | | | ✅카드 | ✅전체 | ✅`*` | ✅`*` | | |
| `background_images.storage_url` | | | | | | | ✅ | | | | | | | | | |
| `saved_verses.image_url` | | | | | | | | | | | | | ✅`*` | ✅`*` | | |

#### 정적 에셋 (하드코딩)

| 에셋 / 텍스트 | 스플래시 | ONB인트로 | ONB체험 | ONB닉네임 | ONB알람 | 로그인 | Stage1 | Stage2 |
|-------------|---------|---------|-------|---------|-------|------|------|------|
| `SplashBackground` | ✅ | | | | | | | |
| `onb_bg_first_light` | | ✅ | | | | | | |
| `onb_alarm_bg` | | | ✅폴백 | | | | | |
| `AuthWelcomeBG` | | | | | | ✅ | | |
| `LogoMMColor` | | | | | | ✅ | | ✅ |
| `AlarmStage1BG` | | | | | | | ✅전체 | |
| 하드코딩 말씀 (시편 143:8) | | | ✅ | | | | | |
| 하드코딩 해석/적용 | | | ✅ | | | | | |
| 슬로건·UI 문구 | | ✅ | ✅ | ✅ | ✅ | ✅ | | |

---

## 누락 체크리스트

> 이 문서 작성 시 검토한 항목. 신규 화면/콘텐츠 추가 시 여기에 체크.

### 화면 커버리지

- [x] SplashView
- [x] ONBIntroView (온보딩 1)
- [x] ONBExperienceView (온보딩 2 — 알람 체험)
- [x] ONBNicknameView (온보딩 3)
- [x] ONBAlarmPermissionView (온보딩 4)
- [x] AuthWelcomeView (로그인)
- [x] HomeView + VerseCardView (홈 탭)
- [x] WeatherWidgetView (홈 날씨 위젯)
- [x] VerseDetailBottomSheet (홈 바텀시트)
- [x] AlarmListView (알람 탭)
- [x] AlarmAddEditView (알람 추가/수정)
- [x] AlarmStage1View (Legacy iOS 15-25 전용)
- [x] AlarmStage2View (웰컴 스크린)
- [x] SavedView (저장 탭 목록)
- [x] SavedDetailView (저장 탭 상세)
- [x] DevotionVerseView (묵상 읽기)
- [x] DevotionResponseView (묵상 응답)
- [x] SettingsView (설정 탭)

### 콘텐츠 타입 커버리지

- [x] verses (verse_short_ko, verse_full_ko, reference, interpretation, application, alarm_top_ko, question, theme)
- [x] greetings (HOME_GREETINGS)
- [x] alarm_greetings (ALARM_GREETINGS)
- [x] daily_cards (절기 편성 — verse_id 1개 확정 + image_ids[] 풀 랜덤)
- [x] daily_card_images (절기 이미지 에셋 — dc_img_* → DAILY_CARDS_IMAGES 탭 + daily_card_images/ 컬렉션)
- [x] images / VERSE_IMAGES (감성 이미지)
- [x] background_images / BACKGROUND_IMAGES (Zone 고정 배경)
- [x] saved_verses (저장 스냅샷)
- [x] 온보딩 하드코딩 텍스트
- [x] 온보딩 하드코딩 이미지 에셋
- [x] 정적 에셋 전체 (SplashBackground, AuthWelcomeBG, LogoMMColor 등)

### 미커버 (의도적 제외)

- [ ] UI 레이블·버튼 문구 (저장, 닫기, 로그인 등) — 하드코딩 UI 문자열, 콘텐츠 관리 대상 아님
- [ ] SF Symbols — 시스템 아이콘, 교체 불필요
- [ ] 날씨 데이터 (WeatherKit/OWM) — 외부 API, Sheets/DB 관리 대상 아님
- [ ] 닉네임 — UserDefaults, 사용자 입력값

---

## 관련 파일 위치

| 파일 | 경로 | 내용 |
|------|------|------|
| 이 문서 | `docs/content-schema.md` | 콘텐츠 스키마 전체 레퍼런스 |
| 상세 가이드라인 | `docs/contents-guideline.md` | LLM 프롬프트, Zone 컨텍스트, QA 규칙 상세 |
| 프로젝트 전체 컨텍스트 | `CLAUDE.md` | 아키텍처, 스프린트 계획, 데이터 모델 |
| 콘텐츠 생성 규칙 | `scripts/content-rules.json` | JSON 기반 자동 검증 규칙 |
| Sheets 접근 키 | `scripts/serviceAccountKey.json` | 서비스 계정 (git 제외, 공유 금지) |
