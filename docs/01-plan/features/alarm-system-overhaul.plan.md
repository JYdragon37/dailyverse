# Plan: alarm-system-overhaul

> **Feature**: 알람 시스템 전체 점검 및 개선
> **작성일**: 2026-04-15
> **상태**: Plan 확정

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | alarm-system-overhaul |
| 작성일 | 2026-04-15 |
| 대상 파일 | AppRootView.swift, LegacyAlarmEngine.swift, NotificationManager.swift, AlarmCoordinator.swift, Alarm.swift, AlarmAddEditView.swift |

### Value Delivered

| 관점 | 내용 |
|------|------|
| Problem | 앱 종료 시 알람 1회만 발동, 오디오 파일 누락, 디버그 코드 미제거, 잠금화면 자동 팝업 불가 |
| Solution | 연속 알람 스케줄링, 오디오 파일 보완, 디버그 라인 제거, Alarmy 수준 알람 신뢰성 확보 |
| Function / UX | 유저가 잠들어도 알람이 확실히 울리고, 무음 모드에서도 소리가 나며, 알람을 끄기 전까지 계속 울림 |
| Core Value | "알람 중심 설계" — 앱의 핵심 기능이 신뢰할 수 있어야 유저 리텐션 확보 |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| WHY | 알람이 신뢰받지 못하면 앱의 핵심 가치 훼손. Alarmy 수준 신뢰성 필요 |
| WHO | 기상 알람을 DailyVerse로 교체하려는 크리스천 유저 |
| RISK | 연속 알람 구현 시 UNUserNotificationCenter 64개 예약 한도 초과 가능 |
| SUCCESS | 앱 종료 상태에서도 5분간 알람이 반복 발동, 무음에서도 소리 |
| SCOPE | iOS 16+, 앱 소스만 수정 (서버 변경 없음) |

---

## 1. 현황 분석 (AS-IS)

### 1-1. 현재 구현 상태

| 기능 | 상태 | 비고 |
|------|------|------|
| 포그라운드 소리 | ✅ 완전 구현 | AVAudioSession .playback, 무음 우회 |
| 백그라운드 소리 | ✅ 완전 구현 | dvAlarmTriggered → Stage1 → AVAudioPlayer |
| **앱 종료 시 소리** | ⚠️ 부분 구현 | 시스템 알림음 1회만 (UNCalendarNotificationTrigger 1회) |
| 무음 모드 우회 | ✅ 완전 구현 | AVAudioSession .playback 카테고리 |
| 잠금화면 전면팝업 | ⚠️ 제한적 구현 | **배너 탭 후** Stage 1 표시 (자동 불가) |
| 스누즈 | ✅ 완전 구현 | 최대 N회, 간격 설정 가능 |
| 미션 (wake mission) | ✅ 완전 구현 | shake/math/typing/word/amen |
| 알람 반복 스케줄 | ✅ 완전 구현 | 요일별 UNCalendarNotificationTrigger |
| **alarm_nature 오디오** | ❌ 파일 누락 | 선택해도 beep 폴백 |
| **alarm_hymn 오디오** | ❌ 파일 누락 | 선택해도 beep 폴백 |
| **`onboardingCompleted = false`** | ❌ 디버그 잔존 | AppRootView.swift:120 — 즉시 제거 필요 |
| 연속 알람 | ❌ 미구현 | 코드 주석엔 있으나 실제 구현 없음 |
| 메시지 알람 타입 | ❌ 미구현 | 단일 타입만 존재 |

### 1-2. iOS 플랫폼 한계 (변경 불가)

| 한계 | 설명 | 대응 방안 |
|------|------|---------|
| 앱 완전 종료 시 자동 실행 불가 | iOS는 앱을 자동 실행할 수 없음 (AlarmKit iOS 26+ 예외) | 연속 UNNotification 10개 예약으로 보완 |
| 잠금화면 자동 전면팝업 불가 | 배너 탭 없이는 앱 진입 불가 | 배너 메시지를 말씀 전체로 충실히 |
| 볼륨 강제 설정 불가 | iOS API 제한 | 볼륨 경고 토스트 (기존) |

---

## 2. 요구사항

### P0 — 즉시 수정 (배포 블로커)

#### FR-P0-1: `onboardingCompleted = false` 디버그 라인 제거
- 파일: `AppRootView.swift:120`
- 현재: `onboardingCompleted = false` (매 실행마다 온보딩 강제)
- 수정: 해당 줄 삭제

### P1 — 핵심 기능 보완

#### FR-P1-1: 연속 알람 스케줄링 구현
- 알람 발동 시 30초 간격으로 최대 10개 추가 UNNotification 예약
- 각 보조 알림 ID: `{alarmId}_repeat_{index}` (index: 1~10)
- 각 보조 알림은 동일한 userInfo (alarm_id, verse_id, sound_id, alert_style)
- Stage 1 진입 시 보조 알림 전체 취소
- UNNotificationCenter 64개 한도 초과 방지: 알람당 기존(7일×3알람=21) + 보조(10) = 31개 → 안전

