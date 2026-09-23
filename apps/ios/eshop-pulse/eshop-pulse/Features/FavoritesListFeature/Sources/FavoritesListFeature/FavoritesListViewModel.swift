import Observation

@MainActor
@Observable
final class FavoritesListViewModel {
    @ObservationIgnored private let dataSource: any FavoritesListDataSource

    var showsSalesOnly = false

    init(dataSource: any FavoritesListDataSource) {
        self.dataSource = dataSource
    }

    var visibleGames: [FavoriteGame] {
        dataSource.favoriteGames.filter { game in
            dataSource.favoriteGameIDs.contains(game.id)
                && (!showsSalesOnly || game.price.isOnSale)
        }
    }

    var hasLoadedCatalog: Bool { dataSource.hasLoadedCatalog }
    var isLoadingCatalog: Bool { dataSource.isLoadingCatalog }
    var initialLoadErrorMessage: String? { dataSource.initialLoadErrorMessage }
    var updateErrorMessage: String? { dataSource.updateErrorMessage }

    func isFavorite(_ game: FavoriteGame) -> Bool {
        dataSource.favoriteGameIDs.contains(game.id)
    }

    func toggleFavorite(for game: FavoriteGame) {
        dataSource.toggleFavorite(gameID: game.id)
    }

    func load() {
        dataSource.load()
    }

    func refresh() async {
        await dataSource.refresh()
    }
}
