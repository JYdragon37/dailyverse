# Morning Manna — Splash Screen Archive

> 작성일: 2026-04-23

---

## 현재 사용 중 (v4.3 — 브랜드 가이드라인 적용)

**파일**: `DailyVerse/Features/Splash/SplashView.swift`

로고 이미지를 그대로 사용하는 단순하고 안정적인 구현.

### 브랜드 가이드라인 준수 사항
| 항목 | 값 | 근거 |
|------|-----|------|
| 로고 너비 | 화면 100%, scaledToFit | 높이 64% 수준 (Netflix 23%, Disney+ 34%) |
| 로고 상단 여백 | 화면 8% | 상단 > 하단 여백 원칙 |
| 워드마크 크기 | 18pt Regular | 업계 표준 16-20pt |
| 워드마크 자간 | 3.5 | 과도하지 않은 프리미엄 자간 |
| 워드마크 위치 | 로고 하단 32pt | 직하 배치 |
| 배경 연속성 | 이미지 엣지 색상 pin | 박스 경계 무음처리 |

### 구성
- **배경**: 이미지 상·하단 엣지 색상에 완전히 맞춘 LinearGradient (상단 sky blue pin, 하단 coral pin)
- **로고**: `Assets.xcassets/SplashBackground.imageset/splash_logo.png`
  - 원본: `design-assets/splash/Using_the_supplied_reference_images_create_a_refi-1776929278986.png`
  - 820×1140px, scaledToFit 화면 전체 너비
- **워드마크**: `morning manna` — Pretendard Regular 18pt, tracking 3.5, white 82%
- **애니메이션**: 로고 0.65s easeOut fade-in + 8pt 위로 settle → 워드마크 0.55s delay

### Assets 경로
```
DailyVerse/DailyVerse/Assets.xcassets/SplashBackground.imageset/
  splash_logo.png  ← 현재 사용 이미지 (820×1140px)
  Contents.json
```

---

## 아카이브: 네온 크로스 버전 (v3.2 — 코드 기반)

**파일**: `design-assets/splash-archive/SplashView_neon_v3.2.swift`

SwiftUI 코드로 완전 구현한 프리미엄 스플래시.
이미지 에셋 없이 순수 SwiftUI 코드만으로 동작.

### 구성 요소
- **배경**: 4-stop inline LinearGradient (참조 이미지 색상 직접 매칭)
- **아치 프레임** (`ArchGlassFrame`): 아치 Shape + 얇은 오팔빛 테두리 (1pt stroke)
- **십자가** (`CrossLogo`): 4개 NeonBar + 교차점 White Bloom
- **워드마크**: `morning manna` — Pretendard Light 14pt

### 네온 바 설계 원칙
```
NeonBar (4개)
├── 글로우 ZStack — .blendMode(.screen)  ← 가산 발광
│   ├── 외부 블룸: +18px frame, blur 8, opacity 0.44
│   └── 내부 블룸: +5px frame, blur 2.5, opacity 0.72
└── 코어 — .blendMode(.normal)  ← 색상 채도 유지
```

> **주의**: 코어에 `.screen` 적용 시 밝은 배경에서 색상이 세탁됨.
> 반드시 글로우=`.screen`, 코어=`.normal` 분리 적용해야 함.

### 색상 토큰
| 요소 | 색상 | Hex |
|------|------|-----|
| 메인 Cyan | teal-cyan | `#6FCDE8` |
| 보조 Pink | rose-pink | `#EC90AE` |
| 배경 Top | sky blue | `#8DC7EB` |
| 배경 Mid | lavender | `#BFB0DC` |
| 배경 Low | mauve | `#D4B1C2` |
| 배경 Bottom | coral | `#EFB8AE` |

### 애니메이션 타임라인
```
Phase 1 (0.00s): 십자가 fade-in + 10pt 위로 settle (0.55s easeOut)
Phase 2 (0.35s): 아치 프레임 scale(0.97→1.0) + fade (0.50s easeOut)
Phase 3 (0.72s): 워드마크 fade-in (0.40s easeOut)
Phase 4 (1.20s): 글로우 펄스 2.2s 반복 (easeInOut, autoreverses)
```

### 복원 방법
1. `SplashView_neon_v3.2.swift` → `DailyVerse/Features/Splash/SplashView.swift` 복사
2. 빌드 확인
3. 콜드 런치 시 Firebase 초기화(~2s) 후 스플래시 표시됨 — 정상

---

## 참조 이미지 원본

| 파일 | 설명 |
|------|------|
| `Using_the_supplied_..._1776929278986.png` | 아치 + 크로스 최종 구성 ← **현재 사용** |
| `Using_the_supplied_..._1776929260526.png` | 아치 + 크로스 (동일 구성, 대안) |
| `Create_an_ultra-minimal_..._1776929303399.png` | 아치 없이 크로스만 (미니멀 버전) |

모두 `design-assets/splash/` 폴더에 보존.
