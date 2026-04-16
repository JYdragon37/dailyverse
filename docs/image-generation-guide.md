# DailyVerse 이미지 생성 가이드라인 v1.1

> 이 파일은 DailyVerse 앱에 사용되는 모든 이미지를 생성할 때의 기준 문서입니다.
> AI 이미지 생성 도구(Genspark 등)에 프롬프트를 입력하기 전 반드시 숙지하세요.

---

## 이미지 타입 선택

| | 타입 | 용도 | 규격 | DB 컬렉션 |
|---|---|---|---|---|
| 🅰 | **Zone 배경 이미지** | 홈 화면 풀스크린 배경, 알람 울림 화면 | 세로 9:16 | `background_images` |
| 🅱 | **말씀 배경 이미지** | Gallery 탭, 저장 카드 썸네일, 알람 웰컴 스크린 | 세로 2:3 | `images` |

---

## 공통 규칙 (🅰🅱 모두 적용)

### 기본 생성 원칙

- **모델**: `nano-banana-2`
- **프롬프트**: 영어로 작성
- 기본 1장 생성. 대량 생성 시 **6장 단위**로 끊어서 확인 후 다음 배치
- 결과물은 앱에서 바로 쓸 수 있는 실무 자산이어야 함
- **고퀄리티**: 아이폰 배경화면에 사용될 수 있는 수준의 고화질, 고품질
- **가로 이미지 금지** — 반드시 세로형

### 텍스트 절대 금지

이미지 안에 어떤 텍스트도 금지

- letters / typography / captions / signage / logo / watermark / 한글 / 영문 전부
- 텍스트를 나중에 얹기 좋은 **빈 공간만 확보**

---

## 🅰 Zone 배경 이미지 상세 가이드

### 개요

홈 화면 풀스크린 배경. 8개 Zone(3시간 단위)마다 자동 전환되는 앱의 메인 비주얼.
닉네임 인사말 + 날씨 + 말씀 텍스트(흰색 대형)가 올라가므로 **가독성 최우선**.

### Zone별 스펙

| Zone | 시간 | 이름 | 무드 | 색온도 | 명도 | 그라데이션 |
|------|------|------|------|--------|------|-----------|
| 1 | 00–03 | 🌑 Deep Dark | dark, still | 극냉(deep purple-black) | 극저 | `#06080F→#0D1533` |
| 2 | 03–06 | 🌒 First Light | dark, calm | 냉(navy-indigo) | 저 | `#06080F→#0D1533` |
| 3 | 06–09 | 🌅 Rise & Ignite | bright, dramatic | 중온(warm gold) | 중~중고 | `#1A0E2E→#3D1F5A` |
| 4 | 09–12 | ⚡ Peak Mode | bright, dramatic | 중온(warm gold) | 중~중고 | `#1A0E2E→#3D1F5A` |
| 5 | 12–15 | ☀️ Recharge | calm, warm | 중온(soft blue-gold) | 중 | `#0D1B2A→#1B3A5C` |
| 6 | 15–18 | 🌤 Second Wind | calm, warm | 중온(amber haze) | 중 | `#0D1B2A→#1B3A5C` |
| 7 | 18–21 | 🌇 Golden Hour | warm, serene | 온(deep amber) | 중저 | `#06080F→#0D1533` |
| 8 | 21–24 | 🌙 Wind Down | cozy, calm | 냉(navy-indigo) | 저 | `#06080F→#0D1533` |

### Zone별 프롬프트 무드 키워드

```
Zone 1: pitch-black sky, faint starlight, absolute stillness, nocturnal silence, deep purple-black tones
Zone 2: pre-dawn glow, first hint of indigo light on horizon, sleeping world, quiet anticipation
Zone 3: sunrise breaking through, amber and rose light, morning mist lifting, fresh start energy
Zone 4: clear bright morning, confident golden light, crisp atmosphere, full daylight dignity
Zone 5: soft midday diffused light, gentle warmth, breathing room, calm blue-gold palette
Zone 6: late afternoon amber haze, lengthening shadows, warm persistence, golden-tinted atmosphere
Zone 7: deep sunset afterglow, gratitude warmth, amber-to-indigo transition, reflective serenity
Zone 8: early night, moon visible, deep navy sky, cozy darkness settling, peaceful closure
```

### 프롬프트 필수 포함 문구

```
deep dark tone, low-key lighting, ample negative space in upper third,
low horizon, no text no letters no watermark, 9:16 vertical,
documentary DSLR realism
```

### 레이아웃 원칙

- **상단 1/3**: 충분한 여백 (인사말 + 날씨 텍스트 영역)
- **낮은 horizon**: 피사체는 하단에 배치
- 흰색 텍스트를 얹었을 때 가독성 확보 필수

### 🅰 체크리스트

