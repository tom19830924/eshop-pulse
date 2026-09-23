import Observation

@MainActor
public protocol FavoritesListDataSource: AnyObject, Observable {
    var favoriteGames: [FavoriteGame] { get }
    var favoriteGameIDs: Set<String> { get }
    var hasLoadedCatalog: Bool { get }
    var isLoadingCatalog: Bool { get }
    var initialLoadErrorMessage: String? { get }
    var updateErrorMessage: String? { get }

    func loadIfNeeded()
    func load()
    func refresh() async
    func toggleFavorite(gameID: String)
}
