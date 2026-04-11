# Design: onboarding-redesign

> 생성일: 2026-04-11
> 아키텍처: Option C — Pragmatic Balance (ZStack + 단일 ViewModel)
> 참조 Plan: docs/01-plan/features/onboarding-redesign.plan.md

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| **WHY** | 메인 앱과 다른 비주얼 톤 + 가치 증명 없이 정보 수집 → 이탈 유발 |
| **WHO** | 한국 크리스천 청년/성인, 알람+말씀 습관을 원하지만 확신이 없는 유저 |
| **RISK** | Screen 2 로딩 지연 / UserDefaults 호환성 / 테마→알고리즘 연결 |
| **SUCCESS** | 완료율 85%+ / 알람 설정 70%+ / 알림 수락 60%+ / 60초 이내 |
| **SCOPE** | 리빌드: 6파일 신규 + 2파일 수정 (OnboardingContainerView, ViewModel) |

---

## 1. 아키텍처 개요

### 1.1 선택된 아키텍처: Option C — Pragmatic Balance

```
OnboardingContainerView (ZStack 기반 컨테이너)
  ├── @StateObject var vm = OnboardingViewModel()
  ├── ZStack {
  │     ONBIntroView(vm: vm)            // Page 0
  │     ONBExperienceView(vm: vm)       // Page 1
  │     ONBPersonalizeView(vm: vm)      // Page 2
  │     ONBAlarmPermissionView(vm: vm)  // Page 3
  │   }
  │   .offset(x: pageOffset)           // 전환 애니메이션
  └── 하단 skip/progress 오버레이
```

### 1.2 전환 애니메이션 방식

**Slide + Fade 조합 (Calm 스타일)**:
```swift
// 전환: 새 화면이 오른쪽에서 슬라이드 인 + 동시에 opacity fade-in
// 이전 화면: 왼쪽으로 슬라이드 아웃 + fade-out

withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
    currentPage += 1
}
// 각 화면: opacity(currentPage == myPage ? 1 : 0)
//          offset(x: (currentPage - myPage) * UIScreen.main.bounds.width)
```

---

## 2. 파일 구조

```
DailyVerse/Features/Onboarding/
├── OnboardingContainerView.swift    ← 리빌드 (ZStack + 전환)
├── OnboardingViewModel.swift        ← 리빌드 (테마/알람 상태 추가)
├── Screens/
│   ├── ONBIntroView.swift           ← 신규
│   ├── ONBExperienceView.swift      ← 신규
│   ├── ONBPersonalizeView.swift     ← 신규
│   └── ONBAlarmPermissionView.swift ← 신규
└── Components/
    ├── ONBThemeChip.swift           ← 신규
    └── ONBAlarmTimeRow.swift        ← 신규

삭제 (대체됨):
- OnboardingWelcomeView.swift       → ONBIntroView로 대체
- OnboardingNicknameView.swift      → ONBPersonalizeView에 통합
- OnboardingFirstVerseView.swift    → ONBExperienceView로 대체
- OnboardingLocationView.swift      → 홈탭으로 이동
- OnboardingNotificationView.swift  → ONBAlarmPermissionView에 통합
- OnboardingFirstAlarmView.swift    → ONBAlarmPermissionView로 통합

수정:
- HomeViewModel.swift               ← 위치권한 요청 로직 추가
```

---

## 3. OnboardingViewModel 상세 설계

