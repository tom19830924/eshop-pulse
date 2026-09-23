import Observation

@MainActor
@Observable
final class GameDetailViewModel {
    @ObservationIgnored private let dataSource: any GameDetailDataSource

    init(dataSource: any GameDetailDataSource) {
        self.dataSource = dataSource
    }

    func isFavorite(_ game: GameDetail) -> Bool {
        dataSource.favoriteGameIDs.contains(game.id)
    }

    func toggleFavorite(for game: GameDetail) {
        dataSource.toggleFavorite(gameID: game.id)
    }
}
