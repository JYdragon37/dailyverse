import Foundation

struct DVUser: Codable, Equatable {
    let uid: String
    let email: String
    let displayName: String
    let createdAt: Date
    var subscriptionStatus: String   // "free" | "premium"
    var subscriptionExpireAt: Date?
    var settings: UserSettings

    struct UserSettings: Codable, Equatable {
        var timezone: String
        var locationEnabled: Bool
        var notificationEnabled: Bool
        var preferredTheme: String

        static let `default` = UserSettings(
            timezone: TimeZone.current.identifier,
            locationEnabled: false,
            notificationEnabled: false,
            preferredTheme: "hope"
        )
    }

    var isPremium: Bool {
        guard subscriptionStatus == "premium",
              let expiry = subscriptionExpireAt else { return false }
        return expiry > Date()
    }

    enum CodingKeys: String, CodingKey {
        case uid, email, settings
        case displayName = "display_name"
        case createdAt = "created_at"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpireAt = "subscription_expire_at"
    }
}
