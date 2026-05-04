# Morning Manna Rebrand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DailyVerse iOS 앱을 Morning Manna로 전면 리브랜딩 — 컬러·폰트·Zone 그라데이션·브랜드명 전면 교체.

**Architecture:** 내부 토큰명(`dv` prefix)은 유지하고 값만 교체해 코드 전체 find/replace를 최소화. 폰트는 프로젝트 번들에 직접 임베드(기존 FA00100x UUID 패턴 확장). DB·URL scheme·Xcode 프로젝트명은 이번 범위 외.

**Tech Stack:** SwiftUI, Xcode 26, Python 3 (pbxproj 수정), curl (폰트 다운로드)

---

## File Map

| 파일 | 역할 |
|------|------|
| `DailyVerse/DailyVerse/PretendardVariable.ttf` | 신규 — Pretendard Variable 폰트 |
| `DailyVerse/DailyVerse/NotoSerifKR-Regular.otf` | 신규 — Noto Serif KR Regular |
| `DailyVerse/DailyVerse/NotoSerifKR-SemiBold.otf` | 신규 — Noto Serif KR SemiBold |
| `DailyVerse/DailyVerse.xcodeproj/project.pbxproj` | 폰트 파일 프로젝트 등록 |
| `DailyVerse/DailyVerse/Info.plist` | UIAppFonts + CFBundleDisplayName |
| `DailyVerse/DailyVerse/Common/Extensions/Color+DailyVerse.swift` | 컬러 토큰 값 교체 |
| `DailyVerse/DailyVerse/Common/Extensions/Font+DailyVerse.swift` | 폰트 토큰 교체 |
| `DailyVerse/DailyVerse/App/AppMode.swift` | Zone 그라데이션 교체 |
| `DailyVerse/DailyVerse/Features/Splash/SplashView.swift` | 브랜드명 + 폰트 |
| `DailyVerse/DailyVerse/Features/Auth/AuthWelcomeView.swift` | 브랜드명 + 폰트 |
| `DailyVerse/DailyVerse/Features/Onboarding/Screens/ONBIntroView.swift` | 브랜드명 |
| `DailyVerse/DailyVerse/Features/Onboarding/Screens/ONBExperienceView.swift` | 브랜드명 |
| `DailyVerse/DailyVerse/Core/Services/NotificationManager.swift` | 알림 title |
| `DailyVerse/DailyVerse/Features/Saved/SavedDetailView.swift` | 공유 문자열 |
| `DailyVerse/DailyVerse/Features/Meditation/DevotionShareCard.swift` | 워터마크 |
| `DailyVerse/DailyVerseWidgets/DailyVerseWidgetsLiveActivity.swift` | 위젯 텍스트 |
| `DailyVerse/DailyVerse/Assets.xcassets/AppIcon.appiconset/` | 앱 아이콘 |

---

## Task 1: 폰트 파일 다운로드

**Files:**
- Create: `DailyVerse/DailyVerse/PretendardVariable.ttf`
- Create: `DailyVerse/DailyVerse/NotoSerifKR-Regular.otf`
- Create: `DailyVerse/DailyVerse/NotoSerifKR-SemiBold.otf`

- [ ] **Step 1-1: Pretendard Variable 다운로드**

```bash
cd /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse
curl -L "https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip" -o /tmp/pretendard.zip
unzip -o /tmp/pretendard.zip "web/static/Pretendard-Regular.otf" "web/static/Pretendard-Medium.otf" "web/static/Pretendard-SemiBold.otf" "web/static/Pretendard-Bold.otf" -d /tmp/pretendard_extracted/ 2>/dev/null || true
# Variable 폰트 우선
unzip -o /tmp/pretendard.zip "*/PretendardVariable.ttf" -d /tmp/pretendard_extracted/ 2>/dev/null || true
ls /tmp/pretendard_extracted/
```

- [ ] **Step 1-2: Variable 폰트 복사 (있으면) 또는 Bold+Regular 복사**

