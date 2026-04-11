# Plan: weather-detail-ui

**Feature**: 날씨 상세페이지 UI 개선
**Date**: 2026-04-09
**Level**: Dynamic
**Phase**: Plan

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| **Problem** | 날씨 상세페이지가 단일 검정 배경 + 강수확률 0% 표기로 정보가 불친절함 |
| **Solution** | 날씨/시간대 기반 동적 배경 그라데이션 + 강수 정보 개선 |
| **Function UX Effect** | iOS Weather 앱 수준의 몰입감 있는 날씨 상세 화면으로 감성+정보 모두 개선 |
| **Core Value** | DailyVerse의 "배려하는 친구" 톤을 날씨 UI에도 일관되게 적용 |

---

## Context Anchor

| 축 | 내용 |
|----|------|
| **WHY** | 날씨 상세 화면이 앱 전체 감성(청록→보라 그라데이션, 골드 강조)과 동떨어진 검정 단색 배경 |
| **WHO** | 날씨 위젯 탭해서 상세 보는 유저 — 정보성 + 감성 둘 다 기대 |
| **RISK** | 배경 그라데이션이 텍스트 가독성 저하 시킬 수 있음 → 다크 오버레이 레이어 필수 |
| **SUCCESS** | 강수확률 0% 타일이 의미있는 정보를 제공, 배경이 현재 날씨를 즉각 시각적으로 전달 |
| **SCOPE** | HomeView.swift (WeatherDetailSheet) + WeatherData.swift + WeatherService.swift |

---

## 1. 기능 요구사항

### 1-1. 강수 타일 개선

**현재**: 강수 확률 `0%` 단순 표시
**목표**: iOS Weather 앱 패턴 적용

| 조건 | 표시 |
|------|------|
| 강수확률 0% + 강수량 없음 | "비 없음" |
| 강수확률 0% + 강수량 있음 | "0% · 0.0mm" |
| 강수확률 > 0% + 강수량 없음 | "X%" |
| 강수확률 > 0% + 강수량 있음 | "X% · Y.Zmm" |
| 데이터 없음(`nil`) | "--" |

**WeatherKit 데이터 소스**:
- 확률: `daily.forecast.first.precipitationChance` (이미 사용 중)
- 강수량: `daily.forecast.first.precipitationAmount.value` (Measurement<UnitLength>, mm 변환 필요) — **신규 추가**

### 1-2. WeatherDetailSheet 배경 동적 그라데이션

**현재**: `Color.black.opacity(0.4)` 단일
**목표**: condition + mode(시간대) 기반 5단계 그라데이션

| 날씨 × 시간대 | 그라데이션 | 참고 |
|-------------|----------|------|
| 맑음 + 아침/낮 | 하늘색→밝은 파랑 | iOS Weather 맑음 낮 |
| 맑음 + 저녁/밤 | 짙은 남색→보라 | iOS Weather 맑음 밤 |
| 흐림 | 회청색→진회색 | iOS Weather 흐림 |
| 비 | 짙은 파랑→남회색 | iOS Weather 비 |
| 눈 | 연한 파랑→흰빛 회색 | iOS Weather 눈 |

**구조**: `ZStack { dynamicBackground → darkScrim(0.25~0.40) → content }`
darkScrim은 가독성 보장용. 배경이 밝을수록 scrim opacity 높임.

### 1-3. 추가 폴리시 (Low 우선순위)

- 배경 전환 시 `.animation(.easeInOut(duration: 0.5))` 적용
- 시간별 예보 아이콘 색상을 배경 테마에 맞게 조정 (기존 `.dvTemperature` 유지)

---

## 2. 기술 스펙

### 수정 파일 목록

| 파일 | 변경 유형 | 내용 |
|------|---------|------|
| `WeatherData.swift` | 필드 추가 | `precipitationAmountMM: Double?` |
| `WeatherService.swift` | fetch 추가 | WeatherKit `precipitationAmount` → mm 변환 |
| `HomeView.swift` | UI 수정 | 강수 타일 로직 + 배경 그라데이션 함수 추가 |

### WeatherData 추가 필드

```swift
var precipitationAmountMM: Double?  // 오늘 예상 강수량 (mm)
```

CodingKey: `precipitation_amount_mm`
WeatherCacheManager 스키마: v7로 bump (구 캐시 무효화)

