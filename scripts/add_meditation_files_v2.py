#!/usr/bin/env python3
"""
add_meditation_files_v2.py
Meditation/Devotion 파일들을 Xcode project.pbxproj에 추가
"""

import sys

PBXPROJ = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj"

# ─── UUID 정의 (24자 순수 hex) ──────────────────────────────────────────────

FILES = [
    # fileRefUUID,                   buildFileUUID,                 filename
    ("A2000001A2000001A2000001", "A3000001A3000001A3000001", "MeditationEntry.swift"),
    ("A2000002A2000002A2000002", "A3000002A3000002A3000002", "MeditationRepository.swift"),
    ("A2000003A2000003A2000003", "A3000003A3000003A3000003", "StreakManager.swift"),
    ("A2000004A2000004A2000004", "A3000004A3000004A3000004", "MeditationView.swift"),
    ("A2000005A2000005A2000005", "A3000005A3000005A3000005", "MeditationViewModel.swift"),
    ("A2000006A2000006A2000006", "A3000006A3000006A3000006", "MeditationWriteSheet.swift"),
    ("A2000007A2000007A2000007", "A3000007A3000007A3000007", "DevotionHomeView.swift"),
    ("A2000008A2000008A2000008", "A3000008A3000008A3000008", "DevotionVerseView.swift"),
    ("A2000009A2000009A2000009", "A3000009A3000009A3000009", "DevotionResponseView.swift"),
    ("A200000AA200000AA200000A", "A300000AA300000AA300000A", "DevotionCompleteView.swift"),
    ("A200000BA200000BA200000B", "A300000BA300000BA300000B", "DevotionShareCard.swift"),
]

MEDITATION_GROUP_UUID = "A4000001A4000001A4000001"

# Meditation 뷰 파일들 (그룹에 들어갈 것들)
MEDITATION_VIEW_FILES = [
    "A2000004A2000004A2000004",  # MeditationView.swift
    "A2000005A2000005A2000005",  # MeditationViewModel.swift
    "A2000006A2000006A2000006",  # MeditationWriteSheet.swift
    "A2000007A2000007A2000007",  # DevotionHomeView.swift
    "A2000008A2000008A2000008",  # DevotionVerseView.swift
    "A2000009A2000009A2000009",  # DevotionResponseView.swift
    "A200000AA200000AA200000A",  # DevotionCompleteView.swift
    "A200000BA200000BA200000B",  # DevotionShareCard.swift
]

def validate():
    for ref, build, name in FILES:
        assert len(ref) == 24, f"UUID length error: {ref}"
        assert len(build) == 24, f"UUID length error: {build}"
        for c in ref + build:
            assert c in '0123456789ABCDEFabcdef', f"Non-hex char '{c}' in UUID"
    print("✅ UUID 검증 통과")

