#!/usr/bin/env python3
"""
DailyVerse project.pbxproj 종합 복구 스크립트
git checkout 후 반드시 이 스크립트를 실행해야 합니다.

용도:
  1. git 원본의 malformed WA 항목 3개 수정
  2. 신규 Swift 파일들 빌드 타겟에 등록
  3. Gallery 파일 참조 제거

실행: python3 scripts/fix_pbxproj_complete.py
"""

import sys

path = '/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj'
with open(path) as f:
    content = f.read()

print("=== project.pbxproj 종합 수정 ===\n")

# ──────────────────────────────────────────────────────────
# STEP 1: git 원본 malformed 항목 수정
# ──────────────────────────────────────────────────────────

# 1a) PBXBuildFile 섹션의 중첩 항목 (Lines 19-20 원본)
bad1 = (
    '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = WA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherAdviceService.swift; sourceTree = "<group>"; };\n'
    '\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */; };\n'
)
fix1 = '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = C1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */; };\n'
if bad1 in content:
    content = content.replace(bad1, fix1)
    print("✅ 1a) PBXBuildFile 중첩 수정")
else:
    print("⚠️  1a) 이미 수정됨")

# 1b) Services 그룹 children 안의 인라인 PBXFileReference
bad2 = (
    '\t\t\t\tWA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WeatherAdviceService.swift; sourceTree = "<group>"; };\n'
    '\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */,\n'
)
fix2 = '\t\t\t\tC1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */,\n'
if bad2 in content:
    content = content.replace(bad2, fix2)
    print("✅ 1b) Services 그룹 중첩 수정")
else:
    print("⚠️  1b) 이미 수정됨")

# 1c) Sources 섹션 안의 인라인 PBXBuildFile
bad3 = (
    '\t\t\t\tWA100002WA100002WA100002 /* WeatherAdviceService.swift in Sources */ = {isa = PBXBuildFile; fileRef = WA100001WA100001WA100001 /* WeatherAdviceService.swift */; };\n'
    '\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */,\n'
    '\t\t\t\tWA100002WA100002WA100002 /* WeatherAdviceService.swift in Sources */,\n'
)
fix3 = '\t\t\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */,\n'
if bad3 in content:
    content = content.replace(bad3, fix3)
    # WeatherAdviceService Sources 재추가
    content = content.replace(
        '\t\t\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */,\n',
        '\t\t\t\t1FF7C326A5C192FB8BE58500 /* WeatherService.swift in Sources */,\n'
        '\t\t\t\tWA100002WA100002WA100002 /* WeatherAdviceService.swift in Sources */,\n'
    )
    print("✅ 1c) Sources 섹션 중첩 수정")
else:
    print("⚠️  1c) 이미 수정됨")

# ──────────────────────────────────────────────────────────
# STEP 2: Gallery 제거
# ──────────────────────────────────────────────────────────
if '5BBE906E89F743F09DE20AEC /* GalleryViewModel.swift in Sources */ = {isa = PBXBuildFile' in content:
    content = content.replace(
        '\t\t5BBE906E89F743F09DE20AEC /* GalleryViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0BBE47153FCE4F30946B3242 /* GalleryViewModel.swift */; };\n', ''
    )
    content = content.replace(
        '\t\tD39674E67A7B4197ADB946FE /* GalleryView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A52BFEE375434767B74AA06F /* GalleryView.swift */; };\n', ''
    )
    content = content.replace('\t\t\t\tD39674E67A7B4197ADB946FE /* GalleryView.swift in Sources */,\n', '')
    content = content.replace('\t\t\t\t5BBE906E89F743F09DE20AEC /* GalleryViewModel.swift in Sources */,\n', '')
    print("✅ 2) Gallery 빌드 참조 제거")
else:
    print("⚠️  2) Gallery 이미 제거됨")