### 배경 그라데이션 함수

```swift
private func weatherDetailBackground(
    condition: String,
    mode: AppMode
) -> LinearGradient
```

파일 내 private func으로 `WeatherDetailSheet` 안에 정의.
SwiftUI `LinearGradient`만 사용 — 신규 에셋/이미지 불필요.

---

## 3. 구현 순서 (체크리스트)

### Phase 1 — 데이터 레이어 (WeatherKit 강수량)
- [ ] `WeatherData.swift`: `precipitationAmountMM: Double?` 필드 추가
- [ ] `WeatherService.swift` fetchFromWeatherKit: `daily.forecast.first.precipitationAmount` → mm 변환 추가
- [ ] `WeatherService.swift` fetchFromOpenWeatherMap: OWM `rain.1h` 또는 `rain.3h` 폴백
- [ ] `WeatherCacheManager.swift`: 스키마 v7 bump

### Phase 2 — 강수 타일 로직
- [ ] `HomeView.swift` WeatherDetailTile 강수 타일: 조건별 표시 로직 구현
  - 0% + nil → "비 없음"
  - 0% + 0.0mm → "0% · 0.0mm"
  - >0% + nil → "X%"
  - >0% + Y.Zmm → "X% · Y.Zmm"

### Phase 3 — 배경 그라데이션
- [ ] `HomeView.swift` `weatherDetailBackground()` 함수 구현 (5가지 날씨 × 2 시간대)
- [ ] `WeatherDetailSheet` body: `Color.black.opacity(0.4)` → 동적 배경 + darkScrim 구조로 교체
- [ ] 텍스트 가독성 검증 (각 배경별 scrim opacity 조정)

### Phase 4 — 폴리시
- [ ] 배경 전환 애니메이션 `.easeInOut(0.5)`
- [ ] SourceKit 에러 검증 (false positive 구분)
- [ ] 빌드 확인

---

## 4. 그라데이션 색상 스펙

### Sunny Day (맑음 + 아침/낮)
```swift
colors: [Color(red:0.38,green:0.62,blue:0.92), Color(red:0.18,green:0.42,blue:0.82)]
// 하늘색 → 코발트 블루
scrim: 0.25
```

### Sunny Night (맑음 + 저녁/밤)
```swift
colors: [Color(red:0.08,green:0.10,blue:0.28), Color(red:0.22,green:0.12,blue:0.38)]
// 딥 네이비 → 다크 퍼플 (DailyVerse 브랜드 컬러와 연결)
scrim: 0.20
```

### Cloudy (흐림)
```swift
colors: [Color(red:0.38,green:0.42,blue:0.52), Color(red:0.22,green:0.25,blue:0.32)]
// 회청색 → 진회색
scrim: 0.30
```

### Rainy (비)
```swift
colors: [Color(red:0.18,green:0.22,blue:0.38), Color(red:0.12,green:0.15,blue:0.28)]
// 스틸 블루 → 다크 네이비
scrim: 0.28
```

### Snowy (눈)
```swift
colors: [Color(red:0.72,green:0.82,blue:0.92), Color(red:0.48,green:0.58,blue:0.72)]
// 연한 아이스 블루 → 페일 블루
scrim: 0.40  // 밝은 배경이라 scrim 강화
```

---

## 5. 리스크

| 리스크 | 대응 |
|--------|------|
| WeatherKit `precipitationAmount` nil (야간, 현재 날씨 없음) | `?? nil` 폴백, "비 없음" 표시 |
| OWM 폴백 시 강수량 없음 | mm 생략, 확률만 표시 |
| 눈 배경이 밝아서 흰 텍스트 안 보임 | scrim 0.40으로 강화 |
| 배경 교체 후 AQI 카드 등 기존 컴포넌트 가독성 | 각 컴포넌트가 `.ultraThinMaterial` 사용 중 → 자동 대응 |

---

## 6. 성공 기준

- [ ] 강수확률 0% 타일이 "비 없음" 또는 mm 정보 표시
- [ ] 맑음/흐림/비/눈 × 낮/밤 총 5가지 배경이 조건에 맞게 표시
- [ ] 기존 텍스트·카드 가독성 유지 (WCAG AA 기준)
- [ ] WeatherKit + OWM 폴백 양쪽에서 크래시 없음