```swift
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - 네비게이션
    @Published var currentPage: Int = 0
    static let totalPages = 4  // 기존 6 → 4

    // MARK: - 기존 UserDefaults 키 (호환성 유지)
    @AppStorage(OnboardingKey.completed.rawValue) var onboardingCompleted = false
    @AppStorage(OnboardingKey.nicknameSet.rawValue) var nicknameSet = false
    @AppStorage(OnboardingKey.notificationRequested.rawValue) var notificationPermissionRequested = false
    @AppStorage(OnboardingKey.firstAlarmShown.rawValue) var firstAlarmPromptShown = false
    // OnboardingKey.locationRequested는 HomeViewModel에서 관리

    // MARK: - 신규 State
    @Published var nicknameInput: String = ""
    @Published var selectedThemes: [String] = []  // 테마 다중 선택 (최대 3개)

    @Published var morningAlarmEnabled: Bool = true
    @Published var eveningAlarmEnabled: Bool = false
    @Published var morningAlarmTime: Date = Calendar.current
        .date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var eveningAlarmTime: Date = Calendar.current
        .date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()

    // MARK: - 네비게이션
    func next() {
        guard currentPage < Self.totalPages - 1 else { complete(); return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage += 1
        }
    }

    func skip() {
        next()  // v2.0: 단순 skip (스킵 카운트 제거 — 4단계면 충분)
    }

    func complete() {
        saveNickname()
        saveSelectedThemes()
        saveAlarms()
        onboardingCompleted = true
    }

    // MARK: - 저장
    func saveNickname() { ... }
    func saveSelectedThemes() {
        // UserDefaults에 JSON 저장
        let data = try? JSONEncoder().encode(selectedThemes)
        UserDefaults.standard.set(data, forKey: "preferredThemes")
        // 로그인 유저면 Firestore에도 저장
    }
    func saveAlarms() {
        // AlarmRepository에 아침/저녁 알람 저장
        // NotificationManager.schedule(alarm, verse:) 호출
    }
    func toggleTheme(_ theme: String) {
        if selectedThemes.contains(theme) {
            selectedThemes.removeAll { $0 == theme }
        } else if selectedThemes.count < 3 {
            selectedThemes.append(theme)
        }
    }
}
```

---

## 4. 화면별 상세 설계

### 4.1 ONBIntroView (Screen 1 — 감성 인트로)

**목적**: 브랜드 각인 + 감정적 공감

**레이아웃**:
```
ZStack {
  // 배경: dvBgDeep + 미세 파티클 (Canvas 기반)
  Color.dvBgDeep.ignoresSafeArea()
  ParticleView()  // 별빛 파티클 10~15개, opacity 0.3~0.6

  VStack(spacing: 0) {
    Spacer()

    // 로고 영역 (fade-in 0.8s)
    VStack(spacing: 16) {
      Image("app_logo_white")  // 브랜드 로고 (기존 book.fill 아이콘 대체)
        .font(.system(size: 64))
        .opacity(logoOpacity)  // 0 → 1, 0.8s ease-in

      Text("DailyVerse")
        .font(.system(size: 36, weight: .bold))
        .foregroundColor(.white)

      Text("하루의 끝과 시작을 경건하게")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.white.opacity(0.75))
    }

    Spacer().frame(height: 32)

    // 서브카피 (fade-in 1.4s, 딜레이 0.6s)
    VStack(spacing: 8) {
      Text("알람이 울릴 때,")
        .font(.system(size: 22, weight: .light))
        .foregroundColor(.dvAccentGold)
      Text("말씀이 함께 울립니다")
        .font(.system(size: 22, weight: .light))
        .foregroundColor(.dvAccentGold)
    }
    .opacity(subCopyOpacity)

    Spacer()

    // CTA 버튼
    Button("시작하기") { vm.next() }
      .font(.system(size: 18, weight: .semibold))
      .foregroundColor(.black)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(Color.dvAccentGold)
      .cornerRadius(16)
      .padding(.horizontal, 32)
      .padding(.bottom, 60)
      .opacity(ctaOpacity)
  }
}
.onAppear { runEntryAnimations() }
```

**애니메이션 시퀀스**:
```swift
func runEntryAnimations() {
    // 1. 로고 fade-in
    withAnimation(.easeIn(duration: 0.8)) { logoOpacity = 1 }
    // 2. 서브카피 fade-in (0.6s 딜레이)
    withAnimation(.easeIn(duration: 0.6).delay(0.6)) { subCopyOpacity = 1 }
    // 3. CTA 버튼 fade-in (1.2s 딜레이)
    withAnimation(.easeIn(duration: 0.4).delay(1.2)) { ctaOpacity = 1 }
}
```

