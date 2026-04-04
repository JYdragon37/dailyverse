import Foundation
import SwiftUI

struct DVUser: Codable, Equatable {
    let uid: String
    let email: String
    let displayName: String
    let createdAt: Date
    var nickname: String            // v5.1 — 닉네임 (기본: "친구")
    var subscriptionStatus: String  // "free" | "premium" (향후 도입)
    var subscriptionExpireAt: Date?
    var settings: UserSettings
    var pinnedImages: PinnedImages  // v5.1 — 모드별 핀 이미지

    struct UserSettings: Codable, Equatable {
        var timezone: String
        var locationEnabled: Bool
        var notificationEnabled: Bool
        var preferredTheme: String
        var wakeMission: String         // v5.1 — 기본 웨이크업 미션

        static let `default` = UserSettings(
            timezone: TimeZone.current.identifier,
            locationEnabled: false,
            notificationEnabled: false,
            preferredTheme: "hope",
            wakeMission: "none"
        )

        enum CodingKeys: String, CodingKey {
            case timezone
            case locationEnabled  = "location_enabled"
            case notificationEnabled = "notification_enabled"
            case preferredTheme   = "preferred_theme"
            case wakeMission      = "wake_mission"
        }
    }

    struct PinnedImages: Codable, Equatable {
        // v6.0 — 8 Zone
        var deepDark: String?
        var firstLight: String?
        var riseIgnite: String?
        var peakMode: String?
        var recharge: String?
        var secondWind: String?
        var goldenHour: String?
        var windDown: String?

        static let empty = PinnedImages()

        func pinnedImageId(for mode: AppMode) -> String? {
            switch mode {
            case .deepDark:   return deepDark
            case .firstLight: return firstLight
            case .riseIgnite: return riseIgnite
            case .peakMode:   return peakMode
            case .recharge:   return recharge
            case .secondWind: return secondWind
            case .goldenHour: return goldenHour
            case .windDown:   return windDown
            }
        }

        mutating func setPin(_ imageId: String?, for mode: AppMode) {
            switch mode {
            case .deepDark:   deepDark   = imageId
            case .firstLight: firstLight = imageId
            case .riseIgnite: riseIgnite = imageId
            case .peakMode:   peakMode   = imageId
            case .recharge:   recharge   = imageId
            case .secondWind: secondWind = imageId
            case .goldenHour: goldenHour = imageId
            case .windDown:   windDown   = imageId
            }
        }

        enum CodingKeys: String, CodingKey {
            case deepDark   = "deep_dark"
            case firstLight = "first_light"
            case riseIgnite = "rise_ignite"
            case peakMode   = "peak_mode"
            case recharge   = "recharge"
            case secondWind = "second_wind"
            case goldenHour = "golden_hour"
            case windDown   = "wind_down"
        }
    }

    var isPremium: Bool {
        guard subscriptionStatus == "premium",
              let expiry = subscriptionExpireAt else { return false }
        return expiry > Date()
    }

    enum CodingKeys: String, CodingKey {
        case uid, email, settings, nickname
        case displayName         = "display_name"
        case createdAt           = "created_at"
        case subscriptionStatus  = "subscription_status"
        case subscriptionExpireAt = "subscription_expire_at"
        case pinnedImages        = "pinned_images"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid                 = try container.decode(String.self, forKey: .uid)
        email               = try container.decode(String.self, forKey: .email)
        displayName         = try container.decode(String.self, forKey: .displayName)
        createdAt           = try container.decode(Date.self, forKey: .createdAt)
        nickname            = try container.decodeIfPresent(String.self, forKey: .nickname) ?? "친구"
        subscriptionStatus  = try container.decodeIfPresent(String.self, forKey: .subscriptionStatus) ?? "free"
        subscriptionExpireAt = try container.decodeIfPresent(Date.self, forKey: .subscriptionExpireAt)
        settings            = try container.decodeIfPresent(UserSettings.self, forKey: .settings) ?? .default
        pinnedImages        = try container.decodeIfPresent(PinnedImages.self, forKey: .pinnedImages) ?? .empty
    }

    init(
        uid: String,
        email: String,
        displayName: String,
        createdAt: Date = Date(),
        nickname: String = "친구",
        subscriptionStatus: String = "free",
        subscriptionExpireAt: Date? = nil,
        settings: UserSettings = .default,
        pinnedImages: PinnedImages = .empty
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.nickname = nickname
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionExpireAt = subscriptionExpireAt
        self.settings = settings
        self.pinnedImages = pinnedImages
    }
}