# ──────────────────────────────────────────────────────────
# STEP 3: 신규 파일 등록
# ──────────────────────────────────────────────────────────
new_files = [
    # (UUID_REF, UUID_BUILD, 파일명)
    ('A1B2C3D4E5F601020304050A', 'A1B2C3D4E5F601020304050B', 'MeditationEntry.swift'),
    ('A1B2C3D4E5F601020304050C', 'A1B2C3D4E5F601020304050D', 'StreakManager.swift'),
    ('A1B2C3D4E5F601020304050E', 'A1B2C3D4E5F601020304050F', 'MeditationRepository.swift'),
    ('A1B2C3D4E5F601020304051A', 'A1B2C3D4E5F601020304051B', 'MeditationViewModel.swift'),
    ('A1B2C3D4E5F601020304051C', 'A1B2C3D4E5F601020304051D', 'MeditationView.swift'),
    ('A1B2C3D4E5F601020304051E', 'A1B2C3D4E5F601020304051F', 'MeditationWriteSheet.swift'),
    ('AUTH001AUTH001AUTH001AUTH001', 'AUTH002AUTH002AUTH002AUTH002', 'AuthWelcomeView.swift'),
]

# 3a) PBXBuildFile
build_entries = ''
for ref, build, name in new_files:
    if f'{build} /* {name} in Sources */ = {{isa = PBXBuildFile' not in content:
        build_entries += f'\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};\n'
if build_entries:
    content = content.replace(
        '\t\t072B32B990614D39DB0A9B78 /* SettingsView.swift in Sources */ = {isa = PBXBuildFile;',
        build_entries + '\t\t072B32B990614D39DB0A9B78 /* SettingsView.swift in Sources */ = {isa = PBXBuildFile;'
    )
    print(f"✅ 3a) PBXBuildFile {len(build_entries.splitlines())}개 추가")
else:
    print("⚠️  3a) PBXBuildFile 이미 등록됨")

# 3b) PBXFileReference (path = 파일명 패턴으로 체크해 정확히 확인)
ref_entries = ''
for ref, build, name in new_files:
    if f'path = {name}; sourceTree = "<group>"' not in content:
        ref_entries += f'\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};\n'
if ref_entries:
    content = content.replace(
        '/* End PBXFileReference section */',
        ref_entries + '/* End PBXFileReference section */'
    )
    print(f"✅ 3b) PBXFileReference {len(ref_entries.splitlines())}개 추가")
else:
    print("⚠️  3b) PBXFileReference 이미 등록됨")

# 3c) Meditation 그룹
MED_GROUP = 'A1B2C3D4E5F601020304052A'
if f'path = Meditation;' not in content:
    med_group = (
        f'\t\t{MED_GROUP} /* Meditation */ = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = (\n'
        f'\t\t\t\tA1B2C3D4E5F601020304051A /* MeditationViewModel.swift */,\n'
        f'\t\t\t\tA1B2C3D4E5F601020304051C /* MeditationView.swift */,\n'
        f'\t\t\t\tA1B2C3D4E5F601020304051E /* MeditationWriteSheet.swift */,\n'
        f'\t\t\t);\n'
        f'\t\t\tpath = Meditation;\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};\n'
    )
    content = content.replace(
        '\t\tDEEFF164B9331317976C2B9B /* Features */ = {',
        med_group + '\t\tDEEFF164B9331317976C2B9B /* Features */ = {'
    )
    print("✅ 3c) Meditation 그룹 추가")

# Auth 그룹
if f'path = Auth;' not in content:
    AUTH_GROUP = 'AUTH003AUTH003AUTH003AUTH003'
    auth_group = (
        f'\t\t{AUTH_GROUP} /* Auth */ = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = (\n'
        f'\t\t\t\tAUTH001AUTH001AUTH001AUTH001 /* AuthWelcomeView.swift */,\n'
        f'\t\t\t);\n'
        f'\t\t\tpath = Auth;\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};\n'
    )
    content = content.replace(
        '\t\tDEEFF164B9331317976C2B9B /* Features */ = {',
        auth_group + '\t\tDEEFF164B9331317976C2B9B /* Features */ = {'
    )
    print("✅ 3d) Auth 그룹 추가")

# 3e) Models, Managers, Repositories, Features children
if 'A1B2C3D4E5F601020304050A /* MeditationEntry.swift */,' not in content:
    content = content.replace(
        '\t\t\t\tA3664800DCA8F54718AE0379 /* Alarm.swift */,\n',
        '\t\t\t\tA3664800DCA8F54718AE0379 /* Alarm.swift */,\n'
        '\t\t\t\tA1B2C3D4E5F601020304050A /* MeditationEntry.swift */,\n'
    )
