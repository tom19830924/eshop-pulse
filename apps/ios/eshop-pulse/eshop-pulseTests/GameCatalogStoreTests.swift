import EshopService
import Foundation
import XCTest
@testable import eshop_pulse

@MainActor
final class GameCatalogStoreTests: XCTestCase {
    func testStoreMapsCatalogIntoFeatureOwnedModels() async throws {
        let catalog = CatalogDocument(
            generatedAt: "2026-09-18",
            games: [makeGame()]
        )
        let repository = MutableCatalogRepository(cachedCatalog: nil, nextCatalog: catalog)
        let defaults = try makeUserDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

        let store = GameCatalogStore(repository: repository, userDefaults: defaults)
        await store.refresh()

        XCTAssertEqual(store.games.map(\.id), ["game-1"])
        XCTAssertEqual(store.games.first?.price.isOnSale, true)
        XCTAssertEqual(store.favoriteGames.first?.imageURL, URL(string: "https://example.test/game.jpg"))

        let detail = try XCTUnwrap(store.game(withID: "game-1"))
        XCTAssertEqual(detail.title, "Example Game")
        XCTAssertEqual(detail.productTypes, ["Game", "DLC", "Demo"])
        XCTAssertNotNil(detail.releaseDate)
        XCTAssertEqual(detail.price.sale?.amount, "NT$ 500")
    }

    func testStoreKeepsCachedCatalogAndCanRetryAfterFailure() async throws {
        let cached = CatalogDocument(generatedAt: "cached", games: [])
        let updated = CatalogDocument(generatedAt: "updated", games: [])
        let repository = MutableCatalogRepository(cachedCatalog: cached, nextCatalog: nil, shouldFail: true)
        let defaults = try makeUserDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

        let store = GameCatalogStore(repository: repository, userDefaults: defaults)
        await store.refresh()

        XCTAssertEqual(store.generatedAt, "cached")
        XCTAssertTrue(store.hasLoadedCatalog)
        XCTAssertNotNil(store.updateErrorMessage)

        await repository.setNextResult(shouldFail: false, catalog: updated)
        await store.refresh()

        XCTAssertEqual(store.generatedAt, "updated")
        XCTAssertTrue(store.hasLoadedCatalog)
        XCTAssertNil(store.updateErrorMessage)
    }

    func testTogglingFavoriteUpdatesStoreAndPersistsTheSelection() throws {
        let defaults = try makeUserDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let repository = MutableCatalogRepository(cachedCatalog: nil, nextCatalog: nil)
        let store = GameCatalogStore(repository: repository, userDefaults: defaults)

        store.toggleFavorite(gameID: "game-1")

        XCTAssertEqual(store.favoriteGameIDs, ["game-1"])
        XCTAssertEqual(
            defaults.stringArray(forKey: FavoriteGameIDsStore.userDefaultsKey),
            ["game-1"]
        )

        store.toggleFavorite(gameID: "game-1")

        XCTAssertTrue(store.favoriteGameIDs.isEmpty)
        XCTAssertEqual(defaults.stringArray(forKey: FavoriteGameIDsStore.userDefaultsKey), [])
    }

    private func makeGame() -> Game {
        Game(
            id: "game-1",
            title: "Example Game",
            releaseDate: "2025-06-15T00:00:00Z",
            imageURL: URL(string: "https://example.test/game.jpg"),
            sourceURL: URL(string: "https://example.test/store/game-1"),
            price: GamePrice(
                status: "available",
                isOnSale: true,
                regular: Money(amount: "NT$ 1,000", currency: "TWD", rawValue: "1000"),
                sale: Money(amount: "NT$ 500", currency: "TWD", rawValue: "500"),
                saleStartsAt: "2025-06-01T00:00:00Z",
                saleEndsAt: "2025-06-30T00:00:00Z"
            ),
            supportedLanguages: ["繁體中文", "English"],
            productType: "Game, DLC, , Demo"
        )
    }

    private let defaultsSuiteName = "GameCatalogStoreTests.\(UUID().uuidString)"

    private func makeUserDefaults() throws -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: defaultsSuiteName) else {
            throw TestFailure.userDefaultsUnavailable
        }
        return defaults
    }
}

private actor MutableCatalogRepository: CatalogRepository {
    private var cachedCatalog: CatalogDocument?
    private var nextCatalog: CatalogDocument?
    private var shouldFail: Bool

    init(
        cachedCatalog: CatalogDocument?,
        nextCatalog: CatalogDocument?,
        shouldFail: Bool = false
    ) {
        self.cachedCatalog = cachedCatalog
        self.nextCatalog = nextCatalog
        self.shouldFail = shouldFail
    }

    func loadCachedCatalog() async -> CatalogDocument? {
        cachedCatalog
    }

    func refreshCatalogIfNeeded() async throws -> CatalogDocument? {
        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }
        if let nextCatalog {
            cachedCatalog = nextCatalog
        }
        return nextCatalog
    }

    func setNextResult(shouldFail: Bool, catalog: CatalogDocument?) {
        self.shouldFail = shouldFail
        nextCatalog = catalog
    }
}

private enum TestFailure: Error {
    case userDefaultsUnavailable
}
