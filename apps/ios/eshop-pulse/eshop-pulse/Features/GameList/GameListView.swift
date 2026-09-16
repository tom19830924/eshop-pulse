import SwiftUI

struct GameListView: View {
    @State private var viewModel: GameListViewModel

    init(viewModel: GameListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .idle, .loading:
                    ProgressView("正在讀取台灣 eShop…")
                case .loaded:
                    GameListContentView(games: viewModel.visibleGames, searchText: viewModel.searchText)
                case .failed(let message):
                    ContentUnavailableView {
                        Label("暫時無法取得資料", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("再試一次", systemImage: "arrow.clockwise", action: viewModel.load)
                    }
                }
            }
            .navigationTitle("台灣 eShop")
            .searchable(text: $viewModel.searchText, prompt: "搜尋遊戲")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("顯示範圍", selection: $viewModel.showsSalesOnly) {
                        Text("全部遊戲").tag(false)
                        Text("特價中").tag(true)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .task { viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }
}
