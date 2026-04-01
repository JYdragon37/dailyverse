import Foundation
import Network

/// 오프라인 상황에서 번들에 내장된 폴백 말씀을 제공하는 매니저.
/// Core Data 캐시도 없을 때 최후의 안전망 역할을 한다.
final class OfflineFallbackManager: Sendable {
    static let shared = OfflineFallbackManager()
    private init() {}

    // MARK: - Fallback Verses

    /// 번들에 내장된 폴백 말씀 3개 (아침/낮/저녁 각 1개) 반환
    func fallbackVerses() -> [Verse] {
        return Verse.fallbackVerses
    }

    /// 현재 모드에 맞는 폴백 말씀 반환
    func fallbackVerse(for mode: AppMode) -> Verse {
        switch mode {
        case .morning:   return Verse.fallbackMorning
        case .afternoon: return Verse.fallbackAfternoon
        case .evening:   return Verse.fallbackEvening
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
