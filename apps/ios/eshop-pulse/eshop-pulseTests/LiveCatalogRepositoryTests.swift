import Foundation
import XCTest
@testable import eshop_pulse

final class LiveCatalogRepositoryTests: XCTestCase {
    func testFirstLoadFetchesMetadataThenCatalogAndPersistsBoth() async throws {
        let fixture = try makeFixture()
        defer { removeFixture(fixture) }
        await fixture.client.enqueue(.init(data: metadataJSON(100), statusCode: 200), for: Self.metadataURL)
        await fixture.client.enqueue(.init(data: catalogJSON("first"), statusCode: 200), for: Self.catalogURL)

        let updatedCatalog = try await fixture.repository.refreshCatalogIfNeeded()
        let cachedCatalog = await fixture.repository.loadCachedCatalog()
        let requests = await fixture.client.requestedURLs()

        XCTAssertEqual(updatedCatalog?.generatedAt, "first")
        XCTAssertEqual(cachedCatalog?.generatedAt, "first")
        XCTAssertEqual(fixture.defaults.object(forKey: CatalogCacheStore.metadataTimestampKey) as? Int, 100)
        XCTAssertEqual(requests, [Self.metadataURL, Self.catalogURL])
    }

    func testEqualOrOlderTimestampDoesNotDownloadCatalog() async throws {
        for remoteTimestamp in [100, 99] {
            let fixture = try makeFixture(localTimestamp: 100, cachedData: catalogJSON("cached"))
            defer { removeFixture(fixture) }
            await fixture.client.enqueue(
                .init(data: metadataJSON(remoteTimestamp), statusCode: 200),
                for: Self.metadataURL
            )

            let updatedCatalog = try await fixture.repository.refreshCatalogIfNeeded()
            let requests = await fixture.client.requestedURLs()

            XCTAssertNil(updatedCatalog)
            XCTAssertEqual(requests, [Self.metadataURL])
            XCTAssertEqual(fixture.defaults.object(forKey: CatalogCacheStore.metadataTimestampKey) as? Int, 100)
        }
    }

    func testNewerTimestampReplacesCatalogAndSavedTimestamp() async throws {
        let fixture = try makeFixture(localTimestamp: 100, cachedData: catalogJSON("old"))
        defer { removeFixture(fixture) }
        await fixture.client.enqueue(.init(data: metadataJSON(101), statusCode: 200), for: Self.metadataURL)
        await fixture.client.enqueue(.init(data: catalogJSON("new"), statusCode: 200), for: Self.catalogURL)

        let updatedCatalog = try await fixture.repository.refreshCatalogIfNeeded()
        let cachedCatalog = await fixture.repository.loadCachedCatalog()

        XCTAssertEqual(updatedCatalog?.generatedAt, "new")
        XCTAssertEqual(cachedCatalog?.generatedAt, "new")
        XCTAssertEqual(fixture.defaults.object(forKey: CatalogCacheStore.metadataTimestampKey) as? Int, 101)
    }

    func testInvalidNewCatalogKeepsPreviousFileAndTimestamp() async throws {
        let oldCatalogData = catalogJSON("old")
        let fixture = try makeFixture(localTimestamp: 100, cachedData: oldCatalogData)
        defer { removeFixture(fixture) }
        await fixture.client.enqueue(.init(data: metadataJSON(101), statusCode: 200), for: Self.metadataURL)
        await fixture.client.enqueue(.init(data: Data("not json".utf8), statusCode: 200), for: Self.catalogURL)

        do {
            _ = try await fixture.repository.refreshCatalogIfNeeded()
            XCTFail("Expected invalid catalog data to fail decoding")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }

        let cachedCatalog = await fixture.repository.loadCachedCatalog()
        let storedData = try Data(contentsOf: fixture.directory.appending(path: "games.json"))
        XCTAssertEqual(cachedCatalog?.generatedAt, "old")
        XCTAssertEqual(storedData, oldCatalogData)
        XCTAssertEqual(fixture.defaults.object(forKey: CatalogCacheStore.metadataTimestampKey) as? Int, 100)
    }

    func testMissingCacheForcesCatalogDownloadEvenWhenTimestampMatches() async throws {
        let fixture = try makeFixture(localTimestamp: 100)
        defer { removeFixture(fixture) }
        await fixture.client.enqueue(.init(data: metadataJSON(100), statusCode: 200), for: Self.metadataURL)
        await fixture.client.enqueue(.init(data: catalogJSON("restored"), statusCode: 200), for: Self.catalogURL)

        let updatedCatalog = try await fixture.repository.refreshCatalogIfNeeded()
        let requests = await fixture.client.requestedURLs()

        XCTAssertEqual(updatedCatalog?.generatedAt, "restored")
        XCTAssertEqual(requests, [Self.metadataURL, Self.catalogURL])
    }

