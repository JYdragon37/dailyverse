# [Plan] auth-nickname-meditation-ux

> Feature: Auth 플로우 개선 + 닉네임 시스템 + 묵상 탭 UX + 콘텐츠 생성
> Created: 2026-04-10
> Status: Plan

---

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 비회원 둘러보기 후 앱 재실행 시 Auth 화면이 안 뜨고, 닉네임이 묵상/인사말에 반영 안 되며, 묵상 응답 화면의 레이아웃과 저장 로직에 UX 문제가 있음 |
| **Solution** | Auth 플로우를 세션 기반으로 변경하고, 최초 로그인 시 Toss 스타일 닉네임 입력을 추가하며, 묵상 화면 레이아웃을 한 화면에 맞게 최적화 |
| **Function UX Effect** | 비회원 재방문 시 자연스러운 가입 유도 + 개인화된 인사말(닉네임) + 묵상 응답이 스크롤 없이 한 화면에 완성 |
| **Core Value** | 영적 루틴이 개인화되고 마찰 없이 진행된다. 닉네임이 묵상 질문에도 포함되어 "나를 위한 말씀" 경험 강화 |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| **WHY** | 비회원 세션 관리 버그 + 닉네임 미반영 + 묵상 UX 개선으로 리텐션 향상 |
| **WHO** | 앱을 처음 시작하거나 비회원으로 둘러보다가 재방문하는 크리스천 유저 |
| **RISK** | AuthWelcomeShown 제거 시 기존 유저가 Auth 화면을 다시 볼 수 있음 (로그인 상태면 스킵) |
| **SUCCESS** | 비회원 재방문 → Auth 화면 표시 / 로그인 유저 → Auth 스킵 / 닉네임이 인사말·묵상에 반영 |
| **SCOPE** | AppRootView, AuthWelcomeView, NicknameSetupView(신규), DevotionHomeView, DevotionVerseView, DevotionResponseView, SettingsView, NicknameManager, 콘텐츠 생성 |

---

## 1. Auth 플로우 (Group A)

### 현재 문제
- `authWelcomeShown` AppStorage가 `true`로 저장되면 비회원 재방문 시 홈 바로 진입
- 요구사항: 비회원(Guest)은 앱 재시작 시 항상 Auth 화면 표시

### 변경 방향
```
현재: authManager.isLoggedIn이 false && authWelcomeShown이 false → Auth 표시
수정: authManager.isLoggedIn이 false → 항상 Auth 표시 (authWelcomeShown 제거)
      단, 현재 세션 내 Guest 진입은 @State guestModeActive로 관리
```

### 변경 파일
- `AppRootView.swift`: `authWelcomeShown` AppStorage 제거 → `@State guestModeActive`로 교체
- `AuthWelcomeView.swift`: onSkip 콜백이 guestModeActive를 true로 설정

---

## 2. 닉네임 시스템 (Group B)

### 최초 로그인 닉네임 입력 (Toss 스타일)
- 로그인 성공 → `nicknameManager.isSet == false` → `NicknameSetupView` 표시
- 화면 구성:
  - 큰 제목: "어떻게 불러드릴까요?"
  - 서브: "매일 말씀 묵상, 함께 시작해요 🙏"
  - TextField: 즉시 포커스, placeholder "닉네임"
  - 실시간 검증: 한글 5자 이내 / 영어·숫자 8자 이내
  - CTA: "시작하기" (입력 시 활성)
  - 스킵: "나중에" (기본값 "친구" 유지)

### 닉네임 제한 로직
```swift
// 한글 5자 / 영어 8자 스마트 제한
func isValid(_ text: String) -> Bool {
    let koreanCount = text.filter { $0.unicodeScalars.allSatisfy {
        $0.value >= 0xAC00 && $0.value <= 0xD7A3
    }}.count
    let hasKorean = koreanCount > 0
    return hasKorean ? text.count <= 5 : text.count <= 8
}
```

### 닉네임 반영 위치
- `DevotionHomeView` 인사말: `authManager.user?.displayName ?? "JY"` → `NicknameManager.shared.nickname`
- `DevotionResponseView` 묵상 질문: `"{NicknameManager.shared.nickname}님, {question}"` 앱에서 동적 합성
- `SettingsView` 닉네임 변경: 동일 한글5/영어8 제한 적용

---

## 3. 묵상 탭 UX (Group C + D)

