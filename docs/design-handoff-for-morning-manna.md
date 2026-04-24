# Morning Manna — Design Handoff Document
> 현재 앱(DailyVerse)의 모든 화면·컴포넌트·컬러·타이포 구조를 Morning Manna로 리디자인하기 위한 핸드오프 문서
> 작성 기준: 2026-04-22 / 구현 코드 기준 100% 실측

---

## 1. 앱 구조 전체 맵

```
Morning Manna
├── 스플래시 (로고 + 앱명, 0.8초)
│
├── 온보딩 (최초 1회, 4화면)
│   ├── Screen 1: 공감 — 일반 알람 vs 말씀 알람 애니메이션
│   ├── Screen 2: 체험 — Stage 1/2 알람 시뮬레이션
│   ├── Screen 3: 닉네임 입력
│   └── Screen 4: 첫 알람 설정 (시간 피커 + 알림 권한)
│
├── 메인 탭 (TabView, 4탭)
│   ├── 탭 1: Home (홈)
│   ├── 탭 2: Alarm (알람)
│   ├── 탭 3: Saved (저장)
│   └── 탭 4: Settings (설정)
│
└── 오버레이 / 모달
    ├── 알람 Stage 1 — 전체화면 알람 (Legacy iOS)
    ├── 알람 Stage 2 — 말씀 웰컴 스크린
    ├── 말씀 상세 바텀시트
    ├── 업셀 바텀시트
    ├── 로그인 유도 바텀시트
    └── 날씨 상세 시트
```

---

## 2. 현재 컬러 시스템 (교체 대상)

### 2-1. 배경 계층

| 토큰 | 현재 HEX | 용도 |
|------|----------|------|
| `dvBgDeep` | `#090D18` | 앱 전체 기본 배경 (탭바, 알람 목록) |
| `dvBgSurface` | `#0F1420` | 카드 서피스 |
| `dvBgElevated` | `#1C2333` | Elevated 서피스 (모달 내부) |

### 2-2. 액센트 컬러

| 토큰 | 현재 HEX | 용도 |
|------|----------|------|
| `dvAccentGold` / `dvGold` | `#C8972A` | CTA 버튼, 저장 버튼, 테마 태그, 성경 참조 |
| `dvAccentSoft` | `#F5EDD8` | 보조 텍스트, 칩 테두리 |
| `dvSaved` | `#E86B7A` | 저장 하트 아이콘 |

### 2-3. 8-Zone 그라데이션 배경 (홈·알람 풀스크린 배경)

각 Zone은 배경 이미지(Firebase Storage) + 폴백 그라데이션으로 구성됨.

| Zone | 시간 | 폴백 그라데이션 | 분위기 |
|------|------|-----------------|--------|
| Deep Dark | 00–03 | `#030308` → `#0A0820` | 극야, 보랏빛 어둠 |
| First Light | 03–06 | `#0A1025` → `#1E3A6E` | 새벽 블루 |
| Rise & Ignite | 06–09 | `#1A0E2E` → `#3D1F5A` | 아침 퍼플→코랄 |
| Peak Mode | 09–12 | `#0D1B2A` → `#1B3A5C` | 딥 네이비 |
| Recharge | 12–15 | `#0D2020` → `#1A4A40` | 틸 그린 |
| Second Wind | 15–18 | `#1A1508` → `#3A3010` | 올리브 골드 |
| Golden Hour | 18–21 | `#1A0A02` → `#3A1808` | 딥 앰버 |
| Wind Down | 21–24 | `#06080F` → `#0D1533` | 심야 인디고 |

---

## 3. 타이포그래피 시스템 (교체 가능)

