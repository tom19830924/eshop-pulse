import SwiftUI

public struct GameDetailView: View {
    private let game: GameDetail
    @State private var viewModel: GameDetailViewModel

    public init(game: GameDetail, dataSource: any GameDetailDataSource) {
        self.game = game
        _viewModel = State(initialValue: GameDetailViewModel(dataSource: dataSource))
    }

    public var body: some View {
        List {
            GameDetailArtworkView(imageURL: game.imageURL)
                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            Section("價格") {
                GamePriceLabel(price: game.price)
                    .listRowBackground(Color.clear)
                if let saleDateRangeText = game.price.saleDateRangeText {
                    Text(saleDateRangeText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .listRowBackground(Color.clear)
                }
            }

            if let supportedLanguages = game.supportedLanguages, !supportedLanguages.isEmpty {
                Section("語言") {
                    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(supportedLanguages.indices, id: \.self) { index in
                            Text(supportedLanguages[index])
                                .font(.subheadline)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
                }
            }

            if !game.productTypes.isEmpty {
                Section("商品類型") {
                    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(game.productTypes.indices, id: \.self) { index in
                            Text(game.productTypes[index])
                                .font(.subheadline)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
                }
            }

            if let releaseDate = game.releaseDate {
                Section("發售日") {
                    Text(releaseDate, format: .dateTime.year().month().day())
                        .listRowBackground(Color.clear)
                }
            }

            if let sourceURL = game.sourceURL {
                Section {
                    Link("在任天堂網站查看", destination: sourceURL)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorite(for: game)
                } label: {
                    Image(systemName: viewModel.isFavorite(game) ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorite(game) ? .red : .primary)
                }
                .accessibilityLabel(viewModel.isFavorite(game) ? "從最愛移除" : "加入最愛")
            }
        }
    }
}

private struct GamePriceLabel: View {
    let price: GameDetailPrice

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
