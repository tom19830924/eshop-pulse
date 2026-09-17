import SwiftUI

struct GameRowView: View {
    let game: Game
    let isFavorite: Bool
    let showsArtwork: Bool
    let showsFavoriteMarker: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        NavigationLink(value: game) {
            HStack(spacing: 12) {
                if showsArtwork {
                    GameArtworkView(imageURL: game.imageURL)
                }

                VStack(alignment: .leading) {
                    Text(game.title)
                        .font(.headline)
                        .lineLimit(2)
                        .overlay(alignment: .topLeading) {
                            if showsFavoriteMarker && isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                                    .accessibilityLabel("已加入最愛")
                                    .allowsHitTesting(false)
                                    .offset(x: -16)
                            }
                        }
                    PriceLabelView(price: game.price)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(role: isFavorite ? .destructive : nil, action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.slash.fill" : "heart.fill")
            }
            .accessibilityLabel(isFavorite ? "從最愛移除" : "加入最愛")
            .tint(isFavorite ? .red : .pink)
        }
    }
}