| 토큰 | 폰트 | 크기 | 용도 |
|------|------|------|------|
| `dvLargeTitle` | SF Pro Display Bold | 34pt | 인사말 ("Good Morning, NY") |
| `dvSubtitle` | SF Pro Display Medium | 17pt | 시간·날씨 보조 텍스트 |
| `dvVerseHero` | Georgia BoldItalic | 26pt | 홈 말씀 카드 |
| `dvStage1Verse` | Georgia Italic | 28pt | Stage 1 전체화면 말씀 |
| `dvVerseFullText` | Georgia Italic | 17pt | 바텀시트 전체 구절 |
| `dvVerseDisplay` | Georgia Italic | 14pt | 저장 카드 말씀 |
| `dvTitle` | SF Pro Text Semibold | 22pt | 섹션 타이틀 |
| `dvBody` | SF Pro Text Regular | 15pt | 일반 본문 |
| `dvCaption` | SF Pro Text Regular | 13pt | 캡션, 보조 레이블 |
| `dvReference` | SF Pro Text Medium | 14pt | 성경 참조 (이사야 41:10) |
| `dvUITitle` | SF Pro Rounded Semibold | 20pt | UI 타이틀 |

---

## 4. 화면별 컴포넌트 상세

---

### 4-1. Home 탭

**배경**: 풀스크린 감성 이미지 (Firebase Storage) + 상하 다크 그라데이션 오버레이
**레이어 구조** (아래부터):
1. 감성 이미지 (풀스크린 fill)
2. 상단 그라데이션 오버레이 (black 65% → clear, height 200pt)
3. 하단 그라데이션 오버레이 (clear → black 70%, height 300pt)
4. 인사말 헤더 (상단 고정, padding-top 60pt, padding-horizontal 24pt)
5. 말씀 카드 (화면 48% 지점 중앙 배치)
6. 탭바 (safeAreaInset bottom)

**인사말 헤더 (greetingHeader)**
```
Row 1: [Zone 아이콘 26pt] [인사말 텍스트 34pt bold, max 2줄]
         └ 예: 🌅 Good Morning, NY
Row 2: [34pt spacer] [날짜·시간 17pt semibold] · [도시 온도°C 15pt]
         └ 예: 4월 22일 수  11:57 PM · Seoul 9°C
```
- 인사말 텍스트: `lineLimit(2)`, `minimumScaleFactor(0.7)`
- 날짜 텍스트: `lineLimit(1)`
- 날씨 텍스트: 탭 → 날씨 상세 시트 오픈

**말씀 카드 (verseCenter)**
```
말씀 텍스트     Georgia BoldItalic 22pt, white, lineSpacing 8
성경 참조       SF Pro Medium 15pt, white 80%
테마 태그 칩    13pt, dvAccentGold, capsule 배경 (gold 20%)
♥ 저장 버튼    36pt circle, white 18% 배경
#N 인덱스      11pt, white 35% (폴백이면 숨김)
말씀 깊게 보기  12pt, white 45%, 가로선 + chevron.up
```
- 전체 탭 → 말씀 상세 바텀시트 오픈
- 크로스 디졸브 1.0s 전환 (Zone 변경 시)

---

### 4-2. Alarm 탭

**배경**: `dvBgDeep (#090D18)` 단색

**다가오는 알람 박스** (첫 번째 List 섹션)
```
"다가오는 알람"   13pt medium, secondary color
hh:mm            44pt bold, white
AM/PM            22pt medium, white 60%
X시간 Y분 후     14pt, white 55%
─────────────────
"말씀 미리보기"  Georgia Italic 15pt, white 88%
성경 참조        12pt, dvGold 75%
```
- 배경: `.ultraThinMaterial` + white 10% stroke, cornerRadius 18pt

**알람 카드 (AlarmCardRow)** — 각 알람
```
시간 (hh:mm a)    30pt bold, white
반복 요일          13pt, secondary
테마 태그          13pt, dvGold (capsule)
ON/OFF 토글       iOS standard toggle
```
- 스와이프 삭제 → 3초 되돌리기 토스트
- 탭 → AlarmAddEditView 모달

**빈 상태**: 알람 아이콘 + 안내 텍스트 + [+ 첫 알람 만들기] 버튼

**하단 CTA**: [+ 새 알람 추가] — dvGold gradient, height 52pt, cornerRadius 14pt

---

### 4-3. AlarmAddEditView (모달 시트)

