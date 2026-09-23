import Foundation

public struct GameDetail: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let releaseDate: Date?
    public let imageURL: URL?
    public let sourceURL: URL?
    public let price: GameDetailPrice
    public let supportedLanguages: [String]?
    public let productTypes: [String]

    public init(
        id: String,
        title: String,
        releaseDate: Date?,
        imageURL: URL?,
        sourceURL: URL?,
        price: GameDetailPrice,
        supportedLanguages: [String]?,
        productTypes: [String]
    ) {
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.price = price
        self.supportedLanguages = supportedLanguages
        self.productTypes = productTypes
    }
}

public struct GameDetailPrice: Hashable, Sendable {
    public let status: String
    public let isOnSale: Bool
    public let regular: GameDetailMoney?
    public let sale: GameDetailMoney?
    public let saleStartsAt: String?
    public let saleEndsAt: String?

    public init(
        status: String,
        isOnSale: Bool,
        regular: GameDetailMoney?,
        sale: GameDetailMoney?,
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

    var saleDateRangeText: String? {
        guard isOnSale else { return nil }

        let startDate = saleStartsAt.map { String($0.prefix(10)) }
        let endDate = saleEndsAt.map { String($0.prefix(10)) }

        switch (startDate, endDate) {
        case let (start?, end?):
            return "特價期間：\(start) – \(end)"
        case let (start?, nil):
            return "特價開始：\(start)"
        case let (nil, end?):
            return "特價結束：\(end)"
        case (nil, nil):
            return nil
        }
    }
}

public struct GameDetailMoney: Hashable, Sendable {
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
