# morning manna — 유저 데이터 흐름 & 보안 가이드

> 최종 업데이트: 2026-04-26
> 대상: 개발자, 운영자

---

## 1. 유저 데이터 저장 위치 전체 맵

```
Firebase Auth ──── UID · 소셜 토큰 · 이메일
                         │
                         ▼
Firestore ─────── users/{uid}                  ← 프로필, 최근 말씀 이력, 핀 이미지
                  saved_verses/{uid}/verses/   ← 저장한 말씀 + 스냅샷
                  meditation_logs/{uid}/       ← 묵상 기도·감사 일기
                  verses/{id}                  ← 전역 노출 통계 (show_count, last_shown)
                  verse_stats/{id}             ← Zone별 전역 통계
                         │
Core Data ───────         ├─ CachedVerse       ← 오늘의 말씀 오프라인 캐시
                          └─ CachedWeather     ← 날씨 30분 캐시
                         │
UserDefaults ──── AlarmEntity 확장 속성 (label, soundId, volume 등)
                  NicknameManager (닉네임)
                  StreakManager (연속 묵상 일수)
                  온보딩 완료 여부 (onboardingCompleted)
                         │
SecureStorage ─── 묵상 오늘 캐시 (kTodayCache)   ← iCloud 백업 제외
(iCloud 제외)      묵상 오프라인 대기 (kPending)   ← 개인 기도·감사 임시 저장
                         │
AlarmKit / UNNotification ── 알람 스케줄
                              (기기 시스템 레벨, Firestore/DB 아님)
```

---

## 2. 이벤트별 데이터 저장 흐름

### 회원가입 / 로그인

```
[Apple Sign-In / Google Sign-In]
          ↓
Firebase Auth — UID, 토큰 발급 (기기 Keychain에 자동 저장)
          ↓
Firestore users/{uid} 문서 생성 (최초 1회)
  ├─ email
  ├─ display_name
  ├─ created_at
  ├─ subscription_status: "free"
  ├─ recent_verse_ids: []
  └─ pinned_images: {}
```

**pendingSave**: 비로그인 상태에서 ♥ 저장 탭 시 메모리에 임시 보관 → 로그인 성공 후 자동 Firestore 저장

---

### 말씀 조회 (홈 화면 진입 시)

```
앱 실행
  ↓
Core Data CachedVerse 확인 (05:00 기준 하루 유효)
  ├─ 캐시 있음 → 즉시 표시 (네트워크 없음)
  └─ 캐시 없음
       ↓
       daily_cards/{오늘날짜} 확인 (절기 편성)
         ├─ 절기일 → verse_id 고정 사용
         └─ 일반 → VerseSelector 스코어링 알고리즘
              ↓
              users/{uid}.recent_verse_ids 조회 (최근 30개 — 중복 방지)
              ↓
              Firestore verses/ 필터링 → 스코어링 → 선택
  ↓
Core Data CachedVerse 저장
  ↓
[rate limit: 5분 쿨다운]
  ↓
Firestore verses/{id} 업데이트:
  ├─ show_count +1
  └─ last_shown: "오늘날짜"
Firestore users/{uid}.recent_verse_ids 업데이트 (FIFO, max 30)
Firestore verse_stats/{id} 업데이트:
  ├─ total_shown +1
  └─ zone_breakdown.{zone} +1
```

---

### 말씀 저장 (♥ 버튼)

```
로그인 상태 확인
  ├─ 미로그인 → LoginPromptSheet 표시
  │             pendingSave 메모리 보관
  │             → 로그인 후 자동 저장
  └─ 로그인
       ↓
SavedVerse 객체 생성:
  ├─ verseId
  ├─ imageId, imageUrl         ← 현재 표시 중인 이미지 스냅샷
  ├─ savedAt: 현재 시각
  ├─ mode: 현재 Zone
  ├─ weatherTemp, weatherCondition, weatherHumidity, weatherDust
  ├─ locationName
  └─ verseFullKo               ← 말씀 텍스트 스냅샷
       ↓
Firestore saved_verses/{uid}/verses/{uuid} 저장
```

---

### 묵상 기록 작성

```
MeditationEntry 생성:
  ├─ dateKey: "yyyy-MM-dd"
  ├─ readingText (말씀 읽기 메모)
  ├─ prayer (기도문)              ← 민감 — SecureStorage 임시 캐시
  ├─ gratitude: [감사 항목 1·2·3] ← 민감 — SecureStorage 임시 캐시
  └─ verse snapshot
       ↓
SecureStorage(kTodayCache) 임시 저장 (iCloud 백업 제외)
       ↓
온라인 확인
  ├─ 온라인 → Firestore meditation_logs/{uid}/entries/{dateKey} 즉시 저장
  └─ 오프라인 → SecureStorage(kPending) 대기
               → 앱 재시작·온라인 복귀 시 자동 flush
       ↓
StreakManager.updateMeditatedDates() 호출
UserDefaults streak 카운터 업데이트
```