```
시간 피커    DatePicker .wheel style, 80% 높이
──────────
반복 요일    [일][월][화][수][목][금][토] — 7개 토글 버튼
             선택: white bg + dvBgDeep text / 미선택: transparent
요일 요약    "매일" / "주중" / "주말" / "월, 수, 금" 등
──────────
주제 (테마)  Free: 자동 배분 (잠금 아이콘) / Premium: 드롭다운 선택
말씀 미리보기 Georgia Italic, 2줄 max
──────────
[저장하기]   dvGold gradient CTA
```

---

### 4-4. Alarm Stage 1 (전체화면 알람 — Legacy iOS 15-25)

**배경**: 풀스크린 감성 이미지 (알람 발동 시점 기준 Zone)
**오버레이**: 상하 다크 그라데이션 동일
**레이아웃**: 화면 중앙 말씀 텍스트

```
Zone 아이콘 + 인사말    34pt bold
시간·날짜              16pt
────────────────────
말씀 (verseShortKo)   Georgia Italic 22pt, white
성경 참조              15pt medium
────────────────────
[5분 스누즈]           반투명 버튼
[종료]                 반투명 버튼
```
- 탭바·네비게이션바 완전 숨김, zIndex 30

---

### 4-5. Alarm Stage 2 (말씀 웰컴 스크린)

Stage 1과 동일한 배경/레이아웃. 차이점:

```
인사말 헤더       HomeView와 동일 구조
말씀 카드         HomeView verseCenter와 동일 (verseFullKo)
날씨 위젯         도시명 + 온도 (HomeView와 동일)
────────────────────────────────────────
[📖 말씀 더보기]   반투명 와이드 버튼 → VerseDetailBottomSheet
[■ 종료]          작은 원형 버튼
```
- Fade-in 0.6s ease-in-out 등장

---

### 4-6. 말씀 상세 바텀시트 (VerseDetailBottomSheet)

화면 78% 높이 커스텀 detent

```
드래그 인디케이터
────────────────
🔍 해석 (레이블)
해석 텍스트         17pt regular, secondary
────────────────
✨ 오늘의 적용 (레이블)
{닉네임}, 적용 텍스트   19pt regular, primary
────────────────
AdMob 배너 (300×250 Medium Rectangle)
────────────────────────────────────────
[♥ 저장]  dvGold gradient / [🍃 묵상]  반투명 / [✕]  원형
```

---

### 4-7. Saved 탭 (저장)

**배경**: `dvBgDeep`
**레이아웃**: 2열 그리드, 최신순

**접근 제어 (Free)**:
```
0–7일:    자유 열람 (일반 카드)
7–30일:   흐림 처리 + "광고 시청 후 열람하기 ▶"
30일+:    잠금 (🔒 + Premium CTA)
```

**빈 상태 3가지**:
```
비로그인:      북마크 아이콘 + [Apple로 시작하기]
저장 없음:     하트 아이콘 + [홈으로 가기]
30일 초과만:   [Premium 시작하기]
```

**저장 카드**:
```
감성 이미지 (1:1 비율)
말씀 일부 (2줄 truncate)
저장 날짜
```

**카드 상세 (SavedDetailView)** — 풀스크린 시트:
```
감성 이미지 풀스크린 [✕]
말씀 전체 텍스트      Georgia BoldItalic
성경 참조
────────────────────
📅 저장 날짜·시간·Zone
🌤 날씨 스냅샷 (온도, 습도)
📍 위치
────────────────────
[♥ 저장 해제]  [공유]
```

---

### 4-8. Settings 탭

**배경**: iOS 기본 grouped list style

**5개 섹션**:
```
계정:     Apple ID, [로그아웃], [계정 탈퇴 🔴]
구독:     현재 플랜, [✨ Premium 시작하기 / ₩24,500/월]
          플랜 비교 (Free vs Premium 기능 표)
권한:     위치 상태 + [재설정], 알림 상태 + [재설정]
앱 정보:  버전, 이용약관, 개인정보처리방침
피드백:   [⭐ 앱 리뷰 남기기], [📨 문의하기]
```

---

### 4-9. 온보딩 (4화면)

