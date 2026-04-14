---
feature: App-BugFix
phase: plan
created: 2026-04-11
status: active
---

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | App-BugFix (5개 버그 수정) |
| 날짜 | 2026-04-11 |

### Value Delivered (4-Perspective)

| 관점 | 내용 |
|------|------|
| Problem | 계정 탈퇴 UX 혼란, 알람 누적, 삭제 후 복구, 하단 버튼 가림, 묵상 이미지 미저장 |
| Solution | 탈퇴 리텐션 팝업, 중복 알람 방지, 즉시 DB 삭제, 안전 영역 패딩 보정, 이미지 랜덤 저장 |
| Function UX Effect | 혼란 없는 탈퇴 플로우, 알람 정합성 유지, 묵상 기록에 감성 이미지 추가 |
| Core Value | 앱 신뢰성 향상, 크리스천 영적 루틴 경험 완성도 상승 |

## Context Anchor

| 축 | 내용 |
|----|------|
| WHY | 테스트 중 발견된 5개 버그가 핵심 UX 흐름을 방해함 |
| WHO | 앱을 테스트하는 개발자 / 실제 사용자 |
| RISK | 알람 중복은 UNNotificationCenter 과부하, 탈퇴 플로우 오해는 리뷰 문제 |
| SUCCESS | 5개 이슈 모두 재현 불가 상태 달성 |
| SCOPE | SettingsView, AlarmViewModel, OnboardingViewModel, MeditationEntry, DevotionHomeView, AlarmListView |

---

## 1. 버그 목록 및 원인 분석

### Bug 1: 계정 탈퇴 시 구글 로그인 팝업 + 리텐션 메세지 부재

**현상**: 설정 > 계정 탈퇴 탭 → 기존 Alert 확인 후 Google 로그인 팝업이 바로 뜸. 탈퇴를 붙잡는 감성 메세지가 없음.

**원인**:
- `SettingsView.swift:52` — `showDeleteAccountAlert` Alert의 "탈퇴하기" 버튼이 곧바로 `deleteAccount()` 호출
- `AuthManager.deleteAccount()` 내부에서 Google 계정인 경우 `reauthenticateWithGoogle()` 실행 → Google Sign-In 팝업
- 리텐션 메세지 없이 바로 삭제 프로세스 진입

**요구 파일**:
- `DailyVerse/Features/Settings/SettingsView.swift`

**수정 방향**:
1. 기존 Alert를 2단계로 분리
   - 1단계: 리텐션 메세지 + "그래도 탈퇴할게요" / "취소" (감성적 붙잡기)
   - 2단계: 기존 "구독 해지 필요" 경고 + "탈퇴하기" / "취소" (최종 확인)
2. "그래도 탈퇴할게요" 탭 → 2단계 Alert 표시
3. 2단계 "탈퇴하기" 탭 → `deleteAccount()` 실행 (Google 재인증 포함 기존 플로우)

---

### Bug 2: 온보딩 완료 시마다 알람 중복 생성

**현상**: 같은 디바이스에서 온보딩을 여러 번 완료하면 오전 6시 알람이 누적됨.

**원인**:
- `OnboardingViewModel.saveFirstAlarms()` — 매번 새 UUID로 알람 생성, 기존 알람 중복 체크 없음
- `AppRootView.swift:112-113` (TEMPORARY 코드) — `onboardingCompleted = false`로 매 실행마다 온보딩 강제 표시
- `AlarmRepository.save()` — 중복 알람 방지 로직 없음

**요구 파일**:
- `DailyVerse/Features/Onboarding/OnboardingViewModel.swift`
- `DailyVerse/App/AppRootView.swift`

**수정 방향**:
1. `saveFirstAlarms()` 실행 전 `alarmRepository.fetchAll()` 호출
2. 이미 알람이 존재하면 `saveFirstAlarms()` 스킵 (중복 방지)
3. `AppRootView.swift` TEMPORARY 코드 제거 (온보딩 테스트 목적 코드 정리)

