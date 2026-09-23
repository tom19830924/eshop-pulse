import Foundation

struct FavoriteGameIDsStore {
    static let userDefaultsKey = "favoriteGameIDs"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> Set<String> {
        Set(userDefaults.stringArray(forKey: Self.userDefaultsKey) ?? [])
    }

    func save(_ favoriteGameIDs: Set<String>) {
        userDefaults.set(favoriteGameIDs.sorted(), forKey: Self.userDefaultsKey)
    }
}

enum FavoriteSaleAlertPreference {
    static let userDefaultsKey = "favoriteSaleAlertsEnabled"

    static func isEnabled(in userDefaults: UserDefaults = .standard) -> Bool {
        userDefaults.bool(forKey: userDefaultsKey)
    }

    static func setEnabled(_ enabled: Bool, in userDefaults: UserDefaults = .standard) {
        userDefaults.set(enabled, forKey: userDefaultsKey)
    }
}