**ParticleView**: `Canvas` API 활용, 15개 원형 파티클, 각기 다른 크기(2~6pt)와 opacity(0.2~0.5), 천천히 부유하는 애니메이션 (3~6초 주기, `repeatForever`).

---

### 4.2 ONBExperienceView (Screen 2 — Value-First 체험)

**목적**: 실제 서비스를 설명 없이 체험시키기

**레이아웃**:
```
ZStack {
  // 배경: 현재 Zone 배경이미지 (AppLoadingCoordinator.zoneBgImage 또는 fallback gradient)
  backgroundLayer.ignoresSafeArea()

  // 다크 오버레이
  LinearGradient(0.3→0.6).ignoresSafeArea()

  VStack(spacing: 0) {
    Spacer()

    // 시간대 인사 (데모 - 실제 앱과 동일한 스타일)
    HStack {
      Image(systemName: AppMode.current().greetingIcon)
        .font(.system(size: 22))
      Text("\(AppMode.current().greeting), 친구")
        .font(.dvLargeTitle)
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 28)

    Spacer().frame(height: 32)

    // 말씀 카드 (인터랙티브 - 실제 앱과 동일 스타일)
    VStack(alignment: .leading, spacing: 12) {
      Text(demoVerse.verseFullKo)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.white)
        .lineSpacing(6)
        .shadow(color: .black.opacity(0.8), radius: 6)

      Text(demoVerse.reference)
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(.dvAccentGold)
    }
    .padding(24)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.dvAccentGold.opacity(0.3), lineWidth: 1))
    )
    .padding(.horizontal, 28)

    Spacer().frame(height: 28)

    // 설명 문구
    VStack(spacing: 6) {
      Text("✨ 매일 아침, 이 말씀이 알람과 함께 도착해요")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white.opacity(0.85))
        .multilineTextAlignment(.center)
      Text("알람은 이미 쓰고 있어요\n거기에 말씀만 얹는 거예요")
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.55))
        .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 32)

    Spacer()

    // CTA
    Button("이런 말씀을 받고 싶어요 →") { vm.next() }
      // dvAccentGold 버튼, height 56
      .padding(.bottom, 60)
  }
}
```

**demoVerse**: `Verse.fallbackRiseIgnite` (항상 사용 가능, 로딩 불필요)

---

### 4.3 ONBPersonalizeView (Screen 3 — 테마 + 닉네임)

**목적**: Headspace 2-Question 패턴 — 테마 선택 + 닉네임

**레이아웃**:
```
ZStack {
  Color.dvBgDeep.ignoresSafeArea()

  ScrollView {
    VStack(alignment: .leading, spacing: 0) {
      Spacer().frame(height: 60)

      // 질문 헤더
      VStack(alignment: .leading, spacing: 8) {
        Text("지금 당신에게 필요한 건")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.white)
        Text("어떤 말씀인가요?")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.dvAccentGold)
        Text("최대 3개까지 선택할 수 있어요")
          .font(.dvCaption)
          .foregroundColor(.white.opacity(0.5))
          .padding(.top, 4)
      }
      .padding(.horizontal, 28)

      Spacer().frame(height: 32)

      // 테마 그리드 (2×4, 8개)
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ForEach(themes, id: \.key) { theme in
          ONBThemeChip(
            emoji: theme.emoji,
            label: theme.label,
            isSelected: vm.selectedThemes.contains(theme.key),
            onTap: { vm.toggleTheme(theme.key) }
          )
        }
      }
      .padding(.horizontal, 24)

      Spacer().frame(height: 40)

      // 닉네임 구분선
      HStack {
        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
        Text("그리고").font(.dvCaption).foregroundColor(.white.opacity(0.4))
        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
      }
      .padding(.horizontal, 28)

      Spacer().frame(height: 28)

      // 닉네임
      VStack(alignment: .leading, spacing: 8) {
        Text("우리가 어떻게 불러드릴까요?")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.white)
        TextField("친구", text: $vm.nicknameInput)
          .font(.system(size: 18))
          .foregroundColor(.white)
          .padding(16)
          .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dvAccentGold.opacity(0.3), lineWidth: 1))
      }
      .padding(.horizontal, 28)

      Spacer().frame(height: 40)

      // CTA
      Button(vm.selectedThemes.isEmpty ? "건너뛰기" : "선택 완료 →") { vm.next() }
        .padding(.horizontal, 28)
        .padding(.bottom, 60)
    }
  }
}
```