    @MainActor
    func testViewModelKeepsCachedCatalogAndCanRetryAfterFailure() async throws {
        let cached = CatalogDocument(generatedAt: "cached", games: [])
        let updated = CatalogDocument(generatedAt: "updated", games: [])
        let repository = MutableCatalogRepository(cachedCatalog: cached, shouldFail: true)
        let viewModel = GameListViewModel(repository: repository)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.generatedAt, "cached")
        XCTAssertEqual(viewModel.loadingState, .loaded)
        XCTAssertNotNil(viewModel.updateError)

        await repository.setNextResult(shouldFail: false, catalog: updated)
        await viewModel.refresh()

        XCTAssertEqual(viewModel.generatedAt, "updated")
        XCTAssertEqual(viewModel.loadingState, .loaded)
        XCTAssertNil(viewModel.updateError)
    }

    private func makeFixture(localTimestamp: Int? = nil, cachedData: Data? = nil) throws -> RepositoryFixture {
        let domain = "LiveCatalogRepositoryTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: domain) else {
            throw TestFailure.userDefaultsUnavailable
        }

        let directory = FileManager.default.temporaryDirectory
            .appending(path: "LiveCatalogRepositoryTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let localTimestamp {
            defaults.set(localTimestamp, forKey: CatalogCacheStore.metadataTimestampKey)
        }
        if let cachedData {
            try cachedData.write(to: directory.appending(path: "games.json"), options: .atomic)
        }

        let client = StubCatalogHTTPClient()
        let repository = LiveCatalogRepository(
            session: client,
            cacheDirectory: directory,
            userDefaults: defaults,
            metadataURL: Self.metadataURL,
            catalogURL: Self.catalogURL
        )
        return RepositoryFixture(directory: directory, domain: domain, defaults: defaults, client: client, repository: repository)
    }

    private func removeFixture(_ fixture: RepositoryFixture) {
        try? FileManager.default.removeItem(at: fixture.directory)
        fixture.defaults.removePersistentDomain(forName: fixture.domain)
    }

    private func metadataJSON(_ timestamp: Int) -> Data {
        Data("{\"timestamp\":\(timestamp)}".utf8)
    }

    private func catalogJSON(_ generatedAt: String) -> Data {
        Data("{\"generatedAt\":\"\(generatedAt)\",\"games\":[]}".utf8)
    }

    private static let metadataURL = URL(string: "https://example.test/normalized/games.meta.json")!
    private static let catalogURL = URL(string: "https://example.test/normalized/games.json")!
}

private struct RepositoryFixture {
    let directory: URL
    let domain: String
    let defaults: UserDefaults
    let client: StubCatalogHTTPClient
    let repository: LiveCatalogRepository
}

private struct StubbedResponse {
    let data: Data
    let statusCode: Int
}

private actor StubCatalogHTTPClient: CatalogHTTPClient {
    private var responses: [URL: [StubbedResponse]] = [:]
    private var requests: [URL] = []

    func enqueue(_ response: StubbedResponse, for url: URL) {
        responses[url, default: []].append(response)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else { throw URLError(.badURL) }
        requests.append(url)
        guard var queuedResponses = responses[url], !queuedResponses.isEmpty else {
            throw URLError(.resourceUnavailable)
        }

        let stubbedResponse = queuedResponses.removeFirst()
        responses[url] = queuedResponses
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: stubbedResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        ) else {
            throw URLError(.badServerResponse)
        }
        return (stubbedResponse.data, response)
    }

    func requestedURLs() -> [URL] {
        requests
    }
}

private actor MutableCatalogRepository: CatalogRepository {
    private var cachedCatalog: CatalogDocument?
    private var nextCatalog: CatalogDocument?
    private var shouldFail: Bool

    init(cachedCatalog: CatalogDocument?, shouldFail: Bool) {
        self.cachedCatalog = cachedCatalog
        self.shouldFail = shouldFail
    }

    func loadCachedCatalog() async -> CatalogDocument? {
        cachedCatalog
    }

    func refreshCatalogIfNeeded() async throws -> CatalogDocument? {
        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }
        if let nextCatalog {
            cachedCatalog = nextCatalog
        }
        return nextCatalog
    }

    func setNextResult(shouldFail: Bool, catalog: CatalogDocument?) {
        self.shouldFail = shouldFail
        nextCatalog = catalog
    }
}

private enum TestFailure: Error {
    case userDefaultsUnavailable
}
