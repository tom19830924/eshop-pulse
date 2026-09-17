import Foundation

actor CatalogCacheStore {
    static let metadataTimestampKey = "gamesMetadataTimestamp"

    private let cacheDirectory: URL
    private let cacheFileURL: URL
    private let userDefaults: UserDefaults

    init(cacheDirectory: URL, userDefaults: UserDefaults) {
        self.cacheDirectory = cacheDirectory
        cacheFileURL = cacheDirectory.appending(path: "games.json")
        self.userDefaults = userDefaults
    }

    func loadCatalog() -> CatalogDocument? {
        loadCatalogFromDisk()
    }

    func snapshot() -> (CatalogDocument?, Int?) {
        let catalog = loadCatalogFromDisk()
        let timestamp = userDefaults.object(forKey: Self.metadataTimestampKey) as? Int
        return (catalog, timestamp)
    }

    func saveCatalog(_ data: Data, timestamp: Int) throws {
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
        try data.write(to: cacheFileURL, options: .atomic)
        userDefaults.set(timestamp, forKey: Self.metadataTimestampKey)
    }

    private func loadCatalogFromDisk() -> CatalogDocument? {
        guard let data = try? Data(contentsOf: cacheFileURL) else { return nil }
        return try? JSONDecoder().decode(CatalogDocument.self, from: data)
    }
}
