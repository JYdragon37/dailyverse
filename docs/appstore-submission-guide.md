# App Store 출시 가이드 — morning manna

> 작성일: 2026-05-17
> 번들 ID: com.morningmanna.app | Apple ID: 6763995142

---

## 전체 순서 한눈에 보기

```
1. 코드 마무리 (Xcode)
2. Archive 빌드 생성
3. TestFlight 업로드
4. App Store Connect 정보 입력
5. 심사 제출
6. 심사 통과 → 배포
```

---

## STEP 1 — 코드 마무리 (Xcode에서)

### 1-1. RevenueCat API 키 입력 (필수)
`DailyVerse/DailyVerse/App/DailyVerseApp.swift:29`
```swift
// 현재 (비어있음 → 수익화 불능)
Purchases.configure(withAPIKey: "")

// 변경
Purchases.configure(withAPIKey: "appl_XXXXXXXXXXXX")
```
> RevenueCat 대시보드 → Projects → API Keys → Public SDK key (appl_로 시작)

### 1-2. Bundle Version 업데이트
> Xcode → 프로젝트 → General → Version: **1.0.0** / Build: **1**
> 재빌드마다 Build 번호 +1 (같은 버전으로 재업로드 불가)

### 1-3. Scheme = Release 확인
> Xcode 툴바 → 기기 선택 옆 scheme → Edit Scheme → Run → Build Configuration: **Release**

### 1-4. PrivacyInfo.xcprivacy 타겟 포함 확인
> Xcode → 좌측 파일 트리 → `PrivacyInfo.xcprivacy` 클릭
> 우측 File Inspector → Target Membership → `DailyVerse` ✅ 체크 확인

### 1-5. 빌드 테스트
```bash
xcodebuild \
  -scheme DailyVerse \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Release \
  build 2>&1 | tail -5
# Expected: BUILD SUCCEEDED
```

---

## STEP 2 — Archive 생성

1. Xcode → 상단 메뉴 → **Product → Archive**
   (실기기 또는 "Any iOS Device (arm64)" 선택 상태에서만 활성화)
2. Archive 완료 후 **Organizer** 창 자동 오픈
3. Archive 선택 → **Distribute App** 클릭
4. **App Store Connect** 선택 → Next
5. **Upload** 선택 → Next
6. 옵션 그대로 → Next (Bitcode, Symbol 업로드 체크 권장)
7. **Automatically manage signing** → Next → Upload

> 업로드 완료: "Your app has been successfully uploaded" 메시지 확인
> App Store Connect에서 빌드 처리 10~30분 소요

---

## STEP 3 — TestFlight (권장)

출시 전 실기기 테스트:

