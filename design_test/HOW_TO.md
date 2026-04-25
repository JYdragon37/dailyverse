# 🖼️ 이미지 업로드 가이드

> morning manna — 젠스파크 이미지 → 앱 반영 워크플로우

---

## 3단계로 끝납니다

```
Step 1  이미지를 이 폴더에 넣기
Step 2  Claude Code에서 검수 요청
Step 3  커맨드 파일 더블클릭 → 업로드 + 삭제 자동
```

---

## Step 1 — 이미지 넣기

젠스파크에서 생성한 이미지를 **이 폴더(`design_test/`)** 에 붙여넣기.
- 파일명은 그대로 두어도 됩니다 (Claude가 리네임합니다)
- JPG · PNG 모두 지원

---

## Step 2 — Claude Code에서 검수 요청

Claude Code 채팅에 아래 문장을 입력하세요:

```
design_test 검수해줘
```

Claude가 자동으로:
- 각 이미지 시각 확인 (비율·밝기·Zone 감성)
- 통과 / 오버레이 필요 / 탈락 판정
- 통과 이미지 → `bg_` 또는 `img_` 파일명으로 자동 리네임
- 탈락 이미지 → 삭제 권고 목록 출력 (삭제는 직접 확인 후)

---

## Step 3 — 업로드 커맨드 더블클릭

루트 폴더의 **`🖼️ 이미지 업로드.command`** 를 더블클릭합니다.

```
자동으로 진행됩니다:
  1. 미리보기 (dry-run)
  2. "업로드 하시겠습니까?" → y 입력
  3. Firebase Storage 업로드
  4. Google Sheets 기록
  5. Firestore 기록
  6. 이 폴더 파일 자동 삭제
```

---

## 파일명 규칙 (참고)

Claude가 자동으로 처리하므로 몰라도 됩니다.

| 파일 타입 | 형식 | 예시 |
|----------|------|------|
| Zone 고정 배경 | `bg_{zone}_{설명}.jpg` | `bg_deep_dark_banpo_hanriver.jpg` |
| 날씨별 배경 | `bg_{zone}_{weather}_{설명}.jpg` | `bg_rise_ignite_sunny_yeouido.jpg` |
| 감성 이미지 | `img_{zone}_{설명}.png` | `img_golden_hour_prague_sunset.png` |

**Zone 목록**: `deep_dark` · `first_light` · `rise_ignite` · `peak_mode` · `recharge` · `second_wind` · `golden_hour` · `wind_down`

---

## 빠른 복사

> Claude Code에 붙여넣을 문장:

```
design_test 검수해줘
```

---

*루트 폴더의 `🔍 이미지 검수.command` 를 더블클릭하면 위 문장이 클립보드에 자동 복사됩니다.*
