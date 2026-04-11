# DailyVerse — Zone 배경 이미지 업로드 폴더

이 폴더에 8개 Zone의 배경 이미지를 넣고 업로드 스크립트를 실행합니다.

## 파일명 규칙 (v6.0 — 8 Zone 기준)

| 파일명              | Zone             | 시간대      | 분위기       |
|---------------------|------------------|-------------|--------------|
| bg_deep_dark.jpg    | 🌑 Deep Dark     | 00:00–03:00 | 극야 / 고요  |
| bg_first_light.jpg  | 🌒 First Light   | 03:00–06:00 | 여명 / 준비  |
| bg_rise_ignite.jpg  | 🌅 Rise & Ignite | 06:00–09:00 | 아침 / 점화  |
| bg_peak_mode.jpg    | ⚡ Peak Mode     | 09:00–12:00 | 집중 / 성과  |
| bg_recharge.jpg     | ☀️ Recharge      | 12:00–15:00 | 정오 / 회복  |
| bg_second_wind.jpg  | 🌤 Second Wind   | 15:00–18:00 | 오후 / 재점화|
| bg_golden_hour.jpg  | 🌇 Golden Hour   | 18:00–21:00 | 저녁 / 수확  |
| bg_wind_down.jpg    | 🌙 Wind Down     | 21:00–24:00 | 밤 / 마무리  |

## 이미지 가이드라인

- 해상도: 최소 1080 × 1920px (세로형 9:16)
- 파일 형식: JPEG (품질 85%+) 또는 WebP
- 파일 크기: 최대 3MB
- 말씀 텍스트 가독성 확보 필수 (어두운 배경 또는 중간 명도 추천)
- 소스: Genspark Pro (상업적 사용 가능)

## 업로드 방법

루트 폴더의 "🖼️ 이미지 업로드.command" 더블클릭
또는: cd scripts && node upload_local_images.js

## 주의 (deprecated)
아래 구 4-Zone 파일명은 더 이상 사용하지 않습니다:
  ~~bg_morning.jpg~~ / ~~bg_afternoon.jpg~~ / ~~bg_evening.jpg~~ / ~~bg_dawn.jpg~~
