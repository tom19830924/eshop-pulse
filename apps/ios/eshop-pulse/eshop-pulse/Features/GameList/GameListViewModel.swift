import Foundation
import Observation

@MainActor
@Observable
final class GameListViewModel {
    private static let favoriteGameIDsKey = "favoriteGameIDs"

    private let repository: any CatalogRepository
    private let userDefaults: UserDefaults
    private var loadTask: Task<Void, Never>?
    private var activeRequestID: UUID?
    private var hasCatalog = false

    private(set) var loadingState: CatalogLoadingState = .idle
    private(set) var generatedAt: String?
    private(set) var games: [Game] = []
    private(set) var favoriteGameIDs: Set<String>
    private(set) var updateError: String?

    init(repository: any CatalogRepository, userDefaults: UserDefaults = .standard) {
        self.repository = repository
        self.userDefaults = userDefaults
        favoriteGameIDs = Set(userDefaults.stringArray(forKey: Self.favoriteGameIDsKey) ?? [])
    }

    func isFavorite(_ game: Game) -> Bool {
        favoriteGameIDs.contains(game.id)
    }

    func toggleFavorite(for game: Game) {
        if favoriteGameIDs.contains(game.id) {
            favoriteGameIDs.remove(game.id)
        } else {
            favoriteGameIDs.insert(game.id)
        }

        userDefaults.set(favoriteGameIDs.sorted(), forKey: Self.favoriteGameIDsKey)
    }

    func loadIfNeeded() {
        guard loadingState == .idle else { return }
        load()
    }

    func refresh() async {
        loadTask?.cancel()
        await performLoad()
    }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        let requestID = UUID()
        activeRequestID = requestID

        do {
            if let cachedCatalog = await repository.loadCachedCatalog() {
                try Task.checkCancellation()
                guard activeRequestID == requestID else { return }
                apply(cachedCatalog)
                loadingState = .loaded
            } else if !hasCatalog {
                loadingState = .loading
            }

            let updatedCatalog = try await repository.refreshCatalogIfNeeded()
            try Task.checkCancellation()
            guard activeRequestID == requestID else { return }
            if let updatedCatalog {
                apply(updatedCatalog)
            }
            updateError = nil
            loadingState = .loaded
        } catch is CancellationError {
            guard activeRequestID == requestID else { return }
            if !hasCatalog {
                loadingState = .idle
            }
        } catch {
            guard activeRequestID == requestID else { return }
            if hasCatalog {
                updateError = "無法更新遊戲資料，請檢查網路後再試一次。"
                loadingState = .loaded
            } else {
                loadingState = .failed("無法更新遊戲資料，請檢查網路後再試一次。")
            }
        }
    }

    private func apply(_ catalog: CatalogDocument) {
        games = catalog.games
        generatedAt = catalog.generatedAt
        hasCatalog = true
    }
}
