import Observation

enum AppTab: Hashable {
    case favorites
    case browse
}

enum AppRoute: Hashable {
    case gameDetail(id: String)
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .favorites
    var favoritesPath: [AppRoute] = []
    var browsePath: [AppRoute] = []

    func showGameDetail(id: String, in tab: AppTab) {
        switch tab {
        case .favorites:
            favoritesPath.append(.gameDetail(id: id))
        case .browse:
            browsePath.append(.gameDetail(id: id))
        }
    }
}