```bash
# Variable 찾기
VARFONT=$(find /tmp/pretendard_extracted -name "PretendardVariable.ttf" 2>/dev/null | head -1)
if [ -n "$VARFONT" ]; then
  cp "$VARFONT" /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/PretendardVariable.ttf
  echo "Variable 폰트 복사 완료"
else
  # Static 폰트들 복사 (Regular, Bold 최소)
  find /tmp/pretendard_extracted -name "Pretendard-Regular.otf" | head -1 | xargs -I{} cp {} /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/
  find /tmp/pretendard_extracted -name "Pretendard-Bold.otf" | head -1 | xargs -I{} cp {} /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/
  find /tmp/pretendard_extracted -name "Pretendard-SemiBold.otf" | head -1 | xargs -I{} cp {} /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/
  find /tmp/pretendard_extracted -name "Pretendard-Medium.otf" | head -1 | xargs -I{} cp {} /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/
  echo "Static 폰트 복사 완료"
fi
ls /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Pretendard*
```

- [ ] **Step 1-3: Noto Serif KR 다운로드**

```bash
# Google Fonts에서 Noto Serif KR 다운로드
curl -L "https://fonts.gstatic.com/s/notoserifkr/v25/3Jn8SDn90Gmq2mr3blnHaTZXTEeF1g_1qVnQ.woff2" -o /tmp/NotoSerifKR-Regular.woff2 2>/dev/null
# woff2는 iOS에서 직접 사용 불가 → otf 링크 시도
curl -L "https://github.com/notofonts/noto-cjk/raw/main/Serif/OTF/Korean/NotoSerifCJKkr-Regular.otf" \
  -o /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/NotoSerifKR-Regular.otf
curl -L "https://github.com/notofonts/noto-cjk/raw/main/Serif/OTF/Korean/NotoSerifCJKkr-SemiBold.otf" \
  -o /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/NotoSerifKR-SemiBold.otf
ls -lh /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/NotoSerifKR-*.otf
```

- [ ] **Step 1-4: 다운로드 확인**

```bash
ls -lh /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Pretendard* \
        /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/NotoSerifKR*
```

Expected: 각 파일 > 1MB (폰트 파일은 큰 편)

---

## Task 2: project.pbxproj에 폰트 등록

기존 패턴: `FA00100{N}FA00100{N}FA00100{N}`
(NanumPen = FA001003/FA001004, DancingScript = FA001001/FA001002)

신규 할당:
- FA001005 — PretendardVariable.ttf (FileRef)
- FA001006 — PretendardVariable.ttf (BuildFile)
- FA001007 — NotoSerifKR-Regular.otf (FileRef)
- FA001008 — NotoSerifKR-Regular.otf (BuildFile)
- FA001009 — NotoSerifKR-SemiBold.otf (FileRef)
- FA00100A — NotoSerifKR-SemiBold.otf (BuildFile)

**Files:**
- Modify: `DailyVerse/DailyVerse.xcodeproj/project.pbxproj`

- [ ] **Step 2-1: 현재 pbxproj 백업**

```bash
cp /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj \
   /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj.bak2
echo "백업 완료"
```

- [ ] **Step 2-2: Python 스크립트로 폰트 등록**

