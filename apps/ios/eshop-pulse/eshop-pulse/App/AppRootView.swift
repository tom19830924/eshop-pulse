import BrowseListFeature
import EshopService
import FavoritesListFeature
import GameDetailFeature
import SwiftUI

@MainActor
struct AppRootView: View {
    @State private var router = AppRouter()
    @State private var store: GameCatalogStore
    @State private var showsNotificationSettingsAlert = false
    @Environment(\.openURL) private var openURL

    init(repository: any CatalogRepository) {
        _store = State(initialValue: GameCatalogStore(repository: repository))
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.favoritesPath) {
                FavoritesListView(
                    dataSource: store,
                    saleAlertsEnabled: store.saleAlertsEnabled,
                    onBrowse: { router.selectedTab = .browse },
                    onSelectGame: { router.showGameDetail(id: $0, in: .favorites) },
                    onToggleSaleAlerts: toggleSaleAlerts
                )
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
            }
            .tabItem {
                Label("首頁", systemImage: "heart")
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("首頁")
            }
            .tag(AppTab.favorites)

            NavigationStack(path: $router.browsePath) {
                BrowseListView(
                    dataSource: store,
                    onSelectGame: { router.showGameDetail(id: $0, in: .browse) }
                )
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
            }
            .tabItem {
                Label("瀏覽", systemImage: "list.bullet")
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("瀏覽")
            }
            .tag(AppTab.browse)
        }
        .task {
            store.loadIfNeeded()
        }
        .alert("需要允許通知", isPresented: $showsNotificationSettingsAlert) {
            Button("前往設定") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("請在系統設定中允許 eShop Pulse 發送通知，再開啟最愛特價提醒。")
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .gameDetail(let id):
            if let game = store.game(withID: id) {
                GameDetailView(game: game, dataSource: store)
            } else {
                ContentUnavailableView {
                    Label("找不到遊戲", systemImage: "gamecontroller")
                }
            }
        }
    }

    private func toggleSaleAlerts() {
        if store.saleAlertsEnabled {
            store.setSaleAlertsEnabled(false)
            BackgroundCatalogRefreshScheduler.cancel()
            return
        }

        Task { @MainActor in
            let isAuthorized = await FavoriteSaleNotificationService.requestAuthorization()
            guard isAuthorized else {
                showsNotificationSettingsAlert = true
                return
            }

            store.setSaleAlertsEnabled(true)
            await BackgroundCatalogRefreshScheduler.scheduleNextIfEnabled()
        }
    }
}
