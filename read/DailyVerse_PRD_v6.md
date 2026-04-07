# DailyVerse PRD v6.0 (2026-04-07)

> v5.1 → v6.0 핵심 변경: 4모드 → 8 Zone 시스템, 배경 이미지 이원화, 에어코리아 API 연동, 알람 팝업 날씨/광고 슬롯 추가

---

## 1. Product Overview

DailyVerse는 크리스천을 위한 iOS 알람 앱으로, 하루의 끝과 시작을 성경 말씀과 함께 경건하게 만들어주는 서비스다. 기존 알람 앱의 기계적인 경험에 성경 말씀·감성 이미지·실시간 날씨를 결합하여, 이미 습관화된 "알람 확인" 행동 위에 영적 루틴을 자연스럽게 얹는다.

- **슬로건**: 하루의 끝과 시작을 경건하게
- **플랫폼**: iOS 16.0+ (iPhone 전용, MVP)
- **버전**: v1.0 MVP
- **개발 방식**: Claude Code + SwiftUI
- **구독 모델**: 단일 플랜. 모든 기능 전면 제공. Free/Premium 기능 분리는 유저 데이터 확보 후 별도 업데이트로 도입.

---

## 2. 문제 정의 & 솔루션

크리스천 유저는 매일 말씀을 묵상하고 싶지만, 별도 앱을 여는 행동 장벽이 높아 습관 형성에 실패한다. DailyVerse는 이미 매일 하는 행동인 "알람 설정 및 확인"에 말씀 경험을 끼워넣어 마찰을 0에 가깝게 만든다. 그 결과 유저는 특별한 노력 없이도 하루 8번(Zone별 전환 시점) 자연스럽게 성경 말씀을 접하게 된다.

---

## 3. 시장 분석

글로벌 영적 웰니스 앱 시장은 2026년 기준 $2.99B 규모이며 CAGR 16.3%로 성장 중이다. 한국 시장은 2024년 $19.3M에서 2033년 $69.6M으로 약 3.6배 성장이 예상된다. 한국 인구의 약 20%가 기독교인으로 핵심 타깃 모수는 충분하다.

| 경쟁사 | 강점 | 약점 | DailyVerse 차별점 |
|--------|------|------|------------------|
| Rise Alarm + Daily Verse | 알람+말씀 조합 | UX 불안정, 날씨 없음, 1일 1회 | 8 Zone + 날씨 + 개인화 닉네임 + 세련된 UX |
| YouVersion | 방대한 콘텐츠 | 알람 기능 없음 | 알람 중심 설계 |
| Pray.com | 커뮤니티 | 고가, 한국어 미지원 | 한국어 특화 + 날씨 연동 |
| iOS 기본 알람 | 안정성 | 영적 콘텐츠 없음 | 말씀+날씨+닉네임 통합 |
| 알라미(Alarmy) | 강력한 알람 기능 | 영적 콘텐츠 없음 | 알라미급 알람 + 말씀 경험 + 웨이크업 미션 |

---

## 4. 타깃 유저

**Primary**: 20~50대 한국 기독교인. 이미 스마트폰 알람을 매일 사용하며, 말씀 묵상에 대한 니즈가 있지만 별도 앱을 여는 행동 장벽을 넘지 못하는 그룹이다.

**Secondary**: 영적 웰니스에 관심 있는 비기독교인 명상·마음챙김 사용자.

**페르소나 A — 아침형 규 (30대 직장인)**: 매일 오전 6시에 알람을 맞추고, 뉴스 대신 힘 있는 한 마디로 하루를 시작하고 싶다. 알람이 울릴 때 산 풍경 위에 말씀이 뜨는 화면을 보며 "Good Morning, 규 ☀️"라는 인사를 받는다.

**페르소나 B — 저녁형 지연 (40대 주부)**: 잠들기 전 알람을 확인하며 하루를 돌아보고, 위로가 되는 말씀 한 구절이 필요하다. 저녁 10시, 노을빛 배경 위에 "수고했어요, 오늘 하루도."와 함께 평안의 말씀을 만난다.

---

## 5. 핵심 기능 명세

### 5.1 8 Zone 시스템 (v6.0 신규)

