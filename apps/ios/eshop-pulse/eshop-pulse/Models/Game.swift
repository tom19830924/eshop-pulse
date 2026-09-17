import Foundation

struct Game: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let releaseDate: String?
    let imageURL: URL?
    let sourceURL: URL?
    let price: GamePrice
    let supportedLanguages: [String]?
    let productType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case releaseDate
        case imageURL = "imageUrl"
        case sourceURL = "sourceUrl"
        case price
        case supportedLanguages
        case productType
    }

    var productTypes: [String] {
        guard let productType else { return [] }

        return productType
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var releaseDateValue: Date? {
        guard let releaseDate else { return nil }
        return try? Date(releaseDate, strategy: .iso8601)
    }
}