```bash
python3 << 'PYEOF'
import re

pbxproj_path = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj"

with open(pbxproj_path, "r", encoding="utf-8") as f:
    content = f.read()

# 괄호 검증 (수정 전)
open_count = content.count("{")
close_count = content.count("}")
assert open_count == close_count, f"수정 전 괄호 불균형: {{ {open_count} vs }} {close_count}"
print(f"수정 전 괄호 균형 OK: {open_count}")

# --- 추가할 항목 결정 (Variable이 있으면 Variable만, 없으면 static 4종) ---
import os
font_dir = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse"
fonts = []
if os.path.exists(f"{font_dir}/PretendardVariable.ttf"):
    fonts.append(("FA001005FA001005FA001005", "FA001006FA001006FA001006", "PretendardVariable.ttf", "ttf"))
else:
    for fname, fref, fbuild in [
        ("Pretendard-Regular.otf",   "FA001005FA001005FA001005", "FA001006FA001006FA001006"),
        ("Pretendard-Medium.otf",    "FA001007FA001007FA001007", "FA001008FA001008FA001008"),
        ("Pretendard-SemiBold.otf",  "FA001009FA001009FA001009", "FA00100AFA00100AFA00100A"),
        ("Pretendard-Bold.otf",      "FA00100BFA00100BFA00100B", "FA00100CFA00100CFA00100C"),
    ]:
        if os.path.exists(f"{font_dir}/{fname}"):
            fonts.append((fref, fbuild, fname, "otf"))

# Noto Serif KR
for fref, fbuild, fname, ext in [
    ("FA001011FA001011FA001011", "FA001012FA001012FA001012", "NotoSerifKR-Regular.otf", "otf"),
    ("FA001013FA001013FA001013", "FA001014FA001014FA001014", "NotoSerifKR-SemiBold.otf", "otf"),
]:
    if os.path.exists(f"{font_dir}/{fname}"):
        fonts.append((fref, fbuild, fname, ext))

print(f"등록할 폰트: {[f[2] for f in fonts]}")

# --- PBXFileReference 섹션에 추가 ---
file_ref_block = ""
for fref, fbuild, fname, ext in fonts:
    if fref in content:
        print(f"이미 등록됨: {fname}")
        continue
    file_ref_block += f'\t\t{fref} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = file; path = "{fname}"; sourceTree = "<group>"; }};\n'

if file_ref_block:
    # NanumPen FileRef 다음에 삽입
    anchor = 'FA001003FA001003FA001003 /* NanumPenScript-Regular.ttf */'
    insert_after = content.find(anchor)
    line_end = content.find("\n", insert_after)
    content = content[:line_end+1] + file_ref_block + content[line_end+1:]
    print("PBXFileReference 추가 완료")

# --- PBXBuildFile 섹션에 추가 ---
build_file_block = ""
for fref, fbuild, fname, ext in fonts:
    if fbuild in content:
        continue
    build_file_block += f'\t\t{fbuild} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {fname} */; }};\n'

if build_file_block:
    anchor = 'FA001004FA001004FA001004 /* NanumPenScript-Regular.ttf in Resources */'
    insert_after = content.find(anchor)
    line_end = content.find("\n", insert_after)
    content = content[:line_end+1] + build_file_block + content[line_end+1:]
    print("PBXBuildFile 추가 완료")

# --- 그룹(Sources) 파일 목록에 FileRef 추가 ---
group_ref_block = ""
for fref, fbuild, fname, ext in fonts:
    group_entry = f'\t\t\t\t{fref} /* {fname} */,'
    if fref in content:
        continue
    group_ref_block += group_entry + "\n"

if group_ref_block:
    anchor = 'FA001003FA001003FA001003 /* NanumPenScript-Regular.ttf */,'
    insert_after = content.find(anchor)
    line_end = content.find("\n", insert_after)
    content = content[:line_end+1] + group_ref_block + content[line_end+1:]
    print("그룹 파일 목록 추가 완료")

# --- PBXResourcesBuildPhase에 BuildFile 추가 ---
resource_block = ""
for fref, fbuild, fname, ext in fonts:
    resource_entry = f'\t\t\t\t{fbuild} /* {fname} in Resources */,'
    if fbuild in content:
        continue
    resource_block += resource_entry + "\n"

if resource_block:
    anchor = 'FA001004FA001004FA001004 /* NanumPenScript-Regular.ttf in Resources */,'
    insert_after = content.find(anchor)
    line_end = content.find("\n", insert_after)
    content = content[:line_end+1] + resource_block + content[line_end+1:]
    print("PBXResourcesBuildPhase 추가 완료")

# 괄호 검증 (수정 후)
open_count2 = content.count("{")
close_count2 = content.count("}")
assert open_count2 == close_count2, f"수정 후 괄호 불균형: {{ {open_count2} vs }} {close_count2}"
print(f"수정 후 괄호 균형 OK: {open_count2}")

with open(pbxproj_path, "w", encoding="utf-8") as f:
    f.write(content)
print("project.pbxproj 저장 완료")
PYEOF
```

- [ ] **Step 2-3: 등록 확인**

```bash
grep -c "Pretendard\|NotoSerifKR" /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj
```

Expected: 등록된 폰트 수에 따라 4~12 (각 파일당 PBXFileReference + PBXBuildFile + 그룹 + Resources = 4줄)

---

## Task 3: Info.plist 업데이트

**Files:**
- Modify: `DailyVerse/DailyVerse/Info.plist`

- [ ] **Step 3-1: CFBundleDisplayName 추가 + UIAppFonts에 신규 폰트 등록**

