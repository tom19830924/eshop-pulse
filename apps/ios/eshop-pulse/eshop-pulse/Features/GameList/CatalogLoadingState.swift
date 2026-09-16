enum CatalogLoadingState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}