앱은 현재 시간을 기준으로 자동으로 8개 Zone을 전환하며, 각 Zone에 맞는 개인화 인사말·말씀 테마·배경 이미지·날씨 정보를 제공한다.

| Zone | 시간대 | 컨셉 | 인사말 (EN) | 인사말 (KR) | 테마 |
|------|--------|------|-------------|-------------|------|
| Zone 1 | 00:00–03:00 | 🌑 Deep Dark | *Still up, Night Owl?* | *아직 안 잤어요?* | stillness, surrender, grace, faith |
| Zone 2 | 03:00–06:00 | 🌒 First Light | *Rise before the world.* | *세상보다 먼저 일어난 당신.* | faith, renewal, stillness, hope |
| Zone 3 | 06:00–09:00 | 🌅 Rise & Ignite | *Good Morning* | *좋은 아침이에요, 오늘도 파이팅!* | hope, courage, strength, renewal |
| Zone 4 | 09:00–12:00 | ⚡ Peak Mode | *In the Zone* | *지금 당신, 최고의 상태예요.* | wisdom, focus, courage, strength |
| Zone 5 | 12:00–15:00 | ☀️ Recharge | *Breathe. Reset.* | *잠깐 숨 고르고, 다시 달려요.* | rest, patience, gratitude, comfort |
| Zone 6 | 15:00–18:00 | 🌤 Second Wind | *Second Wind's here.* | *두 번째 바람이 왔어요, 마무리해봐요.* | strength, focus, patience, wisdom |
| Zone 7 | 18:00–21:00 | 🌇 Golden Hour | *Good Evening* | *수고했어요, 오늘 하루도.* | gratitude, reflection, comfort, peace |
| Zone 8 | 21:00–24:00 | 🌙 Wind Down | *Rest well.* | *오늘도 잘 했어요, 푹 쉬어요.* | peace, rest, comfort, stillness |

**Zone별 mood 매핑**:
- Zone 1·2: serene, calm
- Zone 3·4: bright, dramatic
- Zone 5·6: calm, warm
- Zone 7: warm, serene
- Zone 8: cozy, calm

**일별 고정 정책**: 각 Zone의 말씀과 배경 이미지는 해당 Zone 최초 진입 시 결정되며 하루 동안 고정. `daily_cards` 컬렉션에 해당 날짜 데이터가 있으면 알고리즘 대신 큐레이션 조합 우선 적용. 06:00 기준으로 초기화.

**배경 이미지 전환**: Zone 전환 시 Cross-Fade 애니메이션. Gallery 탭에서 유저가 핀한 이미지가 있으면 해당 Zone에 우선 적용. 없으면 알고리즘 자동 선택.

**[다음 말씀] 기능**: 홈 화면 말씀 우측 버튼 탭 시 같은 Zone·테마 내에서 새로운 말씀 표시. cooldown 대상 구절 제외 후 선택. 모든 유저 제공.

---

### 5.2 홈 탭

홈 화면은 **딥 다크 톤 풀스크린 Zone 배경 이미지** 위에 아래 요소들이 레이어링된다. 배경 이미지는 스플래시 로딩 중 미리 다운로드되어 홈 진입 시 즉시 표시된다 (플래시 없음).

**레이아웃 (상단 → 하단)**:
- 상단: 날씨 이모지 + 개인화 인사말(`Good Morning, {nickname}` 또는 `Breathe. Reset. {nickname}`)
- 그 아래: 시간 + 날씨 정보 한 줄 (`09:57 AM · ☀️ Seoul 11°C · 💧67%`)
- 화면 중앙: 말씀 텍스트 (흰색, 대형 폰트, 좌하단 정렬), 성경 참조 + 테마 배지 칩 + DB 글귀 번호 (`#7`)
- 날씨 탭 → 날씨 상세 시트

**이미지 이원화**: 홈 배경은 Zone별 `background_images` 컬렉션 이미지만 사용. 말씀 연계 `images` 컬렉션은 홈 배경으로 사용하지 않음.

**말씀 카드 바텀시트**: 말씀 영역 탭 시 화면의 78% 높이 바텀시트 오픈. 구성:
- 원문 (`text_full_ko`)
- 오늘의 적용 (`application`, 닉네임 포함)
- 해석 (`interpretation`)
- **광고 슬롯 (AdMob Banner 300×250 Medium Rectangle)** — 해석 아래 배치
- 저장 / 다음 말씀 / 닫기 버튼

