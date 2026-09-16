import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            GameListView(viewModel: GameListViewModel(repository: LiveCatalogRepository()))
        }
    }
}
