import Foundation

public struct CatalogDocument: Decodable, Sendable {
    public let generatedAt: String
    public let games: [Game]

    public init(generatedAt: String, games: [Game]) {
        self.generatedAt = generatedAt
        self.games = games
    }
}
