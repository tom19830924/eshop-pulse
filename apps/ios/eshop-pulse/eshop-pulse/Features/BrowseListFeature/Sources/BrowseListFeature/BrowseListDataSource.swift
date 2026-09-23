import Observation

@MainActor
public protocol BrowseListDataSource: AnyObject, Observable {
    var games: [BrowseGame] { get }
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
