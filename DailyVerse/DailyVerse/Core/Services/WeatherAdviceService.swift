import Foundation

/// OpenAI GPT 기반 개인화 날씨 조언 서비스
actor WeatherAdviceService {
    static let shared = WeatherAdviceService()
    private init() {}

    /// 마지막 조언 캐시 (날씨 조건 변경 전까지 재사용)
    private var cachedAdvice: String?
    private var cacheKey: String?

    func fetchAdvice(for weather: WeatherData) async -> String {
        let key = makeCacheKey(weather: weather)
        if let cached = cachedAdvice, cacheKey == key { return cached }

        let advice = await callGPT(weather: weather) ?? fallbackAdvice(weather: weather)
        cachedAdvice = advice
        cacheKey = key
        return advice
    }

    private func makeCacheKey(weather: WeatherData) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeSlot = hour < 12 ? "am" : "pm"
        return "\(weather.condition)_\(weather.temperature)_\(weather.dustGrade)_\(timeSlot)"
    }

    private func callGPT(weather: WeatherData) async -> String? {
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String,
              !apiKey.isEmpty,
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return nil
        }

        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = hour >= 18 || hour < 6
        let timeContext = isEvening ? "저녁 시간대 (내일 날씨 안내)" : "아침/낮 시간대 (오늘 외출 전 안내)"

        let weatherDesc = buildWeatherDescription(weather: weather, isEvening: isEvening)

        let systemPrompt = """
        당신은 한국 사용자를 위한 친근한 날씨 비서입니다.
        날씨 데이터를 보고 사용자에게 실용적인 조언을 한 문장으로 해주세요.
        - 반드시 한국어로 답하세요
        - 40자 이내로 간결하게
        - 이모지 1개 포함
        - 반말로 친근하게
        - 실천 가능한 구체적 행동 제안
        """

        let userPrompt = """
        현재: \(timeContext)
        \(weatherDesc)

        이 날씨에 맞는 조언을 한 문장으로 해줘.
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

    private func buildWeatherDescription(weather: WeatherData, isEvening: Bool) -> String {
        var lines: [String] = []
        if isEvening {
            lines.append("내일 날씨: \(weather.tomorrowMorningConditionKo ?? weather.conditionKo)")
            if let temp = weather.tomorrowMorningTemp { lines.append("내일 아침 기온: \(temp)°C") }
            if let prob = weather.tomorrowPrecipitationProbability, prob > 0 { lines.append("강수 확률: \(prob)%") }
        } else {
            lines.append("오늘 날씨: \(weather.conditionKo) \(weather.temperature)°C")
            lines.append("습도: \(weather.humidity)%")
            if let uv = weather.uvIndex { lines.append("자외선: \(uv) (\(weather.uvIndexDescription))") }
            if let prob = weather.precipitationProbability, prob > 0 { lines.append("강수 확률: \(prob)%") }
        }
        lines.append("미세먼지: \(weather.dustGrade)")
        return lines.joined(separator: "\n")
    }

    /// GPT 실패 시 간단한 룰 기반 폴백
    private func fallbackAdvice(weather: WeatherData) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = hour >= 18 || hour < 6

        if isEvening {
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
            if weather.dustGrade == "나쁨" || weather.dustGrade == "매우나쁨" { return "😷 미세먼지 나빠요, 마스크 챙겨요" }
            return "☀️ 오늘 날씨 좋아요, 나들이 어때요?"
        }
    }
}
