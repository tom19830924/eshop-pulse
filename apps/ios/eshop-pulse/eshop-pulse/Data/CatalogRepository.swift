protocol CatalogRepository: Sendable {
    func loadCachedCatalog() async -> CatalogDocument?
    func refreshCatalogIfNeeded() async throws -> CatalogDocument?
}
