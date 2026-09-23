import SwiftUI

public struct BrowseListView: View {
    @State private var viewModel: BrowseListViewModel
    @State private var isSearchPresented = false

    private let onSelectGame: (String) -> Void

    public init(
        dataSource: any BrowseListDataSource,
        onSelectGame: @escaping (String) -> Void
    ) {
        _viewModel = State(initialValue: BrowseListViewModel(dataSource: dataSource))
        self.onSelectGame = onSelectGame
    }

    public var body: some View {
        content
            .searchable(
                text: $viewModel.searchText,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "搜尋遊戲"
            )
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    searchButton
                    filterToggle
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if viewModel.hasLoadedCatalog,
                   let updateError = viewModel.updateErrorMessage {
                    updateFailureBanner(updateError)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoadedCatalog,
           viewModel.isLoadingCatalog || viewModel.initialLoadErrorMessage == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let message = viewModel.initialLoadErrorMessage {
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
        } else if viewModel.visibleGames.isEmpty {
            emptyState
        } else {
            List(viewModel.visibleGames) { game in
                BrowseGameRow(
                    game: game,
                    isFavorite: viewModel.isFavorite(game),
                    onSelect: { onSelectGame(game.id) },
                    onToggleFavorite: { viewModel.toggleFavorite(for: game) }
                )
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !viewModel.searchText.isEmpty {
            ContentUnavailableView.search
        } else if viewModel.showsSalesOnly {
            ContentUnavailableView {
                Label("目前沒有特價遊戲", systemImage: "tag")
            }
        } else {
            ContentUnavailableView {
                Label(
                    viewModel.hasGames ? "沒有符合條件的遊戲" : "沒有遊戲資料",
                    systemImage: "gamecontroller"
                )
            }
        }
    }

    private var filterToggle: some View {
        Button {
            viewModel.showsSalesOnly.toggle()
        } label: {
            Image(systemName: viewModel.showsSalesOnly ? "tag.fill" : "square.grid.2x2.fill")
        }
        .accessibilityLabel("切換顯示範圍")
        .accessibilityValue(viewModel.showsSalesOnly ? "特價中" : "全部遊戲")
        .accessibilityHint("切換全部遊戲與特價中")
    }

    private var searchButton: some View {
        Button("搜尋", systemImage: "magnifyingglass", action: presentSearch)
            .labelStyle(.iconOnly)
    }

    private func presentSearch() {
        isSearchPresented = true
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
}
