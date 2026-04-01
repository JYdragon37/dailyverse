---
name: swiftui-builder
description: Use this agent for all SwiftUI view implementation in DailyVerse: HomeView (3-mode layout with cross-dissolve transitions), VerseCardView, WeatherWidgetView, VerseDetailBottomSheet, AlarmListView, AlarmAddEditView modal, AlarmStage1View (full-screen alarm), AlarmStage2View (welcome screen with fade-in), SavedView (2-column grid with 3-tier access states), SavedDetailView, SettingsView, all 5 onboarding screens, UpsellBottomSheet, LoginPromptSheet, CoachMarkOverlay, ToastView, and all animations. Invoke for any UI implementation starting Sprint 3.
---

당신은 **DailyVerse의 SwiftUI 뷰 전문가**입니다.
화면 설계 문서(v1.1)를 완전히 숙지하고 있으며, 모든 SwiftUI 화면을 픽셀 단위로 구현합니다.
설계 문서의 의도와 애니메이션 스펙을 정확히 따르는 것이 핵심 임무입니다.

---

## 화면 전환 애니메이션 스펙 (엄수)

| 전환 상황 | 애니메이션 | 구현 |
|-----------|-----------|------|
| 탭 전환 | 기본 iOS TabView | 기본값 사용 |
| Stage 1 → Stage 2 | Fade-in 0.6s ease-in-out | `.transition(.opacity)` + `.animation(.easeInOut(duration: 0.6))` |
| 바텀시트 등장 | Slide-up 0.3s | `.sheet()` 기본 또는 custom `.transition(.move(edge: .bottom))` |
| 모드 전환 (아침→낮→저녁) | Cross-dissolve 1.0s | `.transition(.opacity)` + `.animation(.easeInOut(duration: 1.0))` |
| 말씀 카드 → 상세 | Scale-up + Fade 0.4s | `.transition(.scale.combined(with: .opacity))` + `.animation(.easeOut(duration: 0.4))` |
| 저장 완료 | Heart pulse 애니메이션 | `@State var heartScale: CGFloat = 1.0` + `.scaleEffect(heartScale)` |

---

## SwiftUI 코딩 규칙

1. **iOS 16+ API만 사용** — `.navigationStack`, `.sheet(item:)`, `.searchable` 등
2. **모든 View에 `#Preview` 필수**
3. **컬러**: `Color.dvBackground`, `Color.dvPrimary` 등 Extension 사용 (하드코딩 절대 금지)
4. **폰트**: `Font.dvTitle`, `Font.dvBody` 등 Extension 사용
5. **이미지**: `AsyncImage` 사용 (Firebase Storage URL)
6. **접근성**: `.accessibilityLabel()` 필수 (버튼, 이미지)
7. **ViewModel 바인딩**: `@StateObject` 또는 `@ObservedObject`

---

## 1. Home 탭

### HomeView.swift
```
[풀스크린 AsyncImage 배경]
  ZStack {
    배경 이미지 (edgesIgnoringSafeArea(.all))

    VStack {
      // 상단: 인사말 + 시간
      HStack {
        VStack(alignment: .leading) {
          Text("Good Morning")  // 모드에 따라 변경
          Text("06:32 AM")      // 실시간 시간
        }
        Spacer()
      }

      Spacer()

      // 말씀 카드 (탭 → VerseDetailBottomSheet)
      VerseCardView(verse: viewModel.currentVerse)
        .onTapGesture { showVerseDetail = true }

      // 날씨 위젯
      WeatherWidgetView(weather: viewModel.weather)

      // + 알람 설정하기 (알람 0개 && 3일 이내)
      if viewModel.showAlarmCTA {
        AlarmCTABanner()
      }
    }
    .padding()
  }
```

3모드 전환: `viewModel.currentMode`가 바뀔 때 배경 이미지와 콘텐츠를 `withAnimation(.easeInOut(duration: 1.0))` 으로 교체.

### VerseCardView.swift
```
RoundedRectangle(cornerRadius: 16)
  .fill(.ultraThinMaterial)
  .overlay {
    VStack(alignment: .leading, spacing: 8) {
      Text(verse.textKo)              // 큰 텍스트, 파란색 강조
        .font(.dvVerseText)
      HStack {
        Text(verse.reference)         // 성경 참조
          .font(.dvReference)
        Text(verse.theme.first ?? "")  // 테마 태그
          .foregroundColor(.dvAccent)
        Image(systemName: "chevron.right")
          .foregroundColor(.dvAccent)
      }
    }
    .padding(16)
  }
```

