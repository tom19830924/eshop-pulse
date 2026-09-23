// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EshopService",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "EshopService", targets: ["EshopService"]),
    ],
    targets: [
        .target(name: "EshopService"),
        .testTarget(
            name: "EshopServiceTests",
            dependencies: ["EshopService"]
        ),
    ]
)
