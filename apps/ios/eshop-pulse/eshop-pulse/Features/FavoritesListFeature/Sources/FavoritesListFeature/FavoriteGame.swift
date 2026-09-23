import Foundation

public struct FavoriteGame: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let imageURL: URL?
    public let price: FavoriteGamePrice

    public init(id: String, title: String, imageURL: URL?, price: FavoriteGamePrice) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.price = price
    }
}

public struct FavoriteGamePrice: Hashable, Sendable {
    public let status: String
    public let isOnSale: Bool
    public let regular: FavoriteMoney?
    public let sale: FavoriteMoney?

    public init(status: String, isOnSale: Bool, regular: FavoriteMoney?, sale: FavoriteMoney?) {
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

public struct FavoriteMoney: Hashable, Sendable {
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
