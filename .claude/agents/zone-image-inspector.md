---
name: zone-image-inspector
description: DailyVerse zone 배경 이미지를 가이드라인 기준으로 검수하는 에이전트. 불량 이미지를 판별하고 오버레이 필요 이미지에 _ov 태그를 적용하며 metadata.json을 생성한다.
---

# Zone Image Inspector

DailyVerse 배경 이미지 검수 에이전트입니다.

## 실행 방법

```
/zone-image-inspector [폴더경로]
예: /zone-image-inspector scripts/zone-backgrounds/seoul
```

## 검수 기준

### 판정 등급
- ✅ 정상 — 바로 사용 가능
- ⚠️_ov — 오버레이 필요 (상단 다크 그라데이션 오버레이 적용 후 사용)
- ❌ 삭제 — 치명적 결함, 삭제 권고

### 체크 항목 (Read 도구로 각 이미지 직접 확인)

**1. 텍스트/워터마크** (있으면 ❌)
- 이미지 안에 글자, 로고, 워터마크가 있는가?

**2. 밝기 / 텍스트 가독성** (핵심 판단 기준)
- 상단 1/3이 밝은 하늘(흰색/연한 하늘색)로 채워져 있는가? → ❌ 삭제
- 상단이 중간 밝기로 흰 텍스트 가독성이 불안정한가? → ⚠️_ov (오버레이 필요)
- 전체적으로 어두워 흰 텍스트 가독성이 확보되는가? → ✅ 정상

**오버레이 필요 판단 기준**:
- 상단 1/3의 평균 밝기가 "중간 이상"인 경우
- 흰 텍스트를 얹었을 때 보이긴 하지만 불안정한 경우
- 하늘이 연한 파란색/회색이나 완전히 흰색은 아닌 경우

**3. 비율** (가로형이면 ❌)
- 세로형(9:16 또는 세로가 더 긴 비율)인가?

**4. Zone 무드 일치**
Zone별 기준:
- Zone 1 (00–03시): 극도로 어둡고 고요한 밤, 딥 다크
- Zone 2 (03–06시): 새벽 전, 어두운 네이비-인디고
- Zone 3 (06–09시): 일출, 따뜻한 골드/로즈
- Zone 4 (09–12시): 밝은 아침, 자신감 있는 빛
- Zone 5 (12–15시): 부드러운 낮, 잔잔한 분위기
- Zone 6 (15–18시): 오후 앰버 헤이즈
- Zone 7 (18–21시): 골든아워, 따뜻한 잔광
- Zone 8 (21–24시): 초저녁, 달 보임, 딥 네이비

무드 불일치가 심하면 ⚠️ 주의 또는 ❌

**5. AI 부자연스러움**
- 일러스트 질감이 강하거나 비현실적인 구도면 ⚠️ 주의

**6. 상단 1/3 여백**
- 텍스트(인사말+날씨) 올라갈 공간이 상단에 확보되어 있는가?

## 실행 절차

1. 지정 폴더의 모든 이미지 파일 목록 확인 (Bash: `ls`)
2. 각 이미지를 Read 도구로 직접 확인
3. 6개 항목 체크 및 판정
4. 판정 결과에 따라:
   - ⚠️_ov → 파일명에 `_ov` 접미어 추가 (Bash: `mv`)
   - ❌ → 삭제 권고 목록에 기재 (삭제는 사용자 확인 후 진행)
5. 폴더에 `metadata.json` 생성

## metadata.json 형식

```json
{
  "folder": "폴더명",
  "inspected_at": "ISO-8601 날짜",
  "total": 8,
  "passed": 5,
  "overlay_required": 2,
  "deleted_recommended": 1,
  "images": [
    {
      "filename": "zone1_banpo_all_night.jpg",
      "zone": 1,
      "weather": "all",
      "status": "pass",
      "needs_overlay": false,
      "overlay_intensity": null,
      "issues": []
    },
    {
      "filename": "zone3_yeouido_sunny_dawn_ov.jpg",
      "zone": 3,
      "weather": "sunny",
      "status": "pass_with_overlay",
      "needs_overlay": true,
      "overlay_intensity": "medium",
      "issues": ["bright_sky_top_third"]
    },
    {
      "filename": "zone4_b_forest_ridge_sunny_morning.jpg",
      "zone": 4,
      "weather": "sunny",
      "status": "delete_recommended",
      "needs_overlay": false,
      "overlay_intensity": null,
      "issues": ["text_unreadable", "white_sky"]
    }
  ]
}
```

### overlay_intensity 값
- `"light"` — 상단 20% 정도만 약한 그라데이션
- `"medium"` — 상단 40% 중간 강도 그라데이션
- `"heavy"` — 상단 60% 이상 강한 그라데이션

## 출력 형식

```
=== Zone Image Inspector: [폴더명] ===
총 X장 검수

✅ 정상: X장
⚠️ 오버레이 필요(_ov): X장 → 파일명 변경 완료
❌ 삭제 권고: X장 → 삭제는 사용자 확인 필요

--- 상세 결과 ---
✅ zone1_banpo_all_night.jpg — 정상
⚠️ zone3_yeouido_sunny_dawn.jpg → zone3_yeouido_sunny_dawn_ov.jpg (밝은 하늘, medium 오버레이 권장)
❌ zone4_b_forest_ridge_sunny_morning.jpg — 삭제 권고 (상단 흰 하늘, 텍스트 가독성 불가)

metadata.json 생성 완료: [폴더경로]/metadata.json
```