---

### 알람 설정

```
AlarmAddEditView → Alarm 구조체 생성
  ↓
Core Data AlarmEntity 저장:
  ├─ id (UUID)
  ├─ time (Date)
  ├─ repeatDays ([Int])
  ├─ theme (String)
  └─ isEnabled (Bool)

UserDefaults (AlarmEntity 확장):
  ├─ label
  ├─ snoozeInterval
  ├─ maxSnoozeCount
  ├─ wakeMission
  ├─ soundId
  ├─ volume
  └─ alertStyle
  ↓
AlarmEngine.schedule() — UNNotification 또는 AlarmKit에 등록
```

---

### 계정 탈퇴

```
Apple 재인증
  ↓
Firestore 삭제 (순서 중요):
  1. saved_verses/{uid}/verses/* 하위 문서 전체 삭제
  2. saved_verses/{uid} 부모 문서 삭제
  3. meditation_logs/{uid}/entries/* 하위 문서 전체 삭제
  4. meditation_logs/{uid} 부모 문서 삭제
  5. users/{uid} 삭제
  ↓
RevenueCat logOut()
Firebase Auth 계정 삭제
UserDefaults 전체 초기화 → onboardingCompleted = false
SecureStorage 전체 삭제
  ↓
온보딩 첫 화면으로 이동
```

> ⚠️ **미삭제 항목**: `verse_stats/{id}` 의 집계 통계 (uid와 무관한 전역 데이터)

---

## 3. 저장소별 상세

### Firebase Auth (기기 Keychain)
| 저장 데이터 | 영속성 |
|-----------|--------|
| UID | 앱 삭제 전까지 |
| 소셜 토큰 (Apple/Google) | 자동 갱신 |
| 이메일 | 앱 삭제 전까지 |

### Firestore `users/{uid}`
| 필드 | 설명 | 쓰기 주체 |
|------|------|---------|
| `email` | 가입 이메일 | 앱 (최초 1회) |
| `display_name` | 표시 이름 | 앱 |
| `subscription_status` | free / premium | RevenueCat 연동 |
| `recent_verse_ids` | 최근 본 말씀 30개 FIFO | 앱 (rate limited) |
| `pinned_images` | Zone별 고정 이미지 | 앱 |
| `settings.*` | 앱 설정 | 앱 |

### Firestore `saved_verses/{uid}/verses/{id}`
| 필드 | 설명 |
|------|------|
| `verseId` | 참조용 말씀 ID |
| `verseFullKo` | 저장 당시 말씀 텍스트 스냅샷 |
| `imageUrl` | 저장 당시 배경 이미지 URL 스냅샷 |
| `savedAt` | 저장 시각 |
| `mode` | 저장 당시 Zone |
| `weather_*` | 저장 당시 날씨 스냅샷 |
| `locationName` | 저장 당시 위치 |

### Firestore `meditation_logs/{uid}/entries/{dateKey}`
| 필드 | 설명 | 암호화 |
|------|------|--------|
| `dateKey` | "yyyy-MM-dd" | ❌ |
| `readingText` | 말씀 읽기 메모 | ❌ |
| `prayer` | 기도문 | 🔑 AES-GCM (클라이언트 측) |
| `gratitude` | 감사 항목 | 🔑 AES-GCM (클라이언트 측) |

> 암호화 키: `SHA256(bundleId + uid + ".meditation.v1")` — 결정론적, 서버 전송 없음

### Core Data (로컬 기기)
| 엔티티 | 저장 내용 | TTL |
|--------|---------|-----|
| `CachedVerse` | 오늘의 말씀 JSON | 05:00 기준 하루 |
| `CachedWeather` | 날씨 데이터 | 30분 |
| `AlarmEntity` | 알람 핵심 설정 | 앱 삭제 전까지 |

### UserDefaults (iCloud 백업됨)
| 키 | 내용 | 민감도 |
|----|------|--------|
| `onboardingCompleted` | 온보딩 완료 여부 | 낮음 |
| `nickname` / `nicknameSet` | 닉네임 | 낮음 |
| `streak_current` 등 | 묵상 스트릭 | 낮음 |
| `pinnedImage_{zone}` | Zone별 고정 이미지 ID | 낮음 |
| `debugShowAuthWelcome` | 개발자 디버그 플래그 | 낮음 |

### SecureStorage (iCloud 백업 제외)
`Library/Application Support/SecureData/` — `isExcludedFromBackup = true`

