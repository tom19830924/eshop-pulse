import Foundation

public struct BrowseGame: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let price: BrowseGamePrice

    public init(id: String, title: String, price: BrowseGamePrice) {
        self.id = id
        self.title = title
        self.price = price
    }
}

public struct BrowseGamePrice: Hashable, Sendable {
    public let status: String
    public let isOnSale: Bool
    public let regular: BrowseMoney?
    public let sale: BrowseMoney?

    public init(status: String, isOnSale: Bool, regular: BrowseMoney?, sale: BrowseMoney?) {
        self.status = status
        self.isOnSale = isOnSale
        self.regular = regular
        self.sale = sale
    }

    var salePriceRatio: Decimal? {
        guard isOnSale,
              let regularAmount = regular?.decimalAmount,
              regularAmount > .zero,
              let saleAmount = sale?.decimalAmount
        else {
            return nil
        }

        return saleAmount / regularAmount
    }
}

public struct BrowseMoney: Hashable, Sendable {
    public let amount: String?
    public let currency: String?
    public let rawValue: String?

    public init(amount: String?, currency: String?, rawValue: String?) {
        self.amount = amount
        self.currency = currency
        self.rawValue = rawValue
    }

    var decimalAmount: Decimal? {
        let locale = Locale(identifier: "en_US_POSIX")

        if let rawValue, let value = Decimal(string: rawValue, locale: locale) {
            return value
        }

        guard let amount else { return nil }
        let numericCharacters = amount.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return Decimal(string: String(numericCharacters), locale: locale)
    }
}
