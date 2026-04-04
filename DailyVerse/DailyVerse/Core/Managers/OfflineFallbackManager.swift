import Foundation
import Network

/// 오프라인 상황에서 번들에 내장된 폴백 말씀을 제공하는 매니저.
/// Core Data 캐시도 없을 때 최후의 안전망 역할을 한다.
/// v6.0: 8 Zone 폴백 — 각 Zone별 1개 구절 (총 8개)
final class OfflineFallbackManager: Sendable {
    static let shared = OfflineFallbackManager()
    private init() {}

    // MARK: - Fallback Verses

    /// 번들에 내장된 폴백 말씀 8개 (Zone별 1개) 반환
    func fallbackVerses() -> [Verse] {
        return Verse.fallbackVerses
    }

    /// 현재 Zone에 맞는 폴백 말씀 반환
    func fallbackVerse(for mode: AppMode) -> Verse {
        switch mode {
        case .deepDark:   return Verse.fallbackDeepDark
        case .firstLight: return Verse.fallbackFirstLight
        case .riseIgnite: return Verse.fallbackRiseIgnite
        case .peakMode:   return Verse.fallbackPeakMode
        case .recharge:   return Verse.fallbackRecharge
        case .secondWind: return Verse.fallbackSecondWind
        case .goldenHour: return Verse.fallbackGoldenHour
        case .windDown:   return Verse.fallbackWindDown
        }
    }

    // MARK: - Connectivity Check

    /// NWPathMonitor를 이용해 현재 네트워크 오프라인 여부를 단발성으로 확인한다.
    /// `true` = 오프라인, `false` = 온라인
    func isOffline() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.dailyverse.offline-check")
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status != .satisfied)
            }
            monitor.start(queue: queue)
        }
    }
}