**골든 배너**: 알람 0개 유저에게 "⏰ 매일 아침 말씀으로 시작해보세요" 배너 3일간 표시. 알람 1개 이상 설정 시 자동 소멸.

**코치마크**: 첫 진입 시 1회. 말씀 영역 → Alarm 탭 순서 하이라이트. 탭 또는 3초 후 자동 진행.

---

### 5.3 날씨 (v6.0 업데이트)

**API 구조**: 에어코리아(한국 공식) 우선, 실패 시 OpenWeatherMap 폴백.

| 데이터 | API | 설명 |
|--------|-----|------|
| 기온·날씨·시간별 예보 | WeatherKit (Apple) | 정확도 양호 |
| 미세먼지 AQI | **에어코리아** (환경부 공식) | 한국 측정소 실시간 실측값 |
| AQI 폴백 | OpenWeatherMap | 에어코리아 실패 시 |

**날씨 상세 시트** (홈 날씨 탭 시 오픈):
- 위치 + 현재 온도 + 날씨 상태
- CAI 통합대기환경지수 게이지 (에어코리아 또는 OWM 기반, 출처 표시)
- **PM2.5 실측값 (μg/m³)** + **PM10 실측값 (μg/m³)** — 에어코리아 측정소명 표시
- 시간별 예보 스크롤 (현재 실측값 첫 항목 고정 + API 예보 순서대로)
- 습도, 내일 아침 예보
- **새로고침 버튼** — 캐시 강제 초기화 후 실시간 재조회

**캐시 정책**: 30분 캐시 적용. 수동 새로고침 시 캐시 초기화 후 재요청.

---

### 5.4 알람 탭

알라미의 핵심 알람 기능 구조를 DailyVerse 감성 UX에 맞게 재해석한다. 최대 **5개** 알람 등록 가능.

**알람 목록**: 각 셀에 시간·반복 요일 요약·레이블·ON/OFF 토글 표시. 스와이프 삭제 + 3초 [되돌리기] 제공.

**알람 탭 상단**: Zone별 말씀 텍스트 표시 (`alarm_text_ko` 필드 우선, 없으면 `text_ko` 사용).

**알람 추가/수정 모달**:
- TimePicker (스크롤 휠, 1분 단위)
- 반복 요일 선택 (기본: 매일). 전체→"매일" / 평일→"주중" / 주말→"주말" / 특정→나열 / 미선택→저장 버튼 비활성화
- 알람 소리 선택: 🎵 알람송 / 자연 소리 / 찬양 멜로디
- 볼륨 슬라이더
- 웨이크업 미션 선택
- 스누즈 설정 (간격: 1·3·5·10분 / 최대 횟수: 0~10회)
- 말씀 미리보기 (해당 Zone 테마 기준)
- 저장 버튼

**저장 완료 토스트**: "✅ 내일 {HH:mm}, 말씀이 함께 올릴 거예요" 2초 표시.

**웨이크업 미션 7종**:

| 미션 | 설명 |
|------|------|
| 없음 (기본) | 스누즈/종료 버튼으로 해제 |
| 흔들기 | 지정 횟수 폰 흔들기 (CMMotionManager) |
| 수학 문제 | 난이도 선택 (쉬움/보통/어려움) |
| 사진 촬영 | 미리 등록한 장소 사진 일치 시 해제 |
| 바코드/QR | 미리 등록한 바코드 스캔 시 해제 |
| 타이핑 ✨ | 알람 화면의 성경 구절 직접 타이핑 → 말씀 손필사가 묵상이 되는 DailyVerse 전용 미션 |
| 걷기 | 목표 걸음 수 달성 시 해제 (HealthKit 연동) |

---

### 5.5 알람 울림 UX — 듀얼 엔진 (iOS 16+)

**엔진 선택 구조**:
- iOS 16–25: LegacyAlarmEngine (AVAudioSession + UNUserNotificationCenter)
- iOS 26+: AlarmKitEngine (시스템 레벨 알람)

