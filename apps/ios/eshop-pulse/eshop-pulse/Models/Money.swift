import Foundation

struct Money: Decodable, Hashable, Sendable {
    let amount: String?
    let currency: String?
    let rawValue: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case rawValue = "rawValue"
    }
}
