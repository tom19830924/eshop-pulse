// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FavoritesListFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "FavoritesListFeature", targets: ["FavoritesListFeature"]),
    ],
    targets: [
        .target(name: "FavoritesListFeature"),
    ]
)