```bash
python3 << 'PYEOF'
import plistlib, os

plist_path = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Info.plist"
font_dir = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse"

with open(plist_path, "rb") as f:
    plist = plistlib.load(f)

# 1. 앱 표시 이름
plist["CFBundleDisplayName"] = "Morning Manna"

# 2. UIAppFonts에 신규 폰트 추가
existing_fonts = plist.get("UIAppFonts", [])
new_fonts = []
for fname in ["PretendardVariable.ttf",
              "Pretendard-Regular.otf", "Pretendard-Medium.otf",
              "Pretendard-SemiBold.otf", "Pretendard-Bold.otf",
              "NotoSerifKR-Regular.otf", "NotoSerifKR-SemiBold.otf"]:
    if fname not in existing_fonts and os.path.exists(f"{font_dir}/{fname}"):
        new_fonts.append(fname)

plist["UIAppFonts"] = existing_fonts + new_fonts
print("UIAppFonts:", plist["UIAppFonts"])
print("CFBundleDisplayName:", plist["CFBundleDisplayName"])

with open(plist_path, "wb") as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_XML, sort_keys=False)
print("Info.plist 저장 완료")
PYEOF
```

- [ ] **Step 3-2: 확인**

```bash
grep -A3 "UIAppFonts\|CFBundleDisplayName" /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Info.plist | head -20
```

Expected: Morning Manna 표시 + Pretendard/NotoSerifKR 항목 포함

---

## Task 4: 컬러 토큰 교체 (Color+DailyVerse.swift)

**Files:**
- Modify: `DailyVerse/DailyVerse/Common/Extensions/Color+DailyVerse.swift`

- [ ] **Step 4-1: 파일 전체를 Morning Manna 팔레트로 교체**

`Color+DailyVerse.swift` 전체를 아래 내용으로 교체:

```swift
import SwiftUI

// Morning Manna Design System — v1.0
// 리브랜딩: DailyVerse 골드 시스템 → Morning Manna 새벽 파스텔 시스템

extension Color {

    // MARK: - 배경 계층 (Dark Charcoal)

    /// 앱 기본 배경 #15171C
    static let dvBgDeep     = Color(hex: "#15171C")
    /// 카드 서피스 #1C1F26
    static let dvBgSurface  = Color(hex: "#1C1F26")
    /// Elevated 서피스 (모달, 바텀시트) #252932
    static let dvBgElevated = Color(hex: "#252932")

    // MARK: - 액센트 (Dawn Pastel)

    /// Sky Blue #B7E3F6 — 주요 하이라이트, 칩 선택 상태
    static let dvAccentSky   = Color(hex: "#B7E3F6")
    /// Blush Pink #F4C7D4 — 따뜻한 포인트
    static let dvAccentBlush = Color(hex: "#F4C7D4")
    /// Ivory Glow #F6F1E8 — 교차 중심 부드러운 빛
    static let dvAccentIvory = Color(hex: "#F6F1E8")
    /// Lilac Mist #CFC6F3 — 보조 미스트
    static let dvAccentLilac = Color(hex: "#CFC6F3")

    /// CTA 그라데이션 시작 #9FDDF3
    static let dvCtaStart = Color(hex: "#9FDDF3")
    /// CTA 그라데이션 종료 #E8C3D3
    static let dvCtaEnd   = Color(hex: "#E8C3D3")

    // MARK: - 레거시 토큰명 유지 (값만 교체 — 기존 코드 무수정)

    /// 기존 dvAccentGold → Sky Blue로 교체
    static let dvAccentGold  = dvAccentSky
    static let dvGold        = dvAccentSky
    static let dvAccentSoft  = dvAccentIvory
    static let dvAccent      = dvAccentSky
    static let dvVerseGold   = dvAccentSky

    // MARK: - 텍스트

    /// 본문 주요 텍스트 #F7F3EE
    static let dvTextPrimary   = Color(hex: "#F7F3EE")
    /// 보조 텍스트 #D8D1C8
    static let dvTextSecondary = Color(hex: "#D8D1C8")
    /// 비활성 / 캡션 #AAA39A
    static let dvTextMuted     = Color(hex: "#AAA39A")
    /// 힌트 텍스트
    static let dvTextHint      = Color(hex: "#AAA39A").opacity(0.7)

    // MARK: - 저장 / 하트

    /// 저장 하트 #E48A9A
    static let dvSaved = Color(hex: "#E48A9A")

    // MARK: - 서피스 / 보더

    /// 구분선 / stroke — white 12%
    static let dvBorderMid     = Color.white.opacity(0.12)
    static let dvSurfaceGlass  = Color.white.opacity(0.10)
    static let dvSurfaceBorder = Color.white.opacity(0.14)
    static let dvOverlay       = Color.black.opacity(0.40)
    static let dvLine          = Color(hex: "#FFFFFF1F")

    // MARK: - 레거시 호환

    static let dvPrimaryDeep  = Color(hex: "#15171C")
    static let dvPrimaryMid   = Color(hex: "#1C1F26")
    static let dvPrimary      = Color.primary
    static let dvBackground   = Color(UIColor.systemBackground)
    static let dvSurface      = dvSurfaceGlass
    static let dvCardFill     = dvSurfaceGlass
    static let dvCardBorder   = dvSurfaceBorder
    static let dvNight        = dvPrimaryDeep
    static let dvDeepNavy     = dvPrimaryMid
    static let dvDarkSlate    = Color(hex: "#252932")
    static let dvTemperature  = dvAccentSky
    static let dvSage         = Color(hex: "#7A9E87")

    // MARK: - Zone 액센트 (값 업데이트)

    static let dvDeepDarkAccent   = Color(hex: "#1A1F31")
    static let dvFirstLightAccent = Color(hex: "#365B8A")
    static let dvRechargeAccent   = Color(hex: "#56727D")
    static let dvRechargeSoft     = Color(hex: "#274040")
    static let dvSecondWindAccent = Color(hex: "#7A7F9A")
    static let dvSecondWindSoft   = Color(hex: "#3A4251")
    static let dvGoldenHourAccent = Color(hex: "#A9828F")

    // MARK: - Morning / Afternoon / Evening (레거시 호환)

    static let dvMorningGold        = dvAccentIvory
    static let dvMorningAmber       = dvAccentBlush
    static let dvNoonSky            = dvAccentSky
    static let dvNoonTeal           = Color(hex: "#56727D")
    static let dvEveningPurple      = dvAccentLilac
    static let dvEveningIndigo      = Color(hex: "#2A3150")
    static let dvDawnIndigo         = Color(hex: "#1A1F31")
    static let dvDawnNavy           = Color(hex: "#171E33")

    // MARK: - 그라데이션 토큰 (레거시 호환)

    static let dvMorningGradStart   = Color(hex: "#2E3656")
    static let dvMorningGradMid     = Color(hex: "#8DB8DA")
    static let dvMorningGradEnd     = Color(hex: "#E8C8D2")
    static let dvAfternoonGradStart = Color(hex: "#243246")
    static let dvAfternoonGradMid   = Color(hex: "#4D6A8F")
    static let dvAfternoonGradEnd   = Color(hex: "#4D6A8F")
    static let dvEveningGradStart   = Color(hex: "#161923")
    static let dvEveningGradMid     = Color(hex: "#2A3150")
    static let dvEveningGradEnd     = Color(hex: "#2A3150")
}

// MARK: - Hex 초기화 헬퍼

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

- [ ] **Step 4-2: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Common/Extensions/Color+DailyVerse.swift
git commit -m "design: Morning Manna 컬러 팔레트 적용 — 골드 → 새벽 파스텔"
```

