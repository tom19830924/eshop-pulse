import SwiftUI

struct PriceLabelView: View {
    let price: GamePrice

    var body: some View {
        if price.isOnSale, let saleAmount = price.sale?.amount {
            HStack {
                Text(price.regular?.amount ?? "")
                    .strikethrough()
                    .foregroundStyle(.secondary)
                Text(saleAmount)
                    .foregroundStyle(.red)
                    .bold()
                Text("特價")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } else if let amount = price.regular?.amount {
            Text(amount)
                .foregroundStyle(.secondary)
        } else {
            Text(priceStatusLabel)
                .foregroundStyle(.secondary)
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