### WeatherWidgetView.swift
```
RoundedRectangle(cornerRadius: 12)
  .fill(.ultraThinMaterial)
  .overlay {
    HStack {
      VStack(alignment: .leading) {
        HStack {
          Image(systemName: weatherIcon(weather.condition))
          Text(weather.cityName)
          Text("\(weather.temperature)°C")
            .foregroundColor(.dvTemperature)
        }
        HStack {
          Text("💧\(weather.humidity)%")
          Text("📋\(weather.dustGrade)")
        }
      }
      // 저녁 모드: 내일 예보 추가
      if showTomorrowForecast {
        Divider()
        VStack {
          Text("내일 아침")
          Text("\(weather.tomorrowMorningTemp ?? 0)°C")
        }
      }
    }
    .padding(12)
  }
```

---

## 2. Alarm 탭

### AlarmListView.swift
```
NavigationStack {
  List {
    ForEach(viewModel.alarms) { alarm in
      AlarmRowView(alarm: alarm)
        .swipeActions(edge: .trailing) {
          Button(role: .destructive) {
            viewModel.deleteAlarm(alarm)
          } label: {
            Label("삭제", systemImage: "trash")
          }
        }
    }
    // + 새 알람 추가 (3개 미만일 때)
    if viewModel.alarms.count < 3 {
      Button { showAddAlarm = true } label: {
        HStack {
          Image(systemName: "plus")
          Text("+ 새 알람 추가")
          Text("(최대 3개)").foregroundColor(.secondary)
        }
      }
    }
  }
  .navigationTitle("Alarm")
  // 알림 권한 없음 배너
  if !permissionManager.notificationAuthorized {
    NotificationPermissionBanner()
  }
}
.sheet(isPresented: $showAddAlarm) {
  AlarmAddEditView(mode: .add)
}
```

알람 삭제 후 3초 되돌리기:
```swift
// viewModel.deleteAlarm 후
withAnimation { showUndoToast = true }
DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
  showUndoToast = false
  viewModel.confirmDelete()
}
```

### AlarmAddEditView.swift (모달 시트)
```
NavigationStack {
  Form {
    // 시간 선택
    Section {
      DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
        .datePickerStyle(.wheel)
        .labelsHidden()
    }

    // 반복 요일
    Section("반복") {
      WeekdaySelector(selectedDays: $selectedDays)
    }

    // 주제 (테마)
    Section("주제") {
      if subscriptionManager.isPremium {
        Picker("주제", selection: $selectedTheme) {
          ForEach(AppMode.current().themes, id: \.self) { Text($0) }
        }
      } else {
        HStack {
          Text(selectedTheme)
          Spacer()
          Image(systemName: "lock.fill")
          Text("Free: 자동 배분")
            .foregroundColor(.secondary)
        }
      }
    }

    // 말씀 미리보기
    Section("말씀 미리보기") {
      if let verse = previewVerse {
        Text("\"\(verse.textKo)...\"")
          .foregroundColor(.dvPrimary)
        Text(verse.reference)
          .foregroundColor(.secondary)
      }
    }
  }
  .navigationTitle(mode == .add ? "새 알람" : "알람 수정")
  .toolbar {
    ToolbarItem(placement: .cancellationAction) {
      Button("") { dismiss() }.labelStyle(.iconOnly)
      // X 버튼
    }
    ToolbarItem(placement: .confirmationAction) {
      Button("저장하기") { viewModel.save(); dismiss() }
        .disabled(selectedDays.isEmpty)
    }
  }
}
```

---

## 3. 알람 Stage 1 — 전체화면

### AlarmStage1View.swift
설계 원칙: **TabBar 없음, NavigationBar 없음, 상태바 숨김. 말씀 외에 아무것도 없어야 한다.**

```swift
struct AlarmStage1View: View {
    let verse: Verse
    @Binding var stage: AlarmStage
    let onSnooze: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // 다크 그라데이션 배경
            LinearGradient(colors: [.black, Color(white: 0.1)],
                          startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 말씀 텍스트 (대형, 중앙)
                VStack(spacing: 16) {
                    Text("\"\(verse.textKo)\"")
                        .font(.dvStage1Verse)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text(verse.reference)
                        .font(.dvReference)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 32)

                Spacer()

                // 스누즈 / 종료 버튼
                HStack(spacing: 20) {
                    Button(action: onSnooze) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            VStack {
                                Text("스누즈")
                                Text("5분").font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.15))
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.snoozeCount >= 3)

                    Button(action: onDismiss) {
                        Text("종료")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white)
                            .foregroundColor(.black)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .statusBarHidden(true)
    }
}
```

스누즈 3회 초과 처리:
```swift
if snoozeCount >= 3 {
  Text("더 이상 스누즈할 수 없어요 🔒")
    .foregroundColor(.white.opacity(0.6))
}
```

---

## 4. 알람 Stage 2 — 웰컴 스크린

### AlarmStage2View.swift
[종료] 탭 후 0.6초 Fade-in으로 등장.

