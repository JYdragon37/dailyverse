import Foundation

// MARK: - HourlyForecastItem

struct HourlyForecastItem: Codable, Equatable {
    let time: Date
    let temperature: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let conditionKo: String
}

// MARK: - DailyForecastItem

struct DailyForecastItem: Codable, Equatable {
    let date: Date
    let highTemp: Int
    let lowTemp: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy"
    let conditionKo: String     // "맑음" | "흐림" | "비" | "눈"
    let precipitationProbability: Int  // 강수 확률 0-100%
}

// MARK: - WeatherData

struct WeatherData: Codable, Equatable {
    let temperature: Int
    let condition: String       // "sunny" | "cloudy" | "rainy" | "snowy" | "any"
    let conditionKo: String     // "맑음" | "흐림" | "비" | "눈"
    let humidity: Int
    let dustGrade: String       // "좋음" | "보통" | "나쁨" | "매우나쁨"
    let cityName: String
    let cachedAt: Date

    // 내일 아침 예보
    var tomorrowMorningTemp: Int?
    var tomorrowMorningCondition: String?
    var tomorrowMorningConditionKo: String?

    // v5.2 — 날씨 상세 시트용
    var highTemp: Int?                          // 오늘 최고 기온
    var lowTemp: Int?                           // 오늘 최저 기온
    var hourlyForecast: [HourlyForecastItem]    // 다음 12시간 예보
    var aqi: Int?                               // 대기질 지수 (0–250 매핑 또는 에어코리아 CAI)
    var aqiDescription: String?                 // "좋음" | "보통" | "나쁨" | "매우나쁨"
    // 에어코리아 실측값
    var pm25: Double?                           // PM2.5 실측 (μg/m³)
    var pm10: Double?                           // PM10 실측 (μg/m³)
    var airStation: String?                     // 측정소명
    var uvIndex: Int?                              // 자외선 지수 0-11+
    var precipitationProbability: Int?             // 오늘 강수 확률 %
    var precipitationAmountMM: Double?             // 오늘 예상 강수량 (mm)
    var tomorrowPrecipitationProbability: Int?     // 내일 강수 확률 %
    var dailyForecast: [DailyForecastItem]         // 7일 예보

    init(
        temperature: Int,
        condition: String,
        conditionKo: String,
        humidity: Int,
        dustGrade: String,
        cityName: String,
        cachedAt: Date,
        tomorrowMorningTemp: Int? = nil,
        tomorrowMorningCondition: String? = nil,
        tomorrowMorningConditionKo: String? = nil,
        highTemp: Int? = nil,
        lowTemp: Int? = nil,
        hourlyForecast: [HourlyForecastItem] = [],
        aqi: Int? = nil,
        aqiDescription: String? = nil,
        pm25: Double? = nil,
        pm10: Double? = nil,
        airStation: String? = nil,
        uvIndex: Int? = nil,
        precipitationProbability: Int? = nil,
        precipitationAmountMM: Double? = nil,
        tomorrowPrecipitationProbability: Int? = nil,
        dailyForecast: [DailyForecastItem] = []
    ) {
        self.temperature = temperature
        self.condition = condition
        self.conditionKo = conditionKo
        self.humidity = humidity
        self.dustGrade = dustGrade
        self.cityName = cityName
        self.cachedAt = cachedAt
        self.tomorrowMorningTemp = tomorrowMorningTemp
        self.tomorrowMorningCondition = tomorrowMorningCondition
        self.tomorrowMorningConditionKo = tomorrowMorningConditionKo
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.hourlyForecast = hourlyForecast
        self.aqi = aqi
        self.aqiDescription = aqiDescription
        self.pm25 = pm25
        self.pm10 = pm10
        self.airStation = airStation
        self.uvIndex = uvIndex
        self.precipitationProbability = precipitationProbability
        self.precipitationAmountMM = precipitationAmountMM
        self.tomorrowPrecipitationProbability = tomorrowPrecipitationProbability
        self.dailyForecast = dailyForecast
    }