| 구분 | iOS 16–25 Legacy Engine | iOS 26+ AlarmKit Engine |
|------|-------------------------|-------------------------|
| 핵심 기술 | AVAudioSession + UNNotificationCenter | AlarmKit |
| 소리 | 앱 번들 오디오 (alarm_song.mp3) + WAV 생성 폴백 | 시스템 알람 인프라 |
| 무음 모드 | AVAudioSession.playback 카테고리로 관통 | 완전 관통 |
| DND 관통 | 부분적 (.timeSensitive) | 완전 관통 |
| 앱 종료 시 | 로컬 알림 사운드 폴백 | 완전 작동 |

**알람 울림 플로우 (미션 없음)**:
```
Stage 0 — 알람 트리거 (소리 발동)
  ↓
Stage 1 — 전체화면 알람 (TabBar 완전 숨김)
  · 풀스크린 Zone 배경 이미지
  · [날씨 컴팩트 스트립] 현재 날씨 + 시간별 예보 5개
  · 말씀 텍스트 (text_ko 요약본)
  · [스누즈 N분] (좌, 회색) / [종료] (우, 골드)
  · 스누즈 소진 시: 🔒 "더 이상 스누즈할 수 없어요"
  ↓ [종료] 탭
Stage 2 — 웰컴 스크린 (0.6초 Fade-in)
  · 날씨 위젯 (아침: 현재 날씨 / 저녁·새벽: 내일 예보)
  · 글래스모피즘 말씀 카드 (말씀 + 성경 참조 + 테마 칩)
  · [♥ 저장] / [오늘의 한마디 ✨] / [× 닫기]
  · [× 닫기] → 홈 탭 이동, TabBar 노출
```

**알람 울림 플로우 (미션 설정 시)**:
```
Stage 0 → Stage 1 → [말씀 깨우기 시작] 탭
  ↓
Stage 1.5 — 미션 수행 화면
  · 미션 UI (흔들기/수학/사진/바코드/타이핑/걷기)
  · 완료 → "수고했어요, {nickname}. 오늘 말씀이 기다리고 있어요 🌿"
  ↓ 0.6초 Fade-in
Stage 2 — 웰컴 스크린
```

**엣지 케이스**:

| 상황 | iOS 16–25 | iOS 26+ |
|------|-----------|---------|
| 앱 완전 종료 | 로컬 알림 사운드, 배너 탭 시 Stage 1 진입 | 시스템 전체화면 자동 발동 |
| 오프라인 | 캐시 말씀 + 로컬 이미지 정상 작동 | 동일 |
| 다중 알람 | 현재 알람 종료 후 홈 탭, 다음 알람 별도 루프 | 동일 |
| 포그라운드 | willPresent 콜백 → Stage 1 오버레이 즉시 | 동일 |
| 무음 모드 | AVAudioSession.playback으로 관통 | 완전 관통 |

---

### 5.6 저장 탭 (Saved)

저장된 말씀을 **이미지 썸네일 카드** 형태로 표시. 저장 당시 배경 이미지를 썸네일로 사용하고 날짜·날씨·말씀을 오버레이.

**카드 구조**:
```
[배경 이미지 풀 블리드]
| 2026. 4. 3  ☀️ 11°C    ← 상단: 날짜 + 날씨
| "두려워하지 말라
|  내가 너와 함께 함이라" ← 중하단: 말씀 (흰색 중형)
| 이사야 41:10            ← 성경 참조 (Accent Gold)
```

- 2열 그리드, 종횡비 3:4, 간격 12pt
- 하단 그라데이션 오버레이 (투명→블랙 40%) 가독성 확보
- 최신순 정렬. **전체 무제한 열람**.

**카드 탭**: 전체화면 상세 뷰. 전체 구절·저장 일시·날씨 스냅샷·위치·Zone 표시. [저장 해제]·[공유] 액션 제공.

**빈 상태(Empty State)**:
- 비로그인: 북마크 아이콘 + "말씀을 저장하려면 로그인이 필요해요" + [Apple로 시작하기]
- 로그인 후 저장 없음: 하트 아이콘 + "아직 저장된 말씀이 없어요" + [홈으로 가기]

---

### 5.7 Gallery 탭

Firestore `background_images` 컬렉션의 전체 배경 이미지를 탐색하고, Zone별 핀 설정으로 홈 배경을 커스터마이즈한다.

