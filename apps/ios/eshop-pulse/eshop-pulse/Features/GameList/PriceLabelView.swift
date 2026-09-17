import SwiftUI

struct PriceLabelView: View {
    let price: GamePrice

    var body: some View {
        if price.isOnSale, let saleAmount = price.sale?.amount {
            HStack {
                Text(price.regular?.amount ?? "")
                    .strikethrough()
                    .foregroundStyle(.primary)
                Text(saleAmount)
                    .foregroundStyle(.red)
                    .bold()
                if let salePriceRatio = price.salePriceRatio {
                    Text("\((salePriceRatio * 100).formatted(.number.precision(.fractionLength(0))))%")
                        .foregroundStyle(.red)
                }
            }
        } else if let amount = price.regular?.amount {
            Text(amount)
                .foregroundStyle(.primary)
        } else {
            Text(priceStatusLabel)
                .foregroundStyle(.primary)
        }
    }

    private var priceStatusLabel: String {
        switch price.status {
        case "unreleased", "preorder": "尚未發售"
        case "not_found": "暫無價格"
        default: "暫無價格"
        }
    }
}
