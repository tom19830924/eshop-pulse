import SwiftUI

struct GameRowView: View {
    let game: Game

    var body: some View {
        HStack {
            GameArtworkView(imageURL: game.imageURL)

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