**테마 목록 (8개)**:
```swift
let themes: [(key: String, emoji: String, label: String)] = [
    ("courage",      "🌟", "용기"),
    ("peace",        "🕊️", "평안"),
    ("wisdom",       "💡", "지혜"),
    ("gratitude",    "🙏", "감사"),
    ("strength",     "💪", "힘"),
    ("renewal",      "✨", "회복"),
    ("comfort",      "🤍", "위로"),
    ("hope",         "🌱", "소망"),
]
```

---

### 4.4 ONBAlarmPermissionView (Screen 4 — 알람 + Permission Priming)

**목적**: 핵심 리텐션 행동(알람 설정) 완료 + 65%+ 알림 수락

**레이아웃**:
```
ZStack {
  Color.dvBgDeep.ignoresSafeArea()

  VStack(spacing: 0) {
    Spacer().frame(height: 60)

    // 헤더
    VStack(alignment: .leading, spacing: 8) {
      Text("언제 말씀을 받고 싶으신가요?")
        .font(.system(size: 26, weight: .bold))
        .foregroundColor(.white)
      Text("알람이 울릴 때 함께 도착해요")
        .font(.dvBody)
        .foregroundColor(.white.opacity(0.6))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 28)

    Spacer().frame(height: 32)

    // 알람 카드 2개
    VStack(spacing: 12) {
      ONBAlarmTimeRow(
        icon: "☀️",
        label: "아침",
        isEnabled: $vm.morningAlarmEnabled,
        time: $vm.morningAlarmTime
      )
      ONBAlarmTimeRow(
        icon: "🌙",
        label: "저녁",
        isEnabled: $vm.eveningAlarmEnabled,
        time: $vm.eveningAlarmTime
      )
    }
    .padding(.horizontal, 24)

    Spacer().frame(height: 40)

    // Permission Priming 섹션 (알람 설정 후 표시)
    if vm.morningAlarmEnabled || vm.eveningAlarmEnabled {
      VStack(spacing: 16) {
        // 알림 배너 목업
        HStack(spacing: 12) {
          Image(systemName: "bell.fill")
            .foregroundColor(.dvAccentGold)
            .padding(10)
            .background(Circle().fill(Color.dvAccentGold.opacity(0.15)))
          VStack(alignment: .leading, spacing: 2) {
            Text("DailyVerse 🔔")
              .font(.system(size: 13, weight: .semibold))
              .foregroundColor(.white)
            Text("\"두려워하지 말라 내가 너와 함께...\"")
              .font(.system(size: 12))
              .foregroundColor(.white.opacity(0.6))
          }
          Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
        .padding(.horizontal, 24)

        Text("알람과 동시에 오늘의 말씀이 잠금화면에 나타나요")
          .font(.system(size: 14))
          .foregroundColor(.white.opacity(0.6))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)

        // 알림 허용 버튼
        Button("알림 허용하기") {
          Task {
            vm.notificationPermissionRequested = true
            _ = await NotificationManager.shared.requestPermission()
            vm.completeOnboarding()
          }
        }
        // gold 배경 버튼
        .padding(.horizontal, 24)

        Button("나중에") { vm.completeOnboarding() }
          .font(.dvCaption)
          .foregroundColor(.white.opacity(0.4))
      }
      .transition(.move(edge: .bottom).combined(with: .opacity))
      .animation(.spring(response: 0.4), value: vm.morningAlarmEnabled || vm.eveningAlarmEnabled)
    } else {
      // 알람 미설정 시 스킵 버튼
      Button("건너뛰기") { vm.completeOnboarding() }
        .foregroundColor(.white.opacity(0.4))
    }

    Spacer()
  }
}
```

