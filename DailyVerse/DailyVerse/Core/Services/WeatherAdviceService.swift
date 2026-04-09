import Foundation

/// OpenAI GPT 기반 개인화 날씨 조언 서비스
///
/// 캐시 전략: Zone 변경 시에만 새 조언 생성 (배경 이미지 갱신과 동일 주기)
/// - 캐시 키: "{zone}_{yyyy-MM-dd}" — 같은 날 같은 Zone이면 API 재호출 없음
/// - UserDefaults에 영구 저장 — 앱 재시작해도 유지
/// - 비용 최적화: 유저당 하루 2~4회 최대 (Zone 전환 횟수)
actor WeatherAdviceService {
    static let shared = WeatherAdviceService()
    private init() {}

    private let udKeyPrefix = "weatherAdvice_"

    /// Zone 변경 시 호출 — Zone + 날짜 기반 캐시 확인 후 필요 시 GPT 호출
    func fetchAdvice(for weather: WeatherData, zone: String) async -> String {
        let key = cacheKey(zone: zone)

        // UserDefaults 영구 캐시 확인
        if let cached = UserDefaults.standard.string(forKey: udKeyPrefix + key),
           !cached.isEmpty {
            return cached
        }

        // 새 조언 생성
        let advice = await callGPT(weather: weather, zone: zone)
                     ?? fallbackAdvice(weather: weather, zone: zone)

        // 영구 캐시 저장 (다음 Zone 전환까지 유지)
        UserDefaults.standard.set(advice, forKey: udKeyPrefix + key)

        return advice
    }

    /// Zone + 오늘 날짜 기반 캐시 키
    private func cacheKey(zone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(zone)_\(formatter.string(from: Date()))"
    }

    /// 이전 Zone 캐시 정리 (불필요한 UserDefaults 누적 방지)
    func clearOldCache(currentZone: String) {
        let currentKey = udKeyPrefix + cacheKey(zone: currentZone)
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(udKeyPrefix) && key != currentKey {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - GPT 호출

    private func callGPT(weather: WeatherData, zone: String) async -> String? {
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String,
              !apiKey.isEmpty,
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return nil
        }

        let context = zoneContext(zone: zone)
        let weatherDesc = buildWeatherDescription(weather: weather, zone: zone)

        let systemPrompt = """
        당신은 한국 사용자를 위한 친근한 날씨 비서입니다.
        날씨 데이터와 현재 시간대를 보고 실용적인 조언을 한 문장으로 해주세요.
        - 반드시 한국어로 답하세요
        - 40자 이내로 간결하게
        - 이모지 1개 포함
        - 반말로 친근하게
        - 지금 이 시간대에 맞는 구체적 행동 제안
        """

        let userPrompt = """
        현재 시간대: \(context)
        \(weatherDesc)

        이 시간대와 날씨에 맞는 조언을 한 문장으로 해줘.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 80,
            "temperature": 0.7
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Zone별 컨텍스트

    private func zoneContext(zone: String) -> String {
        switch zone {
        case "deep_dark":   return "자정~새벽 3시 (수면 중 or 야행성)"
        case "first_light": return "새벽 3~6시 (이른 기상, 하루 준비)"
        case "rise_ignite": return "오전 6~9시 (아침, 외출 전)"
        case "peak_mode":   return "오전 9~12시 (활동 피크, 집중 시간)"
        case "recharge":    return "오후 12~15시 (점심 후, 오후 활동)"
        case "second_wind": return "오후 15~18시 (오후 중반, 마무리)"
        case "golden_hour": return "오후 18~21시 (저녁, 내일 준비)"
        case "wind_down":   return "오후 21~24시 (취침 전, 내일 대비)"
        default:            return "현재 시간대"
        }
    }

    private func buildWeatherDescription(weather: WeatherData, zone: String) -> String {
        var lines: [String] = []

        // 저녁/취침 전 → 내일 날씨 중심
        let isFutureFocus = zone == "golden_hour" || zone == "wind_down"

        if isFutureFocus {
            lines.append("내일 날씨: \(weather.tomorrowMorningConditionKo ?? weather.conditionKo)")
            if let temp = weather.tomorrowMorningTemp { lines.append("내일 아침 기온: \(temp)°C") }
            if let prob = weather.tomorrowPrecipitationProbability, prob > 0 {
                lines.append("내일 강수 확률: \(prob)%")
            }
        } else {
            lines.append("현재 날씨: \(weather.conditionKo) \(weather.temperature)°C")
            lines.append("습도: \(weather.humidity)%")
            if let uv = weather.uvIndex { lines.append("자외선: \(uv) (\(weather.uvIndexDescription))") }
            if let prob = weather.precipitationProbability, prob > 0 {
                lines.append("강수 확률: \(prob)%")
            }
        }
        lines.append("미세먼지: \(weather.dustGrade)")
        return lines.joined(separator: "\n")
    }

    // MARK: - 룰 기반 폴백

    private func fallbackAdvice(weather: WeatherData, zone: String) -> String {
        let isFutureFocus = zone == "golden_hour" || zone == "wind_down"

        if isFutureFocus {
            let prob = weather.tomorrowPrecipitationProbability ?? 0
            let cond = weather.tomorrowMorningCondition ?? weather.condition
            if cond == "rainy" || prob >= 50 { return "☂️ 내일 우산 챙기는 거 잊지 마!" }
            if cond == "snowy" { return "🧥 내일 눈 와요, 따뜻하게 입어요" }
            let temp = weather.tomorrowMorningTemp ?? weather.temperature
            if temp <= 5 { return "🧣 내일 아침 꽤 추워요, 겉옷 챙겨요" }
            return "😊 내일 날씨 괜찮아요, 좋은 하루 되세요"
        } else {
            if weather.condition == "rainy" { return "☂️ 오늘 비 와요, 우산 챙겨요" }
            let uv = weather.uvIndex ?? 0
            if uv >= 6 { return "🧴 자외선 강해요, 선크림 바르고 나가요" }
            if weather.dustGrade == "나쁨" || weather.dustGrade == "매우나쁨" {
                return "😷 미세먼지 나빠요, 마스크 챙겨요"
            }
            return "☀️ 오늘 날씨 좋아요, 나들이 어때요?"
        }
    }
}
