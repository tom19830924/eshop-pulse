import SwiftUI

struct GameArtworkView: View {
    let imageURL: URL?
    var size: CGFloat = 64
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: {
            Image(systemName: "gamecontroller.fill")
                .font(size >= 128 ? .largeTitle : .title2)
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
        .background(.quaternary)
        .clipShape(.rect(cornerRadius: size >= 128 ? 20 : 12))
        .accessibilityHidden(true)
    }
}
