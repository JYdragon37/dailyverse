#!/usr/bin/env python3
"""
Fix DailyVerse project.pbxproj parse error.

Problems fixed:
1. Inline PBXBuildFile definitions embedded inside PBXSourcesBuildPhase files array
2. Invalid UUIDs containing non-hex characters (AUTH*, WA*)
"""

import re
import sys

PBXPROJ = '/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj'

with open(PBXPROJ, 'r') as f:
    content = f.read()

original = content

# ── Fix 1: Remove inline PBXBuildFile defs inside the files array ─────────────
# Lines 741-747 have object definitions (= {isa = PBXBuildFile; ...};)
# embedded inside a files = (...) array, which is invalid pbxproj syntax.
# The meditation files are already correctly listed at lines 772-777.

bad_block = (
    '\t\t\t\tA1B2C3D4E5F601020304050B /* MeditationEntry.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1B2C3D4E5F601020304050A /* MeditationEntry.swift */; };\n'
    '\t\tA1B2C3D4E5F601020304050D /* StreakManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1B2C3D4E5F601020304050C /* StreakManager.swift */; };\n'
    '\t\tA1B2C3D4E5F601020304050F /* MeditationRepository.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1B2C3D4E5F601020304050E /* MeditationRepository.swift */; };\n'
    '\t\tA1B2C3D4E5F601020304051B /* MeditationViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1B2C3D4E5F601020304051A /* MeditationViewModel.swift */; };\n'
    '\t\tA1B2C3D4E5F601020304051D /* MeditationView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1B2C3D4E5F601020304051C /* MeditationView.swift */; };\n'
    '\t\tA1B2C3D4E5F601020304051F /* MeditationWriteSheet.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1B2C3D4E5F601020304051E /* MeditationWriteSheet.swift */; };\n'
    '\t\t072B32B990614D39DB0A9B78 /* SettingsView.swift in Sources */,'
)
good_replacement = '\t\t\t\t072B32B990614D39DB0A9B78 /* SettingsView.swift in Sources */,'

if bad_block in content:
    content = content.replace(bad_block, good_replacement)
    print('[Fix 1] Removed inline PBXBuildFile definitions from files array')
else:
    print('[Fix 1] WARNING: bad_block not found — skipping')

# ── Fix 2: Replace invalid UUIDs (containing non-hex chars U, T, H, W) ────────
# Valid Xcode UUID = 24 hex chars [0-9A-F]
uuid_replacements = {
    'AUTH001AUTH001AUTH001AUTH001': 'A8B3C2D1E4F5A8B3C2D1E4F5',  # AuthWelcomeView fileRef
    'AUTH002AUTH002AUTH002AUTH002': 'A8B3C2D1E4F5A8B3C2D1E4F6',  # AuthWelcomeView buildFile
    'AUTH003AUTH003AUTH003AUTH003': 'A8B3C2D1E4F5A8B3C2D1E4F7',  # Auth PBXGroup
    'WA100001WA100001WA100001':     'BA20000CBA20000CBA20000C',  # WeatherAdviceService fileRef
    'WA100002WA100002WA100002':     'BA20000DBA20000DBA20000D',  # WeatherAdviceService buildFile
}

for old, new in uuid_replacements.items():
    count = content.count(old)
    if count > 0:
        content = content.replace(old, new)
        print(f'[Fix 2] Replaced {old} → {new}  ({count} occurrence(s))')
    else:
        print(f'[Fix 2] WARNING: {old} not found')

# ── Validate: brace balance ───────────────────────────────────────────────────
opens = content.count('{')
closes = content.count('}')
if opens != closes:
    print(f'\nERROR: Brace mismatch after fix! {{ = {opens}, }} = {closes}')
    sys.exit(1)
else:
    print(f'\n[Validate] Braces balanced: {{ = {opens}, }} = {closes} ✓')

# ── Write fixed file ──────────────────────────────────────────────────────────
if content == original:
    print('\nNo changes made (all patterns already fixed or not found).')
else:
    with open(PBXPROJ, 'w') as f:
        f.write(content)
    print(f'\nFixed file written to {PBXPROJ}')