```swift
// OnboardingViewModel.saveFirstAlarms() 수정
private func saveFirstAlarms() {
    // 이미 알람이 있으면 중복 생성 방지
    let existing = alarmRepository.fetchAll()
    guard existing.isEmpty else { return }

    // ... 기존 알람 생성 코드
}
```

---

### Bug 3: 알람 삭제 후 다른 탭 이동 시 알람이 다시 나타남

**현상**: 알람 삭제(스와이프) → 다른 탭 이동 → 알람 탭 복귀 시 삭제한 알람이 다시 표시됨.

**원인**:
- `AlarmViewModel.deleteAlarm()`:
  1. UI에서 즉시 제거 (`alarms.removeAll { $0.id == id }`)
  2. Core Data 삭제는 3초 후에 실행 (`undoTask`)
  3. `.onAppear`에서 `viewModel.loadAlarms()` 호출 → Core Data 재로드 → 아직 삭제 안 된 알람이 다시 표시
- `AlarmListView.onAppear`: 매번 `viewModel.loadAlarms()` 호출

**요구 파일**:
- `DailyVerse/Features/Alarm/AlarmViewModel.swift`

**수정 방향**:
1. `deleteAlarm()` 에서 Core Data 삭제를 즉시 실행 (UI 제거와 동시에)
2. 되돌리기(undo) 발동 시 Core Data에 다시 저장
3. 3초 타이머는 토스트 메세지 자동 숨김 용도로만 유지

```swift
func deleteAlarm(id: UUID) {
    guard let alarm = alarms.first(where: { $0.id == id }) else { return }

    notificationManager.cancel(alarmId: id)
    alarms.removeAll { $0.id == id }
    try? alarmRepository.delete(id: id)  // ← 즉시 Core Data 삭제
    pendingDeleteAlarm = alarm
    toastMessage = "알람이 삭제되었습니다."

    // 3초 후 토스트만 숨김
    undoTask?.cancel()
    undoTask = Task { @MainActor [weak self] in
        do { try await Task.sleep(for: .seconds(3)) } catch { return }
        self?.pendingDeleteAlarm = nil
        self?.toastMessage = nil
    }
}

func undoDelete() {
    guard let alarm = pendingDeleteAlarm else { return }
    undoTask?.cancel()
    undoTask = nil
    pendingDeleteAlarm = nil
    try? alarmRepository.save(alarm)  // ← Core Data에 재저장
    notificationManager.schedule(alarm, verse: ...)
    loadAlarms()
    toastMessage = nil
}
```

---

### Bug 4: 알람 탭 / 묵상 탭 하단 노란색 버튼이 탭바에 가려짐

**현상**: 알람 탭의 "새 알람 추가" 골드 버튼, 묵상 탭의 "오늘도 묵상 진행해볼까?" 골드 버튼이 DVTabBar에 가려져 일부 또는 전체가 보이지 않음.

**원인**:
- `MainTabView`: DVTabBar를 `.safeAreaInset(edge: .bottom, spacing: 0)`로 추가
- SwiftUI의 `TabView`가 부모의 `safeAreaInset`을 자식 뷰에 항상 정확히 전달하지 않는 경우 발생
- `AlarmListView`: `addAlarmButton`은 `.safeAreaInset(edge: .bottom)` 사용 → 일부 기기/OS에서 DVTabBar와 겹침
- `DevotionHomeView`: CTA 버튼이 ScrollView 내 `.padding(.bottom, 40)` 에 의존 → DVTabBar 높이(~88pt) 부족

**요구 파일**:
- `DailyVerse/Features/Alarm/AlarmListView.swift`
- `DailyVerse/Features/Meditation/DevotionHomeView.swift`

**수정 방향**:
1. AlarmListView의 `addAlarmButton` 하단 패딩 보강:
   - `.padding(.bottom, 16)` → `.padding(.bottom, 24)` 또는 safe area 기반 계산 추가
   - 혹은 `safeAreaInset`을 제거하고 ScrollView/List 하단에 spacer 추가
