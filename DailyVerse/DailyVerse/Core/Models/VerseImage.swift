import Foundation

struct VerseImage: Identifiable, Codable, Equatable {
    let id: String
    let filename: String
    let storageUrl: String
    let source: String
    let sourceUrl: String
    let license: String
    let mode: [String]
    let theme: [String]
    let mood: [String]
    let season: [String]
    let weather: [String]
    let tone: String     // "bright" | "mid" | "dark"
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "image_id"
        case filename
        case storageUrl = "storage_url"
        case sourceUrl = "source_url"
        case source, license, mode, theme, mood, season, weather, tone, status
    }
}