**레이아웃**: 2열 그리드, 종횡비 2:3. 상단 Zone 필터 탭: 전체 / 🌑Deep Dark / 🌒First Light / 🌅Rise & Ignite / ⚡Peak Mode / ☀️Recharge / 🌤Second Wind / 🌇Golden Hour / 🌙Wind Down.

**이미지 카드**: 썸네일 + 우상단 Zone 배지 + 핀된 경우 우하단 📌.

**이미지 탭 → 바텀시트**: 상세 정보(출처·라이선스·테마·분위기) + Zone별 배경 설정 버튼 8개. Zone당 1개 핀 가능. 새로 설정 시 기존 핀 자동 해제.

`is_sacred_safe: false` 이미지: Gallery 탭에서 흐림 처리 없이 표시하되, 홈 배경 핀 불가처리 (관리자 필터링 전제).

---

### 5.8 Settings 탭

5개 섹션으로 구성.

- **계정**: 닉네임 표시·변경, Apple ID 정보, 로그아웃, 계정 탈퇴(빨간색, App Store 필수).
- **권한**: 위치·알림 권한 현재 상태 + [설정 열기] 딥링크.
- **외관**: 다크 모드 고정 / 시스템 따라가기.
- **앱 정보**: 버전, 이용약관, 개인정보처리방침, 오픈소스 라이선스.
- **피드백**: 앱스토어 리뷰 바로가기, 문의하기.

**계정 탈퇴 플로우**: ① 경고 바텀시트 → ② Apple Sign-In 재인증 → ③ Firestore `users/{uid}` + `saved_verses/{uid}` 삭제, Firebase Auth 삭제 → ④ UserDefaults 초기화 → 온보딩 첫 화면.

---

## 6. 온보딩 플로우

"가치 먼저 → 개인화 → 권한 → 첫 알람" 원칙. 총 6단계.

| 순서 | 화면 | 내용 |
|------|------|------|
| 1 | Welcome | 풀스크린 감성 이미지 + "하루의 끝과 시작을 경건하게" + [시작하기] |
| 2 | 닉네임 입력 | "우리 어떻게 불러드릴까요?" + 텍스트 필드 (최대 10자). 미입력 시 "친구"로 기본 저장 |
| 3 | First Verse | 이사야 41:10 샘플 + "Good Morning, {nickname} ☀️" 개인화 미리보기 + [다음] |
| 4 | Location 권한 | "위치를 허용하면 날씨에 맞는 말씀을 만날 수 있어요" + [허용하기] / [나중에] |
| 5 | Notification 권한 | "알람이 울릴 때 말씀을 함께 받으세요" + [허용하기] / [나중에]. iOS 26+는 AlarmKit 권한도 함께 요청 |
| 6 | First Alarm | "첫 알람을 설정해볼까요?" 06:00 기본값 + 웨이크업 미션 선택 + [설정하기] / [건너뛰기] |

**닉네임 저장**: UserDefaults: `userNickname` + Firestore: `users/{uid}.nickname` 동화. Settings에서 언제든 변경 가능.

**상태 관리 키 (UserDefaults)**: `onboardingCompleted`, `nicknameSet`, `locationPermissionRequested`, `notificationPermissionRequested`, `firstAlarmPromptShown`. 최대 3회 스킵 시 강제 완료 처리. 다음 앱 진입 시 스킵 지점부터 재개.

---

## 7. 앱 실행 & 로딩 플로우

**Stage 1**: 2.8초 스플래시 (로고 페이드인 0.4초).

**Stage 2** — 데이터 로드:
- **Zone 배경 이미지 pre-load**: 현재 Zone 배경 이미지를 디스크 캐시에 미리 저장 → HomeView 진입 시 즉시 표시 (플래시 0)
- 유효 캐시(30분 이내) → 스켈레톤 없이 홈 즉시 이동
- 캐시 없음 + 온라인 → Firebase 로드 → 홈 이동
- 캐시 없음 + 오프라인 → 번들 폴백 구절 8개(Zone별 1개)로 홈 렌더링 + 토스트 "오프라인 상태입니다. 저장된 말씀을 표시해요"

**Stage 3**: 온보딩 완료 여부 확인 → 미완료 시 온보딩, 완료 시 홈 탭.

---

## 8. 권한 처리 설계