#### FR-P1-2: 잠금화면 배너 말씀 텍스트 품질 향상
- 현재 배너: `"두려워하지 말라..." / 이사야 41:10`
- 개선: `verseShortKo` 전체 + `reference` + Zone 인사말을 subtitle에 표시
- UNMutableNotificationContent의 title/subtitle/body 최대 활용

#### FR-P1-3: alarm_nature, alarm_hymn 오디오 파일 추가
- `alarm_nature.mp3`: 자연 환경음 스타일 (새소리 등)
- `alarm_hymn.mp3`: 찬송가 스타일 멜로디
- 번들 추가 시 Xcode 프로젝트에 자동 포함

### P2 — 알람 신뢰성 향상

#### FR-P2-1: 배터리 절약 백그라운드 유지 (선택적)
- `audio` 백그라운드 모드 활용: 무음 오디오 루프로 앱 백그라운드 유지
- 장점: 알람 발동 시 Stage 1 자동 표시 (배너 탭 불필요)
- 단점: 배터리 소모 증가 → 설정에서 ON/OFF 선택 가능하게
- 구현: `AVAudioPlayer`로 무음(volume=0) 오디오 루프, 알람 시간 내부 타이머로 관리

#### FR-P2-2: 볼륨 램핑 (점진적 볼륨 증가)
- 알람 시작 시 volume 0.3 → 1.0 (30초 동안 점진적 증가)
- Timer로 0.5초마다 volume += 0.025
- Alarmy 핵심 기능 중 하나

### P3 — UX 개선

#### FR-P3-1: 알람 타입 구분 (메시지 알람 vs 시간 알람)
- `Alarm.alarmType: String` 필드 추가: `"full"` | `"notification"`
- `"full"` (기본): 현재와 동일 (Stage 1 전체화면)
- `"notification"`: 잠금화면 배너만 (말씀 전체 텍스트, Stage 1 생략)
  - 새벽 시간대(deep_dark, first_light)의 조용한 말씀 알림
  - UX: 알람이 아닌 '말씀 알림'으로 동작

---

## 3. 구현 계획

### Phase 1 (즉시, ~30분)
```
1. AppRootView.swift:120 — onboardingCompleted = false 제거
2. LegacyAlarmEngine.makeContent() — 배너 title/subtitle/body 개선
```

### Phase 2 (핵심, ~2시간)
```
3. LegacyAlarmEngine.scheduleOnce() — 연속 알람 보조 예약 추가
4. LegacyAlarmEngine.schedule() — 보조 알람 cancel 로직 연계
5. AlarmCoordinator.handleNotification() — Stage 1 진입 시 보조 알람 취소
```

### Phase 3 (오디오, ~30분)
```
6. alarm_nature.mp3 / alarm_hymn.mp3 파일 추가
7. 프로젝트 번들 포함 확인
```

### Phase 4 (선택적, ~3시간)
```
8. 볼륨 램핑 구현 (LegacyAlarmEngine)
9. 백그라운드 유지 옵션 구현 (선택 시 배터리 경고 표시)
10. 알람 타입 구분 (Alarm 모델 + AlarmAddEditView + 스케줄링 분기)
```

---

## 4. 성공 기준

- [ ] P0: `onboardingCompleted = false` 제거 → 앱 정상 실행 (온보딩 1회)
- [ ] P1-1: 앱 종료 상태에서 알람 발동 후 5분간 30초 간격으로 반복 발동
- [ ] P1-2: 잠금화면 배너에 말씀 전체 텍스트 표시
- [ ] P1-3: alarm_nature, alarm_hymn 선택 시 실제 해당 소리 재생
- [ ] P2-1 (선택): 백그라운드 유지 시 잠금화면에서 배너 탭 없이 Stage 1 표시
- [ ] P2-2 (선택): 볼륨이 30초에 걸쳐 점진적으로 증가
- [ ] P3-1 (선택): 알람 추가 화면에서 "시간 알람" / "말씀 알림" 타입 선택 가능

---

## 5. 위험 요소

| 위험 | 대응 |
|------|------|
| UNNotification 64개 한도 초과 | 최대 10개 보조 예약, 알람 3개 기준 31개로 안전 |
| 백그라운드 오디오로 앱 거절 | 사용자 명시 동의 + 배터리 경고 + 설정 ON/OFF |
| alarm_nature/hymn 저작권 | CC0 또는 자체 생성 오디오만 사용 |
| 볼륨 램핑 중 스누즈 탭 | stopAudio 즉시 타이머 해제 |
