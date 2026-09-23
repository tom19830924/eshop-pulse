import BrowseListFeature
import EshopService
import FavoritesListFeature
import Foundation
import GameDetailFeature
import Observation

@MainActor
@Observable
final class GameCatalogStore: FavoritesListDataSource, BrowseListDataSource, GameDetailDataSource {
    @ObservationIgnored private let repository: any CatalogRepository
    @ObservationIgnored private let favoriteGameIDsStore: FavoriteGameIDsStore
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var activeRequestID: UUID?

    private(set) var hasLoadedCatalog = false
    private(set) var isLoadingCatalog = false
    private(set) var initialLoadErrorMessage: String?
    private(set) var updateErrorMessage: String?
    private(set) var generatedAt: String?
    private(set) var games: [BrowseGame] = []
    private(set) var favoriteGames: [FavoriteGame] = []
    private(set) var detailGames: [GameDetail] = []
    private(set) var favoriteGameIDs: Set<String>
    private(set) var saleAlertsEnabled: Bool

    init(repository: any CatalogRepository, userDefaults: UserDefaults = .standard) {
        self.repository = repository
        self.userDefaults = userDefaults
        favoriteGameIDsStore = FavoriteGameIDsStore(userDefaults: userDefaults)
        favoriteGameIDs = favoriteGameIDsStore.load()
        saleAlertsEnabled = FavoriteSaleAlertPreference.isEnabled(in: userDefaults)
    }

    func game(withID id: String) -> GameDetail? {
        detailGames.first { $0.id == id }
    }

    func loadIfNeeded() {
        guard !hasLoadedCatalog, !isLoadingCatalog else { return }
        load()
    }

    func refresh() async {
        loadTask?.cancel()
        initialLoadErrorMessage = nil
        if !hasLoadedCatalog {
            isLoadingCatalog = true
        }
        await performLoad()
    }

    func load() {
        loadTask?.cancel()
        initialLoadErrorMessage = nil
        if !hasLoadedCatalog {
            isLoadingCatalog = true
        }
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    func toggleFavorite(gameID: String) {
        if favoriteGameIDs.contains(gameID) {
            favoriteGameIDs.remove(gameID)
        } else {
            favoriteGameIDs.insert(gameID)
        }

        favoriteGameIDsStore.save(favoriteGameIDs)
    }

    func setSaleAlertsEnabled(_ enabled: Bool) {
        saleAlertsEnabled = enabled
        FavoriteSaleAlertPreference.setEnabled(enabled, in: userDefaults)
    }

    private func performLoad() async {
        let requestID = UUID()
        activeRequestID = requestID

        do {
            if let cachedCatalog = await repository.loadCachedCatalog() {
                try Task.checkCancellation()
                guard activeRequestID == requestID else { return }
                apply(cachedCatalog)
                isLoadingCatalog = false
                initialLoadErrorMessage = nil
            } else if !hasLoadedCatalog {
                isLoadingCatalog = true
            }

            let updatedCatalog = try await repository.refreshCatalogIfNeeded()
            try Task.checkCancellation()
            guard activeRequestID == requestID else { return }
            if let updatedCatalog {
                apply(updatedCatalog)
            }
            initialLoadErrorMessage = nil
            updateErrorMessage = nil
            isLoadingCatalog = false
        } catch is CancellationError {
            guard activeRequestID == requestID else { return }
            if !hasLoadedCatalog {
                isLoadingCatalog = false
            }
        } catch {
            guard activeRequestID == requestID else { return }
            isLoadingCatalog = false
            if hasLoadedCatalog {
                updateErrorMessage = "無法更新遊戲資料，請檢查網路後再試一次。"
            } else {
                initialLoadErrorMessage = "無法更新遊戲資料，請檢查網路後再試一次。"
            }
        }
    }

    private func apply(_ catalog: CatalogDocument) {
        games = catalog.games.map(FeatureGameMapper.browseGame(from:))
        favoriteGames = catalog.games.map(FeatureGameMapper.favoriteGame(from:))
        detailGames = catalog.games.map(FeatureGameMapper.gameDetail(from:))
        generatedAt = catalog.generatedAt
        hasLoadedCatalog = true
    }
}