    /// 강수 타일 표시값 — iOS Weather 패턴
    /// 0% + nil  → "비 없음"
    /// 0% + mm   → "0% · 0.0mm"
    /// >0% + nil → "X%"
    /// >0% + mm  → "X% · Y.Zmm"
    var precipitationDisplay: String {
        let prob = precipitationProbability ?? 0
        if let mm = precipitationAmountMM {
            // 강수량 0mm = 비 없음 처리 (WeatherKit이 맑은 날 0.0 반환)
            if mm <= 0 {
                return prob == 0 ? "비 없음" : "\(prob)%"
            }
            let mmStr = mm.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(mm))mm" : String(format: "%.1fmm", mm)
            return prob == 0 ? "\(mmStr)" : "\(prob)% · \(mmStr)"
        }
        if prob == 0 { return "비 없음" }
        return "\(prob)%"
    }

    /// 강수 타일 subtitle — 강수 있을 때만 표시
    var precipitationAdvice: String? {
        let prob = precipitationProbability ?? 0
        if prob >= 70 { return "우산을 꼭 챙기세요" }
        if prob >= 40 { return "우산 챙기는 게 좋아요" }
        if prob >= 20 { return "가볍게 우산 챙겨요" }
        return nil
    }

    /// PM2.5 기준 미세먼지 상세 설명 (일반인 친화적)
    var dustDescription: String {
        switch dustGrade {
        case "좋음":    return "좋음 · 야외활동 최적"
        case "보통":    return "보통 · 민감군 주의"
        case "나쁨":    return "나쁨 · 외출 자제"
        case "매우나쁨": return "매우나쁨 · 외출 금지"
        default:      return dustGrade
        }
    }

    /// PM2.5 수치 표시 문자열 (있을 때만)
    var pm25DisplayText: String? {
        guard let pm25 else { return nil }
        return "PM2.5 \(Int(pm25.rounded()))㎍/㎥"
    }

    var uvIndexDescription: String {
        guard let uv = uvIndex else { return "정보 없음" }
        switch uv {
        case 0...2:  return "낮음"
        case 3...5:  return "보통"
        case 6...7:  return "높음"
        case 8...10: return "매우 높음"
        default:     return "위험"
        }
    }

    /// UV 표시값 — "등급 · 숫자" 형식, nil 시 시간대 기반 처리
    var uvDisplayValue: String {
        if let uv = uvIndex {
            switch uv {
            case 0...2:  return "낮음 · \(uv)"
            case 3...5:  return "보통 · \(uv)"
            case 6...7:  return "높음 · \(uv)"
            case 8...10: return "매우높음 · \(uv)"
            default:     return "위험 · \(uv)"
            }
        }
        let hour = Calendar.current.component(.hour, from: Date())
        return (hour >= 20 || hour < 6) ? "없음" : "확인 중"
    }

    /// UV 권고 문구 — nil이면 subtitle 미표시
    var uvAdvice: String? {
        if let uv = uvIndex {
            switch uv {
            case 0...2:  return "외출 시 특별한 보호 불필요"
            case 3...5:  return "긴 소매나 모자 권장"
            case 6...7:  return "선크림 필수, 11-15시 자제"
            case 8...10: return "11-15시 외출 최소화"
            default:     return "외출을 피해주세요"
            }
        }
        let hour = Calendar.current.component(.hour, from: Date())
        return (hour >= 20 || hour < 6) ? "야간에는 자외선이 없어요" : nil
    }

    /// 미세먼지 표시값 — "등급 · 수치㎍" (pm25 없으면 등급만)
    var dustDisplayValue: String {
        if let pm25 {
            return "\(dustGrade) · \(Int(pm25.rounded()))㎍"
        }
        return dustGrade
    }

    /// 미세먼지 권고 문구
    var dustAdvice: String {
        switch dustGrade {
        case "좋음":    return "외출하기 좋은 날이에요"
        case "보통":    return "민감한 분은 마스크 권장"
        case "나쁨":    return "마스크 착용, 외출 자제"
        case "매우나쁨": return "외출을 피해주세요"
        default:      return ""
        }
    }

    /// 홈 미니위젯용 — 등급 텍스트만 (공간 제약)
    var dustSummary: String { dustGrade }

    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < 1800  // 30분
    }

    var dustEmoji: String {
        switch dustGrade {
        case "좋음":   return "😊"
        case "보통":   return "🙂"
        case "나쁨":   return "😷"
        case "매우나쁨": return "🤢"
        default:     return "😊"
        }
    }

    /// AQI 게이지용 0.0–1.0 비율
    var aqiFraction: Double {
        let val = aqi ?? dustGradeToAqi
        return min(Double(val) / 250.0, 1.0)
    }

    /// dustGrade → AQI 수치 매핑
    var dustGradeToAqi: Int {
        switch dustGrade {
        case "좋음":   return 50
        case "보통":   return 100
        case "나쁨":   return 150
        case "매우나쁨": return 200
        default:     return 50
        }
    }

    static let placeholder = WeatherData(
        temperature: 20,
        condition: "sunny",
        conditionKo: "맑음",
        humidity: 60,
        dustGrade: "좋음",
        cityName: "서울",
        cachedAt: Date(),
        highTemp: 24,
        lowTemp: 14,
        hourlyForecast: [],
        aqi: 50,
        aqiDescription: "좋음"
    )
}
