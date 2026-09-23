// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GameDetailFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GameDetailFeature", targets: ["GameDetailFeature"]),
    ],
    targets: [
        .target(name: "GameDetailFeature"),
    ]
)