**Screen 1 — 공감 애니메이션**:
```
단계 1 (1.5초): 어두운 배경 + 큰 숫자 "06:00" + 진동 흔들림
단계 2 (1.0초): Bloom dissolve 전환
단계 3 (유지): 감성 배경 + 06:00이 말씀 카드로 전환 + 슬로건 fade-in
슬로건: "매일 아침, 알람이 아닌 말씀으로 눈을 뜨세요"
[시작하기 →]
```

**Screen 2 — 체험 시뮬레이션**:
```
Stage 1 시뮬 → [종료] 탭 → Stage 2 시뮬 → 자동 종료
"내일 아침 알람이 울릴 때 이 말씀이 함께 올 거예요"
[다음 →]
```

**Screen 3 — 닉네임**:
```
"당신을 뭐라고 불러드릴까요?"
텍스트 필드 (타이핑 애니메이션)
[시작하기 →]
```

**Screen 4 — 첫 알람 설정**:
```
"첫 말씀 알람을 설정해볼까요?"
[ 07 : 00 ] TimePicker
[내일 아침 말씀 받기] → 알림 권한 요청 → 알람 저장 → 온보딩 완료
```

---

## 5. 공통 컴포넌트

### 5-1. 버튼 스타일

| 타입 | 스타일 | 용도 |
|------|--------|------|
| Primary CTA | dvGold gradient, height 52pt, cornerRadius 14pt, white text | 저장, 온보딩 완료, 알람 추가 |
| Secondary | `.ultraThinMaterial` + white 18% stroke, cornerRadius 14pt | 말씀 더보기, 스누즈 |
| Destructive | Red, text only | 계정 탈퇴 |
| Icon Button | Circle 44pt, white 10% fill + white 18% stroke | 닫기(✕), 종료(■) |

### 5-2. 테마 태그 칩

```
텍스트: 13pt medium, dvAccentGold
배경:   dvAccentGold 20% opacity, Capsule shape
패딩:   horizontal 8pt, vertical 3pt
예시:   "Peace" "Hope" "Courage"
```

### 5-3. 토스트 (ToastView)

```
배경:   `.ultraThinMaterial` + cornerRadius 12pt
텍스트: 14pt medium, white
표시:   2초 후 자동 dismiss, bottom 100pt
예시:   "말씀이 저장되었습니다" / "알람이 삭제되었습니다"
```

### 5-4. 날씨 표시 (헤더 인라인)

```
[날씨 아이콘] [도시명 온도°C]
예: ☀️ Seoul 9°C
```
탭 시 날씨 상세 시트 오픈 (iOS Weather 앱 스타일, 풀스크린)

### 5-5. 글래스모피즘 카드

```
배경: .ultraThinMaterial / Color.white.opacity(0.10)
테두리: Color.white.opacity(0.10~0.18), 1pt
cornerRadius: 14~18pt
```

---

## 6. 애니메이션 스펙

| 상황 | 애니메이션 |
|------|-----------|
| Zone 전환 (홈 배경) | Cross-dissolve 1.0s |
| Stage 1 → Stage 2 | Fade-in 0.6s ease-in-out |
| 바텀시트 등장 | iOS 기본 slide-up 0.3s |
| 말씀 카드 전환 | `.dvScaleAndFade` (scale + opacity) |
| 저장 하트 | Spring pulse (scale 1.4 → 1.0) |
| 토스트 | Slide-up + opacity 0.3s |
| 온보딩 1화면 | Bloom dissolve 1.0s |

---

## 7. Zone 시스템 (8개)

각 Zone은 시간대별로 배경 이미지·인사말·테마·아이콘이 다름.

