import Foundation

struct Game: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let releaseDate: String?
    let sourceURL: URL?
    let price: GamePrice

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case releaseDate
        case sourceURL = "sourceUrl"
        case price
    }

    var releaseDateValue: Date? {
        guard let releaseDate else { return nil }
        return try? Date(releaseDate, strategy: .iso8601)
    }
}
