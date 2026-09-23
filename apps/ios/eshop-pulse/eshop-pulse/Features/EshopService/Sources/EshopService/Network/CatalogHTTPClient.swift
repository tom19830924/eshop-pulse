import Foundation

protocol CatalogHTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: CatalogHTTPClient {}
