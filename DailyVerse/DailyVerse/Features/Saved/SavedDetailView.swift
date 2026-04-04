import SwiftUI
import Combine

struct SavedDetailView: View {
    let savedVerse: SavedVerse
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    private var fallbackVerse: Verse? {
        Verse.fallbackVerses.first { $0.id == savedVerse.verseId }
    }

    private var verseText: String {
        fallbackVerse?.textFullKo ?? "저장된 말씀을 불러올 수 없어요"
    }

    private var verseReference: String {
        fallbackVerse?.reference ?? ""
    }

    private var modeText: String {
        switch savedVerse.mode {
        case "deep_dark":   return "🌑 Deep Dark"
        case "first_light": return "🌒 First Light"
        case "rise_ignite": return "🌅 Rise & Ignite"
        case "peak_mode":   return "⚡ Peak Mode"
        case "recharge":    return "☀️ Recharge"
        case "second_wind": return "🌤 Second Wind"
        case "golden_hour": return "🌇 Golden Hour"
        case "wind_down":   return "🌙 Wind Down"
        // 레거시 호환
        case "morning":     return "🌅 아침"
        case "afternoon":   return "☀️ 낮"
        case "evening":     return "🌇 저녁"
        case "dawn":        return "🌒 새벽"
        default:            return savedVerse.mode
        }
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd  HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return "\(formatter.string(from: savedVerse.savedAt))  \(modeText)"
    }

    private var weatherIconName: String {
        switch savedVerse.weatherCondition {
        case "sunny":  return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy":  return "cloud.rain.fill"
        case "snowy":  return "cloud.snow.fill"
        default:       return "cloud.fill"
        }
    }

    private var backgroundGradient: LinearGradient {
        // AppMode rawValue로 매핑하여 각 Zone의 그라데이션 사용
        let mode = AppMode(rawValue: savedVerse.mode) ?? AppMode.current()
        return LinearGradient(colors: mode.gradientColors, startPoint: .top, endPoint: .bottom)
    }

    private var shareText: String {
        var parts = [String]()
        parts.append("\"\(verseText)\"")
        if !verseReference.isEmpty {
            parts.append(verseReference)
        }
        parts.append("")
        parts.append("DailyVerse")
        return parts.joined(separator: "\n")
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 풀스크린 배경
            backgroundGradient
                .ignoresSafeArea()

            // 닫기 버튼
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(10)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
            }
            .accessibilityLabel("닫기")
            .padding(.top, 56)
            .padding(.trailing, 20)

            // 메인 콘텐츠
            VStack(spacing: 0) {
                Spacer()

                // 말씀 영역
                VStack(spacing: 16) {
                    Text("\"\(verseText)\"")
                        .font(.dvVerseFullText)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .accessibilityLabel(verseText)

                    if !verseReference.isEmpty {
                        Text(verseReference)
                            .font(.dvReference)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // 메타데이터
                VStack(spacing: 6) {
                    // 날짜·시간·모드
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .accessibilityHidden(true)
                        Text(formattedDateTime)
                    }
                    .accessibilityLabel("저장일시 \(formattedDateTime)")

                    // 날씨
                    HStack(spacing: 8) {
                        Image(systemName: weatherIconName)
                            .accessibilityHidden(true)
                        Text("\(savedVerse.weatherTemp)°C")
                        Image(systemName: "drop.fill")
                            .accessibilityHidden(true)
                        Text("\(savedVerse.weatherHumidity)%")
                    }
                    .accessibilityLabel("날씨 기온 \(savedVerse.weatherTemp)도 습도 \(savedVerse.weatherHumidity)퍼센트")

                    // 위치
                    if !savedVerse.locationName.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin")
                                .accessibilityHidden(true)
                            Text(savedVerse.locationName)
                        }
                        .accessibilityLabel("저장 위치 \(savedVerse.locationName)")
                    }
                }
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 24)

                // 하단 버튼
                HStack(spacing: 16) {
                    Button {
                        handleDelete()
                    } label: {
                        Label("저장 해제", systemImage: "heart.slash.fill")
                            .font(.dvBody)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .accessibilityLabel("이 말씀 저장 해제")

                    ShareLink(item: shareText) {
                        Label("공유", systemImage: "square.and.arrow.up")
                            .font(.dvBody)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .accessibilityLabel("이 말씀 공유하기")
                }
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Delete

    private func handleDelete() {
        onDelete?()
        dismiss()
    }
}

// MARK: - Preview

#Preview("아침 말씀") {
    let savedVerse = SavedVerse(
        id: "saved_preview_001",
        verseId: "fallback_morning",
        savedAt: Date(),
        mode: "morning",
        weatherTemp: 18,
        weatherCondition: "sunny",
        weatherHumidity: 65,
        locationName: "서울 강남구"
    )
    SavedDetailView(savedVerse: savedVerse, onDelete: nil)
        .environmentObject(AuthManager())
}

#Preview("저녁 말씀") {
    let savedVerse = SavedVerse(
        id: "saved_preview_002",
        verseId: "fallback_evening",
        savedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
        mode: "evening",
        weatherTemp: 8,
        weatherCondition: "rainy",
        weatherHumidity: 90,
        locationName: "부산 해운대구"
    )
    SavedDetailView(savedVerse: savedVerse, onDelete: nil)
        .environmentObject(AuthManager())
}

#Preview("위치 없음") {
    let savedVerse = SavedVerse(
        id: "saved_preview_003",
        verseId: "fallback_afternoon",
        savedAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date(),
        mode: "afternoon",
        weatherTemp: 24,
        weatherCondition: "cloudy",
        weatherHumidity: 55,
        locationName: ""
    )
    SavedDetailView(savedVerse: savedVerse, onDelete: nil)
        .environmentObject(AuthManager())
}
