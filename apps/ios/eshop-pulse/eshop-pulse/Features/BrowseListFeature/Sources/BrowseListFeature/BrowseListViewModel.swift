import Observation

@MainActor
@Observable
final class BrowseListViewModel {
    @ObservationIgnored private let dataSource: any BrowseListDataSource

    var searchText = ""
    var showsSalesOnly = false

    init(dataSource: any BrowseListDataSource) {
        self.dataSource = dataSource
    }

    var visibleGames: [BrowseGame] {
        dataSource.games.filter { game in
            let matchesSaleFilter = !showsSalesOnly || game.price.isOnSale
            let matchesSearch = searchText.isEmpty
                || game.title.localizedStandardContains(searchText)
            return matchesSaleFilter && matchesSearch
        }
    }

    var hasGames: Bool { !dataSource.games.isEmpty }
    var hasLoadedCatalog: Bool { dataSource.hasLoadedCatalog }
    var isLoadingCatalog: Bool { dataSource.isLoadingCatalog }
    var initialLoadErrorMessage: String? { dataSource.initialLoadErrorMessage }
    var updateErrorMessage: String? { dataSource.updateErrorMessage }

    func isFavorite(_ game: BrowseGame) -> Bool {
        dataSource.favoriteGameIDs.contains(game.id)
    }

    func toggleFavorite(for game: BrowseGame) {
        dataSource.toggleFavorite(gameID: game.id)
    }

    func load() {
        dataSource.load()
    }

    func refresh() async {
        await dataSource.refresh()
    }
}
