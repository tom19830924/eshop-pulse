import Foundation

struct Money: Decodable, Hashable, Sendable {
    let amount: String?
    let currency: String?
    let rawValue: String?

    var decimalAmount: Decimal? {
        let locale = Locale(identifier: "en_US_POSIX")

        if let rawValue, let value = Decimal(string: rawValue, locale: locale) {
            return value
        }

        guard let amount else { return nil }
        let numericCharacters = amount.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return Decimal(string: String(numericCharacters), locale: locale)
    }

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case rawValue = "rawValue"
    }
}
