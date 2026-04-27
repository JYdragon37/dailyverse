# Legacy Backup

> 생성일: 2026-04-27
> 목적: 기술 부채 정리 시 제거된 레거시 코드의 원본 보관

## 보관 파일 목록

| 파일 | 원본 경로 | 제거된 내용 |
|------|----------|------------|
| `DailyVerseCache_backup.swift` | `Core/Models/DailyVerseCache.swift` | Zone별 말씀 ID 필드 8개 (deepDarkVerseId 등) — todayVerseId로 통일됨 |
| `FirestoreService_backup.swift` | `Core/Services/FirestoreService.swift` | `fetchBackgroundImage(for:)` 단일 문서 레거시 메서드 |

## 에러 발생 시 복구 방법

```bash
# DailyVerseCache 복구
cp Legacy_Backup/DailyVerseCache_backup.swift DailyVerse/DailyVerse/Core/Models/DailyVerseCache.swift

# FirestoreService 복구
cp Legacy_Backup/FirestoreService_backup.swift DailyVerse/DailyVerse/Core/Services/FirestoreService.swift
```

또는 `git checkout <커밋 해시> -- <파일 경로>` 로 git 이력에서 복구 가능.