**위치 권한 4가지 상태**:
- `authorizedWhenInUse`: 날씨 위젯 정상 작동
- `notDetermined`: "위치를 허용하면 날씨에 맞는 말씀을 만날 수 있어요" + [허용하기]
- `denied/restricted`: "위치 권한이 없어요" + [설정 열기]
- API 오류: 캐시 사용 또는 날씨 위젯 숨김

**알림 권한**:
- `notDetermined`: 탭 시 iOS 권한 팝업 호출
- `denied`: Settings 딥링크 제공
- 알람 탭 진입 시 상단 배너로 권한 없음 경고

---

## 9. DB 스키마

### 9.1 Firestore — verses/{verse_id}

| 필드 | 타입 | 설명 |
|------|------|------|
| `verse_id` | String | 문서 ID (`v_001`) |
| `text_ko` | String | 카드 표시용 요약 구절 (30자 이내 권장) |
| `text_full_ko` | String | 바텀시트 전체 구절 |
| `alarm_text_ko` | String? | 알람 탭 전용 텍스트 (없으면 `text_ko` 사용) |
| `reference` | String | 성경 참조 (`이사야 41:10`) |
| `book` | String | 성경책명 |
| `chapter` | Int | 장 |
| `verse` | Int | 절 |
| `mode` | [String] | Zone rawValue 배열 또는 `["all"]` |
| `theme` | [String] | 테마 태그 배열 또는 `["all"]` |
| `mood` | [String] | 분위기 태그 배열 또는 `["all"]` |
| `season` | [String] | 계절 |
| `weather` | [String] | 날씨 조건 |
| `interpretation` | String | 말씀 해석 |
| `application` | String | 일상 적용 |
| `notes` | String? | 신학 메모 (선택) |
| `curated` | Bool | 신학 검수 완료 여부 |
| `status` | String | `active` \| `draft` \| `inactive` |
| `usage_count` | Int | 표시 횟수 |
| `cooldown_days` | Int | 재표시까지 최소 일수 (기본 7) |
| `last_shown` | String? | 마지막 표시일 (`YYYY-MM-DD`) |
| `show_count` | Int | 누적 표시 횟수 |

### 9.2 Firestore — background_images/{bg_id}

| 필드 | 타입 | 설명 |
|------|------|------|
| `bg_id` | String | `bg_rise_ignite` 등 Zone rawValue 기반 |
| `mode` | String | Zone rawValue (`rise_ignite`, `golden_hour` 등) |
| `storage_url` | String | Firebase Storage URL |
| `filename` | String | 파일명 |
| `source` | String | 이미지 출처 |
| `license` | String | 라이선스 |
| `status` | String | `active` \| `draft` |

### 9.3 Firestore — images/{image_id}

말씀 연계 이미지. Gallery 탭 및 알람 Stage 1/2에서 사용. 홈 배경으로 사용하지 않음 (이미지 이원화).

| 필드 | 타입 | 설명 |
|------|------|------|
| `image_id` | String | `img_001` |
| `filename` | String | 파일명 |
| `storage_url` | String | Firebase Storage URL |
| `mode` | [String] | Zone 배열 |
| `theme` | [String] | 테마 배열 또는 `["all"]` |
| `mood` | [String] | 분위기 배열 또는 `["all"]` |
| `tone` | String | `bright` \| `mid` \| `dark` |
| `text_position` | String | `top` \| `center` \| `bottom` |
| `is_sacred_safe` | Bool | 홈 배경 사용 가능 여부 |
| `avoid_themes` | [String] | 함께 쓰면 안 되는 테마 |
| `status` | String | `active` \| `draft` |

### 9.4 Firestore — users/{user_id}

```
email: String
display_name: String
nickname: String              // 기본: "친구"
created_at: Timestamp
subscription_status: String   // "free" (향후 "premium")
settings: {
  timezone: String
  location_enabled: Bool
  notification_enabled: Bool
  preferred_theme: String
  wake_mission: String
}
pinned_images: {              // 8 Zone별 핀 이미지 ID
  deep_dark: String?
  first_light: String?
  rise_ignite: String?
  peak_mode: String?
  recharge: String?
  second_wind: String?
  golden_hour: String?
  wind_down: String?
}
```

### 9.5 Firestore — saved_verses/{user_id}/verses/{saved_id}

