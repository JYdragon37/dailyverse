# 🖼️ 이미지 업로드 가이드

> morning manna — 젠스파크 이미지 → 앱 반영 워크플로우
> 파일명은 그대로 넣어도 됩니다. Claude가 모두 리네임합니다.

---

## 이미지 종류 먼저 파악

| 종류 | 언제 쓰는가 | Claude에게 말하는 방법 |
|------|-----------|---------------------|
| **Zone 배경** | 홈 화면 풀스크린 배경 | "deep_dark Zone 배경이야" |
| **감성 이미지** | 알람 팝업 · 저장 화면 배경 | "golden_hour 감성 이미지야" |
| **절기 이미지** | 특정 날짜(크리스마스 등) 한정 | "어린이주일 이미지야" |

---

## 3단계 워크플로우

```
Step 1  이미지를 이 폴더에 넣기  (파일명 그대로 OK)
Step 2  Claude Code에서 검수 + 리네임 요청
Step 3  🖼️ 이미지 업로드.command 더블클릭 → 업로드 + 삭제 자동
```

---

## Step 2 — Claude Code 요청 예시

### 일반 이미지 (Zone 배경 / 감성 이미지)
```
design_test 검수해줘
```
→ Claude가 각 이미지를 보고 Zone 판단 + 품질 검수 + 리네임

### 절기 이미지
```
design_test 검수해줘. 어린이주일 이미지야.
```
```
design_test 검수해줘. 크리스마스 절기 이미지야.
```
```
design_test 검수해줘. 부활절용이야.
```
→ Claude가 절기 이름을 파악해서 `dc_img_{event_tag}_{설명}` 형식으로 리네임

### 혼합 (일반 + 절기 함께)
```
design_test 검수해줘. 그 중 asset_abc.png는 어린이주일 이미지야.
```

---

## Step 3 — 업로드 커맨드 더블클릭

루트 폴더의 **`🖼️ 이미지 업로드.command`** 를 더블클릭합니다.

```
자동으로 진행됩니다:
  1. 미리보기 (bg_ / img_ / dc_img_ 분류 확인)
  2. "업로드 하시겠습니까?" → y 입력
  3. Firebase Storage 업로드
  4. Google Sheets 기록
  5. Firestore 기록
  6. 이 폴더 파일 자동 삭제
```

---

## 파일명 규칙 (참고 — Claude가 자동 처리)

| 종류 | 형식 | 예시 |
|------|------|------|
| Zone 고정 배경 | `bg_{zone}_{설명}.jpg` | `bg_deep_dark_banpo_hanriver.jpg` |
| 날씨별 배경 | `bg_{zone}_{weather}_{설명}.jpg` | `bg_rise_ignite_sunny_yeouido.jpg` |
| 감성 이미지 | `img_{zone}_{설명}.png` | `img_golden_hour_prague_sunset.png` |
| 절기 이미지 | `dc_img_{event_tag}_{설명}.jpg` | `dc_img_childrens_sunday_kids_joy.jpg` |

**Zone 목록**: `deep_dark` · `first_light` · `rise_ignite` · `peak_mode` · `recharge` · `second_wind` · `golden_hour` · `wind_down`

**절기 이미지는 DAILY_CARDS 탭에서 별도로 image_ids 배정 필요** (업로드 후 Claude에게 요청)

---

## 빠른 복사

루트 폴더의 `🔍 이미지 검수.command` 를 더블클릭하면
`design_test 검수해줘` 가 클립보드에 자동 복사됩니다.
