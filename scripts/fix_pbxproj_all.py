#!/usr/bin/env python3
"""
fix_pbxproj_all.py
pbxproj 전체 수정 — 한 번에 모든 문제 해결
1. 기존 corruption 수정 (WeatherService, WeatherAdvice, Services group)
2. Gallery 파일 제거 (파일 삭제됨)
3. Meditation/Devotion 파일 11개 추가
4. Auth 파일 추가 (AuthWelcomeView.swift)
"""

import sys

PBXPROJ = "/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj"

# ─── 새 파일 정의 ──────────────────────────────────────────────────────────────
MEDITATION_FILES = [
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
MEDITATION_VIEW_REFS = {f[0] for f in MEDITATION_FILES[3:]}  # View files (not Model/Repo/Manager)

AUTH_FILE_REF   = "A5000001A5000001A5000001"
AUTH_BUILD_FILE = "A6000001A6000001A6000001"
AUTH_GROUP_UUID = "A7000001A7000001A7000001"

def add_after(content, anchor, addition, replace_first_only=True):
    """anchor 바로 뒤에 addition을 삽입. replace_first_only=True면 첫 번째 일치만."""
    idx = content.find(anchor)
    if idx == -1:
        return None, False
    pos = idx + len(anchor)
    return content[:pos] + addition + content[pos:], True

def remove_line(content, line_text):
    """정확히 일치하는 라인(개행 포함) 제거."""
    for ending in ['\n', '']:
        target = line_text + ending
        if target in content:
            return content.replace(target, '', 1), True
    return content, False

def main():
    with open(PBXPROJ, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'MeditationView.swift' in content:
        print("⚠️  이미 적용됨. 스킵.")
        return

    print("=== 1. 기존 Corruption 수정 ===")

    # Fix 1: WeatherService BuildFile corruption
    corrupt_ws_bf = (
        '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = WA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherAdviceService.swift; sourceTree = "<group>"; };\n'
        '\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */; };'
    )
    if corrupt_ws_bf in content:
        content = content.replace(corrupt_ws_bf,
            '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = C1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */; };')
        print("✅ WeatherService BuildFile 수정")

    # Fix 2: Services group corruption
    corrupt_svc = (
        '\t\t\t\tWA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherAdviceService.swift; sourceTree = "<group>"; };\n'
        '\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */,\n'
        '\t\t\t\tWA100001WA100001WA100001 /* WeatherAdviceService.swift */,'
    )
    if corrupt_svc in content:
        content = content.replace(corrupt_svc,
            '\t\t\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */,\n'
            '\t\t\t\tWA100001WA100001WA100001 /* WeatherAdviceService.swift */,')
        print("✅ Services group 수정")

    # Fix 3: Sources build phase corruption
    corrupt_src = (
        '\t\t\t\tWA100002WA100002WA100002 /* WeatherAdviceService.swift in Sources */ = {isa = PBXBuildFile; fileRef = WA100001WA100001WA100001 /* WeatherAdviceService.swift */; };\n'
        '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */,\n'
        '\t\t\t\tWA100002WA100002WA100002 /* WeatherAdviceService.swift in Sources */,'
    )
    if corrupt_src in content:
        content = content.replace(corrupt_src,
            '\t\t\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */,\n'
            '\t\t\t\tWA100002WA100002WA100002 /* WeatherAdviceService.swift in Sources */,')
        print("✅ Sources build phase 수정")

    print("\n=== 2. Gallery 파일 제거 ===")
    for line in [
        '\t\t5BBE906E89F743F09DE20AEC /* GalleryViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0BBE47153FCE4F30946B3242 /* GalleryViewModel.swift */; };\n',
        '\t\tD39674E67A7B4197ADB946FE /* GalleryView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A52BFEE375434767B74AA06F /* GalleryView.swift */; };\n',
        '\t\t0BBE47153FCE4F30946B3242 /* GalleryViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GalleryViewModel.swift; sourceTree = "<group>"; };\n',
        '\t\tA52BFEE375434767B74AA06F /* GalleryView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GalleryView.swift; sourceTree = "<group>"; };\n',
        '\t\t\t\tA52BFEE375434767B74AA06F /* GalleryView.swift */,\n',
        '\t\t\t\t0BBE47153FCE4F30946B3242 /* GalleryViewModel.swift */,\n',
        '\t\t\t\tD39674E67A7B4197ADB946FE /* GalleryView.swift in Sources */,\n',
        '\t\t\t\t5BBE906E89F743F09DE20AEC /* GalleryViewModel.swift in Sources */,\n',
    ]:
        if line in content:
            content = content.replace(line, '')
    print("✅ Gallery 파일 제거")

    print("\n=== 3. Meditation/Devotion 파일 추가 ===")

    # 3a. PBXBuildFile entries
    bf_entries = ''.join(
        f'\n\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};'
        for ref, build, name in MEDITATION_FILES
    )
    # SavedView BuildFile 항목 뒤에 추가 (고유한 전체 문자열 사용)
    anchor = '\t\tC0D6D65B97AB39E715DF88D4 /* SavedView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 5E61A63D33E6A03DA92C092E /* SavedView.swift */; };'
    if anchor in content:
        content = content.replace(anchor, anchor + bf_entries)
        print("✅ PBXBuildFile 추가")
    else:
        print("❌ PBXBuildFile 앵커 없음"); sys.exit(1)

    # 3b. PBXFileReference entries
    fr_entries = ''.join(
        f'\n\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};'
        for ref, build, name in MEDITATION_FILES
    )
    # SavedView FileRef 항목 뒤에 추가 (고유한 전체 문자열 사용)
    anchor_fr = '\t\t5E61A63D33E6A03DA92C092E /* SavedView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SavedView.swift; sourceTree = "<group>"; };'
    if anchor_fr in content:
        content = content.replace(anchor_fr, anchor_fr + fr_entries)
        print("✅ PBXFileReference 추가")
    else:
        print("❌ PBXFileReference 앵커 없음"); sys.exit(1)

    # 3c. Meditation group definition
    med_children = ''.join(
        f'\n\t\t\t\t{ref} /* {name} */,'
        for ref, build, name in MEDITATION_FILES
        if ref in MEDITATION_VIEW_REFS
    )
    med_group = (
        f'\n\t\t{MEDITATION_GROUP_UUID} /* Meditation */ = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = ({med_children}\n'
        f'\t\t\t);\n'
        f'\t\t\tpath = Meditation;\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};'
    )
    # Settings 그룹 끝 뒤에 삽입
    anchor_settings_end = '\t\t\tpath = Settings;\n\t\t\tsourceTree = "<group>";\n\t\t};'
    if anchor_settings_end in content:
        content = content.replace(anchor_settings_end, anchor_settings_end + med_group)
        print("✅ Meditation 그룹 정의 추가")
    else:
        print("❌ Settings 그룹 끝 앵커 없음"); sys.exit(1)

    # 3d. Meditation group reference in Features group
    anchor_features = '\t\t\t\tA43B0E4BCF0ACE7B1C50A3F7 /* Settings */,'
    if anchor_features in content:
        content = content.replace(anchor_features,
            f'\t\t\t\t{MEDITATION_GROUP_UUID} /* Meditation */,\n{anchor_features}')
        print("✅ Meditation → Features 추가")
    else:
        print("❌ Features 앵커 없음"); sys.exit(1)

    # 3e. MeditationEntry → Models group
    anchor_models = '\t\t\t\tB24AF2F893CA3C34B471EA3B /* User.swift */,'
    if anchor_models in content:
        content = content.replace(anchor_models,
            f'\t\t\t\tA2000001A2000001A2000001 /* MeditationEntry.swift */,\n{anchor_models}')
        print("✅ MeditationEntry → Models")

    # 3f. MeditationRepository → Repositories group
    anchor_repos = '\t\t\t\tF97449D55F8DB9F917F590C3 /* SavedVerseRepository.swift */,'
    if anchor_repos in content:
        content = content.replace(anchor_repos,
            f'\t\t\t\tA2000002A2000002A2000002 /* MeditationRepository.swift */,\n{anchor_repos}')
        print("✅ MeditationRepository → Repositories")

    # 3g. StreakManager → Managers group
    anchor_mgrs = '\t\t\t\tDC574AED1BAE4561C1662061 /* UpsellManager.swift */,'
    if anchor_mgrs in content:
        content = content.replace(anchor_mgrs,
            f'\t\t\t\tA2000003A2000003A2000003 /* StreakManager.swift */,\n{anchor_mgrs}')
        print("✅ StreakManager → Managers")

    # 3h. Sources build phase
    src_entries = ''.join(
        f'\n\t\t\t\t{build} /* {name} in Sources */,'
        for ref, build, name in MEDITATION_FILES
    )
    # 고유한 Sources 앵커 사용
    anchor_src = '\t\t\t\tC0D6D65B97AB39E715DF88D4 /* SavedView.swift in Sources */,'
    if anchor_src in content:
        content = content.replace(anchor_src, anchor_src + src_entries)
        print("✅ Sources build phase 추가")
    else:
        print("❌ Sources 앵커 없음"); sys.exit(1)

    print("\n=== 4. Auth 파일 추가 ===")

    # Auth BuildFile (고유한 전체 문자열 앵커 사용)
    auth_bf = f'\n\t\t{AUTH_BUILD_FILE} /* AuthWelcomeView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {AUTH_FILE_REF} /* AuthWelcomeView.swift */; }};'
    anchor_auth_bf = '\t\tC0D6D65B97AB39E715DF88D4 /* SavedView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 5E61A63D33E6A03DA92C092E /* SavedView.swift */; };'
    if anchor_auth_bf in content:
        content = content.replace(anchor_auth_bf, anchor_auth_bf + auth_bf)
        print("✅ Auth BuildFile 추가")

    # Auth FileReference
    auth_fr = f'\n\t\t{AUTH_FILE_REF} /* AuthWelcomeView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AuthWelcomeView.swift; sourceTree = "<group>"; }};'
    anchor_auth_fr = '\t\t5E61A63D33E6A03DA92C092E /* SavedView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SavedView.swift; sourceTree = "<group>"; };'
    if anchor_auth_fr in content:
        content = content.replace(anchor_auth_fr, anchor_auth_fr + auth_fr)
        print("✅ Auth FileReference 추가")

    # Auth group definition
    auth_group = (
        f'\n\t\t{AUTH_GROUP_UUID} /* Auth */ = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = (\n'
        f'\t\t\t\t{AUTH_FILE_REF} /* AuthWelcomeView.swift */,\n'
        f'\t\t\t);\n'
        f'\t\t\tpath = Auth;\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};'
    )
    anchor_auth_group_after = '\t\t\tpath = Settings;\n\t\t\tsourceTree = "<group>";\n\t\t};'
    if anchor_auth_group_after in content:
        content = content.replace(anchor_auth_group_after, anchor_auth_group_after + auth_group)
        print("✅ Auth 그룹 정의 추가")

    # Auth group reference in Features
    anchor_auth_feat = f'\t\t\t\t{MEDITATION_GROUP_UUID} /* Meditation */,'
    if anchor_auth_feat in content:
        content = content.replace(anchor_auth_feat,
            f'\t\t\t\t{AUTH_GROUP_UUID} /* Auth */,\n\t\t\t\t{MEDITATION_GROUP_UUID} /* Meditation */,')
        print("✅ Auth → Features 추가")

    # Auth Sources
    auth_src = f'\n\t\t\t\t{AUTH_BUILD_FILE} /* AuthWelcomeView.swift in Sources */,'
    anchor_auth_src = '\t\t\t\tC0D6D65B97AB39E715DF88D4 /* SavedView.swift in Sources */,'
    if anchor_auth_src in content:
        content = content.replace(anchor_auth_src, anchor_auth_src + auth_src)
        print("✅ Auth Sources 추가")

    print("\n=== 검증 ===")
    ob, cb = content.count('{'), content.count('}')
    op, cp = content.count('('), content.count(')')
    if ob != cb:
        print(f"❌ 중괄호 불균형: {ob} vs {cb}"); sys.exit(1)
    if op != cp:
        print(f"❌ 소괄호 불균형: {op} vs {cp}"); sys.exit(1)
    print(f"✅ 괄호 균형 ({ob}/{cb}, {op}/{cp})")

    with open(PBXPROJ, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ project.pbxproj 저장 완료")

if __name__ == '__main__':
    main()
