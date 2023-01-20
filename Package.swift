// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "PaylikeClient",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "PaylikeClient", targets: ["PaylikeClient"])
    ],
    dependencies: [
        .package(url: "git@github.com:paylike/swift-request.git", .upToNextMajor(from: "0.2.1"))
    ],
    targets: [
        .target(
            name: "PaylikeClient",
            dependencies: [.product(name: "PaylikeRequest", package: "swift-request")]),
        .testTarget(
            name: "PaylikeClientTests",
            dependencies: [
                "PaylikeClient",
                .product(name: "PaylikeRequest", package: "swift-request"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
