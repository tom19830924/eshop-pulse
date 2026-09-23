import SwiftUI

public struct FavoritesListView: View {
    @State private var viewModel: FavoritesListViewModel

    private let saleAlertsEnabled: Bool
    private let onBrowse: () -> Void
    private let onSelectGame: (String) -> Void
    private let onToggleSaleAlerts: () -> Void

    public init(
        dataSource: any FavoritesListDataSource,
        saleAlertsEnabled: Bool,
        onBrowse: @escaping () -> Void,
        onSelectGame: @escaping (String) -> Void,
        onToggleSaleAlerts: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: FavoritesListViewModel(dataSource: dataSource))
        self.saleAlertsEnabled = saleAlertsEnabled
        self.onBrowse = onBrowse
        self.onSelectGame = onSelectGame
        self.onToggleSaleAlerts = onToggleSaleAlerts
    }

    public var body: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    saleAlertsToggle
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
                FavoriteGameRow(
                    game: game,
                    onSelect: { onSelectGame(game.id) },
                    onRemoveFavorite: { viewModel.toggleFavorite(for: game) }
                )
            }
            .contentMargins(.top, 0, for: .scrollContent)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.showsSalesOnly {
            ContentUnavailableView {
                Label("沒有特價的最愛", systemImage: "tag")
            }
        } else {
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
        }
    }

    private var saleAlertsToggle: some View {
        Button(action: onToggleSaleAlerts) {
            Image(systemName: saleAlertsEnabled ? "bell.badge.fill" : "bell")
        }
        .accessibilityLabel(saleAlertsEnabled ? "關閉最愛特價通知" : "開啟最愛特價通知")
        .accessibilityValue(saleAlertsEnabled ? "已開啟" : "已關閉")
        .accessibilityHint("開啟後會在背景檢查最愛的新特價並發送本機通知；需允許通知與背景 App 重新整理。最早於每天上午 9 點後執行，實際時間由 iOS 安排。")
    }

    private var filterToggle: some View {
        Button {
            viewModel.showsSalesOnly.toggle()
        } label: {
            Image(systemName: viewModel.showsSalesOnly ? "tag.fill" : "square.grid.2x2.fill")
        }
        .accessibilityLabel("切換顯示範圍")
        .accessibilityValue(viewModel.showsSalesOnly ? "特價中的最愛" : "全部最愛")
        .accessibilityHint("切換全部最愛與特價中的最愛")
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
