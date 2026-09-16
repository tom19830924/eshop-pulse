import SwiftUI

struct GameListContentView: View {
    let games: [Game]
    let searchText: String

    var body: some View {
        if games.isEmpty {
            ContentUnavailableView.search
        } else {
            List(games) { game in
                NavigationLink(value: game) {
                    GameRowView(game: game)
                }
            }
            .navigationDestination(for: Game.self, destination: GameDetailView.init)
        }
    }
}
