import Foundation
import Observation

@MainActor
@Observable
final class GameListViewModel {
    private let repository: any CatalogRepository
    private var loadTask: Task<Void, Never>?
    private var activeRequestID: UUID?

    private(set) var loadingState: CatalogLoadingState = .idle
    private(set) var generatedAt: String?
    private var games: [Game] = []

    var searchText = "" {
        didSet { updateVisibleGames() }
    }
    var showsSalesOnly = false {
        didSet { updateVisibleGames() }
    }
    private(set) var visibleGames: [Game] = []

    init(repository: any CatalogRepository) {
        self.repository = repository
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
        loadingState = .loading

        do {
            let catalog = try await repository.fetchCatalog()
            try Task.checkCancellation()
            guard activeRequestID == requestID else { return }
            games = catalog.games
            generatedAt = catalog.generatedAt
            updateVisibleGames()
            loadingState = .loaded
        } catch is CancellationError {
            guard activeRequestID == requestID else { return }
            loadingState = .idle
        } catch {
            guard activeRequestID == requestID else { return }
            loadingState = .failed("無法更新遊戲資料，請檢查網路後再試一次。")
        }
    }

    private func updateVisibleGames() {
        visibleGames = games.filter { game in
            let matchesSearch = searchText.isEmpty || game.title.localizedStandardContains(searchText)
            return matchesSearch && (!showsSalesOnly || game.price.isOnSale)
        }
    }
}
