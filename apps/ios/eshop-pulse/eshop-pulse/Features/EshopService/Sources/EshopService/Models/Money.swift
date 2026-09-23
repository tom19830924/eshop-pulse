import Foundation

public struct Money: Decodable, Hashable, Sendable {
    public let amount: String?
    public let currency: String?
    public let rawValue: String?

    public init(amount: String?, currency: String?, rawValue: String?) {
        self.amount = amount
        self.currency = currency
        self.rawValue = rawValue
    }

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case rawValue = "rawValue"
    }
}
