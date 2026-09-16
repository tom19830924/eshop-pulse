import Foundation

struct CatalogDocument: Decodable, Sendable {
    let generatedAt: String
    let games: [Game]
}