if 'A1B2C3D4E5F601020304050C /* StreakManager.swift */,' not in content:
    content = content.replace(
        '\t\t\t\tB113511A4B97FE47D8D0CCE5 /* AdManager.swift */,\n',
        '\t\t\t\tB113511A4B97FE47D8D0CCE5 /* AdManager.swift */,\n'
        '\t\t\t\tA1B2C3D4E5F601020304050C /* StreakManager.swift */,\n'
    )
if 'A1B2C3D4E5F601020304050E /* MeditationRepository.swift */,' not in content:
    content = content.replace(
        '\t\t\t\t883AE40A2F80AF5436D647BF /* AlarmRepository.swift */,\n',
        '\t\t\t\t883AE40A2F80AF5436D647BF /* AlarmRepository.swift */,\n'
        '\t\t\t\tA1B2C3D4E5F601020304050E /* MeditationRepository.swift */,\n'
    )
if 'A1B2C3D4E5F601020304052A /* Meditation */,' not in content:
    content = content.replace(
        '\t\t\t\t51F353101DD50EB0FD099465 /* Alarm */,\n',
        '\t\t\t\t51F353101DD50EB0FD099465 /* Alarm */,\n'
        '\t\t\t\tA1B2C3D4E5F601020304052A /* Meditation */,\n'
    )
if 'AUTH003AUTH003AUTH003AUTH003 /* Auth */,' not in content:
    content = content.replace(
        '\t\t\t\t51F353101DD50EB0FD099465 /* Alarm */,\n',
        '\t\t\t\tAUTH003AUTH003AUTH003AUTH003 /* Auth */,\n'
        '\t\t\t\t51F353101DD50EB0FD099465 /* Alarm */,\n'
    )

# 3f) Sources build phase
sources_to_add = ''
for ref, build, name in new_files:
    if f'{build} /* {name} in Sources */,' not in content:
        sources_to_add += f'\t\t\t\t{build} /* {name} in Sources */,\n'
if sources_to_add:
    content = content.replace(
        '\t\t\t\tB951AE80C46633E6FA2D3313 /* WeatherWidgetView.swift in Sources */,\n',
        '\t\t\t\tB951AE80C46633E6FA2D3313 /* WeatherWidgetView.swift in Sources */,\n' + sources_to_add
    )
    print(f"✅ 3f) Sources {len(sources_to_add.splitlines())}개 추가")

# ──────────────────────────────────────────────────────────
# 저장 + 최종 검증
# ──────────────────────────────────────────────────────────
with open(path, 'w') as f:
    f.write(content)

lines = content.splitlines()
depth = 0
nested = 0
for line in lines:
    for ch in line:
        if ch in '{(': depth += 1
        elif ch in '})': depth -= 1
    if line.strip().count('isa = PBX') > 1:
        nested += 1

print(f"\n=== 최종 검증 ===")
print(f"줄 수: {len(lines)}")
print(f"괄호 밸런스: {depth} {'✅' if depth==0 else '❌ 오류!'}")
print(f"중첩 PBX 항목: {nested} {'✅' if nested==0 else '❌ 오류!'}")

checks = [
    ('MeditationEntry', 'path = MeditationEntry.swift; sourceTree'),
    ('StreakManager', 'path = StreakManager.swift; sourceTree'),
    ('MeditationView', 'path = MeditationView.swift; sourceTree'),
    ('AuthWelcomeView', 'path = AuthWelcomeView.swift; sourceTree'),
    ('Gallery 제거', 'GalleryViewModel.swift in Sources */,' not in content),
]
for name, check in checks:
    if isinstance(check, bool):
        print(f"  {name}: {'✅' if check else '❌'}")
    else:
        print(f"  {name}: {'✅' if check in content else '❌'}")

if depth == 0 and nested == 0:
    print("\n✅ 프로젝트 파일 정상 — Xcode에서 열 수 있습니다")
else:
    print("\n❌ 추가 수정 필요")
    sys.exit(1)
