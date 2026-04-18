import SwiftUI
import Combine

struct AlarmStage1View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator
    @State private var weatherForForecast: WeatherData?
    @State private var showVolumeWarning: Bool = false
    @State private var todayVerse: Verse? = nil
    @State private var weatherAdvice: String = ""

    var body: some View {
        ZStack {
            // ── 전체화면 배경 ──
            backgroundLayer
            Color.black.opacity(0.50).ignoresSafeArea()

            // ── 콘텐츠: 날씨 조언 + 시간별 예보(상단) → 날씨 스트립 → 말씀 → 버튼 ──
            VStack(spacing: 0) {

                // ── 상단: 날씨 GPT 조언 pill + 날씨 스트립 ──
                VStack(spacing: 12) {
                    if !weatherAdvice.isEmpty {
                        Text(weatherAdvice)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.90))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 1))
                            )
                    }

                    // 날씨 스트립 — pill 바로 아래 배치
                    if let weather = weatherForForecast {
                        Stage1WeatherStrip(weather: weather)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                if let verse = todayVerse {
                    VStack(spacing: 14) {
                        Text(verse.verseShortKo)
                            .font(.dvStage1Verse)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 32)

                        Text(verse.reference)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    if coordinator.canSnooze {
                        Button { coordinator.snooze() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "alarm").accessibilityHidden(true)
                                Text("스누즈 \(coordinator.activeSnoozeInterval)분")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                    } else {
                        Text("더 이상 스누즈할 수 없어요")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                    }

                    Button { coordinator.dismissToStage2() } label: {
                        Text("말씀 보기")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dvAccentGold)
                            .foregroundColor(.dvPrimaryDeep)
                            .cornerRadius(14)
                    }
                    .accessibilityLabel("알람 종료 후 말씀 화면으로 이동")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        // 볼륨 경고 토스트
        .overlay(alignment: .top) {
            if showVolumeWarning {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.slash.fill")
                    Text("미디어 볼륨을 올려주세요 (옆면 버튼 ▲)")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.85))
                .clipShape(Capsule())
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showVolumeWarning)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .task {
            // 날씨 로드
            let resolvedWeather: WeatherData?
            if let w = coordinator.activeWeather, !w.hourlyForecast.isEmpty {
                weatherForForecast = w
                resolvedWeather = w
            } else if let cached = WeatherCacheManager().load() {
                weatherForForecast = cached
                coordinator.activeWeather = cached
                resolvedWeather = cached
            } else {
                resolvedWeather = nil
            }

            // 날씨 GPT 조언 로드 (forceCurrentWeather: true — zone 무관하게 현재 날씨 기준)
            if let w = resolvedWeather {
                let mode = AppMode.current()
                weatherAdvice = await WeatherAdviceService.shared.fetchAdvice(
                    for: w,
                    zone: mode.rawValue,
                    forceCurrentWeather: true
                )
            }

            // 알람 발동 시점의 Zone 기준으로 말씀 로드 (coordinator.activeMode 우선)
            // AppMode.current()를 사용하면 앱 진입 시점이 다를 경우 Zone이 달라질 수 있음
            let mode = coordinator.activeMode
            if let id = DailyCacheManager.shared.getVerseId(for: mode),
               let verse = DailyCacheManager.shared.loadCachedVerse(id: id) {
                todayVerse = verse
            } else {
                todayVerse = Verse.fallbackVerses.first { $0.mode.contains(mode.rawValue) }
                             ?? Verse.fallbackRiseIgnite
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dvAlarmVolumeTooLow)) { _ in
            withAnimation { showVolumeWarning = true }
            // 5초 후 자동 숨김
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { showVolumeWarning = false }
            }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let urlStr = coordinator.activeImage?.storageUrl,
           let url = URL(string: urlStr) {
            RemoteImageView(url: url) { darkFallbackGradient }
                .ignoresSafeArea()
        } else {
            darkFallbackGradient
        }
    }

    private var darkFallbackGradient: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.18)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - 콤팩트 날씨 스트립
// 날씨 추가 전 Spacer-말씀-Spacer-버튼 비율을 유지하기 위해
// 최소 높이의 2줄 구성: (1) 현재 날씨 한 줄 + (2) 시간별 예보 한 줄

private struct Stage1WeatherStrip: View {
    let weather: WeatherData

    private var conditionIcon: String {
        switch weather.condition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "cloud.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 줄 1: 현재 날씨 (아이콘 + 도시 + 온도 + 상태 + 습도)
            HStack(spacing: 6) {
                Image(systemName: conditionIcon)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))

                Text(weather.cityName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.80))

                Text("\(weather.temperature)°")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("·")
                    .foregroundColor(.white.opacity(0.35))

                Text(weather.conditionKo)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))

                Text("·")
                    .foregroundColor(.white.opacity(0.35))

                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                    Text("\(weather.humidity)%")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.55))
            }

            // 줄 2: 시간별 예보 — 5개, 현재 시각 기준 가장 가까운 예보를 "지금"으로 표시
            if !weather.hourlyForecast.isEmpty {
                let forecasts = Array(weather.hourlyForecast.prefix(5))
                let now = Date()
                let nowIdx = forecasts.enumerated().min(by: {
                    abs($0.element.time.timeIntervalSince(now)) < abs($1.element.time.timeIntervalSince(now))
                })?.offset ?? 0
                HStack(spacing: 0) {
                    ForEach(Array(forecasts.enumerated()), id: \.offset) { idx, item in
                        CompactHourlyItem(item: item, isNow: idx == nowIdx)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
    }
}

private struct CompactHourlyItem: View {
    let item: HourlyForecastItem
    let isNow: Bool

    private var timeLabel: String {
        if isNow { return "지금" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h시"
        return f.string(from: item.time)
    }

    private var conditionIcon: String {
        switch item.condition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "sun.max.fill"
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            // 고정 높이 → 모든 아이템 높이 동일 보장
            Text(timeLabel)
                .font(.system(size: 12, weight: isNow ? .semibold : .regular))
                .foregroundColor(isNow ? .white : .white.opacity(0.70))
                .frame(height: 16)
                .lineLimit(1)
            Image(systemName: conditionIcon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.90))
                .frame(width: 28, height: 28)
            Text("\(item.temperature)°")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 18)
        }
    }
}

#Preview {
    let coordinator = AlarmCoordinator()
    coordinator.activeWeather = WeatherData(
        temperature: 14, condition: "sunny", conditionKo: "맑음",
        humidity: 67, dustGrade: "보통", cityName: "Seoul", cachedAt: Date(),
        hourlyForecast: [
            HourlyForecastItem(time: Date(), temperature: 15, condition: "cloudy", conditionKo: "흐림"),
            HourlyForecastItem(time: Date().addingTimeInterval(3600), temperature: 17, condition: "cloudy", conditionKo: "흐림"),
            HourlyForecastItem(time: Date().addingTimeInterval(7200), temperature: 15, condition: "rainy", conditionKo: "비"),
            HourlyForecastItem(time: Date().addingTimeInterval(10800), temperature: 13, condition: "rainy", conditionKo: "비"),
            HourlyForecastItem(time: Date().addingTimeInterval(14400), temperature: 11, condition: "sunny", conditionKo: "맑음"),
        ]
    )
    return AlarmStage1View().environmentObject(coordinator)
}
