# Morning Manna Rebrand — Design Spec
> Date: 2026-04-22 | Status: Approved

## Summary
DailyVerse iOS 앱을 Morning Manna로 전면 리브랜딩. 컬러·폰트·브랜드명 교체. DB 구조·Xcode 프로젝트명·URL scheme은 이번 범위 외.

---

## 1. 브랜드명

| 위치 | 변경 전 | 변경 후 |
|------|---------|---------|
| 사용자 노출 텍스트 | "DailyVerse" | "Morning Manna" |
| Info.plist CFBundleDisplayName | (없음, PRODUCT_NAME 사용) | "Morning Manna" 추가 |
| Notification title | "DailyVerse" | "Morning Manna" |
| 공유 카드 워터마크 | "DailyVerse" | "Morning Manna" |

**변경 제외 (내부 식별자)**:
- `NSPersistentContainer(name: "DailyVerse")` — .xcdatamodeld 파일명 참조, 건드리면 Core Data 깨짐
- `dailyverse://` URL scheme — 나중에 별도 처리
- Xcode 프로젝트명 — 나중에 별도 처리
- Firebase 컬렉션명 (`verses/`, `images/` 등) — 백엔드 영향 없음

---

## 2. 컬러 토큰 (Color+DailyVerse.swift 업데이트)

기존 `dv` 토큰명은 유지 (코드 전체 find/replace 방지), 값만 교체.

| 토큰 | 기존 | 신규 |
|------|------|------|
| dvBgDeep | #090D18 | **#15171C** |
| dvBgSurface | #0F1420 | **#1C1F26** |
| dvBgElevated | #1C2333 | **#252932** |
| dvAccentGold / dvGold | #C8972A | **#B7E3F6** (mm_accent_sky) |
| dvAccentSoft | #F5EDD8 | **#F6F1E8** (mm_accent_ivory) |
| dvSaved | #E86B7A | **#E48A9A** |
| dvTextPrimary | white | **#F7F3EE** |
| dvTextSecondary | white 55% | **#D8D1C8** |
| dvTextMuted | white 35% | **#AAA39A** |

**신규 추가 토큰**:
- `dvAccentSky` = #B7E3F6
- `dvAccentBlush` = #F4C7D4
- `dvAccentLilac` = #CFC6F3
- `dvCtaStart` = #9FDDF3
- `dvCtaEnd` = #E8C3D3

**CTA 버튼 그라데이션**: `dvCtaStart → dvCtaEnd` (sky→blush) — 기존 dvGold solid 대체

---

## 3. Zone 그라데이션 (AppMode.swift)

| Zone | 신규 그라데이션 |
|------|----------------|
| deep_dark | #11131A → #1A1F31 |
| first_light | #171E33 → #365B8A |
| rise_ignite | #2E3656 → #8DB8DA → #E8C8D2 (3-stop) |
| peak_mode | #243246 → #4D6A8F |
| recharge | #274040 → #56727D |
| second_wind | #3A4251 → #7A7F9A |
| golden_hour | #47364B → #A9828F |
| wind_down | #161923 → #2A3150 |

---

## 4. 폰트 (Font+DailyVerse.swift)

**임베드 방식**: Option A — 직접 번들 포함

| 패밀리 | 웨이트 | 파일명 |
|--------|--------|--------|
| Pretendard | Regular(400), Medium(500), SemiBold(600), Bold(700) | PretendardVariable.ttf (Variable 단일 파일) |
| Noto Serif KR | Regular(400), SemiBold(600) | NotoSerifKR-Regular.otf, NotoSerifKR-SemiBold.otf |

**토큰 매핑**:
| 토큰 | 기존 | 신규 |
|------|------|------|
| dvLargeTitle | SF Pro Bold 34pt | Pretendard Bold 32pt |
| dvSubtitle | SF Pro Medium 17pt | Pretendard Medium 17pt |
| dvVerseHero | Georgia BoldItalic 26pt | Noto Serif KR SemiBold 24pt |
| dvStage1Verse | Georgia Italic 28pt | Noto Serif KR Regular 22pt |
| dvVerseFullText | Georgia Italic 17pt | Noto Serif KR Regular 17pt |
| dvVerseDisplay | Georgia Italic 14pt | Noto Serif KR Regular 14pt |
| dvVerseText | Georgia Italic 18pt | Noto Serif KR Regular 18pt |
| dvBody | SF Pro Regular 15pt | Pretendard Regular 15pt |
| dvCaption | SF Pro Regular 13pt | Pretendard Medium 13pt |
| dvReference | SF Pro Medium 14pt | Pretendard Medium 14pt |

---

## 5. 앱 아이콘

- `morning_mana_app_icon_cutout.png` → `Assets.xcassets/AppIcon.appiconset`
- 1024×1024 PNG, 외부 투명

---

## 6. 변경 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `Color+DailyVerse.swift` | 컬러 토큰 값 교체 + 신규 토큰 추가 |
| `Font+DailyVerse.swift` | Pretendard / Noto Serif KR 토큰 |
| `AppMode.swift` | gradientColors 8-Zone 교체 |
| `Info.plist` | CFBundleDisplayName + Fonts 키 추가 |
| `SplashView.swift` | "DailyVerse" → "Morning Manna" |
| `AuthWelcomeView.swift` | "DailyVerse" → "Morning Manna" |
| `ONBIntroView.swift` | "DailyVerse" → "Morning Manna" |
| `ONBExperienceView.swift` | "DailyVerse" → "Morning Manna" |
| `NotificationManager.swift` | content.title 교체 |
| `SavedDetailView.swift` | 공유 문자열 교체 |
| `DevotionShareCard.swift` | 워터마크 텍스트 교체 |
| `DailyVerseWidgetsLiveActivity.swift` | Text("DailyVerse") 교체 |
| `Assets.xcassets/AppIcon` | 새 아이콘 PNG |
| `Resources/Fonts/` (신규) | Pretendard + Noto Serif KR 폰트 파일 |

---

## 7. 범위 외 (defer)
- Xcode 프로젝트·타겟·스킴 이름 변경
- `dailyverse://` URL scheme 변경
- Firebase 컬렉션명
- Core Data model 파일명
- App Store 메타데이터
