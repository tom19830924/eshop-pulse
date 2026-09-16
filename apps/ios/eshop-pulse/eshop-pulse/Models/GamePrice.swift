import Foundation

struct GamePrice: Decodable, Hashable, Sendable {
    let status: String
    let isOnSale: Bool
    let regular: Money?
    let sale: Money?
    let saleEndsAt: String?
}
