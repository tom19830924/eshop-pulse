import SwiftUI

struct BrowseGameRow: View {
    let game: BrowseGame
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(game.title)
                        .font(.headline)
                        .lineLimit(2)
                        .overlay(alignment: .topLeading) {
                            if isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                                    .accessibilityLabel("已加入最愛")
                                    .allowsHitTesting(false)
                                    .offset(x: -16)
                            }
                        }
                    GamePriceLabel(price: game.price)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isLink)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.slash.fill" : "heart.fill")
            }
            .accessibilityLabel(isFavorite ? "從最愛移除" : "加入最愛")
            .tint(isFavorite ? .red : .pink)
        }
    }
}

struct GamePriceLabel: View {
    let price: BrowseGamePrice

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
            Text(price.status == "unreleased" || price.status == "preorder" ? "尚未發售" : "暫無價格")
                .foregroundStyle(.primary)
        }
    }
}