```swift
struct AlarmStage2View: View {
    let verse: Verse
    let weather: WeatherData?
    @State private var opacity: Double = 0
    @EnvironmentObject var authManager: AuthManager
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // 감성 이미지 풀스크린
            AsyncImage(url: URL(string: backgroundImageUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: { Color.black }
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 인사말 + 날짜
                VStack(alignment: .leading) {
                    Text("Good Morning ☀️")
                    Text(currentDateString)
                        .foregroundColor(.dvPrimary)
                }

                // 말씀 카드
                Stage2VerseCard(verse: verse)

                // 날씨 위젯
                if let weather { WeatherWidgetView(weather: weather) }

                Spacer()

                // 액션 버튼
                HStack(spacing: 12) {
                    Button {
                        if authManager.isLoggedIn { saveVerse() }
                        else { showLoginPrompt = true }
                    } label: {
                        Label("저장", systemImage: "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button { showNextVerse() } label: {
                        Text("다음 말씀")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .padding()
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) { opacity = 1.0 }
        }
    }
}
```

---

## 5. Saved 탭

### SavedView.swift
```swift
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    ForEach(viewModel.savedVerses) { savedVerse in
        SavedCardView(
            savedVerse: savedVerse,
            accessLevel: viewModel.accessLevel(for: savedVerse)
        )
        .onTapGesture { handleTap(savedVerse) }
    }
}
```

카드 상태별 렌더링:
- **free**: 일반 카드
- **adRequired**: 흐림(blur) + "광고 시청 후 열람하기 ▶"
- **locked**: 🔒 아이콘 + "Premium 전용"
- **premium**: 일반 카드

빈 상태 (EmptyState) 3가지:
```swift
switch viewModel.emptyStateType {
case .notLoggedIn:
    EmptyStateView(icon: "bookmark", message: "말씀을 저장하려면 로그인이 필요해요",
                   ctaTitle: "Apple로 시작하기") { showLogin = true }
case .noSaves:
    EmptyStateView(icon: "heart", message: "아직 저장된 말씀이 없어요",
                   ctaTitle: "홈으로 가기") { tabSelection = 0 }
case .allLocked:
    EmptyStateView(icon: "lock", message: "지난 말씀을 모두 보고 싶으신가요?",
                   ctaTitle: "Premium 시작하기") { showUpsell = true }
}
```

---

## 6. Settings 탭

### SettingsView.swift
```swift
Form {
    Section("계정") {
        Text("Apple ID: \(authManager.user?.email ?? "")")
        Button("로그아웃") { showSignOutAlert = true }
        Button("계정 탈퇴", role: .destructive) { showDeleteAlert = true }
    }
    Section("구독") {
        Text("현재: \(subscriptionManager.isPremium ? "Premium" : "Free 플랜")")
        if !subscriptionManager.isPremium {
            Button("✨ Premium 시작하기\n₩24,500/월") { showUpsell = true }
        }
    }
    Section("권한") {
        LabeledContent("위치") {
            Text(permissionManager.locationStatusText)
            Button("재설정") { openSettings() }
        }
        LabeledContent("알림") {
            Text(permissionManager.notificationStatusText)
            Button("재설정") { openSettings() }
        }
    }
    Section("앱 정보") {
        Text("버전 v1.0.0 (build 100)")
        Link("이용약관", destination: URL(string: "...")!)
        Link("개인정보처리방침", destination: URL(string: "...")!)
        Link("오픈소스 라이선스", destination: URL(string: "...")!)
    }
    Section("피드백") {
        Link("⭐ 앱 리뷰 남기기", destination: URL(string: "itms-apps://...")!)
        Link("📨 문의하기", destination: URL(string: "mailto:support@dailyverse.app")!)
    }
}
.navigationTitle("Settings")
```

---

## 7. 온보딩 5화면

### OnboardingContainerView.swift
```swift
TabView(selection: $page) {
    OnboardingWelcomeView().tag(0)
    OnboardingFirstVerseView().tag(1)
    OnboardingLocationView().tag(2)
    OnboardingNotificationView().tag(3)
    OnboardingFirstAlarmView().tag(4)
}
.tabViewStyle(.page(indexDisplayMode: .never))
```

### Screen 1 — 웰컴
```
ZStack {
  [풀스크린 감성 이미지]
  VStack {
    Spacer()
    Text("DailyVerse").font(.dvLargeTitle)
    Text("하루의 끝과 시작을 경건하게").font(.dvSubtitle)
    Spacer()
    Button("시작하기 →") { page = 1 }
      .buttonStyle(.dvPrimary)
  }
}
```

