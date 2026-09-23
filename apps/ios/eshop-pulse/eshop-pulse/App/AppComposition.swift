import EshopService

@MainActor
enum AppComposition {
    static let catalogRepository: any CatalogRepository = LiveCatalogRepository()
}
