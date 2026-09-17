import SwiftUI

struct GameListContentView: View {
    let games: [Game]
    let searchText: String
    let isFavoritesList: Bool
    let showsSalesOnly: Bool
    let viewModel: GameListViewModel
    let onBrowse: () -> Void

    var body: some View {
        if games.isEmpty {
            emptyState
        } else {
            List(games) { game in
                GameRowView(
                    game: game,
                    isFavorite: viewModel.isFavorite(game),
                    showsArtwork: isFavoritesList,
                    showsFavoriteMarker: !isFavoritesList,
                    onToggleFavorite: { viewModel.toggleFavorite(for: game) }
                )
            }
            .navigationDestination(for: Game.self) { game in
                GameDetailView(game: game, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search
        } else if isFavoritesList && !showsSalesOnly {
            ContentUnavailableView {
                Label("尚無最愛", systemImage: "heart")
            } description: {
                Text("在瀏覽中加入遊戲")
            } actions: {
                Button(action: onBrowse) {
                    Image(systemName: "square.grid.2x2")
                }
                .accessibilityLabel("前往瀏覽")
            }
        } else if isFavoritesList {
            ContentUnavailableView {
                Label("沒有特價的最愛", systemImage: "tag")
            }
        } else if showsSalesOnly {
            ContentUnavailableView {
                Label("目前沒有特價遊戲", systemImage: "tag")
            }
        } else {
            ContentUnavailableView {
                Label("沒有遊戲資料", systemImage: "gamecontroller")
            }
        }
    }
}