---

## Task 5: 폰트 토큰 교체 (Font+DailyVerse.swift)

**Files:**
- Modify: `DailyVerse/DailyVerse/Common/Extensions/Font+DailyVerse.swift`

- [ ] **Step 5-1: 어떤 폰트가 설치되었는지 확인 후 토큰 파일 교체**

```bash
python3 << 'PYEOF'
import os
font_dir = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse"
has_variable = os.path.exists(f"{font_dir}/PretendardVariable.ttf")
has_noto_reg = os.path.exists(f"{font_dir}/NotoSerifKR-Regular.otf")
has_noto_semi = os.path.exists(f"{font_dir}/NotoSerifKR-SemiBold.otf")

# 실제 폰트 PostScript 이름 결정
pretendard_name = "PretendardVariable" if has_variable else "Pretendard-Regular"
pretendard_bold = "PretendardVariable" if has_variable else "Pretendard-Bold"
pretendard_semi = "PretendardVariable" if has_variable else "Pretendard-SemiBold"
pretendard_med  = "PretendardVariable" if has_variable else "Pretendard-Medium"
noto_reg  = "NotoSerifCJKkr-Regular"  if has_noto_reg  else "NotoSerifKR-Regular"
noto_semi = "NotoSerifCJKkr-SemiBold" if has_noto_semi else "NotoSerifKR-SemiBold"

print(f"Pretendard: {pretendard_name}")
print(f"Noto Serif Regular: {noto_reg}")
print(f"Noto Serif SemiBold: {noto_semi}")
print(f"Variable={has_variable}, NotoReg={has_noto_reg}, NotoSemi={has_noto_semi}")
PYEOF
```

- [ ] **Step 5-2: Font+DailyVerse.swift 교체**

