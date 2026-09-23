import Observation

@MainActor
public protocol GameDetailDataSource: AnyObject, Observable {
    var favoriteGameIDs: Set<String> { get }

    func toggleFavorite(gameID: String)
}
