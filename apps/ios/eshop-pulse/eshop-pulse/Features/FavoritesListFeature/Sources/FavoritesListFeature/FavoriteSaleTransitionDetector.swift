public enum FavoriteSaleTransitionDetector {
    public static func newlyOnSaleFavorites(
        from previousGames: [FavoriteGame]?,
        to updatedGames: [FavoriteGame],
        favoriteGameIDs: Set<String>
    ) -> [FavoriteGame] {
        guard let previousGames else { return [] }

        var previousSaleStatusByID: [String: Bool] = [:]
        for game in previousGames {
            previousSaleStatusByID[game.id] = game.price.isOnSale
        }

        return updatedGames.filter { game in
            favoriteGameIDs.contains(game.id)
                && previousSaleStatusByID[game.id] == false
                && game.price.isOnSale
        }
    }
}
