import Foundation
import XCTest
import FavoritesListFeature

final class FavoriteSaleTransitionDetectorTests: XCTestCase {
    func testOnlyNotifiesFavoritesThatTransitionFromNotOnSaleToOnSale() {
        let previousGames = [
            makeGame(id: "new-sale", isOnSale: false),
            makeGame(id: "already-on-sale", isOnSale: true),
            makeGame(id: "sale-ended", isOnSale: true),
            makeGame(id: "not-favorite", isOnSale: false),
        ]
        let updatedGames = [
            makeGame(id: "new-sale", isOnSale: true),
            makeGame(id: "already-on-sale", isOnSale: true),
            makeGame(id: "sale-ended", isOnSale: false),
            makeGame(id: "not-favorite", isOnSale: true),
            makeGame(id: "newly-listed", isOnSale: true),
        ]

        let newlyOnSale = FavoriteSaleTransitionDetector.newlyOnSaleFavorites(
            from: previousGames,
            to: updatedGames,
            favoriteGameIDs: ["new-sale", "already-on-sale", "sale-ended", "newly-listed"]
        )

        XCTAssertEqual(newlyOnSale.map(\.id), ["new-sale"])
    }

    func testMissingPreviousGamesCreatesBaselineWithoutNotifications() {
        let newlyOnSale = FavoriteSaleTransitionDetector.newlyOnSaleFavorites(
            from: nil,
            to: [makeGame(id: "favorite", isOnSale: true)],
            favoriteGameIDs: ["favorite"]
        )

        XCTAssertTrue(newlyOnSale.isEmpty)
    }

    private func makeGame(id: String, isOnSale: Bool) -> FavoriteGame {
        FavoriteGame(
            id: id,
            title: id,
            imageURL: nil,
            price: FavoriteGamePrice(
                status: isOnSale ? "sale" : "regular",
                isOnSale: isOnSale,
                regular: nil,
                sale: nil
            )
        )
    }
}