| Zone | 시간 | 영문 인사말 | 한국어 인사말 | 아이콘 |
|------|------|-------------|---------------|--------|
| Deep Dark | 00–03 | "Still up, Night Owl?" | "아직 안 잤어요?" | 🌑 moon.fill |
| First Light | 03–06 | "Rise before the world." | "세상보다 먼저 일어난 당신." | 🌒 moon.stars.fill |
| Rise & Ignite | 06–09 | "Good Morning" | "좋은 아침이에요, 오늘도 파이팅!" | 🌅 sunrise.fill |
| Peak Mode | 09–12 | "In the Zone," | "지금 당신, 최고의 상태예요." | ⚡ bolt.fill |
| Recharge | 12–15 | "Breathe. Reset." | "잠깐 숨 고르고, 다시 달려요." | ☀️ sun.max.fill |
| Second Wind | 15–18 | "Second Wind's here." | "두 번째 바람이 왔어요." | 🌤 cloud.sun.fill |
| Golden Hour | 18–21 | "Good Evening" | "수고했어요, 오늘 하루도." | 🌇 sunset.fill |
| Wind Down | 21–24 | "Rest well." | "오늘도 잘 했어요, 푹 쉬어요." | 🌙 moon.stars.fill |

---

## 8. Morning Manna 리브랜딩 체크리스트

아래 항목을 디자이너가 정의해주면 코드로 즉시 반영 가능합니다.

### 컬러 토큰 (필수)

```
[ ] mm_bgDeep          — 앱 기본 배경 (현: #090D18)
[ ] mm_bgSurface       — 카드 서피스 (현: #0F1420)
[ ] mm_bgElevated      — Elevated 서피스 (현: #1C2333)
[ ] mm_accentPrimary   — 주요 액센트 / CTA (현: #C8972A 앰버골드)
[ ] mm_accentSecondary — 보조 액센트
[ ] mm_saved           — 저장 하트 색상 (현: #E86B7A)
[ ] mm_verseTextColor  — 말씀 텍스트 색상 (현: white)
[ ] mm_referenceColor  — 성경 참조 색상 (현: white 80%)
```

### Zone 그라데이션 (8개 × 2~3색)

```
[ ] deep_dark 폴백 그라데이션
[ ] first_light 폴백 그라데이션
[ ] rise_ignite 폴백 그라데이션
[ ] peak_mode 폴백 그라데이션
[ ] recharge 폴백 그라데이션
[ ] second_wind 폴백 그라데이션
[ ] golden_hour 폴백 그라데이션
[ ] wind_down 폴백 그라데이션
```

### 타이포그래피

```
[ ] 말씀 폰트 유지 여부 (현: Georgia BoldItalic)
[ ] 인사말 폰트 유지 여부 (현: SF Pro Display Bold 34pt)
[ ] 새 폰트가 있다면 이름 + 사이즈 매핑
```

### 브랜드 텍스트

```
[ ] 앱 이름: Morning Manna (확정)
[ ] 탭바 타이틀 변경 여부 (현: 홈/알람/저장/설정)
[ ] 온보딩 슬로건 (현: "매일 아침, 알람이 아닌 말씀으로 눈을 뜨세요")
[ ] 알람 완료 토스트 문구 유지 여부
```

### 에셋

```
[ ] AppIcon: morning_mana_app_icon_cutout.png (완료)
[ ] Logo: morning_mana_logo_transparent_safe.png (완료)
[ ] 스플래시 로고 사용 (logo vs icon)
[ ] 탭바 아이콘 커스텀 여부 (현: SF Symbols)
```

---

## 9. 코드 교체 범위 (개발자 참고)

디자인 확정 후 수정할 파일 목록:

| 파일 | 내용 |
|------|------|
| `Color+DailyVerse.swift` | 전체 컬러 토큰 교체 |
| `AppMode.swift` | Zone 그라데이션 컬러 교체 |
| `Font+DailyVerse.swift` | 폰트 토큰 교체 (필요시) |
| `Assets.xcassets/AppIcon` | 새 아이콘 PNG 교체 |
| `AppMode.swift` | 인사말 텍스트 교체 (greeting 프로퍼티) |
| `OnboardingXxxView.swift` | 슬로건·브랜드명 텍스트 |
| `AlarmListView.swift` | "알람" 탭 내 브랜드 텍스트 |
| `SettingsView.swift` | 앱 이름, 이용약관 링크 등 |
| `Info.plist` | `CFBundleDisplayName` = "Morning Manna" |
| `NotificationManager.swift` | 알림 문구 내 브랜드명 |
