# DailyVerse — Stitch 디자인 브리프

> 이 문서는 Stitch가 DailyVerse 앱 디자인 작업을 시작하기 위한 가이드입니다.
> 현재 구현된 실제 상태 기준으로 작성되었습니다. (2026-04-18)

---

## 1. 앱 개요

**DailyVerse**는 크리스천을 위한 iOS 알람 앱입니다.

> "매일 아침, 알람이 아닌 말씀으로 눈을 뜨세요"

기존 알람의 기계적인 경험을 **성경 말씀 + 감성 이미지 + 실시간 날씨**로 대체합니다.
사용자가 이미 하는 "알람 확인" 행동에 영적 경험을 자연스럽게 얹습니다.

**플랫폼**: iOS 16+ (iPhone 전용)
**디자인 레퍼런스**: Calm, YouVersion, Headspace
**무드**: 경건하고 신비로운 / Dark + 감성 이미지 풀스크린 / 글래스모피즘

---

## 2. 컬러 시스템

### Primary (배경)
| 토큰 | HEX | 용도 |
|------|-----|------|
| `dvBgDeep` | `#090D18` | 앱 기본 배경 |
| `dvBgSurface` | `#0F1420` | 카드 배경 |
| `dvBgElevated` | `#1C2333` | 모달, 바텀시트 |
| `dvPrimaryDeep` | `#1A2340` | 딥 네이비 카드 |
| `dvPrimaryMid` | `#2C3E6B` | 탭바, 네비게이션 |

### Accent
| 토큰 | HEX | 용도 |
|------|-----|------|
| `dvAccentGold` | `#C8972A` | CTA 버튼, 성경 참조, 하이라이트 |
| `dvAccentSoft` | `#F5EDD8` | 보조 텍스트, 테마 칩 |
| `dvSaved` | `#E86B7A` | 저장 하트 |

### Text (모두 다크 배경 위 화이트 계열)
| 용도 | 값 |
|------|-----|
| 주요 텍스트 (말씀) | White 100% |
| 보조 텍스트 | White 55% |
| Muted | White 35% |
| Hint | White 30% |

### Surface (글래스모피즘)
- 카드/위젯 배경: `White 15%` + `.ultraThinMaterial` blur
- 테두리: `White 20%`

### 시간대별 그라데이션 배경 (홈화면 풀스크린)
| Zone | 시간 | 컬러 방향 |
|------|------|-----------|
| Deep Dark | 00–03 | 딥 퍼플 `#3D2B6B` |
| First Light | 03–06 | 스틸 블루 `#2A4A8A` |
| Rise & Ignite | 06–09 | 황금 Sunrise → 코랄 `#1A0E2E → #C9704A` |
| Peak Mode | 09–12 | 맑은 블루 `#0D1B2A → #2E7DAA` |
| Recharge | 12–15 | 틸 그린 `#2A8A7A` |
| Second Wind | 15–18 | 다크 골드 `#8A7A2A` |
| Golden Hour | 18–21 | 버닝 오렌지 `#C87020` |
| Wind Down | 21–24 | 인디고 `#06080F → #1A2460` |

> 실제 배경은 그라데이션이 아닌 **감성 사진**이 풀스크린으로 깔립니다.
> 그라데이션은 사진 위에 상단/하단 페이드 오버레이 용도입니다.

---

## 3. 타이포그래피

### 말씀 텍스트 (성경 구절)
- **Georgia Bold Italic** — 홈 말씀 카드 Hero (size 26–28)
- **Georgia Italic** — 바텀시트 전체 구절, 알람 Stage (size 17–22)

### UI 텍스트 (시스템 SF Pro)
| 토큰 | 폰트 | 용도 |
|------|------|------|
| `dvLargeTitle` | SF Pro Bold 34pt | 네비게이션 타이틀 |
| `dvTitle` | SF Pro SemiBold 22pt | 섹션 헤더 |
| `dvSubtitle` | SF Pro Medium 17pt | 부제목 |
| `dvBody` | SF Pro Regular 15pt | 본문 |
| `dvCaption` | SF Pro Regular 13pt | 캡션 |
| `dvUITitle` | SF Pro Rounded SemiBold 20pt | UI 강조 제목 |
| `dvUIBody` | SF Pro Rounded Regular 15pt | UI 본문 |

### 커스텀 번들 폰트
- **Dancing Script** (DancingScript.ttf) — 온보딩 브랜딩/로고 포인트
- **나눔펜스크립트** (NanumPenScript-Regular.ttf) — 한글 손글씨 강조

---

## 4. 화면 구조 (5탭)

```
온보딩 (최초 1회, 4화면)
  1. 공감 — Before/After 알람 애니메이션
  2. 닉네임 입력 — 타이핑 시퀀스 애니메이션
  3. 체험 — AlarmKit 알람 시뮬레이션
  4. 알람 설정 — 시간 피커 + 권한 요청

메인 앱 (TabBar 5탭)
  탭 1: Home
  탭 2: Alarm
  탭 3: Saved (말씀들)
  탭 4: Meditation (묵상)
  탭 5: Settings (설정/프로필)
```

---

## 5. 홈 화면 (가장 중요한 화면)

풀스크린 감성 이미지 위에 콘텐츠가 float되는 구조.

```
[감성 사진 — 풀스크린 배경]
상단 그라데이션 오버레이 (Black 65% → clear)
  └── 인사말 텍스트 ("지금이 바로 그 타이밍이에요.")
      날짜 + 시간 + 날씨 인라인 (White 85%)

중앙 — 말씀 카드 (floating)
  └── verse_full_ko (Georgia Italic, 22pt, leading text)
      성경 참조 + 테마 태그 (Gold accent)

하단 그라데이션 오버레이 (clear → Black 70%)
  └── (없음 — 탭바는 앱 하단 고정)
```

