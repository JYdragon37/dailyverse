#!/usr/bin/env python3
"""
add_devotion_files.py
5개 Devotion Swift 파일을 Xcode project.pbxproj에 안전하게 추가
"""

import re
import sys

PBXPROJ = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj"

# 신규 파일 정보 (fileRef UUID, buildFile UUID, filename)
NEW_FILES = [
    ("A1B2C3D4E5F60102030405A0", "A1B2C3D4E5F60102030405A1", "DevotionHomeView.swift"),
    ("A1B2C3D4E5F60102030405A2", "A1B2C3D4E5F60102030405A3", "DevotionVerseView.swift"),
    ("A1B2C3D4E5F60102030405A4", "A1B2C3D4E5F60102030405A5", "DevotionResponseView.swift"),
    ("A1B2C3D4E5F60102030405A6", "A1B2C3D4E5F60102030405A7", "DevotionCompleteView.swift"),
    ("A1B2C3D4E5F60102030405A8", "A1B2C3D4E5F60102030405A9", "DevotionShareCard.swift"),
]

# 기존 앵커 (이 뒤에 삽입)
ANCHOR_BUILD_FILE  = 'A1B2C3D4E5F601020304051F /* MeditationWriteSheet.swift in Sources */'
ANCHOR_FILE_REF    = 'A1B2C3D4E5F601020304051E /* MeditationWriteSheet.swift */'
ANCHOR_GROUP       = 'A1B2C3D4E5F601020304051E /* MeditationWriteSheet.swift */,'
ANCHOR_SOURCES     = 'A1B2C3D4E5F601020304051F /* MeditationWriteSheet.swift in Sources */,'

def validate_uuids():
    for ref, build, name in NEW_FILES:
        assert len(ref) == 24 and all(c in '0123456789ABCDEFabcdef' for c in ref), f"Invalid UUID: {ref}"
        assert len(build) == 24 and all(c in '0123456789ABCDEFabcdef' for c in build), f"Invalid UUID: {build}"
    print("✅ UUID 검증 통과")

def main():
    validate_uuids()

    with open(PBXPROJ, 'r', encoding='utf-8') as f:
        content = f.read()

    # 이미 추가됐는지 확인
    if "DevotionHomeView.swift" in content:
        print("⚠️  DevotionHomeView.swift 이미 등록됨. 스킵.")
        return

    # ── 1. PBXBuildFile section에 추가 ────────────────────────────────────
    build_file_entries = ""
    for ref, build, name in NEW_FILES:
        build_file_entries += f"\n\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};"

    # 앵커 뒤에 삽입
    anchor_bf = f"\t\t{ANCHOR_BUILD_FILE} = {{isa = PBXBuildFile; fileRef = A1B2C3D4E5F601020304051E /* MeditationWriteSheet.swift */; }};"
    if anchor_bf in content:
        content = content.replace(anchor_bf, anchor_bf + build_file_entries)
        print("✅ PBXBuildFile 추가 완료")
    else:
        print(f"❌ PBXBuildFile 앵커를 찾지 못함")
        sys.exit(1)

    # ── 2. PBXFileReference section에 추가 ───────────────────────────────
    file_ref_entries = ""
    for ref, build, name in NEW_FILES:
        file_ref_entries += f"\n\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};"

    anchor_fr = f"\t\t{ANCHOR_FILE_REF} /* MeditationWriteSheet.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MeditationWriteSheet.swift; sourceTree = \"<group>\"; }};"
    if anchor_fr in content:
        content = content.replace(anchor_fr, anchor_fr + file_ref_entries)
        print("✅ PBXFileReference 추가 완료")
    else:
        print(f"❌ PBXFileReference 앵커를 찾지 못함")
        sys.exit(1)

    # ── 3. PBXGroup (Meditation 폴더)에 추가 ─────────────────────────────
    group_entries = ""
    for ref, build, name in NEW_FILES:
        group_entries += f"\n\t\t\t\t{ref} /* {name} */,"

    anchor_g = f"\t\t\t\tA1B2C3D4E5F601020304051E /* MeditationWriteSheet.swift */,"
    if anchor_g in content:
        content = content.replace(anchor_g, anchor_g + group_entries)
        print("✅ PBXGroup 추가 완료")
    else:
        print(f"❌ PBXGroup 앵커를 찾지 못함")
        sys.exit(1)

    # ── 4. PBXSourcesBuildPhase에 추가 ────────────────────────────────────
    sources_entries = ""
    for ref, build, name in NEW_FILES:
        sources_entries += f"\n\t\t\t\t{build} /* {name} in Sources */,"

    anchor_s = f"\t\t\t\tA1B2C3D4E5F601020304051F /* MeditationWriteSheet.swift in Sources */,"
    if anchor_s in content:
        content = content.replace(anchor_s, anchor_s + sources_entries)
        print("✅ PBXSourcesBuildPhase 추가 완료")
    else:
        print(f"❌ PBXSourcesBuildPhase 앵커를 찾지 못함")
        sys.exit(1)

    # ── 괄호 균형 검증 ────────────────────────────────────────────────────
    open_braces  = content.count('{')
    close_braces = content.count('}')
    open_parens  = content.count('(')
    close_parens = content.count(')')
    if open_braces != close_braces:
        print(f"❌ 괄호 불균형: {{ {open_braces} vs }} {close_braces}")
        sys.exit(1)
    if open_parens != close_parens:
        print(f"❌ 괄호 불균형: ( {open_parens} vs ) {close_parens}")
        sys.exit(1)
    print("✅ 괄호 균형 검증 통과")

    # ── 파일 저장 ─────────────────────────────────────────────────────────
    with open(PBXPROJ, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ project.pbxproj 저장 완료")

if __name__ == '__main__':
    main()
