import SwiftUI
import Combine

struct WeatherWidgetView: View {
    let weather: WeatherData?
    let mode: AppMode
    var isLoading: Bool = false

    private var showTomorrowForecast: Bool {
        mode == .evening
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay {
                if let weather {
                    loadedContent(weather: weather)
                } else if isLoading {
                    placeholderContent
                } else {
                    unavailableContent
                }
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func loadedContent(weather: WeatherData) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // 현재 날씨 섹션
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: weatherIconName(weather.condition))
                        .foregroundColor(.dvTemperature)
                        .accessibilityHidden(true)

                    Text(weather.cityName)
                        .font(.dvBody)
                        .foregroundColor(.primary)

                    Text("\(weather.temperature)°C")
                        .font(.dvSubtitle)
                        .foregroundColor(.dvTemperature)
                }

                HStack(spacing: 10) {
                    Text("💧\(weather.humidity)%")
                        .font(.dvCaption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text(weather.dustEmoji)
                        Text(weather.dustGrade)
                            .font(.dvCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // 저녁 모드: 내일 아침 예보
            if showTomorrowForecast,
               let tomorrowTemp = weather.tomorrowMorningTemp,
               let tomorrowCondition = weather.tomorrowMorningCondition {
                Divider()
                    .frame(height: 36)
                    .padding(.horizontal, 12)

                VStack(alignment: .center, spacing: 4) {
                    Text("내일 아침")
                        .font(.dvCaption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: weatherIconName(tomorrowCondition))
                            .font(.system(size: 12))
                            .foregroundColor(.dvTemperature)
                            .accessibilityHidden(true)

                        Text("\(tomorrowTemp)°C")
                            .font(.dvBody)
                            .foregroundColor(.dvTemperature)
                    }
                }
            }
        }
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription(weather: weather))
    }

    private var placeholderContent: some View {
        HStack {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
            Text("날씨 정보를 불러오는 중...")
                .font(.dvCaption)
                .foregroundColor(.secondary)
        }
        .padding(12)
    }

    private var unavailableContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "location.slash")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .accessibilityHidden(true)
            Text("날씨 정보 없음  —")
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func weatherIconName(_ condition: String) -> String {
        switch condition {
        case "sunny":   return "sun.max.fill"
        case "cloudy":  return "cloud.fill"
        case "rainy":   return "cloud.rain.fill"
        case "snowy":   return "cloud.snow.fill"
        default:        return "sun.max.fill"
        }
    }

    private func accessibilityDescription(weather: WeatherData) -> String {
        var desc = "\(weather.cityName) \(weather.temperature)도 \(weather.conditionKo) 습도 \(weather.humidity)% 미세먼지 \(weather.dustGrade)"
        if showTomorrowForecast, let temp = weather.tomorrowMorningTemp {
            desc += " 내일 아침 \(temp)도"
        }
        return desc
    }
}

#Preview("날씨 데이터 있음") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            WeatherWidgetView(weather: .placeholder, mode: .morning)
            WeatherWidgetView(
                weather: WeatherData(
                    temperature: 14,
                    condition: "cloudy",
                    conditionKo: "흐림",
                    humidity: 72,
                    dustGrade: "보통",
                    cityName: "서울",
                    cachedAt: Date(),
                    tomorrowMorningTemp: 12,
                    tomorrowMorningCondition: "rainy"
                ),
                mode: .evening
            )
        }
        .padding(.horizontal, 20)
    }
}

#Preview("날씨 없음") {
    ZStack {
        Color.black.ignoresSafeArea()
        WeatherWidgetView(weather: nil, mode: .morning)
            .padding(.horizontal, 20)
    }
}