---

### 4.5 ONBThemeChip (컴포넌트)

```swift
struct ONBThemeChip: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(emoji).font(.system(size: 22))
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.dvAccentGold : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .animation(.spring(response: 0.3), value: isSelected)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}
```

---

### 4.6 ONBAlarmTimeRow (컴포넌트)

```swift
struct ONBAlarmTimeRow: View {
    let icon: String
    let label: String
    @Binding var isEnabled: Bool
    @Binding var time: Date

    var body: some View {
        HStack(spacing: 16) {
            Text(icon).font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(label) 알람")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.4))
                if isEnabled {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .tint(.dvAccentGold)
                }
            }
            Spacer()
            Toggle("", isOn: $isEnabled)
                .tint(.dvAccentGold)
                .labelsHidden()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isEnabled ? 0.08 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEnabled ? Color.dvAccentGold.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3), value: isEnabled)
    }
}
```

---

## 5. OnboardingContainerView 상세 설계

```swift
struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()

    // 화면 전환 offset 계산
    private func offsetX(for page: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return CGFloat(page - vm.currentPage) * screenWidth
    }

    var body: some View {
        ZStack {
            // 각 화면을 ZStack에 쌓고 offset으로 배치
            ONBIntroView(vm: vm)
                .offset(x: offsetX(for: 0))
                .opacity(abs(vm.currentPage - 0) <= 1 ? 1 : 0)

            ONBExperienceView(vm: vm)
                .offset(x: offsetX(for: 1))
                .opacity(abs(vm.currentPage - 1) <= 1 ? 1 : 0)

            ONBPersonalizeView(vm: vm)
                .offset(x: offsetX(for: 2))
                .opacity(abs(vm.currentPage - 2) <= 1 ? 1 : 0)

            ONBAlarmPermissionView(vm: vm)
                .offset(x: offsetX(for: 3))
                .opacity(abs(vm.currentPage - 3) <= 1 ? 1 : 0)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: vm.currentPage)
        .ignoresSafeArea()
        .gesture(
            // 스와이프 비활성화 (실수 방지)
            DragGesture().onEnded { _ in }
        )
    }
}
```

---

## 6. 위치권한 → HomeViewModel 이동

```swift
// HomeViewModel.loadData() 내에 추가
private func checkAndRequestLocationIfNeeded() {
    let locationRequested = UserDefaults.standard.bool(forKey: OnboardingKey.locationRequested.rawValue)
    guard !locationRequested else { return }
    guard permissionManager.locationStatus == .notDetermined else { return }

    // 첫 홈탭 진입 시 요청 (한 번만)
    Task {
        await permissionManager.requestLocationPermission()
        UserDefaults.standard.set(true, forKey: OnboardingKey.locationRequested.rawValue)
    }
}

// loadData() 마지막에 호출
await verseTask
await weatherTask
checkAndRequestLocationIfNeeded()  // ← 추가
```

---

## 7. 테마 → VerseSelector 연동

```swift
// VerseSelector.select(from:mode:weather:) 내에 추가
// 선택된 테마가 있으면 해당 테마 구절에 가중치 추가

private func preferredThemeBonus(_ verse: Verse) -> Int {
    let preferred = UserDefaults.standard.data(forKey: "preferredThemes")
        .flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
    guard !preferred.isEmpty else { return 0 }
    let overlap = Set(verse.theme).intersection(Set(preferred))
    return overlap.isEmpty ? 0 : 5  // 선호 테마 겹침 시 +5점 보너스
}
```

---

## 8. 디자인 토큰 (온보딩 전용)

