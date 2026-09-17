import Foundation

struct LiveCatalogRepository: CatalogRepository {
    private let session: any CatalogHTTPClient
    private let cacheStore: CatalogCacheStore
    private let metadataURL: URL?
    private let catalogURL: URL?

    init(
        session: any CatalogHTTPClient = URLSession.shared,
        cacheDirectory: URL? = nil,
        userDefaults: UserDefaults = .standard,
        metadataURL: URL? = nil,
        catalogURL: URL? = nil
    ) {
        let directory = cacheDirectory
            ?? URL.applicationSupportDirectory.appending(path: "eShopPulse", directoryHint: .isDirectory)
        self.session = session
        cacheStore = CatalogCacheStore(cacheDirectory: directory, userDefaults: userDefaults)
        self.metadataURL = metadataURL ?? Self.endpoint(named: "games.meta.json")
        self.catalogURL = catalogURL ?? Self.endpoint(named: "games.json")
    }

    func loadCachedCatalog() async -> CatalogDocument? {
        await cacheStore.loadCatalog()
    }

    func refreshCatalogIfNeeded() async throws -> CatalogDocument? {
        guard let metadataURL else {
            throw URLError(.badURL)
        }

        let metadataData = try await fetchData(from: metadataURL)
        try Task.checkCancellation()
        let metadata = try JSONDecoder().decode(CatalogMetadata.self, from: metadataData)

        let (cachedCatalog, savedTimestamp) = await cacheStore.snapshot()
        if cachedCatalog != nil,
           let savedTimestamp,
           metadata.timestamp <= savedTimestamp {
            return nil
        }

        guard let catalogURL else {
            throw URLError(.badURL)
        }

        let catalogData = try await fetchData(from: catalogURL)
        try Task.checkCancellation()
        let catalog = try JSONDecoder().decode(CatalogDocument.self, from: catalogData)

        try await cacheStore.saveCatalog(catalogData, timestamp: metadata.timestamp)

        return catalog
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private static func endpoint(named filename: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tom19830924.github.io"
        components.path = "/eshop-pulse/normalized/\(filename)"
        return components.url
    }
}

protocol CatalogHTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: CatalogHTTPClient {}
