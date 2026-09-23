import BrowseListFeature
import EshopService
import FavoritesListFeature
import Foundation
import GameDetailFeature

enum FeatureGameMapper {
    static func browseGame(from game: Game) -> BrowseGame {
        BrowseGame(
            id: game.id,
            title: game.title,
            price: BrowseGamePrice(
                status: game.price.status,
                isOnSale: game.price.isOnSale,
                regular: game.price.regular.map {
                    BrowseMoney(amount: $0.amount, currency: $0.currency, rawValue: $0.rawValue)
                },
                sale: game.price.sale.map {
                    BrowseMoney(amount: $0.amount, currency: $0.currency, rawValue: $0.rawValue)
                }
            )
        )
    }

    static func favoriteGame(from game: Game) -> FavoriteGame {
        FavoriteGame(
            id: game.id,
            title: game.title,
            imageURL: game.imageURL,
            price: FavoriteGamePrice(
                status: game.price.status,
                isOnSale: game.price.isOnSale,
                regular: game.price.regular.map {
                    FavoriteMoney(amount: $0.amount, currency: $0.currency, rawValue: $0.rawValue)
                },
                sale: game.price.sale.map {
                    FavoriteMoney(amount: $0.amount, currency: $0.currency, rawValue: $0.rawValue)
                }
            )
        )
    }

    static func gameDetail(from game: Game) -> GameDetail {
        GameDetail(
            id: game.id,
            title: game.title,
            releaseDate: game.releaseDate.flatMap { try? Date($0, strategy: .iso8601) },
            imageURL: game.imageURL,
            sourceURL: game.sourceURL,
            price: GameDetailPrice(
                status: game.price.status,
                isOnSale: game.price.isOnSale,
                regular: game.price.regular.map {
                    GameDetailMoney(amount: $0.amount, currency: $0.currency, rawValue: $0.rawValue)
                },
                sale: game.price.sale.map {
                    GameDetailMoney(amount: $0.amount, currency: $0.currency, rawValue: $0.rawValue)
                },
                saleStartsAt: game.price.saleStartsAt,
                saleEndsAt: game.price.saleEndsAt
            ),
            supportedLanguages: game.supportedLanguages,
            productTypes: productTypes(from: game.productType)
        )
    }

    static func productTypes(from value: String?) -> [String] {
        guard let value else { return [] }
        return value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