### C1: 섹션 헤더 텍스트 변경
- DevotionVerseView L23: `"📖 오늘의 말씀"` → `"📖 오늘의 묵상"`

### C2-C3: 레이아웃 개선
- CTA "오늘의 묵상 완료하기" 홈바 겹침 → safeAreaInset 패딩 조정
- 좌우 padding: 20pt 통일 (현재 일부 불균형)

### C4: 3섹션 한 화면 표시 (스크롤 없이)
```
iPhone 15 Pro 화면 높이: 852pt
- 네비게이션바: ~60pt
- 섹션1(읽기): ~180pt
- 구분선: 20pt
- 섹션2(질문): ~100pt
- 구분선: 20pt
- 섹션3(기도): ~80pt
- CTA: ~72pt (safeArea 포함)
총 필요: ~532pt → 여유 있음
→ ScrollView → VStack으로 변경, 고정 높이
```

### C5: 뒤로가기 버튼 위치
- `navigationBarTitleDisplayMode(.inline)` 사용 중 → 자동으로 safe area 아래 배치
- `.toolbarBackground(.visible, for: .navigationBar)` 추가로 확실히 처리

### D1-D2: 읽기 저장 로직 개선
```
현재: isReadingCompleted && !prayer.isEmpty → CTA 활성
수정: isReadingCompleted → CTA 활성 (prayer 선택)
     handleComplete() → prayer가 비어있어도 saveGuided() 호출
```

---

## 4. 콘텐츠 생성 (Group E)

### devotion_question 필드
- Firestore verses/{id}에 `devotion_question: String` 추가
- 형식: "{name}님" 없이 저장, 앱에서 닉네임 앞붙임으로 개인화
- 예시: "오늘 바라보고 있는 '산'은 무엇인가요? 문제보다 더 큰 하나님을 바라볼 수 있나요?"
- 길이: 40-80자 (1-2문장)
- 톤: 따뜻하고 개인적인 질문 (대답하기 쉬운)

### 기존 contemplation_ko와 차이
| 필드 | contemplation_ko | devotion_question |
|------|-----------------|-------------------|
| 용도 | 묵상 읽기 대상 구절 (핵심 요약) | 마음 속 묵상 질문 |
| 길이 | 20-50자 | 40-80자 |
| 형태 | 말씀 요약 | 질문형 문장 |

---

## 5. Settings 정리 (Group F)

### 현재 코드 검증
```swift
if authManager.isLoggedIn {
    // 이메일 + 로그아웃 + 계정탈퇴
} else {
    // "Apple로 시작하기" 버튼
}
```
→ 이미 올바른 구조. 로그인 중 Apple 버튼 미표시. 사용자가 비로그인 상태에서 테스트한 것으로 판단.

---

## 6. 구현 파일 목록

### 수정 파일 (6개)
| 파일 | 변경 내용 |
|------|----------|
| `AppRootView.swift` | authWelcomeShown 제거, guestModeActive @State |
| `DevotionHomeView.swift` | NicknameManager.shared.nickname 사용 |
| `DevotionVerseView.swift` | "오늘의 말씀" → "오늘의 묵상" |
| `DevotionResponseView.swift` | 레이아웃, padding, CTA 조건, 닉네임 질문 |
| `SettingsView.swift` | 닉네임 한글5/영어8 제한 |
| `NicknameManager.swift` | 한글5/영어8 스마트 제한 |

### 신규 파일 (1개)
| 파일 | 내용 |
|------|------|
| `NicknameSetupView.swift` | Toss 스타일 닉네임 입력 화면 |

### 콘텐츠 스크립트 (1개)
| 파일 | 내용 |
|------|------|
| `generate_devotion_questions.js` | 101개 말씀 묵상 질문 생성 |

---

## 7. 성공 기준

| # | 기준 |
|---|------|
| SC-1 | 비로그인 비회원이 앱 재시작 시 Auth 화면 표시 |
| SC-2 | 로그인 유저는 Auth 화면 없이 홈 직행 |
| SC-3 | 최초 로그인 시 닉네임 입력 화면 표시 |
| SC-4 | 닉네임이 DevotionHomeView 인사말에 반영 |
| SC-5 | 묵상 응답 3섹션이 스크롤 없이 한 화면에 표시 |
| SC-6 | 읽기 텍스트 입력만으로 CTA 활성화 |
| SC-7 | devotion_question 101개 생성 완료 |