```
verse_id: String
image_id: String?
saved_at: Timestamp
mode: String                  // Zone rawValue
weather_snapshot: { temp, condition, humidity }
weather_dust: String?         // 미세먼지 등급
location: { city, lat, lng }
```

### 9.6 Firestore — daily_cards/{date}/{zone}

관리자가 특정 날짜·Zone에 큐레이션 말씀을 지정하는 컬렉션. 앱이 이 데이터를 우선 사용.

```
verse_id: String
date: String                  // "2026-04-07"
zone: String                  // Zone rawValue
```

---

## 10. 말씀 선택 알고리즘

```
1. status == "active" && curated == true 필터링
2. mode 매칭: verse.mode.contains(zone.rawValue) || verse.mode.contains("all")
3. isEligible: cooldown_days 경과 여부 확인
4. 스코어 산정:
   - theme: "all" → +3, 특정 테마 매칭 → 매칭 수 × 3
   - mood: "all" → +2, 특정 분위기 매칭 → 매칭 수 × 2
   - weather 일치 또는 "any" → +2
   - season 일치 또는 "all" → +1
5. 최고 점수 구절 중 랜덤 선택
6. daily_cards 컬렉션 큐레이션 데이터 있으면 알고리즘 대신 큐레이션 우선
```

---

## 11. 이미지 매칭 알고리즘

```
1. status == "active" 필터링
2. mode 매칭: image.mode.contains(zone.rawValue) || image.mode.contains("all")
3. 스코어 산정:
   - theme: "all" → +3, 특정 테마 → 매칭 수 × 3
   - mood: "all" → +2, 특정 분위기 → 매칭 수 × 2
   - weather 일치 → +2
   - season 일치 → +1
   - tone 우선순위: Zone 3·4(bright) → bright +2 / Zone 1·2·8(dark) → dark +2 / 나머지 mid +1
4. 최고 점수 이미지 중 랜덤 선택
5. Gallery 핀 이미지 있으면 알고리즘 대신 핀 이미지 우선
```

---

## 12. 데이터 파이프라인

### 12.1 말씀 업로드

1. 구글 시트 `VERSES` 탭에 말씀 데이터 입력
2. `📖 말씀 업로드.command` 더블클릭 (또는 `node sync_sheets_to_firestore.js`)
3. 시트가 단일 진실 원본 → 시트에 없는 Firestore 문서는 자동 삭제

### 12.2 배경 이미지 업로드

1. `scripts/background_images_to_upload/` 폴더에 이미지 파일 복사
   - 파일명 규칙: `bg_{zone_rawValue}.jpg` (예: `bg_rise_ignite.jpg`)
2. `🌅 배경이미지 업로드.command` 더블클릭 (또는 `node upload_backgrounds.js`)

### 12.3 말씀 이미지 업로드

1. `scripts/images_to_upload/` 폴더에 이미지 파일 복사
2. `scripts/upload_images.js`의 `IMAGE_METADATA` 배열에 메타데이터 추가
3. `node upload_images.js` 실행

### 12.4 mode 태그 규칙 (8-zone 기준)

```
all                           → 모든 Zone (범용 말씀 권장)
rise_ignite, peak_mode        → 06–12시 (아침 전체)
recharge, second_wind         → 12–18시 (낮 전체)
golden_hour, wind_down        → 18–24시 (저녁 전체)
deep_dark, first_light        → 00–06시 (새벽 전체)
```

---

## 13. 디자인 시스템

**Calm 벤치마크 컬러/타이포/모션 시스템 기준**. 딥 다크 톤 유지.

**컬러 팔레트**:
- `dvBgDeep` #090D18 — 딥 다크 배경
- `dvGold` #C9A84C — CTA, 강조
- `dvAccentGold` #C8972A — 버튼, 하이라이트

**Zone별 그라데이션**:
- Zone 1·2 (새벽): 극야 퍼플 `#030308` → `#0A0820`
- Zone 3·4 (아침): 딥퍼플 `#1A0E2E` → `#3D1F5A`
- Zone 5·6 (낮): 딥네이비 `#0D1B2A` → `#1B3A5C`
- Zone 7·8 (저녁): 극야 인디고 `#06080F` → `#0D1533`

