import SwiftUI

struct GameDetailView: View {
    let game: Game

    var body: some View {
        List {
            Section {
                Label(game.price.isOnSale ? "目前特價中" : "台灣 eShop", systemImage: game.price.isOnSale ? "tag.fill" : "gamecontroller.fill")
                    .foregroundStyle(game.price.isOnSale ? .red : .primary)
                PriceLabelView(price: game.price)
            }

            if let releaseDate = game.releaseDateValue {
                Section("發售日") {
                    Text(releaseDate, format: .dateTime.year().month().day())
                }
            }

            if let sourceURL = game.sourceURL {
                Section {
                    Link("在任天堂網站查看", destination: sourceURL)
                }
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
