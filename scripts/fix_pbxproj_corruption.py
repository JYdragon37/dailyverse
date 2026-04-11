#!/usr/bin/env python3
"""
fix_pbxproj_corruption.py
pbxproj의 기존 corruption을 수정 (WeatherService 관련)
"""

PBXPROJ = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj"

def main():
    with open(PBXPROJ, 'r', encoding='utf-8') as f:
        content = f.read()

    # ── Fix 1: WeatherService BuildFile corruption (lines 19-20) ─────────────
    # 깨진 항목:
    # 		1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = WA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherAdviceService.swift; sourceTree = "<group>"; };
    # 		C1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */; };
    # → 정상 항목으로 교체

    corrupt_build = (
        '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = WA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherAdviceService.swift; sourceTree = "<group>"; };\n'
        '\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */; };'
    )
    fixed_build = '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = C1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */; };'

    if corrupt_build in content:
        content = content.replace(corrupt_build, fixed_build)
        print("✅ WeatherService BuildFile corruption 수정")
    else:
        print("⚠️  WeatherService BuildFile corruption 없음 (이미 수정됨)")

    # ── Fix 2: Services group corruption ─────────────────────────────────────
    # 깨진 항목 (Services 그룹 내):
    # WA100001... FileReference 정의가 children 안에 포함됨
    # C1BB2A3C4... WeatherService 줄 들여쓰기 오류
    corrupt_services = (
        '\t\t\t\tWA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherAdviceService.swift; sourceTree = "<group>"; };\n'
        '\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */,\n'
        '\t\t\t\tWA100001WA100001WA100001 /* WeatherAdviceService.swift */,'
    )
    fixed_services = (
        '\t\t\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */,\n'
        '\t\t\t\tWA100001WA100001WA100001 /* WeatherAdviceService.swift */,'
    )

    if corrupt_services in content:
        content = content.replace(corrupt_services, fixed_services)
        print("✅ Services group corruption 수정")
    else:
        print("⚠️  Services group corruption 없음 (이미 수정됨)")

    # ── FileReference: WeatherService.swift 확인 ─────────────────────────────
    # C1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */ FileRef가 있어야 함
    if 'C1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */ = {isa = PBXFileReference' not in content:
        # SavedView FileRef 앞에 추가
        anchor = '\t\t5E61A63D33E6A03DA92C092E /* SavedView.swift */ = {isa = PBXFileReference;'
        if anchor in content:
            ws_ref = '\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherService.swift; sourceTree = "<group>"; };\n'
            content = content.replace(anchor, ws_ref + anchor)
            print("✅ WeatherService.swift FileReference 추가")
    else:
        print("⚠️  WeatherService.swift FileReference 이미 존재")

    # ── 괄호 검증 ─────────────────────────────────────────────────────────────
    ob, cb = content.count('{'), content.count('}')
    op, cp = content.count('('), content.count(')')
    if ob != cb:
        print(f"❌ 중괄호 불균형: {{ {ob} vs }} {cb}")
        return
    if op != cp:
        print(f"❌ 소괄호 불균형: ( {op} vs ) {cp}")
        return
    print("✅ 괄호 균형 통과")

    with open(PBXPROJ, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ 저장 완료")

if __name__ == '__main__':
    main()
