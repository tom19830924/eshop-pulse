import Foundation

public struct Game: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let releaseDate: String?
    public let imageURL: URL?
    public let sourceURL: URL?
    public let price: GamePrice
    public let supportedLanguages: [String]?
    public let productType: String?

    public init(
        id: String,
        title: String,
        releaseDate: String?,
        imageURL: URL?,
        sourceURL: URL?,
        price: GamePrice,
        supportedLanguages: [String]?,
        productType: String?
    ) {
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.price = price
        self.supportedLanguages = supportedLanguages
        self.productType = productType
    }

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

}