위 Step 5-1 결과를 참고해 PostScript 이름을 확인한 뒤 아래 파일로 교체. Variable 폰트면 `weight:` 파라미터로 굵기 조절 가능.

```swift
import SwiftUI

// Morning Manna Typography System v1.0
// Primary UI: Pretendard (Variable or Static)
// Editorial Serif: Noto Serif KR
// Fallback: SF Pro System

extension Font {

    // MARK: - 말씀 전용 (Noto Serif KR — 경건함)

    /// 홈 화면 핵심 말씀 (SemiBold 24pt)
    static let dvVerseHero     = Font.custom("NotoSerifCJKkr-SemiBold", size: 24)
    /// Stage 1 전체화면 말씀 (Regular 22pt)
    static let dvStage1Verse   = Font.custom("NotoSerifCJKkr-Regular", size: 22)
    /// 바텀시트 전체 구절 (Regular 17pt)
    static let dvVerseFullText = Font.custom("NotoSerifCJKkr-Regular", size: 17)
    /// 저장 카드 말씀 (Regular 14pt)
    static let dvVerseDisplay  = Font.custom("NotoSerifCJKkr-Regular", size: 14)
    /// 범용 말씀 텍스트 (Regular 18pt)
    static let dvVerseText     = Font.custom("NotoSerifCJKkr-Regular", size: 18)

    // MARK: - 인사말 / UI (Pretendard)

    /// 인사말 "Good Morning, NY" (Bold 32pt)
    static let dvLargeTitle = Font.custom("PretendardVariable", size: 32).weight(.bold)
    /// 시간 / 날씨 보조 (Medium 17pt)
    static let dvSubtitle   = Font.custom("PretendardVariable", size: 17).weight(.medium)

    // MARK: - UI 레이블 / 버튼

    static let dvTitle        = Font.custom("PretendardVariable", size: 22).weight(.semibold)
    static let dvBody         = Font.custom("PretendardVariable", size: 15)
    static let dvCaption      = Font.custom("PretendardVariable", size: 13).weight(.medium)
    static let dvSectionTitle = Font.custom("PretendardVariable", size: 13).weight(.semibold)
    static let dvReference    = Font.custom("PretendardVariable", size: 14).weight(.medium)

    // MARK: - UI Rounded (레거시 호환 — Pretendard로 대체)

    static let dvUITitle    = Font.custom("PretendardVariable", size: 20).weight(.semibold)
    static let dvUISubtitle = Font.custom("PretendardVariable", size: 17).weight(.medium)
    static let dvUIBody     = Font.custom("PretendardVariable", size: 15)
    static let dvUICaption  = Font.custom("PretendardVariable", size: 13).weight(.medium)
}
```

**중요**: 실제 PostScript 이름은 Step 5-1 출력 기준으로 조정. Variable 폰트가 없으면:
- `"PretendardVariable"` → `"Pretendard-Regular"` / `"Pretendard-Bold"` 등으로 교체
- Noto CJK가 없으면 `"NotoSerifCJKkr-Regular"` → `"NotoSerifKR-Regular"` 로 교체

- [ ] **Step 5-3: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Common/Extensions/Font+DailyVerse.swift
git commit -m "design: Morning Manna 타이포 시스템 — Pretendard + Noto Serif KR"
```

---

## Task 6: Zone 그라데이션 교체 (AppMode.swift)

**Files:**
- Modify: `DailyVerse/DailyVerse/App/AppMode.swift`

- [ ] **Step 6-1: gradientColors 섹션 교체**

`AppMode.swift`의 `gradientColors` computed property 전체를 교체:

```swift
var gradientColors: [Color] {
    switch self {
    case .deepDark:
        return [Color(hex: "#11131A"), Color(hex: "#1A1F31")]
    case .firstLight:
        return [Color(hex: "#171E33"), Color(hex: "#365B8A")]
    case .riseIgnite:
        return [Color(hex: "#2E3656"), Color(hex: "#8DB8DA"), Color(hex: "#E8C8D2")]
    case .peakMode:
        return [Color(hex: "#243246"), Color(hex: "#4D6A8F")]
    case .recharge:
        return [Color(hex: "#274040"), Color(hex: "#56727D")]
    case .secondWind:
        return [Color(hex: "#3A4251"), Color(hex: "#7A7F9A")]
    case .goldenHour:
        return [Color(hex: "#47364B"), Color(hex: "#A9828F")]
    case .windDown:
        return [Color(hex: "#161923"), Color(hex: "#2A3150")]
    }
}
```

- [ ] **Step 6-2: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/App/AppMode.swift
git commit -m "design: Morning Manna Zone 그라데이션 8종 교체"
```