2. DevotionHomeView ScrollView 하단 패딩 증가:
   - `.padding(.bottom, 40)` → `.padding(.bottom, 100)` (DVTabBar + home indicator 여유분)

---

### Bug 5: 묵상 저장 시 이미지 미저장

**현상**: 묵상을 저장해도 이미지가 기록되지 않음. 묵상 상세 화면에서 감성 이미지가 없어 배경이 그라데이션만 표시됨.

**원인**:
- `MeditationEntry` 모델에 `imageUrl: String?` 필드 없음
- `MeditationViewModel`의 저장 함수들(saveQuick, saveRead, saveEntry, saveGuided)에서 이미지 선택/저장 로직 없음
- `MeditationEntryDetailView`에서 이미지 표시 로직 없음

**요구 파일**:
- `DailyVerse/Core/Models/MeditationEntry.swift`
- `DailyVerse/Features/Meditation/MeditationViewModel.swift`
- `DailyVerse/Features/Meditation/MeditationEntryDetailView.swift`

**수정 방향**:
1. `MeditationEntry` 모델에 `imageUrl: String?` 필드 추가 (CodingKey: `image_url`)
2. `MeditationViewModel`에 `randomImageUrl()` 헬퍼 추가:
   - Core Data 캐시에서 이미지 URL 풀 로드
   - 현재 모드/날씨에 맞는 이미지 랜덤 선택
   - 없으면 nil
3. 모든 저장 함수(saveQuick, saveRead, saveEntry, saveGuided)에서 `entry.imageUrl = randomImageUrl()` 설정
4. `MeditationEntryDetailView`에서 `imageUrl`이 있으면 AsyncImage로 표시, 없으면 기존 그라데이션

---

## 2. 수정 파일 목록

| 파일 | 변경 유형 | 관련 Bug |
|------|----------|---------|
| `Features/Settings/SettingsView.swift` | 수정 | Bug 1 |
| `Features/Onboarding/OnboardingViewModel.swift` | 수정 | Bug 2 |
| `App/AppRootView.swift` | 수정 (TEMPORARY 코드 제거) | Bug 2 |
| `Features/Alarm/AlarmViewModel.swift` | 수정 | Bug 3 |
| `Features/Alarm/AlarmListView.swift` | 수정 | Bug 4 |
| `Features/Meditation/DevotionHomeView.swift` | 수정 | Bug 4 |
| `Core/Models/MeditationEntry.swift` | 수정 | Bug 5 |
| `Features/Meditation/MeditationViewModel.swift` | 수정 | Bug 5 |
| `Features/Meditation/MeditationEntryDetailView.swift` | 수정 | Bug 5 |

---

## 3. 구현 순서

1. **Bug 3** (알람 삭제 복구) → 가장 간단, 로직 변경만
2. **Bug 2** (온보딩 알람 누적) → TEMPORARY 코드 제거 포함
3. **Bug 4** (하단 버튼 가림) → 패딩 보정
4. **Bug 1** (탈퇴 UX) → Alert 2단계 분리
5. **Bug 5** (묵상 이미지) → 모델 + ViewModel + View 연쇄 변경

---

## 4. 성공 기준

- [ ] Bug 1: 탈퇴 탭 → 리텐션 팝업 → "그래도 탈퇴" → 최종 확인 → 탈퇴 진행 (3단계 플로우)
- [ ] Bug 2: 온보딩 재실행 시 기존 알람 있으면 신규 알람 미생성
- [ ] Bug 3: 알람 삭제 → 다른 탭 이동 → 돌아와도 삭제된 상태 유지 / 되돌리기 정상 작동
- [ ] Bug 4: 알람 탭 "새 알람 추가" 버튼 전체 노출 / 묵상 탭 CTA 버튼 전체 노출
- [ ] Bug 5: 묵상 저장 시 이미지 URL 저장, 상세 화면에서 이미지 표시