```swift
// 기존 Color+DailyVerse.swift 활용 (추가 불필요)
// dvBgDeep, dvAccentGold, dvBgSurface 그대로 사용

// 온보딩 전용 폰트 사이즈 (추가 없이 inline으로 처리)
// 타이틀: .system(size: 28, weight: .bold)
// 서브타이틀: .system(size: 18, weight: .medium)
// 버튼: .system(size: 18, weight: .semibold)
// 캡션: .dvCaption (기존)

// 온보딩 전용 애니메이션
extension Animation {
    static let onbTransition: Animation = .spring(response: 0.5, dampingFraction: 0.85)
    static let onbFadeIn: Animation = .easeIn(duration: 0.6)
}
```

---

## 9. 엣지케이스 처리

| 케이스 | 처리 방법 |
|--------|---------|
| Screen 2 배경이미지 nil | `Verse.fallbackRiseIgnite` + Zone gradient 폴백 |
| 테마 선택 0개 | "건너뛰기" 버튼 표시, 빈 선택 허용 |
| 알람 모두 미설정 | 온보딩 완료 가능, HomeView에서 CTA 표시 |
| 닉네임 빈 값 | "친구" 기본값 자동 저장 |
| 알림 권한 거부 | 완료 처리, Settings 딥링크 나중에 제공 |
| 온보딩 중 앱 종료 | `currentPage` UserDefaults 저장 → 재진입 시 해당 페이지부터 |

---

## 10. 삭제 파일 처리

기존 6개 뷰 파일은 **소프트 삭제** (코드 유지 + project.pbxproj에서 제거):
- 안전한 pbxproj 수정 스크립트 사용 (기존 패턴)
- 또는 파일명 변경 후 추후 정리: `OnboardingWelcomeView_DEPRECATED.swift`

---

## 11. 구현 가이드

### 11.1 구현 순서

| 순서 | 모듈 | 파일 | 예상 라인 |
|------|------|------|----------|
| M1 | ViewModel | OnboardingViewModel.swift | ~120줄 |
| M2 | 컴포넌트 | ONBThemeChip.swift, ONBAlarmTimeRow.swift | ~60줄 |
| M3 | Screen 1 | ONBIntroView.swift (파티클 포함) | ~100줄 |
| M4 | Screen 2 | ONBExperienceView.swift | ~90줄 |
| M5 | Screen 3 | ONBPersonalizeView.swift | ~100줄 |
| M6 | Screen 4 | ONBAlarmPermissionView.swift | ~110줄 |
| M7 | Container | OnboardingContainerView.swift (전환 애니메이션) | ~70줄 |
| M8 | 연동 | HomeViewModel.swift (위치권한), VerseSelector.swift (테마 가중치) | ~30줄 |

총 예상: ~680줄 신규 + ~30줄 수정

### 11.2 pbxproj 처리

```python
# 신규 파일 8개 등록 필요
# 1. ONBIntroView.swift
# 2. ONBExperienceView.swift
# 3. ONBPersonalizeView.swift
# 4. ONBAlarmPermissionView.swift
# 5. ONBThemeChip.swift
# 6. ONBAlarmTimeRow.swift
# → 기존 add_files_to_pbxproj.py 패턴 활용

# 삭제 파일 5개 unregister:
# - OnboardingWelcomeView.swift (→ ONBIntroView로 대체)
# - OnboardingNicknameView.swift (→ 통합)
# - OnboardingFirstVerseView.swift (→ ONBExperienceView로 대체)
# - OnboardingLocationView.swift (→ 이동)
# - OnboardingNotificationView.swift (→ 통합)
# - OnboardingFirstAlarmView.swift (→ 통합)
```

### 11.3 Session Guide

```
Session 1: M1(ViewModel) + M2(컴포넌트) — 기반 작업
Session 2: M3(Screen 1) + M4(Screen 2) — 인트로 + 체험
Session 3: M5(Screen 3) + M6(Screen 4) — 개인화 + 알람
Session 4: M7(Container 전환) + M8(연동) + pbxproj 처리
```
