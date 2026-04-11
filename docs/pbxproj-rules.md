# project.pbxproj 수정 규칙

> **이 파일을 어기면 Xcode에서 프로젝트가 열리지 않습니다.**
> 위반 시 에러: `The project 'DailyVerse' is damaged and cannot be opened due to a parse error.`

---

## 절대 금지 사항

| 금지 행위 | 이유 |
|-----------|------|
| 에이전트(서브 에이전트 포함)에게 pbxproj 직접 수정 지시 | 인라인 삽입, UUID 오타 등 구조 파괴 발생 |
| `Edit` 툴로 pbxproj 직접 편집 | 복잡한 중첩 구조에서 컨텍스트 오류 발생 |
| 검증 없이 스크립트 실행 | 괄호 불균형 시 파일 완전 손상 |
| 유효하지 않은 UUID 사용 | Xcode UUID는 반드시 **24자리 16진수** [0-9A-F] |

---

## pbxproj 구조 규칙

### 1. UUID 형식
```
올바른 형식: A8B3C2D1E4F5A8B3C2D1E4F5  (24자, 0-9 A-F만)
잘못된 형식: AUTH001AUTH001AUTH001AUTH001  (U,T,H는 16진수 아님)
잘못된 형식: WA100001WA100001WA100001      (W는 16진수 아님)
```

### 2. 배열 vs 객체 정의 위치

**PBXBuildFile 섹션** — 객체 정의는 여기에만:
```
/* Begin PBXBuildFile section */
    UUID_BUILD /* Foo.swift in Sources */ = {isa = PBXBuildFile; fileRef = UUID_REF /* Foo.swift */; };
/* End PBXBuildFile section */
```

**PBXSourcesBuildPhase files 배열** — ID 참조만, 정의 절대 금지:
```
files = (
    UUID_BUILD /* Foo.swift in Sources */,   ← 이것만 허용
    UUID_BUILD /* Foo.swift in Sources */ = {isa = PBXBuildFile; ...};  ← 절대 금지!
);
```

### 3. 새 파일 등록 시 수정해야 할 4개 위치
1. `PBXBuildFile section` — 빌드 파일 정의
2. `PBXFileReference section` — 파일 참조 정의
3. 해당 `PBXGroup children` — 그룹에 파일 추가
4. `PBXSourcesBuildPhase files` — 컴파일 대상 추가

---

## 올바른 수정 방법

### Python 스크립트 템플릿

```python
PBXPROJ = '/Users/jeongyong/workspace/dailyverse/DailyVerse/DailyVerse.xcodeproj/project.pbxproj'

with open(PBXPROJ, 'r') as f:
    content = f.read()

UUID_REF   = 'REPLACE_WITH_24_HEX'   # fileRef UUID
UUID_BUILD = 'REPLACE_WITH_24_HEX'   # buildFile UUID

# 1. PBXBuildFile 섹션
content = content.replace(
    '/* Begin PBXBuildFile section */',
    '/* Begin PBXBuildFile section */\n'
    f'\t\t{UUID_BUILD} /* Foo.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {UUID_REF} /* Foo.swift */; }};'
)

# 2. PBXFileReference 섹션
content = content.replace(
    '/* End PBXFileReference section */',
    f'\t\t{UUID_REF} /* Foo.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Foo.swift; sourceTree = "<group>"; }};\n'
    '/* End PBXFileReference section */'
)

# 3. PBXGroup children (기존 항목 앞에 삽입)
content = content.replace(
    '\t\t\t\tSOME_EXISTING_UUID /* ExistingFile.swift */,',
    f'\t\t\t\t{UUID_REF} /* Foo.swift */,\n'
    '\t\t\t\tSOME_EXISTING_UUID /* ExistingFile.swift */,'
)

# 4. PBXSourcesBuildPhase files (ID 참조만! 정의 금지)
content = content.replace(
    '\t\t\t\tSOME_BUILD_UUID /* AnyFile.swift in Sources */,',
    f'\t\t\t\t{UUID_BUILD} /* Foo.swift in Sources */,\n'
    '\t\t\t\tSOME_BUILD_UUID /* AnyFile.swift in Sources */,'
)

# 반드시 검증
opens = content.count('{')
closes = content.count('}')
assert opens == closes, f"괄호 불균형: {{ {opens} vs }} {closes}"

with open(PBXPROJ, 'w') as f:
    f.write(content)
print("✅ 완료")
```

---

## 손상 시 복구 방법

```bash
cd /Users/jeongyong/workspace/dailyverse

# 1단계: git으로 복구
git checkout DailyVerse/DailyVerse.xcodeproj/project.pbxproj

# 2단계: 반드시 fix 스크립트 실행 (git 원본에 알려진 오류가 있음)
python3 scripts/fix_pbxproj_complete.py
```

> **주의**: git checkout 후 fix 스크립트를 실행하지 않으면 여전히 열리지 않습니다.
> git 원본 자체에 손상된 항목이 존재하기 때문입니다.

---

## 이 프로젝트에 등록된 UUID 목록

| 파일 | UUID_REF (fileRef) | UUID_BUILD (buildFile) |
|------|-------------------|----------------------|
| MeditationEntry.swift | A1B2C3D4E5F601020304050A | A1B2C3D4E5F601020304050B |
| StreakManager.swift | A1B2C3D4E5F601020304050C | A1B2C3D4E5F601020304050D |
| MeditationRepository.swift | A1B2C3D4E5F601020304050E | A1B2C3D4E5F601020304050F |
| MeditationViewModel.swift | A1B2C3D4E5F601020304051A | A1B2C3D4E5F601020304051B |
| MeditationView.swift | A1B2C3D4E5F601020304051C | A1B2C3D4E5F601020304051D |
| MeditationWriteSheet.swift | A1B2C3D4E5F601020304051E | A1B2C3D4E5F601020304051F |
| AuthWelcomeView.swift | A8B3C2D1E4F5A8B3C2D1E4F5 | A8B3C2D1E4F5A8B3C2D1E4F6 |
| WeatherAdviceService.swift | BA20000CBA20000CBA20000C | BA20000DBA20000DBA20000D |

> 새 파일 추가 시 기존 UUID와 충돌하지 않도록 위 목록을 먼저 확인하세요.

---

## 과거 발생한 파싱 에러 패턴

### 패턴 1: 인라인 PBXFileReference (2026-04 발생)
```
/* 잘못된 예 — PBXGroup children 안에 정의가 삽입됨 */
children = (
    WA100001WA100001WA100001 /* WeatherAdviceService.swift */ = {isa = PBXFileReference; ...};
    C1BB2A3C4EB162E8A4F48B7C /* WeatherService.swift */,   ← 이 줄도 잘려나감
```

### 패턴 2: 인라인 PBXBuildFile in Sources (2026-04 발생)
```
/* 잘못된 예 — files 배열 안에 정의가 삽입됨 */
files = (
    A1B2C3D4... /* MeditationEntry.swift in Sources */ = {isa = PBXBuildFile; fileRef = ...; };
    ← 이런 형태는 절대 금지
```

### 패턴 3: 비16진수 UUID (2026-04 발생)
```
잘못된 예:
  AUTH001AUTH001AUTH001AUTH001  (U,T,H 포함)
  WA100001WA100001WA100001      (W 포함)

올바른 예:
  A8B3C2D1E4F5A8B3C2D1E4F5    (0-9, A-F만)
```
