// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BrowseListFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BrowseListFeature", targets: ["BrowseListFeature"]),
    ],
    targets: [
        .target(name: "BrowseListFeature"),
    ]
)