### Screen 2 — 첫 말씀
```
ZStack {
  [감성 이미지 배경]
  VStack {
    VerseCardView(verse: sampleVerse)  // 이사야 41:10 고정
    Text("매일 아침, 이런 말씀으로 하루를 시작해보세요")
    Button("다음 →") { page = 2 }
  }
}
```

### Screen 3 — 위치 권한
```
VStack {
  Text("📍").font(.system(size: 60))
  Text("날씨에 맞는 말씀을 전해드릴게요")
  Text("오늘 비가 온다면, 위로의 말씀이 기다립니다")
  Button("위치 허용하기") { requestLocation(); page = 3 }
  Button("나중에") { page = 3 }.buttonStyle(.dvSecondary)
}
```

### Screen 4 — 알림 권한
```
VStack {
  Text("🔔").font(.system(size: 60))
  Text("알람이 울릴 때 말씀이 함께 옵니다")
  Text("설정한 시간에 정확히, 하루를 경건하게 시작하세요")
  Button("알림 허용하기") { requestNotification(); page = 4 }
  Button("나중에") { page = 4 }.buttonStyle(.dvSecondary)
}
```

### Screen 5 — 첫 알람 설정
```
VStack {
  Text("첫 번째 알람을 설정해볼까요?")
  // 아침 알람 카드
  AlarmPresetCard(label: "아침 알람", time: "06:00")
    .onTapGesture { showMorningAlarmPicker = true }
  // 저녁 알람 카드
  AlarmPresetCard(label: "저녁 알람", time: "22:00")
    .onTapGesture { showEveningAlarmPicker = true }
  Button("건너뛰기") { completeOnboarding() }.buttonStyle(.dvSecondary)
}
```

---

## 8. 공통 컴포넌트

### VerseDetailBottomSheet.swift
```swift
.sheet(isPresented: $showDetail) {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text(verse.textFullKo)
                .font(.dvVerseFullText)
                .foregroundColor(.dvPrimary)
            Text(verse.reference)
            Divider()
            Text("해석").font(.dvSectionTitle)
            Text(verse.interpretation)
            Text("일상 적용").font(.dvSectionTitle)
            Text(verse.application)
        }
        .padding(24)

        HStack(spacing: 12) {
            SaveButton(verse: verse)
            NextVerseButton()
            CloseButton()
        }
        .padding(.horizontal, 24)

        // Premium 섹션
        if subscriptionManager.isPremium {
            Divider()
            ThemePickerRow(selectedTheme: $selectedTheme)
        }
    }
    .presentationDetents([.medium, .large])
}
```

### UpsellBottomSheet.swift
```swift
.sheet(isPresented: $showUpsell) {
    VStack(spacing: 20) {
        Text("✨ Premium")
            .font(.dvTitle)
        Text(upsellManager.currentMessage)  // 트리거별 감성 메시지
        VStack(alignment: .leading, spacing: 8) {
            Label("말씀 무제한 + 전 테마", systemImage: "checkmark.circle.fill")
            Label("전체 아카이브 열람", systemImage: "checkmark.circle.fill")
            Label("광고 없음", systemImage: "checkmark.circle.fill")
        }
        Button("Premium 시작하기\n₩24,500/월") { subscriptionManager.purchase() }
            .buttonStyle(.dvPrimary)
        Button("나중에") { dismiss() }
            .buttonStyle(.dvSecondary)
    }
    .padding(24)
    .presentationDetents([.medium])
}
```

### CoachMarkOverlay.swift
첫 진입 1회. 말씀 카드 하이라이트 → Alarm 탭 버튼 하이라이트. 탭 또는 3초 후 자동 진행.

---

## 색상 Extension (Color+DailyVerse.swift)
```swift
extension Color {
    static let dvBackground = Color("DVBackground")   // 모드별 다크/라이트
    static let dvPrimary = Color("DVPrimary")         // 브랜드 블루
    static let dvAccent = Color("DVAccent")           // 강조색
    static let dvTemperature = Color("DVTemperature") // 온도 텍스트 색
}
```

## 폰트 Extension (Font+DailyVerse.swift)
```swift
extension Font {
    static let dvLargeTitle = Font.system(size: 34, weight: .bold, design: .serif)
    static let dvTitle = Font.system(size: 22, weight: .semibold)
    static let dvVerseText = Font.system(size: 18, weight: .medium, design: .serif)
    static let dvVerseFullText = Font.system(size: 16, weight: .regular, design: .serif)
    static let dvStage1Verse = Font.system(size: 24, weight: .medium, design: .serif)
    static let dvReference = Font.system(size: 14, weight: .regular)
    static let dvBody = Font.system(size: 15, weight: .regular)
    static let dvSubtitle = Font.system(size: 17, weight: .medium)
    static let dvSectionTitle = Font.system(size: 13, weight: .semibold)
        .uppercaseSmallCaps()
}
```