**말씀 카드 탭 → 바텀시트 (78% 높이)**:
- 해석 (interpretation)
- 오늘의 적용 (application)
- 하단: 저장 버튼

---

## 6. 알람 Stage2 (알람 종료 후 웰컴 스크린)

홈과 동일한 풀스크린 감성 이미지 구조.

```
[감성 이미지]
  └── 인사말 + 날짜/시간 (좌상단 fixed)

중앙
  └── 말씀 카드 (현재 시간대 말씀)

하단 safeAreaInset (반투명 배경)
  └── [말씀 더보기] [■ 종료] 버튼 2개
```

---

## 7. AlarmKit 잠금화면 (iOS 26 시스템 UI)

> 이 화면은 iOS 시스템이 렌더링합니다 (앱이 직접 그리지 않음).
> 디자이너는 **버튼 색상(tintColor)과 버튼 텍스트**만 커스터마이징 가능합니다.

현재 설정:
- tintColor: `dvAccentGold` (#C8972A)
- 스누즈 버튼: "스누즈" (repeat.circle.fill 아이콘)
- 종료 제스처: "밀어서 중단"

---

## 8. 컴포넌트 패턴

### 카드 (말씀 카드, 날씨 위젯)
- 배경: `White 10–15%` + blur
- 테두리: `White 12–20%`, 1px stroke
- Corner radius: 14–18pt
- Shadow: 없음 (글래스모피즘)

### CTA 버튼 (Primary)
- 배경: `dvAccentGold (#C8972A)`
- 텍스트: 딥 네이비 `#1A2340` SemiBold 17pt
- Height: 60pt (온보딩), 50pt (인앱)
- Corner radius: 16pt continuous

### CTA 버튼 (Secondary)
- 배경: `White 10%` + 1px White 18% border
- 텍스트: White Medium 15pt
- Corner radius: 14pt

### 반투명 Pill 버튼 (날씨 조언 등)
- 배경: `White 12%` + Capsule stroke `White 20%`
- 텍스트: White 90%, 14pt

---

## 9. 인터랙션 & 애니메이션

| 상황 | 애니메이션 |
|------|-----------|
| 홈 모드 전환 (아침→낮→저녁) | Cross-dissolve 1.0s |
| 바텀시트 등장 | Slide-up 0.3s |
| Stage2 등장 | Fade-in 0.6s ease-in-out |
| 저장 완료 | Heart pulse (scaleEffect 1.0→1.4→1.0) |
| 온보딩 화면 전환 | Spring(response: 0.5, dampingFraction: 0.85) + offset |

---

## 10. 주요 디자인 원칙

1. **배경이 주인공**: 감성 사진 풀스크린 → UI는 그 위에 float
2. **Dark 기반**: 앱 전체 다크 테마. 라이트 모드 없음
3. **글래스모피즘**: 카드/위젯은 반투명 + blur
4. **골드 포인트**: 강조색은 `#C8972A` 한 가지로 통일
5. **말씀은 Georgia Italic**: 성경 구절만 세리프체, 나머지는 SF Pro
6. **여백 넉넉하게**: 24–28pt horizontal padding
7. **탭바 숨김**: 알람 Stage1/2 진입 시 탭바 완전 숨김

---

## 11. 현재 개발된 화면 목록

| 화면 | 상태 | 파일 |
|------|------|------|
| 홈 (3모드) | ✅ 완성 | HomeView.swift |
| 알람 목록 | ✅ 완성 | AlarmListView.swift |
| 알람 추가/수정 | ✅ 완성 | AlarmAddEditView.swift |
| 알람 Stage1 (전체화면) | ✅ 완성 | AlarmStage1View.swift |
| 알람 Stage2 (웰컴) | ✅ 완성 | AlarmStage2View.swift |
| 말씀들 (저장) | ✅ 완성 | SavedView.swift |
| 말씀 상세 바텀시트 | ✅ 완성 | VerseDetailBottomSheet.swift |
| 묵상 탭 | 🔨 개발 중 | MeditationView.swift |
| 설정 | ✅ 완성 | SettingsView.swift |
| 온보딩 (4화면) | ✅ 완성 | ONBIntroView ~ ONBAlarmPermissionView |
| AlarmKit 잠금화면 | ✅ 완성 | 시스템 UI (커스텀 불가) |
| Live Activity | ✅ 완성 | DailyVerseWidgetsLiveActivity.swift |

---

## 12. 아직 완성되지 않은 / 개선 필요한 영역

다음 영역에서 Stitch의 디자인 도움이 필요합니다:

- [ ] **묵상 탭** (4화면 플로우 — 현재 설계 중)
- [ ] **Live Activity** 잠금화면 "말씀 보기" 버튼 디자인 고도화
- [ ] **홈 화면 날씨 위젯** 정보 밀도 최적화
- [ ] **온보딩** 애니메이션 완성도 향상
- [ ] **알람 목록** 카드 디자인 리프레시
- [ ] **다크 모드 일관성** 전체 점검

---

## 13. 참고 레퍼런스

- **벤치마크 앱**: Calm, YouVersion Bible, Headspace, Alarmy(알라미)
- **무드**: 경건함 + 따뜻함 + 신비로움 (종교적이지 않고 영적인 느낌)
- **이미지 소스**: Genspark Pro 생성 이미지 (성지 풍경, 자연, Yosemite 등)
- **아이콘**: SF Symbols (시스템 통일)
- **앱 아이콘**: 청록→보라 그라데이션 배경, 골드 십자가+태양, 커시브 "DV" 로고

---

*CLAUDE.md 전체 프로젝트 컨텍스트 참조 가능*
