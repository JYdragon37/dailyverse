# DailyVerse 콘텐츠 가이드라인

> **상태**: 확정 — v6.2
> 마지막 업데이트: 2026-04-10 (devotion_question 필드 추가)

---

## 목차
1. [콘텐츠 전체 구조](#1-콘텐츠-전체-구조)
2. [필드명 전체 매핑 (v6.0 확정)](#2-필드명-전체-매핑-v60-확정)
3. [컬럼명 변경 이력](#3-컬럼명-변경-이력)
4. [Verse — 홈 말씀](#4-verse--홈-말씀)
5. [Alarm Verse — 알람 말씀](#5-alarm-verse--알람-말씀)
6. [VerseImage — 감성 배경 이미지](#6-verseimage--감성-배경-이미지)
7. [BackgroundImage — 존별 고정 배경](#7-backgroundimage--존별-고정-배경)
8. [글자수 가이드라인](#8-글자수-가이드라인)
9. [UI 문구](#9-ui-문구)
10. [Zone 기준표](#10-zone-기준표)

---

## 1. 콘텐츠 전체 구조

```
Firestore
├── verses/            v_001 ~ v_101     홈화면 말씀 (101개, 전체 active)
├── alarm_verses/      av_001 ~ av_105   알람 말씀 (105개)
├── images/                              감성 배경 이미지 메타데이터 (49개 active)
└── background_images/                   Zone별 고정 배경 (8개 신 Zone + 구 Zone 4개 잔존)

Firebase Storage
├── images/            *.jpg, *.webp     감성 이미지 원본 (59개 업로드 완료)
└── background_images/                   Zone 배경 원본 (8개)
```

**콘텐츠 현황 요약 (2026-04-10 기준)**

| 컬렉션 | 총수 | active | 비고 |
|--------|------|--------|------|
| verses | 101 | 101 | contemplation_ko 전체 보유, devotion_question 추가 예정 |
| alarm_verses | 105 | - | av_001~av_105 |
| images | 49 | 49 | Zone별 편차 큼 (아래 참고) |
| background_images | 12 | 8 신Zone + 4 구Zone | 구Zone은 코드 미참조 |

---

## 2. 필드명 전체 매핑 (v6.0 확정)

> 코드·스크립트·Firestore 문서 작성 시 아래 컬럼명을 기준으로 사용합니다.

| 번호 | 탭 | 섹션 | 타이틀(코드명) | UI 표시명 | Firestore 컬렉션 | 컬럼명 |
|------|-----|------|----------------|----------|----------------|--------|
| 1.1.1 | 홈 | 메인 카드 | main_title | 메인 글귀 | verses | verse_full_ko |
| 1.2.1 | 홈 | 팝업 | application | 오늘의 적용 | verses | application |
| 1.2.2 | 홈 | 팝업 | interpretation | 해석 | verses | interpretation |
| 2.1.1 | 알람 | 알람 목록 상단 | alarm_main | 오늘의 말씀 | verses | alarm_top_ko → 없으면 verse_short_ko |
| 2.2.1 | 알람 | Stage 1 전체화면 | alarm_popup1 | 알람 메인 글귀 | alarm_verses | verse_short_ko |
| 2.3.1 | 알람 | Stage 2 웰컴 | alarm_popup2 | 알람 전문 글귀 | alarm_verses | verse_full_ko |
| 2.3.2 | 알람 | Stage 2 한마디 | alarm_mission | 오늘의 한마디 참조 | alarm_verses | verse_short_ko |
| 3.1.1 | 말씀들 | 썸네일 카드 | saved_title | 저장 메인 글귀 | saved_verses | verse_full_ko (저장 시 복사) |
| 3.2.1 | 말씀들 | 저장 상세화면 | saved_application | 저장된 적용 | verses (동적) | application |
| 3.2.2 | 말씀들 | 저장 상세화면 | saved_interpretation | 저장된 해석 | verses (동적) | interpretation |
| 4.1.1 | 묵상 | 오늘의 묵상 카드 | contemplation_main | 오늘의 묵상 | verses | verse_short_ko |
| 4.2.1 | 묵상 | 묵상 작성 시트 | contemplation_mission | 묵상 한 구절 | verses | contemplation_ko + contemplation_reference |
| 4.3.1 | 묵상 | 묵상 응답 화면 | devotion_question | 묵상 질문 | verses | devotion_question |

---

## 3. 컬럼명 변경 이력

> v6.0 기준으로 아래 컬럼명이 변경되었습니다. deprecated 이름은 사용하지 않습니다.

| 기존 (deprecated) | 신규 | 적용 컬렉션 |
|------------------|------|-----------|
| text_ko | verse_short_ko | verses, alarm_verses |
| text_full_ko | verse_full_ko | verses, alarm_verses |
| alarm_text_ko | alarm_top_ko | verses |
| verse_text_short | verse_full_ko | saved_verses |

---

## 4. Verse — 홈 말씀

**Firestore 컬렉션**: `verses/`
**ID 형식**: `v_001`, `v_002` ...
**사용 위치**: 홈화면 카드, 말씀 상세 바텀시트, 저장 탭 썸네일

---

### 4-1. 텍스트 필드 규격

#### `verse_short_ko` — 핵심 요약 구절 (카드 표시용)

| 항목 | 기준 |
|------|------|
| 용도 | 알람 목록 오늘의 말씀, 묵상 카드 메인, Stage 2 한마디 |
| 분량 | **15~40자** |
| 형식 | 현대어 의역 — 직역 아님, 의미가 살아있는 자연스러운 표현 |
| 말투 | 친근체 (`~야`, `~이야`, `~거야`) 또는 성경 인용체 |
| 예시 | "두려워하지 말라 내가 너와 함께 함이라" (23자) ✅ |
| 이전 이름 | ~~text_ko~~ (deprecated) |

---

#### `verse_full_ko` — 전체 구절 (홈 메인 카드 + 바텀시트 + 저장 썸네일)

| 항목 | 기준 |
|------|------|
| 용도 | 홈화면 메인 글귀, 말씀 상세 바텀시트 상단, 저장 썸네일 오버레이, Stage 2 알람 전문 글귀 |
| 분량 | **40~120자** |
| 형식 | 전체 구절 의역 — 끊기지 않게 자연스럽게 |
| 말투 | 성경 인용체 또는 현대어 의역 |
| 예시 | "두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라 내가 너를 굳세게 하리라" ✅ |
| 이전 이름 | ~~text_full_ko~~ (deprecated) |

---

#### `interpretation` — 해석

| 항목 | 기준 |
|------|------|
| 용도 | 바텀시트 "해석" 섹션 |
| 분량 | **102~154자** (기준 128자, ±20%) |
| 구조 | ① 성경 배경/맥락 1문장 → ② 구절의 의미 1~2문장 → ③ 오늘과의 연결 1문장 |
| 줄바꿈 | 2~3문장마다 `\n` 삽입 |
| 금지 | 원어(히브리어·헬라어) 직접 표기 절대 금지 (한국어 풀이로 대체) |
| 금지 | ~이다, ~합니다, ~입니다, 설교조 |
| 허용 | ~야, ~이야, ~거야, ~있어, ~계셔 |

**나쁜 예 vs 좋은 예**:
```
❌ 나쁨: '히브리어 "두마야"는 잠잠히 고정한다는 뜻이야.'

✅ 좋음: '다윗이 수많은 적들에게 둘러싸인 상황에서 쓴 시야.\n
"잠잠히 바라라"는 소음 속에서도 하나님께만 시선을 고정하는 태도야.\n
상황이 아닌 임재가 나의 안전이 되는 거야.'
```

---

#### `application` — 일상 적용

| 항목 | 기준 |
|------|------|
| 용도 | 바텀시트 "오늘의 적용" 섹션 (닉네임 앞에 붙음) |
| 분량 | **49~73자** (기준 61자, ±20%) |
| 구조 | 오늘 바로 할 수 있는 구체적 행동 1가지 |
| 말투 | ~해봐, ~기억해, ~말해봐, ~생각해봐, ~내려놔 |
| 금지 | 반드시 ~해야, 꼭 ~하라, ~하십시오, ~해야 한다 |
| 시간대 | Zone에 맞는 시간대 상황 반영 (아침/낮/저녁/밤) |
| 예시 | "오늘 하루, 혼자가 아님을 기억하며 시작해" (23자) ✅ |

---

#### `alarm_top_ko` — 알람 목록 상단 전용 글귀 (선택)

| 항목 | 기준 |
|------|------|
| 용도 | 알람 탭 목록 상단 "오늘의 말씀" |
| 분량 | **15~35자** |
| 형식 | 짧고 강렬한 핵심 문장 |
| 말투 | 성경 인용체 또는 친근체 |
| 주의 | verse_short_ko가 35자 이하이면 alarm_top_ko 생략 가능 → verse_short_ko로 대체 표시 |
| 이전 이름 | ~~alarm_text_ko~~ (deprecated) |

---

#### `contemplation_ko` — 묵상 작성 시트용 구절 (신규)

| 항목 | 기준 |
|------|------|
| 용도 | 묵상 탭 "묵상 한 구절" 영역 — 사용자가 묵상을 작성할 때 보여주는 구절 |
| 분량 | **50~200자** |
| 형식 | 묵상에 어울리는 성경 구절 (verse_full_ko와 달라도 됨) |
| 조건 | 같은 verse_id의 verse_full_ko와 다른 구절 선정 가능 |
| 말투 | 성경 인용체 (의역 허용) |
| 톤 | 긴 묵상 시간에 천천히 읽을 수 있는 구절. verse_short_ko보다 깊이 있게 |
| 현재 상태 | 전체 빈값 → 콘텐츠 작성 필요 |

**예시**:
```
contemplation_ko: "나의 영혼아 잠잠히 하나님만 바라라. 무릇 나의 소망이 그로부터 나오는도다."
```

---

#### `devotion_question` — 묵상 응답 질문 (신규)

| 항목 | 기준 |
|------|------|
| 용도 | 묵상 응답 화면의 "묵상 질문" 섹션에 표시되는 개인화된 질문 |
| 분량 | **40~80자** (1~2문장) |
| 형식 | 질문형 문장. 닉네임 없이 저장 — 앱에서 `"{name}님, "` 앞붙임 |
| 톤 | 따뜻하고 개인적인 질문. 대답하기 쉬운 형태 (선택/회상/상상). 말씀의 핵심 의미를 일상 삶에 연결. 종교적 어조 피하고 일상 언어 사용 |
| 금지 | 닉네임 직접 포함 (앱에서 동적 합성), 설교조 질문, 부담스러운 신앙 점검 형태 |

**예시**:
```
"요즘 당신이 가장 무겁게 들고 있는 것은 무엇인가요?"
"오늘 이 말씀이 가장 필요한 순간은 언제일까요?"
"지금 당신의 시선은 어디를 향해 있나요?"
```

**contemplation_ko와의 차이**:
| 필드 | 역할 |
|------|------|
| `contemplation_ko` | 묵상 작성 시트에 표시되는 성경 구절 (핵심 구절 요약) |
| `devotion_question` | 묵상 응답 화면에 표시되는 삶 적용 질문 (개인화된 일상 질문) |

---

#### `contemplation_reference` — 묵상 구절 출처 (신규)

| 항목 | 기준 |
|------|------|
| 용도 | contemplation_ko의 성경 출처 표기 |
| 형식 | `"책이름 장:절"` (예: `"시편 62:5"`, `"이사야 40:31"`) |
| 주의 | contemplation_ko와 반드시 쌍으로 작성 |

**예시**:
```
contemplation_reference: "시편 62:5"
```

---

### 4-2. 메타데이터 필드 규격

| 필드 | 타입 | 허용값 | 규칙 |
|------|------|--------|------|
| `mode` | String 배열 | zone명 8가지 또는 `all` | 최소 1개, 다중 허용 |
| `theme` | String 배열 | 아래 테마 풀 참고 | Zone 테마와 일치해야 매칭됨 |
| `mood` | String 배열 | serene, calm, bright, dramatic, warm, cozy | Zone 무드와 일치해야 매칭됨 |
| `season` | String 배열 | spring, summer, autumn, winter, all | 복수 허용 |
| `weather` | String 배열 | sunny, cloudy, rainy, snowy, any | 복수 허용 |
| `status` | String | `active`, `draft`, `inactive` | 배포 전 반드시 `draft` |
| `curated` | Boolean | true / false | 신학 검수 완료 시 `true` |
| `cooldown_days` | Int | 7 (기본) | 동일 구절 재출현 방지 기간 (일) |
| `usage_count` | Int | 0~ | 자동 증가, 초기값 0 |

---

### 4-3. 목표 수량

| 기준 | 목표 |
|------|------|
| Zone당 최솟값 | 10개 active (cooldown 7일 기준 일주일 순환) |
| 전체 목표 | **80개+** |
| 현재 보유 | v_001~v_101 (101개) ✅ |

---

## 5. Alarm Verse — 알람 말씀

**Firestore 컬렉션**: `alarm_verses/`
**ID 형식**: `av_001`, `av_002` ...
**사용 위치**: 알람 Stage 1 전체화면, Stage 2 웰컴 스크린, 잠금화면 배너

---

### 5-1. Verse와의 차이점

| 항목 | Verse (v_) | Alarm Verse (av_) |
|------|-----------|------------------|
| 컬렉션 | verses/ | alarm_verses/ |
| verse_short_ko | 선택 | **필수** |
| application 톤 | 일반 일상 | 알람 맥락 (잠 깨는 순간 / 취침 전) |
| mode | 모든 Zone 가능 | 주로 아침/저녁 Zone |
| notes | 자유 | `alarm_context` 명시 권장 |

---

### 5-2. 알람 맥락별 application 톤

#### 아침 알람 (rise_ignite, first_light, peak_mode)
```
✅ "알람이 울리면 30초만 눈 감아봐.\n오늘 하루도 하나님 손 안에 있어."
✅ "내일 이 알람이 울릴 때, '오늘은 하나님이 만드신 날이야'라고 한 번만 말해봐."
❌ "매일 아침 하나님께 감사해야 한다."
```

#### 취침 전 알람 (wind_down, golden_hour)
```
✅ "알람을 맞추며 기억해. 내일 무슨 일이 생기든 하나님 손 안에 있어. 이제 편히 자."
✅ "오늘의 무게를 내려놓고 쉬어. 그분이 돌보신다."
❌ "반드시 하나님께 기도하고 자야 한다."
```

---

### 5-3. 목표 수량

| 분류 | 목표 |
|------|------|
| 아침용 (rise_ignite + first_light + peak_mode) | 30개+ |
| 저녁/취침용 (golden_hour + wind_down) | 30개+ |
| 기타 Zone | 15개+ |
| **전체 목표** | **75개+** |
| 현재 보유 | av_001~av_075 (75개) |

---

## 6. VerseImage — 감성 배경 이미지

**Firestore 컬렉션**: `images/`
**Firebase Storage**: `images/*.jpg`
**사용 위치**: 홈화면 배경 (말씀·날씨 알고리즘 매칭), 알람 Stage 1/2 배경, 저장 썸네일

---

### 6-1. 파일 규격

| 항목 | 기준 |
|------|------|
| 해상도 | 최소 **1080 × 1920px** (세로형 9:16) |
| 파일 형식 | JPEG (품질 85%+) 또는 WebP |
| 파일 크기 | 최대 **3MB** |
| 색공간 | sRGB |
| 방향 | 세로 (portrait) 전용 |

---

### 6-2. 소스 기준

| 소스 | 라이선스 | 사용 가능 여부 |
|------|---------|-------------|
| Genspark Pro | 상업적 사용 가능 | ✅ 현재 주력 소스 |
| Unsplash CC0 | 무료 상업 사용 | ✅ |
| 기타 유료 스톡 | 별도 확인 필요 | 확인 후 사용 |

---

### 6-3. 이미지 선정 기준

#### 허용하는 이미지
- 자연 풍경: 산, 바다, 하늘, 숲, 들판, 호수, 사막, 설경
- 감성적·경건한 분위기 — "하나님의 창조물"처럼 느껴지는 장면
- 추상적 빛, 구름, 물결, 안개
- 성지 지명 배경 (예루살렘, 페트라, 갈릴리) — 단, 관광사진 느낌 제외
- 실루엣 인물 (얼굴 비식별)

#### 금지하는 이미지
- 인물 얼굴 (정면 식별 가능한 얼굴)
- 십자가, 교회 건물, 종교 아이콘 등 특정 종교 상징
- 폭력적·선정적·공포스러운 이미지
- 특정 브랜드·로고·텍스트 노출
- 도시 야경, 인공 구조물 위주 이미지 (자연 없음)
- 너무 밝거나 채도가 높아 말씀 텍스트가 안 보이는 이미지

#### 톤(tone) 선정 기준
| tone | 설명 | 예시 피사체 |
|------|------|-----------|
| **bright** | 밝고 선명, 개방감 | 맑은 하늘, 일출 직후, 풍경 전경 |
| **mid** | 중간 밝기, 따뜻하거나 차분 | 골든아워, 안개 낀 숲, 흐린 날 |
| **dark** | 어둡고 깊이 있음, 고요함 | 별빛, 새벽 직전, 심야 설경, 어두운 숲 |

---

### 6-4. 메타데이터 필드 전체 규격

| 필드 | 필수 | 허용값 | 태깅 기준 |
|------|------|--------|---------|
| `filename` | ✅ | 파일명 | 중복 체크 키 — 스크립트 자동 설정 |
| `storage_url` | ✅ | Firebase Storage URL | 스크립트 자동 설정 |
| `tone` | ✅ | bright / mid / dark | **매칭 핵심** — Zone별 선호 톤 참고 |
| `is_sacred_safe` | ✅ | true / false | **홈/알람 배경 노출 여부** — 부적합 이미지만 false |
| `text_position` | ✅ | top / center / bottom | 이미지의 어느 영역이 밝은지 판단 (말씀이 그 반대 위치에 표시됨) |
| `text_color` | ✅ | light / dark | 배경이 어두우면 light, 배경이 밝으면 dark |
| `mode` | ✅ | zone명 또는 `all` | 어울리는 시간대 Zone (복수 허용) |
| `theme` | ✅ | 테마 풀 (아래 참고) | 이미지가 떠올리게 하는 테마 (1~3개) |
| `mood` | ✅ | serene / calm / bright / dramatic / warm / cozy | 이미지의 감정적 분위기 |
| `season` | 선택 | spring / summer / autumn / winter / all | 계절감이 뚜렷하면 지정, 아니면 all |
| `weather` | 선택 | sunny / cloudy / rainy / snowy / any | 날씨가 명확하면 지정, 아니면 any |
| `avoid_themes` | 선택 | 테마명 배열 | 이 이미지와 조합하기 부적합한 테마 (예: 십자가 없는 이미지에 "sacrifice" 금지) |
| `source` | ✅ | Genspark Pro / Unsplash | 저작권 추적용 |
| `license` | ✅ | Commercial / CC0 | |
| `status` | ✅ | active / draft | 신규 업로드 시 `active`로 설정 (스크립트 기본값) |

---

### 6-5. text_position · text_color 설정 방법

```
이미지를 보고 판단:

text_position:
  - 이미지 상단이 어둡고 하단이 밝음 → "top"    (말씀이 상단에 표시)
  - 이미지 전체가 균등함                → "center"
  - 이미지 상단이 밝고 하단이 어둠 → "bottom"  (말씀이 하단에 표시)

text_color:
  - 말씀이 표시될 영역(text_position)이 어두움 → "light"  (흰 텍스트)
  - 말씀이 표시될 영역이 밝음               → "dark"   (어두운 텍스트)
```

**예시**:
- 야간 숲 이미지 → tone: dark, text_position: center, text_color: light
- 일출 하늘 이미지 (하단에 산 실루엣) → tone: bright, text_position: bottom, text_color: light
- 안개 낀 호수 (전체 밝음) → tone: mid, text_position: center, text_color: dark

---

### 6-6. 파일명 → 메타데이터 자동 추론 키워드

`upload_local_images.js` 스크립트가 파일명에서 키워드를 감지해 자동으로 태깅합니다.

**mode 키워드**

| 키워드 | 자동 매핑 Zone |
|--------|--------------|
| deep_dark, midnight, night, aurora, moonlit, milky_way | deep_dark |
| first_light, dawn, blue_hour, foggy, misty | first_light |
| rise_ignite, sunrise, morning, rainbow, lighthouse | rise_ignite |
| peak_mode, peak, noon | peak_mode |
| recharge, midday | recharge |
| second_wind, autumn_archway | second_wind |
| golden_hour, sunset, dusk, twilight, santorini | golden_hour |
| wind_down, evening, frozen, monastery | wind_down |

**theme 키워드**

| 키워드 | 자동 매핑 테마 |
|--------|--------------|
| hope, guidance, lighthouse, rainbow | hope, renewal |
| faith, church, monastery, cathedral | faith, stillness |
| stillness, desert, campfire, milky_way | stillness, surrender |
| wisdom, petra, ruins, ancient | wisdom, courage |
| peace, ocean, beach, lake, meadow | peace, comfort |
| grace, aurora, fog | grace, rest |

> 자동 추론이 부정확하면 업로드 후 Firestore에서 직접 수정

---

### 6-7. Zone별 tone 우선순위

| Zone | 시간대 | 선호 tone | 이유 |
|------|--------|---------|------|
| 🌑 deep_dark | 00~03 | **dark** | 깊은 밤 — 고요하고 어두운 분위기 |
| 🌒 first_light | 03~06 | **dark** | 여명 직전 — 어둠이 걷히는 느낌 |
| 🌅 rise_ignite | 06~09 | **bright** | 일출 — 에너지 넘치는 밝음 |
| ⚡ peak_mode | 09~12 | **bright** | 한낮 — 선명하고 활기찬 빛 |
| ☀️ recharge | 12~15 | **mid** | 정오 — 따뜻하지만 차분 |
| 🌤 second_wind | 15~18 | **mid** | 오후 — 따뜻한 자연광 |
| 🌇 golden_hour | 18~21 | **mid** | 노을 — 황금빛 중간 톤 |
| 🌙 wind_down | 21~24 | **dark** | 밤 마무리 — 깊고 고요한 어둠 |

---

### 6-8. 이미지 선택 알고리즘 (앱 내부 로직)

```
1단계: 필터
  - status == "active" AND is_sacred_safe != false

2단계: 핀 이미지 우선 (UserDefaults pinnedImage_{zone})
  - 유저가 직접 지정한 이미지 최우선 적용

3단계: Zone 모드 필터
  - mode.contains(currentZone) OR mode.contains("all")

4단계: 스코어링
  theme 일치 1개당  +3점 (all이면 +3)
  mood 일치 1개당   +2점 (all이면 +2)
  weather 일치      +2점 (any 포함)
  season 일치       +1점 (all 포함)
  tone 선호 일치    +2점
  tone이 mid        +1점 (부분 점수)

5단계: 최고점 이미지 중 랜덤 1개 선택
```

---

### 6-9. 현재 보유 현황 및 우선순위 (2026-04-10)

| Zone | 현재 | 목표 | 상태 |
|------|------|------|------|
| 🌑 deep_dark | 9개 | 10~15개 | ⚠️ 1개 부족 |
| 🌒 first_light | 11개 | 10~15개 | ✅ |
| 🌅 rise_ignite | 12개 | 10~15개 | ✅ |
| ⚡ peak_mode | 3개 | 10~15개 | 🚨 **7개 부족** |
| ☀️ recharge | 4개 | 10~15개 | 🚨 **6개 부족** |
| 🌤 second_wind | 4개 | 10~15개 | 🚨 **6개 부족** |
| 🌇 golden_hour | 8개 | 10~15개 | ⚠️ 2개 부족 |
| 🌙 wind_down | 7개 | 10~15개 | ⚠️ 3개 부족 |
| 🌐 all (모든 Zone) | 3개 | 5~10개 | ⚠️ |
| **합계** | **49개** | **80~120개** | **31~71개 추가 필요** |

**신규 이미지 제작 우선순위**: peak_mode > recharge > second_wind > golden_hour

---

### 6-10. 이미지 업로드 방법

**방법 1: GUI (권장)**
```
루트 폴더의 "🖼️ 이미지 업로드.command" 더블클릭
→ images_to_upload/ 폴더의 모든 이미지 자동 업로드
→ 이미 Firestore에 등록된 파일명은 자동 건너뜀
```

**방법 2: 터미널**
```bash
cd /Users/jeongyong/workspace/dailyverse/scripts
node upload_local_images.js
```

**업로드 플로우**:
```
images_to_upload/ 에 파일 추가
    ↓
파일명 키워드로 mode/theme/mood/tone 자동 추론
    ↓
Firebase Storage 업로드
    ↓
Firestore images/{image_id} 문서 생성
    ↓
Google Sheets IMAGES 탭에 행 추가
```

> 업로드 후 Firestore에서 메타데이터 정확성 확인 필수 (특히 is_sacred_safe, text_position)

---

## 7. BackgroundImage — 존별 고정 배경

**Firestore 컬렉션**: `background_images/`
**Firebase Storage**: `background_images/*.jpg`
**사용 위치**: 홈화면 메인 배경 (VerseImage보다 우선 적용), 말씀 저장 시 캡처 URL

---

### 7-1. 구조

- Zone당 **1장** 큐레이션 고정 → 총 **8장**
- VerseImage 알고리즘과 무관 — Zone에 1:1 고정
- 홈화면에서 **currentBackground** 로 로드됨 (없으면 VerseImage 폴백)

---

### 7-2. Firestore ID 규칙

| bg_id | Zone | 시간대 |
|-------|------|--------|
| `bg_deep_dark` | 🌑 Deep Dark | 00~03시 |
| `bg_first_light` | 🌒 First Light | 03~06시 |
| `bg_rise_ignite` | 🌅 Rise & Ignite | 06~09시 |
| `bg_peak_mode` | ⚡ Peak Mode | 09~12시 |
| `bg_recharge` | ☀️ Recharge | 12~15시 |
| `bg_second_wind` | 🌤 Second Wind | 15~18시 |
| `bg_golden_hour` | 🌇 Golden Hour | 18~21시 |
| `bg_wind_down` | 🌙 Wind Down | 21~24시 |

> **deprecated** (코드 미참조, Firestore 정리 권장):
> `bg_morning`, `bg_afternoon`, `bg_evening`, `bg_dawn`

---

### 7-3. 이미지 선정 기준

- **파일 규격**: VerseImage와 동일 (1080×1920px, JPEG 85%+, 3MB 이하)
- **품질 기준**: VerseImage보다 더 엄선 — 홈화면에 장시간 노출됨
- **Zone 대표성**: 해당 Zone의 색감·분위기·시간대감이 명확해야 함
- **텍스트 가독성**: 말씀 텍스트 영역이 충분히 어두워야 함 (다크 오버레이 0.25~0.40 적용됨)
- **업로드 위치**: `scripts/background_images_to_upload/` 폴더

---

### 7-4. 현재 보유 현황 (2026-04-10)

| Zone | Firestore bg_id | Storage 파일 | 상태 |
|------|----------------|------------|------|
| 🌑 deep_dark | bg_deep_dark | bg_deep_dark.jpg | ✅ active |
| 🌒 first_light | bg_first_light | bg_first_light.jpg | ✅ active |
| 🌅 rise_ignite | bg_rise_ignite | bg_rise_ignite.jpg | ✅ active |
| ⚡ peak_mode | bg_peak_mode | bg_peak_mode.jpg | ✅ active |
| ☀️ recharge | bg_recharge | bg_recharge.jpg | ✅ active |
| 🌤 second_wind | bg_second_wind | bg_second_wind.jpg | ✅ active |
| 🌇 golden_hour | bg_golden_hour | bg_golden_hour.jpg | ✅ active |
| 🌙 wind_down | bg_wind_down | bg_wind_down.jpg | ✅ active |

**로컬 대기 파일**: `scripts/background_images_to_upload/` — 8Zone 파일 보관 중 (업로드 완료 상태)

---

## 8. 글자수 가이드라인

> 스크린샷 실측 기준. 신규 콘텐츠 작성 시 아래 범위를 반드시 준수합니다.

| 컬럼명 | 기준 글자수 | 범위 | 비율 |
|--------|-----------|------|------|
| verse_full_ko | 40자 | 40~120자 | 100~300% |
| verse_short_ko | verse_full_ko보다 짧게 | 15~40자 | — |
| alarm_top_ko | verse_short_ko 이하 | 15~35자 | — |
| interpretation | 128자 | 102~154자 | 80~120% |
| application | 61자 | 49~73자 | 80~120% |
| contemplation_ko | (신규) | 50~200자 | — |
| devotion_question | (신규) | 40~80자 | — |

---

## 9. UI 문구

### 9-1. Zone 인사말 (확정)

| Zone | 영문 | 한국어 |
|------|------|--------|
| deep_dark | Still up, Night Owl? | 아직 안 잤어요? |
| first_light | Rise before the world. | 세상보다 먼저 일어난 당신. |
| rise_ignite | Good Morning | 좋은 아침이에요, 오늘도 파이팅! |
| peak_mode | In the Zone | 지금 당신, 최고의 상태예요. |
| recharge | Breathe. Reset. | 잠깐 숨 고르고, 다시 달려요. |
| second_wind | Second Wind's here. | 두 번째 바람이 왔어요, 마무리해봐요. |
| golden_hour | Good Evening | 수고했어요, 오늘 하루도. |
| wind_down | Rest well. | 오늘도 잘 했어요, 푹 쉬어요. |

---

### 9-2. 날씨 권고 문구 (확정)

**UV Index (5단계)**

| 등급 | 범위 | 문구 |
|------|------|------|
| 낮음 | 0~2 | 외출 시 특별한 보호 불필요 |
| 보통 | 3~5 | 긴 소매나 모자 권장 |
| 높음 | 6~7 | 선크림 필수, 11-15시 자제 |
| 매우높음 | 8~10 | 11-15시 외출 최소화 |
| 위험 | 11+ | 외출을 피해주세요 |

**미세먼지 PM2.5 (4단계)**

| 등급 | 범위 | 문구 |
|------|------|------|
| 좋음 | 0~15㎍ | 외출하기 좋은 날이에요 |
| 보통 | 16~35㎍ | 민감한 분은 마스크 권장 |
| 나쁨 | 36~75㎍ | 마스크 착용, 외출 자제 |
| 매우나쁨 | 76㎍+ | 외출을 피해주세요 |

**강수 (3단계)**

| 확률 | 문구 |
|------|------|
| 20%+ | 가볍게 우산 챙겨요 |
| 40%+ | 우산 챙기는 게 좋아요 |
| 70%+ | 우산을 꼭 챙기세요 |

---

### 9-3. 온보딩 문구

5개 화면 문구 규격 별도 정의 필요

### 9-4. 토스트·EmptyState·버튼 문구

통일 기준 별도 정의 필요

---

## 10. Zone 기준표

| Zone | 시간대 | 키워드 | theme 풀 | mood 풀 |
|------|--------|--------|---------|---------|
| deep_dark | 00~03 | 고요·침묵 | stillness, surrender, grace, faith | serene, calm |
| first_light | 03~06 | 여명·준비 | faith, renewal, stillness, hope | serene, calm |
| rise_ignite | 06~09 | 각성·시작 | hope, courage, strength, renewal | bright, dramatic |
| peak_mode | 09~12 | 집중·성과 | wisdom, focus, courage, strength | bright, dramatic |
| recharge | 12~15 | 휴식·재충전 | rest, patience, gratitude, comfort | calm, warm |
| second_wind | 15~18 | 오후·재점화 | strength, focus, patience, wisdom | warm, calm |
| golden_hour | 18~21 | 저녁·수확 | gratitude, reflection, comfort, peace | warm, serene |
| wind_down | 21~24 | 마무리·안식 | peace, rest, comfort, stillness | cozy, calm |
