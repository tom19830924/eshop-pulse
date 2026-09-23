import SwiftUI

struct FavoriteGameRow: View {
    let game: FavoriteGame
    let onSelect: () -> Void
    let onRemoveFavorite: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                FavoriteArtworkView(imageURL: game.imageURL)

                VStack(alignment: .leading) {
                    Text(game.title)
                        .font(.headline)
                        .lineLimit(2)
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
            Button(action: onRemoveFavorite) {
                Image(systemName: "heart.slash.fill")
            }
            .accessibilityLabel("從最愛移除")
            .tint(.red)
        }
    }
}

struct FavoriteArtworkView: View {
    let imageURL: URL?

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 64, height: 64)
        .background(.quaternary)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}

struct GamePriceLabel: View {
    let price: FavoriteGamePrice

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
