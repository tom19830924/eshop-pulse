import Foundation

public struct GamePrice: Decodable, Hashable, Sendable {
    public let status: String
    public let isOnSale: Bool
    public let regular: Money?
    public let sale: Money?
    public let saleStartsAt: String?
    public let saleEndsAt: String?

    public init(
        status: String,
        isOnSale: Bool,
        regular: Money?,
        sale: Money?,
        saleStartsAt: String?,
        saleEndsAt: String?
    ) {
        self.status = status
        self.isOnSale = isOnSale
        self.regular = regular
        self.sale = sale
        self.saleStartsAt = saleStartsAt
        self.saleEndsAt = saleEndsAt
    }

}
