import SwiftUI

struct GameRowView: View {
    let game: Game

    var body: some View {
        HStack {
            Image(systemName: game.price.isOnSale ? "tag.fill" : "gamecontroller.fill")
                .font(.title2)
                .foregroundStyle(game.price.isOnSale ? Color.red : Color.accentColor)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(game.title)
                    .font(.headline)
                    .lineLimit(2)
                PriceLabelView(price: game.price)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