| # | 체크 항목 |
|---|-----------|
| ✅ | 모델 nano-banana-2 / 프롬프트 영어 |
| ✅ | 9:16 세로형 (가로 이미지 절대 금지) |
| ✅ | 상단 1/3에 충분한 여백 |
| ✅ | 낮은 horizon |
| ✅ | 이미지 안에 텍스트 전혀 없음 |
| ✅ | 해당 Zone 무드·색온도·명도에 정확히 부합 |
| ✅ | 딥 다크 톤 기조 유지 |
| ✅ | 흰색 텍스트 얹었을 때 가독성 확보 |
| ✅ | 너무 AI스럽지 않고 실사적 |
| ✅ | 이전 컷과 장면 충분히 다름 |

### 파일명 규칙

```
bg_{zone_rawValue}_{location}_{weather}_{time}.jpg

예시:
  bg_rise_ignite_misty_mountain_dawn.jpg
  bg_deep_dark_clear_milkyway.jpg
  bg_golden_hour_rainy_hanriver_dusk.jpg
```

**weather 값**: `sunny` / `rainy` / `snowy` / `misty` / `cloudy` / `clear` / `all`

```
# _ov 접미어 규칙 (오버레이 필요 표시)
# 밝기로 인해 흰색 텍스트 가독성이 불안정한 이미지는 파일명에 _ov 추가
# 앱에서 자동으로 상단 다크 그라데이션 오버레이를 적용함

bg_{zone_rawValue}_{location}_{weather}_{time}.jpg           → 오버레이 불필요
bg_{zone_rawValue}_{location}_{weather}_{time}_ov.jpg        → 오버레이 자동 적용

예시:
  zone1_banpo_all_night.jpg                           (정상)
  zone3_yeouido_sunny_dawn_ov.jpg                     (오버레이 필요)
  zone4_hanriver_sunny_morning_ov.jpg                 (오버레이 필요)
```

### metadata.json 자동 생성

이미지 검수 후 각 폴더에 `metadata.json`이 자동 생성됩니다.
Firebase 업로드 시 이 파일의 정보가 Firestore 문서에 자동 병합됩니다.

```json
{
  "filename": "zone3_yeouido_sunny_dawn_ov.jpg",
  "zone": 3,
  "weather": "sunny",
  "concept": "seoul",
  "status": "pass_with_overlay",
  "needs_overlay": true,
  "overlay_intensity": "medium",
  "issues": ["bright_sky_top_third"]
}
```

```
overlay_intensity 기준:
  light  (상단 30%, opacity 0.35) → 하늘이 약간 밝은 경우
  medium (상단 45%, opacity 0.50) → 하늘이 중간 밝기인 경우
  heavy  (상단 60%, opacity 0.65) → 하늘이 많이 밝은 경우
```

**weather 필드와 앱 노출 로직**:
- `weather: "all"` → 날씨 무관 항상 노출
- `weather: "sunny" | "cloudy" | "misty"` → 항상 노출 (맑음 계열)
- `weather: "rainy"` → 유저 현재 날씨가 rainy일 때만 노출
- `weather: "snowy"` → 유저 현재 날씨가 snowy일 때만 노출

---

## 🅱 말씀 배경 이미지 상세 가이드

### 개요

성경 말씀이 얹혀지는 다양한 컨셉의 감성 이미지.
Gallery 탐색·저장 카드·알람 웰컴 스크린에 사용.

### 규격 & 레이아웃

- **세로 2:3** (Gallery 그리드 비율)
- 텍스트가 올라갈 위치(`top` / `center` / `bottom`)가 명확하게 구분되면 OK
- 상단 여백 권장하되, 🅰만큼 엄격하지 않음

### 표현 자유도

🅰보다 감성적·상징적 표현 자유도 높음.
자연 풍경 외에도 상징적 오브젝트 허용:

> 촛불, 열린 창문, 빗방울 맺힌 유리, 들꽃, 오래된 나무, 빈 벤치, 강물 위 빛, 안개 속 길 등

딥 다크 톤 기조 유지하되, 말씀 테마에 따라 **밝은 톤(bright)도 허용**.

### 테마 & 분위기 태그

| 분류 | 태그 |
|------|------|
| **테마** | `hope` `courage` `strength` `renewal` `wisdom` `focus` `patience` `gratitude` `comfort` `peace` `rest` `stillness` `surrender` `grace` `faith` `reflection` |
| **분위기** | `serene` `calm` `bright` `dramatic` `warm` `cozy` |
| **Tone** | `bright` / `mid` / `dark` |

작업 시 타깃 테마·분위기를 명시하고, 결과물의 tone 분류(bright/mid/dark)가 판단 가능해야 함.

### 다양성 매트릭스

같은 테마라도 장면이 반복되면 안 됩니다.

**장소 축**
- 한국 자연: 설악산, 제주 해안, 대나무 숲, 시골 논길, 한강 새벽
- 보편적 자연: 호수, 설원, 사막, 초원, 해안 절벽, 숲 오솔길
- 상징적 공간: 오래된 교회 창문 빛, 촛불 있는 방, 비 온 뒤 골목, 열린 문 너머 빛

