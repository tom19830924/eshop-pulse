import SwiftUI

struct GameListScreenView: View {
    let viewModel: GameListViewModel
    let isFavoritesList: Bool
    let onBrowse: () -> Void

    @State private var showsSalesOnly = false
    @State private var searchText = ""

    init(
        viewModel: GameListViewModel,
        isFavoritesList: Bool,
        onBrowse: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.isFavoritesList = isFavoritesList
        self.onBrowse = onBrowse
    }

    var body: some View {
        Group {
            if isFavoritesList {
                navigationView
            } else {
                navigationView.searchable(
                    text: $searchText,
                    prompt: "搜尋遊戲"
                )
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var navigationView: some View {
        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .idle, .loading:
                    ProgressView()
                case .loaded:
                    GameListContentView(
                        games: visibleGames,
                        searchText: searchText,
                        isFavoritesList: isFavoritesList,
                        showsSalesOnly: showsSalesOnly,
                        viewModel: viewModel,
                        onBrowse: onBrowse
                    )
                case .failed(let message):
                    ContentUnavailableView {
                        Label("無法載入", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button(action: viewModel.load) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("再試一次")
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    filterToggle
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if case .loaded = viewModel.loadingState,
                   let updateError = viewModel.updateError {
                    updateFailureBanner(updateError)
                }
            }
        }
    }

    private func updateFailureBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Label(message, systemImage: "wifi.exclamationmark")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("重試", systemImage: "arrow.clockwise", action: viewModel.load)
                .labelStyle(.titleAndIcon)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .foregroundStyle(.orange)
        .background(.thinMaterial)
    }

    private var filterToggle: some View {
        Button {
            showsSalesOnly.toggle()
        } label: {
            Image(systemName: showsSalesOnly ? "tag.fill" : "square.grid.2x2.fill")
        }
        .accessibilityLabel("切換顯示範圍")
        .accessibilityValue(selectedFilterAccessibilityLabel)
        .accessibilityHint(filterToggleAccessibilityHint)
    }

    private var visibleGames: [Game] {
        viewModel.games.filter { game in
            let isInCollection = !isFavoritesList || viewModel.isFavorite(game)
            let matchesSaleFilter = !showsSalesOnly || game.price.isOnSale
            let matchesSearch = isFavoritesList
                || searchText.isEmpty
                || game.title.localizedStandardContains(searchText)

            return isInCollection && matchesSaleFilter && matchesSearch
        }
    }

    private var allGamesAccessibilityLabel: String {
        isFavoritesList ? "全部最愛" : "全部遊戲"
    }

    private var salesAccessibilityLabel: String {
        isFavoritesList ? "特價中的最愛" : "特價中"
    }

    private var selectedFilterAccessibilityLabel: String {
        showsSalesOnly ? salesAccessibilityLabel : allGamesAccessibilityLabel
    }

    private var filterToggleAccessibilityHint: String {
        isFavoritesList ? "切換全部最愛與特價中的最愛" : "切換全部遊戲與特價中"
    }
}
