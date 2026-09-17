import Foundation

struct GamePrice: Decodable, Hashable, Sendable {
    let status: String
    let isOnSale: Bool
    let regular: Money?
    let sale: Money?
    let saleStartsAt: String?
    let saleEndsAt: String?

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