**탭바**: 커스텀 DVTabBar (safeAreaInset 방식). UIKit UITabBarAppearance 대신 SwiftUI safeAreaInset으로 정확한 위치 보장.

**이미지 캐시**: `ImageDiskCache` (NSCache + FileManager 2-level). 첫 다운로드 후 디스크 저장 → 앱 재실행 시 즉시 표시.

---

## 14. 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| UI | SwiftUI | iOS 16.0+ |
| 백엔드 | Firebase Firestore | 말씀/이미지/유저 데이터 |
| 인증 | Firebase Auth | Apple Sign-In 전용 |
| 스토리지 | Firebase Storage | 감성 이미지 CDN |
| 분석 | Firebase Analytics + Crashlytics | |
| 날씨 | WeatherKit (1차) + OpenWeatherMap (폴백) | |
| 대기질 | **에어코리아** (1차) + OpenWeatherMap (폴백) | v6.0 신규 |
| 광고 | AdMob Banner (말씀 상세 시트) | |
| 알람 | AVAudioSession (iOS 16–25) + AlarmKit (iOS 26+) | |
| 알람 소리 | alarm_song.mp3 (번들 내장) | v6.0 신규 |
| 로컬 캐시 | Core Data + ImageDiskCache | |
| 개발 도구 | Claude Code | |

---

## 15. 운영 규칙

- **말씀 저작권**: 자체 의역 (Claude/GPT-4 초안 + 신학 자문자 검수 후 `curated = true`)
- **text_ko**: 30자 이내 요약 구절 (필드 아님, 운영 가이드)
- **alarm_text_ko**: 알람 탭 전용 텍스트. 비워두면 `text_ko` 자동 사용
- **cooldown 로직**: cooldown_days 기간 내 같은 말씀 재노출 방지. 기본 7일
- **이미지 라이선스**: Genspark Pro (상업적 사용 가능) 또는 Unsplash CC0
- **배경 이미지**: Zone별 1장씩 총 8장. `background_images` 컬렉션
- **말씀 이미지**: `images` 컬렉션. 홈 배경으로 사용 안 함 (이미지 이원화)

---

## 16. v5 → v6 변경 이력

| 항목 | v5 | v6 |
|------|----|----|
| 시간대 시스템 | 4모드 (아침/낮/저녁/새벽) | **8 Zone** (3시간 단위) |
| 인사말 | 영문만 | EN + KR 이원화 |
| 홈 배경 이미지 | 말씀 이미지 폴백 | Zone 전용 배경 이미지 (이원화) |
| 배경 pre-load | 없음 | Splash 중 Zone 배경 미리 로드 |
| 알람 팝업 | 말씀만 | 날씨 컴팩트 스트립 + 시간별 예보 추가 |
| 말씀 상세 팝업 | medium/large | 화면 78% 고정 + 광고 슬롯 |
| 대기질 API | OpenWeatherMap (글로벌 모델) | **에어코리아** (한국 공식 측정소) |
| 날씨 상세 | AQI 지수만 | PM2.5·PM10 실측치 (μg/m³) + 측정소명 |
| 날씨 새로고침 | 캐시 유지 | 캐시 강제 초기화 후 재조회 |
| 알람 소리 | 없음 (WAV 생성 폴백) | alarm_song.mp3 번들 내장 |
| 탭바 | DVTabBar (ZStack 오버레이) | DVTabBar (safeAreaInset 방식) |
| DB mode 태그 | morning/afternoon/evening/dawn | Zone rawValue 또는 "all" |
| theme/mood | 특정 태그만 | **"all" 범용 태그** 추가 지원 |
| alarm_text_ko | 없음 | **알람 탭 전용 텍스트 필드** 추가 |
| 이미지 캐시 | URLSession 캐시 | **ImageDiskCache** (2-level) |
| 데이터 업로드 | Apps Script (OAuth 문제) | **Node.js 자동화** (.command 파일) |
| Gallery Zone 필터 | 4개 탭 | **8개 Zone 탭** |
| PinnedImages | 4 Zone 필드 | **8 Zone 필드** |
| DailyVerseCache | 4 Zone 필드 | **8 Zone 필드** |
| 폴백 말씀 | 4개 | **8개** (Zone별 1개) |

---

*최종 업데이트: 2026-04-07*
*작성: Claude Code + 효진*
