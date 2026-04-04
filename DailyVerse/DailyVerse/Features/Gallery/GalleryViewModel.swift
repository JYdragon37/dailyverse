import SwiftUI
import Combine

@MainActor
final class GalleryViewModel: ObservableObject {

    // MARK: - Mode Filter

    enum ModeFilter: String, CaseIterable {
        case all        = "all"
        case deepDark   = "deep_dark"
        case firstLight = "first_light"
        case riseIgnite = "rise_ignite"
        case peakMode   = "peak_mode"
        case recharge   = "recharge"
        case secondWind = "second_wind"
        case goldenHour = "golden_hour"
        case windDown   = "wind_down"

        var displayName: String {
            switch self {
            case .all:        return "전체"
            case .deepDark:   return "🌑 Deep Dark"
            case .firstLight: return "🌒 First Light"
            case .riseIgnite: return "🌅 Rise & Ignite"
            case .peakMode:   return "⚡ Peak Mode"
            case .recharge:   return "☀️ Recharge"
            case .secondWind: return "🌤 Second Wind"
            case .goldenHour: return "🌇 Golden Hour"
            case .windDown:   return "🌙 Wind Down"
            }
        }
    }

    // MARK: - Published

    @Published var images: [VerseImage] = []
    @Published var selectedFilter: ModeFilter = .all
    @Published var isLoading = false
    @Published var pinnedImages: DVUser.PinnedImages = .empty

    // MARK: - Filtered Images

    var filteredImages: [VerseImage] {
        guard selectedFilter != .all else { return images }
        return images.filter { $0.mode.contains(selectedFilter.rawValue) || $0.mode.contains("all") }
    }

    func isPinned(_ image: VerseImage) -> Bool {
        AppMode.allCases.contains { pinnedImages.pinnedImageId(for: $0) == image.id }
    }

    // MARK: - Data Loading

    private let firestoreService = FirestoreService()

    func loadImages() async {
        isLoading = true
        defer { isLoading = false }
        do {
            images = try await firestoreService.fetchImages()
        } catch {
            #if DEBUG
            print("⚠️ [Gallery] 이미지 로드 실패: \(error)")
            #endif
        }
    }

    func loadPinnedImages(userId: String) async {
        if let user = try? await firestoreService.fetchUser(uid: userId) {
            pinnedImages = user.pinnedImages
        }
    }

    // MARK: - Pin / Unpin

    func pinImage(_ image: VerseImage, forMode mode: AppMode, userId: String?) async {
        guard image.isHomeSafe else { return }
        pinnedImages.setPin(image.id, for: mode)

        if let uid = userId {
            try? await firestoreService.updatePinnedImage(image.id, forMode: mode, userId: uid)
        }
        // UserDefaults에도 저장 (오프라인 지원)
        UserDefaults.standard.set(image.id, forKey: "pinnedImage_\(mode.rawValue)")
    }

    func unpinImage(forMode mode: AppMode, userId: String?) async {
        pinnedImages.setPin(nil, for: mode)

        if let uid = userId {
            try? await firestoreService.updatePinnedImage(nil, forMode: mode, userId: uid)
        }
        UserDefaults.standard.removeObject(forKey: "pinnedImage_\(mode.rawValue)")
    }
}