1. App Store Connect → [morning manna 앱](https://appstoreconnect.apple.com/apps/6763995142) → TestFlight
2. 빌드 처리 완료 후 → Internal Testing → 테스터 추가
3. 직접 기기에서 TestFlight 앱 설치 후 테스트

**테스트 체크리스트:**
- [ ] 첫 실행 → 온보딩 4화면 정상 동작
- [ ] 알람 설정 → 알람음 선택 (SoundPickerSheet 6종)
- [ ] 알람 울림 → Stage2 웰컴 스크린 표시
- [ ] 홈 탭 → 말씀 카드 + 날씨 위젯 표시
- [ ] 저장 탭 → 그리드 + Premium 배너 표시
- [ ] 설정 → 구독 섹션 표시 → Premium 페이지 진입
- [ ] ATT 팝업 표시 확인 (첫 알람 저장 시)
- [ ] 개인정보처리방침 링크 정상 열림

---

## STEP 4 — App Store Connect 정보 입력

### 4-1. 앱 메타데이터
> [App Store Connect](https://appstoreconnect.apple.com/apps/6763995142) → App Information

| 항목 | 내용 |
|------|------|
| 이름 | morning manna |
| 부제목 | 말씀 알람으로 하루를 시작하세요 |
| 카테고리 | 라이프스타일 / 참조 |
| 키워드 | 성경,말씀,알람,QT,크리스천,묵상,기도,신앙,찬양,교회,성경구절,큐티,아침,경건,소망 |

### 4-2. 앱 설명
`docs/appstore-metadata.md` 내용 그대로 복사

### 4-3. What's New
```
morning manna 첫 출시를 환영합니다.
말씀 알람으로 하루를 시작해보세요 🙏
```

### 4-4. 스크린샷 (필수: iPhone 6.7인치 = 1290×2796px)

**5장 권장 순서:**
1. 홈 화면 — 아침 말씀 카드 + 날씨 (rise_ignite Zone)
2. 알람 Stage2 — 잠금해제 후 말씀 웰컴 스크린
3. 알람 설정 — SoundPickerSheet 포함 모달
4. 저장된 말씀 그리드
5. 말씀 상세 바텀시트 (해석 + 일상적용)

> Xcode Simulator → 기기: iPhone 16 Pro Max → 앱 실행 → Cmd+S (스크린샷)
> 또는 실기기에서 직접 캡처 (1290×2796 아이폰 15 Pro Max 이상)

### 4-5. 앱 아이콘 확인
> App Store Connect 업로드 이미지 미리보기에서 `morning_mana_app_icon_cutout.png` 표시 확인

### 4-6. 지원 URL
```
mailto:morningmanna.app@gmail.com
```

### 4-7. 개인정보처리방침 URL
```
https://jydragon37.github.io/dailyverse/legal/privacy.html
```

---

## STEP 5 — Privacy & Age Rating

### Privacy Practices (앱 개인정보 관행)
> App Store Connect → 앱 → App Privacy → 답변 필요

| 데이터 유형 | 수집 여부 | 용도 |
|------------|----------|------|
| 이름 | ✅ 수집 | 앱 기능 (닉네임) |
| 이메일 주소 | ✅ 수집 | 계정 관리 (Apple Sign-In) |
| 사용자 ID | ✅ 수집 | 계정 관리 |
| 기기 ID | ✅ 수집 | 광고 (AdMob, ATT 수락 시) |
| 위치 | ✅ 수집 | 앱 기능 (날씨 - 정확한 위치 아님) |
| 진단 데이터 | ✅ 수집 | 앱 개선 (Crashlytics) |

**핵심 포인트:**
- "Do you or your third-party partners collect data?" → **Yes**
- AdMob 광고 ID: ATT 수락한 유저만 → **Third-Party Advertising** 체크

### Age Rating
> App Store Connect → General Information → Age Rating
> **4+** (모든 항목 "없음" 선택)

---

## STEP 6 — 심사 제출 전 최종 점검

### Apple 가이드라인 주요 체크포인트

**[결제 / 구독 — Guideline 3.1.2]**
- [x] 구독 기간, 가격(₩24,500/월)이 앱 내에 명시됨
- [x] "구독은 App Store에서 언제든지 해지 가능합니다" 문구 포함
- [x] 복원하기 버튼 (구독 복원하기) 존재
- [ ] 구독 기능이 실제로 작동하는지 확인 (RevenueCat 키 입력 후)

**[로그인 — Guideline 4.8]**
- [x] Apple Sign-In 구현 (소셜 로그인 있으면 Apple 필수)
- [x] 비로그인 게스트 모드로 앱 사용 가능

**[광고 — Guideline 2.3.7, 3.2.1]**
- [x] ATT 팝업 구현 (첫 알람 저장 시 표시)
- [x] NSUserTrackingUsageDescription 문구 존재
- [x] Premium 유저에게는 광고 미노출 (isPremium 조건)

**[알림 — Guideline 4.5.4]**
- [x] 알림 권한 요청 전 사전 설명 (Permission Priming)
- [x] 알림이 거부된 경우 설정 앱 딥링크 제공

**[개인정보 — Guideline 5.1]**
- [x] PrivacyInfo.xcprivacy 파일 존재
- [ ] Xcode 타겟 포함 확인 필요
- [x] 개인정보처리방침 URL 실제 페이지 (GitHub Pages)
- [x] 이용약관 URL 실제 페이지 (GitHub Pages)

**[콘텐츠 / 종교 — Guideline 1.2]**
- [x] 성경 콘텐츠는 일반 대중 적합
- [x] 개역한글 출처 표기 (SettingsView)
- [x] 번영신학 등 편향 콘텐츠 없음 (content-checker 검증)

**[앱 완성도 — Guideline 2.1]**
- [ ] 모든 탭 (홈/알람/저장/설정) 정상 작동 확인
- [ ] 오프라인 상태에서도 크래시 없는지 확인
- [ ] 빈 상태(empty state) UI 정상 표시 확인

**[인앱 구매 — Guideline 3.1]**
- [ ] 인앱 구매 상품이 App Store Connect에 등록됨
  > App Store Connect → 앱 → Features → In-App Purchases → + 추가
  > Type: Auto-Renewable Subscription
  > ID: com.morningmanna.app.premium.monthly
  > Duration: 1 Month / Price: ₩24,500

---

## STEP 7 — 심사 제출

1. App Store Connect → 앱 → Add for Review
2. 빌드 선택 (TestFlight에서 테스트한 빌드 권장)
3. Export Compliance → No (암호화 없음)
4. Advertising Identifier → Yes (AdMob 사용)
5. 제출 완료

**심사 기간**: 보통 24~48시간 (종교 카테고리는 드물게 5일)

---

## 심사 거절 흔한 이유 & 대응

| 거절 사유 | 대응 |
|----------|------|
| 구독 복원 기능 없음 | PremiumUpgradeView "구독 복원하기" 버튼 존재 ✅ |
| Apple Sign-In 미구현 | 구현 완료 ✅ |
| 개인정보처리방침 미비 | GitHub Pages 실제 페이지 ✅ |
| 광고 ID 수집 시 ATT 미구현 | ATT 구현 완료 ✅ |
| 데모 계정 미제공 | 심사 노트에 게스트 모드 안내 작성 |
| 인앱 구매 미등록 | App Store Connect에서 상품 등록 필요 |

### 심사 노트 (Review Notes) 작성 예시
```
This app is a Christian alarm app for Korean users.

Demo/Test Account: Not required — the app supports guest mode without login.
To experience full features:
1. Launch the app
2. Complete the 4-step onboarding
3. Set an alarm and test notifications

Premium features can be tested using the "구독 복원하기" (Restore Purchases) button.

Note: The app uses the Korean Revised Bible (개역한글, 1961) which is in the public domain.
```

---

## 출시 후 즉시 할 일

- [ ] App Store 페이지 스크린샷 최종 확인
- [ ] TestFlight beta 종료 (출시 후 외부 베타 중단)
- [ ] Firebase Analytics 이벤트 유입 확인
- [ ] Crashlytics 크래시 없는지 모니터링 (24시간)
- [ ] App Store 리뷰 첫 피드백 모니터링