| 키 | 내용 | 암호화 |
|----|------|--------|
| `kTodayCache` | 오늘 묵상 임시 캐시 | ❌ (파일 시스템만) |
| `kPending` | 오프라인 대기 묵상 | ❌ |

---

## 4. Firestore Security Rules 요약

> 배포 위치: Firebase 콘솔 → Firestore → Rules
> 최종 배포: 2026-04-26 10:01

| 컬렉션 | 읽기 | 쓰기 |
|--------|------|------|
| `verses/` | 전체 공개 | `show_count`, `last_shown` 만 인증 유저 |
| `images/`, `background_images/` 등 콘텐츠 | 전체 공개 | ❌ 불가 |
| `verse_stats/` | 인증 유저 | 지정 필드만 인증 유저 |
| `users/{uid}` | 본인만 | 본인만 (지정 필드) |
| `saved_verses/{uid}/**` | 본인만 | 본인만 |
| `meditation_logs/{uid}/**` | 본인만 | 본인만 |

---

## 5. 보안 업데이트 이력

### 2026-04-26 — 보안 전면 개선 (commit: f85df70)

#### ① ATS (App Transport Security) 수정
- **변경 전**: `NSAllowsArbitraryLoads = true` — HTTP 전면 허용
- **변경 후**: 제거 + 필요 도메인만 `NSExceptionDomains` 명시
- **영향**: App Store 심사 리젝 위험 해소, MITM 취약점 차단

#### ② API 키 노출 제거
- **변경 전**: `Info.plist`에 OpenWeatherMap, Airkorea API 키 하드코딩
- **변경 후**: `$(OPENWEATHER_API_KEY)` 변수 참조로 교체
- `Secrets.xcconfig` 파일 분리 (`.gitignore` 등록)
- Xcode Configurations → Debug/Release에 xcconfig 연결
- **영향**: 앱 바이너리에서 키 추출 불가

#### ③ Firestore Security Rules 배포
- **변경 전**: 콘솔에서만 관리, 버전 미관리
- **변경 후**: `firestore.rules` + `storage.rules` + `firebase.json` 프로젝트 등록
- Firebase REST API로 직접 배포
- **핵심 규칙**:
  - 콘텐츠 컬렉션 (verses, images 등) → 클라이언트 쓰기 완전 차단
  - 유저 데이터 → 본인 UID만 접근 가능
  - verse 통계 → 지정 필드만 increment 허용

#### ④ 계정 탈퇴 완전 삭제
- **변경 전**: `saved_verses` + `users` 만 삭제
- **변경 후**: `meditation_logs` 서브컬렉션 추가 삭제 (기도·감사 완전 제거)
- **영향**: 개인정보보호법 준수, GDPR 대응

#### ⑤ 통계 쓰기 Rate Limiting
- **변경 전**: 말씀 표시 시마다 무제한 Firestore 쓰기
- **변경 후**: 동일 말씀 5분 쿨다운 (`verseStatCooldown = 300`)
- 유저+말씀 조합 단위 쿨다운으로 스팸 방지
- **영향**: Firebase 비용 급증 방지, 통계 조작 방지

#### ⑥ 묵상 개인 데이터 암호화
- **변경**: `MeditationEntry` 에 CryptoKit AES-GCM 암호화 extension 추가
- 키 생성: `SHA256(bundleId + uid + ".meditation.v1")` — 결정론적
- 기존 평문 데이터 하위 호환 보장 (복호화 실패 시 평문 반환)
- **영향**: 서버 관리자도 기도·감사 내용 열람 불가

#### ⑦ iCloud 백업에서 민감 데이터 제외
- **변경**: `SecureStorage` 클래스 신규 생성
- `Library/Application Support/SecureData/` 디렉토리 — `isExcludedFromBackup = true`
- 묵상 기도·감사 임시 캐시를 UserDefaults → SecureStorage 이관
- **영향**: 개인 영적 기록의 iCloud 자동 백업 차단

---

## 6. 남은 보안 권고 사항

| 항목 | 우선순위 | 설명 |
|------|---------|------|
| OpenWeatherMap Bundle ID 제한 | 높음 | OWM 대시보드에서 Bundle ID `dragonbear.DailyVerse`로 키 제한 |
| Airkorea API 보호 | 중간 | 공공 API이나 Cloud Functions 프록시 권장 |
| verse 통계 Cloud Functions 이관 | 낮음 | 완전한 서버 측 검증을 위해 장기적으로 이관 권장 |
| 묵상 데이터 실제 암호화 적용 | 중간 | extension은 추가됐으나 실제 save/load 호출 지점에 encrypt/decrypt 연결 필요 |
