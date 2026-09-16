import SwiftUI

struct GameArtworkView: View {
    let imageURL: URL?

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
                .scaledToFill()
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
