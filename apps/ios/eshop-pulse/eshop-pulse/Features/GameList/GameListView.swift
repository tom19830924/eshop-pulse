import SwiftUI

struct GameListView: View {
    @State private var viewModel: GameListViewModel
    @State private var selectedTab: MainTab = .home

    init(viewModel: GameListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GameListScreenView(
                viewModel: viewModel,
                isFavoritesList: true,
                onBrowse: { selectedTab = .browse }
            )
            .tabItem {
                Label("首頁", systemImage: "heart")
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("首頁")
            }
            .tag(MainTab.home)

            GameListScreenView(viewModel: viewModel, isFavoritesList: false)
                .tabItem {
                    Label("瀏覽", systemImage: "square.grid.2x2")
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("瀏覽")
                }
                .tag(MainTab.browse)
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }

    private enum MainTab: Hashable {
        case home
        case browse
    }
}