**계절 축**: 봄(벚꽃, 안개) / 여름(녹음, 장마 후) / 가을(단풍, 억새) / 겨울(설경, 서리)

**기후 축**: 맑음 / 안개 / 비 직후 / 눈 / 구름 사이 빛 / 흐린 하늘

### 프롬프트 필수 포함 문구

```
contemplative mood, [theme keyword], [mood keyword],
no text no letters no watermark, 2:3 vertical,
documentary DSLR realism
```

### 🅱 체크리스트

| # | 체크 항목 |
|---|-----------|
| ✅ | 모델 nano-banana-2 / 프롬프트 영어 |
| ✅ | 2:3 세로형 |
| ✅ | 텍스트 배치 최적 위치(top/center/bottom) 명확 |
| ✅ | 이미지 안에 텍스트 전혀 없음 |
| ✅ | 타깃 테마·분위기와 시각적으로 일치 |
| ✅ | tone(bright/mid/dark) 분류 가능 |
| ✅ | 너무 AI스럽지 않고 실사적 |
| ✅ | 이전 컷과 장소/계절/기후/피사체 충분히 다름 |
| ✅ | 경건하고 고요한 톤 유지 |
| ✅ | 상징적 오브젝트 사용 시 과하지 않음 |

### 파일명 규칙

```
img_{zone}_{theme}_{descriptor}.jpg

예시:
  img_golden_hour_gratitude_sunset_lake.jpg
  img_rise_ignite_hope_misty_path.jpg
  img_wind_down_peace_candlelight.jpg
```

---

## 컨셉별 프롬프트 예시

### 서울 (Seoul)

```
Zone 1 (deep dark):
A wide-angle shot of Banpo Bridge over Han River at 2am,
the city lights reflecting on the dark water,
pitch-black sky above, deep navy tones,
no people, absolute stillness, 9:16 vertical,
no text no letters no watermark, documentary DSLR realism
```

### 피렌체·파리 (Florence/Paris)

```
Zone 2 (first light):
Cobblestone street in Florence at 4am,
warm lanterns glowing against deep blue pre-dawn sky,
fog rising from the Arno River in the background,
no people, misty atmosphere, 9:16 vertical,
no text no letters no watermark, documentary DSLR realism
```

### 호주 (Australia)

```
Zone 3 (rise ignite):
Sydney Opera House at sunrise from the harbour,
amber and rose light breaking over the water,
morning mist lifting, golden tones reflecting on the harbour,
no people, 9:16 vertical,
no text no letters no watermark, documentary DSLR realism
```

### 프라하 (Prague)

```
Zone 7 (golden hour):
Charles Bridge in Prague at golden hour,
warm amber afterglow over the Vltava River,
the castle silhouetted on the hill,
no people, reflective serenity, 9:16 vertical,
no text no letters no watermark, documentary DSLR realism
```

### 자연 (Nature)

```
Zone 8 (wind down):
A snow-covered pine valley at night in South Korea,
crescent moon visible in deep navy sky,
a small frozen stream winding through the trees,
serene and quiet, 9:16 vertical,
no text no letters no watermark, documentary DSLR realism
```

---

## 현재 보유 컨셉 현황

| 폴더 | 컨셉 | 파일 수 | zone 커버리지 | 오버레이(_ov) | 포맷 |
|------|------|---------|--------------|--------------|------|
| `seoul/` | 서울 맑음 | 8 | zone 1–8 완성 | 3장 (z3/z4/z6) | JPG |
| `seoul_rainy/` | 서울 우천 | 8 | zone 1–8 완성 | 2장 (z3/z5) | JPG |
| `nature/` | 자연 맑음 | 14 | zone당 1–2장 | 2장 (z4a/z5a) | JPG |
| `nature_rainy/` | 자연 우천 | 7 | zone 1–8 (z2 삭제) | 1장 (z5) | JPG |
| `greece_rome/` | 고대 그리스·로마 AI | 6 | zone 1–3/6–8 (z4/z5 삭제) | 1장 (z6) | PNG |
| `prague/` | 프라하 AI | 7 | zone 1–8 (z5 삭제) | 0장 | PNG |
| `florence_paris/` | 피렌체·파리 | 5 | zone 1/2/3/8만 | 1장 (z3a) | JPG |

> ⚠️ 부족한 zone 슬롯 (추가 생성 필요):
> - `greece_rome`: zone 4, zone 5 (낮 이미지 — 밝기 문제로 삭제됨)
> - `prague`: zone 5 (낮 이미지 — 밝기 문제로 삭제됨)
> - `florence_paris`: zone 4, 5, 6, 7 (낮/오후/황혼 시간대)

> 💡 추가 가능한 새 컨셉: `australia` (호주), `japan` (일본), `new_york` (뉴욕)

---

*최종 업데이트: 2026-04-16 | v1.1*