def main():
    validate()

    with open(PBXPROJ, 'r', encoding='utf-8') as f:
        content = f.read()

    if "MeditationView.swift" in content:
        print("⚠️  이미 등록됨. 스킵.")
        return

    # ── 1. PBXBuildFile 섹션에 추가 ──────────────────────────────────────────
    build_entries = ""
    for ref, build, name in FILES:
        build_entries += f"\n\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};"

    # 앵커: SavedView.swift in Sources (BuildFile 섹션)
    anchor_bf = "\t\tC0D6D65B97AB39E715DF88D4 /* SavedView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 5E61A63D33E6A03DA92C092E /* SavedView.swift */; };"
    if anchor_bf not in content:
        print("❌ PBXBuildFile 앵커 없음"); sys.exit(1)
    content = content.replace(anchor_bf, anchor_bf + build_entries)
    print("✅ PBXBuildFile 추가")

    # ── 2. PBXFileReference 섹션에 추가 ──────────────────────────────────────
    ref_entries = ""
    for ref, build, name in FILES:
        ref_entries += f"\n\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};"

    # 앵커: SavedView.swift FileReference
    anchor_fr = "\t\t5E61A63D33E6A03DA92C092E /* SavedView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SavedView.swift; sourceTree = \"<group>\"; };"
    if anchor_fr not in content:
        print("❌ PBXFileReference 앵커 없음"); sys.exit(1)
    content = content.replace(anchor_fr, anchor_fr + ref_entries)
    print("✅ PBXFileReference 추가")

    # ── 3. Meditation 그룹 생성 ───────────────────────────────────────────────
    group_children = "\n".join(
        f"\t\t\t\t{ref} /* {name} */,"
        for ref, build, name in FILES
        if ref in MEDITATION_VIEW_FILES
    )
    meditation_group = f"""
\t\t{MEDITATION_GROUP_UUID} /* Meditation */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{chr(10).join(
    f"{ref} /* {name} */,"
    for ref, build, name in FILES
    if ref in MEDITATION_VIEW_FILES
)}
\t\t\t);
\t\t\tpath = Meditation;
\t\t\tsourceTree = "<group>";
\t\t}};"""

    # Features 그룹 (DEEFF164) 안에 Meditation 추가
    # 앵커: Settings 그룹 레퍼런스
    anchor_fg = "\t\t\t\tA43B0E4BCF0ACE7B1C50A3F7 /* Settings */,"
    if anchor_fg not in content:
        print("❌ Features 그룹 앵커 없음"); sys.exit(1)
    content = content.replace(
        anchor_fg,
        f"\t\t\t\t{MEDITATION_GROUP_UUID} /* Meditation */,\n{anchor_fg}"
    )

    # 그룹 정의를 PBXGroup 섹션에 추가 (Settings 그룹 뒤)
    settings_group_end = """\t\t\tpath = Settings;
\t\t\tsourceTree = "<group>";
\t\t};"""
    if settings_group_end not in content:
        print("❌ Settings 그룹 끝 앵커 없음"); sys.exit(1)

    # Meditation 그룹 정의 텍스트
    med_group_text = f"""
\t\t{MEDITATION_GROUP_UUID} /* Meditation */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ("""
    for ref, build, name in FILES:
        if ref in MEDITATION_VIEW_FILES:
            med_group_text += f"\n\t\t\t\t{ref} /* {name} */,"
    med_group_text += f"""
\t\t\t);
\t\t\tpath = Meditation;
\t\t\tsourceTree = "<group>";
\t\t}};"""

    content = content.replace(settings_group_end, settings_group_end + med_group_text)
    print("✅ Meditation 그룹 생성")

    # ── 4. Models 그룹에 MeditationEntry 추가 ────────────────────────────────
    # 앵커: User.swift in Models
    anchor_models = "\t\t\t\tB24AF2F893CA3C34B471EA3B /* User.swift */,"
    if anchor_models not in content:
        print("❌ Models 그룹 앵커 없음"); sys.exit(1)
    content = content.replace(
        anchor_models,
        f"\t\t\t\tA2000001A2000001A2000001 /* MeditationEntry.swift */,\n{anchor_models}"
    )
    print("✅ MeditationEntry → Models 추가")

    # ── 5. Repositories 그룹에 MeditationRepository 추가 ─────────────────────
    anchor_repos = "\t\t\t\tF97449D55F8DB9F917F590C3 /* SavedVerseRepository.swift */,"
    if anchor_repos not in content:
        print("❌ Repositories 그룹 앵커 없음"); sys.exit(1)
    content = content.replace(
        anchor_repos,
        f"\t\t\t\tA2000002A2000002A2000002 /* MeditationRepository.swift */,\n{anchor_repos}"
    )
    print("✅ MeditationRepository → Repositories 추가")

    # ── 6. Managers 그룹에 StreakManager 추가 ────────────────────────────────
    anchor_mgrs = "\t\t\t\tDC574AED1BAE4561C1662061 /* UpsellManager.swift */,"
    if anchor_mgrs not in content:
        print("❌ Managers 그룹 앵커 없음"); sys.exit(1)
    content = content.replace(
        anchor_mgrs,
        f"\t\t\t\tA2000003A2000003A2000003 /* StreakManager.swift */,\n{anchor_mgrs}"
    )
    print("✅ StreakManager → Managers 추가")

    # ── 7. Sources Build Phase에 추가 ─────────────────────────────────────────
    sources_entries = ""
    for ref, build, name in FILES:
        sources_entries += f"\n\t\t\t\t{build} /* {name} in Sources */,"

    anchor_src = "\t\t\t\tC0D6D65B97AB39E715DF88D4 /* SavedView.swift in Sources */,"
    if anchor_src not in content:
        print("❌ Sources 앵커 없음"); sys.exit(1)
    content = content.replace(anchor_src, anchor_src + sources_entries)
    print("✅ Sources Build Phase 추가")

    # ── 괄호 검증 ─────────────────────────────────────────────────────────────
    ob, cb = content.count('{'), content.count('}')
    op, cp = content.count('('), content.count(')')
    if ob != cb:
        print(f"❌ 중괄호 불균형: {{ {ob} vs }} {cb}"); sys.exit(1)
    if op != cp:
        print(f"❌ 소괄호 불균형: ( {op} vs ) {cp}"); sys.exit(1)
    print("✅ 괄호 균형 검증 통과")

    with open(PBXPROJ, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ project.pbxproj 저장 완료")
    print(f"\n총 {len(FILES)}개 파일 추가됨")

if __name__ == '__main__':
    main()
