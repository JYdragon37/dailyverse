---
name: MeditationEntryDetailView 풀스크린 디자인 스펙
description: 묵상 달력 탭 시 나오는 풀스크린 뷰의 확정된 디자인 결정 사항
type: project
---

## 확정된 디자인 스펙 (2026-04-12)

### 그라데이션 오버레이 (4-stop)
- 0.00: black.opacity(0.70) — 상단 날짜 가독성
- 0.28: black.opacity(0.15) — 중앙 배경 노출 구간
- 0.55: black.opacity(0.35) — 말씀 블록 시작
- 1.00: black.opacity(0.78) — 하단 버튼 가독성

**Why:** 기존 2-stop(0.25/0.55)은 배경 이미지를 균일하게 죽임. 4-stop으로 이미지 중앙 30%가 살아숨쉬게 함.

### 날짜 블록 (3단 수직)
- 연도: 11pt, Medium, tracking +3, opacity 0.45
- 구분선: Rectangle 20×1pt, opacity 0.35, 상하 6pt padding
- 월·일: 32pt, Bold, opacity 1.0
- 요일: 14pt, Regular, opacity 0.65, padding-top 2pt
- 블록 전체 shadow: black.opacity(0.8), radius 8

**Why:** 연도 포함으로 묵상 날의 "인생 고정점" 감각 부여. 3단 계층이 정보를 감성적으로 풀어냄.

### 말씀 블록
- 본문: 26pt, semibold (기존 21pt → 업그레이드)
- lineSpacing: 11pt (행간 약 1.6배)
- shadow: black.opacity(0.9), radius 12, y 4 (오버레이 의존도 낮추고 텍스트 자체 가독성 확보)
- 참조: 14pt, Medium, tracking +0.5, opacity 0.75, em dash prefix("— 이사야 41:10")
- 위치: y = height * 0.50 (기존 0.48에서 2% 하강)
- 좌우 패딩: max(width * 0.10, 24pt)

### 묵상 기록 보기 힌트
- 순서: Rectangle(20×1, rule) → "묵상 기록 보기"(12pt Regular) → chevron.up(9pt)
- 전체 opacity: 0.50
- padding-top: 28pt

**Why:** 선이 먼저 나와 시선을 왼→오로 이끌고, 자연스럽게 위로 올리는 제스처를 암시.