---

## Task 7: 브랜드명 텍스트 교체 (8개 파일)

**Files:**
- Modify: SplashView, AuthWelcomeView, ONBIntroView, ONBExperienceView, NotificationManager, SavedDetailView, DevotionShareCard, DailyVerseWidgetsLiveActivity

- [ ] **Step 7-1: SplashView.swift**

```
파일: DailyVerse/DailyVerse/Features/Splash/SplashView.swift
변경:
  Text("DailyVerse")  →  Text("Morning Manna")
  .font(.custom("DancingScript-Regular", size: 56))  →  .font(.dvLargeTitle)
  Text("... NanumPenScript ...")  →  .font(.dvCaption) 또는 .font(.dvSubtitle)
```

SplashView.swift의 브랜드명 Text 부분을 직접 Edit 도구로 교체.

- [ ] **Step 7-2: AuthWelcomeView.swift**

```
파일: DailyVerse/DailyVerse/Features/Auth/AuthWelcomeView.swift
변경:
  Text("DailyVerse")  →  Text("Morning Manna")
  .font(.custom("DancingScript-Regular", size: 64))  →  .font(.dvLargeTitle)
```

- [ ] **Step 7-3: ONBIntroView.swift**

```
파일: DailyVerse/DailyVerse/Features/Onboarding/Screens/ONBIntroView.swift
변경:
  Text("DailyVerse")  →  Text("Morning Manna")
  .font(.custom("DancingScript-Regular", size: 26))  →  .font(.dvTitle)
```

- [ ] **Step 7-4: ONBExperienceView.swift**

```
파일: DailyVerse/DailyVerse/Features/Onboarding/Screens/ONBExperienceView.swift
변경:
  Text("DailyVerse")  →  Text("Morning Manna")
```

- [ ] **Step 7-5: NotificationManager.swift**

```
파일: DailyVerse/DailyVerse/Core/Services/NotificationManager.swift
변경:
  content.title = "DailyVerse"  →  content.title = "Morning Manna"
```

- [ ] **Step 7-6: SavedDetailView.swift**

```
파일: DailyVerse/DailyVerse/Features/Saved/SavedDetailView.swift
변경:
  parts.append("DailyVerse")  →  parts.append("Morning Manna")
```

- [ ] **Step 7-7: DevotionShareCard.swift**

```
파일: DailyVerse/DailyVerse/Features/Meditation/DevotionShareCard.swift
변경:
  "DailyVerse".draw(...)  →  "Morning Manna".draw(...)
```

- [ ] **Step 7-8: DailyVerseWidgetsLiveActivity.swift (Widget Extension)**

```
파일: DailyVerse/DailyVerseWidgets/DailyVerseWidgetsLiveActivity.swift
변경:
  Text("DailyVerse")  →  Text("Morning Manna")  (두 곳)
```

- [ ] **Step 7-9: 교체 확인**

```bash
grep -rn '"DailyVerse"' /Users/jeongyong/workspace/dailyverse/DailyVerse \
  --include="*.swift" \
  | grep -v "NSPersistentContainer\|//\|\.bak"
```

Expected: 결과 없음 (NSPersistentContainer 제외 후 "DailyVerse" 문자열 0건)

- [ ] **Step 7-10: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Features/Splash/SplashView.swift \
        DailyVerse/DailyVerse/Features/Auth/AuthWelcomeView.swift \
        DailyVerse/DailyVerse/Features/Onboarding/Screens/ONBIntroView.swift \
        DailyVerse/DailyVerse/Features/Onboarding/Screens/ONBExperienceView.swift \
        DailyVerse/DailyVerse/Core/Services/NotificationManager.swift \
        DailyVerse/DailyVerse/Features/Saved/SavedDetailView.swift \
        DailyVerse/DailyVerse/Features/Meditation/DevotionShareCard.swift \
        DailyVerse/DailyVerseWidgets/DailyVerseWidgetsLiveActivity.swift
git commit -m "brand: DailyVerse → Morning Manna 브랜드명 전면 교체"
```

---

## Task 8: 앱 아이콘 교체

**Files:**
- Modify: `DailyVerse/DailyVerse/Assets.xcassets/AppIcon.appiconset/`

- [ ] **Step 8-1: AppIcon.appiconset 내용 확인**

```bash
ls /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Assets.xcassets/AppIcon.appiconset/
cat /Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Assets.xcassets/AppIcon.appiconset/Contents.json
```

- [ ] **Step 8-2: 기존 아이콘 파일 확인 후 Morning Manna 아이콘으로 교체**

```bash
ICON_DIR="/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Assets.xcassets/AppIcon.appiconset"
SRC="/Users/jeongyong/workspace/dailyverse/design-assets/morning manna pkg/morning_mana_app_icon_cutout.png"

# Contents.json에서 사용 중인 파일명 확인
ICON_FILE=$(python3 -c "
import json
with open('$ICON_DIR/Contents.json') as f:
    d = json.load(f)
# 1024×1024 단일 아이콘 파일명
for img in d.get('images', []):
    if img.get('scale') == '1x' and img.get('idiom') == 'universal':
        print(img.get('filename', ''))
        break
# 없으면 첫 번째 파일명
if not True:
    print(d['images'][0].get('filename', 'AppIcon.png'))
")
echo "타겟 아이콘 파일: $ICON_FILE"
```

- [ ] **Step 8-3: Contents.json을 단일 1024 아이콘 구조로 업데이트 (iOS 16+ 방식)**

```bash
ICON_DIR="/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse/Assets.xcassets/AppIcon.appiconset"
SRC="/Users/jeongyong/workspace/dailyverse/design-assets/morning manna pkg/morning_mana_app_icon_cutout.png"

# 기존 아이콘 파일들 백업
mkdir -p "$ICON_DIR/backup"
find "$ICON_DIR" -name "*.png" -exec cp {} "$ICON_DIR/backup/" \;

# Morning Manna 아이콘 복사
cp "$SRC" "$ICON_DIR/AppIcon-mm.png"

# Contents.json 단일 아이콘 구조로 교체
cat > "$ICON_DIR/Contents.json" << 'JSON'
{
  "images" : [
    {
      "filename" : "AppIcon-mm.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON
echo "AppIcon 교체 완료"
ls -la "$ICON_DIR/"
```

- [ ] **Step 8-4: 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add "DailyVerse/DailyVerse/Assets.xcassets/AppIcon.appiconset/"
git commit -m "brand: Morning Manna 앱 아이콘 교체"
```

---

## Task 9: 폰트+pbxproj 최종 커밋

- [ ] **Step 9-1: 폰트 파일 + pbxproj + Info.plist 커밋**

```bash
cd /Users/jeongyong/workspace/dailyverse
git add DailyVerse/DailyVerse/Pretendard* \
        DailyVerse/DailyVerse/NotoSerifKR* \
        DailyVerse/DailyVerse.xcodeproj/project.pbxproj \
        DailyVerse/DailyVerse/Info.plist
git commit -m "feat: Morning Manna 폰트 임베드 — Pretendard + Noto Serif KR"
```

- [ ] **Step 9-2: 전체 변경 확인**

```bash
cd /Users/jeongyong/workspace/dailyverse
git log --oneline -6
echo "---"
# 남은 DailyVerse 문자열 (내부 식별자 제외) 확인
grep -rn '"DailyVerse"' DailyVerse --include="*.swift" \
  | grep -v "NSPersistentContainer\|\.bak"
echo "위 결과가 0줄이어야 합니다"
```

- [ ] **Step 9-3: 푸시**

```bash
cd /Users/jeongyong/workspace/dailyverse
git push origin main
```

---

## 주의 사항

1. **폰트 PostScript 이름**: iOS에서 `Font.custom()` 에 쓰는 이름은 파일명이 아니라 폰트 내부 PostScript 이름. Variable 폰트는 보통 `"PretendardVariable"`, Noto CJK는 `"NotoSerifCJKkr-Regular"`. Task 5-1에서 실제 이름 확인 필수.

2. **NSPersistentContainer(name: "DailyVerse")**: 절대 변경하지 말 것. `.xcdatamodeld` 파일명과 동일해야 Core Data가 작동.

3. **네트워크 오류 시**: Pretendard와 Noto Serif KR 다운로드가 실패하면, 수동으로 GitHub에서 다운로드 후 `DailyVerse/DailyVerse/` 폴더에 넣고 Task 2부터 재개.

4. **Xcode에서 빌드 필수**: pbxproj 변경 후 Xcode에서 Clean Build Folder (⌘+⇧+K) 후 빌드해야 폰트 번들 포함 확인 가능.
